import 'package:flutter/material.dart';
import 'smart_pagination/basic_listview_screen.dart';
import 'smart_pagination/gridview_screen.dart';
import 'smart_pagination/column_example_screen.dart';
import 'smart_pagination/row_example_screen.dart';
import 'smart_pagination/retry_demo_screen.dart';
import 'smart_pagination/filter_search_screen.dart';
import 'smart_pagination/single_stream_screen.dart';
import 'smart_pagination/multi_stream_screen.dart';
import 'smart_pagination/merged_streams_screen.dart';
import 'smart_pagination/cursor_pagination_screen.dart';
import 'smart_pagination/horizontal_list_screen.dart';
import 'smart_pagination/page_view_screen.dart';
import 'smart_pagination/pull_to_refresh_screen.dart';
import 'smart_pagination/staggered_grid_screen.dart';
import 'smart_pagination/custom_states_screen.dart';
import 'smart_pagination/before_build_hook_screen.dart';
import 'smart_pagination/scroll_control_screen.dart';
import 'smart_pagination/has_reached_end_screen.dart';
import 'smart_pagination/custom_view_builder_screen.dart';
import 'smart_pagination/reorderable_list_screen.dart';
import 'smart_pagination/state_separation_screen.dart';
import 'smart_pagination/smart_preloading_screen.dart';
import 'smart_pagination/custom_error_handling_screen.dart';
import 'smart_pagination/data_operations_screen.dart';
import 'smart_pagination/data_age_screen.dart';
import 'smart_pagination/sorting_screen.dart';
import 'smart_pagination/search_dropdown_screen.dart';

// Error handling examples
import 'errors/basic_error_example.dart';
import 'errors/network_errors_example.dart';
import 'errors/retry_patterns_example.dart';
import 'errors/custom_error_widgets_example.dart';
import 'errors/error_recovery_example.dart';
import 'errors/graceful_degradation_example.dart';
import 'errors/load_more_errors_example.dart';

/// Home screen with navigation to all example screens
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Smart Pagination Examples')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeader('Single Pagination Examples'),
          const SizedBox(height: 16),
          _buildExampleCard(
            context,
            title: 'Basic ListView',
            description: 'Simple paginated ListView with products',
            icon: Icons.list,
            color: Colors.blue,
            onTap: () => _navigate(context, const BasicListViewScreen()),
          ),
          const SizedBox(height: 12),
          _buildExampleCard(
            context,
            title: 'GridView',
            description: 'Paginated GridView with product cards',
            icon: Icons.grid_view,
            color: Colors.green,
            onTap: () => _navigate(context, const GridViewScreen()),
          ),
          const SizedBox(height: 12),
          _buildExampleCard(
            context,
            title: 'Column Layout',
            description: 'Non-scrollable column layout inside a scroll view',
            icon: Icons.view_column,
            color: Colors.teal,
            onTap: () => _navigate(context, const ColumnExampleScreen()),
          ),
          const SizedBox(height: 12),
          _buildExampleCard(
            context,
            title: 'Row Layout',
            description: 'Non-scrollable row layout inside a scroll view',
            icon: Icons.table_rows,
            color: Colors.pink,
            onTap: () => _navigate(context, const RowExampleScreen()),
          ),
          const SizedBox(height: 12),
          _buildExampleCard(
            context,
            title: 'Retry Mechanism',
            description: 'Auto-retry on errors with exponential backoff',
            icon: Icons.refresh,
            color: Colors.orange,
            onTap: () => _navigate(context, const RetryDemoScreen()),
          ),
          const SizedBox(height: 12),
          _buildExampleCard(
            context,
            title: 'Filter & Search',
            description: 'Paginated list with filtering and search',
            icon: Icons.search,
            color: Colors.purple,
            onTap: () => _navigate(context, const FilterSearchScreen()),
          ),
          const SizedBox(height: 12),
          _buildExampleCard(
            context,
            title: 'Pull to Refresh',
            description: 'Swipe down to refresh paginated content',
            icon: Icons.refresh,
            color: Colors.amber,
            onTap: () => _navigate(context, const PullToRefreshScreen()),
          ),
          const SizedBox(height: 32),
          _buildHeader('Stream Examples'),
          const SizedBox(height: 16),
          _buildExampleCard(
            context,
            title: 'Single Stream',
            description: 'Real-time updates from a single data stream',
            icon: Icons.stream,
            color: Colors.cyan,
            onTap: () => _navigate(context, const SingleStreamScreen()),
          ),
          const SizedBox(height: 12),
          _buildExampleCard(
            context,
            title: 'Multi Stream',
            description: 'Multiple streams with different update rates',
            icon: Icons.multiline_chart,
            color: Colors.indigo,
            onTap: () => _navigate(context, const MultiStreamScreen()),
          ),
          const SizedBox(height: 12),
          _buildExampleCard(
            context,
            title: 'Merged Streams',
            description: 'Merge multiple streams into one unified stream',
            icon: Icons.merge_type,
            color: Colors.deepPurple,
            onTap: () => _navigate(context, const MergedStreamsScreen()),
          ),
          const SizedBox(height: 32),
          _buildHeader('Advanced Examples'),
          const SizedBox(height: 16),
          _buildExampleCard(
            context,
            title: 'Cursor Pagination',
            description: 'Cursor-based pagination for real-time data',
            icon: Icons.list_alt,
            color: Colors.teal,
            onTap: () => _navigate(context, const CursorPaginationScreen()),
          ),
          const SizedBox(height: 12),
          _buildExampleCard(
            context,
            title: 'Horizontal Scroll',
            description: 'Horizontal scrolling list with pagination',
            icon: Icons.swipe_left,
            color: Colors.deepOrange,
            onTap: () => _navigate(context, const HorizontalListScreen()),
          ),
          const SizedBox(height: 12),
          _buildExampleCard(
            context,
            title: 'PageView',
            description: 'Swipeable pages with automatic pagination',
            icon: Icons.swipe,
            color: Colors.pink,
            onTap: () => _navigate(context, const PageViewScreen()),
          ),
          const SizedBox(height: 12),
          _buildExampleCard(
            context,
            title: 'Staggered Grid',
            description: 'Pinterest-like masonry layout with pagination',
            icon: Icons.view_quilt,
            color: Colors.deepPurple,
            onTap: () => _navigate(context, const StaggeredGridScreen()),
          ),
          const SizedBox(height: 12),
          _buildExampleCard(
            context,
            title: 'Custom States',
            description: 'Custom loading, empty, and error states',
            icon: Icons.palette,
            color: Colors.blueGrey,
            onTap: () => _navigate(context, const CustomStatesScreen()),
          ),
          const SizedBox(height: 12),
          _buildExampleCard(
            context,
            title: 'Scroll Control',
            description: 'Programmatic scrolling to items or indices',
            icon: Icons.keyboard_arrow_down,
            color: Colors.indigo,
            onTap: () => _navigate(context, const ScrollControlScreen()),
          ),
          const SizedBox(height: 12),
          _buildExampleCard(
            context,
            title: 'beforeBuild Hook',
            description: 'Execute logic before rendering the list',
            icon: Icons.build,
            color: Colors.brown,
            onTap: () => _navigate(context, const BeforeBuildHookScreen()),
          ),
          const SizedBox(height: 12),
          _buildExampleCard(
            context,
            title: 'hasReachedEnd',
            description: 'Detect when pagination reaches the end',
            icon: Icons.check_circle,
            color: Colors.orange,
            onTap: () => _navigate(context, const HasReachedEndScreen()),
          ),
          const SizedBox(height: 12),
          _buildExampleCard(
            context,
            title: 'Custom View Builder',
            description: 'Complete control with custom view builder',
            icon: Icons.dashboard_customize,
            color: Colors.teal,
            onTap: () => _navigate(context, const CustomViewBuilderScreen()),
          ),
          const SizedBox(height: 12),
          _buildExampleCard(
            context,
            title: 'Reorderable List',
            description: 'Drag and drop to reorder paginated items',
            icon: Icons.reorder,
            color: Colors.purple,
            onTap: () => _navigate(context, const ReorderableListScreen()),
          ),
          const SizedBox(height: 12),
          _buildExampleCard(
            context,
            title: 'State Separation',
            description: 'Different UI for first page vs load more states',
            icon: Icons.splitscreen,
            color: Colors.indigo,
            onTap: () => _navigate(context, const StateSeparationScreen()),
          ),
          const SizedBox(height: 12),
          _buildExampleCard(
            context,
            title: 'Smart Preloading',
            description: 'Load items before reaching the end',
            icon: Icons.speed,
            color: Colors.deepPurple,
            onTap: () => _navigate(context, const SmartPreloadingScreen()),
          ),
          const SizedBox(height: 12),
          _buildExampleCard(
            context,
            title: 'Custom Error Handling',
            description: 'Multiple error widget styles with retry support',
            icon: Icons.error_outline,
            color: Colors.red,
            onTap: () => _navigate(context, const CustomErrorHandlingScreen()),
          ),
          const SizedBox(height: 12),
          _buildExampleCard(
            context,
            title: 'Data Operations',
            description: 'Programmatic add, remove, update, and clear items',
            icon: Icons.data_array,
            color: Colors.cyan,
            onTap: () => _navigate(context, const DataOperationsScreen()),
          ),
          const SizedBox(height: 12),
          _buildExampleCard(
            context,
            title: 'Data Age & Expiration',
            description: 'Auto-refresh data after expiration period',
            icon: Icons.timer,
            color: Colors.deepOrange,
            onTap: () => _navigate(context, const DataAgeScreen()),
          ),
          const SizedBox(height: 12),
          _buildExampleCard(
            context,
            title: 'Sorting & Orders',
            description: 'Programmatic sorting with configurable orders',
            icon: Icons.sort,
            color: Colors.indigo,
            onTap: () => _navigate(context, const SortingScreen()),
          ),
          const SizedBox(height: 12),
          _buildExampleCard(
            context,
            title: 'Search Dropdown',
            description: 'Search box with auto-positioning overlay dropdown',
            icon: Icons.search,
            color: Colors.deepPurple,
            onTap: () => _navigate(context, const SearchDropdownScreen()),
          ),
          const SizedBox(height: 32),
          _buildHeader('Error Handling Examples'),
          const SizedBox(height: 16),
          _buildExampleCard(
            context,
            title: 'Basic Error Handling',
            description: 'Simple error display with retry functionality',
            icon: Icons.error,
            color: Colors.red,
            onTap: () => _navigate(context, const BasicErrorExample()),
          ),
          const SizedBox(height: 12),
          _buildExampleCard(
            context,
            title: 'Network Errors',
            description: 'Different network error types (timeout, 404, 500, etc.)',
            icon: Icons.wifi_off,
            color: Colors.orange,
            onTap: () => _navigate(context, const NetworkErrorsExample()),
          ),
          const SizedBox(height: 12),
          _buildExampleCard(
            context,
            title: 'Retry Patterns',
            description: 'Manual, auto, exponential backoff, and limited retries',
            icon: Icons.autorenew,
            color: Colors.blue,
            onTap: () => _navigate(context, const RetryPatternsExample()),
          ),
          const SizedBox(height: 12),
          _buildExampleCard(
            context,
            title: 'Custom Error Widgets',
            description: 'All pre-built error widget styles and customization',
            icon: Icons.widgets,
            color: Colors.purple,
            onTap: () => _navigate(context, const CustomErrorWidgetsExample()),
          ),
          const SizedBox(height: 12),
          _buildExampleCard(
            context,
            title: 'Error Recovery',
            description: 'Cached data, partial data, fallback strategies',
            icon: Icons.restore,
            color: Colors.green,
            onTap: () => _navigate(context, const ErrorRecoveryExample()),
          ),
          const SizedBox(height: 12),
          _buildExampleCard(
            context,
            title: 'Graceful Degradation',
            description: 'Offline mode, placeholders, and limited features',
            icon: Icons.layers,
            color: Colors.amber,
            onTap: () => _navigate(context, const GracefulDegradationExample()),
          ),
          const SizedBox(height: 12),
          _buildExampleCard(
            context,
            title: 'Load More Errors',
            description: 'Handle errors while loading additional pages',
            icon: Icons.expand_more,
            color: Colors.indigo,
            onTap: () => _navigate(context, const LoadMoreErrorsExample()),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildExampleCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withValues(alpha:0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  void _navigate(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }
}
