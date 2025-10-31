import 'package:flutter/material.dart';
import '../pagination.dart';

/// A convenience widget for creating a grouped paginated ListView.
///
/// This is a simpler alternative to [DualPagination] when you just want
/// a basic grouped list with pagination.
///
/// ## Example
///
/// ```dart
/// DualPaginatedListView<String, Message>(
///   request: PaginationRequest(page: 1, pageSize: 50),
///   dataProvider: (request) => apiService.fetchMessages(request),
///   groupKeyGenerator: (message) {
///     return DateFormat('yyyy-MM-dd').format(message.timestamp);
///   },
///   groupHeaderBuilder: (context, dateKey, messages) {
///     return Container(
///       padding: EdgeInsets.all(16),
///       color: Colors.grey[200],
///       child: Text(dateKey),
///     );
///   },
///   childBuilder: (context, message, index) {
///     return ListTile(
///       title: Text(message.content),
///       subtitle: Text(message.author),
///     );
///   },
/// )
/// ```
class DualPaginatedListView<Key, T> extends StatelessWidget {
  const DualPaginatedListView({
    super.key,
    required this.request,
    required this.dataProvider,
    required this.groupKeyGenerator,
    required this.groupHeaderBuilder,
    required this.childBuilder,
    this.separatorBuilder,
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
  final DualPaginationDataProvider<T> dataProvider;

  /// Function that determines which group each item belongs to.
  final Key Function(T item) groupKeyGenerator;

  /// Builder for group headers.
  final Widget Function(BuildContext context, Key groupKey, List<T> items)
      groupHeaderBuilder;

  /// Builder for each list item.
  final Widget Function(BuildContext context, T item, int index) childBuilder;

  /// Optional builder for separators between items.
  final Widget Function(BuildContext context, int index)? separatorBuilder;

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

  /// Padding around the list.
  final EdgeInsetsGeometry? padding;

  /// The scroll physics.
  final ScrollPhysics? physics;

  /// Optional scroll controller.
  final ScrollController? scrollController;

  /// Callback when the list reaches the end.
  final VoidCallback? onReachedEnd;

  @override
  Widget build(BuildContext context) {
    return DualPagination<Key, T>(
      request: request,
      dataProvider: dataProvider,
      groupKeyGenerator: groupKeyGenerator,
      groupHeaderBuilder: groupHeaderBuilder,
      itemBuilder: (context, item, index) => childBuilder(context, item, index),
      separator: separatorBuilder != null
          ? _SeparatorBuilder(separatorBuilder!)
          : null,
      emptyWidget: emptyBuilder?.call(context) ?? const EmptyDisplay(),
      loadingWidget: initialLoadingBuilder?.call(context) ?? const InitialLoader(),
      bottomLoader: bottomLoadingBuilder?.call(context) ?? const BottomLoader(),
      onError: errorBuilder != null ? (exception) => errorBuilder!(context, exception, () {}) : null,
      shrinkWrap: shrinkWrap,
      reverse: reverse,
      padding: padding ?? const EdgeInsets.all(0),
      physics: physics,
      scrollController: scrollController,
      onReachedEnd: onReachedEnd != null ? (_) => onReachedEnd!() : null,
    );
  }
}

class _SeparatorBuilder extends StatelessWidget {
  const _SeparatorBuilder(this.builder);

  final Widget Function(BuildContext context, int index) builder;

  @override
  Widget build(BuildContext context) {
    // This is a placeholder - the actual index will be provided by the pagination widget
    return builder(context, 0);
  }
}
