import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:scrollview_observer/scrollview_observer.dart';

import '../data/data.dart';

// Export error handling utilities
export 'error_handling.dart';

// Core interfaces for pagination system
part 'bloc/pagination_cubit.dart';
part 'bloc/pagination_listeners.dart';
part 'bloc/pagination_state.dart';
part 'controller/controller.dart';

typedef WhereChecker<T> = bool Function(T item);
typedef CompareBy<T> = int Function(T a, T b);
typedef OnInsertionCallback<T> = void Function(List<T> items);

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

/// Signature for a function that builds a list from fetched items.
typedef ListBuilder<T> = List<T> Function(List<T> list);

/// Signature for a callback function that is called when items are inserted.
typedef InsertAllCallback<T> =
    void Function(List<T> currentItems, Iterable<T> newItems);

/// Base mixin for pagination controllers with scroll capabilities.
mixin PaginationScrollToItemMixin {
  PaginationScrollToItem? _scrollToItem;
  PaginationScrollToIndex? _scrollToIndex;

  /// Attaches the scroll methods that will be used for scrolling operations.
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

  /// Disposes scroll resources.
  void disposeScrollMethods() {
    detachScrollMethods();
  }
}
