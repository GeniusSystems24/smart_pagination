part of '../../pagination.dart';

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

  /// Paginate as a ReorderableListView
  /// Allows users to reorder items by drag and drop
  reorderableListView,

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
    this.onReorder,
    // State Separation Builders
    this.loadMoreLoadingBuilder,
    this.loadMoreErrorBuilder,
    this.loadMoreNoMoreItemsBuilder,
    // Performance
    this.invisibleItemsThreshold = 3,
    this.retryLoadMore,
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

  /// Callback for reordering items in ReorderableListView
  /// Called with the old index and new index when an item is moved
  final void Function(int oldIndex, int newIndex)? onReorder;

  // ========== State Separation Builders ==========

  /// Builder for load more loading indicator
  final Widget Function(BuildContext context)? loadMoreLoadingBuilder;

  /// Builder for load more error state with retry capability
  final Widget Function(BuildContext context, Exception error, VoidCallback retry)? loadMoreErrorBuilder;

  /// Builder for end of list indicator (no more items to load)
  final Widget Function(BuildContext context)? loadMoreNoMoreItemsBuilder;

  // ========== Performance ==========

  /// Number of items before the end that triggers loading more items
  final int invisibleItemsThreshold;

  /// Retry callback for load more errors
  final VoidCallback? retryLoadMore;

  List<T> get _items => loadedState.items;

  /// Builds the bottom widget for load more states
  Widget _buildBottomWidget(BuildContext context) {
    if (loadedState.hasReachedEnd) {
      // Use loadMoreNoMoreItemsBuilder if provided
      if (loadMoreNoMoreItemsBuilder != null) {
        return loadMoreNoMoreItemsBuilder!(context);
      }
      // Otherwise don't show anything (seamless end)
      return const SizedBox.shrink();
    } else if (loadedState.isLoadingMore) {
      // Use loadMoreLoadingBuilder if provided, otherwise fallback to bottomLoader
      if (loadMoreLoadingBuilder != null) {
        return loadMoreLoadingBuilder!(context);
      }
      return bottomLoader ?? const SizedBox.shrink();
    } else if (loadedState.loadMoreError != null) {
      // Use loadMoreErrorBuilder if provided with retry callback
      if (loadMoreErrorBuilder != null && retryLoadMore != null) {
        return loadMoreErrorBuilder!(
          context,
          loadedState.loadMoreError!,
          retryLoadMore!,
        );
      }
      // Fallback: simple error display
      return const SizedBox.shrink();
    }
    // Default: show loading indicator
    return bottomLoader ?? const SizedBox.shrink();
  }

  /// Checks if we should trigger loading more items
  bool _shouldLoadMore(int currentIndex) {
    if (loadedState.hasReachedEnd || loadedState.isLoadingMore) {
      return false;
    }
    // Trigger when we're [invisibleItemsThreshold] items away from the end
    return currentIndex >= _items.length - invisibleItemsThreshold;
  }

  @override
  Widget build(BuildContext context) {
    return switch (itemBuilderType) {
      PaginateBuilderType.listView => _buildListView(context),
      PaginateBuilderType.gridView => _buildGridView(context),
      PaginateBuilderType.pageView => _buildPageView(context),
      PaginateBuilderType.staggeredGridView => _buildStaggeredGridView(context),
      PaginateBuilderType.reorderableListView => _buildReorderableListView(context),
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
                  // Show bottom widget (loading/error/end indicator)
                  return _buildBottomWidget(context);
                }

                // Check if we should trigger loading more
                if (_shouldLoadMore(index)) {
                  fetchPaginatedList?.call();
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
                    // Show bottom widget (loading/error/end indicator)
                    return _buildBottomWidget(context);
                  }

                  // Check if we should trigger loading more
                  if (_shouldLoadMore(itemIndex)) {
                    fetchPaginatedList?.call();
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

  Widget _buildReorderableListView(BuildContext context) {
    if (onReorder == null) {
      throw FlutterError(
        'onReorder callback must be provided when using PaginateBuilderType.reorderableListView',
      );
    }

    return ReorderableListView.builder(
      padding: padding,
      reverse: reverse,
      scrollController: scrollController,
      shrinkWrap: shrinkWrap,
      physics: physics,
      keyboardDismissBehavior: keyboardDismissBehavior,
      onReorder: onReorder!,
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final item = itemBuilder(context, _items, index);
        // Wrap with a key - ReorderableListView requires each child to have a unique key
        return KeyedSubtree(
          key: ValueKey('reorderable_item_$index'),
          child: item,
        );
      },
      proxyDecorator: (child, index, animation) {
        return AnimatedBuilder(
          animation: animation,
          builder: (BuildContext context, Widget? child) {
            final double animValue = Curves.easeInOut.transform(animation.value);
            final double elevation = lerpDouble(0, 6, animValue)!;
            final double scale = lerpDouble(1, 1.02, animValue)!;
            return Transform.scale(
              scale: scale,
              child: Card(
                elevation: elevation,
                child: child,
              ),
            );
          },
          child: child,
        );
      },
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
