part of '../../pagination.dart';

/// Per-page stream subscription entry tracked by `SmartPaginationCubit`'s
/// `_pageStreams` registry. Private to this library — not exported.
///
/// Each entry owns exactly one `StreamSubscription`, the generation it was
/// registered under (used to drop stale buffered emissions after a scope
/// reset), and the page's most recent emission (the authoritative slice in
/// the merged paginated view).
///
/// See spec 002-stabilize-provider §FR-010 to FR-019c, data-model.md §4.
class _PageStreamEntry<T> {
  _PageStreamEntry({
    required this.subscription,
    required this.generation,
    required this.latestValue,
    this.error,
    this.isComplete = false,
  });

  final StreamSubscription<List<T>> subscription;
  final int generation;
  List<T> latestValue;

  /// Non-null when the page's stream errored. Per FR-017 / Clarifications Q1
  /// the entry is kept in the registry (its `latestValue` continues to
  /// contribute to the merged view) but its [subscription] is cancelled, so
  /// no further emissions will arrive for this page.
  Object? error;

  /// Spec 003-load-more-guard §6.7: Set to `true` once this page's stream has
  /// produced at least one full emission (i.e., `.first` has resolved). Used
  /// by `_emitMergedLoaded` to guard the short-page end-of-list heuristic so
  /// pages still warming up cannot prematurely trigger `hasReachedEnd`.
  bool isComplete;
}

// =============================================================================
// Spec 002-stabilize-provider — Phase 3 (US1) refactor landed.
// =============================================================================
// The previous single `_streamSubscription` field has been replaced by the
// per-page registry `Map<int, _PageStreamEntry<T>> _pageStreams` together
// with the per-page error annotation map `Map<int, Object> _pageErrors`.
//
// Lifecycle entry points:
//   `_resetToInitial`, `refreshPaginatedList`, `dispose` — bump `_generation`
//                                                          and call
//                                                          `_cancelAllPageStreams()`.
//   `_attachStream(stream, request)`                     — registers a new
//                                                          per-page subscription
//                                                          in `_pageStreams[page]`,
//                                                          gates emissions by
//                                                          `entry.generation == _generation`,
//                                                          and rebuilds the
//                                                          merged view via
//                                                          `_emitMergedLoaded`.
//   `_isolatePageError`                                  — per-page error
//                                                          isolation per
//                                                          FR-017 / Q1.
//   `_trimCachedPages`                                   — propagates page
//                                                          eviction to the
//                                                          registry (Research R6).
// =============================================================================

/// Strategy for handling retry behavior after an error occurs.
enum ErrorRetryStrategy {
  /// Automatically retry on next fetch call.
  /// Use this when you want seamless retry behavior.
  automatic,

  /// Don't retry automatically. Requires explicit call to [retryAfterError].
  /// Use this when you want user-controlled retry (e.g., retry button).
  manual,

  /// Don't retry at all until [refreshPaginatedList] is called (default behavior).
  /// This is the safest option - errors won't cause repeated failed requests.
  none,
}

class SmartPaginationCubit<T, R extends PaginationRequest>
    extends IPaginationListCubit<T, SmartPaginationState<T>, R> {
  static bool enableLogging = false;
  SmartPaginationCubit({
    required R request,
    required PaginationProvider<T, R> provider,
    ListBuilder<T>? listBuilder,
    OnInsertionCallback<T>? onInsertionCallback,
    VoidCallback? onClear,
    int maxPagesInMemory = 5,
    Logger? logger,
    RetryConfig? retryConfig,
    Duration? dataAge,
    SortOrderCollection<T>? orders,
    this.errorRetryStrategy = ErrorRetryStrategy.none,
    Stream<bool>? connectivityStream,
    this.identityKey,
  }) : _provider = provider,
       _listBuilder = listBuilder,
       _onInsertionCallback = onInsertionCallback,
       _onClear = onClear,
       _maxPagesInMemory = maxPagesInMemory,
       _logger = logger ?? Logger(),
       _retryHandler = retryConfig != null ? RetryHandler(retryConfig) : null,
       _dataAge = dataAge,
       _orders = orders,
       initialRequest = request,
       _currentRequest = request,
       super(SmartPaginationInitial<T>()) {
    // Listen to connectivity changes for auto-retry on network errors
    if (connectivityStream != null) {
      _connectivitySubscription = connectivityStream.listen(
        _onConnectivityChanged,
      );
    }
  }

  final PaginationProvider<T, R> _provider;
  final ListBuilder<T>? _listBuilder;
  final OnInsertionCallback<T>? _onInsertionCallback;
  final VoidCallback? _onClear;
  final int _maxPagesInMemory;
  final Logger _logger;
  final RetryHandler? _retryHandler;
  final Duration? _dataAge;
  SortOrderCollection<T>? _orders;

  /// Strategy for handling retry behavior when an error occurs.
  ///
  /// Defaults to [ErrorRetryStrategy.none] which means errors persist until
  /// [refreshPaginatedList] is called. This prevents automatic retry loops.
  ///
  /// Set to [ErrorRetryStrategy.automatic] to allow automatic retries, or
  /// [ErrorRetryStrategy.manual] to require explicit [retryAfterError] calls.
  final ErrorRetryStrategy errorRetryStrategy;

  /// Optional identity-key extractor for cross-page item deduplication.
  ///
  /// Spec 003-load-more-guard §FR-012. When non-null, the cubit drops items
  /// from a newly fetched page whose `identityKey(item)` already appears in
  /// any earlier accumulated page. Equality is on the extracted key, not the
  /// item itself, so consumers can dedupe by `id`, composite tuple, or any
  /// stable hashable value.
  ///
  /// When `null` (default) no deduplication occurs — items are appended
  /// exactly as the provider returned them. Deduplication is opt-in: the
  /// library never silently drops items.
  ///
  /// Example:
  /// ```dart
  /// SmartPaginationCubit<Product, PaginationRequest>(
  ///   request: PaginationRequest(page: 1, pageSize: 20),
  ///   provider: PaginationProvider.future(api.fetchProducts),
  ///   identityKey: (product) => product.id,
  /// );
  /// ```
  final Object? Function(T item)? identityKey;

  @override
  final R initialRequest;

  R _currentRequest;
  PaginationMeta? _currentMeta;
  final List<List<T>> _pages = <List<T>>[];
  StreamSubscription<bool>? _connectivitySubscription;
  int _fetchToken = 0;
  DateTime? _lastFetchTime;

  /// Pagination scope generation counter.
  ///
  /// Bumped before any cancellation begins on every scope-reset path
  /// (`_resetToInitial`, `refreshPaginatedList`, `dispose`). Every per-page
  /// stream entry in `_pageStreams` is tagged with the generation in effect
  /// at registration time; buffered emissions whose tagged generation no
  /// longer matches `_generation` are discarded.
  ///
  /// See spec 002-stabilize-provider §FR-003, FR-013, FR-016.
  int _generation = 0;

  /// Per-page stream subscription registry.
  ///
  /// Keys are 1-based page indices (the `request.page` of each registered
  /// page load). The map preserves insertion order (Dart `Map` default), so
  /// `_pageStreams.keys.first` is always the oldest active page — used by
  /// `_trimCachedPages` to propagate eviction to the registry.
  ///
  /// `StreamPaginationProvider` and `MergedStreamPaginationProvider` populate
  /// this map. `FuturePaginationProvider` does not.
  ///
  /// See spec 002-stabilize-provider §FR-010 to FR-018, data-model.md §5.
  final Map<int, _PageStreamEntry<T>> _pageStreams =
      <int, _PageStreamEntry<T>>{};

  /// Per-page error annotations carried in the public `SmartPaginationLoaded`
  /// state. Populated when a page's stream errors; the failing page's
  /// subscription is cancelled and removed from `_pageStreams` before this
  /// map is updated. Sibling pages remain unaffected.
  ///
  /// See spec 002-stabilize-provider §FR-017, Clarifications Q1.
  final Map<int, Object> _pageErrors = <int, Object>{};

  /// Bumps the scope generation. Call **before** cancellation runs on any
  /// scope-reset path so late buffered emissions are dropped by generation
  /// mismatch in Phase 3.
  void _bumpGeneration() {
    _generation++;
  }

  /// Flag to prevent concurrent fetch operations.
  ///
  /// Spec 003-load-more-guard §4.2: This flag is now set in
  /// [fetchPaginatedList] **before** the `emit(isLoadingMore: true)` call,
  /// not inside [_fetch]. This closes the synchronous gap between guard
  /// check and flag set. The flag is cleared in [_fetch]'s `finally` block
  /// (success and error paths) and in [cancelOngoingRequest].
  bool _isFetching = false;

  /// Per-page request key of the currently in-flight load-more.
  ///
  /// Spec 003-load-more-guard §4.1: Independent second-layer guard against
  /// duplicate fetches for the same page. Format is `"page:pageSize"`.
  /// Set in [fetchPaginatedList] alongside `_isFetching = true`; cleared on
  /// completion (success or error) in [_fetch]'s `finally` block, and on
  /// every scope-reset path ([_resetToInitial], [refreshPaginatedList],
  /// [cancelOngoingRequest], [dispose]).
  String? _activeLoadMoreKey;

  /// Builds the per-page load-more key for [_activeLoadMoreKey].
  String _buildLoadMoreKey(R request) =>
      '${request.page}:${request.pageSize ?? 'null'}';

  /// Removes items from [pageItems] whose [identityKey] already appears in
  /// [existingPages]. No-op when [identityKey] is null or [pageItems] is
  /// empty. Spec 003-load-more-guard §FR-012.
  List<T> _dedupeWithIdentityKey(
    List<T> pageItems,
    List<List<T>> existingPages,
  ) {
    final extractor = identityKey;
    if (extractor == null) return pageItems;
    if (pageItems.isEmpty) return pageItems;
    final seen = <Object?>{};
    for (final page in existingPages) {
      for (final item in page) {
        seen.add(extractor(item));
      }
    }
    final out = <T>[];
    for (final item in pageItems) {
      if (seen.add(extractor(item))) {
        out.add(item);
      }
    }
    return out;
  }

  /// Flag to track if the last fetch resulted in an error.
  /// Used by [errorRetryStrategy] to prevent automatic retries.
  bool _lastFetchWasError = false;

  /// Flag to track if the last error was a network-related error.
  /// Used for auto-retry when connectivity is restored.
  bool _lastErrorWasNetwork = false;

  /// The last error that occurred during fetch.
  Exception? _lastError;

  @override
  bool didFetch = false;

  /// Returns true if a fetch operation is currently in progress.
  bool get isFetching => _isFetching;

  /// Returns true if the last fetch resulted in an error.
  bool get hasError => _lastFetchWasError;

  /// Returns the last error that occurred, or null if no error.
  Exception? get lastError => _lastError;

  /// Returns true if the last error was network-related.
  /// Use this to show appropriate UI (e.g., "No internet connection").
  bool get isNetworkError => _lastErrorWasNetwork;

  /// Returns the configured data age duration.
  Duration? get dataAge => _dataAge;

  /// Returns the timestamp of the last successful data fetch.
  DateTime? get lastFetchTime => _lastFetchTime;

  // ==================== SORTING / ORDERS ====================

  /// Returns the current sort order collection.
  SortOrderCollection<T>? get orders => _orders;

  /// Returns the currently active sort order.
  SortOrder<T>? get activeOrder => _orders?.activeOrder;

  /// Returns the ID of the currently active sort order.
  String? get activeOrderId => _orders?.activeOrderId;

  /// Returns all available sort orders.
  List<SortOrder<T>> get availableOrders => _orders?.orders ?? [];

  /// Sets the sort order collection.
  ///
  /// This replaces the entire orders collection. If you want to just
  /// change the active order, use [setActiveOrder] instead.
  void setOrders(SortOrderCollection<T>? orders) {
    _orders = orders;
    _applySortingToCurrentState();
  }

  /// Sets the active sort order by ID and re-sorts the current items.
  ///
  /// Returns true if the order was found and set, false otherwise.
  ///
  /// Example:
  /// ```dart
  /// cubit.setActiveOrder('price'); // Sort by price
  /// cubit.setActiveOrder('name');  // Sort by name
  /// ```
  bool setActiveOrder(String orderId) {
    if (_orders == null) {
      if (SmartPaginationCubit.enableLogging) {
        _logger.w('Cannot set active order: no orders collection configured');
      }
      return false;
    }

    if (_orders!.setActiveOrder(orderId)) {
      if (SmartPaginationCubit.enableLogging) {
        _logger.d('Active sort order changed to: $orderId');
      }
      _applySortingToCurrentState();
      return true;
    }

    if (SmartPaginationCubit.enableLogging) {
      _logger.w('Sort order not found: $orderId');
    }
    return false;
  }

  /// Resets to the default sort order and re-sorts the current items.
  ///
  /// Example:
  /// ```dart
  /// cubit.resetOrder(); // Reset to default sorting
  /// ```
  void resetOrder() {
    if (_orders == null) return;

    _orders!.resetToDefault();
    if (SmartPaginationCubit.enableLogging) {
      _logger.d('Sort order reset to default: ${_orders!.defaultOrderId}');
    }
    _applySortingToCurrentState();
  }

  /// Clears the active sort order (items will be in their original order).
  ///
  /// Example:
  /// ```dart
  /// cubit.clearOrder(); // Remove sorting, show original order
  /// ```
  void clearOrder() {
    if (_orders == null) return;

    _orders!.clearActiveOrder();
    if (SmartPaginationCubit.enableLogging) {
      _logger.d('Sort order cleared');
    }
    _applySortingToCurrentState();
  }

  /// Adds a new sort order to the collection.
  ///
  /// Example:
  /// ```dart
  /// cubit.addSortOrder(SortOrder.byField(
  ///   id: 'rating',
  ///   label: 'Rating',
  ///   fieldSelector: (p) => p.rating,
  ///   direction: SortDirection.descending,
  /// ));
  /// ```
  void addSortOrder(SortOrder<T> order) {
    _orders ??= SortOrderCollection<T>(orders: []);
    _orders!.addOrder(order);
    if (SmartPaginationCubit.enableLogging) {
      _logger.d('Sort order added: ${order.id}');
    }
  }

  /// Removes a sort order from the collection.
  ///
  /// Returns true if the order was found and removed, false otherwise.
  bool removeSortOrder(String orderId) {
    if (_orders == null) return false;

    if (_orders!.removeOrder(orderId)) {
      if (SmartPaginationCubit.enableLogging) {
        _logger.d('Sort order removed: $orderId');
      }
      _applySortingToCurrentState();
      return true;
    }
    return false;
  }

  /// Sorts items using a one-time comparator without changing the active order.
  ///
  /// This is useful for temporary sorting that doesn't persist.
  ///
  /// Example:
  /// ```dart
  /// cubit.sortBy((a, b) => a.price.compareTo(b.price));
  /// ```
  void sortBy(ItemComparator<T> comparator) {
    final currentState = state;
    if (currentState is! SmartPaginationLoaded<T>) return;

    final sorted = List<T>.from(currentState.items)..sort(comparator);
    final sortedAll = List<T>.from(currentState.allItems)..sort(comparator);

    emit(
      currentState.copyWith(
        items: sorted,
        allItems: sortedAll,
        lastUpdate: DateTime.now(),
        lastOperation: const PaginationOperationReload(),
      ),
    );
  }

  /// Applies current sorting to the current state.
  void _applySortingToCurrentState() {
    final currentState = state;
    if (currentState is! SmartPaginationLoaded<T>) return;

    final sortedItems = _applySorting(currentState.items);
    final sortedAllItems = _applySorting(currentState.allItems);

    emit(
      currentState.copyWith(
        items: sortedItems,
        allItems: sortedAllItems,
        activeOrderId: _orders?.activeOrderId,
        lastUpdate: DateTime.now(),
        lastOperation: const PaginationOperationReload(),
      ),
    );
  }

  /// Applies the active sort order to a list of items.
  List<T> _applySorting(List<T> items) {
    if (_orders == null || _orders!.activeOrder == null) {
      return items;
    }
    return _orders!.sortItems(items);
  }

  /// Finds the correct insertion index to maintain sort order using binary search.
  ///
  /// Returns the index where [item] should be inserted to maintain sorted order.
  /// If no sorting is active, returns the [fallbackIndex].
  int _findSortedInsertIndex(
    List<T> sortedList,
    T item, {
    int fallbackIndex = 0,
  }) {
    final order = _orders?.activeOrder;
    if (order == null) {
      return fallbackIndex.clamp(0, sortedList.length);
    }

    // Binary search to find insertion point
    int low = 0;
    int high = sortedList.length;

    while (low < high) {
      final mid = (low + high) ~/ 2;
      final comparison = order.compare(item, sortedList[mid]);

      if (comparison <= 0) {
        high = mid;
      } else {
        low = mid + 1;
      }
    }

    return low;
  }

  /// Inserts multiple items into a sorted list while maintaining sort order.
  ///
  /// This is more efficient than inserting one by one for large batches,
  /// as it sorts the new items first and then merges them.
  List<T> _insertAllSorted(List<T> sortedList, List<T> newItems) {
    final order = _orders?.activeOrder;
    if (order == null) {
      // No sorting active, just append items
      return [...sortedList, ...newItems];
    }

    // Sort new items first
    final sortedNewItems = List<T>.from(newItems)..sort(order.compare);

    // Merge two sorted lists
    final result = <T>[];
    int i = 0;
    int j = 0;

    while (i < sortedList.length && j < sortedNewItems.length) {
      if (order.compare(sortedList[i], sortedNewItems[j]) <= 0) {
        result.add(sortedList[i]);
        i++;
      } else {
        result.add(sortedNewItems[j]);
        j++;
      }
    }

    // Add remaining items
    while (i < sortedList.length) {
      result.add(sortedList[i]);
      i++;
    }
    while (j < sortedNewItems.length) {
      result.add(sortedNewItems[j]);
      j++;
    }

    return result;
  }

  // ==================== END SORTING / ORDERS ====================

  /// Returns true if data has expired based on the configured [dataAge].
  /// If [dataAge] is null, data never expires.
  /// If no data has been fetched yet, returns false.
  bool get isDataExpired {
    if (_dataAge == null || _lastFetchTime == null) return false;
    return DateTime.now().difference(_lastFetchTime!) > _dataAge;
  }

  /// Checks if data has expired and resets the cubit if so.
  /// Returns true if the data was expired and reset was triggered.
  /// This is useful when using the cubit as a global variable and
  /// re-entering a screen after some time.
  bool checkAndResetIfExpired() {
    if (isDataExpired) {
      if (SmartPaginationCubit.enableLogging) {
        _logger.d('Data expired after $_dataAge, resetting pagination');
      }
      _resetToInitial();
      return true;
    }
    return false;
  }

  /// Resets the cubit to its initial state, clearing all data.
  void _resetToInitial() {
    _bumpGeneration();
    cancelOngoingRequest();
    _cancelAllPageStreams();
    _onClear?.call();
    didFetch = false;
    _pages.clear();
    _currentMeta = null;
    _lastFetchTime = null;
    emit(SmartPaginationInitial<T>());
  }

  /// Refreshes the data age timer. Called on any data interaction.
  /// This extends the data validity when user interacts with the list.
  void _refreshDataAge() {
    if (_dataAge != null && _lastFetchTime != null) {
      _lastFetchTime = DateTime.now();
    }
  }

  /// Gets the current expiration DateTime based on lastFetchTime and dataAge.
  DateTime? _getDataExpiredAt() {
    if (_dataAge == null || _lastFetchTime == null) return null;
    return _lastFetchTime!.add(_dataAge);
  }

  bool get _hasReachedEnd => _currentMeta != null && !_currentMeta!.hasNext;

  @override
  ListBuilder<T>? get listBuilder => _listBuilder;

  @override
  void filterPaginatedList(WhereChecker<T>? searchTerm) {
    final currentState = state;
    if (currentState is! SmartPaginationLoaded<T>) return;

    if (searchTerm == null) {
      emit(
        currentState.copyWith(
          items: List<T>.from(currentState.allItems),
          lastUpdate: DateTime.now(),
          lastOperation: const PaginationOperationReload(),
        ),
      );
      return;
    }

    final filtered = currentState.allItems.where(searchTerm).toList();
    if (SmartPaginationCubit.enableLogging) {
      _logger.d(
        'Applied pagination filter ${currentState.allItems.length} -> ${filtered.length}',
      );
    }
    emit(
      currentState.copyWith(
        items: filtered,
        lastUpdate: DateTime.now(),
        lastOperation: const PaginationOperationReload(),
      ),
    );
  }

  @override
  void refreshPaginatedList({R? requestOverride, int? limit}) {
    _bumpGeneration();
    // Cancel any ongoing request
    cancelOngoingRequest();
    _cancelAllPageStreams();
    _onClear?.call();
    didFetch = false;
    _pages.clear();
    _currentMeta = null;

    // Clear error state on refresh
    _lastFetchWasError = false;
    _lastErrorWasNetwork = false;
    _lastError = null;

    final request = _buildRequest(
      reset: true,
      override: requestOverride,
      limit: limit,
    );
    _fetch(request: request, reset: true);
  }

  /// Retries the last failed fetch operation.
  ///
  /// Use this method when [errorRetryStrategy] is set to [ErrorRetryStrategy.manual]
  /// to explicitly retry after an error.
  ///
  /// Example:
  /// ```dart
  /// if (cubit.hasError) {
  ///   cubit.retryAfterError();
  /// }
  /// ```
  void retryAfterError() {
    if (!_lastFetchWasError) {
      if (SmartPaginationCubit.enableLogging) {
        _logger.d('retryAfterError called but there is no error to retry');
      }
      return;
    }

    if (SmartPaginationCubit.enableLogging) {
      _logger.d('Retrying after error...');
    }
    _lastFetchWasError = false;
    _lastErrorWasNetwork = false;
    _lastError = null;

    // Determine if this was an initial load or load more
    if (state is SmartPaginationError<T>) {
      // Initial load failed, refresh
      refreshPaginatedList();
    } else if (state is SmartPaginationLoaded<T>) {
      // Load more failed, retry load more
      final currentState = state as SmartPaginationLoaded<T>;
      if (currentState.loadMoreError != null) {
        emit(currentState.copyWith(loadMoreError: null));
        final request = _buildRequest(reset: false);
        _fetch(request: request, reset: false);
      }
    }
  }

  /// Clears the error state without retrying.
  ///
  /// This is useful when you want to dismiss the error UI without triggering a retry.
  void clearError() {
    _lastFetchWasError = false;
    _lastErrorWasNetwork = false;
    _lastError = null;

    final currentState = state;
    if (currentState is SmartPaginationLoaded<T> &&
        currentState.loadMoreError != null) {
      emit(currentState.copyWith(loadMoreError: null));
    }
  }

  /// Called when connectivity status changes.
  /// Automatically retries if there was a pending network error.
  void _onConnectivityChanged(bool isConnected) {
    if (isConnected && _lastFetchWasError && _lastErrorWasNetwork) {
      if (SmartPaginationCubit.enableLogging) {
        _logger.d('Connectivity restored, retrying after network error...');
      }
      retryAfterError();
    }
  }

  /// Manually notify the cubit that connectivity has been restored.
  ///
  /// Call this method when you detect that internet connection is back
  /// and want to retry the last failed network request.
  ///
  /// Example:
  /// ```dart
  /// // Using connectivity_plus package
  /// Connectivity().onConnectivityChanged.listen((result) {
  ///   if (result != ConnectivityResult.none) {
  ///     cubit.onConnectivityRestored();
  ///   }
  /// });
  /// ```
  void onConnectivityRestored() {
    if (_lastFetchWasError && _lastErrorWasNetwork) {
      if (SmartPaginationCubit.enableLogging) {
        _logger.d(
          'Connectivity restored (manual), retrying after network error...',
        );
      }
      retryAfterError();
    }
  }

  @override
  void fetchPaginatedList({R? requestOverride, int? limit}) {
    // Prevent concurrent fetch operations
    if (_isFetching) {
      if (SmartPaginationCubit.enableLogging) {
        _logger.d('Fetch already in progress, skipping duplicate request');
      }
      return;
    }

    // Check error retry strategy
    if (_lastFetchWasError) {
      switch (errorRetryStrategy) {
        case ErrorRetryStrategy.automatic:
          // Allow retry, clear the error flag
          _lastFetchWasError = false;
          _lastError = null;
          break;
        case ErrorRetryStrategy.manual:
          // Don't retry automatically, require explicit retryAfterError() call
          if (SmartPaginationCubit.enableLogging) {
            _logger.d(
              'Error retry strategy is manual, skipping automatic retry. Call retryAfterError() to retry.',
            );
          }
          return;
        case ErrorRetryStrategy.none:
          // Don't retry at all
          if (SmartPaginationCubit.enableLogging) {
            _logger.d(
              'Error retry strategy is none, skipping retry. Call refreshPaginatedList() to reset.',
            );
          }
          return;
      }
    }

    // Check if data has expired and reset if necessary
    if (checkAndResetIfExpired()) {
      // State has been reset to initial, continue to load fresh data
    }

    if (state is SmartPaginationInitial<T>) {
      refreshPaginatedList(requestOverride: requestOverride, limit: limit);
      return;
    }

    if (_hasReachedEnd) return;

    // Spec 003-load-more-guard §4.4 — guard order:
    //   5. _hasReachedEnd  (above)
    //   6. compute loadMoreKey
    //   7. _activeLoadMoreKey == loadMoreKey  → drop duplicate page request
    //   8. currentState.isLoadingMore         → drop duplicate state-level
    //   9. _isFetching = true                 → moved here from _fetch()
    //   10. _activeLoadMoreKey = loadMoreKey  → set before any await
    //   11. emit(isLoadingMore: true)
    //   12. _fetch(...)
    final request = _buildRequest(
      reset: false,
      override: requestOverride,
      limit: limit,
    );
    final loadMoreKey = _buildLoadMoreKey(request);
    if (_activeLoadMoreKey == loadMoreKey) {
      if (SmartPaginationCubit.enableLogging) {
        _logger.d(
          'Duplicate load-more for key=$loadMoreKey already in flight; skipping',
        );
      }
      return;
    }

    // Set isLoadingMore = true when loading more items
    final currentState = state;
    if (currentState is SmartPaginationLoaded<T>) {
      if (currentState.isLoadingMore) return; // Already loading

      _isFetching = true;
      _activeLoadMoreKey = loadMoreKey;
      emit(
        currentState.copyWith(
          isLoadingMore: true,
          loadMoreError: null, // Clear any previous error
        ),
      );
    }

    _fetch(request: request, reset: false);
  }

  Future<void> _fetch({
    required R request,
    required bool reset,
  }) async {
    // Spec 003-load-more-guard §4.2: `_isFetching` is now set in
    // `fetchPaginatedList` BEFORE this method is called. For initial-load
    // paths that bypass `fetchPaginatedList` (refresh/reset) we still need
    // the flag here to prevent concurrent fetches.
    if (!_isFetching) {
      _isFetching = true;
    }
    final token = ++_fetchToken;

    // Spec 003-load-more-guard §8.1, §9: capture the stream factory call
    // exactly once per page. The same instance is awaited for `.first`
    // (snapshot) and passed to `_attachStream` for the persistent
    // subscription, eliminating the previous double factory call.
    Stream<List<T>>? capturedStream;

    try {
      // Fetch data based on provider type
      final pageItems = await switch (_provider) {
        FuturePaginationProvider<T, R>(:final dataProvider) =>
          _retryHandler != null
              ? _retryHandler.execute(
                  () => dataProvider(request),
                  onRetry: (attempt, error) {
                    if (SmartPaginationCubit.enableLogging) {
                      _logger.w('Retry attempt $attempt after error: $error');
                    }
                  },
                )
              : dataProvider(request),
        StreamPaginationProvider<T, R> provider =>
          (capturedStream = provider.streamProvider(request)).first,
        MergedStreamPaginationProvider<T, R> provider =>
          (capturedStream = provider.getMergedStream(request)).first,
      };

      // Check if request was cancelled
      if (token != _fetchToken) {
        return;
      }
      // Per FR-005: do not mutate state after the cubit has been closed
      // (e.g., a slow page response that resolves after `dispose()`).
      if (isClosed) {
        return;
      }

      didFetch = true;
      _currentRequest = request;

      // Clear error state on successful fetch
      _lastFetchWasError = false;
      _lastError = null;

      // Update last fetch time for data age tracking
      // Refresh on initial load and on load more (any successful fetch)
      _lastFetchTime = DateTime.now();

      // Spec 003-load-more-guard §6.1, FR-005: empty load-more response
      // signals end-of-list. Mark `hasReachedEnd` and DO NOT append the
      // empty page. (Empty initial-load is handled below — it produces an
      // empty Loaded state with `hasReachedEnd = true`.)
      if (!reset && pageItems.isEmpty) {
        final meta = PaginationMeta(
          page: request.page,
          pageSize: request.pageSize,
          hasNext: false,
          hasPrevious: request.page > 1,
        );
        _currentMeta = meta;
        final currentState = state;
        if (currentState is SmartPaginationLoaded<T>) {
          emit(
            currentState.copyWith(
              meta: meta,
              hasReachedEnd: true,
              isLoadingMore: false,
              loadMoreError: null,
              fetchedAt: _lastFetchTime,
              dataExpiredAt: _dataAge != null && _lastFetchTime != null
                  ? _lastFetchTime!.add(_dataAge)
                  : null,
              lastOperation: const PaginationOperationNone(),
            ),
          );
        }
        return;
      }

      // Spec 003-load-more-guard §FR-012: cross-page identity-key
      // deduplication (opt-in). On load-more, drop items already present in
      // earlier pages. On reset/initial load `_pages` is empty so dedup is
      // a no-op and items pass through unchanged.
      final dedupedPageItems = reset
          ? pageItems
          : _dedupeWithIdentityKey(pageItems, _pages);

      if (reset) {
        _pages
          ..clear()
          ..add(dedupedPageItems);
      } else {
        _pages.add(dedupedPageItems);
      }

      _trimCachedPages();

      final aggregated = _applyListBuilder(
        _pages.expand((page) => page).toList(),
      );

      // Apply sorting if orders are configured
      final sortedItems = _applySorting(aggregated);

      final hasNext = _computeHasNext(pageItems, request.pageSize);
      final meta = PaginationMeta(
        page: request.page,
        pageSize: request.pageSize,
        hasNext: hasNext,
        hasPrevious: request.page > 1,
      );
      _currentMeta = meta;

      _onInsertionCallback?.call(sortedItems);

      // Compute the operation that produced this state so the UI can decide
      // whether to remount the animated list (Reload) or just animate the
      // newly appended items (Insert at the previous tail).
      final PaginationOperation fetchOperation;
      if (reset) {
        fetchOperation = const PaginationOperationReload();
      } else {
        final previousState = state;
        final previousLength = previousState is SmartPaginationLoaded<T>
            ? previousState.items.length
            : 0;
        final delta = sortedItems.length - previousLength;
        // Only treat it as a clean append when sorting did not reorder the
        // existing prefix; otherwise fall back to a reload signal.
        final appendedCleanly = delta > 0 &&
            _isPrefix(sortedItems, previousState, previousLength);
        fetchOperation = appendedCleanly
            ? PaginationOperationInsert(
                index: previousLength,
                count: delta,
              )
            : const PaginationOperationReload();
      }

      emit(
        SmartPaginationLoaded<T>(
          items: List<T>.from(sortedItems),
          allItems: sortedItems,
          meta: meta,
          hasReachedEnd: !hasNext,
          isLoadingMore: false, // Clear loading flag on success
          loadMoreError: null, // Clear any previous error
          fetchedAt: _lastFetchTime,
          dataExpiredAt: _dataAge != null && _lastFetchTime != null
              ? _lastFetchTime!.add(_dataAge)
              : null,
          activeOrderId: _orders?.activeOrderId,
          lastOperation: fetchOperation,
        ),
      );

      // Register a per-page stream subscription for **every** page load
      // (initial AND load-more) per spec FR-010. This delivers stream
      // accumulation: page N's subscription is added to the registry without
      // cancelling pages 1..N-1.
      //
      // Spec 003-load-more-guard §8.1, §9: when the captured stream is a
      // broadcast stream, reuse it for the persistent subscription — the
      // `.first` consumer above and the `_attachStream` listener can both
      // co-exist. For single-subscription streams the `.first` await has
      // already consumed the only allowed listener slot; we fall back to a
      // second factory call so `_attachStream` gets a fresh subscription.
      // RC-3 (eliminate double factory call) applies to broadcast streams,
      // which is the real-world common case (Firestore, broadcast
      // controllers, RxDart subjects).
      if (capturedStream != null) {
        final Stream<List<T>> persistent;
        final provider = _provider;
        if (capturedStream.isBroadcast) {
          persistent = capturedStream;
        } else if (provider is StreamPaginationProvider<T, R>) {
          persistent = provider.streamProvider(request);
        } else if (provider is MergedStreamPaginationProvider<T, R>) {
          persistent = provider.getMergedStream(request);
        } else {
          persistent = capturedStream;
        }
        _attachStream(persistent, request);
      }
    } on Exception catch (error, stackTrace) {
      if (SmartPaginationCubit.enableLogging) {
        _logger.e(
          'Pagination request failed',
          error: error,
          stackTrace: stackTrace,
        );
      }

      // Set error state
      _lastFetchWasError = true;
      _lastError = error;

      // Check if this is a network-related error
      _lastErrorWasNetwork = _isNetworkError(error);
      if (_lastErrorWasNetwork) {
        if (SmartPaginationCubit.enableLogging) {
          _logger.d(
            'Network error detected, will auto-retry when connectivity is restored',
          );
        }
      }

      // Handle load more errors differently
      if (!reset && state is SmartPaginationLoaded<T>) {
        final currentState = state as SmartPaginationLoaded<T>;
        emit(currentState.copyWith(isLoadingMore: false, loadMoreError: error));
      } else {
        emit(SmartPaginationError<T>(error: error));
      }
    } catch (error, stackTrace) {
      final exception = Exception(error.toString());
      if (SmartPaginationCubit.enableLogging) {
        _logger.e(
          'Pagination request failed',
          error: exception,
          stackTrace: stackTrace,
        );
      }

      // Set error state
      _lastFetchWasError = true;
      _lastError = exception;

      // Check if this is a network-related error (based on error message)
      _lastErrorWasNetwork = _isNetworkErrorMessage(error.toString());
      if (_lastErrorWasNetwork) {
        if (SmartPaginationCubit.enableLogging) {
          _logger.d(
            'Network error detected, will auto-retry when connectivity is restored',
          );
        }
      }

      // Handle load more errors differently
      if (!reset && state is SmartPaginationLoaded<T>) {
        final currentState = state as SmartPaginationLoaded<T>;
        emit(
          currentState.copyWith(isLoadingMore: false, loadMoreError: exception),
        );
      } else {
        emit(SmartPaginationError<T>(error: exception));
      }
    } finally {
      // Spec 003-load-more-guard §4.1, §4.2: always clear both the in-flight
      // flag and the per-page key. Runs on success, error, and stale-token
      // early returns. Clearing the key allows a subsequent retry for the
      // same page after an error to proceed.
      _isFetching = false;
      _activeLoadMoreKey = null;
    }
  }

  R _buildRequest({
    required bool reset,
    R? override,
    int? limit,
  }) {
    final base = override ?? (reset ? initialRequest : _currentRequest);
    final pageSize = limit ?? base.pageSize ?? initialRequest.pageSize;
    final nextPage = reset ? 1 : base.page + 1;

    // copyWith is declared on PaginationRequest but subclasses should override
    // it to return their own type (preserving custom fields). The cast is safe
    // when the override is implemented correctly.
    return base.copyWith(page: nextPage, pageSize: pageSize) as R;
  }

  /// Computes whether more pages may exist after the current one.
  ///
  /// Spec 003-load-more-guard §6.3: When the provider knows the answer
  /// (cursor-null or explicit `hasMore: false`), it can pass [serverHasNext]
  /// to override the item-count heuristic. The override is consulted first
  /// — if it is non-null, its value is returned verbatim.
  ///
  /// Without [serverHasNext], end-of-list is inferred from the page size:
  /// a short page (`items.length < pageSize`) signals end. When [pageSize]
  /// is null, a non-empty page is treated as "more may exist".
  bool _computeHasNext(
    List<T> items,
    int? pageSize, {
    bool? serverHasNext,
  }) {
    if (serverHasNext != null) return serverHasNext;
    if (pageSize == null) {
      return items.isNotEmpty;
    }
    return items.length >= pageSize;
  }

  /// Checks if the exception is a network-related error.
  bool _isNetworkError(Exception error) {
    // Check for pagination-specific network exceptions
    if (error is PaginationNetworkException) return true;
    if (error is PaginationTimeoutException) return true;
    if (error is PaginationRetryExhaustedException) {
      // Check if the original error was network-related
      final original = error.originalError;
      if (original is PaginationNetworkException) return true;
      if (original is PaginationTimeoutException) return true;
    }

    // Check error message for common network error patterns
    return _isNetworkErrorMessage(error.toString());
  }

  /// Checks if the error message indicates a network error.
  bool _isNetworkErrorMessage(String message) {
    final lowerMessage = message.toLowerCase();
    return lowerMessage.contains('socketexception') ||
        lowerMessage.contains('connection refused') ||
        lowerMessage.contains('connection reset') ||
        lowerMessage.contains('connection closed') ||
        lowerMessage.contains('connection timed out') ||
        lowerMessage.contains('network is unreachable') ||
        lowerMessage.contains('no internet') ||
        lowerMessage.contains('no address associated') ||
        lowerMessage.contains('failed host lookup') ||
        lowerMessage.contains('handshake') ||
        lowerMessage.contains('certificate') ||
        lowerMessage.contains('errno = 7') || // Android: no internet
        lowerMessage.contains('errno = 101') || // Linux: network unreachable
        lowerMessage.contains('clientexception'); // http package
  }

  /// Registers a per-page stream subscription in `_pageStreams[page]`.
  ///
  /// Each emission is gated by `entry.generation == _generation` (stale-scope
  /// protection per FR-016), then attributed to the originating page (FR-011),
  /// and the cubit re-emits a merged `SmartPaginationLoaded` whose `items` is
  /// the concatenation of every active page's `latestValue` in ascending page
  /// order (FR-012). On a per-page error, only the failing page's subscription
  /// is cancelled and removed; sibling pages keep emitting (FR-017,
  /// Clarifications Q1).
  ///
  /// Replaces the prior single-`_streamSubscription` implementation. Called
  /// for **every** page load (initial + load-more), not just on reset.
  void _attachStream(Stream<List<T>> stream, R request) {
    final page = request.page;
    final generation = _generation;

    // Spec 003-load-more-guard §4.6, §8.2: duplicate-registration guard.
    // If this exact page is already registered under the current generation,
    // skip silently — the existing subscription is the authoritative one and
    // re-registering would either double-subscribe (cold stream) or destroy
    // accumulated `latestValue` for no reason.
    final existing = _pageStreams[page];
    if (existing != null && existing.generation == generation) {
      return;
    }

    // Defensive: cancel any stale entry from a prior generation for this page.
    _pageStreams.remove(page)?.subscription.cancel();

    // Seed the registry with whatever `_pages` currently has for this page.
    // The `_fetch` method has already appended the `.first` snapshot to
    // `_pages` before calling us, so the slot mapping to `request.page` is
    // the most recently appended entry.
    final seededValue = _pages.isNotEmpty
        ? List<T>.from(_pages.last)
        : <T>[];

    late StreamSubscription<List<T>> sub;
    sub = stream.listen(
      (items) {
        if (generation != _generation) return; // stale-scope emission
        if (isClosed) return;
        final entry = _pageStreams[page];
        if (entry == null) return; // entry already cancelled by reset/eviction
        entry.latestValue = items;
        // Spec 003-load-more-guard §6.7: mark the page complete once it has
        // delivered its first emission. The merged-stream end-of-list check
        // in `_emitMergedLoaded` only consults pages flagged complete, so
        // pages still warming up cannot prematurely set `hasReachedEnd`.
        entry.isComplete = true;
        _pageErrors.remove(page); // a fresh successful emission clears prior error
        _rebuildPagesFromRegistry();
        _emitMergedLoaded(request);
      },
      onError: (error, stack) {
        if (generation != _generation) return;
        if (isClosed) return;
        _isolatePageError(page, error, stack, request);
      },
    );

    // The page's `.first` snapshot has already been awaited and appended to
    // `_pages` by `_fetch`, so the entry is born complete.
    _pageStreams[page] = _PageStreamEntry<T>(
      subscription: sub,
      generation: generation,
      latestValue: seededValue,
      isComplete: true,
    );
  }

  /// Cancels every active per-page stream subscription, clears the registry,
  /// and clears the `_pageErrors` annotation map. Used on every scope-reset
  /// path (`_resetToInitial`, `refreshPaginatedList`, `dispose`) per FR-013
  /// and FR-014.
  void _cancelAllPageStreams() {
    for (final entry in _pageStreams.values) {
      entry.subscription.cancel();
    }
    _pageStreams.clear();
    _pageErrors.clear();
  }

  /// Rebuilds `_pages` from the per-page registry, in ascending page order,
  /// so the existing aggregation pipeline (`_applyListBuilder`, `_applySorting`,
  /// emission) sees the merged view of every active page's latest emission.
  void _rebuildPagesFromRegistry() {
    final keys = _pageStreams.keys.toList()..sort();
    _pages
      ..clear()
      ..addAll(keys.map((k) => _pageStreams[k]!.latestValue));
  }

  /// Emits a `SmartPaginationLoaded` derived from the current registry state.
  /// `_pages` MUST already be in sync with the registry before calling.
  void _emitMergedLoaded(R request) {
    // Spec 003-load-more-guard §FR-012: apply identity-key deduplication to
    // the merged view. `_rebuildPagesFromRegistry` rebuilds `_pages` from the
    // per-page registry in ascending order — we deduplicate across that
    // ordered view so the first occurrence (in the lowest page) wins.
    final mergedRaw = _pages.expand((page) => page).toList();
    final extractor = identityKey;
    final merged = extractor == null
        ? mergedRaw
        : (() {
            final seen = <Object?>{};
            final out = <T>[];
            for (final item in mergedRaw) {
              if (seen.add(extractor(item))) {
                out.add(item);
              }
            }
            return out;
          })();

    final aggregated = _applyListBuilder(merged);
    final sortedItems = _applySorting(aggregated);
    _onInsertionCallback?.call(sortedItems);

    // Derive end-of-pagination per Clarifications Q2 / FR-019b/c.
    // When pageSize is null we cannot compute "page is full"; mirror the
    // existing `_computeHasNext` behaviour and assume more pages remain.
    //
    // Spec 003-load-more-guard §6.7 (RC-7): only pages that have completed
    // their initial emission contribute to the short-page end-of-list
    // signal. Pages still warming up cannot prematurely set `hasReachedEnd`.
    final pageSize = request.pageSize;
    final endOfPagination = pageSize != null &&
        _pageStreams.values
            .any((e) => e.isComplete && e.latestValue.length < pageSize);
    final highestPage = _pageStreams.keys.isEmpty
        ? request.page
        : _pageStreams.keys.reduce((a, b) => a > b ? a : b);
    final lowestPage = _pageStreams.keys.isEmpty
        ? request.page
        : _pageStreams.keys.reduce((a, b) => a < b ? a : b);
    final meta = PaginationMeta(
      page: highestPage,
      pageSize: pageSize,
      hasNext: !endOfPagination,
      hasPrevious: lowestPage > 1,
    );
    _currentMeta = meta;

    emit(
      SmartPaginationLoaded<T>(
        items: List<T>.from(sortedItems),
        allItems: sortedItems,
        meta: meta,
        hasReachedEnd: endOfPagination,
        isLoadingMore: false,
        loadMoreError: null,
        fetchedAt: _lastFetchTime,
        dataExpiredAt: _dataAge != null && _lastFetchTime != null
            ? _lastFetchTime!.add(_dataAge)
            : null,
        activeOrderId: _orders?.activeOrderId,
        lastOperation: const PaginationOperationReload(),
        pageErrors: Map<int, Object>.unmodifiable(_pageErrors),
      ),
    );
  }

  /// Per-page error isolation per FR-017 / Clarifications Q1.
  ///
  /// Cancels the failing page's subscription, marks the entry's `error`
  /// field, and records the error in `_pageErrors`. The entry itself is
  /// **kept in the registry** so its `latestValue` continues to contribute
  /// to the merged view — the user keeps seeing the page's last good slice
  /// alongside the per-page error annotation. Sibling pages remain live.
  void _isolatePageError(
    int page,
    Object error,
    StackTrace stack,
    R request,
  ) {
    final entry = _pageStreams[page];
    if (entry == null) return;
    entry.subscription.cancel();
    entry.error = error;
    _pageErrors[page] = error;
    if (SmartPaginationCubit.enableLogging) {
      _logger.e(
        'Pagination per-page stream error on page $page',
        error: error,
        stackTrace: stack,
      );
    }
    _rebuildPagesFromRegistry();
    _emitMergedLoaded(request);
  }

  List<T> _applyListBuilder(List<T> items) {
    return _listBuilder?.call(items) ?? items;
  }

  /// Returns true if the first [previousLength] items of [next] match the
  /// items of [previousState] in order. Used to detect a clean append for
  /// load-more so we can emit a precise [PaginationOperationInsert].
  bool _isPrefix(
    List<T> next,
    SmartPaginationState<T> previousState,
    int previousLength,
  ) {
    if (previousState is! SmartPaginationLoaded<T>) return false;
    if (previousLength == 0) return true;
    if (next.length < previousLength) return false;
    final previousItems = previousState.items;
    for (var i = 0; i < previousLength; i++) {
      if (previousItems[i] != next[i]) return false;
    }
    return true;
  }

  void _trimCachedPages() {
    if (_maxPagesInMemory <= 0) return;
    while (_pages.length > _maxPagesInMemory) {
      _pages.removeAt(0);
      // Lifecycle propagation per Research R6: when the page-list cap drops
      // the oldest page, cancel the corresponding registry entry so its
      // stream subscription is not orphaned. `_pageStreams.keys` preserves
      // insertion order; the lowest key is always the oldest page.
      if (_pageStreams.isNotEmpty) {
        final oldestPage = _pageStreams.keys.reduce((a, b) => a < b ? a : b);
        final removed = _pageStreams.remove(oldestPage);
        removed?.subscription.cancel();
        _pageErrors.remove(oldestPage);
      }
    }
  }

  @override
  void cancelOngoingRequest() {
    _fetchToken++;
    _isFetching = false;
    // Spec 003-load-more-guard §4.1: external cancellation must also clear
    // the per-page key so a subsequent fetch for the same page is not
    // blocked by a stale active key.
    _activeLoadMoreKey = null;
  }

  @override
  void dispose() {
    _bumpGeneration();
    cancelOngoingRequest();
    _cancelAllPageStreams();
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
  }

  @override
  Future<bool> insertEmit(T item, {int index = 0}) async {
    final currentState = state;
    if (currentState is! SmartPaginationLoaded<T>) return false;

    final updated = List<T>.from(currentState.allItems);

    // Use sorted insertion if sorting is active, otherwise use the provided index
    final insertIndex = _findSortedInsertIndex(
      updated,
      item,
      fallbackIndex: index,
    );
    updated.insert(insertIndex, item);
    _onInsertionCallback?.call(updated);

    _refreshDataAge();
    emit(
      currentState.copyWith(
        allItems: updated,
        items: updated,
        lastUpdate: DateTime.now(),
        fetchedAt: _lastFetchTime,
        dataExpiredAt: _getDataExpiredAt(),
        lastOperation: PaginationOperationInsert(index: insertIndex),
      ),
    );
    return true;
  }

  @override
  Future<bool> addOrUpdateEmit(T item, {int index = 0}) async {
    final currentState = state;
    if (currentState is! SmartPaginationLoaded<T>) return false;

    final updated = List<T>.from(currentState.allItems);
    final existingIndex = updated.indexWhere((element) => element == item);

    PaginationOperation operation;

    if (existingIndex != -1) {
      // Update existing item - if sorting is active, may need to reposition
      final order = _orders?.activeOrder;
      if (order != null) {
        // Remove and re-insert at correct sorted position
        updated.removeAt(existingIndex);
        final newIndex = _findSortedInsertIndex(
          updated,
          item,
          fallbackIndex: existingIndex,
        );
        updated.insert(newIndex, item);
      } else {
        // No sorting, just update in place
        updated[existingIndex] = item;
      }
      operation = PaginationOperationUpdate(indices: [existingIndex]);
    } else {
      // New item - use sorted insertion if sorting is active
      final insertIndex = _findSortedInsertIndex(
        updated,
        item,
        fallbackIndex: index,
      );
      updated.insert(insertIndex, item);
      operation = PaginationOperationInsert(index: insertIndex);
    }

    _onInsertionCallback?.call(updated);

    _refreshDataAge();
    emit(
      currentState.copyWith(
        allItems: updated,
        items: updated,
        lastUpdate: DateTime.now(),
        fetchedAt: _lastFetchTime,
        dataExpiredAt: _getDataExpiredAt(),
        lastOperation: operation,
      ),
    );
    return true;
  }

  @override
  List<T> get currentItems {
    final currentState = state;
    if (currentState is SmartPaginationLoaded<T>) {
      return List<T>.unmodifiable(currentState.allItems);
    }
    return const [];
  }

  @override
  Future<bool> insertAllEmit(List<T> items, {int index = 0}) async {
    final currentState = state;
    if (currentState is! SmartPaginationLoaded<T>) return false;

    if (items.isEmpty) return false;

    final currentItems = List<T>.from(currentState.allItems);
    final insertIndex = index.clamp(0, currentItems.length);

    // Use efficient merge if sorting is active, otherwise use simple insertAll
    final updated = _orders?.activeOrder != null
        ? _insertAllSorted(currentItems, items)
        : (List<T>.from(currentItems)..insertAll(insertIndex, items));

    _onInsertionCallback?.call(updated);

    _refreshDataAge();
    emit(
      currentState.copyWith(
        allItems: updated,
        items: updated,
        lastUpdate: DateTime.now(),
        fetchedAt: _lastFetchTime,
        dataExpiredAt: _getDataExpiredAt(),
        lastOperation: PaginationOperationInsert(
          index: insertIndex,
          count: items.length,
        ),
      ),
    );
    return true;
  }

  @override
  Future<bool> removeItemEmit(T item) async {
    final currentState = state;
    if (currentState is! SmartPaginationLoaded<T>) return false;

    final updated = List<T>.from(currentState.allItems);
    final removedIndex = updated.indexOf(item);

    if (removedIndex == -1) return false;

    updated.removeAt(removedIndex);

    _onInsertionCallback?.call(updated);

    _refreshDataAge();
    emit(
      currentState.copyWith(
        allItems: updated,
        items: updated,
        lastUpdate: DateTime.now(),
        fetchedAt: _lastFetchTime,
        dataExpiredAt: _getDataExpiredAt(),
        lastOperation: PaginationOperationRemove(index: removedIndex),
      ),
    );
    return true;
  }

  @override
  Future<bool> removeAtEmit(int index) async {
    final currentState = state;
    if (currentState is! SmartPaginationLoaded<T>) return false;

    final updated = List<T>.from(currentState.allItems);

    if (index < 0 || index >= updated.length) return false;

    updated.removeAt(index);

    _onInsertionCallback?.call(updated);

    _refreshDataAge();
    emit(
      currentState.copyWith(
        allItems: updated,
        items: updated,
        lastUpdate: DateTime.now(),
        fetchedAt: _lastFetchTime,
        dataExpiredAt: _getDataExpiredAt(),
        lastOperation: PaginationOperationRemove(index: index),
      ),
    );
    return true;
  }

  @override
  Future<bool> removeWhereEmit(bool Function(T item) test) async {
    final currentState = state;
    if (currentState is! SmartPaginationLoaded<T>) return false;

    final updated = List<T>.from(currentState.allItems);
    final originalLength = updated.length;
    updated.removeWhere(test);
    final removedCount = originalLength - updated.length;

    if (removedCount == 0) return false;

    _onInsertionCallback?.call(updated);

    _refreshDataAge();
    emit(
      currentState.copyWith(
        allItems: updated,
        items: updated,
        lastUpdate: DateTime.now(),
        fetchedAt: _lastFetchTime,
        dataExpiredAt: _getDataExpiredAt(),
        lastOperation: PaginationOperationRemove(
          index: -1,
          count: removedCount,
        ),
      ),
    );
    return true;
  }

  @override
  Future<bool> updateItemEmit(
    bool Function(T item) matcher,
    T Function(T item) updater,
  ) async {
    final currentState = state;
    if (currentState is! SmartPaginationLoaded<T>) return false;

    final updated = List<T>.from(currentState.allItems);
    final index = updated.indexWhere(matcher);

    if (index == -1) return false;

    final updatedItem = updater(updated[index]);

    // If sorting is active, reposition the item to maintain sort order
    final order = _orders?.activeOrder;
    if (order != null) {
      updated.removeAt(index);
      final newIndex = _findSortedInsertIndex(
        updated,
        updatedItem,
        fallbackIndex: index,
      );
      updated.insert(newIndex, updatedItem);
    } else {
      updated[index] = updatedItem;
    }

    _onInsertionCallback?.call(updated);

    _refreshDataAge();
    emit(
      currentState.copyWith(
        allItems: updated,
        items: updated,
        lastUpdate: DateTime.now(),
        fetchedAt: _lastFetchTime,
        dataExpiredAt: _getDataExpiredAt(),
        lastOperation: PaginationOperationUpdate(indices: [index]),
      ),
    );
    return true;
  }

  @override
  Future<bool> updateWhereEmit(
    bool Function(T item) matcher,
    T Function(T item) updater,
  ) async {
    final currentState = state;
    if (currentState is! SmartPaginationLoaded<T>) return false;

    final updated = List<T>.from(currentState.allItems);
    final order = _orders?.activeOrder;
    final updatedIndices = <int>[];

    if (order != null) {
      // Collect items to update
      final itemsToUpdate = <T>[];
      final indicesToRemove = <int>[];

      for (var i = 0; i < updated.length; i++) {
        if (matcher(updated[i])) {
          itemsToUpdate.add(updater(updated[i]));
          indicesToRemove.add(i);
          updatedIndices.add(i);
        }
      }

      if (updatedIndices.isEmpty) return false;

      // Remove items in reverse order to maintain indices
      for (var i = indicesToRemove.length - 1; i >= 0; i--) {
        updated.removeAt(indicesToRemove[i]);
      }

      // Re-insert updated items at correct sorted positions using merge
      final result = _insertAllSorted(updated, itemsToUpdate);
      updated
        ..clear()
        ..addAll(result);
    } else {
      // No sorting, update in place
      for (var i = 0; i < updated.length; i++) {
        if (matcher(updated[i])) {
          updated[i] = updater(updated[i]);
          updatedIndices.add(i);
        }
      }

      if (updatedIndices.isEmpty) return false;
    }

    _onInsertionCallback?.call(updated);

    _refreshDataAge();
    emit(
      currentState.copyWith(
        allItems: updated,
        items: updated,
        lastUpdate: DateTime.now(),
        fetchedAt: _lastFetchTime,
        dataExpiredAt: _getDataExpiredAt(),
        lastOperation: PaginationOperationUpdate(indices: updatedIndices),
      ),
    );
    return true;
  }

  @override
  Future<bool> clearItems() async {
    final currentState = state;
    if (currentState is! SmartPaginationLoaded<T>) return false;

    _pages.clear();
    _onClear?.call();

    emit(
      currentState.copyWith(
        allItems: <T>[],
        items: <T>[],
        hasReachedEnd: true,
        lastUpdate: DateTime.now(),
        lastOperation: const PaginationOperationReload(),
      ),
    );
    return true;
  }

  @override
  void reload() {
    refreshPaginatedList();
  }

  @override
  Future<bool> setItems(List<T> items) async {
    final currentState = state;

    final transformedItems = _applyListBuilder(items);
    _onInsertionCallback?.call(transformedItems);

    // Update last fetch time when setting items manually
    _lastFetchTime = DateTime.now();

    if (currentState is SmartPaginationLoaded<T>) {
      emit(
        currentState.copyWith(
          allItems: transformedItems,
          items: transformedItems,
          hasReachedEnd: true,
          lastUpdate: DateTime.now(),
          fetchedAt: _lastFetchTime,
          dataExpiredAt: _dataAge != null
              ? _lastFetchTime!.add(_dataAge)
              : null,
          lastOperation: const PaginationOperationReload(),
        ),
      );
    } else {
      // Create a new loaded state if we're in initial or error state
      final meta = PaginationMeta(
        page: 1,
        pageSize: items.length,
        hasNext: false,
        hasPrevious: false,
      );
      _currentMeta = meta;

      emit(
        SmartPaginationLoaded<T>(
          items: List<T>.from(transformedItems),
          allItems: transformedItems,
          meta: meta,
          hasReachedEnd: true,
          isLoadingMore: false,
          loadMoreError: null,
          fetchedAt: _lastFetchTime,
          dataExpiredAt: _dataAge != null
              ? _lastFetchTime!.add(_dataAge)
              : null,
          lastOperation: const PaginationOperationReload(),
        ),
      );
    }
    return true;
  }

  @override
  Future<bool> refreshItem(
    bool Function(T item) matcher,
    Future<T> Function(T currentItem) refresher,
  ) async {
    final currentState = state;
    if (currentState is! SmartPaginationLoaded<T>) return false;

    final index = currentState.allItems.indexWhere(matcher);
    if (index == -1) return false;

    try {
      final currentItem = currentState.allItems[index];
      final refreshedItem = await refresher(currentItem);

      // Re-check state hasn't changed dramatically during async gap
      final latestState = state;
      if (latestState is! SmartPaginationLoaded<T>) return false;

      final updated = List<T>.from(latestState.allItems);
      // Re-find the item in case list shifted during async gap
      final latestIndex = updated.indexWhere(matcher);
      if (latestIndex == -1) return false;

      // Handle sorting: remove and re-insert if sort is active
      final order = _orders?.activeOrder;
      if (order != null) {
        updated.removeAt(latestIndex);
        final newIndex = _findSortedInsertIndex(
          updated,
          refreshedItem,
          fallbackIndex: latestIndex,
        );
        updated.insert(newIndex, refreshedItem);
      } else {
        updated[latestIndex] = refreshedItem;
      }

      _onInsertionCallback?.call(updated);
      _refreshDataAge();
      emit(
        latestState.copyWith(
          allItems: updated,
          items: updated,
          lastUpdate: DateTime.now(),
          lastOperation: PaginationOperationRefresh(index: latestIndex),
          fetchedAt: _lastFetchTime,
          dataExpiredAt: _getDataExpiredAt(),
        ),
      );
      return true;
    } on Exception catch (e) {
      if (SmartPaginationCubit.enableLogging) {
        _logger.e('Failed to refresh item', error: e);
      }
      return false;
    }
  }

  // ==================== TARGETED DATA OPERATIONS ====================

  @override
  Future<bool> updateFirstWhereEmit(
    bool Function(T item) matcher,
    T Function(T item) updater,
  ) async {
    final currentState = state;
    if (currentState is! SmartPaginationLoaded<T>) return false;

    final updated = List<T>.from(currentState.allItems);
    final index = updated.indexWhere(matcher);

    if (index == -1) return false;

    final updatedItem = updater(updated[index]);

    final order = _orders?.activeOrder;
    if (order != null) {
      updated.removeAt(index);
      final newIndex = _findSortedInsertIndex(
        updated,
        updatedItem,
        fallbackIndex: index,
      );
      updated.insert(newIndex, updatedItem);
    } else {
      updated[index] = updatedItem;
    }

    _onInsertionCallback?.call(updated);
    _refreshDataAge();
    emit(
      currentState.copyWith(
        allItems: updated,
        items: updated,
        lastUpdate: DateTime.now(),
        fetchedAt: _lastFetchTime,
        dataExpiredAt: _getDataExpiredAt(),
        lastOperation: PaginationOperationUpdate(indices: [index]),
      ),
    );
    return true;
  }

  @override
  Future<bool> updateLastWhereEmit(
    bool Function(T item) matcher,
    T Function(T item) updater,
  ) async {
    final currentState = state;
    if (currentState is! SmartPaginationLoaded<T>) return false;

    final updated = List<T>.from(currentState.allItems);
    final index = updated.lastIndexWhere(matcher);

    if (index == -1) return false;

    final updatedItem = updater(updated[index]);

    final order = _orders?.activeOrder;
    if (order != null) {
      updated.removeAt(index);
      final newIndex = _findSortedInsertIndex(
        updated,
        updatedItem,
        fallbackIndex: index,
      );
      updated.insert(newIndex, updatedItem);
    } else {
      updated[index] = updatedItem;
    }

    _onInsertionCallback?.call(updated);
    _refreshDataAge();
    emit(
      currentState.copyWith(
        allItems: updated,
        items: updated,
        lastUpdate: DateTime.now(),
        fetchedAt: _lastFetchTime,
        dataExpiredAt: _getDataExpiredAt(),
        lastOperation: PaginationOperationUpdate(indices: [index]),
      ),
    );
    return true;
  }

  @override
  Future<bool> updateAtEmit(int index, T Function(T item) updater) async {
    final currentState = state;
    if (currentState is! SmartPaginationLoaded<T>) return false;

    final updated = List<T>.from(currentState.allItems);

    if (index < 0 || index >= updated.length) return false;

    final updatedItem = updater(updated[index]);

    final order = _orders?.activeOrder;
    if (order != null) {
      updated.removeAt(index);
      final newIndex = _findSortedInsertIndex(
        updated,
        updatedItem,
        fallbackIndex: index,
      );
      updated.insert(newIndex, updatedItem);
    } else {
      updated[index] = updatedItem;
    }

    _onInsertionCallback?.call(updated);
    _refreshDataAge();
    emit(
      currentState.copyWith(
        allItems: updated,
        items: updated,
        lastUpdate: DateTime.now(),
        fetchedAt: _lastFetchTime,
        dataExpiredAt: _getDataExpiredAt(),
        lastOperation: PaginationOperationUpdate(indices: [index]),
      ),
    );
    return true;
  }

  @override
  Future<bool> replaceFirstWhereEmit(
    bool Function(T item) matcher,
    T replacement,
  ) async {
    final currentState = state;
    if (currentState is! SmartPaginationLoaded<T>) return false;

    final updated = List<T>.from(currentState.allItems);
    final index = updated.indexWhere(matcher);

    if (index == -1) return false;

    final order = _orders?.activeOrder;
    if (order != null) {
      updated.removeAt(index);
      final newIndex = _findSortedInsertIndex(
        updated,
        replacement,
        fallbackIndex: index,
      );
      updated.insert(newIndex, replacement);
    } else {
      updated[index] = replacement;
    }

    _onInsertionCallback?.call(updated);
    _refreshDataAge();
    emit(
      currentState.copyWith(
        allItems: updated,
        items: updated,
        lastUpdate: DateTime.now(),
        fetchedAt: _lastFetchTime,
        dataExpiredAt: _getDataExpiredAt(),
        lastOperation: PaginationOperationUpdate(indices: [index]),
      ),
    );
    return true;
  }

  @override
  Future<bool> replaceLastWhereEmit(
    bool Function(T item) matcher,
    T replacement,
  ) async {
    final currentState = state;
    if (currentState is! SmartPaginationLoaded<T>) return false;

    final updated = List<T>.from(currentState.allItems);
    final index = updated.lastIndexWhere(matcher);

    if (index == -1) return false;

    final order = _orders?.activeOrder;
    if (order != null) {
      updated.removeAt(index);
      final newIndex = _findSortedInsertIndex(
        updated,
        replacement,
        fallbackIndex: index,
      );
      updated.insert(newIndex, replacement);
    } else {
      updated[index] = replacement;
    }

    _onInsertionCallback?.call(updated);
    _refreshDataAge();
    emit(
      currentState.copyWith(
        allItems: updated,
        items: updated,
        lastUpdate: DateTime.now(),
        fetchedAt: _lastFetchTime,
        dataExpiredAt: _getDataExpiredAt(),
        lastOperation: PaginationOperationUpdate(indices: [index]),
      ),
    );
    return true;
  }

  @override
  Future<bool> replaceAtEmit(int index, T replacement) async {
    final currentState = state;
    if (currentState is! SmartPaginationLoaded<T>) return false;

    final updated = List<T>.from(currentState.allItems);

    if (index < 0 || index >= updated.length) return false;

    final order = _orders?.activeOrder;
    if (order != null) {
      updated.removeAt(index);
      final newIndex = _findSortedInsertIndex(
        updated,
        replacement,
        fallbackIndex: index,
      );
      updated.insert(newIndex, replacement);
    } else {
      updated[index] = replacement;
    }

    _onInsertionCallback?.call(updated);
    _refreshDataAge();
    emit(
      currentState.copyWith(
        allItems: updated,
        items: updated,
        lastUpdate: DateTime.now(),
        fetchedAt: _lastFetchTime,
        dataExpiredAt: _getDataExpiredAt(),
        lastOperation: PaginationOperationUpdate(indices: [index]),
      ),
    );
    return true;
  }

  @override
  Future<bool> refreshFirstWhereEmit(
    bool Function(T item) matcher,
    Future<T> Function(T currentItem) refresher,
  ) async {
    final currentState = state;
    if (currentState is! SmartPaginationLoaded<T>) return false;

    final index = currentState.allItems.indexWhere(matcher);
    if (index == -1) return false;

    try {
      final currentItem = currentState.allItems[index];
      final refreshedItem = await refresher(currentItem);

      final latestState = state;
      if (latestState is! SmartPaginationLoaded<T>) return false;

      final updated = List<T>.from(latestState.allItems);
      final latestIndex = updated.indexWhere(matcher);
      if (latestIndex == -1) return false;

      final order = _orders?.activeOrder;
      if (order != null) {
        updated.removeAt(latestIndex);
        final newIndex = _findSortedInsertIndex(
          updated,
          refreshedItem,
          fallbackIndex: latestIndex,
        );
        updated.insert(newIndex, refreshedItem);
      } else {
        updated[latestIndex] = refreshedItem;
      }

      _onInsertionCallback?.call(updated);
      _refreshDataAge();
      emit(
        latestState.copyWith(
          allItems: updated,
          items: updated,
          lastUpdate: DateTime.now(),
          lastOperation: PaginationOperationRefresh(index: latestIndex),
          fetchedAt: _lastFetchTime,
          dataExpiredAt: _getDataExpiredAt(),
        ),
      );
      return true;
    } on Exception catch (e) {
      if (SmartPaginationCubit.enableLogging) {
        _logger.e('Failed to refresh first item', error: e);
      }
      return false;
    }
  }

  @override
  Future<bool> refreshLastWhereEmit(
    bool Function(T item) matcher,
    Future<T> Function(T currentItem) refresher,
  ) async {
    final currentState = state;
    if (currentState is! SmartPaginationLoaded<T>) return false;

    final index = currentState.allItems.lastIndexWhere(matcher);
    if (index == -1) return false;

    try {
      final currentItem = currentState.allItems[index];
      final refreshedItem = await refresher(currentItem);

      final latestState = state;
      if (latestState is! SmartPaginationLoaded<T>) return false;

      final updated = List<T>.from(latestState.allItems);
      final latestIndex = updated.lastIndexWhere(matcher);
      if (latestIndex == -1) return false;

      final order = _orders?.activeOrder;
      if (order != null) {
        updated.removeAt(latestIndex);
        final newIndex = _findSortedInsertIndex(
          updated,
          refreshedItem,
          fallbackIndex: latestIndex,
        );
        updated.insert(newIndex, refreshedItem);
      } else {
        updated[latestIndex] = refreshedItem;
      }

      _onInsertionCallback?.call(updated);
      _refreshDataAge();
      emit(
        latestState.copyWith(
          allItems: updated,
          items: updated,
          lastUpdate: DateTime.now(),
          lastOperation: PaginationOperationRefresh(index: latestIndex),
          fetchedAt: _lastFetchTime,
          dataExpiredAt: _getDataExpiredAt(),
        ),
      );
      return true;
    } on Exception catch (e) {
      if (SmartPaginationCubit.enableLogging) {
        _logger.e('Failed to refresh last item', error: e);
      }
      return false;
    }
  }

  @override
  Future<bool> refreshAtEmit(
    int index,
    Future<T> Function(T currentItem) refresher,
  ) async {
    final currentState = state;
    if (currentState is! SmartPaginationLoaded<T>) return false;

    if (index < 0 || index >= currentState.allItems.length) return false;

    try {
      final currentItem = currentState.allItems[index];
      final refreshedItem = await refresher(currentItem);

      final latestState = state;
      if (latestState is! SmartPaginationLoaded<T>) return false;

      if (index >= latestState.allItems.length) return false;

      final updated = List<T>.from(latestState.allItems);

      final order = _orders?.activeOrder;
      if (order != null) {
        updated.removeAt(index);
        final newIndex = _findSortedInsertIndex(
          updated,
          refreshedItem,
          fallbackIndex: index,
        );
        updated.insert(newIndex, refreshedItem);
      } else {
        updated[index] = refreshedItem;
      }

      _onInsertionCallback?.call(updated);
      _refreshDataAge();
      emit(
        latestState.copyWith(
          allItems: updated,
          items: updated,
          lastUpdate: DateTime.now(),
          lastOperation: PaginationOperationRefresh(index: index),
          fetchedAt: _lastFetchTime,
          dataExpiredAt: _getDataExpiredAt(),
        ),
      );
      return true;
    } on Exception catch (e) {
      if (SmartPaginationCubit.enableLogging) {
        _logger.e('Failed to refresh item at index $index', error: e);
      }
      return false;
    }
  }

  @override
  Future<bool> removeFirstWhereEmit(bool Function(T item) test) async {
    final currentState = state;
    if (currentState is! SmartPaginationLoaded<T>) return false;

    final updated = List<T>.from(currentState.allItems);
    final index = updated.indexWhere(test);

    if (index == -1) return false;

    updated.removeAt(index);

    _onInsertionCallback?.call(updated);
    _refreshDataAge();
    emit(
      currentState.copyWith(
        allItems: updated,
        items: updated,
        lastUpdate: DateTime.now(),
        fetchedAt: _lastFetchTime,
        dataExpiredAt: _getDataExpiredAt(),
        lastOperation: PaginationOperationRemove(index: index),
      ),
    );
    return true;
  }

  @override
  Future<bool> removeLastWhereEmit(bool Function(T item) test) async {
    final currentState = state;
    if (currentState is! SmartPaginationLoaded<T>) return false;

    final updated = List<T>.from(currentState.allItems);
    final index = updated.lastIndexWhere(test);

    if (index == -1) return false;

    updated.removeAt(index);

    _onInsertionCallback?.call(updated);
    _refreshDataAge();
    emit(
      currentState.copyWith(
        allItems: updated,
        items: updated,
        lastUpdate: DateTime.now(),
        fetchedAt: _lastFetchTime,
        dataExpiredAt: _getDataExpiredAt(),
        lastOperation: PaginationOperationRemove(index: index),
      ),
    );
    return true;
  }

  // ==================== SCROLL NAVIGATION ====================

  /// The attached list observer controller for scroll navigation.
  ListObserverController? _listObserverController;

  /// The attached grid observer controller for scroll navigation.
  GridObserverController? _gridObserverController;

  /// Returns the attached list observer controller, if available.
  ListObserverController? get listObserverController => _listObserverController;

  /// Returns the attached grid observer controller, if available.
  GridObserverController? get gridObserverController => _gridObserverController;

  /// Returns true if a list observer controller is attached.
  bool get hasListObserverController => _listObserverController != null;

  /// Returns true if a grid observer controller is attached.
  bool get hasGridObserverController => _gridObserverController != null;

  /// Returns true if any observer controller is attached.
  bool get hasObserverController =>
      _listObserverController != null || _gridObserverController != null;

  /// Attaches a [ListObserverController] for scroll navigation.
  ///
  /// This must be called before using [animateToIndex], [jumpToIndex],
  /// [animateFirstWhere], or [jumpFirstWhere] with list views.
  ///
  /// Example:
  /// ```dart
  /// final observerController = ListObserverController(controller: scrollController);
  /// cubit.attachListObserverController(observerController);
  /// ```
  void attachListObserverController(ListObserverController controller) {
    _listObserverController = controller;
  }

  /// Attaches a [GridObserverController] for scroll navigation.
  ///
  /// This must be called before using [animateToIndex], [jumpToIndex],
  /// [animateFirstWhere], or [jumpFirstWhere] with grid views.
  ///
  /// Example:
  /// ```dart
  /// final observerController = GridObserverController(controller: scrollController);
  /// cubit.attachGridObserverController(observerController);
  /// ```
  void attachGridObserverController(GridObserverController controller) {
    _gridObserverController = controller;
    if (SmartPaginationCubit.enableLogging) {
      _logger.d('GridObserverController attached');
    }
  }

  /// Detaches the list observer controller.
  void detachListObserverController() {
    _listObserverController = null;
    if (SmartPaginationCubit.enableLogging) {
      _logger.d('ListObserverController detached');
    }
  }

  /// Detaches the grid observer controller.
  void detachGridObserverController() {
    _gridObserverController = null;
    if (SmartPaginationCubit.enableLogging) {
      _logger.d('GridObserverController detached');
    }
  }

  /// Detaches all observer controllers.
  void detachAllObserverControllers() {
    _listObserverController = null;
    _gridObserverController = null;
    if (SmartPaginationCubit.enableLogging) {
      _logger.d('All observer controllers detached');
    }
  }

  /// Animates to the item at the given [index] with smooth scrolling.
  ///
  /// The [duration] defaults to 300ms. The [curve] defaults to [Curves.easeInOut].
  /// The [alignment] determines where the item should be positioned in the viewport
  /// (0.0 = top/left, 0.5 = center, 1.0 = bottom/right).
  ///
  /// Returns a [Future] that completes when the animation finishes.
  /// Returns `false` if no observer controller is attached or the index is out of bounds.
  ///
  /// Example:
  /// ```dart
  /// await cubit.animateToIndex(10);
  /// await cubit.animateToIndex(5, duration: Duration(milliseconds: 500));
  /// await cubit.animateToIndex(0, alignment: 0.5); // Center the item
  /// ```
  Future<bool> animateToIndex(
    int index, {
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
    double alignment = 0.0,
    EdgeInsets padding = EdgeInsets.zero,
    BuildContext? sliverContext,
    bool isFixedHeight = false,
  }) async {
    // Validate index
    final items = currentItems;
    if (index < 0 || index >= items.length) {
      if (SmartPaginationCubit.enableLogging) {
        _logger.w(
          'animateToIndex: index $index out of bounds (0-${items.length - 1})',
        );
      }
      return false;
    }

    try {
      if (_listObserverController != null) {
        await _listObserverController!.animateTo(
          index: index,
          duration: duration,
          curve: curve,
          alignment: alignment,
          padding: padding,
          sliverContext: sliverContext,
          isFixedHeight: isFixedHeight,
        );
        if (SmartPaginationCubit.enableLogging) {
          _logger.d('Animated to index $index');
        }
        return true;
      }

      if (_gridObserverController != null) {
        await _gridObserverController!.animateTo(
          index: index,
          duration: duration,
          curve: curve,
          alignment: alignment,
          padding: padding,
          sliverContext: sliverContext,
          isFixedHeight: isFixedHeight,
        );
        if (SmartPaginationCubit.enableLogging) {
          _logger.d('Animated to index $index (grid)');
        }
        return true;
      }

      if (SmartPaginationCubit.enableLogging) {
        _logger.w('animateToIndex: no observer controller attached');
      }
      return false;
    } catch (e, stackTrace) {
      if (SmartPaginationCubit.enableLogging) {
        _logger.e('animateToIndex failed', error: e, stackTrace: stackTrace);
      }
      return false;
    }
  }

  /// Jumps immediately to the item at the given [index] without animation.
  ///
  /// The [alignment] determines where the item should be positioned in the viewport
  /// (0.0 = top/left, 0.5 = center, 1.0 = bottom/right).
  ///
  /// Returns `true` if successful, `false` if no observer controller is attached
  /// or the index is out of bounds.
  ///
  /// Example:
  /// ```dart
  /// cubit.jumpToIndex(10);
  /// cubit.jumpToIndex(0, alignment: 0.5); // Center the item
  /// ```
  bool jumpToIndex(
    int index, {
    double alignment = 0.0,
    EdgeInsets padding = EdgeInsets.zero,
    BuildContext? sliverContext,
    bool isFixedHeight = false,
  }) {
    // Validate index
    final items = currentItems;
    if (index < 0 || index >= items.length) {
      if (SmartPaginationCubit.enableLogging) {
        _logger.w(
          'jumpToIndex: index $index out of bounds (0-${items.length - 1})',
        );
      }
      return false;
    }

    try {
      if (_listObserverController != null) {
        _listObserverController!.jumpTo(
          index: index,
          alignment: alignment,
          padding: padding,
          sliverContext: sliverContext,
          isFixedHeight: isFixedHeight,
        );
        if (SmartPaginationCubit.enableLogging) {
          _logger.d('Jumped to index $index');
        }
        return true;
      }

      if (_gridObserverController != null) {
        _gridObserverController!.jumpTo(
          index: index,
          alignment: alignment,
          padding: padding,
          sliverContext: sliverContext,
          isFixedHeight: isFixedHeight,
        );
        if (SmartPaginationCubit.enableLogging) {
          _logger.d('Jumped to index $index (grid)');
        }
        return true;
      }

      if (SmartPaginationCubit.enableLogging) {
        _logger.w('jumpToIndex: no observer controller attached');
      }
      return false;
    } catch (e, stackTrace) {
      if (SmartPaginationCubit.enableLogging) {
        _logger.e('jumpToIndex failed', error: e, stackTrace: stackTrace);
      }
      return false;
    }
  }

  /// Animates to the first item matching the given [test] function.
  ///
  /// The [duration] defaults to 300ms. The [curve] defaults to [Curves.easeInOut].
  /// The [alignment] determines where the item should be positioned in the viewport
  /// (0.0 = top/left, 0.5 = center, 1.0 = bottom/right).
  ///
  /// Returns a [Future] that completes with `true` if a matching item was found
  /// and scrolled to, or `false` if no match was found or no controller is attached.
  ///
  /// Example:
  /// ```dart
  /// await cubit.animateFirstWhere((item) => item.id == targetId);
  /// await cubit.animateFirstWhere(
  ///   (item) => item.name.contains('search'),
  ///   duration: Duration(milliseconds: 500),
  /// );
  /// ```
  Future<bool> animateFirstWhere(
    bool Function(T item) test, {
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
    double alignment = 0.0,
    EdgeInsets padding = EdgeInsets.zero,
    BuildContext? sliverContext,
    bool isFixedHeight = false,
  }) async {
    final items = currentItems;
    final index = items.indexWhere(test);

    if (index == -1) {
      if (SmartPaginationCubit.enableLogging) {
        _logger.d('animateFirstWhere: no matching item found');
      }
      return false;
    }

    return animateToIndex(
      index,
      duration: duration,
      curve: curve,
      alignment: alignment,
      padding: padding,
      sliverContext: sliverContext,
      isFixedHeight: isFixedHeight,
    );
  }

  /// Jumps immediately to the first item matching the given [test] function.
  ///
  /// The [alignment] determines where the item should be positioned in the viewport
  /// (0.0 = top/left, 0.5 = center, 1.0 = bottom/right).
  ///
  /// Returns `true` if a matching item was found and scrolled to, or `false`
  /// if no match was found or no controller is attached.
  ///
  /// Example:
  /// ```dart
  /// cubit.jumpFirstWhere((item) => item.id == targetId);
  /// cubit.jumpFirstWhere((item) => item.isHighlighted, alignment: 0.5);
  /// ```
  bool jumpFirstWhere(
    bool Function(T item) test, {
    double alignment = 0.0,
    EdgeInsets padding = EdgeInsets.zero,
    BuildContext? sliverContext,
    bool isFixedHeight = false,
  }) {
    final items = currentItems;
    final index = items.indexWhere(test);

    if (index == -1) {
      if (SmartPaginationCubit.enableLogging) {
        _logger.d('jumpFirstWhere: no matching item found');
      }
      return false;
    }

    return jumpToIndex(
      index,
      alignment: alignment,
      padding: padding,
      sliverContext: sliverContext,
      isFixedHeight: isFixedHeight,
    );
  }

  /// Scrolls to make the item at [index] visible, using animation if [animate] is true.
  ///
  /// This is a convenience method that calls either [animateToIndex] or [jumpToIndex]
  /// based on the [animate] parameter.
  ///
  /// Example:
  /// ```dart
  /// await cubit.scrollToIndex(10, animate: true);
  /// cubit.scrollToIndex(0, animate: false);
  /// ```
  Future<bool> scrollToIndex(
    int index, {
    bool animate = true,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
    double alignment = 0.0,
    EdgeInsets padding = EdgeInsets.zero,
    BuildContext? sliverContext,
    bool isFixedHeight = false,
  }) async {
    if (animate) {
      return animateToIndex(
        index,
        duration: duration,
        curve: curve,
        alignment: alignment,
        padding: padding,
        sliverContext: sliverContext,
        isFixedHeight: isFixedHeight,
      );
    } else {
      return jumpToIndex(
        index,
        alignment: alignment,
        padding: padding,
        sliverContext: sliverContext,
        isFixedHeight: isFixedHeight,
      );
    }
  }

  /// Scrolls to the first item matching [test], using animation if [animate] is true.
  ///
  /// This is a convenience method that calls either [animateFirstWhere] or [jumpFirstWhere]
  /// based on the [animate] parameter.
  ///
  /// Example:
  /// ```dart
  /// await cubit.scrollFirstWhere((item) => item.id == targetId, animate: true);
  /// cubit.scrollFirstWhere((item) => item.isNew, animate: false);
  /// ```
  Future<bool> scrollFirstWhere(
    bool Function(T item) test, {
    bool animate = true,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
    double alignment = 0.0,
    EdgeInsets padding = EdgeInsets.zero,
    BuildContext? sliverContext,
    bool isFixedHeight = false,
  }) async {
    if (animate) {
      return animateFirstWhere(
        test,
        duration: duration,
        curve: curve,
        alignment: alignment,
        padding: padding,
        sliverContext: sliverContext,
        isFixedHeight: isFixedHeight,
      );
    } else {
      return jumpFirstWhere(
        test,
        alignment: alignment,
        padding: padding,
        sliverContext: sliverContext,
        isFixedHeight: isFixedHeight,
      );
    }
  }

  // ==================== END SCROLL NAVIGATION ====================
}
