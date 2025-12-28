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
import 'smart_pagination/form_validation_search_screen.dart';
import 'smart_pagination/multi_select_search_screen.dart';

// Error handling examples
import 'errors/basic_error_example.dart';
import 'errors/network_errors_example.dart';
import 'errors/retry_patterns_example.dart';
import 'errors/custom_error_widgets_example.dart';
import 'errors/error_recovery_example.dart';
import 'errors/graceful_degradation_example.dart';
import 'errors/load_more_errors_example.dart';

class _ExampleItem {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final Widget screen;

  const _ExampleItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.screen,
  });
}

class _ExampleCategory {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<_ExampleItem> items;

  const _ExampleCategory({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.items,
  });
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<_ExampleCategory> _categories = [
    _ExampleCategory(
      title: 'Basic',
      subtitle: 'Core pagination patterns',
      icon: Icons.layers_outlined,
      items: [
        _ExampleItem(
          title: 'Basic ListView',
          description: 'Simple paginated ListView with products',
          icon: Icons.list_alt_rounded,
          color: Color(0xFF6366F1),
          screen: BasicListViewScreen(),
        ),
        _ExampleItem(
          title: 'GridView',
          description: 'Paginated GridView with product cards',
          icon: Icons.grid_view_rounded,
          color: Color(0xFF10B981),
          screen: GridViewScreen(),
        ),
        _ExampleItem(
          title: 'Column Layout',
          description: 'Non-scrollable column inside scroll view',
          icon: Icons.view_agenda_rounded,
          color: Color(0xFF14B8A6),
          screen: ColumnExampleScreen(),
        ),
        _ExampleItem(
          title: 'Row Layout',
          description: 'Non-scrollable row inside scroll view',
          icon: Icons.view_week_rounded,
          color: Color(0xFFEC4899),
          screen: RowExampleScreen(),
        ),
        _ExampleItem(
          title: 'Pull to Refresh',
          description: 'Swipe down to refresh content',
          icon: Icons.refresh_rounded,
          color: Color(0xFFF59E0B),
          screen: PullToRefreshScreen(),
        ),
        _ExampleItem(
          title: 'Filter & Search',
          description: 'Paginated list with filtering',
          icon: Icons.filter_list_rounded,
          color: Color(0xFF8B5CF6),
          screen: FilterSearchScreen(),
        ),
        _ExampleItem(
          title: 'Retry Mechanism',
          description: 'Auto-retry with exponential backoff',
          icon: Icons.replay_rounded,
          color: Color(0xFFF97316),
          screen: RetryDemoScreen(),
        ),
      ],
    ),
    _ExampleCategory(
      title: 'Streams',
      subtitle: 'Real-time data updates',
      icon: Icons.stream_rounded,
      items: [
        _ExampleItem(
          title: 'Single Stream',
          description: 'Real-time updates from single stream',
          icon: Icons.bolt_rounded,
          color: Color(0xFF06B6D4),
          screen: SingleStreamScreen(),
        ),
        _ExampleItem(
          title: 'Multi Stream',
          description: 'Multiple streams with different rates',
          icon: Icons.cable_rounded,
          color: Color(0xFF4F46E5),
          screen: MultiStreamScreen(),
        ),
        _ExampleItem(
          title: 'Merged Streams',
          description: 'Merge streams into one unified stream',
          icon: Icons.merge_rounded,
          color: Color(0xFF7C3AED),
          screen: MergedStreamsScreen(),
        ),
      ],
    ),
    _ExampleCategory(
      title: 'Advanced',
      subtitle: 'Complex pagination scenarios',
      icon: Icons.auto_awesome_rounded,
      items: [
        _ExampleItem(
          title: 'Cursor Pagination',
          description: 'Cursor-based pagination for real-time',
          icon: Icons.navigate_next_rounded,
          color: Color(0xFF0D9488),
          screen: CursorPaginationScreen(),
        ),
        _ExampleItem(
          title: 'Horizontal Scroll',
          description: 'Horizontal scrolling with pagination',
          icon: Icons.swap_horiz_rounded,
          color: Color(0xFFEA580C),
          screen: HorizontalListScreen(),
        ),
        _ExampleItem(
          title: 'PageView',
          description: 'Swipeable pages with auto pagination',
          icon: Icons.auto_stories_rounded,
          color: Color(0xFFDB2777),
          screen: PageViewScreen(),
        ),
        _ExampleItem(
          title: 'Staggered Grid',
          description: 'Pinterest-like masonry layout',
          icon: Icons.dashboard_rounded,
          color: Color(0xFF7C3AED),
          screen: StaggeredGridScreen(),
        ),
        _ExampleItem(
          title: 'Custom States',
          description: 'Custom loading, empty, error states',
          icon: Icons.palette_rounded,
          color: Color(0xFF64748B),
          screen: CustomStatesScreen(),
        ),
        _ExampleItem(
          title: 'Scroll Control',
          description: 'Programmatic scrolling to items',
          icon: Icons.open_in_full_rounded,
          color: Color(0xFF4F46E5),
          screen: ScrollControlScreen(),
        ),
        _ExampleItem(
          title: 'beforeBuild Hook',
          description: 'Execute logic before rendering',
          icon: Icons.code_rounded,
          color: Color(0xFF78350F),
          screen: BeforeBuildHookScreen(),
        ),
        _ExampleItem(
          title: 'hasReachedEnd',
          description: 'Detect when pagination ends',
          icon: Icons.check_circle_rounded,
          color: Color(0xFFF97316),
          screen: HasReachedEndScreen(),
        ),
        _ExampleItem(
          title: 'Custom View Builder',
          description: 'Complete control with custom builder',
          icon: Icons.construction_rounded,
          color: Color(0xFF14B8A6),
          screen: CustomViewBuilderScreen(),
        ),
        _ExampleItem(
          title: 'Reorderable List',
          description: 'Drag and drop to reorder items',
          icon: Icons.drag_indicator_rounded,
          color: Color(0xFF8B5CF6),
          screen: ReorderableListScreen(),
        ),
        _ExampleItem(
          title: 'State Separation',
          description: 'Different UI for page states',
          icon: Icons.call_split_rounded,
          color: Color(0xFF4F46E5),
          screen: StateSeparationScreen(),
        ),
        _ExampleItem(
          title: 'Smart Preloading',
          description: 'Load items before reaching end',
          icon: Icons.speed_rounded,
          color: Color(0xFF7C3AED),
          screen: SmartPreloadingScreen(),
        ),
        _ExampleItem(
          title: 'Data Operations',
          description: 'Add, remove, update, clear items',
          icon: Icons.data_object_rounded,
          color: Color(0xFF06B6D4),
          screen: DataOperationsScreen(),
        ),
        _ExampleItem(
          title: 'Data Age & Expiration',
          description: 'Auto-refresh after expiration',
          icon: Icons.timer_rounded,
          color: Color(0xFFEA580C),
          screen: DataAgeScreen(),
        ),
        _ExampleItem(
          title: 'Sorting & Orders',
          description: 'Programmatic sorting with orders',
          icon: Icons.sort_rounded,
          color: Color(0xFF4F46E5),
          screen: SortingScreen(),
        ),
        _ExampleItem(
          title: 'Search Dropdown',
          description: 'Search with auto-positioning overlay',
          icon: Icons.search_rounded,
          color: Color(0xFF7C3AED),
          screen: SearchDropdownScreen(),
        ),
        _ExampleItem(
          title: 'Form Validation Search',
          description: 'Search with form validation & formatters',
          icon: Icons.fact_check_rounded,
          color: Color(0xFF059669),
          screen: FormValidationSearchScreen(),
        ),
        _ExampleItem(
          title: 'Multi-Select Search',
          description: 'Search and select multiple items',
          icon: Icons.checklist_rounded,
          color: Color(0xFFDC2626),
          screen: MultiSelectSearchScreen(),
        ),
      ],
    ),
    _ExampleCategory(
      title: 'Errors',
      subtitle: 'Error handling patterns',
      icon: Icons.bug_report_rounded,
      items: [
        _ExampleItem(
          title: 'Basic Error Handling',
          description: 'Simple error display with retry',
          icon: Icons.error_outline_rounded,
          color: Color(0xFFEF4444),
          screen: BasicErrorExample(),
        ),
        _ExampleItem(
          title: 'Network Errors',
          description: 'Timeout, 404, 500 error types',
          icon: Icons.wifi_off_rounded,
          color: Color(0xFFF97316),
          screen: NetworkErrorsExample(),
        ),
        _ExampleItem(
          title: 'Retry Patterns',
          description: 'Auto, exponential, limited retries',
          icon: Icons.autorenew_rounded,
          color: Color(0xFF3B82F6),
          screen: RetryPatternsExample(),
        ),
        _ExampleItem(
          title: 'Custom Error Widgets',
          description: 'Pre-built error widget styles',
          icon: Icons.widgets_rounded,
          color: Color(0xFF8B5CF6),
          screen: CustomErrorWidgetsExample(),
        ),
        _ExampleItem(
          title: 'Error Recovery',
          description: 'Cached data, fallback strategies',
          icon: Icons.healing_rounded,
          color: Color(0xFF10B981),
          screen: ErrorRecoveryExample(),
        ),
        _ExampleItem(
          title: 'Graceful Degradation',
          description: 'Offline mode, placeholders',
          icon: Icons.layers_clear_rounded,
          color: Color(0xFFF59E0B),
          screen: GracefulDegradationExample(),
        ),
        _ExampleItem(
          title: 'Load More Errors',
          description: 'Handle errors loading more pages',
          icon: Icons.expand_more_rounded,
          color: Color(0xFF4F46E5),
          screen: LoadMoreErrorsExample(),
        ),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<_ExampleItem> _getFilteredItems(_ExampleCategory category) {
    if (_searchQuery.isEmpty) return category.items;
    return category.items.where((item) {
      return item.title.toLowerCase().contains(_searchQuery) ||
          item.description.toLowerCase().contains(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
    );

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 180,
              floating: false,
              pinned: true,
              elevation: 0,
              backgroundColor: Color(0xFF6366F1),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(gradient: primaryGradient),
                  child: SafeArea(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(20, 16, 20, 80),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.auto_awesome_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Smart Pagination',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Examples & Demos',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.8),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              bottom: PreferredSize(
                preferredSize: Size.fromHeight(60),
                child: Container(
                  height: 60,
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                  decoration: BoxDecoration(gradient: primaryGradient),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search examples...',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: Colors.grey[400],
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  Icons.close_rounded,
                                  color: Colors.grey[400],
                                ),
                                onPressed: () => _searchController.clear(),
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _TabBarDelegate(
                tabBar: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  labelColor: Color(0xFF6366F1),
                  unselectedLabelColor: Colors.grey[600],
                  indicatorColor: Color(0xFF6366F1),
                  indicatorWeight: 3,
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  tabs: _categories.map((category) {
                    return Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(category.icon, size: 18),
                          SizedBox(width: 8),
                          Text(category.title),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                isDark: isDark,
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: _categories.map((category) {
            final items = _getFilteredItems(category);
            if (items.isEmpty) {
              return _buildEmptyState();
            }
            return _buildCategoryContent(category, items);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 64,
            color: Colors.grey[300],
          ),
          SizedBox(height: 16),
          Text(
            'No examples found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Try a different search term',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryContent(
      _ExampleCategory category, List<_ExampleItem> items) {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: items.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(0xFF6366F1).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    category.icon,
                    color: Color(0xFF6366F1),
                    size: 20,
                  ),
                ),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    Text(
                      category.subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
                Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${items.length} examples',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        return _buildExampleCard(context, items[index - 1]);
      },
    );
  }

  Widget _buildExampleCard(BuildContext context, _ExampleItem item) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _navigate(context, item.screen),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        item.color,
                        item.color.withValues(alpha: 0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: item.color.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(item.icon, color: Colors.white, size: 24),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        item.description,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[500],
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigate(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;
          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: Duration(milliseconds: 300),
      ),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final bool isDark;

  _TabBarDelegate({required this.tabBar, required this.isDark});

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: isDark ? Colors.grey[900] : Colors.white,
      child: tabBar,
    );
  }

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar || isDark != oldDelegate.isDark;
  }
}
