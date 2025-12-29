import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/home_screen.dart';

// Basic examples
import '../screens/smart_pagination/basic_listview_screen.dart';
import '../screens/smart_pagination/gridview_screen.dart';
import '../screens/smart_pagination/column_example_screen.dart';
import '../screens/smart_pagination/row_example_screen.dart';
import '../screens/smart_pagination/pull_to_refresh_screen.dart';
import '../screens/smart_pagination/filter_search_screen.dart';
import '../screens/smart_pagination/retry_demo_screen.dart';

// Streams examples
import '../screens/smart_pagination/single_stream_screen.dart';
import '../screens/smart_pagination/multi_stream_screen.dart';
import '../screens/smart_pagination/merged_streams_screen.dart';

// Advanced examples
import '../screens/smart_pagination/cursor_pagination_screen.dart';
import '../screens/smart_pagination/horizontal_list_screen.dart';
import '../screens/smart_pagination/page_view_screen.dart';
import '../screens/smart_pagination/staggered_grid_screen.dart';
import '../screens/smart_pagination/custom_states_screen.dart';
import '../screens/smart_pagination/scroll_control_screen.dart';
import '../screens/smart_pagination/before_build_hook_screen.dart';
import '../screens/smart_pagination/has_reached_end_screen.dart';
import '../screens/smart_pagination/custom_view_builder_screen.dart';
import '../screens/smart_pagination/reorderable_list_screen.dart';
import '../screens/smart_pagination/state_separation_screen.dart';
import '../screens/smart_pagination/smart_preloading_screen.dart';
import '../screens/smart_pagination/data_operations_screen.dart';
import '../screens/smart_pagination/data_age_screen.dart';
import '../screens/smart_pagination/sorting_screen.dart';

// Search examples
import '../screens/smart_pagination/search_dropdown_screen.dart';
import '../screens/smart_pagination/multi_select_search_screen.dart';
import '../screens/smart_pagination/form_validation_search_screen.dart';
import '../screens/smart_pagination/keyboard_navigation_search_screen.dart';
import '../screens/smart_pagination/search_theming_screen.dart';
import '../screens/smart_pagination/async_search_states_screen.dart';

// Error examples
import '../screens/errors/basic_error_example.dart';
import '../screens/errors/network_errors_example.dart';
import '../screens/errors/retry_patterns_example.dart';
import '../screens/errors/custom_error_widgets_example.dart';
import '../screens/errors/error_recovery_example.dart';
import '../screens/errors/graceful_degradation_example.dart';
import '../screens/errors/load_more_errors_example.dart';

// Firebase examples
import '../screens/firebase/firestore_pagination_screen.dart';
import '../screens/firebase/firestore_realtime_screen.dart';
import '../screens/firebase/firestore_search_screen.dart';
import '../screens/firebase/realtime_database_screen.dart';
import '../screens/firebase/firestore_filters_screen.dart';
import '../screens/firebase/offline_support_screen.dart';

/// Route paths for the example app
class AppRoutes {
  // Home
  static const String home = '/';

  // Basic
  static const String basicListView = '/basic/list-view';
  static const String gridView = '/basic/grid-view';
  static const String columnLayout = '/basic/column';
  static const String rowLayout = '/basic/row';
  static const String pullToRefresh = '/basic/pull-to-refresh';
  static const String filterSearch = '/basic/filter-search';
  static const String retryMechanism = '/basic/retry';

  // Streams
  static const String singleStream = '/streams/single';
  static const String multiStream = '/streams/multi';
  static const String mergedStreams = '/streams/merged';

  // Advanced
  static const String cursorPagination = '/advanced/cursor';
  static const String horizontalScroll = '/advanced/horizontal';
  static const String pageView = '/advanced/page-view';
  static const String staggeredGrid = '/advanced/staggered-grid';
  static const String customStates = '/advanced/custom-states';
  static const String scrollControl = '/advanced/scroll-control';
  static const String beforeBuildHook = '/advanced/before-build';
  static const String hasReachedEnd = '/advanced/reached-end';
  static const String customViewBuilder = '/advanced/custom-builder';
  static const String reorderableList = '/advanced/reorderable';
  static const String stateSeparation = '/advanced/state-separation';
  static const String smartPreloading = '/advanced/preloading';
  static const String dataOperations = '/advanced/data-operations';
  static const String dataAge = '/advanced/data-age';
  static const String sorting = '/advanced/sorting';

  // Search
  static const String searchDropdown = '/search/dropdown';
  static const String multiSelectSearch = '/search/multi-select';
  static const String formValidation = '/search/form-validation';
  static const String keyboardNavigation = '/search/keyboard';
  static const String searchTheming = '/search/theming';
  static const String asyncStates = '/search/async-states';

  // Errors
  static const String basicError = '/errors/basic';
  static const String networkErrors = '/errors/network';
  static const String retryPatterns = '/errors/retry-patterns';
  static const String customErrorWidgets = '/errors/custom-widgets';
  static const String errorRecovery = '/errors/recovery';
  static const String gracefulDegradation = '/errors/graceful';
  static const String loadMoreErrors = '/errors/load-more';

  // Firebase
  static const String firestorePagination = '/firebase/firestore-pagination';
  static const String firestoreRealtime = '/firebase/firestore-realtime';
  static const String firestoreSearch = '/firebase/firestore-search';
  static const String realtimeDatabase = '/firebase/realtime-database';
  static const String firestoreFilters = '/firebase/firestore-filters';
  static const String offlineSupport = '/firebase/offline-support';
}

/// Custom page transition for smooth navigation
CustomTransitionPage<void> _buildPageWithTransition({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(1.0, 0.0);
      const end = Offset.zero;
      const curve = Curves.easeInOutCubic;
      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
      return SlideTransition(
        position: animation.drive(tween),
        child: child,
      );
    },
    transitionDuration: const Duration(milliseconds: 300),
  );
}

/// App router configuration using go_router
final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.home,
  routes: [
    // Home
    GoRoute(
      path: AppRoutes.home,
      builder: (context, state) => const HomeScreen(),
    ),

    // Basic examples
    GoRoute(
      path: AppRoutes.basicListView,
      pageBuilder: (context, state) => _buildPageWithTransition(
        context: context,
        state: state,
        child: const BasicListViewScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.gridView,
      pageBuilder: (context, state) => _buildPageWithTransition(
        context: context,
        state: state,
        child: const GridViewScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.columnLayout,
      pageBuilder: (context, state) => _buildPageWithTransition(
        context: context,
        state: state,
        child: const ColumnExampleScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.rowLayout,
      pageBuilder: (context, state) => _buildPageWithTransition(
        context: context,
        state: state,
        child: const RowExampleScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.pullToRefresh,
      pageBuilder: (context, state) => _buildPageWithTransition(
        context: context,
        state: state,
        child: const PullToRefreshScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.filterSearch,
      pageBuilder: (context, state) => _buildPageWithTransition(
        context: context,
        state: state,
        child: const FilterSearchScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.retryMechanism,
      pageBuilder: (context, state) => _buildPageWithTransition(
        context: context,
        state: state,
        child: const RetryDemoScreen(),
      ),
    ),

    // Streams examples
    GoRoute(
      path: AppRoutes.singleStream,
      pageBuilder: (context, state) => _buildPageWithTransition(
        context: context,
        state: state,
        child: const SingleStreamScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.multiStream,
      pageBuilder: (context, state) => _buildPageWithTransition(
        context: context,
        state: state,
        child: const MultiStreamScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.mergedStreams,
      pageBuilder: (context, state) => _buildPageWithTransition(
        context: context,
        state: state,
        child: const MergedStreamsScreen(),
      ),
    ),

    // Advanced examples
    GoRoute(
      path: AppRoutes.cursorPagination,
      pageBuilder: (context, state) => _buildPageWithTransition(
        context: context,
        state: state,
        child: const CursorPaginationScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.horizontalScroll,
      pageBuilder: (context, state) => _buildPageWithTransition(
        context: context,
        state: state,
        child: const HorizontalListScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.pageView,
      pageBuilder: (context, state) => _buildPageWithTransition(
        context: context,
        state: state,
        child: const PageViewScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.staggeredGrid,
      pageBuilder: (context, state) => _buildPageWithTransition(
        context: context,
        state: state,
        child: const StaggeredGridScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.customStates,
      pageBuilder: (context, state) => _buildPageWithTransition(
        context: context,
        state: state,
        child: const CustomStatesScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.scrollControl,
      pageBuilder: (context, state) => _buildPageWithTransition(
        context: context,
        state: state,
        child: const ScrollControlScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.beforeBuildHook,
      pageBuilder: (context, state) => _buildPageWithTransition(
        context: context,
        state: state,
        child: const BeforeBuildHookScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.hasReachedEnd,
      pageBuilder: (context, state) => _buildPageWithTransition(
        context: context,
        state: state,
        child: const HasReachedEndScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.customViewBuilder,
      pageBuilder: (context, state) => _buildPageWithTransition(
        context: context,
        state: state,
        child: const CustomViewBuilderScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.reorderableList,
      pageBuilder: (context, state) => _buildPageWithTransition(
        context: context,
        state: state,
        child: const ReorderableListScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.stateSeparation,
      pageBuilder: (context, state) => _buildPageWithTransition(
        context: context,
        state: state,
        child: const StateSeparationScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.smartPreloading,
      pageBuilder: (context, state) => _buildPageWithTransition(
        context: context,
        state: state,
        child: const SmartPreloadingScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.dataOperations,
      pageBuilder: (context, state) => _buildPageWithTransition(
        context: context,
        state: state,
        child: const DataOperationsScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.dataAge,
      pageBuilder: (context, state) => _buildPageWithTransition(
        context: context,
        state: state,
        child: const DataAgeScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.sorting,
      pageBuilder: (context, state) => _buildPageWithTransition(
        context: context,
        state: state,
        child: const SortingScreen(),
      ),
    ),

    // Search examples
    GoRoute(
      path: AppRoutes.searchDropdown,
      pageBuilder: (context, state) => _buildPageWithTransition(
        context: context,
        state: state,
        child: const SearchDropdownScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.multiSelectSearch,
      pageBuilder: (context, state) => _buildPageWithTransition(
        context: context,
        state: state,
        child: const MultiSelectSearchScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.formValidation,
      pageBuilder: (context, state) => _buildPageWithTransition(
        context: context,
        state: state,
        child: const FormValidationSearchScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.keyboardNavigation,
      pageBuilder: (context, state) => _buildPageWithTransition(
        context: context,
        state: state,
        child: const KeyboardNavigationSearchScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.searchTheming,
      pageBuilder: (context, state) => _buildPageWithTransition(
        context: context,
        state: state,
        child: const SearchThemingScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.asyncStates,
      pageBuilder: (context, state) => _buildPageWithTransition(
        context: context,
        state: state,
        child: const AsyncSearchStatesScreen(),
      ),
    ),

    // Error examples
    GoRoute(
      path: AppRoutes.basicError,
      pageBuilder: (context, state) => _buildPageWithTransition(
        context: context,
        state: state,
        child: const BasicErrorExample(),
      ),
    ),
    GoRoute(
      path: AppRoutes.networkErrors,
      pageBuilder: (context, state) => _buildPageWithTransition(
        context: context,
        state: state,
        child: const NetworkErrorsExample(),
      ),
    ),
    GoRoute(
      path: AppRoutes.retryPatterns,
      pageBuilder: (context, state) => _buildPageWithTransition(
        context: context,
        state: state,
        child: const RetryPatternsExample(),
      ),
    ),
    GoRoute(
      path: AppRoutes.customErrorWidgets,
      pageBuilder: (context, state) => _buildPageWithTransition(
        context: context,
        state: state,
        child: const CustomErrorWidgetsExample(),
      ),
    ),
    GoRoute(
      path: AppRoutes.errorRecovery,
      pageBuilder: (context, state) => _buildPageWithTransition(
        context: context,
        state: state,
        child: const ErrorRecoveryExample(),
      ),
    ),
    GoRoute(
      path: AppRoutes.gracefulDegradation,
      pageBuilder: (context, state) => _buildPageWithTransition(
        context: context,
        state: state,
        child: const GracefulDegradationExample(),
      ),
    ),
    GoRoute(
      path: AppRoutes.loadMoreErrors,
      pageBuilder: (context, state) => _buildPageWithTransition(
        context: context,
        state: state,
        child: const LoadMoreErrorsExample(),
      ),
    ),

    // Firebase examples
    GoRoute(
      path: AppRoutes.firestorePagination,
      pageBuilder: (context, state) => _buildPageWithTransition(
        context: context,
        state: state,
        child: const FirestorePaginationScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.firestoreRealtime,
      pageBuilder: (context, state) => _buildPageWithTransition(
        context: context,
        state: state,
        child: const FirestoreRealtimeScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.firestoreSearch,
      pageBuilder: (context, state) => _buildPageWithTransition(
        context: context,
        state: state,
        child: const FirestoreSearchScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.realtimeDatabase,
      pageBuilder: (context, state) => _buildPageWithTransition(
        context: context,
        state: state,
        child: const RealtimeDatabaseScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.firestoreFilters,
      pageBuilder: (context, state) => _buildPageWithTransition(
        context: context,
        state: state,
        child: const FirestoreFiltersScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.offlineSupport,
      pageBuilder: (context, state) => _buildPageWithTransition(
        context: context,
        state: state,
        child: const OfflineSupportScreen(),
      ),
    ),
  ],
);
