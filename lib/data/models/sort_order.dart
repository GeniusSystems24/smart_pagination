part of '../../../pagination.dart';

/// Defines the direction of sorting.
enum SortDirection {
  /// Sort items in ascending order (A-Z, 0-9, oldest first).
  ascending,

  /// Sort items in descending order (Z-A, 9-0, newest first).
  descending,
}

/// A comparator function that compares two items of type [T].
typedef ItemComparator<T> = int Function(T a, T b);

/// Configuration for sorting paginated items.
///
/// Allows you to define how items should be sorted by providing either:
/// - A custom [comparator] function for complete control
/// - A [fieldSelector] with a [direction] for simple field-based sorting
///
/// Example usage:
/// ```dart
/// // Using comparator
/// final byPrice = SortOrder<Product>(
///   id: 'price',
///   label: 'Price',
///   comparator: (a, b) => a.price.compareTo(b.price),
/// );
///
/// // Using field selector
/// final byName = SortOrder<Product>.byField(
///   id: 'name',
///   label: 'Name',
///   fieldSelector: (product) => product.name,
///   direction: SortDirection.ascending,
/// );
///
/// // Descending order
/// final byNewest = SortOrder<Product>.byField(
///   id: 'createdAt',
///   label: 'Newest First',
///   fieldSelector: (product) => product.createdAt,
///   direction: SortDirection.descending,
/// );
/// ```
class SortOrder<T> {
  /// Creates a sort order with a custom comparator.
  ///
  /// [id] - Unique identifier for this sort order.
  /// [label] - Human-readable label for display in UI.
  /// [comparator] - Function that compares two items.
  const SortOrder({
    required this.id,
    required this.label,
    required ItemComparator<T> comparator,
  })  : _comparator = comparator,
        _fieldSelector = null,
        _direction = SortDirection.ascending;

  /// Creates a sort order based on a field selector.
  ///
  /// [id] - Unique identifier for this sort order.
  /// [label] - Human-readable label for display in UI.
  /// [fieldSelector] - Function that extracts the comparable field from an item.
  /// [direction] - Sort direction (ascending or descending).
  SortOrder.byField({
    required this.id,
    required this.label,
    required Comparable Function(T item) fieldSelector,
    SortDirection direction = SortDirection.ascending,
  })  : _comparator = null,
        _fieldSelector = fieldSelector,
        _direction = direction;

  /// Unique identifier for this sort order.
  final String id;

  /// Human-readable label for display in UI.
  final String label;

  /// Custom comparator function.
  final ItemComparator<T>? _comparator;

  /// Field selector for simple field-based sorting.
  final Comparable Function(T item)? _fieldSelector;

  /// Sort direction (ascending or descending).
  final SortDirection _direction;

  /// Returns the sort direction.
  SortDirection get direction => _direction;

  /// Compares two items according to this sort order.
  int compare(T a, T b) {
    if (_comparator != null) {
      return _comparator!(a, b);
    }

    if (_fieldSelector != null) {
      final valueA = _fieldSelector!(a);
      final valueB = _fieldSelector!(b);
      final result = valueA.compareTo(valueB);
      return _direction == SortDirection.descending ? -result : result;
    }

    return 0;
  }

  /// Creates a reversed version of this sort order.
  SortOrder<T> get reversed {
    if (_comparator != null) {
      final comparator = _comparator!;
      return SortOrder<T>(
        id: id,
        label: label,
        comparator: (a, b) => -comparator(a, b),
      );
    }

    if (_fieldSelector != null) {
      return SortOrder<T>.byField(
        id: id,
        label: label,
        fieldSelector: _fieldSelector!,
        direction: _direction == SortDirection.ascending
            ? SortDirection.descending
            : SortDirection.ascending,
      );
    }

    return this;
  }

  /// Sorts a list of items according to this sort order.
  List<T> sort(List<T> items) {
    final sorted = List<T>.from(items);
    sorted.sort(compare);
    return sorted;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SortOrder<T> && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'SortOrder(id: $id, label: $label, direction: $_direction)';
}

/// A collection of sort orders with a selected active order.
///
/// This class manages multiple sorting options and tracks which one
/// is currently active.
///
/// Example:
/// ```dart
/// final orders = SortOrderCollection<Product>(
///   orders: [
///     SortOrder.byField(
///       id: 'name',
///       label: 'Name',
///       fieldSelector: (p) => p.name,
///     ),
///     SortOrder.byField(
///       id: 'price',
///       label: 'Price',
///       fieldSelector: (p) => p.price,
///     ),
///   ],
///   defaultOrderId: 'name',
/// );
/// ```
class SortOrderCollection<T> {
  /// Creates a collection of sort orders.
  ///
  /// [orders] - List of available sort orders.
  /// [defaultOrderId] - ID of the default sort order (optional).
  SortOrderCollection({
    required List<SortOrder<T>> orders,
    String? defaultOrderId,
  })  : _orders = Map.fromEntries(orders.map((o) => MapEntry(o.id, o))),
        _defaultOrderId = defaultOrderId ?? (orders.isNotEmpty ? orders.first.id : null),
        _activeOrderId = defaultOrderId ?? (orders.isNotEmpty ? orders.first.id : null);

  final Map<String, SortOrder<T>> _orders;
  final String? _defaultOrderId;
  String? _activeOrderId;

  /// Returns all available sort orders.
  List<SortOrder<T>> get orders => _orders.values.toList();

  /// Returns the currently active sort order, or null if none is active.
  SortOrder<T>? get activeOrder =>
      _activeOrderId != null ? _orders[_activeOrderId] : null;

  /// Returns the ID of the currently active sort order.
  String? get activeOrderId => _activeOrderId;

  /// Returns the default sort order, or null if none is set.
  SortOrder<T>? get defaultOrder =>
      _defaultOrderId != null ? _orders[_defaultOrderId] : null;

  /// Returns the ID of the default sort order.
  String? get defaultOrderId => _defaultOrderId;

  /// Sets the active sort order by ID.
  ///
  /// Returns true if the order was found and set, false otherwise.
  bool setActiveOrder(String orderId) {
    if (_orders.containsKey(orderId)) {
      _activeOrderId = orderId;
      return true;
    }
    return false;
  }

  /// Resets to the default sort order.
  void resetToDefault() {
    _activeOrderId = _defaultOrderId;
  }

  /// Clears the active sort order (no sorting will be applied).
  void clearActiveOrder() {
    _activeOrderId = null;
  }

  /// Gets a sort order by ID.
  SortOrder<T>? getOrder(String orderId) => _orders[orderId];

  /// Adds a new sort order to the collection.
  void addOrder(SortOrder<T> order) {
    _orders[order.id] = order;
  }

  /// Removes a sort order by ID.
  bool removeOrder(String orderId) {
    if (_orders.remove(orderId) != null) {
      if (_activeOrderId == orderId) {
        _activeOrderId = _defaultOrderId;
      }
      return true;
    }
    return false;
  }

  /// Sorts items using the active sort order.
  ///
  /// If no active order is set, returns the items unchanged.
  List<T> sortItems(List<T> items) {
    final order = activeOrder;
    if (order == null) return items;
    return order.sort(items);
  }

  /// Creates a copy of this collection with updated active order.
  SortOrderCollection<T> copyWith({String? activeOrderId}) {
    final copy = SortOrderCollection<T>(
      orders: orders,
      defaultOrderId: _defaultOrderId,
    );
    copy._activeOrderId = activeOrderId ?? _activeOrderId;
    return copy;
  }

  @override
  String toString() =>
      'SortOrderCollection(orders: ${_orders.keys}, active: $_activeOrderId, default: $_defaultOrderId)';
}
