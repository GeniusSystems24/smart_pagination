part of '../../pagination.dart';

/// A paginated Column widget (non-scrollable) with automatic pagination support.
///
/// This widget provides a convenient way to display paginated data in a Column
/// layout. It uses shrinkWrap and NeverScrollableScrollPhysics, making it
/// suitable for embedding inside other scroll views.
///
/// Example usage:
/// ```dart
/// SingleChildScrollView(
///   child: SmartPaginationColumn.withProvider(
///     request: PaginationRequest(page: 1, pageSize: 20),
///     provider: PaginationProvider.future((request) => fetchProducts(request)),
///     itemBuilder: (context, items, index) {
///       return ListTile(title: Text(items[index].name));
///     },
///   ),
/// )
/// ```
class SmartPaginationColumn<T> extends SmartPagination<T> {
  /// Creates a SmartPaginationColumn with a provider for data fetching.
  ///
  /// The [request] and [provider] are required to configure pagination.
  /// Use [itemBuilder] to define how each item should be rendered.
  SmartPaginationColumn.withProvider({
    super.key,
    required super.request,
    required super.provider,
    required super.itemBuilder,
    super.heightOfInitialLoadingAndEmptyWidget,
    super.onError,
    super.onReachedEnd,
    super.onLoaded,
    super.emptyWidget,
    super.loadingWidget,
    super.bottomLoader,
    super.header,
    super.footer,
    super.beforeBuild,
    super.listBuilder,
    super.padding,
    super.allowImplicitScrolling,
    super.scrollController,
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
  }) : super.columnWithProvider();

  /// Creates a SmartPaginationColumn with an external cubit.
  ///
  /// Use this constructor when you want to manage the cubit externally,
  /// such as when using it as a global variable or sharing it across screens.
  SmartPaginationColumn.withCubit({
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
    super.header,
    super.footer,
    super.beforeBuild,
    super.listBuilder,
    super.padding,
    super.allowImplicitScrolling,
    super.scrollController,
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
  }) : super.columnWithCubit();
}
