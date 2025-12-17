part of '../../pagination.dart';

/// A paginated ListView widget with automatic pagination support.
///
/// This widget provides a convenient way to display paginated data in a ListView
/// with built-in support for loading states, error handling, and infinite scrolling.
///
/// Example usage:
/// ```dart
/// SmartPaginationListView.withProvider(
///   request: PaginationRequest(page: 1, pageSize: 20),
///   provider: PaginationProvider.future((request) => fetchProducts(request)),
///   itemBuilder: (context, items, index) {
///     return ListTile(title: Text(items[index].name));
///   },
/// )
/// ```
class SmartPaginationListView<T> extends SmartPagination<T> {
  /// Creates a SmartPaginationListView with a provider for data fetching.
  ///
  /// The [request] and [provider] are required to configure pagination.
  /// Use [itemBuilder] to define how each item should be rendered.
  SmartPaginationListView.withProvider({
    super.key,
    required PaginationRequest request,
    required PaginationProvider<T> provider,
    required super.itemBuilder,
    super.heightOfInitialLoadingAndEmptyWidget,
    super.onError,
    super.onReachedEnd,
    super.onLoaded,
    super.emptyWidget,
    super.loadingWidget,
    super.bottomLoader,
    super.shrinkWrap,
    super.reverse,
    super.scrollDirection,
    super.padding,
    super.physics,
    super.scrollController,
    super.allowImplicitScrolling,
    super.keyboardDismissBehavior,
    super.header,
    super.footer,
    super.beforeBuild,
    super.listBuilder,
    super.cacheExtent,
    Widget? separator,
    double spacing = 4,
    super.firstPageLoadingBuilder,
    super.firstPageErrorBuilder,
    super.firstPageEmptyBuilder,
    super.loadMoreLoadingBuilder,
    super.loadMoreErrorBuilder,
    super.loadMoreNoMoreItemsBuilder,
    super.invisibleItemsThreshold,
    SmartPaginationRefreshedChangeListener? refreshListener,
    List<SmartPaginationFilterChangeListener<T>>? filterListeners,
    OnInsertionCallback<T>? onInsertionCallback,
    VoidCallback? onClear,
    Logger? logger,
    int maxPagesInMemory = 5,
    RetryConfig? retryConfig,
    Duration? dataAge,
  }) : super.listViewWithProvider(
          request: request,
          provider: provider,
          separator: separator,
          spacing: spacing,
          refreshListener: refreshListener,
          filterListeners: filterListeners,
          onInsertionCallback: onInsertionCallback,
          onClear: onClear,
          logger: logger,
          maxPagesInMemory: maxPagesInMemory,
          retryConfig: retryConfig,
        );

  /// Creates a SmartPaginationListView with an external cubit.
  ///
  /// Use this constructor when you want to manage the cubit externally,
  /// such as when using it as a global variable or sharing it across screens.
  SmartPaginationListView.withCubit({
    super.key,
    required super.cubit,
    required super.itemBuilder,
    super.heightOfInitialLoadingAndEmptyWidget,
    super.onError,
    super.onReachedEnd,
    super.onLoaded,
    super.emptyWidget,
    super.loadingWidget,
    super.bottomLoader,
    super.shrinkWrap,
    super.reverse,
    super.scrollDirection,
    super.padding,
    super.physics,
    super.scrollController,
    super.allowImplicitScrolling,
    super.keyboardDismissBehavior,
    super.header,
    super.footer,
    super.beforeBuild,
    super.listBuilder,
    super.cacheExtent,
    Widget? separator,
    double spacing = 4,
    super.firstPageLoadingBuilder,
    super.firstPageErrorBuilder,
    super.firstPageEmptyBuilder,
    super.loadMoreLoadingBuilder,
    super.loadMoreErrorBuilder,
    super.loadMoreNoMoreItemsBuilder,
    super.invisibleItemsThreshold,
    SmartPaginationRefreshedChangeListener? refreshListener,
    List<SmartPaginationFilterChangeListener<T>>? filterListeners,
  }) : super.listViewWithCubit(
          separator: separator,
          spacing: spacing,
          refreshListener: refreshListener,
          filterListeners: filterListeners,
        );
}
