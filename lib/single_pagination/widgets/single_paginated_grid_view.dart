import 'package:flutter/material.dart';
import '../pagination.dart';

/// A convenience widget for creating a paginated GridView.
///
/// This is a simpler alternative to [SinglePagination] when you just want
/// a basic grid with pagination.
///
/// ## Example
///
/// ```dart
/// SinglePaginatedGridView<Product>(
///   request: PaginationRequest(page: 1, pageSize: 20),
///   dataProvider: (request) => apiService.fetchProducts(request),
///   gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
///     crossAxisCount: 2,
///     childAspectRatio: 0.75,
///   ),
///   childBuilder: (context, product, index) {
///     return ProductCard(product: product);
///   },
/// )
/// ```
class SinglePaginatedGridView<T> extends StatelessWidget {
  const SinglePaginatedGridView({
    super.key,
    required this.request,
    required this.dataProvider,
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
  });

  /// The initial pagination request configuration.
  final PaginationRequest request;

  /// Function that fetches a page of data from your API.
  final PaginationDataProvider<T> dataProvider;

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
  )? errorBuilder;

  /// Optional builder for initial loading state.
  final Widget Function(BuildContext context)? initialLoadingBuilder;

  /// Optional builder for bottom loading indicator.
  final Widget Function(BuildContext context)? bottomLoadingBuilder;

  /// Optional retry configuration.
  final RetryConfig? retryConfig;

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
    return SinglePagination<T>(
      request: request,
      dataProvider: dataProvider,
      itemBuilderType: PaginateBuilderType.gridView,
      gridDelegate: gridDelegate,
      itemBuilder: (context, items, index) => childBuilder(context, items[index], index),
      emptyWidget: emptyBuilder?.call(context) ?? const EmptyDisplay(),
      loadingWidget: initialLoadingBuilder?.call(context) ?? const InitialLoader(),
      bottomLoader: bottomLoadingBuilder?.call(context) ?? const BottomLoader(),
      onError: errorBuilder != null
          ? (exception) => _ErrorWrapper(
                exception: exception,
                errorBuilder: errorBuilder!,
              )
          : null,
      shrinkWrap: shrinkWrap,
      reverse: reverse,
      padding: padding ?? const EdgeInsets.all(0),
      physics: physics,
      scrollController: scrollController,
      onReachedEnd: onReachedEnd != null ? (_) => onReachedEnd!() : null,
    );
  }
}

class _ErrorWrapper extends StatelessWidget {
  const _ErrorWrapper({
    required this.exception,
    required this.errorBuilder,
  });

  final Exception exception;
  final Widget Function(
    BuildContext context,
    Exception exception,
    VoidCallback retryCallback,
  ) errorBuilder;

  @override
  Widget build(BuildContext context) {
    // The retry callback will be provided by the pagination cubit
    return errorBuilder(context, exception, () {});
  }
}
