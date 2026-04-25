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

  /// Enables pull-to-refresh integration via [RefreshIndicator].
  final bool canRefresh;

  /// Custom refresh callback. If not provided, [cubit.reload] is used.
  final Future<void> Function(SmartPaginationCubit<T> cubit)? onRefresh;

  // ========== Partial Update & Animation Options ==========

  /// Provides a unique key for each item, enabling efficient partial updates
  /// and animations when items are added, updated, or removed.
  ///
  /// When provided for ListView, [SliverAnimatedList] is used for smooth
  /// insert/remove animations. For other view types, items are wrapped
  /// in [KeyedSubtree] for efficient Flutter reconciliation.
  final Object Function(T item, int index)? itemKeyBuilder;

  /// Controls when the widget rebuilds in response to state changes.
  /// If not provided, the widget rebuilds on every state change.
  final BlocBuilderCondition<SmartPaginationState<T>>? buildWhen;

  /// Custom animation builder for item insertion.
  /// If not provided, a default fade + size animation is used.
  final Widget Function(
    BuildContext context,
    int index,
    Animation<double> animation,
    Widget child,
  )?
  insertItemAnimationBuilder;

  /// Custom animation builder for item removal.
  /// If not provided, a default fade + size animation is used.
  final Widget Function(
    BuildContext context,
    int index,
    Animation<double> animation,
    Widget child,
  )?
  removeItemAnimationBuilder;

  /// Duration of insert/remove animations. Defaults to 300ms.
  final Duration animationDuration;

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
    this.canRefresh = false,
    this.onRefresh,
    this.itemKeyBuilder,
    this.buildWhen,
    this.insertItemAnimationBuilder,
    this.removeItemAnimationBuilder,
    this.animationDuration = const Duration(milliseconds: 300),
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
    this.canRefresh = false,
    this.onRefresh,
    this.itemKeyBuilder,
    this.buildWhen,
    this.insertItemAnimationBuilder,
    this.removeItemAnimationBuilder,
    this.animationDuration = const Duration(milliseconds: 300),
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
    this.canRefresh = false,
    this.onRefresh,
    this.itemKeyBuilder,
    this.buildWhen,
    this.insertItemAnimationBuilder,
    this.removeItemAnimationBuilder,
    this.animationDuration = const Duration(milliseconds: 300),
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
    this.canRefresh = false,
    this.onRefresh,
    this.itemKeyBuilder,
    this.buildWhen,
    this.insertItemAnimationBuilder,
    this.removeItemAnimationBuilder,
    this.animationDuration = const Duration(milliseconds: 300),
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
    this.canRefresh = false,
    this.onRefresh,
    this.itemKeyBuilder,
    this.buildWhen,
    this.insertItemAnimationBuilder,
    this.removeItemAnimationBuilder,
    this.animationDuration = const Duration(milliseconds: 300),
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
    this.canRefresh = false,
    this.onRefresh,
    this.itemKeyBuilder,
    this.buildWhen,
    this.insertItemAnimationBuilder,
    this.removeItemAnimationBuilder,
    this.animationDuration = const Duration(milliseconds: 300),
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
    this.canRefresh = false,
    this.onRefresh,
    this.itemKeyBuilder,
    this.buildWhen,
    this.insertItemAnimationBuilder,
    this.removeItemAnimationBuilder,
    this.animationDuration = const Duration(milliseconds: 300),
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
    this.canRefresh = false,
    this.onRefresh,
    this.itemKeyBuilder,
    this.buildWhen,
    this.insertItemAnimationBuilder,
    this.removeItemAnimationBuilder,
    this.animationDuration = const Duration(milliseconds: 300),
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
    this.canRefresh = false,
    this.onRefresh,
    this.itemKeyBuilder,
    this.buildWhen,
    this.insertItemAnimationBuilder,
    this.removeItemAnimationBuilder,
    this.animationDuration = const Duration(milliseconds: 300),
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
    this.canRefresh = false,
    this.onRefresh,
    this.itemKeyBuilder,
    this.buildWhen,
    this.insertItemAnimationBuilder,
    this.removeItemAnimationBuilder,
    this.animationDuration = const Duration(milliseconds: 300),
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
    this.canRefresh = false,
    this.onRefresh,
    this.itemKeyBuilder,
    this.buildWhen,
    this.insertItemAnimationBuilder,
    this.removeItemAnimationBuilder,
    this.animationDuration = const Duration(milliseconds: 300),
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
    this.canRefresh = false,
    this.onRefresh,
    this.itemKeyBuilder,
    this.buildWhen,
    this.insertItemAnimationBuilder,
    this.removeItemAnimationBuilder,
    this.animationDuration = const Duration(milliseconds: 300),
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
    this.canRefresh = false,
    this.onRefresh,
    this.itemKeyBuilder,
    this.buildWhen,
    this.insertItemAnimationBuilder,
    this.removeItemAnimationBuilder,
    this.animationDuration = const Duration(milliseconds: 300),
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
    this.canRefresh = false,
    this.onRefresh,
    this.itemKeyBuilder,
    this.buildWhen,
    this.insertItemAnimationBuilder,
    this.removeItemAnimationBuilder,
    this.animationDuration = const Duration(milliseconds: 300),
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
    this.canRefresh = false,
    this.onRefresh,
    this.itemKeyBuilder,
    this.buildWhen,
    this.insertItemAnimationBuilder,
    this.removeItemAnimationBuilder,
    this.animationDuration = const Duration(milliseconds: 300),
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
    this.canRefresh = false,
    this.onRefresh,
    this.itemKeyBuilder,
    this.buildWhen,
    this.insertItemAnimationBuilder,
    this.removeItemAnimationBuilder,
    this.animationDuration = const Duration(milliseconds: 300),
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
  bool get _isRefreshEnabled => widget.canRefresh;

  ScrollPhysics _buildRefreshPhysics() {
    return AlwaysScrollableScrollPhysics(parent: widget.physics);
  }

  ScrollPhysics? _effectivePhysics() {
    if (!_isRefreshEnabled) return widget.physics;
    return _buildRefreshPhysics();
  }

  Future<void> _handleRefresh() async {
    final onRefresh = widget.onRefresh;
    if (onRefresh != null) {
      await onRefresh(widget.cubit);
      return;
    }

    widget.cubit.reload();
    await _waitForFetchCompletion();
  }

  Future<void> _waitForFetchCompletion() async {
    while (!widget.cubit.isClosed && !widget.cubit._isFetching) {
      await Future<void>.delayed(const Duration(milliseconds: 16));
    }

    while (widget.cubit._isFetching) {
      await Future<void>.delayed(const Duration(milliseconds: 16));
    }
  }

  Widget _wrapWithRefreshBehavior(Widget child) {
    if (!_isRefreshEnabled) return child;

    if (widget.scrollDirection == Axis.vertical) {
      return RefreshIndicator(onRefresh: _handleRefresh, child: child);
    }

    return _HorizontalPullToRefresh(
      reverse: widget.reverse,
      onRefresh: _handleRefresh,
      child: child,
    );
  }

  Widget _buildFirstPageLoadingWidget(BuildContext context) {
    return widget.firstPageLoadingBuilder?.call(context) ??
        widget.loadingWidget;
  }

  Widget _buildFirstPageErrorWidget(
    BuildContext context,
    SmartPaginationError<T> state,
  ) {
    if (widget.firstPageErrorBuilder != null) {
      return widget.firstPageErrorBuilder!(
        context,
        state.error,
        () => widget.cubit.fetchPaginatedList(),
      );
    }

    if (widget.onError != null) {
      return widget.onError!(state.error);
    }

    return ErrorDisplay(exception: state.error);
  }

  Widget _buildFirstPageEmptyWidget(BuildContext context) {
    return widget.firstPageEmptyBuilder?.call(context) ?? widget.emptyWidget;
  }

  /// Default [buildWhen] used when the user does not supply one.
  /// Rebuilds the top-level widget only when something visually relevant
  /// changes:
  ///  - state runtimeType changes (Initial/Error/Loaded transitions);
  ///  - the items list reference changes (insert/update/remove/reload);
  ///  - hasReachedEnd, isLoadingMore, or loadMoreError flip;
  ///  - lastOperation changes (so animated paths get the right signal).
  /// Pure metadata-only changes (e.g. [SmartPaginationLoaded.lastUpdate]
  /// or [SmartPaginationLoaded.fetchedAt]) no longer cause a rebuild.
  bool _defaultBuildWhen(
    SmartPaginationState<T> previous,
    SmartPaginationState<T> current,
  ) {
    if (previous.runtimeType != current.runtimeType) return true;
    if (previous is SmartPaginationLoaded<T> &&
        current is SmartPaginationLoaded<T>) {
      if (!identical(previous.items, current.items)) return true;
      if (previous.hasReachedEnd != current.hasReachedEnd) return true;
      if (previous.isLoadingMore != current.isLoadingMore) return true;
      if (previous.loadMoreError != current.loadMoreError) return true;
      if (!identical(previous.lastOperation, current.lastOperation)) {
        return true;
      }
      return false;
    }
    return previous != current;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SmartPaginationCubit<T>, SmartPaginationState<T>>(
      bloc: widget.cubit,
      buildWhen: widget.buildWhen ?? _defaultBuildWhen,
      builder: (context, state) {
        if (!widget.cubit.didFetch) widget.cubit.fetchPaginatedList();

        if (state is SmartPaginationInitial<T>) {
          return _buildWithScrollView(
            context,
            _buildFirstPageLoadingWidget(context),
          );
        }

        if (state is SmartPaginationError<T>) {
          return _buildWithScrollView(
            context,
            _buildFirstPageErrorWidget(context, state),
          );
        }

        final loadedState = state as SmartPaginationLoaded<T>;
        if (widget.onLoaded != null) {
          widget.onLoaded!(loadedState);
        }
        if (loadedState.hasReachedEnd && widget.onReachedEnd != null) {
          widget.onReachedEnd!(loadedState);
        }

        final beforeBuildState =
            widget.beforeBuild?.call(loadedState) ?? loadedState;

        // Empty state is rendered INSIDE PaginateApiView so that the same
        // CustomScrollView instance (and its scroll controller, observer,
        // and slivers) is preserved across empty <-> non-empty transitions.
        // This eliminates flicker, scroll-position loss, and animation
        // re-runs that happened when we previously swapped to a different
        // widget tree via _buildWithScrollView.
        final view = PaginateApiView(
          loadedState: beforeBuildState,
          itemBuilderType: widget.itemBuilderType,
          itemBuilder: widget.itemBuilder,
          cubit: widget.cubit,
          heightOfInitialLoadingAndEmptyWidget:
              widget.heightOfInitialLoadingAndEmptyWidget,
          gridDelegate: widget.gridDelegate,
          separator: widget.separator,
          shrinkWrap: widget.shrinkWrap,
          reverse: widget.reverse,
          scrollDirection: widget.scrollDirection,
          staggeredAxisDirection: widget.staggeredAxisDirection,
          padding: widget.padding,
          physics: _effectivePhysics(),
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
          loadMoreLoadingBuilder: widget.loadMoreLoadingBuilder,
          loadMoreErrorBuilder: widget.loadMoreErrorBuilder,
          loadMoreNoMoreItemsBuilder: widget.loadMoreNoMoreItemsBuilder,
          firstPageEmptyBuilder: widget.firstPageEmptyBuilder,
          emptyWidget: widget.emptyWidget,
          invisibleItemsThreshold: widget.invisibleItemsThreshold,
          retryLoadMore: widget.cubit.fetchPaginatedList,
          itemKeyBuilder: widget.itemKeyBuilder,
          insertItemAnimationBuilder: widget.insertItemAnimationBuilder,
          removeItemAnimationBuilder: widget.removeItemAnimationBuilder,
          animationDuration: widget.animationDuration,
        );

        Widget content = view;
        if (widget.listeners != null && widget.listeners!.isNotEmpty) {
          content = MultiProvider(
            providers: widget.listeners!
                .map(
                  (listener) =>
                      ChangeNotifierProvider(create: (context) => listener),
                )
                .toList(),
            child: content,
          );
        }

        return _wrapWithRefreshBehavior(content);
      },
    );
  }

  Widget _buildWithScrollView(BuildContext context, Widget child) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final mediaQuerySize = MediaQuery.sizeOf(context);
        final viewportWidth = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : mediaQuerySize.width;
        final viewportHeight = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : mediaQuerySize.height;

        final contentHeight = widget.scrollDirection == Axis.vertical
            ? widget.heightOfInitialLoadingAndEmptyWidget ?? viewportHeight
            : viewportHeight;

        final content = SizedBox(
          width: viewportWidth,
          height: contentHeight,
          child: Align(alignment: Alignment.center, child: child),
        );

        final scrollView = SingleChildScrollView(
          scrollDirection: widget.scrollDirection,
          physics: _effectivePhysics(),
          child: widget.scrollDirection == Axis.vertical
              ? ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: viewportWidth,
                    minHeight: contentHeight,
                  ),
                  child: content,
                )
              : ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: viewportWidth,
                    minHeight: viewportHeight,
                  ),
                  child: content,
                ),
        );

        return _wrapWithRefreshBehavior(scrollView);
      },
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

class _HorizontalPullToRefresh extends StatefulWidget {
  const _HorizontalPullToRefresh({
    required this.child,
    required this.onRefresh,
    required this.reverse,
  });

  final Widget child;
  final Future<void> Function() onRefresh;
  final bool reverse;

  @override
  State<_HorizontalPullToRefresh> createState() =>
      _HorizontalPullToRefreshState();
}

class _HorizontalPullToRefreshState extends State<_HorizontalPullToRefresh> {
  static const double _triggerDistance = 96;
  static const double _indicatorSize = 28;

  double _dragOffset = 0;
  bool _isArmed = false;
  bool _isRefreshing = false;

  bool _handleNotification(ScrollNotification notification) {
    if (notification.depth != 0 ||
        notification.metrics.axis != Axis.horizontal) {
      return false;
    }

    if (_isRefreshing) {
      return false;
    }

    if (notification is ScrollStartNotification) {
      if (!_isAtLeadingEdge(notification.metrics)) {
        _reset();
      }
      return false;
    }

    if (notification is OverscrollNotification) {
      _handleOverscroll(notification);
      return false;
    }

    if (notification is ScrollUpdateNotification) {
      _handleScrollUpdate(notification);
      return false;
    }

    if (notification is ScrollEndNotification) {
      if (_isArmed) {
        _beginRefresh();
      } else {
        _reset();
      }
    }

    return false;
  }

  bool _isAtLeadingEdge(ScrollMetrics metrics) {
    if (widget.reverse) {
      return (metrics.pixels - metrics.maxScrollExtent).abs() <= 0.5;
    }

    return (metrics.pixels - metrics.minScrollExtent).abs() <= 0.5;
  }

  bool _isLeadingDrag(DragUpdateDetails? details) {
    final delta = details?.delta.dx ?? 0;
    return widget.reverse ? delta < 0 : delta > 0;
  }

  void _handleOverscroll(OverscrollNotification notification) {
    if (!_isAtLeadingEdge(notification.metrics) ||
        !_isLeadingDrag(notification.dragDetails)) {
      return;
    }

    final delta =
        notification.dragDetails?.delta.dx.abs() ??
        notification.overscroll.abs();
    _updateDragOffset(_dragOffset + delta);
  }

  void _handleScrollUpdate(ScrollUpdateNotification notification) {
    if (_dragOffset == 0) return;

    if (!_isAtLeadingEdge(notification.metrics) ||
        !_isLeadingDrag(notification.dragDetails)) {
      _reset();
    }
  }

  void _updateDragOffset(double value) {
    final clampedValue = value.clamp(0.0, _triggerDistance * 1.5).toDouble();
    if (clampedValue == _dragOffset) return;

    setState(() {
      _dragOffset = clampedValue;
      _isArmed = _dragOffset >= _triggerDistance;
    });
  }

  void _beginRefresh() {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
      _isArmed = false;
      _dragOffset = _triggerDistance;
    });

    unawaited(
      widget.onRefresh().whenComplete(() {
        if (!mounted) return;

        setState(() {
          _isRefreshing = false;
          _dragOffset = 0;
          _isArmed = false;
        });
      }),
    );
  }

  void _reset() {
    if (_dragOffset == 0 && !_isArmed) return;

    setState(() {
      _dragOffset = 0;
      _isArmed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final progress = _isRefreshing
        ? null
        : (_dragOffset / _triggerDistance).clamp(0.0, 1.0).toDouble();

    return NotificationListener<ScrollNotification>(
      onNotification: _handleNotification,
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          widget.child,
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedOpacity(
                opacity: (_dragOffset > 0 || _isRefreshing) ? 1 : 0,
                duration: const Duration(milliseconds: 150),
                child: Align(
                  alignment: widget.reverse
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      width: _indicatorSize,
                      height: _indicatorSize,
                      child: RefreshProgressIndicator(value: progress),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
