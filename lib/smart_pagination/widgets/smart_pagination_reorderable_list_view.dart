part of '../../pagination.dart';

/// A paginated ReorderableListView widget with automatic pagination support.
///
/// This widget provides a convenient way to display paginated data in a
/// ReorderableListView with built-in support for loading states, error handling,
/// infinite scrolling, and drag-and-drop reordering.
///
/// Example usage:
/// ```dart
/// SmartPaginationReorderableListView.withProvider(
///   request: PaginationRequest(page: 1, pageSize: 20),
///   provider: PaginationProvider.future((request) => fetchTasks(request)),
///   itemBuilder: (context, items, index) {
///     return ListTile(
///       key: ValueKey(items[index].id),
///       title: Text(items[index].title),
///     );
///   },
///   onReorder: (oldIndex, newIndex) {
///     // Handle reorder logic
///   },
/// )
/// ```
class SmartPaginationReorderableListView<T> extends SmartPagination<T> {
  /// Creates a SmartPaginationReorderableListView with a provider for data fetching.
  ///
  /// The [request], [provider], and [onReorder] are required to configure pagination.
  /// Use [itemBuilder] to define how each item should be rendered.
  /// Each item must have a unique key for reordering to work correctly.
  SmartPaginationReorderableListView.withProvider({
    super.key,
    required super.request,
    required super.provider,
    required super.itemBuilder,
    required super.onReorder,
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
    super.separator,
    super.spacing,
    super.firstPageLoadingBuilder,
    super.firstPageErrorBuilder,
    super.firstPageEmptyBuilder,
    super.loadMoreLoadingBuilder,
    super.loadMoreErrorBuilder,
    super.loadMoreNoMoreItemsBuilder,
    super.invisibleItemsThreshold,
    super.refreshListener,
    super.filterListeners,
    super.onInsertionCallback,
    super.onClear,
    super.logger,
    super.maxPagesInMemory,
    super.retryConfig,
    Duration? dataAge,
  }) : super.reorderableListViewWithProvider();

  /// Creates a SmartPaginationReorderableListView with an external cubit.
  ///
  /// Use this constructor when you want to manage the cubit externally,
  /// such as when using it as a global variable or sharing it across screens.
  SmartPaginationReorderableListView.withCubit({
    super.key,
    required super.cubit,
    required super.itemBuilder,
    required super.onReorder,
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
    super.separator,
    super.spacing,
    super.firstPageLoadingBuilder,
    super.firstPageErrorBuilder,
    super.firstPageEmptyBuilder,
    super.loadMoreLoadingBuilder,
    super.loadMoreErrorBuilder,
    super.loadMoreNoMoreItemsBuilder,
    super.invisibleItemsThreshold,
    super.refreshListener,
    super.filterListeners,
  }) : super.reorderableListViewWithCubit();
}
