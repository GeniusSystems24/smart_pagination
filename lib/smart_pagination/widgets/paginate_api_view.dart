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
class PaginateApiView<T, R extends PaginationRequest> extends StatefulWidget {
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
    this.firstPageEmptyBuilder,
    this.emptyWidget,
    // Performance
    this.invisibleItemsThreshold = 3,
    this.retryLoadMore,
    // Observer options
    this.enableObserver = true,
    this.onObserverCreated,
    // Partial Update & Animation
    this.itemKeyBuilder,
    this.insertItemAnimationBuilder,
    this.removeItemAnimationBuilder,
    this.animationDuration = const Duration(milliseconds: 300),
  });

  final SmartPaginationLoaded<T> loadedState;

  /// The cubit to attach the observer controller to.
  /// When provided, the observer controller will be automatically attached
  /// for scroll navigation methods (animateToIndex, jumpToIndex, etc.)
  final SmartPaginationCubit<T, R>? cubit;

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

  /// Builder for the empty state shown when [loadedState.items] is empty.
  /// When provided, the empty UI is rendered inside the same scroll view used
  /// for items, preserving the scroll controller and observer state.
  final Widget Function(BuildContext context)? firstPageEmptyBuilder;

  /// Fallback empty widget used when [firstPageEmptyBuilder] is not provided.
  final Widget? emptyWidget;

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

  // ========== Partial Update & Animation Options ==========

  /// Provides a unique key for each item, enabling efficient partial updates
  /// and animated insert/remove for ListView.
  final Object Function(T item, int index)? itemKeyBuilder;

  /// Custom animation builder for item insertion.
  final Widget Function(
    BuildContext context,
    int index,
    Animation<double> animation,
    Widget child,
  )? insertItemAnimationBuilder;

  /// Custom animation builder for item removal.
  final Widget Function(
    BuildContext context,
    int index,
    Animation<double> animation,
    Widget child,
  )? removeItemAnimationBuilder;

  /// Duration of insert/remove animations. Defaults to 300ms.
  final Duration animationDuration;

  @override
  State<PaginateApiView<T, R>> createState() => _PaginateApiViewState<T, R>();
}

class _PaginateApiViewState<T, R extends PaginationRequest>
    extends State<PaginateApiView<T, R>> {
  ScrollController? _internalScrollController;
  ListObserverController? _listObserverController;
  GridObserverController? _gridObserverController;

  /// Key for SliverAnimatedList when itemKeyBuilder is provided.
  /// Mutable so it can be regenerated on full reload to keep the animated
  /// list's internal item count in sync with [loadedState.items].
  GlobalKey<SliverAnimatedListState> _animatedListKey =
      GlobalKey<SliverAnimatedListState>();

  /// Key for SliverAnimatedGrid when itemKeyBuilder is provided for grids.
  GlobalKey<SliverAnimatedGridState> _animatedGridKey =
      GlobalKey<SliverAnimatedGridState>();

  /// Stores previous items for building remove animations.
  List<T> _previousItems = [];

  ScrollController get _effectiveScrollController =>
      widget.scrollController ?? (_internalScrollController ??= ScrollController());

  List<T> get _items => widget.loadedState.items;

  bool get _useAnimatedList =>
      widget.itemKeyBuilder != null &&
      widget.itemBuilderType == PaginateBuilderType.listView;

  bool get _useAnimatedGrid =>
      widget.itemKeyBuilder != null &&
      widget.itemBuilderType == PaginateBuilderType.gridView;

  @override
  void initState() {
    super.initState();
    _previousItems = List<T>.from(_items);
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
  void didUpdateWidget(covariant PaginateApiView<T, R> oldWidget) {
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

    // A full reload (clear, setItems, refresh, fetch) invalidates the
    // SliverAnimatedList/Grid's internal item count. Regenerate the keys so
    // a fresh element with `initialItemCount = _items.length` is mounted.
    final op = widget.loadedState.lastOperation;
    final isReload = op is PaginationOperationReload ||
        (oldWidget.loadedState.items.length != _items.length &&
            op is PaginationOperationNone);
    if (isReload) {
      if (_useAnimatedList) {
        _animatedListKey = GlobalKey<SliverAnimatedListState>();
      }
      if (_useAnimatedGrid) {
        _animatedGridKey = GlobalKey<SliverAnimatedGridState>();
      }
      _previousItems = List<T>.from(_items);
      return;
    }

    if (_useAnimatedList || _useAnimatedGrid) {
      _applyAnimatedOperation(op);
    }
    _previousItems = List<T>.from(_items);
  }

  void _applyAnimatedOperation(PaginationOperation op) {
    if (op is PaginationOperationInsert && op.index >= 0) {
      for (var i = 0; i < op.count; i++) {
        if (_useAnimatedList) {
          _animatedListKey.currentState?.insertItem(
            op.index + i,
            duration: widget.animationDuration,
          );
        } else if (_useAnimatedGrid) {
          _animatedGridKey.currentState?.insertItem(
            op.index + i,
            duration: widget.animationDuration,
          );
        }
      }
    } else if (op is PaginationOperationRemove && op.index >= 0) {
      for (var i = op.count - 1; i >= 0; i--) {
        final removeIndex = op.index + i;
        if (removeIndex < _previousItems.length) {
          final removedItem = _previousItems[removeIndex];
          if (_useAnimatedList) {
            _animatedListKey.currentState?.removeItem(
              removeIndex,
              (context, animation) => _buildRemovedItem(
                context,
                removedItem,
                removeIndex,
                animation,
              ),
              duration: widget.animationDuration,
            );
          } else if (_useAnimatedGrid) {
            _animatedGridKey.currentState?.removeItem(
              removeIndex,
              (context, animation) => _buildRemovedItem(
                context,
                removedItem,
                removeIndex,
                animation,
              ),
              duration: widget.animationDuration,
            );
          }
        }
      }
    }
    // Update / Refresh / None: no animation needed. Items in the delegate
    // are reconciled by Flutter via `findChildIndexCallback` so only the
    // changed indexes are rebuilt while element identity is preserved.
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
    if (_items.isEmpty) {
      return _resolveEmptyWidget(context);
    }
    return widget.customViewBuilder!(
      context,
      _items,
      widget.loadedState.hasReachedEnd,
      widget.fetchPaginatedList,
    );
  }

  Widget _buildGridView(BuildContext context) {
    final Widget itemsSliver;

    if (_items.isEmpty) {
      itemsSliver = SliverFillRemaining(
        hasScrollBody: false,
        child: _resolveEmptyWidget(context),
      );
    } else if (_useAnimatedGrid) {
      itemsSliver = SliverAnimatedGrid(
        key: _animatedGridKey,
        gridDelegate: widget.gridDelegate,
        initialItemCount: _items.length,
        itemBuilder: (context, index, animation) {
          if (_shouldLoadMore(index)) {
            widget.fetchPaginatedList?.call();
          }
          if (index >= _items.length) {
            return const SizedBox.shrink();
          }
          final child = widget.itemBuilder(context, _items, index);
          final keyed = _wrapWithKey(child, index);
          if (widget.insertItemAnimationBuilder != null) {
            return widget.insertItemAnimationBuilder!(
              context,
              index,
              animation,
              keyed,
            );
          }
          return _defaultInsertAnimation(animation, keyed);
        },
      );
    } else {
      itemsSliver = SliverGrid(
        gridDelegate: widget.gridDelegate,
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (_shouldLoadMore(index)) {
              widget.fetchPaginatedList?.call();
            }

            final child = widget.itemBuilder(context, _items, index);
            return _wrapWithKey(child, index);
          },
          findChildIndexCallback: widget.itemKeyBuilder != null
              ? (Key key) {
                  if (key is ValueKey) {
                    for (var i = 0; i < _items.length; i++) {
                      if (widget.itemKeyBuilder!(_items[i], i) == key.value) {
                        return i;
                      }
                    }
                  }
                  return null;
                }
              : null,
          childCount: _items.length,
        ),
      );
    }

    final bottomSliver = _buildBottomLoaderSliver(context);

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
          sliver: itemsSliver,
        ),
        if (bottomSliver != null) bottomSliver,
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

  /// Default insert animation: fade + size transition.
  Widget _defaultInsertAnimation(Animation<double> animation, Widget child) {
    return FadeTransition(
      opacity: animation,
      child: SizeTransition(sizeFactor: animation, child: child),
    );
  }

  /// Builds the widget shown during a remove animation.
  Widget _buildRemovedItem(
    BuildContext context,
    T item,
    int index,
    Animation<double> animation,
  ) {
    final child = widget.itemBuilder(context, [item], 0);
    if (widget.removeItemAnimationBuilder != null) {
      return widget.removeItemAnimationBuilder!(context, index, animation, child);
    }
    return FadeTransition(
      opacity: animation,
      child: SizeTransition(sizeFactor: animation, child: child),
    );
  }

  /// Wraps an item with [KeyedSubtree] (when [itemKeyBuilder] is provided)
  /// and a [RepaintBoundary]. The repaint boundary isolates each row's
  /// raster cache so a paint in a sibling row does not invalidate this one,
  /// which is the main source of "everything repaints" symptoms in lists.
  Widget _wrapWithKey(Widget child, int index) {
    final boxed = RepaintBoundary(child: child);
    if (widget.itemKeyBuilder != null && index < _items.length) {
      return KeyedSubtree(
        key: ValueKey(widget.itemKeyBuilder!(_items[index], index)),
        child: boxed,
      );
    }
    return boxed;
  }

  /// Resolves the empty widget to render when the items list is empty.
  /// Prefers [firstPageEmptyBuilder] over [emptyWidget] over a sentinel.
  Widget _resolveEmptyWidget(BuildContext context) {
    if (widget.firstPageEmptyBuilder != null) {
      return widget.firstPageEmptyBuilder!(context);
    }
    return widget.emptyWidget ?? const EmptyDisplay();
  }

  /// Builds the bottom-loader sliver. Returns `null` when there is nothing to
  /// render so the slivers list stays minimal. Kept as a separate sliver so
  /// `isLoadingMore` / `loadMoreError` flips do not invalidate the items
  /// sliver delegate.
  Widget? _buildBottomLoaderSliver(BuildContext context) {
    if (_items.isEmpty) return null;
    final hasReachedEnd = widget.loadedState.hasReachedEnd;
    final isLoadingMore = widget.loadedState.isLoadingMore;
    final loadMoreError = widget.loadedState.loadMoreError;

    if (hasReachedEnd) {
      if (widget.loadMoreNoMoreItemsBuilder == null) return null;
      return SliverToBoxAdapter(
        child: widget.loadMoreNoMoreItemsBuilder!(context),
      );
    }

    if (isLoadingMore) {
      final loader = widget.loadMoreLoadingBuilder?.call(context) ??
          widget.bottomLoader;
      if (loader == null) return null;
      return SliverToBoxAdapter(child: loader);
    }

    if (loadMoreError != null) {
      if (widget.loadMoreErrorBuilder != null && widget.retryLoadMore != null) {
        return SliverToBoxAdapter(
          child: widget.loadMoreErrorBuilder!(
            context,
            loadMoreError,
            widget.retryLoadMore!,
          ),
        );
      }
      return null;
    }

    return null;
  }

  Widget _buildListView(BuildContext context) {
    final Widget itemsSliver;

    if (_items.isEmpty) {
      // Render empty state inside the same CustomScrollView so the scroll
      // controller, observer, and slivers below are kept alive when the
      // list transitions empty <-> non-empty.
      itemsSliver = SliverFillRemaining(
        hasScrollBody: false,
        child: _resolveEmptyWidget(context),
      );
    } else if (_useAnimatedList) {
      // Use SliverAnimatedList for animated insert/remove. Bottom loader is
      // rendered as a separate sliver below so it does not affect the
      // animated list's item count.
      itemsSliver = SliverAnimatedList(
        key: _animatedListKey,
        initialItemCount: _items.length,
        itemBuilder: (context, index, animation) {
          if (_shouldLoadMore(index)) {
            widget.fetchPaginatedList?.call();
          }

          if (index >= _items.length) {
            return const SizedBox.shrink();
          }

          final child = widget.itemBuilder(context, _items, index);
          final keyed = _wrapWithKey(child, index);

          if (widget.insertItemAnimationBuilder != null) {
            return widget.insertItemAnimationBuilder!(
              context,
              index,
              animation,
              keyed,
            );
          }
          return _defaultInsertAnimation(animation, keyed);
        },
      );
    } else {
      // Standard SliverList with optional keys.
      // childCount = items + separators between them, NO trailing slot for
      // the bottom loader (handled by a separate sliver).
      final separatorCount = _items.length > 1 ? _items.length - 1 : 0;
      final childCount = _items.length + separatorCount;
      itemsSliver = SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final itemIndex = index ~/ 2;
            if (index.isEven) {
              if (_shouldLoadMore(itemIndex)) {
                widget.fetchPaginatedList?.call();
              }

              final child = widget.itemBuilder(context, _items, itemIndex);
              return _wrapWithKey(child, itemIndex);
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
          findChildIndexCallback: widget.itemKeyBuilder != null
              ? (Key key) {
                  if (key is ValueKey) {
                    for (var i = 0; i < _items.length; i++) {
                      if (widget.itemKeyBuilder!(_items[i], i) == key.value) {
                        return i * 2; // Account for separators
                      }
                    }
                  }
                  return null;
                }
              : null,
          childCount: childCount,
        ),
      );
    }

    final bottomSliver = _buildBottomLoaderSliver(context);

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
          sliver: itemsSliver,
        ),
        if (bottomSliver != null) bottomSliver,
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

    if (_items.isEmpty) {
      // ReorderableListView.builder asserts itemCount > 0; render the empty
      // state in its place to keep the surrounding layout stable.
      return _resolveEmptyWidget(context);
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
        final key = widget.itemKeyBuilder != null
            ? ValueKey(widget.itemKeyBuilder!(_items[index], index))
            : ValueKey('reorderable_item_$index');
        return KeyedSubtree(key: key, child: item);
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
    if (_items.isEmpty) {
      return _resolveEmptyWidget(context);
    }
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
            final child = widget.itemBuilder(context, _items, index);
            return _wrapWithKey(child, index);
          },
          childCount: widget.loadedState.hasReachedEnd
              ? _items.length
              : _items.length + 1,
        ),
      ),
    );
  }

  Widget _buildStaggeredGridView(BuildContext context) {
    if (_items.isEmpty) {
      return _resolveEmptyWidget(context);
    }
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
                child: _wrapWithKey(
                  widget.itemBuilder(context, _items, index),
                  index,
                ),
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
