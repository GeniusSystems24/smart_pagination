part of '../../pagination.dart';

/// Signature for a function that scrolls the pagination list to a specific item ID.
typedef PaginationScrollToItem =
    Future<bool> Function(
      String itemId, {
      Duration duration,
      Curve curve,
      double alignment,
      double offset,
    });

/// Signature for a function that scrolls the pagination list to a specific index.
typedef PaginationScrollToIndex =
    Future<bool> Function(
      int index, {
      Duration duration,
      Curve curve,
      double alignment,
      double offset,
    });

/// A mixin for [SmartPaginationController] implementations that adds programmatic
/// scrolling capabilities.
///
/// The actual scrolling logic is provided by the UI layer (e.g., `PaginateApiView`)
/// via the [attachScrollMethods] function.
mixin PaginationScrollToItemMixin {
  PaginationScrollToItem? _scrollToItem;
  PaginationScrollToIndex? _scrollToIndex;

  /// Attaches the scroll methods that will be used for scrolling operations.
  /// This is called automatically by PaginateApiView.
  void attachScrollMethods({
    required PaginationScrollToItem scrollToItem,
    required PaginationScrollToIndex scrollToIndex,
  }) {
    _scrollToItem = scrollToItem;
    _scrollToIndex = scrollToIndex;
  }

  /// Detaches the scroll methods when the widget is disposed.
  void detachScrollMethods() {
    _scrollToItem = null;
    _scrollToIndex = null;
  }

  /// Scrolls to a specific item by Path.
  Future<bool> scrollToItem(
    String itemPath, {
    Duration duration = const Duration(milliseconds: 250),
    Curve curve = Curves.linearToEaseOut,

    /// Desired position of the item in viewport [0.0, 1.0].
    /// 0 = top, 0.5 = middle, 1 = bottom
    double alignment = 0,
    double offset = 0,
  }) {
    if (_scrollToItem == null) {
      return Future.value(false);
    }

    return (_scrollToItem as PaginationScrollToItem)(
      itemPath,
      duration: duration,
      curve: curve,
      alignment: alignment,
      offset: offset,
    );
  }

  /// Scrolls to a specific index in the item list.
  Future<bool> scrollToIndex(
    int index, {
    Duration duration = const Duration(milliseconds: 250),
    Curve curve = Curves.linearToEaseOut,

    /// Desired position of the item in viewport [0.0, 1.0].
    /// 0 = top, 0.5 = middle, 1 = bottom
    double alignment = 0,
    double offset = 0,
  }) {
    if (_scrollToIndex == null) {
      return Future.value(false);
    }

    return (_scrollToIndex as PaginationScrollToIndex)(
      index,
      duration: duration,
      curve: curve,
      alignment: alignment,
      offset: offset,
    );
  }

  /// Disposes scroll resources. This should be called in the SmartPaginationController's dispose method.
  void disposeScrollMethods() {
    detachScrollMethods();
  }
}
