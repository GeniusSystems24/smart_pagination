// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_router.dart';

// **************************************************************************
// GoRouterGenerator
// **************************************************************************

List<RouteBase> get $appRoutes => [
  $basicRoute,
  $streamRoute,
  $advancedRoute,
  $searchRoute,
  $errorRoute,
  $firebaseRoute,
];

RouteBase get $basicRoute => GoRouteData.$route(
  path: '/basic',
  factory: $BasicRoute._fromState,
  routes: [
    GoRouteData.$route(
      path: 'list-view',
      factory: $BasicListViewRoute._fromState,
    ),
    GoRouteData.$route(path: 'grid-view', factory: $GridViewRoute._fromState),
    GoRouteData.$route(path: 'column', factory: $ColumnLayoutRoute._fromState),
    GoRouteData.$route(path: 'row', factory: $RowLayoutRoute._fromState),
    GoRouteData.$route(
      path: 'pull-to-refresh',
      factory: $PullToRefreshRoute._fromState,
    ),
    GoRouteData.$route(
      path: 'filter-search',
      factory: $FilterSearchRoute._fromState,
    ),
    GoRouteData.$route(path: 'retry', factory: $RetryMechanismRoute._fromState),
  ],
);

mixin $BasicRoute on GoRouteData {
  static BasicRoute _fromState(GoRouterState state) => const BasicRoute();

  @override
  String get location => GoRouteData.$location('/basic');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $BasicListViewRoute on GoRouteData {
  static BasicListViewRoute _fromState(GoRouterState state) =>
      const BasicListViewRoute();

  @override
  String get location => GoRouteData.$location('/basic/list-view');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $GridViewRoute on GoRouteData {
  static GridViewRoute _fromState(GoRouterState state) => const GridViewRoute();

  @override
  String get location => GoRouteData.$location('/basic/grid-view');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $ColumnLayoutRoute on GoRouteData {
  static ColumnLayoutRoute _fromState(GoRouterState state) =>
      const ColumnLayoutRoute();

  @override
  String get location => GoRouteData.$location('/basic/column');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $RowLayoutRoute on GoRouteData {
  static RowLayoutRoute _fromState(GoRouterState state) =>
      const RowLayoutRoute();

  @override
  String get location => GoRouteData.$location('/basic/row');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $PullToRefreshRoute on GoRouteData {
  static PullToRefreshRoute _fromState(GoRouterState state) =>
      const PullToRefreshRoute();

  @override
  String get location => GoRouteData.$location('/basic/pull-to-refresh');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $FilterSearchRoute on GoRouteData {
  static FilterSearchRoute _fromState(GoRouterState state) =>
      const FilterSearchRoute();

  @override
  String get location => GoRouteData.$location('/basic/filter-search');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $RetryMechanismRoute on GoRouteData {
  static RetryMechanismRoute _fromState(GoRouterState state) =>
      const RetryMechanismRoute();

  @override
  String get location => GoRouteData.$location('/basic/retry');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $streamRoute => GoRouteData.$route(
  path: '/streams',
  factory: $StreamRoute._fromState,
  routes: [
    GoRouteData.$route(path: 'single', factory: $SingleStreamRoute._fromState),
    GoRouteData.$route(path: 'multi', factory: $MultiStreamRoute._fromState),
    GoRouteData.$route(path: 'merged', factory: $MergedStreamsRoute._fromState),
  ],
);

mixin $StreamRoute on GoRouteData {
  static StreamRoute _fromState(GoRouterState state) => const StreamRoute();

  @override
  String get location => GoRouteData.$location('/streams');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $SingleStreamRoute on GoRouteData {
  static SingleStreamRoute _fromState(GoRouterState state) =>
      const SingleStreamRoute();

  @override
  String get location => GoRouteData.$location('/streams/single');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $MultiStreamRoute on GoRouteData {
  static MultiStreamRoute _fromState(GoRouterState state) =>
      const MultiStreamRoute();

  @override
  String get location => GoRouteData.$location('/streams/multi');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $MergedStreamsRoute on GoRouteData {
  static MergedStreamsRoute _fromState(GoRouterState state) =>
      const MergedStreamsRoute();

  @override
  String get location => GoRouteData.$location('/streams/merged');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $advancedRoute => GoRouteData.$route(
  path: '/advanced',
  factory: $AdvancedRoute._fromState,
  routes: [
    GoRouteData.$route(
      path: 'cursor',
      factory: $CursorPaginationRoute._fromState,
    ),
    GoRouteData.$route(
      path: 'horizontal',
      factory: $HorizontalScrollRoute._fromState,
    ),
    GoRouteData.$route(path: 'page-view', factory: $PageViewRoute._fromState),
    GoRouteData.$route(
      path: 'staggered-grid',
      factory: $StaggeredGridRoute._fromState,
    ),
    GoRouteData.$route(
      path: 'custom-states',
      factory: $CustomStatesRoute._fromState,
    ),
    GoRouteData.$route(
      path: 'scroll-control',
      factory: $ScrollControlRoute._fromState,
    ),
    GoRouteData.$route(
      path: 'before-build',
      factory: $BeforeBuildHookRoute._fromState,
    ),
    GoRouteData.$route(
      path: 'reached-end',
      factory: $HasReachedEndRoute._fromState,
    ),
    GoRouteData.$route(
      path: 'custom-builder',
      factory: $CustomViewBuilderRoute._fromState,
    ),
    GoRouteData.$route(
      path: 'reorderable',
      factory: $ReorderableListRoute._fromState,
    ),
    GoRouteData.$route(
      path: 'state-separation',
      factory: $StateSeparationRoute._fromState,
    ),
    GoRouteData.$route(
      path: 'preloading',
      factory: $SmartPreloadingRoute._fromState,
    ),
    GoRouteData.$route(
      path: 'data-operations',
      factory: $DataOperationsRoute._fromState,
    ),
    GoRouteData.$route(path: 'data-age', factory: $DataAgeRoute._fromState),
    GoRouteData.$route(path: 'sorting', factory: $SortingRoute._fromState),
  ],
);

mixin $AdvancedRoute on GoRouteData {
  static AdvancedRoute _fromState(GoRouterState state) => const AdvancedRoute();

  @override
  String get location => GoRouteData.$location('/advanced');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $CursorPaginationRoute on GoRouteData {
  static CursorPaginationRoute _fromState(GoRouterState state) =>
      const CursorPaginationRoute();

  @override
  String get location => GoRouteData.$location('/advanced/cursor');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $HorizontalScrollRoute on GoRouteData {
  static HorizontalScrollRoute _fromState(GoRouterState state) =>
      const HorizontalScrollRoute();

  @override
  String get location => GoRouteData.$location('/advanced/horizontal');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $PageViewRoute on GoRouteData {
  static PageViewRoute _fromState(GoRouterState state) => const PageViewRoute();

  @override
  String get location => GoRouteData.$location('/advanced/page-view');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $StaggeredGridRoute on GoRouteData {
  static StaggeredGridRoute _fromState(GoRouterState state) =>
      const StaggeredGridRoute();

  @override
  String get location => GoRouteData.$location('/advanced/staggered-grid');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $CustomStatesRoute on GoRouteData {
  static CustomStatesRoute _fromState(GoRouterState state) =>
      const CustomStatesRoute();

  @override
  String get location => GoRouteData.$location('/advanced/custom-states');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $ScrollControlRoute on GoRouteData {
  static ScrollControlRoute _fromState(GoRouterState state) =>
      const ScrollControlRoute();

  @override
  String get location => GoRouteData.$location('/advanced/scroll-control');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $BeforeBuildHookRoute on GoRouteData {
  static BeforeBuildHookRoute _fromState(GoRouterState state) =>
      const BeforeBuildHookRoute();

  @override
  String get location => GoRouteData.$location('/advanced/before-build');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $HasReachedEndRoute on GoRouteData {
  static HasReachedEndRoute _fromState(GoRouterState state) =>
      const HasReachedEndRoute();

  @override
  String get location => GoRouteData.$location('/advanced/reached-end');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $CustomViewBuilderRoute on GoRouteData {
  static CustomViewBuilderRoute _fromState(GoRouterState state) =>
      const CustomViewBuilderRoute();

  @override
  String get location => GoRouteData.$location('/advanced/custom-builder');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $ReorderableListRoute on GoRouteData {
  static ReorderableListRoute _fromState(GoRouterState state) =>
      const ReorderableListRoute();

  @override
  String get location => GoRouteData.$location('/advanced/reorderable');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $StateSeparationRoute on GoRouteData {
  static StateSeparationRoute _fromState(GoRouterState state) =>
      const StateSeparationRoute();

  @override
  String get location => GoRouteData.$location('/advanced/state-separation');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $SmartPreloadingRoute on GoRouteData {
  static SmartPreloadingRoute _fromState(GoRouterState state) =>
      const SmartPreloadingRoute();

  @override
  String get location => GoRouteData.$location('/advanced/preloading');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $DataOperationsRoute on GoRouteData {
  static DataOperationsRoute _fromState(GoRouterState state) =>
      const DataOperationsRoute();

  @override
  String get location => GoRouteData.$location('/advanced/data-operations');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $DataAgeRoute on GoRouteData {
  static DataAgeRoute _fromState(GoRouterState state) => const DataAgeRoute();

  @override
  String get location => GoRouteData.$location('/advanced/data-age');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $SortingRoute on GoRouteData {
  static SortingRoute _fromState(GoRouterState state) => const SortingRoute();

  @override
  String get location => GoRouteData.$location('/advanced/sorting');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $searchRoute => GoRouteData.$route(
  path: '/search',
  factory: $SearchRoute._fromState,
  routes: [
    GoRouteData.$route(
      path: 'dropdown',
      factory: $SearchDropdownRoute._fromState,
    ),
    GoRouteData.$route(
      path: 'multi-select',
      factory: $MultiSelectSearchRoute._fromState,
    ),
    GoRouteData.$route(
      path: 'form-validation',
      factory: $FormValidationRoute._fromState,
    ),
    GoRouteData.$route(
      path: 'keyboard',
      factory: $KeyboardNavigationRoute._fromState,
    ),
    GoRouteData.$route(
      path: 'theming',
      factory: $SearchThemingRoute._fromState,
    ),
    GoRouteData.$route(
      path: 'async-states',
      factory: $AsyncStatesRoute._fromState,
    ),
    GoRouteData.$route(
      path: 'overlay-animations',
      factory: $OverlayAnimationsRoute._fromState,
    ),
  ],
);

mixin $SearchRoute on GoRouteData {
  static SearchRoute _fromState(GoRouterState state) => const SearchRoute();

  @override
  String get location => GoRouteData.$location('/search');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $SearchDropdownRoute on GoRouteData {
  static SearchDropdownRoute _fromState(GoRouterState state) =>
      const SearchDropdownRoute();

  @override
  String get location => GoRouteData.$location('/search/dropdown');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $MultiSelectSearchRoute on GoRouteData {
  static MultiSelectSearchRoute _fromState(GoRouterState state) =>
      const MultiSelectSearchRoute();

  @override
  String get location => GoRouteData.$location('/search/multi-select');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $FormValidationRoute on GoRouteData {
  static FormValidationRoute _fromState(GoRouterState state) =>
      const FormValidationRoute();

  @override
  String get location => GoRouteData.$location('/search/form-validation');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $KeyboardNavigationRoute on GoRouteData {
  static KeyboardNavigationRoute _fromState(GoRouterState state) =>
      const KeyboardNavigationRoute();

  @override
  String get location => GoRouteData.$location('/search/keyboard');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $SearchThemingRoute on GoRouteData {
  static SearchThemingRoute _fromState(GoRouterState state) =>
      const SearchThemingRoute();

  @override
  String get location => GoRouteData.$location('/search/theming');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $AsyncStatesRoute on GoRouteData {
  static AsyncStatesRoute _fromState(GoRouterState state) =>
      const AsyncStatesRoute();

  @override
  String get location => GoRouteData.$location('/search/async-states');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $OverlayAnimationsRoute on GoRouteData {
  static OverlayAnimationsRoute _fromState(GoRouterState state) =>
      const OverlayAnimationsRoute();

  @override
  String get location => GoRouteData.$location('/search/overlay-animations');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $errorRoute => GoRouteData.$route(
  path: '/errors',
  factory: $ErrorRoute._fromState,
  routes: [
    GoRouteData.$route(path: 'basic', factory: $BasicErrorRoute._fromState),
    GoRouteData.$route(
      path: 'network',
      factory: $NetworkErrorsRoute._fromState,
    ),
    GoRouteData.$route(
      path: 'retry-patterns',
      factory: $RetryPatternsRoute._fromState,
    ),
    GoRouteData.$route(
      path: 'custom-widgets',
      factory: $CustomErrorWidgetsRoute._fromState,
    ),
    GoRouteData.$route(
      path: 'recovery',
      factory: $ErrorRecoveryRoute._fromState,
    ),
    GoRouteData.$route(
      path: 'graceful',
      factory: $GracefulDegradationRoute._fromState,
    ),
    GoRouteData.$route(
      path: 'load-more',
      factory: $LoadMoreErrorsRoute._fromState,
    ),
  ],
);

mixin $ErrorRoute on GoRouteData {
  static ErrorRoute _fromState(GoRouterState state) => const ErrorRoute();

  @override
  String get location => GoRouteData.$location('/errors');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $BasicErrorRoute on GoRouteData {
  static BasicErrorRoute _fromState(GoRouterState state) =>
      const BasicErrorRoute();

  @override
  String get location => GoRouteData.$location('/errors/basic');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $NetworkErrorsRoute on GoRouteData {
  static NetworkErrorsRoute _fromState(GoRouterState state) =>
      const NetworkErrorsRoute();

  @override
  String get location => GoRouteData.$location('/errors/network');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $RetryPatternsRoute on GoRouteData {
  static RetryPatternsRoute _fromState(GoRouterState state) =>
      const RetryPatternsRoute();

  @override
  String get location => GoRouteData.$location('/errors/retry-patterns');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $CustomErrorWidgetsRoute on GoRouteData {
  static CustomErrorWidgetsRoute _fromState(GoRouterState state) =>
      const CustomErrorWidgetsRoute();

  @override
  String get location => GoRouteData.$location('/errors/custom-widgets');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $ErrorRecoveryRoute on GoRouteData {
  static ErrorRecoveryRoute _fromState(GoRouterState state) =>
      const ErrorRecoveryRoute();

  @override
  String get location => GoRouteData.$location('/errors/recovery');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $GracefulDegradationRoute on GoRouteData {
  static GracefulDegradationRoute _fromState(GoRouterState state) =>
      const GracefulDegradationRoute();

  @override
  String get location => GoRouteData.$location('/errors/graceful');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $LoadMoreErrorsRoute on GoRouteData {
  static LoadMoreErrorsRoute _fromState(GoRouterState state) =>
      const LoadMoreErrorsRoute();

  @override
  String get location => GoRouteData.$location('/errors/load-more');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $firebaseRoute => GoRouteData.$route(
  path: '/firebase',
  factory: $FirebaseRoute._fromState,
  routes: [
    GoRouteData.$route(
      path: 'firestore-pagination',
      factory: $FirestorePaginationRoute._fromState,
    ),
    GoRouteData.$route(
      path: 'firestore-realtime',
      factory: $FirestoreRealtimeRoute._fromState,
    ),
    GoRouteData.$route(
      path: 'firestore-search',
      factory: $FirestoreSearchRoute._fromState,
    ),
    GoRouteData.$route(
      path: 'realtime-database',
      factory: $RealtimeDatabaseRoute._fromState,
    ),
    GoRouteData.$route(
      path: 'firestore-filters',
      factory: $FirestoreFiltersRoute._fromState,
    ),
    GoRouteData.$route(
      path: 'offline-support',
      factory: $OfflineSupportRoute._fromState,
    ),
    GoRouteData.$route(path: 'seed-data', factory: $SeedDataRoute._fromState),
  ],
);

mixin $FirebaseRoute on GoRouteData {
  static FirebaseRoute _fromState(GoRouterState state) => const FirebaseRoute();

  @override
  String get location => GoRouteData.$location('/firebase');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $FirestorePaginationRoute on GoRouteData {
  static FirestorePaginationRoute _fromState(GoRouterState state) =>
      const FirestorePaginationRoute();

  @override
  String get location =>
      GoRouteData.$location('/firebase/firestore-pagination');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $FirestoreRealtimeRoute on GoRouteData {
  static FirestoreRealtimeRoute _fromState(GoRouterState state) =>
      const FirestoreRealtimeRoute();

  @override
  String get location => GoRouteData.$location('/firebase/firestore-realtime');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $FirestoreSearchRoute on GoRouteData {
  static FirestoreSearchRoute _fromState(GoRouterState state) =>
      const FirestoreSearchRoute();

  @override
  String get location => GoRouteData.$location('/firebase/firestore-search');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $RealtimeDatabaseRoute on GoRouteData {
  static RealtimeDatabaseRoute _fromState(GoRouterState state) =>
      const RealtimeDatabaseRoute();

  @override
  String get location => GoRouteData.$location('/firebase/realtime-database');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $FirestoreFiltersRoute on GoRouteData {
  static FirestoreFiltersRoute _fromState(GoRouterState state) =>
      const FirestoreFiltersRoute();

  @override
  String get location => GoRouteData.$location('/firebase/firestore-filters');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $OfflineSupportRoute on GoRouteData {
  static OfflineSupportRoute _fromState(GoRouterState state) =>
      const OfflineSupportRoute();

  @override
  String get location => GoRouteData.$location('/firebase/offline-support');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $SeedDataRoute on GoRouteData {
  static SeedDataRoute _fromState(GoRouterState state) => const SeedDataRoute();

  @override
  String get location => GoRouteData.$location('/firebase/seed-data');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}
