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

/// A paginated view widget that automatically integrates scrollview_observer
/// for programmatic scroll navigation (animateToIndex, jumpToIndex, etc.)
class PaginateApiView<T> extends StatefulWidget {
  const PaginateApiView({
    super.key,
    required this.loadedState,
    required this.itemBuilderType,
    required this.itemBuilder,
    this.cubit,
    this.heightOfInitialLoadingAndEmptyWidget,
    this.gridDelegate = const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
    ),
    this.separator = const EmptySeparator(),
    this.shrinkWrap = false,
    this.reverse = false,
    this.scrollDirection = Axis.vertical,
    this.staggeredAxisDirection,
    this.padding = const EdgeInsets.all(0),
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
    // Observer options
    this.enableObserver = true,
    this.onObserverCreated,
  });

  final SmartPaginationLoaded<T> loadedState;

  /// The cubit to attach the observer controller to.
  /// When provided, the observer controller will be automatically attached
  /// for scroll navigation methods (animateToIndex, jumpToIndex, etc.)
  final SmartPaginationCubit<T>? cubit;

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
  final Widget Function(BuildContext context, Exception error, VoidCallback retry)?
      loadMoreErrorBuilder;

  /// Builder for end of list indicator (no more items to load)
  final Widget Function(BuildContext context)? loadMoreNoMoreItemsBuilder;

  // ========== Performance ==========

  /// Number of items before the end that triggers loading more items
  final int invisibleItemsThreshold;

  /// Retry callback for load more errors
  final VoidCallback? retryLoadMore;

  // ========== Observer Options ==========

  /// Whether to enable the built-in scrollview_observer for scroll navigation.
  /// Defaults to true.
  final bool enableObserver;

  /// Callback when the observer controller is created.
  /// Useful for accessing the observer controller externally.
  final void Function(dynamic controller)? onObserverCreated;

  @override
  State<PaginateApiView<T>> createState() => _PaginateApiViewState<T>();
}

class _PaginateApiViewState<T> extends State<PaginateApiView<T>> {
  ScrollController? _internalScrollController;
  ListObserverController? _listObserverController;
  GridObserverController? _gridObserverController;

  ScrollController get _effectiveScrollController =>
      widget.scrollController ?? (_internalScrollController ??= ScrollController());

  List<T> get _items => widget.loadedState.items;

  @override
  void initState() {
    super.initState();
    _initializeObserver();
  }

  void _initializeObserver() {
    if (!widget.enableObserver) return;

    // Create observer based on builder type
    switch (widget.itemBuilderType) {
      case PaginateBuilderType.listView:
      case PaginateBuilderType.reorderableListView:
        _listObserverController = ListObserverController(
          controller: _effectiveScrollController,
        );
        // Attach to cubit if provided
        widget.cubit?.attachListObserverController(_listObserverController!);
        widget.onObserverCreated?.call(_listObserverController);
        break;

      case PaginateBuilderType.gridView:
        _gridObserverController = GridObserverController(
          controller: _effectiveScrollController,
        );
        // Attach to cubit if provided
        widget.cubit?.attachGridObserverController(_gridObserverController!);
        widget.onObserverCreated?.call(_gridObserverController);
        break;

      default:
        // PageView, StaggeredGridView, custom don't need observer
        break;
    }
  }

  @override
  void didUpdateWidget(covariant PaginateApiView<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Re-attach if cubit changed
    if (widget.cubit != oldWidget.cubit && widget.enableObserver) {
      if (_listObserverController != null) {
        oldWidget.cubit?.detachListObserverController();
        widget.cubit?.attachListObserverController(_listObserverController!);
      }
      if (_gridObserverController != null) {
        oldWidget.cubit?.detachGridObserverController();
        widget.cubit?.attachGridObserverController(_gridObserverController!);
      }
    }
  }

  @override
  void dispose() {
    // Detach observer controllers
    widget.cubit?.detachAllObserverControllers();
    _internalScrollController?.dispose();
    super.dispose();
  }

  /// Builds the bottom widget for load more states
  Widget _buildBottomWidget(BuildContext context) {
    if (widget.loadedState.hasReachedEnd) {
      // Use loadMoreNoMoreItemsBuilder if provided
      if (widget.loadMoreNoMoreItemsBuilder != null) {
        return widget.loadMoreNoMoreItemsBuilder!(context);
      }
      // Otherwise don't show anything (seamless end)
      return const SizedBox.shrink();
    } else if (widget.loadedState.isLoadingMore) {
      // Use loadMoreLoadingBuilder if provided, otherwise fallback to bottomLoader
      if (widget.loadMoreLoadingBuilder != null) {
        return widget.loadMoreLoadingBuilder!(context);
      }
      return widget.bottomLoader ?? const SizedBox.shrink();
    } else if (widget.loadedState.loadMoreError != null) {
      // Use loadMoreErrorBuilder if provided with retry callback
      if (widget.loadMoreErrorBuilder != null && widget.retryLoadMore != null) {
        return widget.loadMoreErrorBuilder!(
          context,
          widget.loadedState.loadMoreError!,
          widget.retryLoadMore!,
        );
      }
      // Fallback: simple error display
      return const SizedBox.shrink();
    }
    // Default: show loading indicator
    return widget.bottomLoader ?? const SizedBox.shrink();
  }

  /// Checks if we should trigger loading more items
  bool _shouldLoadMore(int currentIndex) {
    if (widget.loadedState.hasReachedEnd || widget.loadedState.isLoadingMore) {
      return false;
    }
    // Trigger when we're [invisibleItemsThreshold] items away from the end
    return currentIndex >= _items.length - widget.invisibleItemsThreshold;
  }

  @override
  Widget build(BuildContext context) {
    return switch (widget.itemBuilderType) {
      PaginateBuilderType.listView => _buildListView(context),
      PaginateBuilderType.gridView => _buildGridView(context),
      PaginateBuilderType.pageView => _buildPageView(context),
      PaginateBuilderType.staggeredGridView => _buildStaggeredGridView(context),
      PaginateBuilderType.reorderableListView => _buildReorderableListView(context),
      PaginateBuilderType.custom => _buildCustomView(context),
    };
  }

  Widget _buildCustomView(BuildContext context) {
    if (widget.customViewBuilder == null) {
      throw FlutterError(
        'customViewBuilder must be provided when using PaginateBuilderType.custom',
      );
    }
    return widget.customViewBuilder!(
      context,
      _items,
      widget.loadedState.hasReachedEnd,
      widget.fetchPaginatedList,
    );
  }

  Widget _buildGridView(BuildContext context) {
    final scrollView = CustomScrollView(
      reverse: widget.reverse,
      controller: _effectiveScrollController,
      shrinkWrap: widget.shrinkWrap,
      scrollDirection: widget.scrollDirection,
      physics: widget.physics,
      keyboardDismissBehavior: widget.keyboardDismissBehavior,
      cacheExtent: widget.cacheExtent,
      slivers: [
        if (widget.header != null) widget.header!,
        SliverPadding(
          padding: widget.padding,
          sliver: SliverGrid(
            gridDelegate: widget.gridDelegate,
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index >= _items.length) {
                  // Show bottom widget (loading/error/end indicator)
                  return _buildBottomWidget(context);
                }

                // Check if we should trigger loading more
                if (_shouldLoadMore(index)) {
                  widget.fetchPaginatedList?.call();
                }

                return widget.itemBuilder(context, _items, index);
              },
              childCount: widget.loadedState.hasReachedEnd
                  ? _items.length
                  : _items.length + 1,
            ),
          ),
        ),
        if (widget.footer != null) widget.footer!,
      ],
    );

    // Wrap with GridViewObserver if enabled
    if (widget.enableObserver && _gridObserverController != null) {
      return GridViewObserver(
        controller: _gridObserverController!,
        child: scrollView,
      );
    }

    return scrollView;
  }

  Widget _buildListView(BuildContext context) {
    final scrollView = CustomScrollView(
      reverse: widget.reverse,
      controller: _effectiveScrollController,
      shrinkWrap: widget.shrinkWrap,
      scrollDirection: widget.scrollDirection,
      physics: widget.physics,
      keyboardDismissBehavior: widget.keyboardDismissBehavior,
      cacheExtent: widget.cacheExtent,
      slivers: [
        if (widget.header != null) widget.header!,
        SliverPadding(
          padding: widget.padding,
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
                    widget.fetchPaginatedList?.call();
                  }

                  return widget.itemBuilder(context, _items, itemIndex);
                }
                return widget.separator;
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
                (widget.loadedState.hasReachedEnd
                            ? _items.length
                            : _items.length + 1) *
                        2 -
                    1,
              ),
            ),
          ),
        ),
        if (widget.footer != null) widget.footer!,
      ],
    );

    // Wrap with ListViewObserver if enabled
    if (widget.enableObserver && _listObserverController != null) {
      return ListViewObserver(
        controller: _listObserverController!,
        child: scrollView,
      );
    }

    return scrollView;
  }

  Widget _buildReorderableListView(BuildContext context) {
    if (widget.onReorder == null) {
      throw FlutterError(
        'onReorder callback must be provided when using PaginateBuilderType.reorderableListView',
      );
    }

    final listView = ReorderableListView.builder(
      padding: widget.padding is EdgeInsets ? widget.padding as EdgeInsets : null,
      reverse: widget.reverse,
      scrollController: _effectiveScrollController,
      shrinkWrap: widget.shrinkWrap,
      physics: widget.physics,
      keyboardDismissBehavior: widget.keyboardDismissBehavior,
      onReorder: widget.onReorder!,
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final item = widget.itemBuilder(context, _items, index);
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
            final double elevation = lerpDouble(0, 6, animValue) ?? 0;
            final double scale = lerpDouble(1, 1.02, animValue) ?? 1;
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

    // Wrap with ListViewObserver if enabled
    if (widget.enableObserver && _listObserverController != null) {
      return ListViewObserver(
        controller: _listObserverController!,
        child: listView,
      );
    }

    return listView;
  }

  Widget _buildPageView(BuildContext context) {
    return Padding(
      padding: widget.padding,
      child: PageView.custom(
        reverse: widget.reverse,
        allowImplicitScrolling: widget.allowImplicitScrolling,
        controller: widget.pageController,
        scrollDirection: widget.scrollDirection,
        physics: widget.physics,
        onPageChanged: widget.onPageChanged,
        childrenDelegate: SliverChildBuilderDelegate(
          (context, index) {
            if (index >= _items.length) {
              widget.fetchPaginatedList?.call();
              return widget.bottomLoader ?? const SizedBox.shrink();
            }
            return widget.itemBuilder(context, _items, index);
          },
          childCount: widget.loadedState.hasReachedEnd
              ? _items.length
              : _items.length + 1,
        ),
      ),
    );
  }

  Widget _buildStaggeredGridView(BuildContext context) {
    final delegate = widget.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    final crossAxisCount = delegate.crossAxisCount;
    final mainAxisSpacing = delegate.mainAxisSpacing;
    final crossAxisSpacing = delegate.crossAxisSpacing;

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        // Check if we should load more when scrolling near the end
        if (notification is ScrollUpdateNotification) {
          final pixels = notification.metrics.pixels;
          final maxScrollExtent = notification.metrics.maxScrollExtent;
          // Trigger loading when near the end (80% scrolled)
          if (pixels >= maxScrollExtent * 0.8 &&
              !widget.loadedState.hasReachedEnd &&
              !widget.loadedState.isLoadingMore) {
            widget.fetchPaginatedList?.call();
          }
        }
        return false;
      },
      child: SingleChildScrollView(
        reverse: widget.reverse,
        controller: _effectiveScrollController,
        scrollDirection: widget.scrollDirection,
        physics: widget.physics,
        keyboardDismissBehavior: widget.keyboardDismissBehavior,
        padding: widget.padding,
        child: StaggeredGrid.count(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: mainAxisSpacing,
          crossAxisSpacing: crossAxisSpacing,
          children: [
            for (var index = 0; index < _items.length; index++)
              StaggeredGridTile.fit(
                crossAxisCellCount: 1,
                child: widget.itemBuilder(context, _items, index),
              ),
            // Add bottom widget for loading/error/end states
            if (!widget.loadedState.hasReachedEnd ||
                widget.loadMoreNoMoreItemsBuilder != null)
              StaggeredGridTile.fit(
                crossAxisCellCount: crossAxisCount, // Span full width
                child: _buildBottomWidget(context),
              ),
          ],
        ),
      ),
    );
  }
}
