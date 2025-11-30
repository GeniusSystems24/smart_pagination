part of '../../pagination.dart';

/// A convenience widget for creating a paginated GridView.
///
/// This is a simpler alternative to [SmartPagination] when you just want
/// a basic grid with pagination.
///
/// ## Example with Future
///
/// ```dart
/// SmartPaginatedGridView<Product>(
///   request: PaginationRequest(page: 1, pageSize: 20),
///   provider: PaginationProvider.future(
///     (request) => apiService.fetchProducts(request),
///   ),
///   gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
///     crossAxisCount: 2,
///     childAspectRatio: 0.75,
///   ),
///   childBuilder: (context, product, index) {
///     return ProductCard(product: product);
///   },
/// )
/// ```
///
/// ## Example with Stream
///
/// ```dart
/// SmartPaginatedGridView<Product>(
///   request: PaginationRequest(page: 1, pageSize: 20),
///   provider: PaginationProvider.stream(
///     (request) => apiService.productsStream(request),
///   ),
///   gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
///     crossAxisCount: 2,
///     childAspectRatio: 0.75,
///   ),
///   childBuilder: (context, product, index) {
///     return ProductCard(product: product);
///   },
/// )
/// ```
class SmartPaginatedGridView<T> extends StatelessWidget {
  const SmartPaginatedGridView({
    super.key,
    required this.request,
    required this.provider,
    required this.gridDelegate,
    required this.childBuilder,
    this.emptyBuilder,
    this.errorBuilder,
    this.initialLoadingBuilder,
    this.bottomLoadingBuilder,
    this.retryConfig,
    this.shrinkWrap = false,
    this.reverse = false,
    this.padding,
    this.physics,
    this.scrollController,
    this.onReachedEnd,
    this.firstPageLoadingBuilder,
    this.firstPageErrorBuilder,
    this.firstPageEmptyBuilder,
    this.loadMoreLoadingBuilder,
    this.loadMoreErrorBuilder,
    this.loadMoreNoMoreItemsBuilder,
    this.invisibleItemsThreshold = 3,
  });

  /// The initial pagination request configuration.
  final PaginationRequest request;

  /// Unified data provider (Future or Stream).
  final PaginationProvider<T> provider;

  /// The grid delegate that controls the grid layout.
  final SliverGridDelegate gridDelegate;

  /// Builder for each grid item.
  final Widget Function(BuildContext context, T item, int index) childBuilder;

  /// Optional builder for empty state.
  final Widget Function(BuildContext context)? emptyBuilder;

  /// Optional builder for error state.
  final Widget Function(
    BuildContext context,
    Exception exception,
    VoidCallback retryCallback,
  )?
  errorBuilder;

  /// Optional builder for initial loading state.
  final Widget Function(BuildContext context)? initialLoadingBuilder;

  /// Optional builder for bottom loading indicator.
  final Widget Function(BuildContext context)? bottomLoadingBuilder;

  /// Optional retry configuration.
  final RetryConfig? retryConfig;

  // ========== NEW STATE SEPARATION BUILDERS ==========

  /// Custom builder for first page loading state
  final Widget Function(BuildContext context)? firstPageLoadingBuilder;

  /// Custom builder for first page error state with retry callback
  final Widget Function(BuildContext context, Exception error, VoidCallback retry)?
      firstPageErrorBuilder;

  /// Custom builder for first page empty state
  final Widget Function(BuildContext context)? firstPageEmptyBuilder;

  /// Custom builder for load more loading indicator
  final Widget Function(BuildContext context)? loadMoreLoadingBuilder;

  /// Custom builder for load more error with retry callback
  final Widget Function(BuildContext context, Exception error, VoidCallback retry)?
      loadMoreErrorBuilder;

  /// Custom builder for no more items indicator
  final Widget Function(BuildContext context)? loadMoreNoMoreItemsBuilder;

  /// Number of items from the end to trigger loading more (default: 3)
  final int invisibleItemsThreshold;

  /// Whether the scroll view should shrink-wrap its contents.
  final bool shrinkWrap;

  /// Whether to display items in reverse order.
  final bool reverse;

  /// Padding around the grid.
  final EdgeInsetsGeometry? padding;

  /// The scroll physics.
  final ScrollPhysics? physics;

  /// Optional scroll controller.
  final ScrollController? scrollController;

  /// Callback when the grid reaches the end.
  final VoidCallback? onReachedEnd;

  @override
  Widget build(BuildContext context) {
    return SmartPagination<T>(
      request: request,
      provider: provider,
      itemBuilderType: PaginateBuilderType.gridView,
      gridDelegate: gridDelegate,
      itemBuilder: (context, items, index) =>
          childBuilder(context, items[index], index),
      emptyWidget: emptyBuilder?.call(context) ?? const EmptyDisplay(),
      loadingWidget:
          initialLoadingBuilder?.call(context) ?? const InitialLoader(),
      bottomLoader: bottomLoadingBuilder?.call(context) ?? const BottomLoader(),
      onError: errorBuilder != null
          ? (exception) =>
                _ErrorWrapper(exception: exception, errorBuilder: errorBuilder!)
          : null,
      retryConfig: retryConfig,
      shrinkWrap: shrinkWrap,
      reverse: reverse,
      padding: padding ?? const EdgeInsets.all(0),
      physics: physics,
      scrollController: scrollController,
      onReachedEnd: onReachedEnd != null ? (_) => onReachedEnd!() : null,
      // New state separation builders
      firstPageLoadingBuilder: firstPageLoadingBuilder,
      firstPageErrorBuilder: firstPageErrorBuilder,
      firstPageEmptyBuilder: firstPageEmptyBuilder,
      loadMoreLoadingBuilder: loadMoreLoadingBuilder,
      loadMoreErrorBuilder: loadMoreErrorBuilder,
      loadMoreNoMoreItemsBuilder: loadMoreNoMoreItemsBuilder,
      invisibleItemsThreshold: invisibleItemsThreshold,
    );
  }
}

class _ErrorWrapper extends StatelessWidget {
  const _ErrorWrapper({required this.exception, required this.errorBuilder});

  final Exception exception;
  final Widget Function(
    BuildContext context,
    Exception exception,
    VoidCallback retryCallback,
  )
  errorBuilder;

  @override
  Widget build(BuildContext context) {
    // The retry callback will be provided by the pagination cubit
    return errorBuilder(context, exception, () {});
  }
}
