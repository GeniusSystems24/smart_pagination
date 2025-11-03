part of '../pagination.dart';

enum PaginateBuilderType {
  /// Paginate as a ListView
  listView,

  /// Paginate as a GridView
  gridView,

  /// Paginate as a PageView
  pageView,

  /// Paginate as a StaggeredGridView
  ///
  /// [flutter_staggered_grid_view](https://pub.dev/packages/flutter_staggered_grid_view)
  staggeredGridView,

  /// Use a custom view builder
  custom,
}

class PaginateApiView<T> extends StatelessWidget {
  const PaginateApiView({
    super.key,
    required this.loadedState,
    required this.itemBuilderType,
    required this.itemBuilder,
    this.heightOfInitialLoadingAndEmptyWidget,
    this.gridDelegate = const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
    ),
    this.separator = const EmptySeparator(),
    this.shrinkWrap = false,
    this.reverse = false,
    this.scrollDirection = Axis.vertical,
    this.staggeredAxisDirection,
    this.padding = const EdgeInsetsGeometry.all(0),
    this.physics,
    this.scrollController,
    this.allowImplicitScrolling = false,
    this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
    this.pageController,
    this.onPageChanged,
    this.header,
    this.footer,
    this.bottomLoader,
    this.fetchPaginatedList,
    this.cacheExtent,
    this.customViewBuilder,
  });

  final SmartPaginationLoaded<T> loadedState;

  final double? heightOfInitialLoadingAndEmptyWidget;
  final SliverGridDelegate gridDelegate;
  final PaginateBuilderType itemBuilderType;
  final EdgeInsetsGeometry padding;
  final ScrollPhysics? physics;
  final bool reverse;
  final bool allowImplicitScrolling;
  final ScrollViewKeyboardDismissBehavior keyboardDismissBehavior;
  final ScrollController? scrollController;
  final PageController? pageController;
  final Axis scrollDirection;
  final AxisDirection? staggeredAxisDirection;
  final Widget separator;
  final bool shrinkWrap;
  final Widget? header;
  final Widget? footer;
  final Widget Function(BuildContext context, List<T> documents, int index)
  itemBuilder;
  final void Function(int)? onPageChanged;
  final double? cacheExtent;

  final void Function()? fetchPaginatedList;
  final Widget? bottomLoader;

  /// Custom view builder for complete control over the view
  /// When using PaginateBuilderType.custom, this builder is called with:
  /// - context: BuildContext
  /// - items: List of items
  /// - hasReachedEnd: Whether pagination has reached the end
  /// - fetchMore: Callback to trigger loading more items
  final Widget Function(
    BuildContext context,
    List<T> items,
    bool hasReachedEnd,
    VoidCallback? fetchMore,
  )? customViewBuilder;

  List<T> get _items => loadedState.items;

  @override
  Widget build(BuildContext context) {
    return switch (itemBuilderType) {
      PaginateBuilderType.listView => _buildListView(context),
      PaginateBuilderType.gridView => _buildGridView(context),
      PaginateBuilderType.pageView => _buildPageView(context),
      PaginateBuilderType.staggeredGridView => _buildStaggeredGridView(context),
      PaginateBuilderType.custom => _buildCustomView(context),
    };
  }

  Widget _buildCustomView(BuildContext context) {
    if (customViewBuilder == null) {
      throw FlutterError(
        'customViewBuilder must be provided when using PaginateBuilderType.custom',
      );
    }
    return customViewBuilder!(
      context,
      _items,
      loadedState.hasReachedEnd,
      fetchPaginatedList,
    );
  }

  Widget _buildGridView(BuildContext context) {
    return CustomScrollView(
      reverse: reverse,
      controller: scrollController,
      shrinkWrap: shrinkWrap,
      scrollDirection: scrollDirection,
      physics: physics,
      keyboardDismissBehavior: keyboardDismissBehavior,
      cacheExtent: cacheExtent,
      slivers: [
        if (header != null) header!,
        SliverPadding(
          padding: padding,
          sliver: SliverGrid(
            gridDelegate: gridDelegate,
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index >= _items.length) {
                  fetchPaginatedList?.call();
                  return bottomLoader ?? const SizedBox.shrink();
                }
                return itemBuilder(context, _items, index);
              },
              childCount: loadedState.hasReachedEnd
                  ? _items.length
                  : _items.length + 1,
            ),
          ),
        ),
        if (footer != null) footer!,
      ],
    );
  }

  Widget _buildListView(BuildContext context) {
    return CustomScrollView(
      reverse: reverse,
      controller: scrollController,
      shrinkWrap: shrinkWrap,
      scrollDirection: scrollDirection,
      physics: physics,
      keyboardDismissBehavior: keyboardDismissBehavior,
      cacheExtent: cacheExtent,
      slivers: [
        if (header != null) header!,
        SliverPadding(
          padding: padding,
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final itemIndex = index ~/ 2;
                if (index.isEven) {
                  if (itemIndex >= _items.length) {
                    fetchPaginatedList?.call();
                    return bottomLoader ?? const SizedBox.shrink();
                  }
                  return itemBuilder(context, _items, itemIndex);
                }
                return separator;
              },
              semanticIndexCallback: (widget, localIndex) {
                if (localIndex.isEven) {
                  return localIndex ~/ 2;
                }
                // ignore: avoid_returning_null
                return null;
              },
              childCount: math.max(
                0,
                (loadedState.hasReachedEnd
                            ? _items.length
                            : _items.length + 1) *
                        2 -
                    1,
              ),
            ),
          ),
        ),
        if (footer != null) footer!,
      ],
    );
  }

  Widget _buildPageView(BuildContext context) {
    return Padding(
      padding: padding,
      child: PageView.custom(
        reverse: reverse,
        allowImplicitScrolling: allowImplicitScrolling,
        controller: pageController,
        scrollDirection: scrollDirection,
        physics: physics,
        onPageChanged: onPageChanged,
        childrenDelegate: SliverChildBuilderDelegate(
          (context, index) {
            if (index >= _items.length) {
              fetchPaginatedList?.call();
              return bottomLoader ?? const SizedBox.shrink();
            }
            return itemBuilder(context, _items, index);
          },
          childCount: loadedState.hasReachedEnd
              ? _items.length
              : _items.length + 1,
        ),
      ),
    );
  }

  Widget _buildStaggeredGridView(BuildContext context) {
    final delegate = gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    final crossAxisCount = delegate.crossAxisCount;
    final mainAxisSpacing = delegate.mainAxisSpacing;
    final crossAxisSpacing = delegate.crossAxisSpacing;

    return SingleChildScrollView(
      reverse: reverse,
      controller: scrollController,
      scrollDirection: scrollDirection,
      physics: physics,
      keyboardDismissBehavior: keyboardDismissBehavior,
      padding: padding,
      child: StaggeredGrid.count(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: mainAxisSpacing,
        crossAxisSpacing: crossAxisSpacing,
        children: [
          for (
            var index = 0;
            index < _items.length + (loadedState.hasReachedEnd ? 0 : 1);
            index++
          )
            if (index < _items.length)
              StaggeredGridTile.fit(
                crossAxisCellCount: 1,
                child: itemBuilder(context, _items, index),
              )
            else
              StaggeredGridTile.fit(
                crossAxisCellCount: 1,
                child: GestureDetector(
                  onTap: fetchPaginatedList,
                  behavior: HitTestBehavior.opaque,
                  child: bottomLoader ?? const SizedBox.shrink(),
                ),
              ),
        ],
      ),
    );
  }
}
