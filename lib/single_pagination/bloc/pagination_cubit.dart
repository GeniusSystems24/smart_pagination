part of '../pagination.dart';

class SinglePaginationCubit<T>
    extends IPaginationListCubit<T, SinglePaginationState<T>> {
  SinglePaginationCubit({
    required PaginationRequest request,
    required PaginationProvider<T> provider,
    ListBuilder<T>? listBuilder,
    OnInsertionCallback<T>? onInsertionCallback,
    VoidCallback? onClear,
    int maxPagesInMemory = 5,
    Logger? logger,
    RetryConfig? retryConfig,
  }) : _provider = provider,
       _listBuilder = listBuilder,
       _onInsertionCallback = onInsertionCallback,
       _onClear = onClear,
       _maxPagesInMemory = maxPagesInMemory,
       _logger = logger ?? Logger(),
       _retryHandler = retryConfig != null ? RetryHandler(retryConfig) : null,
       initialRequest = request,
       _currentRequest = request,
       super(SinglePaginationInitial<T>());

  final PaginationProvider<T> _provider;
  final ListBuilder<T>? _listBuilder;
  final OnInsertionCallback<T>? _onInsertionCallback;
  final VoidCallback? _onClear;
  final int _maxPagesInMemory;
  final Logger _logger;
  final RetryHandler? _retryHandler;

  @override
  final PaginationRequest initialRequest;

  PaginationRequest _currentRequest;
  PaginationMeta? _currentMeta;
  final List<List<T>> _pages = <List<T>>[];
  StreamSubscription<List<T>>? _streamSubscription;
  int _fetchToken = 0;

  @override
  bool didFetch = false;

  bool get _hasReachedEnd => _currentMeta != null && !_currentMeta!.hasNext;

  @override
  ListBuilder<T>? get listBuilder => _listBuilder;

  @override
  void filterPaginatedList(WhereChecker<T>? searchTerm) {
    final currentState = state;
    if (currentState is! SinglePaginationLoaded<T>) return;

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
    cancelOngoingRequest();
    _streamSubscription?.cancel();
    _onClear?.call();
    didFetch = false;
    _pages.clear();
    _currentMeta = null;

    final request = _buildRequest(
      reset: true,
      override: requestOverride,
      limit: limit,
    );
    _fetch(request: request, reset: true);
  }

  @override
  void fetchPaginatedList({PaginationRequest? requestOverride, int? limit}) {
    if (state is SinglePaginationInitial<T>) {
      refreshPaginatedList(requestOverride: requestOverride, limit: limit);
      return;
    }

    if (_hasReachedEnd) return;

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
    final token = ++_fetchToken;

    try {
      // Fetch data based on provider type
      final pageItems = await switch (_provider) {
        FuturePaginationProvider<T>(:final dataProvider) => _retryHandler != null
            ? _retryHandler!.execute(
                () => dataProvider(request),
                onRetry: (attempt, error) {
                  _logger.w('Retry attempt $attempt after error: $error');
                },
              )
            : dataProvider(request),
        StreamPaginationProvider<T>(:final streamProvider) => streamProvider(request).first,
        MergedStreamPaginationProvider<T> provider => provider.getMergedStream(request).first,
      };

      if (token != _fetchToken) return;

      didFetch = true;
      _currentRequest = request;

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
      final hasNext = _computeHasNext(pageItems, request.pageSize);
      final meta = PaginationMeta(
        page: request.page,
        pageSize: request.pageSize,
        hasNext: hasNext,
        hasPrevious: request.page > 1,
      );
      _currentMeta = meta;

      _onInsertionCallback?.call(aggregated);

      emit(
        SinglePaginationLoaded<T>(
          items: List<T>.from(aggregated),
          allItems: aggregated,
          meta: meta,
          hasReachedEnd: !hasNext,
        ),
      );

      // Attach stream if it's a stream provider and this is initial load
      if (reset) {
        if (_provider is StreamPaginationProvider<T>) {
          final streamProvider = _provider as StreamPaginationProvider<T>;
          _attachStream(streamProvider.streamProvider(request), request);
        } else if (_provider is MergedStreamPaginationProvider<T>) {
          final mergedProvider = _provider as MergedStreamPaginationProvider<T>;
          _attachStream(mergedProvider.getMergedStream(request), request);
        }
      }
    } on Exception catch (error, stackTrace) {
      _logger.e(
        'Pagination request failed',
        error: error,
        stackTrace: stackTrace,
      );
      emit(SinglePaginationError<T>(error: error));
    } catch (error, stackTrace) {
      final exception = Exception(error.toString());
      _logger.e(
        'Pagination request failed',
        error: exception,
        stackTrace: stackTrace,
      );
      emit(SinglePaginationError<T>(error: exception));
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
        _onInsertionCallback?.call(aggregated);

        final meta = PaginationMeta(
          page: request.page,
          pageSize: request.pageSize,
          hasNext: _computeHasNext(items, request.pageSize),
          hasPrevious: request.page > 1,
        );
        _currentMeta = meta;

        emit(
          SinglePaginationLoaded<T>(
            items: List<T>.from(aggregated),
            allItems: aggregated,
            meta: meta,
            hasReachedEnd: !meta.hasNext,
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
        emit(SinglePaginationError<T>(error: exception));
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
    if (currentState is! SinglePaginationLoaded<T>) return;

    final updated = List<T>.from(currentState.allItems);
    final insertIndex = index.clamp(0, updated.length);
    updated.insert(insertIndex, item);
    _onInsertionCallback?.call(updated);

    emit(
      currentState.copyWith(
        allItems: updated,
        items: updated,
        lastUpdate: DateTime.now(),
      ),
    );
  }

  @override
  void addOrUpdateEmit(T item, {int index = 0}) {
    final currentState = state;
    if (currentState is! SinglePaginationLoaded<T>) return;

    final updated = List<T>.from(currentState.allItems);
    final existingIndex = updated.indexWhere((element) => element == item);

    if (existingIndex != -1) {
      updated[existingIndex] = item;
    } else {
      final insertIndex = index.clamp(0, updated.length);
      updated.insert(insertIndex, item);
    }

    _onInsertionCallback?.call(updated);

    emit(
      currentState.copyWith(
        allItems: updated,
        items: updated,
        lastUpdate: DateTime.now(),
      ),
    );
  }
}
