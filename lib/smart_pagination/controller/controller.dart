part of '../../pagination.dart';

class SmartPaginationController<T, F extends Object?>
    implements IPaginationScrollController<T, F> {
  SmartPaginationController({
    required SmartPaginationCubit<T, F> cubit,
    this.isPublic = false,
    this.estimatedItemHeight = 60.0,
    this.animationDuration = const Duration(milliseconds: 500),
    this.animationCurve = Curves.easeInOut,
    this.maxRetries = 10,
    this.refreshListeners,
    this.filterListeners,
    this.orderListeners,
  }) : _cubit = cubit;

  factory SmartPaginationController.of({
    required PaginationRequest<F> request,
    required PaginationProvider<T, F> provider,
    ListBuilder<T>? listBuilder,
    OnInsertionCallback<T>? onInsertionCallback,
    VoidCallback? onClear,
    bool isPublic = false,
    double estimatedItemHeight = 60,
    Duration animationDuration = const Duration(milliseconds: 500),
    Curve animationCurve = Curves.easeInOut,
    int maxRetries = 10,
    List<IPaginationRefreshedChangeListener>? refreshListeners,
    List<IPaginationFilterChangeListener<T>>? filterListeners,
    List<IPaginationOrderChangeListener<T>>? orderListeners,
  }) {
    final cubit = SmartPaginationCubit<T, F>(
      request: request,
      provider: provider,
      listBuilder: listBuilder,
      onInsertionCallback: onInsertionCallback,
      onClear: onClear,
    );

    return SmartPaginationController<T, F>(
      cubit: cubit,
      isPublic: isPublic,
      estimatedItemHeight: estimatedItemHeight,
      animationDuration: animationDuration,
      animationCurve: animationCurve,
      maxRetries: maxRetries,
      refreshListeners: refreshListeners,
      filterListeners: filterListeners,
      orderListeners: orderListeners,
    );
  }

  final SmartPaginationCubit<T, F> _cubit;

  @override
  SmartPaginationCubit<T, F> get cubit => _cubit;

  @override
  SliverObserverController? observerController;

  @override
  final double estimatedItemHeight;

  @override
  final Duration animationDuration;

  @override
  final Curve animationCurve;

  @override
  final int maxRetries;

  @override
  final List<IPaginationFilterChangeListener<T>>? filterListeners;
  @override
  final List<IPaginationOrderChangeListener<T>>? orderListeners;
  @override
  final List<IPaginationRefreshedChangeListener>? refreshListeners;

  /// If `isPublic = true`, the controller will persist even when widgets dispose.
  @override
  final bool isPublic;

  // ==================== SCROLL NAVIGATION ====================

  @override
  Future<bool> animateToIndex(
    int index, {
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
    double alignment = 0.0,
    EdgeInsets padding = EdgeInsets.zero,
    BuildContext? sliverContext,
    bool isFixedHeight = false,
  }) {
    return _cubit.animateToIndex(
      index,
      duration: duration,
      curve: curve,
      alignment: alignment,
      padding: padding,
      sliverContext: sliverContext,
      isFixedHeight: isFixedHeight,
    );
  }

  @override
  bool jumpToIndex(
    int index, {
    double alignment = 0.0,
    EdgeInsets padding = EdgeInsets.zero,
    BuildContext? sliverContext,
    bool isFixedHeight = false,
  }) {
    return _cubit.jumpToIndex(
      index,
      alignment: alignment,
      padding: padding,
      sliverContext: sliverContext,
      isFixedHeight: isFixedHeight,
    );
  }

  @override
  Future<bool> scrollToIndex(
    int index, {
    bool animate = true,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
    double alignment = 0.0,
    EdgeInsets padding = EdgeInsets.zero,
    BuildContext? sliverContext,
    bool isFixedHeight = false,
  }) {
    return _cubit.scrollToIndex(
      index,
      animate: animate,
      duration: duration,
      curve: curve,
      alignment: alignment,
      padding: padding,
      sliverContext: sliverContext,
      isFixedHeight: isFixedHeight,
    );
  }

  @override
  Future<bool> animateFirstWhere(
    bool Function(T item) test, {
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
    double alignment = 0.0,
    EdgeInsets padding = EdgeInsets.zero,
    BuildContext? sliverContext,
    bool isFixedHeight = false,
  }) {
    return _cubit.animateFirstWhere(
      test,
      duration: duration,
      curve: curve,
      alignment: alignment,
      padding: padding,
      sliverContext: sliverContext,
      isFixedHeight: isFixedHeight,
    );
  }

  @override
  bool jumpFirstWhere(
    bool Function(T item) test, {
    double alignment = 0.0,
    EdgeInsets padding = EdgeInsets.zero,
    BuildContext? sliverContext,
    bool isFixedHeight = false,
  }) {
    return _cubit.jumpFirstWhere(
      test,
      alignment: alignment,
      padding: padding,
      sliverContext: sliverContext,
      isFixedHeight: isFixedHeight,
    );
  }

  @override
  Future<bool> scrollFirstWhere(
    bool Function(T item) test, {
    bool animate = true,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
    double alignment = 0.0,
    EdgeInsets padding = EdgeInsets.zero,
    BuildContext? sliverContext,
    bool isFixedHeight = false,
  }) {
    return _cubit.scrollFirstWhere(
      test,
      animate: animate,
      duration: duration,
      curve: curve,
      alignment: alignment,
      padding: padding,
      sliverContext: sliverContext,
      isFixedHeight: isFixedHeight,
    );
  }

  @override
  void disposeScrollMethods() {
    // No-op: scroll methods delegate directly to cubit,
    // which manages its own observer controller lifecycle.
  }

  // ==================== END SCROLL NAVIGATION ====================

  /// Dispose the controller.
  @override
  void dispose() {
    if (!isPublic) {
      _cubit.dispose();
    }
  }
}
