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
import '../screens/smart_pagination/stream_accumulation_screen.dart';
import '../screens/smart_pagination/per_page_error_screen.dart';
import '../screens/smart_pagination/dynamic_end_of_pagination_screen.dart';

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
import '../screens/smart_pagination/chat_screen.dart';

// Search examples
import '../screens/smart_pagination/search_dropdown_screen.dart';
import '../screens/smart_pagination/multi_select_search_screen.dart';
import '../screens/smart_pagination/bottom_sheet_search_screen.dart';
import '../screens/smart_pagination/form_validation_search_screen.dart';
import '../screens/smart_pagination/keyboard_navigation_search_screen.dart';
import '../screens/smart_pagination/search_theming_screen.dart';
import '../screens/smart_pagination/async_search_states_screen.dart';
import '../screens/smart_pagination/overlay_animations_screen.dart';
import '../screens/smart_pagination/key_based_selection_screen.dart';
import '../screens/smart_pagination/initial_selection_screen.dart';
import '../screens/smart_pagination/realistic_search_examples_screen.dart';

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
import '../screens/firebase/seed_data_screen.dart';

part 'app_router.g.dart';

// ============================================================================
// Navigator Keys
// ============================================================================

final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'shell');

// ============================================================================
// Page transition helper
// ============================================================================

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
      return SlideTransition(position: animation.drive(tween), child: child);
    },
    transitionDuration: const Duration(milliseconds: 300),
  );
}

// ============================================================================
// Shell Route — wraps all section routes so HomeScreen persists across tabs
// ============================================================================

@TypedShellRoute<HomeShellRouteData>(
  routes: <TypedRoute<RouteData>>[
    // ---- Basic ----
    TypedGoRoute<BasicRoute>(
      path: '/basic',
      routes: <TypedRoute<RouteData>>[
        TypedGoRoute<BasicListViewRoute>(path: 'list-view'),
        TypedGoRoute<GridViewRoute>(path: 'grid-view'),
        TypedGoRoute<ColumnLayoutRoute>(path: 'column'),
        TypedGoRoute<RowLayoutRoute>(path: 'row'),
        TypedGoRoute<PullToRefreshRoute>(path: 'pull-to-refresh'),
        TypedGoRoute<FilterSearchRoute>(path: 'filter-search'),
        TypedGoRoute<RetryMechanismRoute>(path: 'retry'),
      ],
    ),
    // ---- Streams ----
    TypedGoRoute<StreamRoute>(
      path: '/streams',
      routes: <TypedRoute<RouteData>>[
        TypedGoRoute<SingleStreamRoute>(path: 'single'),
        TypedGoRoute<MultiStreamRoute>(path: 'multi'),
        TypedGoRoute<MergedStreamsRoute>(path: 'merged'),
        TypedGoRoute<StreamAccumulationRoute>(path: 'stream-accumulation'),
        TypedGoRoute<PerPageErrorRoute>(path: 'per-page-error'),
        TypedGoRoute<DynamicEndOfPaginationRoute>(path: 'dynamic-end'),
      ],
    ),
    // ---- Advanced ----
    TypedGoRoute<AdvancedRoute>(
      path: '/advanced',
      routes: <TypedRoute<RouteData>>[
        TypedGoRoute<CursorPaginationRoute>(path: 'cursor'),
        TypedGoRoute<HorizontalScrollRoute>(path: 'horizontal'),
        TypedGoRoute<PageViewRoute>(path: 'page-view'),
        TypedGoRoute<StaggeredGridRoute>(path: 'staggered-grid'),
        TypedGoRoute<CustomStatesRoute>(path: 'custom-states'),
        TypedGoRoute<ScrollControlRoute>(path: 'scroll-control'),
        TypedGoRoute<BeforeBuildHookRoute>(path: 'before-build'),
        TypedGoRoute<HasReachedEndRoute>(path: 'reached-end'),
        TypedGoRoute<CustomViewBuilderRoute>(path: 'custom-builder'),
        TypedGoRoute<ReorderableListRoute>(path: 'reorderable'),
        TypedGoRoute<StateSeparationRoute>(path: 'state-separation'),
        TypedGoRoute<SmartPreloadingRoute>(path: 'preloading'),
        TypedGoRoute<DataOperationsRoute>(path: 'data-operations'),
        TypedGoRoute<DataAgeRoute>(path: 'data-age'),
        TypedGoRoute<SortingRoute>(path: 'sorting'),
        TypedGoRoute<ChatRoute>(path: 'chat'),
      ],
    ),
    // ---- Search ----
    TypedGoRoute<SearchRoute>(
      path: '/search',
      routes: <TypedRoute<RouteData>>[
        TypedGoRoute<SearchDropdownRoute>(path: 'dropdown'),
        TypedGoRoute<MultiSelectSearchRoute>(path: 'multi-select'),
        TypedGoRoute<BottomSheetSearchRoute>(path: 'bottom-sheet'),
        TypedGoRoute<FormValidationRoute>(path: 'form-validation'),
        TypedGoRoute<KeyboardNavigationRoute>(path: 'keyboard'),
        TypedGoRoute<SearchThemingRoute>(path: 'theming'),
        TypedGoRoute<AsyncStatesRoute>(path: 'async-states'),
        TypedGoRoute<OverlayAnimationsRoute>(path: 'overlay-animations'),
        TypedGoRoute<KeyBasedSelectionRoute>(path: 'key-based-selection'),
        TypedGoRoute<InitialSelectionRoute>(path: 'initial-selection'),
        TypedGoRoute<RealisticSearchExamplesRoute>(path: 'realistic-examples'),
      ],
    ),
    // ---- Errors ----
    TypedGoRoute<ErrorRoute>(
      path: '/errors',
      routes: <TypedRoute<RouteData>>[
        TypedGoRoute<BasicErrorRoute>(path: 'basic'),
        TypedGoRoute<NetworkErrorsRoute>(path: 'network'),
        TypedGoRoute<RetryPatternsRoute>(path: 'retry-patterns'),
        TypedGoRoute<CustomErrorWidgetsRoute>(path: 'custom-widgets'),
        TypedGoRoute<ErrorRecoveryRoute>(path: 'recovery'),
        TypedGoRoute<GracefulDegradationRoute>(path: 'graceful'),
        TypedGoRoute<LoadMoreErrorsRoute>(path: 'load-more'),
      ],
    ),
    // ---- Firebase ----
    TypedGoRoute<FirebaseRoute>(
      path: '/firebase',
      routes: <TypedRoute<RouteData>>[
        TypedGoRoute<FirestorePaginationRoute>(path: 'firestore-pagination'),
        TypedGoRoute<FirestoreRealtimeRoute>(path: 'firestore-realtime'),
        TypedGoRoute<FirestoreSearchRoute>(path: 'firestore-search'),
        TypedGoRoute<RealtimeDatabaseRoute>(path: 'realtime-database'),
        TypedGoRoute<FirestoreFiltersRoute>(path: 'firestore-filters'),
        TypedGoRoute<OfflineSupportRoute>(path: 'offline-support'),
        TypedGoRoute<SeedDataRoute>(path: 'seed-data'),
      ],
    ),
  ],
)
class HomeShellRouteData extends ShellRouteData {
  const HomeShellRouteData();

  static final GlobalKey<NavigatorState> $navigatorKey = _shellNavigatorKey;

  @override
  Widget builder(BuildContext context, GoRouterState state, Widget navigator) {
    return navigator;
  }
}

// ============================================================================
// Section parent routes — render HomeScreen on the shell navigator
// ============================================================================

class BasicRoute extends GoRouteData with $BasicRoute {
  const BasicRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return HomeScreen(initialIndex: 0);
  }
}

class StreamRoute extends GoRouteData with $StreamRoute {
  const StreamRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return HomeScreen(initialIndex: 1);
  }
}

class AdvancedRoute extends GoRouteData with $AdvancedRoute {
  const AdvancedRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return HomeScreen(initialIndex: 2);
  }
}

class SearchRoute extends GoRouteData with $SearchRoute {
  const SearchRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return HomeScreen(initialIndex: 3);
  }
}

class ErrorRoute extends GoRouteData with $ErrorRoute {
  const ErrorRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return HomeScreen(initialIndex: 4);
  }
}

class FirebaseRoute extends GoRouteData with $FirebaseRoute {
  const FirebaseRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return HomeScreen(initialIndex: 5);
  }
}

// ============================================================================
// Detail routes — break out to root navigator via $parentNavigatorKey
// ============================================================================

// ---- Basic detail routes ----

class BasicListViewRoute extends GoRouteData with $BasicListViewRoute {
  const BasicListViewRoute();

  static final GlobalKey<NavigatorState> $parentNavigatorKey =
      _rootNavigatorKey;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return _buildPageWithTransition(
      context: context,
      state: state,
      child: const BasicListViewScreen(),
    );
  }
}

class GridViewRoute extends GoRouteData with $GridViewRoute {
  const GridViewRoute();

  static final GlobalKey<NavigatorState> $parentNavigatorKey =
      _rootNavigatorKey;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return _buildPageWithTransition(
      context: context,
      state: state,
      child: const GridViewScreen(),
    );
  }
}

class ColumnLayoutRoute extends GoRouteData with $ColumnLayoutRoute {
  const ColumnLayoutRoute();

  static final GlobalKey<NavigatorState> $parentNavigatorKey =
      _rootNavigatorKey;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return _buildPageWithTransition(
      context: context,
      state: state,
      child: const ColumnExampleScreen(),
    );
  }
}

class RowLayoutRoute extends GoRouteData with $RowLayoutRoute {
  const RowLayoutRoute();

  static final GlobalKey<NavigatorState> $parentNavigatorKey =
      _rootNavigatorKey;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return _buildPageWithTransition(
      context: context,
      state: state,
      child: const RowExampleScreen(),
    );
  }
}

class PullToRefreshRoute extends GoRouteData with $PullToRefreshRoute {
  const PullToRefreshRoute();

  static final GlobalKey<NavigatorState> $parentNavigatorKey =
      _rootNavigatorKey;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return _buildPageWithTransition(
      context: context,
      state: state,
      child: const PullToRefreshScreen(),
    );
  }
}

class FilterSearchRoute extends GoRouteData with $FilterSearchRoute {
  const FilterSearchRoute();

  static final GlobalKey<NavigatorState> $parentNavigatorKey =
      _rootNavigatorKey;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return _buildPageWithTransition(
      context: context,
      state: state,
      child: const FilterSearchScreen(),
    );
  }
}

class RetryMechanismRoute extends GoRouteData with $RetryMechanismRoute {
  const RetryMechanismRoute();

  static final GlobalKey<NavigatorState> $parentNavigatorKey =
      _rootNavigatorKey;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return _buildPageWithTransition(
      context: context,
      state: state,
      child: const RetryDemoScreen(),
    );
  }
}

// ---- Streams detail routes ----

class SingleStreamRoute extends GoRouteData with $SingleStreamRoute {
  const SingleStreamRoute();

  static final GlobalKey<NavigatorState> $parentNavigatorKey =
      _rootNavigatorKey;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return _buildPageWithTransition(
      context: context,
      state: state,
      child: const SingleStreamScreen(),
    );
  }
}

class MultiStreamRoute extends GoRouteData with $MultiStreamRoute {
  const MultiStreamRoute();

  static final GlobalKey<NavigatorState> $parentNavigatorKey =
      _rootNavigatorKey;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return _buildPageWithTransition(
      context: context,
      state: state,
      child: const MultiStreamScreen(),
    );
  }
}

class MergedStreamsRoute extends GoRouteData with $MergedStreamsRoute {
  const MergedStreamsRoute();

  static final GlobalKey<NavigatorState> $parentNavigatorKey =
      _rootNavigatorKey;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return _buildPageWithTransition(
      context: context,
      state: state,
      child: const MergedStreamsScreen(),
    );
  }
}

class StreamAccumulationRoute extends GoRouteData with $StreamAccumulationRoute {
  const StreamAccumulationRoute();

  static final GlobalKey<NavigatorState> $parentNavigatorKey =
      _rootNavigatorKey;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return _buildPageWithTransition(
      context: context,
      state: state,
      child: const StreamAccumulationScreen(),
    );
  }
}

class PerPageErrorRoute extends GoRouteData with $PerPageErrorRoute {
  const PerPageErrorRoute();

  static final GlobalKey<NavigatorState> $parentNavigatorKey =
      _rootNavigatorKey;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return _buildPageWithTransition(
      context: context,
      state: state,
      child: const PerPageErrorScreen(),
    );
  }
}

class DynamicEndOfPaginationRoute extends GoRouteData
    with $DynamicEndOfPaginationRoute {
  const DynamicEndOfPaginationRoute();

  static final GlobalKey<NavigatorState> $parentNavigatorKey =
      _rootNavigatorKey;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return _buildPageWithTransition(
      context: context,
      state: state,
      child: const DynamicEndOfPaginationScreen(),
    );
  }
}

// ---- Advanced detail routes ----

class CursorPaginationRoute extends GoRouteData with $CursorPaginationRoute {
  const CursorPaginationRoute();

  static final GlobalKey<NavigatorState> $parentNavigatorKey =
      _rootNavigatorKey;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return _buildPageWithTransition(
      context: context,
      state: state,
      child: const CursorPaginationScreen(),
    );
  }
}

class HorizontalScrollRoute extends GoRouteData with $HorizontalScrollRoute {
  const HorizontalScrollRoute();

  static final GlobalKey<NavigatorState> $parentNavigatorKey =
      _rootNavigatorKey;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return _buildPageWithTransition(
      context: context,
      state: state,
      child: const HorizontalListScreen(),
    );
  }
}

class PageViewRoute extends GoRouteData with $PageViewRoute {
  const PageViewRoute();

  static final GlobalKey<NavigatorState> $parentNavigatorKey =
      _rootNavigatorKey;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return _buildPageWithTransition(
      context: context,
      state: state,
      child: const PageViewScreen(),
    );
  }
}

class StaggeredGridRoute extends GoRouteData with $StaggeredGridRoute {
  const StaggeredGridRoute();

  static final GlobalKey<NavigatorState> $parentNavigatorKey =
      _rootNavigatorKey;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return _buildPageWithTransition(
      context: context,
      state: state,
      child: const StaggeredGridScreen(),
    );
  }
}

class CustomStatesRoute extends GoRouteData with $CustomStatesRoute {
  const CustomStatesRoute();

  static final GlobalKey<NavigatorState> $parentNavigatorKey =
      _rootNavigatorKey;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return _buildPageWithTransition(
      context: context,
      state: state,
      child: const CustomStatesScreen(),
    );
  }
}

class ScrollControlRoute extends GoRouteData with $ScrollControlRoute {
  const ScrollControlRoute();

  static final GlobalKey<NavigatorState> $parentNavigatorKey =
      _rootNavigatorKey;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return _buildPageWithTransition(
      context: context,
      state: state,
      child: const ScrollControlScreen(),
    );
  }
}

class BeforeBuildHookRoute extends GoRouteData with $BeforeBuildHookRoute {
  const BeforeBuildHookRoute();

  static final GlobalKey<NavigatorState> $parentNavigatorKey =
      _rootNavigatorKey;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return _buildPageWithTransition(
      context: context,
      state: state,
      child: const BeforeBuildHookScreen(),
    );
  }
}

class HasReachedEndRoute extends GoRouteData with $HasReachedEndRoute {
  const HasReachedEndRoute();

  static final GlobalKey<NavigatorState> $parentNavigatorKey =
      _rootNavigatorKey;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return _buildPageWithTransition(
      context: context,
      state: state,
      child: const HasReachedEndScreen(),
    );
  }
}

class CustomViewBuilderRoute extends GoRouteData with $CustomViewBuilderRoute {
  const CustomViewBuilderRoute();

  static final GlobalKey<NavigatorState> $parentNavigatorKey =
      _rootNavigatorKey;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return _buildPageWithTransition(
      context: context,
      state: state,
      child: const CustomViewBuilderScreen(),
    );
  }
}

class ReorderableListRoute extends GoRouteData with $ReorderableListRoute {
  const ReorderableListRoute();

  static final GlobalKey<NavigatorState> $parentNavigatorKey =
      _rootNavigatorKey;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return _buildPageWithTransition(
      context: context,
      state: state,
      child: const ReorderableListScreen(),
    );
  }
}

class StateSeparationRoute extends GoRouteData with $StateSeparationRoute {
  const StateSeparationRoute();

  static final GlobalKey<NavigatorState> $parentNavigatorKey =
      _rootNavigatorKey;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return _buildPageWithTransition(
      context: context,
      state: state,
      child: const StateSeparationScreen(),
    );
  }
}

class SmartPreloadingRoute extends GoRouteData with $SmartPreloadingRoute {
  const SmartPreloadingRoute();

  static final GlobalKey<NavigatorState> $parentNavigatorKey =
      _rootNavigatorKey;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return _buildPageWithTransition(
      context: context,
      state: state,
      child: const SmartPreloadingScreen(),
    );
  }
}

class DataOperationsRoute extends GoRouteData with $DataOperationsRoute {
  const DataOperationsRoute();

  static final GlobalKey<NavigatorState> $parentNavigatorKey =
      _rootNavigatorKey;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return _buildPageWithTransition(
      context: context,
      state: state,
      child: const DataOperationsScreen(),
    );
  }
}

class DataAgeRoute extends GoRouteData with $DataAgeRoute {
  const DataAgeRoute();

  static final GlobalKey<NavigatorState> $parentNavigatorKey =
      _rootNavigatorKey;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return _buildPageWithTransition(
      context: context,
      state: state,
      child: const DataAgeScreen(),
    );
  }
}

class SortingRoute extends GoRouteData with $SortingRoute {
  const SortingRoute();

  static final GlobalKey<NavigatorState> $parentNavigatorKey =
      _rootNavigatorKey;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return _buildPageWithTransition(
      context: context,
      state: state,
      child: const SortingScreen(),
    );
  }
}

class ChatRoute extends GoRouteData with $ChatRoute {
  const ChatRoute();

  static final GlobalKey<NavigatorState> $parentNavigatorKey =
      _rootNavigatorKey;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return _buildPageWithTransition(
      context: context,
      state: state,
      child: const ChatScreen(),
    );
  }
}

// ---- Search detail routes ----

class SearchDropdownRoute extends GoRouteData with $SearchDropdownRoute {
  const SearchDropdownRoute();

  static final GlobalKey<NavigatorState> $parentNavigatorKey =
      _rootNavigatorKey;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return _buildPageWithTransition(
      context: context,
      state: state,
      child: const SearchDropdownScreen(),
    );
  }
}

class MultiSelectSearchRoute extends GoRouteData with $MultiSelectSearchRoute {
  const MultiSelectSearchRoute();

  static final GlobalKey<NavigatorState> $parentNavigatorKey =
      _rootNavigatorKey;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return _buildPageWithTransition(
      context: context,
      state: state,
      child: const MultiSelectSearchScreen(),
    );
  }
}

class BottomSheetSearchRoute extends GoRouteData with $BottomSheetSearchRoute {
  const BottomSheetSearchRoute();

  static final GlobalKey<NavigatorState> $parentNavigatorKey =
      _rootNavigatorKey;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return _buildPageWithTransition(
      context: context,
      state: state,
      child: const BottomSheetSearchScreen(),
    );
  }
}

class FormValidationRoute extends GoRouteData with $FormValidationRoute {
  const FormValidationRoute();

  static final GlobalKey<NavigatorState> $parentNavigatorKey =
      _rootNavigatorKey;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return _buildPageWithTransition(
      context: context,
      state: state,
      child: const FormValidationSearchScreen(),
    );
  }
}

class KeyboardNavigationRoute extends GoRouteData
    with $KeyboardNavigationRoute {
  const KeyboardNavigationRoute();

  static final GlobalKey<NavigatorState> $parentNavigatorKey =
      _rootNavigatorKey;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return _buildPageWithTransition(
      context: context,
      state: state,
      child: const KeyboardNavigationSearchScreen(),
    );
  }
}

class SearchThemingRoute extends GoRouteData with $SearchThemingRoute {
  const SearchThemingRoute();

  static final GlobalKey<NavigatorState> $parentNavigatorKey =
      _rootNavigatorKey;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return _buildPageWithTransition(
      context: context,
      state: state,
      child: const SearchThemingScreen(),
    );
  }
}

class AsyncStatesRoute extends GoRouteData with $AsyncStatesRoute {
  const AsyncStatesRoute();

  static final GlobalKey<NavigatorState> $parentNavigatorKey =
      _rootNavigatorKey;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return _buildPageWithTransition(
      context: context,
      state: state,
      child: const AsyncSearchStatesScreen(),
    );
  }
}

class OverlayAnimationsRoute extends GoRouteData with $OverlayAnimationsRoute {
  const OverlayAnimationsRoute();

  static final GlobalKey<NavigatorState> $parentNavigatorKey =
      _rootNavigatorKey;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return _buildPageWithTransition(
      context: context,
      state: state,
      child: const OverlayAnimationsScreen(),
    );
  }
}

class KeyBasedSelectionRoute extends GoRouteData with $KeyBasedSelectionRoute {
  const KeyBasedSelectionRoute();

  static final GlobalKey<NavigatorState> $parentNavigatorKey =
      _rootNavigatorKey;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return _buildPageWithTransition(
      context: context,
      state: state,
      child: const KeyBasedSelectionScreen(),
    );
  }
}

class InitialSelectionRoute extends GoRouteData with $InitialSelectionRoute {
  const InitialSelectionRoute();

  static final GlobalKey<NavigatorState> $parentNavigatorKey =
      _rootNavigatorKey;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return _buildPageWithTransition(
      context: context,
      state: state,
      child: const InitialSelectionScreen(),
    );
  }
}

class RealisticSearchExamplesRoute extends GoRouteData
    with $RealisticSearchExamplesRoute {
  const RealisticSearchExamplesRoute();

  static final GlobalKey<NavigatorState> $parentNavigatorKey =
      _rootNavigatorKey;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return _buildPageWithTransition(
      context: context,
      state: state,
      child: const RealisticSearchExamplesScreen(),
    );
  }
}

// ---- Error detail routes ----

class BasicErrorRoute extends GoRouteData with $BasicErrorRoute {
  const BasicErrorRoute();

  static final GlobalKey<NavigatorState> $parentNavigatorKey =
      _rootNavigatorKey;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return _buildPageWithTransition(
      context: context,
      state: state,
      child: const BasicErrorExample(),
    );
  }
}

class NetworkErrorsRoute extends GoRouteData with $NetworkErrorsRoute {
  const NetworkErrorsRoute();

  static final GlobalKey<NavigatorState> $parentNavigatorKey =
      _rootNavigatorKey;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return _buildPageWithTransition(
      context: context,
      state: state,
      child: const NetworkErrorsExample(),
    );
  }
}

class RetryPatternsRoute extends GoRouteData with $RetryPatternsRoute {
  const RetryPatternsRoute();

  static final GlobalKey<NavigatorState> $parentNavigatorKey =
      _rootNavigatorKey;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return _buildPageWithTransition(
      context: context,
      state: state,
      child: const RetryPatternsExample(),
    );
  }
}

class CustomErrorWidgetsRoute extends GoRouteData
    with $CustomErrorWidgetsRoute {
  const CustomErrorWidgetsRoute();

  static final GlobalKey<NavigatorState> $parentNavigatorKey =
      _rootNavigatorKey;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return _buildPageWithTransition(
      context: context,
      state: state,
      child: const CustomErrorWidgetsExample(),
    );
  }
}

class ErrorRecoveryRoute extends GoRouteData with $ErrorRecoveryRoute {
  const ErrorRecoveryRoute();

  static final GlobalKey<NavigatorState> $parentNavigatorKey =
      _rootNavigatorKey;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return _buildPageWithTransition(
      context: context,
      state: state,
      child: const ErrorRecoveryExample(),
    );
  }
}

class GracefulDegradationRoute extends GoRouteData
    with $GracefulDegradationRoute {
  const GracefulDegradationRoute();

  static final GlobalKey<NavigatorState> $parentNavigatorKey =
      _rootNavigatorKey;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return _buildPageWithTransition(
      context: context,
      state: state,
      child: const GracefulDegradationExample(),
    );
  }
}

class LoadMoreErrorsRoute extends GoRouteData with $LoadMoreErrorsRoute {
  const LoadMoreErrorsRoute();

  static final GlobalKey<NavigatorState> $parentNavigatorKey =
      _rootNavigatorKey;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return _buildPageWithTransition(
      context: context,
      state: state,
      child: const LoadMoreErrorsExample(),
    );
  }
}

// ---- Firebase detail routes ----

class FirestorePaginationRoute extends GoRouteData
    with $FirestorePaginationRoute {
  const FirestorePaginationRoute();

  static final GlobalKey<NavigatorState> $parentNavigatorKey =
      _rootNavigatorKey;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return _buildPageWithTransition(
      context: context,
      state: state,
      child: const FirestorePaginationScreen(),
    );
  }
}

class FirestoreRealtimeRoute extends GoRouteData with $FirestoreRealtimeRoute {
  const FirestoreRealtimeRoute();

  static final GlobalKey<NavigatorState> $parentNavigatorKey =
      _rootNavigatorKey;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return _buildPageWithTransition(
      context: context,
      state: state,
      child: const FirestoreRealtimeScreen(),
    );
  }
}

class FirestoreSearchRoute extends GoRouteData with $FirestoreSearchRoute {
  const FirestoreSearchRoute();

  static final GlobalKey<NavigatorState> $parentNavigatorKey =
      _rootNavigatorKey;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return _buildPageWithTransition(
      context: context,
      state: state,
      child: const FirestoreSearchScreen(),
    );
  }
}

class RealtimeDatabaseRoute extends GoRouteData with $RealtimeDatabaseRoute {
  const RealtimeDatabaseRoute();

  static final GlobalKey<NavigatorState> $parentNavigatorKey =
      _rootNavigatorKey;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return _buildPageWithTransition(
      context: context,
      state: state,
      child: const RealtimeDatabaseScreen(),
    );
  }
}

class FirestoreFiltersRoute extends GoRouteData with $FirestoreFiltersRoute {
  const FirestoreFiltersRoute();

  static final GlobalKey<NavigatorState> $parentNavigatorKey =
      _rootNavigatorKey;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return _buildPageWithTransition(
      context: context,
      state: state,
      child: const FirestoreFiltersScreen(),
    );
  }
}

class OfflineSupportRoute extends GoRouteData with $OfflineSupportRoute {
  const OfflineSupportRoute();

  static final GlobalKey<NavigatorState> $parentNavigatorKey =
      _rootNavigatorKey;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return _buildPageWithTransition(
      context: context,
      state: state,
      child: const OfflineSupportScreen(),
    );
  }
}

class SeedDataRoute extends GoRouteData with $SeedDataRoute {
  const SeedDataRoute();

  static final GlobalKey<NavigatorState> $parentNavigatorKey =
      _rootNavigatorKey;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return _buildPageWithTransition(
      context: context,
      state: state,
      child: const SeedDataScreen(),
    );
  }
}

// ============================================================================
// Router configuration
// ============================================================================

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: const BasicRoute().location,
  routes: $appRoutes,
);
