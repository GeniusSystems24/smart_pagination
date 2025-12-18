part of '../../pagination.dart';

@immutable
abstract class SmartPaginationState<T> implements IPaginationInitialState<T> {
  @override
  bool get hasReachedEnd => false;

  @override
  DateTime get lastUpdate => DateTime.now();

  @override
  PaginationMeta? get meta => null;
}

class SmartPaginationInitial<T> extends SmartPaginationState<T> {}

class SmartPaginationError<T> extends SmartPaginationState<T>
    implements IPaginationErrorState<T> {
  final Exception _error;
  SmartPaginationError({required Exception error}) : _error = error;

  @override
  Exception get error => _error;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SmartPaginationError<T> && other.error == error;
  }

  @override
  int get hashCode => error.hashCode;
}

class SmartPaginationLoaded<T> extends SmartPaginationState<T>
    implements IPaginationLoadedState<T> {
  SmartPaginationLoaded({
    required this.items,
    required this.allItems,
    required this.meta,
    required this.hasReachedEnd,
    DateTime? lastUpdate,
    this.isLoadingMore = false,
    this.loadMoreError,
    this.fetchedAt,
    this.dataExpiredAt,
    this.activeOrderId,
  }) : lastUpdate = lastUpdate ?? DateTime.now();

  final List<T> items;
  @override
  final List<T> allItems;
  @override
  final PaginationMeta meta;
  @override
  final bool hasReachedEnd;
  @override
  final DateTime lastUpdate;

  /// Whether the pagination is currently loading more items
  final bool isLoadingMore;

  /// Error that occurred while loading more items (if any)
  final Exception? loadMoreError;

  /// Timestamp when data was initially fetched (for data age tracking)
  final DateTime? fetchedAt;

  /// Timestamp when data will expire (null if no expiration configured)
  final DateTime? dataExpiredAt;

  /// The ID of the currently active sort order (null if no sorting applied)
  final String? activeOrderId;

  SmartPaginationLoaded<T> copyWith({
    List<T>? items,
    List<T>? allItems,
    bool? hasReachedEnd,
    PaginationMeta? meta,
    DateTime? lastUpdate,
    bool? isLoadingMore,
    Exception? loadMoreError,
    DateTime? fetchedAt,
    DateTime? dataExpiredAt,
    String? activeOrderId,
  }) {
    final updatedAllItems = allItems ?? this.allItems;
    final updatedItems = items ?? this.items;

    return SmartPaginationLoaded<T>(
      items: updatedItems,
      allItems: updatedAllItems,
      hasReachedEnd: hasReachedEnd ?? this.hasReachedEnd,
      meta: meta ?? this.meta,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      loadMoreError: loadMoreError ?? this.loadMoreError,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      dataExpiredAt: dataExpiredAt ?? this.dataExpiredAt,
      activeOrderId: activeOrderId ?? this.activeOrderId,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SmartPaginationLoaded<T> &&
        other.hasReachedEnd == hasReachedEnd &&
        listEquals(other.items, items) &&
        listEquals(other.allItems, allItems) &&
        other.meta == meta;
  }

  @override
  int get hashCode => Object.hash(
    hasReachedEnd,
    Object.hashAll(items),
    Object.hashAll(allItems),
    meta,
  );
}
