/// Smart Pagination Library
///
/// A comprehensive Flutter pagination library that provides flexible and powerful
/// pagination solutions for REST APIs with support for multiple view types.
///
/// ## Features
///
/// - **Multiple Layout Support**: ListView, GridView, PageView, StaggeredGridView, Column, Row
/// - **BLoC Pattern**: Clean state management using flutter_bloc
/// - **Cursor & Offset Pagination**: Support for both pagination strategies
/// - **Stream Support**: Real-time updates via stream providers
/// - **Memory Management**: Configurable page caching
/// - **Filtering & Refresh**: Built-in filter and refresh listeners
/// - **Scroll Control**: Programmatic scrolling to items or indices
///
/// ## Basic Usage
///
/// ```dart
/// // 1. Define your data provider
/// Future<List<MyModel>> fetchData(PaginationRequest request) async {
///   final response = await http.get('api/items?page=${request.page}');
///   return (json.decode(response.body) as List)
///       .map((e) => MyModel.fromJson(e))
///       .toList();
/// }
///
/// // 2. Create a SmartPagination widget
/// SmartPagination<MyModel>(
///   request: PaginationRequest(page: 1, pageSize: 20),
///   dataProvider: fetchData,
///   itemBuilder: (context, items, index) {
///     return ListTile(title: Text(items[index].name));
///   },
/// )
/// ```
///
/// For advanced usage and examples, see the documentation.
library;

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:scrollview_observer/scrollview_observer.dart';

part 'core/widget/bottom_loader.dart';
part 'core/widget/empty_display.dart';
part 'core/widget/empty_separator.dart';
part 'core/widget/error_display.dart';
part 'core/widget/custom_error_builder.dart';
part 'core/widget/initial_loader.dart';
part 'smart_pagination/controller/scroll_to_message_mixin.dart';
part 'core/error_handling.dart';

part 'smart_pagination/widgets/paginate_api_view.dart';
part 'smart_pagination/widgets/smart_paginated_grid_view.dart';
part 'smart_pagination/widgets/smart_paginated_list_view.dart';
part 'smart_pagination/bloc/pagination_cubit.dart';
part 'smart_pagination/bloc/pagination_listeners.dart';
part 'smart_pagination/bloc/pagination_state.dart';
part 'smart_pagination/controller/controller.dart';

// Core interfaces for pagination system
part 'core/core.dart';
part 'core/bloc/pagination_cubit.dart';
part 'core/bloc/pagination_listeners.dart';
part 'core/bloc/pagination_state.dart';
part 'core/controller/controller.dart';

// data
part 'data/models/pagination_meta.dart';
part 'data/models/pagination_request.dart';

class SmartPagination<T> extends StatefulWidget {
  final Widget bottomLoader;
  final double? heightOfInitialLoadingAndEmptyWidget;
  final SliverGridDelegate gridDelegate;
  final PaginateBuilderType itemBuilderType;
  final EdgeInsetsGeometry padding;
  final ScrollPhysics? physics;
  final bool reverse;
  final bool allowImplicitScrolling;
  final ScrollViewKeyboardDismissBehavior keyboardDismissBehavior;
  final PageController? pageController;
  final Axis scrollDirection;
  final AxisDirection? staggeredAxisDirection;
  final Widget separator;
  final bool shrinkWrap;
  final Widget? header;
  final Widget? footer;
  final Widget Function(BuildContext context, List<T> documents, int index)
  itemBuilder;
  final void Function(int)? onPageChanged;
  final Widget emptyWidget;
  final Widget loadingWidget;
  final List<SmartPaginationChangeListener>? listeners;
  final ListBuilder<T>? listBuilder;
  final ScrollController? scrollController;
  final SmartPaginationCubit<T> cubit;
  final SmartPaginationLoaded<T> Function(SmartPaginationLoaded<T> state)?
  beforeBuild;
  final double? cacheExtent;

  final Widget Function(Exception exception)? onError;

  final void Function(SmartPaginationLoaded<T> loader)? onReachedEnd;

  final void Function(SmartPaginationLoaded<T> loader)? onLoaded;

  final bool internalCubit;

  /// Custom view builder for complete control over the view
  /// Only used when itemBuilderType is PaginateBuilderType.custom
  final Widget Function(
    BuildContext context,
    List<T> items,
    bool hasReachedEnd,
    VoidCallback? fetchMore,
  )?
  customViewBuilder;

  /// Callback for reordering items in ReorderableListView
  /// Only used when itemBuilderType is PaginateBuilderType.reorderableListView
  final void Function(int oldIndex, int newIndex)? onReorder;

  // ========== State Separation Builders ==========

  /// Builder for first page loading state
  /// If not provided, falls back to [loadingWidget]
  final Widget Function(BuildContext context)? firstPageLoadingBuilder;

  /// Builder for first page error state with retry capability
  /// If not provided, falls back to [onError]
  final Widget Function(BuildContext context, Exception error, VoidCallback retry)? firstPageErrorBuilder;

  /// Builder for first page empty state (no items found)
  /// If not provided, falls back to [emptyWidget]
  final Widget Function(BuildContext context)? firstPageEmptyBuilder;

  /// Builder for load more loading indicator
  /// If not provided, falls back to [bottomLoader]
  final Widget Function(BuildContext context)? loadMoreLoadingBuilder;

  /// Builder for load more error state with retry capability
  final Widget Function(BuildContext context, Exception error, VoidCallback retry)? loadMoreErrorBuilder;

  /// Builder for end of list indicator (no more items to load)
  final Widget Function(BuildContext context)? loadMoreNoMoreItemsBuilder;

  // ========== Performance Options ==========

  /// Number of items before the end that triggers loading more items
  /// Default is 3 - starts loading when user is 3 items away from the end
  final int invisibleItemsThreshold;

  SmartPagination({
    super.key,
    required PaginationRequest request,
    required PaginationProvider<T> provider,
    required this.itemBuilder,
    this.itemBuilderType = PaginateBuilderType.listView,
    this.heightOfInitialLoadingAndEmptyWidget,
    this.gridDelegate = const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
    ),
    this.onError,
    this.onReachedEnd,
    this.onLoaded,
    this.emptyWidget = const EmptyDisplay(),
    this.separator = const EmptySeparator(),
    this.loadingWidget = const InitialLoader(),
    this.bottomLoader = const BottomLoader(),
    this.shrinkWrap = false,
    this.reverse = false,
    this.scrollDirection = Axis.vertical,
    this.staggeredAxisDirection,
    this.padding = const EdgeInsetsGeometry.all(0),
    this.physics,
    this.scrollController,
    this.allowImplicitScrolling = false,
    this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
    this.pageController,
    this.onPageChanged,
    this.header,
    this.footer,
    this.beforeBuild,
    this.listBuilder,
    this.cacheExtent,
    this.customViewBuilder,
    this.onReorder,
    // State Separation Builders
    this.firstPageLoadingBuilder,
    this.firstPageErrorBuilder,
    this.firstPageEmptyBuilder,
    this.loadMoreLoadingBuilder,
    this.loadMoreErrorBuilder,
    this.loadMoreNoMoreItemsBuilder,
    // Performance Options
    this.invisibleItemsThreshold = 3,
    OnInsertionCallback<T>? onInsertionCallback,
    VoidCallback? onClear,
    Logger? logger,
    int maxPagesInMemory = 5,
    RetryConfig? retryConfig,
    SmartPaginationRefreshedChangeListener? refreshListener,
    List<SmartPaginationFilterChangeListener<T>>? filterListeners,
  }) : internalCubit = true,
       cubit = SmartPaginationCubit<T>(
         request: request,
         provider: provider,
         listBuilder: listBuilder,
         onInsertionCallback: onInsertionCallback,
         onClear: onClear,
         logger: logger,
         maxPagesInMemory: maxPagesInMemory,
         retryConfig: retryConfig,
       ),

       listeners =
           refreshListener != null || filterListeners?.isNotEmpty == true
           ? [if (refreshListener != null) refreshListener, ...?filterListeners]
           : null;

  SmartPagination.cubit({
    super.key,
    required this.cubit,
    required this.itemBuilder,
    required this.itemBuilderType,
    this.heightOfInitialLoadingAndEmptyWidget,
    this.gridDelegate = const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
    ),
    this.onError,
    this.onReachedEnd,
    this.onLoaded,
    this.emptyWidget = const EmptyDisplay(),
    this.separator = const EmptySeparator(),
    this.loadingWidget = const InitialLoader(),
    this.bottomLoader = const BottomLoader(),
    this.shrinkWrap = false,
    this.reverse = false,
    this.scrollDirection = Axis.vertical,
    this.staggeredAxisDirection,
    this.padding = const EdgeInsetsGeometry.all(0),
    this.physics,
    this.scrollController,
    this.allowImplicitScrolling = false,
    this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
    this.pageController,
    this.onPageChanged,
    this.header,
    this.footer,
    this.beforeBuild,
    this.listBuilder,
    this.cacheExtent,
    this.customViewBuilder,
    this.onReorder,
    // State Separation Builders
    this.firstPageLoadingBuilder,
    this.firstPageErrorBuilder,
    this.firstPageEmptyBuilder,
    this.loadMoreLoadingBuilder,
    this.loadMoreErrorBuilder,
    this.loadMoreNoMoreItemsBuilder,
    // Performance Options
    this.invisibleItemsThreshold = 3,
    SmartPaginationRefreshedChangeListener? refreshListener,
    List<SmartPaginationFilterChangeListener<T>>? filterListeners,
  }) : internalCubit = false,
       listeners =
           refreshListener != null || filterListeners?.isNotEmpty == true
           ? [if (refreshListener != null) refreshListener, ...?filterListeners]
           : null;

  /// Creates a pagination widget as a Column layout (non-scrollable)
  /// Similar to PaginatorColumn
  SmartPagination.column({
    super.key,
    required this.cubit,
    required this.itemBuilder,
    this.heightOfInitialLoadingAndEmptyWidget,
    this.onError,
    this.onReachedEnd,
    this.onLoaded,
    this.emptyWidget = const EmptyDisplay(),
    this.loadingWidget = const InitialLoader(),
    this.bottomLoader = const BottomLoader(),
    this.header,
    this.footer,
    this.beforeBuild,
    this.listBuilder,
    this.padding = const EdgeInsetsGeometry.all(0),
    this.allowImplicitScrolling = false,
    Widget? separator,
    double spacing = 4,
    SmartPaginationRefreshedChangeListener? refreshListener,
    List<SmartPaginationFilterChangeListener<T>>? filterListeners,
  }) : itemBuilderType = PaginateBuilderType.listView,
       gridDelegate = const SliverGridDelegateWithFixedCrossAxisCount(
         crossAxisCount: 2,
       ),
       separator = separator ?? SizedBox(height: spacing),
       shrinkWrap = true,
       reverse = false,
       scrollDirection = Axis.vertical,
       staggeredAxisDirection = null,
       physics = const NeverScrollableScrollPhysics(),
       scrollController = null,
       keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
       pageController = null,
       onPageChanged = null,
       cacheExtent = null,
       customViewBuilder = null,
       onReorder = null,
       firstPageLoadingBuilder = null,
       firstPageErrorBuilder = null,
       firstPageEmptyBuilder = null,
       loadMoreLoadingBuilder = null,
       loadMoreErrorBuilder = null,
       loadMoreNoMoreItemsBuilder = null,
       invisibleItemsThreshold = 3,
       internalCubit = false,
       listeners =
           refreshListener != null || filterListeners?.isNotEmpty == true
           ? [if (refreshListener != null) refreshListener, ...?filterListeners]
           : null;

  /// Creates a pagination widget as a GridView layout
  /// Similar to PaginatorGridView
  SmartPagination.gridView({
    super.key,
    required this.cubit,
    required this.itemBuilder,
    this.heightOfInitialLoadingAndEmptyWidget,
    this.gridDelegate = const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
    ),
    this.onError,
    this.onReachedEnd,
    this.onLoaded,
    this.emptyWidget = const EmptyDisplay(),
    this.loadingWidget = const InitialLoader(),
    this.bottomLoader = const BottomLoader(),
    this.shrinkWrap = false,
    this.reverse = false,
    this.scrollDirection = Axis.vertical,
    this.padding = const EdgeInsetsGeometry.all(0),
    this.physics,
    this.scrollController,
    this.allowImplicitScrolling = false,
    this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
    this.header,
    this.footer,
    this.beforeBuild,
    this.listBuilder,
    this.cacheExtent,
    Widget? separator,
    double spacing = 4,
    SmartPaginationRefreshedChangeListener? refreshListener,
    List<SmartPaginationFilterChangeListener<T>>? filterListeners,
  }) : itemBuilderType = PaginateBuilderType.gridView,
       separator = separator ?? SizedBox(height: spacing),
       staggeredAxisDirection = null,
       pageController = null,
       onPageChanged = null,
       customViewBuilder = null,
       onReorder = null,
       firstPageLoadingBuilder = null,
       firstPageErrorBuilder = null,
       firstPageEmptyBuilder = null,
       loadMoreLoadingBuilder = null,
       loadMoreErrorBuilder = null,
       loadMoreNoMoreItemsBuilder = null,
       invisibleItemsThreshold = 3,
       internalCubit = false,
       listeners =
           refreshListener != null || filterListeners?.isNotEmpty == true
           ? [if (refreshListener != null) refreshListener, ...?filterListeners]
           : null;

  /// Creates a pagination widget as a ListView layout
  /// Similar to PaginatorListView
  SmartPagination.listView({
    super.key,
    required this.cubit,
    required this.itemBuilder,
    this.heightOfInitialLoadingAndEmptyWidget,
    this.onError,
    this.onReachedEnd,
    this.onLoaded,
    this.emptyWidget = const EmptyDisplay(),
    this.loadingWidget = const InitialLoader(),
    this.bottomLoader = const BottomLoader(),
    this.shrinkWrap = false,
    this.reverse = false,
    this.scrollDirection = Axis.vertical,
    this.padding = const EdgeInsetsGeometry.all(0),
    this.physics,
    this.scrollController,
    this.allowImplicitScrolling = false,
    this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
    this.header,
    this.footer,
    this.beforeBuild,
    this.listBuilder,
    this.cacheExtent,
    Widget? separator,
    double spacing = 4,
    // State Separation Builders
    this.firstPageLoadingBuilder,
    this.firstPageErrorBuilder,
    this.firstPageEmptyBuilder,
    this.loadMoreLoadingBuilder,
    this.loadMoreErrorBuilder,
    this.loadMoreNoMoreItemsBuilder,
    // Performance Options
    this.invisibleItemsThreshold = 3,
    SmartPaginationRefreshedChangeListener? refreshListener,
    List<SmartPaginationFilterChangeListener<T>>? filterListeners,
  }) : itemBuilderType = PaginateBuilderType.listView,
       gridDelegate = const SliverGridDelegateWithFixedCrossAxisCount(
         crossAxisCount: 2,
       ),
       separator =
           separator ??
           (scrollDirection == Axis.horizontal
               ? SizedBox(width: spacing)
               : SizedBox(height: spacing)),
       staggeredAxisDirection = null,
       pageController = null,
       onPageChanged = null,
       customViewBuilder = null,
       onReorder = null,
       internalCubit = false,
       listeners =
           refreshListener != null || filterListeners?.isNotEmpty == true
           ? [if (refreshListener != null) refreshListener, ...?filterListeners]
           : null;

  /// Creates a pagination widget as a PageView layout
  /// Similar to PaginatorPageView
  SmartPagination.pageView({
    super.key,
    required this.cubit,
    required this.itemBuilder,
    this.heightOfInitialLoadingAndEmptyWidget,
    this.onError,
    this.onReachedEnd,
    this.onLoaded,
    this.emptyWidget = const EmptyDisplay(),
    this.loadingWidget = const InitialLoader(),
    this.bottomLoader = const BottomLoader(),
    this.shrinkWrap = false,
    this.reverse = false,
    this.scrollDirection = Axis.vertical,
    this.padding = const EdgeInsetsGeometry.all(0),
    this.physics,
    this.allowImplicitScrolling = false,
    this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
    this.pageController,
    this.onPageChanged,
    this.header,
    this.footer,
    this.beforeBuild,
    this.listBuilder,
    Widget? separator,
    double spacing = 4,
    SmartPaginationRefreshedChangeListener? refreshListener,
    List<SmartPaginationFilterChangeListener<T>>? filterListeners,
  }) : itemBuilderType = PaginateBuilderType.pageView,
       gridDelegate = const SliverGridDelegateWithFixedCrossAxisCount(
         crossAxisCount: 2,
       ),
       separator =
           separator ??
           (scrollDirection == Axis.horizontal
               ? SizedBox(width: spacing)
               : SizedBox(height: spacing)),
       staggeredAxisDirection = null,
       scrollController = null,
       cacheExtent = null,
       customViewBuilder = null,
       onReorder = null,
       firstPageLoadingBuilder = null,
       firstPageErrorBuilder = null,
       firstPageEmptyBuilder = null,
       loadMoreLoadingBuilder = null,
       loadMoreErrorBuilder = null,
       loadMoreNoMoreItemsBuilder = null,
       invisibleItemsThreshold = 3,
       internalCubit = false,
       listeners =
           refreshListener != null || filterListeners?.isNotEmpty == true
           ? [if (refreshListener != null) refreshListener, ...?filterListeners]
           : null;

  /// Creates a pagination widget as a StaggeredGridView layout
  /// Similar to PaginatorFirestoreStaggeredGridView
  SmartPagination.staggeredGridView({
    super.key,
    required this.cubit,
    required StaggeredGridTile Function(
      BuildContext context,
      List<T> documents,
      int index,
    )
    this.itemBuilder,
    this.heightOfInitialLoadingAndEmptyWidget,
    this.onError,
    this.onReachedEnd,
    this.onLoaded,
    this.emptyWidget = const EmptyDisplay(),
    this.loadingWidget = const InitialLoader(),
    this.bottomLoader = const BottomLoader(),
    this.shrinkWrap = false,
    this.reverse = false,
    this.scrollDirection = Axis.vertical,
    this.staggeredAxisDirection,
    this.padding = const EdgeInsetsGeometry.all(0),
    this.physics,
    this.allowImplicitScrolling = false,
    this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
    this.header,
    this.footer,
    this.beforeBuild,
    this.listBuilder,
    required int crossAxisCount,
    double mainAxisSpacing = 4.0,
    double crossAxisSpacing = 4.0,
    Widget? separator,
    double spacing = 4,
    SmartPaginationRefreshedChangeListener? refreshListener,
    List<SmartPaginationFilterChangeListener<T>>? filterListeners,
  }) : itemBuilderType = PaginateBuilderType.staggeredGridView,
       gridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
         crossAxisCount: crossAxisCount,
         mainAxisSpacing: mainAxisSpacing,
         crossAxisSpacing: crossAxisSpacing,
       ),
       separator = separator ?? SizedBox(height: spacing),
       scrollController = null,
       pageController = null,
       onPageChanged = null,
       cacheExtent = null,
       customViewBuilder = null,
       onReorder = null,
       firstPageLoadingBuilder = null,
       firstPageErrorBuilder = null,
       firstPageEmptyBuilder = null,
       loadMoreLoadingBuilder = null,
       loadMoreErrorBuilder = null,
       loadMoreNoMoreItemsBuilder = null,
       invisibleItemsThreshold = 3,
       internalCubit = false,
       listeners =
           refreshListener != null || filterListeners?.isNotEmpty == true
           ? [if (refreshListener != null) refreshListener, ...?filterListeners]
           : null;

  /// Creates a pagination widget as a Row layout (horizontal non-scrollable)
  /// Similar to PaginatorRow
  SmartPagination.row({
    super.key,
    required this.cubit,
    required this.itemBuilder,
    this.heightOfInitialLoadingAndEmptyWidget,
    this.onError,
    this.onReachedEnd,
    this.onLoaded,
    this.emptyWidget = const EmptyDisplay(),
    this.loadingWidget = const InitialLoader(),
    this.bottomLoader = const BottomLoader(),
    this.reverse = false,
    this.padding = const EdgeInsetsGeometry.all(0),
    this.allowImplicitScrolling = false,
    this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
    this.header,
    this.footer,
    this.beforeBuild,
    this.listBuilder,
    this.cacheExtent,
    Widget? separator,
    double spacing = 4,
    SmartPaginationRefreshedChangeListener? refreshListener,
    List<SmartPaginationFilterChangeListener<T>>? filterListeners,
  }) : itemBuilderType = PaginateBuilderType.listView,
       gridDelegate = const SliverGridDelegateWithFixedCrossAxisCount(
         crossAxisCount: 2,
       ),
       separator = separator ?? SizedBox(width: spacing),
       shrinkWrap = true,
       scrollDirection = Axis.horizontal,
       staggeredAxisDirection = null,
       physics = const NeverScrollableScrollPhysics(),
       scrollController = null,
       pageController = null,
       onPageChanged = null,
       customViewBuilder = null,
       onReorder = null,
       firstPageLoadingBuilder = null,
       firstPageErrorBuilder = null,
       firstPageEmptyBuilder = null,
       loadMoreLoadingBuilder = null,
       loadMoreErrorBuilder = null,
       loadMoreNoMoreItemsBuilder = null,
       invisibleItemsThreshold = 3,
       internalCubit = false,
       listeners =
           refreshListener != null || filterListeners?.isNotEmpty == true
           ? [if (refreshListener != null) refreshListener, ...?filterListeners]
           : null;

  @override
  State<SmartPagination<T>> createState() => _SmartPaginationState<T>();
}

class _SmartPaginationState<T> extends State<SmartPagination<T>> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SmartPaginationCubit<T>, SmartPaginationState<T>>(
      bloc: widget.cubit,
      builder: (context, state) {
        if (!widget.cubit.didFetch) widget.cubit.fetchPaginatedList();
        if (state is SmartPaginationInitial<T>) {
          // Use firstPageLoadingBuilder if provided, otherwise fallback to loadingWidget
          final loadingWidget = widget.firstPageLoadingBuilder?.call(context) ?? widget.loadingWidget;
          return _buildWithScrollView(context, loadingWidget);
        } else if (state is SmartPaginationError<T>) {
          // Use firstPageErrorBuilder if provided with retry callback
          Widget errorWidget;
          if (widget.firstPageErrorBuilder != null) {
            errorWidget = widget.firstPageErrorBuilder!(
              context,
              state.error,
              () => widget.cubit.fetchPaginatedList(), // Retry callback
            );
          } else if (widget.onError != null) {
            errorWidget = widget.onError!(state.error);
          } else {
            errorWidget = ErrorDisplay(exception: state.error);
          }
          return _buildWithScrollView(context, errorWidget);
        } else {
          final loadedState = state as SmartPaginationLoaded<T>;
          if (widget.onLoaded != null) {
            widget.onLoaded!(loadedState);
          }
          if (loadedState.hasReachedEnd && widget.onReachedEnd != null) {
            widget.onReachedEnd!(loadedState);
          }

          final beforeBuildState =
              widget.beforeBuild?.call(loadedState) ?? loadedState;

          if (beforeBuildState.items.isEmpty) {
            // Use firstPageEmptyBuilder if provided, otherwise fallback to emptyWidget
            final emptyWidget = widget.firstPageEmptyBuilder?.call(context) ?? widget.emptyWidget;
            return _buildWithScrollView(context, emptyWidget);
          }

          final view = PaginateApiView(
            loadedState: beforeBuildState,
            itemBuilderType: widget.itemBuilderType,
            itemBuilder: widget.itemBuilder,
            heightOfInitialLoadingAndEmptyWidget:
                widget.heightOfInitialLoadingAndEmptyWidget,
            gridDelegate: widget.gridDelegate,
            separator: widget.separator,
            shrinkWrap: widget.shrinkWrap,
            reverse: widget.reverse,
            scrollDirection: widget.scrollDirection,
            staggeredAxisDirection: widget.staggeredAxisDirection,
            padding: widget.padding,
            physics: widget.physics,
            scrollController: widget.scrollController,
            allowImplicitScrolling: widget.allowImplicitScrolling,
            keyboardDismissBehavior: widget.keyboardDismissBehavior,
            pageController: widget.pageController,
            onPageChanged: widget.onPageChanged,
            header: widget.header,
            footer: widget.footer,
            bottomLoader: widget.bottomLoader,
            fetchPaginatedList: widget.cubit.fetchPaginatedList,
            cacheExtent: widget.cacheExtent,
            customViewBuilder: widget.customViewBuilder,
            onReorder: widget.onReorder,
            // State Separation Builders
            loadMoreLoadingBuilder: widget.loadMoreLoadingBuilder,
            loadMoreErrorBuilder: widget.loadMoreErrorBuilder,
            loadMoreNoMoreItemsBuilder: widget.loadMoreNoMoreItemsBuilder,
            // Performance
            invisibleItemsThreshold: widget.invisibleItemsThreshold,
            retryLoadMore: widget.cubit.fetchPaginatedList,
          );

          if (widget.listeners != null && widget.listeners!.isNotEmpty) {
            return MultiProvider(
              providers: widget.listeners!
                  .map(
                    (listener) =>
                        ChangeNotifierProvider(create: (context) => listener),
                  )
                  .toList(),
              child: view,
            );
          }

          return view;
        }
      },
    );
  }

  Widget _buildWithScrollView(BuildContext context, Widget child) {
    return SingleChildScrollView(
      child: Container(
        alignment: Alignment.center,
        height:
            widget.heightOfInitialLoadingAndEmptyWidget ??
            MediaQuery.of(context).size.height,
        child: child,
      ),
    );
  }

  @override
  void dispose() {
    if (widget.internalCubit) widget.cubit.dispose();
    super.dispose();
  }

  @override
  void initState() {
    if (widget.listeners != null) {
      for (var listener in widget.listeners!) {
        if (listener is SmartPaginationRefreshedChangeListener) {
          listener.addListener(() {
            if (listener.refreshed) {
              widget.cubit.refreshPaginatedList();
            }
          });
        } else if (listener is SmartPaginationFilterChangeListener<T>) {
          listener.addListener(() {
            if (listener.searchTerm != null) {
              widget.cubit.filterPaginatedList(listener.searchTerm);
            }
          });
        }
      }
    }

    if (!widget.cubit.didFetch) widget.cubit.fetchPaginatedList();
    super.initState();
  }
}
