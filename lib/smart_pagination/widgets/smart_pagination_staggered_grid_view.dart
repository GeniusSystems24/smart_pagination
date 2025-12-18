part of '../../pagination.dart';

/// A paginated StaggeredGridView widget with automatic pagination support.
///
/// This widget provides a convenient way to display paginated data in a
/// Pinterest-like masonry layout with built-in support for loading states,
/// error handling, and infinite scrolling.
///
/// Example usage:
/// ```dart
/// SmartPaginationStaggeredGridView.withProvider(
///   request: PaginationRequest(page: 1, pageSize: 20),
///   provider: PaginationProvider.future((request) => fetchImages(request)),
///   crossAxisCount: 2,
///   itemBuilder: (context, items, index) {
///     final image = items[index];
///     return StaggeredGridTile.count(
///       crossAxisCellCount: 1,
///       mainAxisCellCount: image.aspectRatio > 1 ? 1 : 2,
///       child: ImageCard(image: image),
///     );
///   },
/// )
/// ```
class SmartPaginationStaggeredGridView<T> extends SmartPagination<T> {
  /// Creates a SmartPaginationStaggeredGridView with a provider for data fetching.
  ///
  /// The [request], [provider], and [crossAxisCount] are required to configure pagination.
  /// Use [itemBuilder] to define how each item should be rendered with StaggeredGridTile.
  SmartPaginationStaggeredGridView.withProvider({
    super.key,
    required super.request,
    required super.provider,
    required super.itemBuilder,
    required super.crossAxisCount,
    super.mainAxisSpacing,
    super.crossAxisSpacing,
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
    super.staggeredAxisDirection,
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
  }) : super.staggeredGridViewWithProvider();

  /// Creates a SmartPaginationStaggeredGridView with an external cubit.
  ///
  /// Use this constructor when you want to manage the cubit externally,
  /// such as when using it as a global variable or sharing it across screens.
  SmartPaginationStaggeredGridView.withCubit({
    super.key,
    required super.cubit,
    required super.itemBuilder,
    required super.crossAxisCount,
    super.mainAxisSpacing,
    super.crossAxisSpacing,
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
    super.staggeredAxisDirection,
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
  }) : super.staggeredGridViewWithCubit();
}
