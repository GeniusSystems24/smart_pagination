import 'package:flutter/material.dart';
import 'smart_pagination/basic_listview_screen.dart';
import 'smart_pagination/gridview_screen.dart';
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

/// Home screen with navigation to all example screens
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Custom Pagination Examples')),
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
            icon: Icons.swipe_horizontal,
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
                  color: color.withOpacity(0.1),
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
