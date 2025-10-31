import 'package:meta/meta.dart';

/// Metadata describing the state of a paginated response.
///
/// [PaginationMeta] contains information about the current state of pagination,
/// including page numbers, cursors, and availability of additional pages.
/// This class supports both offset-based and cursor-based pagination strategies.
///
/// ## Offset-based pagination example:
///
/// ```dart
/// final meta = PaginationMeta(
///   page: 2,
///   pageSize: 20,
///   hasNext: true,
///   hasPrevious: true,
///   totalCount: 100,
/// );
///
/// print('Current page: ${meta.page}');
/// print('Items per page: ${meta.pageSize}');
/// print('Can load more: ${meta.hasNext}');
/// ```
///
/// ## Cursor-based pagination example:
///
/// ```dart
/// final meta = PaginationMeta(
///   nextCursor: 'eyJpZCI6MTIzfQ==',
///   previousCursor: 'eyJpZCI6MTAwfQ==',
///   hasNext: true,
///   pageSize: 20,
/// );
///
/// // Use nextCursor for the next request
/// final nextRequest = PaginationRequest(cursor: meta.nextCursor);
/// ```
@immutable
class PaginationMeta {
  PaginationMeta({
    this.page,
    this.pageSize,
    this.nextCursor,
    this.previousCursor,
    this.hasNext = false,
    this.hasPrevious = false,
    this.totalCount,
    DateTime? fetchedAt,
  }) : fetchedAt = fetchedAt ?? DateTime.now();

  /// The current page number (1-indexed) when working in offset/page mode.
  final int? page;

  /// The page size that was requested/applied.
  final int? pageSize;

  /// The cursor token returned by the backend to fetch the next page.
  final String? nextCursor;

  /// The cursor token returned by the backend to fetch the previous page.
  final String? previousCursor;

  /// Whether there is another page available after this one.
  final bool hasNext;

  /// Whether there is another page available before this one.
  final bool hasPrevious;

  /// The total number of items across all pages when provided by the backend.
  final int? totalCount;

  /// Timestamp of when this metadata was produced.
  final DateTime fetchedAt;

  PaginationMeta copyWith({
    int? page,
    int? pageSize,
    String? nextCursor,
    String? previousCursor,
    bool? hasNext,
    bool? hasPrevious,
    int? totalCount,
    DateTime? fetchedAt,
  }) {
    return PaginationMeta(
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      nextCursor: nextCursor ?? this.nextCursor,
      previousCursor: previousCursor ?? this.previousCursor,
      hasNext: hasNext ?? this.hasNext,
      hasPrevious: hasPrevious ?? this.hasPrevious,
      totalCount: totalCount ?? this.totalCount,
      fetchedAt: fetchedAt ?? this.fetchedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'page': page,
      'pageSize': pageSize,
      'nextCursor': nextCursor,
      'previousCursor': previousCursor,
      'hasNext': hasNext,
      'hasPrevious': hasPrevious,
      'totalCount': totalCount,
      'fetchedAt': fetchedAt.toIso8601String(),
    }..removeWhere((key, value) => value == null);
  }

  factory PaginationMeta.fromJson(Map<String, dynamic> json) {
    return PaginationMeta(
      page: json['page'] as int?,
      pageSize: json['pageSize'] as int? ?? json['limit'] as int?,
      nextCursor: json['nextCursor'] as String? ?? json['next'] as String?,
      previousCursor:
          json['previousCursor'] as String? ?? json['previous'] as String?,
      hasNext:
          json['hasNext'] as bool? ??
          json['has_next'] as bool? ??
          json['nextCursor'] != null,
      hasPrevious:
          json['hasPrevious'] as bool? ??
          json['has_previous'] as bool? ??
          json['previousCursor'] != null,
      totalCount: json['totalCount'] as int? ?? json['total_count'] as int?,
      fetchedAt:
          json['fetchedAt'] != null
              ? DateTime.tryParse(json['fetchedAt'] as String)
              : DateTime.now(),
    );
  }
}
