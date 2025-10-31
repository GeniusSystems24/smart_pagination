import 'package:meta/meta.dart';

/// Lightweight request descriptor used by the pagination cubit.
///
/// [PaginationRequest] encapsulates all the information needed to fetch
/// a page of data. It supports both offset-based (page/pageSize) and
/// cursor-based pagination strategies.
///
/// ## Offset-based pagination:
///
/// ```dart
/// final request = PaginationRequest(
///   page: 1,
///   pageSize: 20,
/// );
///
/// // Next page
/// final nextRequest = request.copyWith(page: request.page + 1);
/// ```
///
/// ## Cursor-based pagination:
///
/// ```dart
/// final request = PaginationRequest(
///   pageSize: 20,
///   cursor: 'next_page_token',
/// );
/// ```
///
/// ## With filters:
///
/// ```dart
/// final request = PaginationRequest(
///   page: 1,
///   pageSize: 20,
///   filters: {
///     'category': 'electronics',
///     'minPrice': 100,
///     'maxPrice': 500,
///   },
/// );
/// ```
///
/// ## With extra metadata:
///
/// ```dart
/// final request = PaginationRequest(
///   page: 1,
///   pageSize: 20,
///   extra: {
///     'sortBy': 'price',
///     'sortOrder': 'desc',
///     'includeDeleted': false,
///   },
/// );
/// ```
@immutable
class PaginationRequest {
  const PaginationRequest({this.page = 1, this.pageSize, this.cursor, this.filters, this.extra})
    : assert(page > 0, 'Page must be greater than 0');

  /// Current page (1-based).
  final int page;

  /// Number of items requested per page.
  final int? pageSize;

  /// Optional cursor/token supplied by the backend.
  final String? cursor;

  /// Optional filter payload forwarded to the data provider.
  final Map<String, dynamic>? filters;

  /// Bag for any additional metadata callers want to persist.
  final Map<String, dynamic>? extra;

  PaginationRequest copyWith({int? page, int? pageSize, String? cursor, Map<String, dynamic>? filters, Map<String, dynamic>? extra}) {
    return PaginationRequest(
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      cursor: cursor ?? this.cursor,
      filters: filters ?? this.filters,
      extra: extra ?? this.extra,
    );
  }
}
