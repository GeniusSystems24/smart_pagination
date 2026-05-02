part of '../../pagination.dart';

/// Lightweight request descriptor used by the pagination cubit.
///
/// [PaginationRequest] encapsulates all the information needed to fetch
/// a page of data. It supports both offset-based (page/pageSize) and
/// cursor-based pagination strategies.
///
/// The optional type parameter [F] makes the [filters] field type-safe.
/// When [F] is omitted it defaults to `dynamic`, preserving backward
/// compatibility with code that passes a plain `Map<String, dynamic>`.
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
/// ## With untyped filters (backward-compatible):
///
/// ```dart
/// final request = PaginationRequest(
///   page: 1,
///   pageSize: 20,
///   filters: {
///     'category': 'electronics',
///     'minPrice': 100,
///   },
/// );
/// ```
///
/// ## With typed filters (generic):
///
/// ```dart
/// class ProductFilters {
///   const ProductFilters({required this.category, this.maxPrice});
///   final String category;
///   final double? maxPrice;
/// }
///
/// final request = PaginationRequest<ProductFilters>(
///   page: 1,
///   pageSize: 20,
///   filters: ProductFilters(category: 'electronics', maxPrice: 500),
/// );
/// ```
@immutable
class PaginationRequest<F extends Object?> {
  const PaginationRequest({
    this.page = 1,
    this.pageSize,
    this.cursor,
    this.filters,
    this.extra,
    this.searchQuery,
  }) : assert(page > 0, 'Page must be greater than 0');

  /// Current page (1-based).
  final int page;

  /// Number of items requested per page.
  final int? pageSize;

  /// Optional cursor/token supplied by the backend.
  final String? cursor;

  /// Optional filter payload forwarded to the data provider.
  ///
  /// Typed as [F] for compile-time safety. When [F] is omitted the field
  /// accepts any value (backward-compatible with `Map<String, dynamic>`).
  final F? filters;

  /// Bag for any additional metadata callers want to persist.
  final Map<String, dynamic>? extra;

  /// Optional search query string for search operations.
  final String? searchQuery;

  PaginationRequest<F> copyWith({
    int? page,
    int? pageSize,
    String? cursor,
    F? filters,
    Map<String, dynamic>? extra,
    String? searchQuery,
  }) {
    return PaginationRequest<F>(
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      cursor: cursor ?? this.cursor,
      filters: filters ?? this.filters,
      extra: extra ?? this.extra,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}
