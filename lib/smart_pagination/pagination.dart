import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:scrollview_observer/scrollview_observer.dart';

import '../core/core.dart';
import '../data/data.dart';

part 'bloc/pagination_cubit.dart';
part 'bloc/pagination_listeners.dart';
part 'bloc/pagination_state.dart';
part 'controller/controller.dart';
part '../core/widget/bottom_loader.dart';
part '../core/widget/empty_display.dart';
part '../core/widget/empty_separator.dart';
part '../core/widget/error_display.dart';
part '../core/widget/initial_loader.dart';
part 'widgets/paginate_api_view.dart';
part 'controller/scroll_to_message_mixin.dart';

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
  final Widget Function(BuildContext context, List<T> documents, int index) itemBuilder;
  final void Function(int)? onPageChanged;
  final Widget emptyWidget;
  final Widget loadingWidget;
  final List<SmartPaginationChangeListener>? listeners;
  final ListBuilder<T>? listBuilder;
  final ScrollController? scrollController;
  final SmartPaginationCubit<T> cubit;
  final SmartPaginationLoaded<T> Function(SmartPaginationLoaded<T> state)? beforeBuild;
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
  )? customViewBuilder;

  SmartPagination({
    super.key,
    required PaginationRequest request,
    required PaginationProvider<T> provider,
    required this.itemBuilder,
    this.itemBuilderType = PaginateBuilderType.listView,
    this.heightOfInitialLoadingAndEmptyWidget,
    this.gridDelegate = const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
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

       listeners = refreshListener != null || filterListeners?.isNotEmpty == true
           ? [if (refreshListener != null) refreshListener, ...?filterListeners]
           : null;

  SmartPagination.cubit({
    super.key,
    required this.cubit,
    required this.itemBuilder,
    required this.itemBuilderType,
    this.heightOfInitialLoadingAndEmptyWidget,
    this.gridDelegate = const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
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
    SmartPaginationRefreshedChangeListener? refreshListener,
    List<SmartPaginationFilterChangeListener<T>>? filterListeners,
  }) : internalCubit = false,
       listeners = refreshListener != null || filterListeners?.isNotEmpty == true
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
       gridDelegate = const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
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
       customViewBuilder = null,
       internalCubit = false,
       listeners = refreshListener != null || filterListeners?.isNotEmpty == true
           ? [if (refreshListener != null) refreshListener, ...?filterListeners]
           : null;

  /// Creates a pagination widget as a GridView layout
  /// Similar to PaginatorGridView
  SmartPagination.gridView({
    super.key,
    required this.cubit,
    required this.itemBuilder,
    this.heightOfInitialLoadingAndEmptyWidget,
    this.gridDelegate = const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
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
       internalCubit = false,
       listeners = refreshListener != null || filterListeners?.isNotEmpty == true
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
    SmartPaginationRefreshedChangeListener? refreshListener,
    List<SmartPaginationFilterChangeListener<T>>? filterListeners,
  }) : itemBuilderType = PaginateBuilderType.listView,
       gridDelegate = const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
       separator = separator ?? (scrollDirection == Axis.horizontal ? SizedBox(width: spacing) : SizedBox(height: spacing)),
       staggeredAxisDirection = null,
       pageController = null,
       onPageChanged = null,
       customViewBuilder = null,
       internalCubit = false,
       listeners = refreshListener != null || filterListeners?.isNotEmpty == true
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
       gridDelegate = const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
       separator = separator ?? (scrollDirection == Axis.horizontal ? SizedBox(width: spacing) : SizedBox(height: spacing)),
       staggeredAxisDirection = null,
       scrollController = null,
       cacheExtent = null,
       customViewBuilder = null,
       internalCubit = false,
       listeners = refreshListener != null || filterListeners?.isNotEmpty == true
           ? [if (refreshListener != null) refreshListener, ...?filterListeners]
           : null;

  /// Creates a pagination widget as a StaggeredGridView layout
  /// Similar to PaginatorFirestoreStaggeredGridView
  SmartPagination.staggeredGridView({
    super.key,
    required this.cubit,
    required StaggeredGridTile Function(BuildContext context, List<T> documents, int index) this.itemBuilder,
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
       internalCubit = false,
       listeners = refreshListener != null || filterListeners?.isNotEmpty == true
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
       gridDelegate = const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
       separator = separator ?? SizedBox(width: spacing),
       shrinkWrap = true,
       scrollDirection = Axis.horizontal,
       staggeredAxisDirection = null,
       physics = const NeverScrollableScrollPhysics(),
       scrollController = null,
       pageController = null,
       onPageChanged = null,
       customViewBuilder = null,
       internalCubit = false,
       listeners = refreshListener != null || filterListeners?.isNotEmpty == true
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
          return _buildWithScrollView(context, widget.loadingWidget);
        } else if (state is SmartPaginationError<T>) {
          return _buildWithScrollView(
            context,
            (widget.onError != null) ? widget.onError!(state.error) : ErrorDisplay(exception: state.error),
          );
        } else {
          final loadedState = state as SmartPaginationLoaded<T>;
          if (widget.onLoaded != null) {
            widget.onLoaded!(loadedState);
          }
          if (loadedState.hasReachedEnd && widget.onReachedEnd != null) {
            widget.onReachedEnd!(loadedState);
          }

          final beforeBuildState = widget.beforeBuild?.call(loadedState) ?? loadedState;

          if (beforeBuildState.items.isEmpty) {
            return _buildWithScrollView(context, widget.emptyWidget);
          }

          final view = PaginateApiView(
            loadedState: beforeBuildState,
            itemBuilderType: widget.itemBuilderType,
            itemBuilder: widget.itemBuilder,
            heightOfInitialLoadingAndEmptyWidget: widget.heightOfInitialLoadingAndEmptyWidget,
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
          );

          if (widget.listeners != null && widget.listeners!.isNotEmpty) {
            return MultiProvider(
              providers: widget.listeners!.map((listener) => ChangeNotifierProvider(create: (context) => listener)).toList(),
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
        height: widget.heightOfInitialLoadingAndEmptyWidget ?? MediaQuery.of(context).size.height,
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
