/// Custom Pagination Library
///
/// A comprehensive Flutter pagination library that provides flexible and powerful
/// pagination solutions for REST APIs with support for multiple view types.
///
/// ## Features
///
/// - **Multiple Layout Support**: ListView, GridView, PageView, StaggeredGridView, Column, Row
/// - **BLoC Pattern**: Clean state management using flutter_bloc
/// - **Cursor & Offset Pagination**: Support for both pagination strategies
/// - **Stream Support**: Real-time updates via stream providers
/// - **Memory Management**: Configurable page caching
/// - **Filtering & Refresh**: Built-in filter and refresh listeners
/// - **Scroll Control**: Programmatic scrolling to items or indices
///
/// ## Basic Usage
///
/// ```dart
/// // 1. Define your data provider
/// Future<List<MyModel>> fetchData(PaginationRequest request) async {
///   final response = await http.get('api/items?page=${request.page}');
///   return (json.decode(response.body) as List)
///       .map((e) => MyModel.fromJson(e))
///       .toList();
/// }
///
/// // 2. Create a SmartPagination widget
/// SmartPagination<MyModel>(
///   request: PaginationRequest(page: 1, pageSize: 20),
///   dataProvider: fetchData,
///   itemBuilder: (context, items, index) {
///     return ListTile(title: Text(items[index].name));
///   },
/// )
/// ```
///
/// For advanced usage and examples, see the documentation.
library;

// Core exports
export 'core/core.dart';

// Data models
export 'data/data.dart';

// Smart pagination
export 'smart_pagination/pagination.dart';

// Smart pagination convenience widgets
export 'smart_pagination/widgets/smart_paginated_list_view.dart';
export 'smart_pagination/widgets/smart_paginated_grid_view.dart';

