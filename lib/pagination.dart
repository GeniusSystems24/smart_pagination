/// Smart Pagination Library
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

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:scrollview_observer/scrollview_observer.dart';

export 'package:scrollview_observer/scrollview_observer.dart';
export 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

part 'core/widget/bottom_loader.dart';
part 'core/widget/empty_display.dart';
part 'core/widget/empty_separator.dart';
part 'core/widget/error_display.dart';
part 'core/widget/custom_error_builder.dart';
part 'core/widget/initial_loader.dart';
part 'smart_pagination/controller/scroll_to_message_mixin.dart';
part 'core/error_handling.dart';

part 'smart_pagination/widgets/paginate_api_view.dart';
part 'smart_pagination/bloc/pagination_cubit.dart';
part 'smart_pagination/bloc/pagination_listeners.dart';
part 'smart_pagination/bloc/pagination_state.dart';
part 'smart_pagination/controller/controller.dart';

// Core interfaces for pagination system
part 'core/core.dart';
part 'core/bloc/pagination_cubit.dart';
part 'core/bloc/pagination_listeners.dart';
part 'core/bloc/pagination_state.dart';
part 'core/controller/controller.dart';

// data
part 'data/models/pagination_meta.dart';
part 'data/models/pagination_request.dart';
part 'data/models/sort_order.dart';

part 'smart_pagination/pagination.dart';

// Specialized widget classes
part 'smart_pagination/widgets/smart_pagination_list_view.dart';
part 'smart_pagination/widgets/smart_pagination_grid_view.dart';
part 'smart_pagination/widgets/smart_pagination_column.dart';
part 'smart_pagination/widgets/smart_pagination_row.dart';
part 'smart_pagination/widgets/smart_pagination_page_view.dart';
part 'smart_pagination/widgets/smart_pagination_staggered_grid_view.dart';
part 'smart_pagination/widgets/smart_pagination_reorderable_list_view.dart';

// Smart Search components
part 'smart_search/models/search_config.dart';
part 'smart_search/theme/smart_search_theme.dart';
part 'smart_search/controller/smart_search_controller.dart';
part 'smart_search/utils/overlay_positioner.dart';
part 'smart_search/widgets/smart_search_box.dart';
part 'smart_search/widgets/smart_search_overlay.dart';
part 'smart_search/widgets/smart_search_dropdown.dart';
