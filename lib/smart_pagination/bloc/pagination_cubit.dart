part of '../../pagination.dart';

/// Strategy for handling automatic retry on error.
enum ErrorRetryStrategy {
  /// Automatically retry on next fetch call (default behavior).
  automatic,

  /// Don't retry automatically. Requires explicit call to [retryAfterError].
  manual,

  /// Don't retry at all. The error state persists until [refreshPaginatedList] is called.
  none,
}

class SmartPaginationCubit<T>
    extends IPaginationListCubit<T, SmartPaginationState<T>> {
  SmartPaginationCubit({
    required PaginationRequest request,
    required PaginationProvider<T> provider,
    ListBuilder<T>? listBuilder,
    OnInsertionCallback<T>? onInsertionCallback,
    VoidCallback? onClear,
    int maxPagesInMemory = 5,
    Logger? logger,
    RetryConfig? retryConfig,
    Duration? dataAge,
    SortOrderCollection<T>? orders,
    this.errorRetryStrategy = ErrorRetryStrategy.automatic,
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
       super(SmartPaginationInitial<T>());

  final PaginationProvider<T> _provider;
  final ListBuilder<T>? _listBuilder;
  final OnInsertionCallback<T>? _onInsertionCallback;
  final VoidCallback? _onClear;
  final int _maxPagesInMemory;
  final Logger _logger;
  final RetryHandler? _retryHandler;
  final Duration? _dataAge;
  SortOrderCollection<T>? _orders;

  /// Strategy for handling automatic retry when an error occurs.
  final ErrorRetryStrategy errorRetryStrategy;

  @override
  final PaginationRequest initialRequest;

  PaginationRequest _currentRequest;
  PaginationMeta? _currentMeta;
  final List<List<T>> _pages = <List<T>>[];
  StreamSubscription<List<T>>? _streamSubscription;
  int _fetchToken = 0;
  DateTime? _lastFetchTime;

  /// Flag to prevent concurrent fetch operations.
  bool _isFetching = false;

  /// Flag to track if the last fetch resulted in an error.
  /// Used by [errorRetryStrategy] to prevent automatic retries.
  bool _lastFetchWasError = false;

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
      _logger.w('Cannot set active order: no orders collection configured');
      return false;
    }

    if (_orders!.setActiveOrder(orderId)) {
      _logger.d('Active sort order changed to: $orderId');
      _applySortingToCurrentState();
      return true;
    }

    _logger.w('Sort order not found: $orderId');
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
    _logger.d('Sort order reset to default: ${_orders!.defaultOrderId}');
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
    _logger.d('Sort order cleared');
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
    _logger.d('Sort order added: ${order.id}');
  }

  /// Removes a sort order from the collection.
  ///
  /// Returns true if the order was found and removed, false otherwise.
  bool removeSortOrder(String orderId) {
    if (_orders == null) return false;

    if (_orders!.removeOrder(orderId)) {
      _logger.d('Sort order removed: $orderId');
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
  int _findSortedInsertIndex(List<T> sortedList, T item, {int fallbackIndex = 0}) {
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
      _logger.d('Data expired after $_dataAge, resetting pagination');
      _resetToInitial();
      return true;
    }
    return false;
  }

  /// Resets the cubit to its initial state, clearing all data.
  void _resetToInitial() {
    cancelOngoingRequest();
    _streamSubscription?.cancel();
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
        ),
      );
      return;
    }

    final filtered = currentState.allItems.where(searchTerm).toList();
    _logger.d(
      'Applied pagination filter ${currentState.allItems.length} -> ${filtered.length}',
    );
    emit(currentState.copyWith(items: filtered, lastUpdate: DateTime.now()));
  }

  @override
  void refreshPaginatedList({PaginationRequest? requestOverride, int? limit}) {
    // Cancel any ongoing request
    cancelOngoingRequest();
    _streamSubscription?.cancel();
    _onClear?.call();
    didFetch = false;
    _pages.clear();
    _currentMeta = null;

    // Clear error state on refresh
    _lastFetchWasError = false;
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
      _logger.d('retryAfterError called but there is no error to retry');
      return;
    }

    _logger.d('Retrying after error...');
    _lastFetchWasError = false;
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
    _lastError = null;

    final currentState = state;
    if (currentState is SmartPaginationLoaded<T> && currentState.loadMoreError != null) {
      emit(currentState.copyWith(loadMoreError: null));
    }
  }

  @override
  void fetchPaginatedList({PaginationRequest? requestOverride, int? limit}) {
    // Prevent concurrent fetch operations
    if (_isFetching) {
      _logger.d('Fetch already in progress, skipping duplicate request');
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
          _logger.d('Error retry strategy is manual, skipping automatic retry. Call retryAfterError() to retry.');
          return;
        case ErrorRetryStrategy.none:
          // Don't retry at all
          _logger.d('Error retry strategy is none, skipping retry. Call refreshPaginatedList() to reset.');
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

    // Set isLoadingMore = true when loading more items
    final currentState = state;
    if (currentState is SmartPaginationLoaded<T>) {
      if (currentState.isLoadingMore) return; // Already loading

      emit(
        currentState.copyWith(
          isLoadingMore: true,
          loadMoreError: null, // Clear any previous error
        ),
      );
    }

    final request = _buildRequest(
      reset: false,
      override: requestOverride,
      limit: limit,
    );
    _fetch(request: request, reset: false);
  }

  Future<void> _fetch({
    required PaginationRequest request,
    required bool reset,
  }) async {
    // Set fetching flag to prevent concurrent requests
    _isFetching = true;
    final token = ++_fetchToken;

    try {
      // Fetch data based on provider type
      final pageItems = await switch (_provider) {
        FuturePaginationProvider<T>(:final dataProvider) => _retryHandler != null
            ? _retryHandler.execute(
                () => dataProvider(request),
                onRetry: (attempt, error) {
                  _logger.w('Retry attempt $attempt after error: $error');
                },
              )
            : dataProvider(request),
        StreamPaginationProvider<T>(:final streamProvider) => streamProvider(request).first,
        MergedStreamPaginationProvider<T> provider => provider.getMergedStream(request).first,
      };

      // Check if request was cancelled
      if (token != _fetchToken) {
        _isFetching = false;
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

      if (reset) {
        _pages
          ..clear()
          ..add(pageItems);
      } else {
        _pages.add(pageItems);
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
        ),
      );

      // Attach stream if it's a stream provider and this is initial load
      if (reset) {
        if (_provider is StreamPaginationProvider<T>) {
          final streamProvider = _provider;
          _attachStream(streamProvider.streamProvider(request), request);
        } else if (_provider is MergedStreamPaginationProvider<T>) {
          final mergedProvider = _provider;
          _attachStream(mergedProvider.getMergedStream(request), request);
        }
      }
    } on Exception catch (error, stackTrace) {
      _logger.e(
        'Pagination request failed',
        error: error,
        stackTrace: stackTrace,
      );

      // Set error state
      _lastFetchWasError = true;
      _lastError = error;

      // Handle load more errors differently
      if (!reset && state is SmartPaginationLoaded<T>) {
        final currentState = state as SmartPaginationLoaded<T>;
        emit(
          currentState.copyWith(
            isLoadingMore: false,
            loadMoreError: error,
          ),
        );
      } else {
        emit(SmartPaginationError<T>(error: error));
      }
    } catch (error, stackTrace) {
      final exception = Exception(error.toString());
      _logger.e(
        'Pagination request failed',
        error: exception,
        stackTrace: stackTrace,
      );

      // Set error state
      _lastFetchWasError = true;
      _lastError = exception;

      // Handle load more errors differently
      if (!reset && state is SmartPaginationLoaded<T>) {
        final currentState = state as SmartPaginationLoaded<T>;
        emit(
          currentState.copyWith(
            isLoadingMore: false,
            loadMoreError: exception,
          ),
        );
      } else {
        emit(SmartPaginationError<T>(error: exception));
      }
    } finally {
      // Always clear the fetching flag
      _isFetching = false;
    }
  }

  PaginationRequest _buildRequest({
    required bool reset,
    PaginationRequest? override,
    int? limit,
  }) {
    final base = override ?? (reset ? initialRequest : _currentRequest);
    final pageSize = limit ?? base.pageSize ?? initialRequest.pageSize;
    final nextPage = reset ? 1 : base.page + 1;

    return base.copyWith(page: nextPage, pageSize: pageSize);
  }

  bool _computeHasNext(List<T> items, int? pageSize) {
    if (pageSize == null) {
      return items.isNotEmpty;
    }
    return items.length >= pageSize;
  }

  void _attachStream(Stream<List<T>> stream, PaginationRequest request) {
    _streamSubscription?.cancel();
    _streamSubscription = stream.listen(
      (items) {
        final aggregated = _applyListBuilder(items);
        final sortedItems = _applySorting(aggregated);
        _onInsertionCallback?.call(sortedItems);

        final meta = PaginationMeta(
          page: request.page,
          pageSize: request.pageSize,
          hasNext: _computeHasNext(items, request.pageSize),
          hasPrevious: request.page > 1,
        );
        _currentMeta = meta;

        emit(
          SmartPaginationLoaded<T>(
            items: List<T>.from(sortedItems),
            allItems: sortedItems,
            meta: meta,
            hasReachedEnd: !meta.hasNext,
            isLoadingMore: false,
            loadMoreError: null,
            fetchedAt: _lastFetchTime,
            dataExpiredAt: _dataAge != null && _lastFetchTime != null
                ? _lastFetchTime!.add(_dataAge)
                : null,
            activeOrderId: _orders?.activeOrderId,
          ),
        );
      },
      onError: (error, stack) {
        final exception =
            error is Exception ? error : Exception(error.toString());
        _logger.e(
          'Pagination stream failed',
          error: exception,
          stackTrace: stack,
        );
        emit(SmartPaginationError<T>(error: exception));
      },
    );
  }

  List<T> _applyListBuilder(List<T> items) {
    return _listBuilder?.call(items) ?? items;
  }

  void _trimCachedPages() {
    if (_maxPagesInMemory <= 0) return;
    while (_pages.length > _maxPagesInMemory) {
      _pages.removeAt(0);
    }
  }

  @override
  void cancelOngoingRequest() {
    _fetchToken++;
    _isFetching = false;
  }

  @override
  void dispose() {
    cancelOngoingRequest();
    _streamSubscription?.cancel();
    _streamSubscription = null;
  }

  @override
  void insertEmit(T item, {int index = 0}) {
    final currentState = state;
    if (currentState is! SmartPaginationLoaded<T>) return;

    final updated = List<T>.from(currentState.allItems);

    // Use sorted insertion if sorting is active, otherwise use the provided index
    final insertIndex = _findSortedInsertIndex(updated, item, fallbackIndex: index);
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
      ),
    );
  }

  @override
  void addOrUpdateEmit(T item, {int index = 0}) {
    final currentState = state;
    if (currentState is! SmartPaginationLoaded<T>) return;

    final updated = List<T>.from(currentState.allItems);
    final existingIndex = updated.indexWhere((element) => element == item);

    if (existingIndex != -1) {
      // Update existing item - if sorting is active, may need to reposition
      final order = _orders?.activeOrder;
      if (order != null) {
        // Remove and re-insert at correct sorted position
        updated.removeAt(existingIndex);
        final newIndex = _findSortedInsertIndex(updated, item, fallbackIndex: existingIndex);
        updated.insert(newIndex, item);
      } else {
        // No sorting, just update in place
        updated[existingIndex] = item;
      }
    } else {
      // New item - use sorted insertion if sorting is active
      final insertIndex = _findSortedInsertIndex(updated, item, fallbackIndex: index);
      updated.insert(insertIndex, item);
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
      ),
    );
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
  void insertAllEmit(List<T> items, {int index = 0}) {
    final currentState = state;
    if (currentState is! SmartPaginationLoaded<T>) return;

    if (items.isEmpty) return;

    final currentItems = List<T>.from(currentState.allItems);

    // Use efficient merge if sorting is active, otherwise use simple insertAll
    final updated = _orders?.activeOrder != null
        ? _insertAllSorted(currentItems, items)
        : (List<T>.from(currentItems)..insertAll(index.clamp(0, currentItems.length), items));

    _onInsertionCallback?.call(updated);

    _refreshDataAge();
    emit(
      currentState.copyWith(
        allItems: updated,
        items: updated,
        lastUpdate: DateTime.now(),
        fetchedAt: _lastFetchTime,
        dataExpiredAt: _getDataExpiredAt(),
      ),
    );
  }

  @override
  bool removeItemEmit(T item) {
    final currentState = state;
    if (currentState is! SmartPaginationLoaded<T>) return false;

    final updated = List<T>.from(currentState.allItems);
    final removed = updated.remove(item);

    if (!removed) return false;

    _onInsertionCallback?.call(updated);

    _refreshDataAge();
    emit(
      currentState.copyWith(
        allItems: updated,
        items: updated,
        lastUpdate: DateTime.now(),
        fetchedAt: _lastFetchTime,
        dataExpiredAt: _getDataExpiredAt(),
      ),
    );
    return true;
  }

  @override
  T? removeAtEmit(int index) {
    final currentState = state;
    if (currentState is! SmartPaginationLoaded<T>) return null;

    final updated = List<T>.from(currentState.allItems);

    if (index < 0 || index >= updated.length) return null;

    final removedItem = updated.removeAt(index);

    _onInsertionCallback?.call(updated);

    _refreshDataAge();
    emit(
      currentState.copyWith(
        allItems: updated,
        items: updated,
        lastUpdate: DateTime.now(),
        fetchedAt: _lastFetchTime,
        dataExpiredAt: _getDataExpiredAt(),
      ),
    );
    return removedItem;
  }

  @override
  int removeWhereEmit(bool Function(T item) test) {
    final currentState = state;
    if (currentState is! SmartPaginationLoaded<T>) return 0;

    final updated = List<T>.from(currentState.allItems);
    final originalLength = updated.length;
    updated.removeWhere(test);
    final removedCount = originalLength - updated.length;

    if (removedCount == 0) return 0;

    _onInsertionCallback?.call(updated);

    _refreshDataAge();
    emit(
      currentState.copyWith(
        allItems: updated,
        items: updated,
        lastUpdate: DateTime.now(),
        fetchedAt: _lastFetchTime,
        dataExpiredAt: _getDataExpiredAt(),
      ),
    );
    return removedCount;
  }

  @override
  bool updateItemEmit(
      bool Function(T item) matcher, T Function(T item) updater) {
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
      final newIndex = _findSortedInsertIndex(updated, updatedItem, fallbackIndex: index);
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
      ),
    );
    return true;
  }

  @override
  int updateWhereEmit(
      bool Function(T item) matcher, T Function(T item) updater) {
    final currentState = state;
    if (currentState is! SmartPaginationLoaded<T>) return 0;

    final updated = List<T>.from(currentState.allItems);
    final order = _orders?.activeOrder;
    var updateCount = 0;

    if (order != null) {
      // Collect items to update
      final itemsToUpdate = <T>[];
      final indicesToRemove = <int>[];

      for (var i = 0; i < updated.length; i++) {
        if (matcher(updated[i])) {
          itemsToUpdate.add(updater(updated[i]));
          indicesToRemove.add(i);
          updateCount++;
        }
      }

      if (updateCount == 0) return 0;

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
          updateCount++;
        }
      }

      if (updateCount == 0) return 0;
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
      ),
    );
    return updateCount;
  }

  @override
  void clearItems() {
    final currentState = state;
    if (currentState is! SmartPaginationLoaded<T>) return;

    _pages.clear();
    _onClear?.call();

    emit(
      currentState.copyWith(
        allItems: <T>[],
        items: <T>[],
        hasReachedEnd: true,
        lastUpdate: DateTime.now(),
      ),
    );
  }

  @override
  void reload() {
    refreshPaginatedList();
  }

  @override
  void setItems(List<T> items) {
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
          dataExpiredAt: _dataAge != null ? _lastFetchTime!.add(_dataAge) : null,
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
          dataExpiredAt: _dataAge != null ? _lastFetchTime!.add(_dataAge) : null,
        ),
      );
    }
  }
}
