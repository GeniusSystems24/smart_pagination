part of '../../pagination.dart';

/// Base interface for pagination controllers that provides common functionality
/// for both SmartPagination and DualPagination controllers.
abstract class IPaginationController<T, R extends PaginationRequest> {
  /// The cubit exposing the REST-backed pagination state.
  IPaginationCubit<T, IPaginationState<T>, R> get cubit;

  /// The refresh listeners to the cubit.
  List<IPaginationRefreshedChangeListener>? get refreshListeners;

  /// The filter listeners to the cubit.
  List<IPaginationFilterChangeListener<T>>? get filterListeners;

  /// The order listeners to the cubit.
  List<IPaginationOrderChangeListener<T>>? get orderListeners;

  /// SliverObserverController for scroll observation and management.
  SliverObserverController? get observerController;

  /// The estimated item height to animate to the specific item.
  double get estimatedItemHeight;

  /// The duration of the animation.
  Duration get animationDuration;

  /// The curve of the animation.
  Curve get animationCurve;

  /// The maximum number of retries to animate to the specific item.
  int get maxRetries;

  /// If `isPublic = true`, the controller will be live until the app is closed.
  bool get isPublic;

  /// Disposes the controller and its resources.
  void dispose();
}

/// Base interface for pagination controllers with scroll capabilities.
abstract class IPaginationScrollController<T, R extends PaginationRequest>
    extends IPaginationController<T, R> {
  /// Animates to the item at the given [index] with smooth scrolling.
  ///
  /// Returns `true` if successful, `false` if no observer controller is attached
  /// or the index is out of bounds.
  Future<bool> animateToIndex(
    int index, {
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
    double alignment = 0.0,
    EdgeInsets padding = EdgeInsets.zero,
    BuildContext? sliverContext,
    bool isFixedHeight = false,
  });

  /// Jumps immediately to the item at the given [index] without animation.
  ///
  /// Returns `true` if successful, `false` if no observer controller is attached
  /// or the index is out of bounds.
  bool jumpToIndex(
    int index, {
    double alignment = 0.0,
    EdgeInsets padding = EdgeInsets.zero,
    BuildContext? sliverContext,
    bool isFixedHeight = false,
  });

  /// Scrolls to make the item at [index] visible, using animation if [animate] is true.
  ///
  /// This is a convenience method that calls either [animateToIndex] or [jumpToIndex].
  Future<bool> scrollToIndex(
    int index, {
    bool animate = true,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
    double alignment = 0.0,
    EdgeInsets padding = EdgeInsets.zero,
    BuildContext? sliverContext,
    bool isFixedHeight = false,
  });

  /// Animates to the first item matching the given [test] function.
  ///
  /// Returns `true` if a matching item was found and scrolled to, or `false`
  /// if no match was found or no controller is attached.
  Future<bool> animateFirstWhere(
    bool Function(T item) test, {
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
    double alignment = 0.0,
    EdgeInsets padding = EdgeInsets.zero,
    BuildContext? sliverContext,
    bool isFixedHeight = false,
  });

  /// Jumps immediately to the first item matching the given [test] function.
  ///
  /// Returns `true` if a matching item was found and scrolled to, or `false`
  /// if no match was found or no controller is attached.
  bool jumpFirstWhere(
    bool Function(T item) test, {
    double alignment = 0.0,
    EdgeInsets padding = EdgeInsets.zero,
    BuildContext? sliverContext,
    bool isFixedHeight = false,
  });

  /// Scrolls to the first item matching [test], using animation if [animate] is true.
  ///
  /// This is a convenience method that calls either [animateFirstWhere] or [jumpFirstWhere].
  Future<bool> scrollFirstWhere(
    bool Function(T item) test, {
    bool animate = true,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
    double alignment = 0.0,
    EdgeInsets padding = EdgeInsets.zero,
    BuildContext? sliverContext,
    bool isFixedHeight = false,
  });

  /// Disposes scroll resources.
  void disposeScrollMethods();
}
