import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../router/app_router.dart';

class _ExampleItem {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final String route;

  const _ExampleItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.route,
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
  const HomeScreen({super.key, this.initialIndex});
  final int? initialIndex;

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
          route: const BasicListViewRoute().location,
        ),
        _ExampleItem(
          title: 'GridView',
          description: 'Paginated GridView with product cards',
          icon: Icons.grid_view_rounded,
          color: Color(0xFF10B981),
          route: const GridViewRoute().location,
        ),
        _ExampleItem(
          title: 'Column Layout',
          description: 'Non-scrollable column inside scroll view',
          icon: Icons.view_agenda_rounded,
          color: Color(0xFF14B8A6),
          route: const ColumnLayoutRoute().location,
        ),
        _ExampleItem(
          title: 'Row Layout',
          description: 'Non-scrollable row inside scroll view',
          icon: Icons.view_week_rounded,
          color: Color(0xFFEC4899),
          route: const RowLayoutRoute().location,
        ),
        _ExampleItem(
          title: 'Pull to Refresh',
          description: 'Swipe down to refresh content',
          icon: Icons.refresh_rounded,
          color: Color(0xFFF59E0B),
          route: const PullToRefreshRoute().location,
        ),
        _ExampleItem(
          title: 'Filter & Search',
          description: 'Paginated list with filtering',
          icon: Icons.filter_list_rounded,
          color: Color(0xFF8B5CF6),
          route: const FilterSearchRoute().location,
        ),
        _ExampleItem(
          title: 'Retry Mechanism',
          description: 'Auto-retry with exponential backoff',
          icon: Icons.replay_rounded,
          color: Color(0xFFF97316),
          route: const RetryMechanismRoute().location,
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
          route: const SingleStreamRoute().location,
        ),
        _ExampleItem(
          title: 'Multi Stream',
          description: 'Multiple streams with different rates',
          icon: Icons.cable_rounded,
          color: Color(0xFF4F46E5),
          route: const MultiStreamRoute().location,
        ),
        _ExampleItem(
          title: 'Merged Streams',
          description: 'Merge streams into one unified stream',
          icon: Icons.merge_rounded,
          color: Color(0xFF7C3AED),
          route: const MergedStreamsRoute().location,
        ),
      ],
    ),
    _ExampleCategory(
      title: 'Advanced',
      subtitle: 'Complex pagination scenarios',
      icon: Icons.auto_awesome_rounded,
      items: [
        _ExampleItem(
          title: 'Chat Example',
          description: 'Scroll navigation with chat UI',
          icon: Icons.chat_bubble_rounded,
          color: Color(0xFF06B6D4),
          route: const ChatRoute().location,
        ),
        _ExampleItem(
          title: 'Cursor Pagination',
          description: 'Cursor-based pagination for real-time',
          icon: Icons.navigate_next_rounded,
          color: Color(0xFF0D9488),
          route: const CursorPaginationRoute().location,
        ),
        _ExampleItem(
          title: 'Horizontal Scroll',
          description: 'Horizontal scrolling with pagination',
          icon: Icons.swap_horiz_rounded,
          color: Color(0xFFEA580C),
          route: const HorizontalScrollRoute().location,
        ),
        _ExampleItem(
          title: 'PageView',
          description: 'Swipeable pages with auto pagination',
          icon: Icons.auto_stories_rounded,
          color: Color(0xFFDB2777),
          route: const PageViewRoute().location,
        ),
        _ExampleItem(
          title: 'Staggered Grid',
          description: 'Pinterest-like masonry layout',
          icon: Icons.dashboard_rounded,
          color: Color(0xFF7C3AED),
          route: const StaggeredGridRoute().location,
        ),
        _ExampleItem(
          title: 'Custom States',
          description: 'Custom loading, empty, error states',
          icon: Icons.palette_rounded,
          color: Color(0xFF64748B),
          route: const CustomStatesRoute().location,
        ),
        _ExampleItem(
          title: 'Scroll Control',
          description: 'Programmatic scrolling to items',
          icon: Icons.open_in_full_rounded,
          color: Color(0xFF4F46E5),
          route: const ScrollControlRoute().location,
        ),
        _ExampleItem(
          title: 'beforeBuild Hook',
          description: 'Execute logic before rendering',
          icon: Icons.code_rounded,
          color: Color(0xFF78350F),
          route: const BeforeBuildHookRoute().location,
        ),
        _ExampleItem(
          title: 'hasReachedEnd',
          description: 'Detect when pagination ends',
          icon: Icons.check_circle_rounded,
          color: Color(0xFFF97316),
          route: const HasReachedEndRoute().location,
        ),
        _ExampleItem(
          title: 'Custom View Builder',
          description: 'Complete control with custom builder',
          icon: Icons.construction_rounded,
          color: Color(0xFF14B8A6),
          route: const CustomViewBuilderRoute().location,
        ),
        _ExampleItem(
          title: 'Reorderable List',
          description: 'Drag and drop to reorder items',
          icon: Icons.drag_indicator_rounded,
          color: Color(0xFF8B5CF6),
          route: const ReorderableListRoute().location,
        ),
        _ExampleItem(
          title: 'State Separation',
          description: 'Different UI for page states',
          icon: Icons.call_split_rounded,
          color: Color(0xFF4F46E5),
          route: const StateSeparationRoute().location,
        ),
        _ExampleItem(
          title: 'Smart Preloading',
          description: 'Load items before reaching end',
          icon: Icons.speed_rounded,
          color: Color(0xFF7C3AED),
          route: const SmartPreloadingRoute().location,
        ),
        _ExampleItem(
          title: 'Data Operations',
          description: 'Add, remove, update, clear items',
          icon: Icons.data_object_rounded,
          color: Color(0xFF06B6D4),
          route: const DataOperationsRoute().location,
        ),
        _ExampleItem(
          title: 'Data Age & Expiration',
          description: 'Auto-refresh after expiration',
          icon: Icons.timer_rounded,
          color: Color(0xFFEA580C),
          route: const DataAgeRoute().location,
        ),
        _ExampleItem(
          title: 'Sorting & Orders',
          description: 'Programmatic sorting with orders',
          icon: Icons.sort_rounded,
          color: Color(0xFF4F46E5),
          route: const SortingRoute().location,
        ),
      ],
    ),
    _ExampleCategory(
      title: 'Search',
      subtitle: 'Smart search components',
      icon: Icons.search_rounded,
      items: [
        _ExampleItem(
          title: 'Search Dropdown',
          description: 'Search with auto-positioning overlay',
          icon: Icons.search_rounded,
          color: Color(0xFF7C3AED),
          route: const SearchDropdownRoute().location,
        ),
        _ExampleItem(
          title: 'Multi-Select Search',
          description: 'Search and select multiple items',
          icon: Icons.checklist_rounded,
          color: Color(0xFFDC2626),
          route: const MultiSelectSearchRoute().location,
        ),
        _ExampleItem(
          title: 'Form Validation',
          description: 'Search with validators & formatters',
          icon: Icons.fact_check_rounded,
          color: Color(0xFF059669),
          route: const FormValidationRoute().location,
        ),
        _ExampleItem(
          title: 'Keyboard Navigation',
          description: 'Arrow keys, Enter, Escape shortcuts',
          icon: Icons.keyboard_rounded,
          color: Color(0xFF2563EB),
          route: const KeyboardNavigationRoute().location,
        ),
        _ExampleItem(
          title: 'Search Theming',
          description: 'Light, dark & custom themes',
          icon: Icons.palette_rounded,
          color: Color(0xFFEC4899),
          route: const SearchThemingRoute().location,
        ),
        _ExampleItem(
          title: 'Async States',
          description: 'Loading, empty & error states',
          icon: Icons.hourglass_empty_rounded,
          color: Color(0xFFF59E0B),
          route: const AsyncStatesRoute().location,
        ),
        _ExampleItem(
          title: 'Overlay Animations',
          description: '13 animation types & overlay values',
          icon: Icons.animation_rounded,
          color: Color(0xFF8B5CF6),
          route: const OverlayAnimationsRoute().location,
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
          route: const BasicErrorRoute().location,
        ),
        _ExampleItem(
          title: 'Network Errors',
          description: 'Timeout, 404, 500 error types',
          icon: Icons.wifi_off_rounded,
          color: Color(0xFFF97316),
          route: const NetworkErrorsRoute().location,
        ),
        _ExampleItem(
          title: 'Retry Patterns',
          description: 'Auto, exponential, limited retries',
          icon: Icons.autorenew_rounded,
          color: Color(0xFF3B82F6),
          route: const RetryPatternsRoute().location,
        ),
        _ExampleItem(
          title: 'Custom Error Widgets',
          description: 'Pre-built error widget styles',
          icon: Icons.widgets_rounded,
          color: Color(0xFF8B5CF6),
          route: const CustomErrorWidgetsRoute().location,
        ),
        _ExampleItem(
          title: 'Error Recovery',
          description: 'Cached data, fallback strategies',
          icon: Icons.healing_rounded,
          color: Color(0xFF10B981),
          route: const ErrorRecoveryRoute().location,
        ),
        _ExampleItem(
          title: 'Graceful Degradation',
          description: 'Offline mode, placeholders',
          icon: Icons.layers_clear_rounded,
          color: Color(0xFFF59E0B),
          route: const GracefulDegradationRoute().location,
        ),
        _ExampleItem(
          title: 'Load More Errors',
          description: 'Handle errors loading more pages',
          icon: Icons.expand_more_rounded,
          color: Color(0xFF4F46E5),
          route: const LoadMoreErrorsRoute().location,
        ),
      ],
    ),
    _ExampleCategory(
      title: 'Firebase',
      subtitle: 'Firebase integration examples',
      icon: Icons.cloud_rounded,
      items: [
        _ExampleItem(
          title: 'Firestore Pagination',
          description: 'Cursor-based Firestore queries',
          icon: Icons.storage_rounded,
          color: Color(0xFFFF9800),
          route: const FirestorePaginationRoute().location,
        ),
        _ExampleItem(
          title: 'Firestore Real-time',
          description: 'Live data with snapshots',
          icon: Icons.sync_rounded,
          color: Color(0xFF4CAF50),
          route: const FirestoreRealtimeRoute().location,
        ),
        _ExampleItem(
          title: 'Firestore Search',
          description: 'Search with array-contains',
          icon: Icons.manage_search_rounded,
          color: Color(0xFF2196F3),
          route: const FirestoreSearchRoute().location,
        ),
        _ExampleItem(
          title: 'Realtime Database',
          description: 'Firebase RTDB pagination',
          icon: Icons.data_object_rounded,
          color: Color(0xFFFFCA28),
          route: const RealtimeDatabaseRoute().location,
        ),
        _ExampleItem(
          title: 'Firestore Filters',
          description: 'Advanced composite queries',
          icon: Icons.filter_alt_rounded,
          color: Color(0xFF9C27B0),
          route: const FirestoreFiltersRoute().location,
        ),
        _ExampleItem(
          title: 'Offline Support',
          description: 'Cache & offline persistence',
          icon: Icons.cloud_off_rounded,
          color: Color(0xFF607D8B),
          route: const OfflineSupportRoute().location,
        ),
        _ExampleItem(
          title: 'Seed Data Manager',
          description: 'Populate Firebase with demo data',
          icon: Icons.dataset_rounded,
          color: Color(0xFF00BCD4),
          route: const SeedDataRoute().location,
        ),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _categories.length,
      vsync: this,
      initialIndex: widget.initialIndex ?? 0,
    );
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
                                      color: Colors.white.withValues(
                                        alpha: 0.8,
                                      ),
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
                  onTap: (value) {
                    Future.delayed(Duration(milliseconds: 400), () {
                      // Categories order: 0-Basic, 1-Streams, 2-Advanced, 3-Search, 4-Errors, 5-Firebase
                      switch (value) {
                        case 0:
                          const BasicRoute().go(context);
                          break;
                        case 1:
                          const StreamRoute().go(context);
                          break;
                        case 2:
                          const AdvancedRoute().go(context);
                          break;
                        case 3:
                          const SearchRoute().go(context);
                          break;
                        case 4:
                          const ErrorRoute().go(context);
                          break;
                        case 5:
                          const FirebaseRoute().go(context);
                          break;
                      }
                    });
                  },
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
          Icon(Icons.search_off_rounded, size: 64, color: Colors.grey[300]),
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
            style: TextStyle(fontSize: 14, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryContent(
    _ExampleCategory category,
    List<_ExampleItem> items,
  ) {
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
                      style: TextStyle(fontSize: 13, color: Colors.grey[500]),
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
          onTap: () => context.go(item.route),
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
                      colors: [item.color, item.color.withValues(alpha: 0.7)],
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
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final bool isDark;

  _TabBarDelegate({required this.tabBar, required this.isDark});

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
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
