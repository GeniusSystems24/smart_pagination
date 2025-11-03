part of '../pagination.dart';

class SmartPaginationController<T>
    with PaginationScrollToItemMixin
    implements IPaginationScrollController<T> {
  SmartPaginationController({
    required SmartPaginationCubit<T> cubit,
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
    required PaginationRequest request,
    required PaginationProvider<T> provider,
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
    final cubit = SmartPaginationCubit<T>(
      request: request,
      provider: provider,
      listBuilder: listBuilder,
      onInsertionCallback: onInsertionCallback,
      onClear: onClear,
    );

    return SmartPaginationController<T>(
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

  final SmartPaginationCubit<T> _cubit;

  @override
  SmartPaginationCubit<T> get cubit => _cubit;

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

  /// dispose the controller
  @override
  void dispose() {
    if (!isPublic) {
      _cubit.dispose();
    }
    disposeScrollMethods();
  }
}
