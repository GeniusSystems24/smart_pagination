/// Re-export the main pagination library for backward compatibility.
///
/// This file is deprecated. Please import 'package:smart_pagination/pagination.dart' instead.

part of '../pagination.dart';

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
  final Widget Function(
    BuildContext context,
    Exception error,
    VoidCallback retry,
  )?
  firstPageErrorBuilder;

  /// Builder for first page empty state (no items found)
  /// If not provided, falls back to [emptyWidget]
  final Widget Function(BuildContext context)? firstPageEmptyBuilder;

  /// Builder for load more loading indicator
  /// If not provided, falls back to [bottomLoader]
  final Widget Function(BuildContext context)? loadMoreLoadingBuilder;

  /// Builder for load more error state with retry capability
  final Widget Function(
    BuildContext context,
    Exception error,
    VoidCallback retry,
  )?
  loadMoreErrorBuilder;

  /// Builder for end of list indicator (no more items to load)
  final Widget Function(BuildContext context)? loadMoreNoMoreItemsBuilder;

  // ========== Performance Options ==========

  /// Number of items before the end that triggers loading more items
  /// Default is 3 - starts loading when user is 3 items away from the end
  final int invisibleItemsThreshold;

  SmartPagination.withProvider({
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

  SmartPagination.withCubit({
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
  SmartPagination.columnWithProvider({
    super.key,
    required PaginationRequest request,
    required PaginationProvider<T> provider,
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
    OnInsertionCallback<T>? onInsertionCallback,
    VoidCallback? onClear,
    Logger? logger,
    int maxPagesInMemory = 5,
    RetryConfig? retryConfig,
    this.scrollController,
    this.cacheExtent,
    this.firstPageLoadingBuilder,
    this.firstPageErrorBuilder,
    this.firstPageEmptyBuilder,
    this.loadMoreLoadingBuilder,
    this.loadMoreErrorBuilder,
    this.loadMoreNoMoreItemsBuilder,
    this.invisibleItemsThreshold = 3,
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
       keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
       pageController = null,
       onPageChanged = null,
       customViewBuilder = null,
       onReorder = null,
       internalCubit = true,
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

  /// Creates a pagination widget as a Column layout (non-scrollable)
  /// with an external Cubit
  SmartPagination.columnWithCubit({
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
    this.scrollController,
    this.cacheExtent,
    this.firstPageLoadingBuilder,
    this.firstPageErrorBuilder,
    this.firstPageEmptyBuilder,
    this.loadMoreLoadingBuilder,
    this.loadMoreErrorBuilder,
    this.loadMoreNoMoreItemsBuilder,
    this.invisibleItemsThreshold = 3,
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
       keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
       pageController = null,
       onPageChanged = null,
       customViewBuilder = null,
       onReorder = null,
       internalCubit = false,
       listeners =
           refreshListener != null || filterListeners?.isNotEmpty == true
           ? [if (refreshListener != null) refreshListener, ...?filterListeners]
           : null;

  /// Creates a pagination widget as a GridView layout
  /// Similar to PaginatorGridView
  SmartPagination.gridViewWithProvider({
    super.key,
    required PaginationRequest request,
    required PaginationProvider<T> provider,
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
    // Cubit params
    OnInsertionCallback<T>? onInsertionCallback,
    VoidCallback? onClear,
    Logger? logger,
    int maxPagesInMemory = 5,
    RetryConfig? retryConfig,
    this.firstPageLoadingBuilder,
    this.firstPageErrorBuilder,
    this.firstPageEmptyBuilder,
    this.loadMoreLoadingBuilder,
    this.loadMoreErrorBuilder,
    this.loadMoreNoMoreItemsBuilder,
    this.invisibleItemsThreshold = 3,
  }) : itemBuilderType = PaginateBuilderType.gridView,
       separator = separator ?? SizedBox(height: spacing),
       staggeredAxisDirection = null,
       pageController = null,
       onPageChanged = null,
       customViewBuilder = null,
       onReorder = null,
       internalCubit = true,
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

  /// Creates a pagination widget as a GridView layout
  /// with an external Cubit
  SmartPagination.gridViewWithCubit({
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
    this.firstPageLoadingBuilder,
    this.firstPageErrorBuilder,
    this.firstPageEmptyBuilder,
    this.loadMoreLoadingBuilder,
    this.loadMoreErrorBuilder,
    this.loadMoreNoMoreItemsBuilder,
    this.invisibleItemsThreshold = 3,
  }) : itemBuilderType = PaginateBuilderType.gridView,
       separator = separator ?? SizedBox(height: spacing),
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

  /// Creates a pagination widget as a ListView layout
  /// Similar to PaginatorListView
  SmartPagination.listViewWithProvider({
    super.key,
    required PaginationRequest request,
    required PaginationProvider<T> provider,
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
    // Cubit params
    OnInsertionCallback<T>? onInsertionCallback,
    VoidCallback? onClear,
    Logger? logger,
    int maxPagesInMemory = 5,
    RetryConfig? retryConfig,
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
       internalCubit = true,
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

  /// Creates a pagination widget as a ListView layout
  /// with an external Cubit
  SmartPagination.listViewWithCubit({
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

  /// Creates a pagination widget as a ReorderableListView layout
  SmartPagination.reorderableListViewWithProvider({
    super.key,
    required PaginationRequest request,
    required PaginationProvider<T> provider,
    required this.itemBuilder,
    required this.onReorder,
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
    // Cubit params
    OnInsertionCallback<T>? onInsertionCallback,
    VoidCallback? onClear,
    Logger? logger,
    int maxPagesInMemory = 5,
    RetryConfig? retryConfig,
  }) : itemBuilderType = PaginateBuilderType.reorderableListView,
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
       internalCubit = true,
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

  /// Creates a pagination widget as a ReorderableListView layout
  /// with an external Cubit
  SmartPagination.reorderableListViewWithCubit({
    super.key,
    required this.cubit,
    required this.itemBuilder,
    required this.onReorder,
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
  }) : itemBuilderType = PaginateBuilderType.reorderableListView,
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
       internalCubit = false,
       listeners =
           refreshListener != null || filterListeners?.isNotEmpty == true
           ? [if (refreshListener != null) refreshListener, ...?filterListeners]
           : null;

  /// Creates a pagination widget as a PageView layout
  /// Similar to PaginatorPageView
  SmartPagination.pageViewWithProvider({
    super.key,
    required PaginationRequest request,
    required PaginationProvider<T> provider,
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
    // Cubit params
    OnInsertionCallback<T>? onInsertionCallback,
    VoidCallback? onClear,
    Logger? logger,
    int maxPagesInMemory = 5,
    RetryConfig? retryConfig,
    this.cacheExtent,
    this.firstPageLoadingBuilder,
    this.firstPageErrorBuilder,
    this.firstPageEmptyBuilder,
    this.loadMoreLoadingBuilder,
    this.loadMoreErrorBuilder,
    this.loadMoreNoMoreItemsBuilder,
    this.invisibleItemsThreshold = 3,
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
       customViewBuilder = null,
       onReorder = null,
       internalCubit = true,
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

  /// Creates a pagination widget as a PageView layout
  /// with an external Cubit
  SmartPagination.pageViewWithCubit({
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
    this.cacheExtent,
    this.firstPageLoadingBuilder,
    this.firstPageErrorBuilder,
    this.firstPageEmptyBuilder,
    this.loadMoreLoadingBuilder,
    this.loadMoreErrorBuilder,
    this.loadMoreNoMoreItemsBuilder,
    this.invisibleItemsThreshold = 3,
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
       customViewBuilder = null,
       onReorder = null,
       internalCubit = false,
       listeners =
           refreshListener != null || filterListeners?.isNotEmpty == true
           ? [if (refreshListener != null) refreshListener, ...?filterListeners]
           : null;

  /// Creates a pagination widget as a StaggeredGridView layout
  /// Similar to PaginatorFirestoreStaggeredGridView
  SmartPagination.staggeredGridViewWithProvider({
    super.key,
    required PaginationRequest request,
    required PaginationProvider<T> provider,
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
    // Cubit params
    OnInsertionCallback<T>? onInsertionCallback,
    VoidCallback? onClear,
    Logger? logger,
    int maxPagesInMemory = 5,
    RetryConfig? retryConfig,
    this.scrollController,
    this.cacheExtent,
    this.firstPageLoadingBuilder,
    this.firstPageErrorBuilder,
    this.firstPageEmptyBuilder,
    this.loadMoreLoadingBuilder,
    this.loadMoreErrorBuilder,
    this.loadMoreNoMoreItemsBuilder,
    this.invisibleItemsThreshold = 3,
  }) : itemBuilderType = PaginateBuilderType.staggeredGridView,
       gridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
         crossAxisCount: crossAxisCount,
         mainAxisSpacing: mainAxisSpacing,
         crossAxisSpacing: crossAxisSpacing,
       ),
       separator = separator ?? SizedBox(height: spacing),
       pageController = null,
       onPageChanged = null,
       customViewBuilder = null,
       onReorder = null,
       internalCubit = true,
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

  /// Creates a pagination widget as a StaggeredGridView layout
  /// with an external Cubit
  SmartPagination.staggeredGridViewWithCubit({
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
    this.scrollController,
    this.cacheExtent,
    this.firstPageLoadingBuilder,
    this.firstPageErrorBuilder,
    this.firstPageEmptyBuilder,
    this.loadMoreLoadingBuilder,
    this.loadMoreErrorBuilder,
    this.loadMoreNoMoreItemsBuilder,
    this.invisibleItemsThreshold = 3,
  }) : itemBuilderType = PaginateBuilderType.staggeredGridView,
       gridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
         crossAxisCount: crossAxisCount,
         mainAxisSpacing: mainAxisSpacing,
         crossAxisSpacing: crossAxisSpacing,
       ),
       separator = separator ?? SizedBox(height: spacing),
       pageController = null,
       onPageChanged = null,
       customViewBuilder = null,
       onReorder = null,
       internalCubit = false,
       listeners =
           refreshListener != null || filterListeners?.isNotEmpty == true
           ? [if (refreshListener != null) refreshListener, ...?filterListeners]
           : null;

  /// Creates a pagination widget as a Row layout (horizontal non-scrollable)
  /// Similar to PaginatorRow
  SmartPagination.rowWithProvider({
    super.key,
    required PaginationRequest request,
    required PaginationProvider<T> provider,
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
    // Cubit params
    OnInsertionCallback<T>? onInsertionCallback,
    VoidCallback? onClear,
    Logger? logger,
    int maxPagesInMemory = 5,
    RetryConfig? retryConfig,
    this.scrollController,
    this.firstPageLoadingBuilder,
    this.firstPageErrorBuilder,
    this.firstPageEmptyBuilder,
    this.loadMoreLoadingBuilder,
    this.loadMoreErrorBuilder,
    this.loadMoreNoMoreItemsBuilder,
    this.invisibleItemsThreshold = 3,
  }) : itemBuilderType = PaginateBuilderType.listView,
       gridDelegate = const SliverGridDelegateWithFixedCrossAxisCount(
         crossAxisCount: 2,
       ),
       separator = separator ?? SizedBox(width: spacing),
       shrinkWrap = true,
       scrollDirection = Axis.horizontal,
       staggeredAxisDirection = null,
       physics = const NeverScrollableScrollPhysics(),
       pageController = null,
       onPageChanged = null,
       customViewBuilder = null,
       onReorder = null,
       internalCubit = true,
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

  /// Creates a pagination widget as a Row layout (horizontal non-scrollable)
  /// with an external Cubit
  SmartPagination.rowWithCubit({
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
    this.scrollController,
    this.firstPageLoadingBuilder,
    this.firstPageErrorBuilder,
    this.firstPageEmptyBuilder,
    this.loadMoreLoadingBuilder,
    this.loadMoreErrorBuilder,
    this.loadMoreNoMoreItemsBuilder,
    this.invisibleItemsThreshold = 3,
  }) : itemBuilderType = PaginateBuilderType.listView,
       gridDelegate = const SliverGridDelegateWithFixedCrossAxisCount(
         crossAxisCount: 2,
       ),
       separator = separator ?? SizedBox(width: spacing),
       shrinkWrap = true,
       scrollDirection = Axis.horizontal,
       staggeredAxisDirection = null,
       physics = const NeverScrollableScrollPhysics(),
       pageController = null,
       onPageChanged = null,
       customViewBuilder = null,
       onReorder = null,
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
          final loadingWidget =
              widget.firstPageLoadingBuilder?.call(context) ??
              widget.loadingWidget;
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
            final emptyWidget =
                widget.firstPageEmptyBuilder?.call(context) ??
                widget.emptyWidget;
            return _buildWithScrollView(context, emptyWidget);
          }

          final view = PaginateApiView(
            loadedState: beforeBuildState,
            itemBuilderType: widget.itemBuilderType,
            itemBuilder: widget.itemBuilder,
            cubit: widget.cubit, // Pass cubit for built-in observer
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
