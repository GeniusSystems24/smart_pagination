part of '../../pagination.dart';

/// A widget that combines SmartSearchBox with an overlay dropdown for results.
///
/// The overlay automatically positions itself in the best available space
/// (top, bottom, left, or right) relative to the search box, unless a
/// specific position is configured.
///
/// Example:
/// ```dart
/// SmartSearchOverlay<Product>(
///   controller: searchController,
///   itemBuilder: (context, product) => ListTile(
///     title: Text(product.name),
///     subtitle: Text('\$${product.price}'),
///   ),
///   onItemSelected: (product) {
///     // Handle selection
///   },
/// )
/// ```
class SmartSearchOverlay<T> extends StatefulWidget {
  const SmartSearchOverlay({
    super.key,
    required this.controller,
    required this.itemBuilder,
    this.onItemSelected,
    this.searchBoxDecoration,
    this.overlayConfig = const SmartSearchOverlayConfig(),
    this.loadingBuilder,
    this.emptyBuilder,
    this.errorBuilder,
    this.separatorBuilder,
    this.headerBuilder,
    this.footerBuilder,
    this.overlayDecoration,
    this.searchBoxStyle,
    this.searchBoxPrefixIcon,
    this.searchBoxSuffixIcon,
    this.showClearButton = true,
    this.searchBoxBorderRadius,
  });

  /// The search controller managing the search state.
  final SmartSearchController<T> controller;

  /// Builder for each result item.
  final Widget Function(BuildContext context, T item) itemBuilder;

  /// Called when an item is selected from the results.
  final ValueChanged<T>? onItemSelected;

  /// Decoration for the search text field.
  final InputDecoration? searchBoxDecoration;

  /// Configuration for the overlay appearance and behavior.
  final SmartSearchOverlayConfig overlayConfig;

  /// Builder for the loading state in the overlay.
  final WidgetBuilder? loadingBuilder;

  /// Builder for the empty state in the overlay.
  final WidgetBuilder? emptyBuilder;

  /// Builder for the error state in the overlay.
  final Widget Function(BuildContext context, Exception error)? errorBuilder;

  /// Builder for separators between items.
  final IndexedWidgetBuilder? separatorBuilder;

  /// Builder for a header above the results list.
  final WidgetBuilder? headerBuilder;

  /// Builder for a footer below the results list.
  final WidgetBuilder? footerBuilder;

  /// Decoration for the overlay container.
  final BoxDecoration? overlayDecoration;

  /// Text style for the search box.
  final TextStyle? searchBoxStyle;

  /// Prefix icon for the search box.
  final Widget? searchBoxPrefixIcon;

  /// Suffix icon for the search box.
  final Widget? searchBoxSuffixIcon;

  /// Whether to show a clear button in the search box.
  final bool showClearButton;

  /// Border radius for the search box.
  final BorderRadius? searchBoxBorderRadius;

  @override
  State<SmartSearchOverlay<T>> createState() => _SmartSearchOverlayState<T>();
}

class _SmartSearchOverlayState<T> extends State<SmartSearchOverlay<T>>
    with SingleTickerProviderStateMixin {
  final LayerLink _layerLink = LayerLink();
  final GlobalKey _searchBoxKey = GlobalKey();

  OverlayEntry? _overlayEntry;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.overlayConfig.animationDuration,
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _removeOverlay();
    _animationController.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (widget.controller.isOverlayVisible) {
      _showOverlay();
    } else {
      _hideOverlay();
    }
  }

  void _showOverlay() {
    if (_overlayEntry != null) {
      _overlayEntry!.markNeedsBuild();
      return;
    }

    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    _animationController.forward();
  }

  void _hideOverlay() {
    if (_overlayEntry == null) return;

    _animationController.reverse().then((_) {
      _removeOverlay();
    });
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _createOverlayEntry() {
    return OverlayEntry(
      builder: (context) {
        return _OverlayContent<T>(
          layerLink: _layerLink,
          searchBoxKey: _searchBoxKey,
          controller: widget.controller,
          config: widget.overlayConfig,
          fadeAnimation: _fadeAnimation,
          itemBuilder: widget.itemBuilder,
          onItemSelected: _onItemSelected,
          loadingBuilder: widget.loadingBuilder,
          emptyBuilder: widget.emptyBuilder,
          errorBuilder: widget.errorBuilder,
          separatorBuilder: widget.separatorBuilder,
          headerBuilder: widget.headerBuilder,
          footerBuilder: widget.footerBuilder,
          overlayDecoration: widget.overlayDecoration,
          onDismiss: () => widget.controller.hideOverlay(),
        );
      },
    );
  }

  void _onItemSelected(T item) {
    widget.controller.selectItem(item);
    widget.onItemSelected?.call(item);
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: SmartSearchBox<T>(
        key: _searchBoxKey,
        controller: widget.controller,
        decoration: widget.searchBoxDecoration,
        style: widget.searchBoxStyle,
        prefixIcon: widget.searchBoxPrefixIcon,
        suffixIcon: widget.searchBoxSuffixIcon,
        showClearButton: widget.showClearButton,
        borderRadius: widget.searchBoxBorderRadius,
      ),
    );
  }
}

class _OverlayContent<T> extends StatefulWidget {
  const _OverlayContent({
    required this.layerLink,
    required this.searchBoxKey,
    required this.controller,
    required this.config,
    required this.fadeAnimation,
    required this.itemBuilder,
    required this.onItemSelected,
    required this.onDismiss,
    this.loadingBuilder,
    this.emptyBuilder,
    this.errorBuilder,
    this.separatorBuilder,
    this.headerBuilder,
    this.footerBuilder,
    this.overlayDecoration,
    this.focusedItemDecoration,
  });

  final LayerLink layerLink;
  final GlobalKey searchBoxKey;
  final SmartSearchController<T> controller;
  final SmartSearchOverlayConfig config;
  final Animation<double> fadeAnimation;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final ValueChanged<T> onItemSelected;
  final VoidCallback onDismiss;
  final WidgetBuilder? loadingBuilder;
  final WidgetBuilder? emptyBuilder;
  final Widget Function(BuildContext context, Exception error)? errorBuilder;
  final IndexedWidgetBuilder? separatorBuilder;
  final WidgetBuilder? headerBuilder;
  final WidgetBuilder? footerBuilder;
  final BoxDecoration? overlayDecoration;
  final BoxDecoration? focusedItemDecoration;

  @override
  State<_OverlayContent<T>> createState() => _OverlayContentState<T>();
}

class _OverlayContentState<T> extends State<_OverlayContent<T>> {
  final ScrollController _scrollController = ScrollController();
  static const double _itemHeight = 56.0; // Approximate item height

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _scrollController.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    // Scroll to the focused item when it changes
    if (widget.controller.hasItemFocus) {
      _scrollToFocusedItem();
    }
  }

  void _scrollToFocusedItem() {
    final focusedIndex = widget.controller.focusedIndex;
    if (focusedIndex < 0 || !_scrollController.hasClients) return;

    // Add small padding to ensure item is fully visible
    const padding = 8.0;
    final targetOffset = focusedIndex * _itemHeight;
    final viewportHeight = _scrollController.position.viewportDimension;
    final currentOffset = _scrollController.offset;
    final maxOffset = _scrollController.position.maxScrollExtent;

    // Check if item is already fully visible with padding
    final itemTop = targetOffset;
    final itemBottom = targetOffset + _itemHeight;
    final viewTop = currentOffset + padding;
    final viewBottom = currentOffset + viewportHeight - padding;

    if (itemTop >= viewTop && itemBottom <= viewBottom) {
      return; // Already fully visible
    }

    // Calculate the scroll position
    double newOffset;
    if (itemTop < viewTop) {
      // Item is above the viewport, scroll up with padding
      newOffset = targetOffset - padding;
    } else {
      // Item is below the viewport, scroll down with padding
      newOffset = targetOffset - viewportHeight + _itemHeight + padding;
    }

    newOffset = newOffset.clamp(0.0, maxOffset);

    _scrollController.animateTo(
      newOffset,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final renderBox =
        widget.searchBoxKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return const SizedBox.shrink();

    final searchBoxPosition = renderBox.localToGlobal(Offset.zero);
    final searchBoxSize = renderBox.size;
    final searchBoxRect = Rect.fromLTWH(
      searchBoxPosition.dx,
      searchBoxPosition.dy,
      searchBoxSize.width,
      searchBoxSize.height,
    );

    final screenSize = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;

    final positionData = OverlayPositioner.calculatePosition(
      targetRect: searchBoxRect,
      overlaySize: Size(
        widget.config.maxWidth ?? searchBoxSize.width,
        widget.config.maxHeight,
      ),
      screenSize: screenSize,
      config: widget.config,
      padding: padding,
    );

    return Stack(
      children: [
        // Barrier
        if (widget.config.barrierDismissible)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onDismiss,
              child: widget.config.barrierColor != null
                  ? FadeTransition(
                      opacity: widget.fadeAnimation,
                      child: Container(color: widget.config.barrierColor),
                    )
                  : const SizedBox.expand(),
            ),
          ),

        // Overlay content
        Positioned(
          left: positionData.offset.dx,
          top: positionData.offset.dy,
          child: FadeTransition(
            opacity: widget.fadeAnimation,
            child: _ThemedOverlayContainer(
              config: widget.config,
              overlayDecoration: widget.overlayDecoration,
              width: positionData.size.width,
              maxHeight: positionData.size.height,
              child: _buildContent(context),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        return BlocBuilder<SmartPaginationCubit<T>, SmartPaginationState<T>>(
          bloc: widget.controller.cubit,
          builder: (context, state) {
            return switch (state) {
              SmartPaginationError<T>(:final error) => _buildError(
                context,
                error,
              ),
              SmartPaginationLoaded<T>(:final items) => _buildResults(
                context,
                items,
              ),
              _ => _buildInitialOrLoading(context),
            };
          },
        );
      },
    );
  }

  Widget _buildInitialOrLoading(BuildContext context) {
    if (widget.loadingBuilder != null) {
      return widget.loadingBuilder!(context);
    }

    final searchTheme = SmartSearchTheme.of(context);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: CircularProgressIndicator.adaptive(
          valueColor: AlwaysStoppedAnimation<Color>(
            searchTheme.loadingIndicatorColor ?? Theme.of(context).primaryColor,
          ),
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, Exception error) {
    if (widget.errorBuilder != null) {
      return widget.errorBuilder!(context, error);
    }

    final searchTheme = SmartSearchTheme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            color: searchTheme.errorIconColor ?? Theme.of(context).colorScheme.error,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            'An error occurred',
            style: TextStyle(
              color: searchTheme.errorTextColor ?? Theme.of(context).colorScheme.error,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => widget.controller.searchNow(),
            style: TextButton.styleFrom(
              foregroundColor: searchTheme.errorButtonColor,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(BuildContext context, List<T> items) {
    if (items.isEmpty) {
      return _buildEmpty(context);
    }

    final focusedIndex = widget.controller.focusedIndex;
    final searchTheme = SmartSearchTheme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.headerBuilder != null) widget.headerBuilder!(context),
        Flexible(
          child: Scrollbar(
            controller: _scrollController,
            thumbVisibility: true,
            thickness: searchTheme.scrollbarThickness ?? 6,
            radius: searchTheme.scrollbarRadius ?? const Radius.circular(3),
            child: ListView.separated(
              controller: _scrollController,
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: items.length,
              separatorBuilder:
                  widget.separatorBuilder ??
                  (context, index) => Divider(
                        height: 1,
                        color: searchTheme.itemDividerColor,
                      ),
              itemBuilder: (context, index) {
                final item = items[index];
                final isFocused = index == focusedIndex;

                return _FocusableItem<T>(
                  item: item,
                  isFocused: isFocused,
                  focusedColor: searchTheme.itemFocusedColor ??
                      Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                  hoverColor: searchTheme.itemHoverColor,
                  focusedDecoration: widget.focusedItemDecoration,
                  onTap: () => widget.onItemSelected(item),
                  onHover: (hovering) {
                    if (hovering) {
                      widget.controller.setFocusedIndex(index);
                    }
                  },
                  child: widget.itemBuilder(context, item),
                );
              },
            ),
          ),
        ),
        if (widget.footerBuilder != null) widget.footerBuilder!(context),
      ],
    );
  }

  Widget _buildEmpty(BuildContext context) {
    if (widget.emptyBuilder != null) {
      return widget.emptyBuilder!(context);
    }

    final searchTheme = SmartSearchTheme.of(context);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off,
              size: 48,
              color: searchTheme.emptyStateIconColor ?? Theme.of(context).disabledColor,
            ),
            const SizedBox(height: 8),
            Text(
              'No results found',
              style: TextStyle(
                color: searchTheme.emptyStateTextColor ?? Theme.of(context).disabledColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Themed container for the overlay dropdown.
class _ThemedOverlayContainer extends StatelessWidget {
  const _ThemedOverlayContainer({
    required this.config,
    required this.width,
    required this.maxHeight,
    required this.child,
    this.overlayDecoration,
  });

  final SmartSearchOverlayConfig config;
  final BoxDecoration? overlayDecoration;
  final double width;
  final double maxHeight;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final searchTheme = SmartSearchTheme.of(context);

    final effectiveBorderRadius = searchTheme.overlayBorderRadius ??
        BorderRadius.circular(config.borderRadius);

    final effectiveElevation = searchTheme.overlayElevation ?? config.elevation;

    return Material(
      elevation: effectiveElevation,
      shadowColor: searchTheme.overlayShadowColor,
      borderRadius: effectiveBorderRadius,
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: width,
        constraints: BoxConstraints(maxHeight: maxHeight),
        decoration: overlayDecoration ??
            BoxDecoration(
              color: searchTheme.overlayBackgroundColor ?? Theme.of(context).cardColor,
              borderRadius: effectiveBorderRadius,
              border: searchTheme.overlayBorderColor != null
                  ? Border.all(color: searchTheme.overlayBorderColor!)
                  : null,
            ),
        child: child,
      ),
    );
  }
}

/// A focusable item widget that shows visual feedback when focused or hovered.
class _FocusableItem<T> extends StatefulWidget {
  const _FocusableItem({
    required this.item,
    required this.isFocused,
    required this.focusedColor,
    required this.onTap,
    required this.onHover,
    required this.child,
    this.hoverColor,
    this.focusedDecoration,
  });

  final T item;
  final bool isFocused;
  final Color focusedColor;
  final Color? hoverColor;
  final BoxDecoration? focusedDecoration;
  final VoidCallback onTap;
  final ValueChanged<bool> onHover;
  final Widget child;

  @override
  State<_FocusableItem<T>> createState() => _FocusableItemState<T>();
}

class _FocusableItemState<T> extends State<_FocusableItem<T>> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final effectiveDecoration = widget.focusedDecoration ??
        BoxDecoration(
          color: widget.isFocused
              ? widget.focusedColor
              : (_isHovering ? widget.hoverColor : null),
        );

    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovering = true);
        widget.onHover(true);
      },
      onExit: (_) {
        setState(() => _isHovering = false);
        widget.onHover(false);
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          decoration: widget.isFocused || _isHovering ? effectiveDecoration : null,
          child: widget.child,
        ),
      ),
    );
  }
}
