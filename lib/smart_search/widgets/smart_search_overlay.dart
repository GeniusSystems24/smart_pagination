part of '../../pagination.dart';

/// A widget that combines SmartSearchBox with an overlay dropdown for results.
///
/// The overlay automatically positions itself in the best available space
/// (top, bottom, left, or right) relative to the search box, unless a
/// specific position is configured.
///
/// ## Generic Types
///
/// - `T`: The data type of items (e.g., Product, User)
/// - `K`: The key type used for identification (e.g., String, int)
///
/// Example:
/// ```dart
/// SmartSearchOverlay<Product, String>(
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
class SmartSearchOverlay<T, K> extends StatefulWidget {
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
    this.searchBoxValidator,
    this.searchBoxInputFormatters,
    this.searchBoxAutovalidateMode,
    this.searchBoxOnChanged,
    this.searchBoxMaxLength,
    this.searchBoxTextInputAction = TextInputAction.search,
    this.searchBoxTextCapitalization = TextCapitalization.none,
    this.searchBoxKeyboardType = TextInputType.text,
  });

  /// The search controller managing the search state.
  final SmartSearchController<T, K> controller;

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

  /// Validator function for form validation.
  final String? Function(String?)? searchBoxValidator;

  /// Input formatters to restrict or format input.
  final List<TextInputFormatter>? searchBoxInputFormatters;

  /// When to validate the input.
  final AutovalidateMode? searchBoxAutovalidateMode;

  /// Called when the text changes.
  final ValueChanged<String>? searchBoxOnChanged;

  /// Maximum length of the input.
  final int? searchBoxMaxLength;

  /// The action button on the keyboard.
  final TextInputAction searchBoxTextInputAction;

  /// Text capitalization behavior.
  final TextCapitalization searchBoxTextCapitalization;

  /// The type of keyboard to display.
  final TextInputType searchBoxKeyboardType;

  @override
  State<SmartSearchOverlay<T, K>> createState() =>
      _SmartSearchOverlayState<T, K>();
}

class _SmartSearchOverlayState<T, K> extends State<SmartSearchOverlay<T, K>>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final LayerLink _layerLink = LayerLink();
  final GlobalKey _searchBoxKey = GlobalKey();

  OverlayEntry? _overlayEntry;
  late AnimationController _animationController;
  late Animation<double> _animation;

  // Position tracking for accurate overlay positioning
  Ticker? _positionTicker;
  Offset? _lastKnownPosition;
  Size? _lastKnownSize;
  final List<ScrollPosition> _trackedScrollPositions = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.overlayConfig.animationDuration,
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: widget.overlayConfig.animationCurve,
    );
    widget.controller.addListener(_onControllerChanged);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _stopPositionTracking();
    widget.controller.removeListener(_onControllerChanged);
    _removeOverlay();
    _detachFromAllScrollPositions();
    _animationController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _attachToAllScrollPositions();
  }

  @override
  void didChangeMetrics() {
    // Screen size or orientation changed - update overlay position
    _scheduleOverlayUpdate();
  }

  /// Attaches to all ancestor scroll positions for comprehensive tracking
  void _attachToAllScrollPositions() {
    if (!widget.overlayConfig.followTargetOnScroll) return;

    _detachFromAllScrollPositions();

    // Find all ancestor Scrollables and attach to their positions
    BuildContext? currentContext = context;
    while (currentContext != null) {
      final scrollable = Scrollable.maybeOf(currentContext);
      if (scrollable != null) {
        final position = scrollable.position;
        if (!_trackedScrollPositions.contains(position)) {
          _trackedScrollPositions.add(position);
          position.addListener(_onScrollPositionChanged);
        }
        // Try to find parent context
        currentContext = scrollable.context;
        // Move up the tree to find more scrollables
        final element = currentContext as Element?;
        if (element != null) {
          Element? parentElement;
          element.visitAncestorElements((ancestor) {
            parentElement = ancestor;
            return false; // Stop at first ancestor
          });
          currentContext = parentElement;
        } else {
          break;
        }
      } else {
        break;
      }
    }
  }

  void _detachFromAllScrollPositions() {
    for (final position in _trackedScrollPositions) {
      position.removeListener(_onScrollPositionChanged);
    }
    _trackedScrollPositions.clear();
  }

  void _onScrollPositionChanged() {
    _scheduleOverlayUpdate();
  }

  /// Starts continuous position tracking using a Ticker for high accuracy
  void _startPositionTracking() {
    if (!widget.overlayConfig.followTargetOnScroll) return;
    if (_positionTicker != null) return;

    _positionTicker = createTicker(_onPositionTick);
    _positionTicker!.start();
  }

  void _stopPositionTracking() {
    _positionTicker?.stop();
    _positionTicker?.dispose();
    _positionTicker = null;
  }

  void _onPositionTick(Duration elapsed) {
    if (_overlayEntry == null || !widget.controller.isOverlayVisible) {
      return;
    }

    // Check if search box position or size has changed
    final renderBox =
        _searchBoxKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.attached) return;

    final currentPosition = renderBox.localToGlobal(Offset.zero);
    final currentSize = renderBox.size;

    // Only update if position or size actually changed
    if (_lastKnownPosition != currentPosition ||
        _lastKnownSize != currentSize) {
      _lastKnownPosition = currentPosition;
      _lastKnownSize = currentSize;
      _overlayEntry!.markNeedsBuild();
    }
  }

  void _scheduleOverlayUpdate() {
    if (_overlayEntry != null && widget.controller.isOverlayVisible) {
      // Use post-frame callback to ensure smooth updates
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_overlayEntry != null && mounted) {
          _overlayEntry!.markNeedsBuild();
        }
      });
    }
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

    // Reset position tracking
    _lastKnownPosition = null;
    _lastKnownSize = null;

    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    _animationController.forward();

    // Start continuous position tracking for high accuracy
    _startPositionTracking();
  }

  void _hideOverlay() {
    if (_overlayEntry == null) return;

    // Stop position tracking
    _stopPositionTracking();

    _animationController.reverse().then((_) {
      _removeOverlay();
    });
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _lastKnownPosition = null;
    _lastKnownSize = null;
  }

  OverlayEntry _createOverlayEntry() {
    return OverlayEntry(
      builder: (context) {
        return _OverlayContent<T, K>(
          layerLink: _layerLink,
          searchBoxKey: _searchBoxKey,
          controller: widget.controller,
          config: widget.overlayConfig,
          animation: _animation,
          animationType: widget.overlayConfig.animationType,
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
    Widget child = CompositedTransformTarget(
      link: _layerLink,
      child: SmartSearchBox<T, K>(
        key: _searchBoxKey,
        controller: widget.controller,
        decoration: widget.searchBoxDecoration,
        style: widget.searchBoxStyle,
        prefixIcon: widget.searchBoxPrefixIcon,
        suffixIcon: widget.searchBoxSuffixIcon,
        showClearButton: widget.showClearButton,
        borderRadius: widget.searchBoxBorderRadius,
        validator: widget.searchBoxValidator,
        inputFormatters: widget.searchBoxInputFormatters,
        autovalidateMode: widget.searchBoxAutovalidateMode,
        onChanged: widget.searchBoxOnChanged,
        maxLength: widget.searchBoxMaxLength,
        textInputAction: widget.searchBoxTextInputAction,
        textCapitalization: widget.searchBoxTextCapitalization,
        keyboardType: widget.searchBoxKeyboardType,
      ),
    );

    // Wrap with NotificationListener to catch scroll events from any ancestor
    if (widget.overlayConfig.followTargetOnScroll) {
      child = NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          // Update overlay position on any scroll event
          _scheduleOverlayUpdate();
          return false; // Don't stop notification propagation
        },
        child: child,
      );
    }

    return child;
  }
}

class _OverlayContent<T, K> extends StatefulWidget {
  const _OverlayContent({
    required this.layerLink,
    required this.searchBoxKey,
    required this.controller,
    required this.config,
    required this.animation,
    required this.animationType,
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
  final SmartSearchController<T, K> controller;
  final SmartSearchOverlayConfig config;
  final Animation<double> animation;
  final OverlayAnimationType animationType;
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
  State<_OverlayContent<T, K>> createState() => _OverlayContentState<T, K>();
}

class _OverlayContentState<T, K> extends State<_OverlayContent<T, K>> {
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

    final overlayChild = _ThemedOverlayContainer(
      config: widget.config,
      overlayDecoration: widget.overlayDecoration,
      width: positionData.size.width,
      maxHeight: positionData.size.height,
      child: _buildContent(context),
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
                      opacity: widget.animation,
                      child: Container(color: widget.config.barrierColor),
                    )
                  : const SizedBox.expand(),
            ),
          ),

        // Overlay content
        Positioned(
          left: positionData.offset.dx,
          top: positionData.offset.dy,
          child: _buildAnimatedOverlay(overlayChild),
        ),
      ],
    );
  }

  Widget _buildAnimatedOverlay(Widget child) {
    switch (widget.animationType) {
      case OverlayAnimationType.fade:
        return FadeTransition(
          opacity: widget.animation,
          child: child,
        );

      case OverlayAnimationType.scale:
        return ScaleTransition(
          scale: widget.animation,
          child: child,
        );

      case OverlayAnimationType.fadeScale:
        return FadeTransition(
          opacity: widget.animation,
          child: ScaleTransition(
            scale: widget.animation,
            child: child,
          ),
        );

      case OverlayAnimationType.slideDown:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -0.3),
            end: Offset.zero,
          ).animate(widget.animation),
          child: FadeTransition(
            opacity: widget.animation,
            child: child,
          ),
        );

      case OverlayAnimationType.slideUp:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.3),
            end: Offset.zero,
          ).animate(widget.animation),
          child: FadeTransition(
            opacity: widget.animation,
            child: child,
          ),
        );

      case OverlayAnimationType.slideLeft:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.3, 0),
            end: Offset.zero,
          ).animate(widget.animation),
          child: FadeTransition(
            opacity: widget.animation,
            child: child,
          ),
        );

      case OverlayAnimationType.slideRight:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(-0.3, 0),
            end: Offset.zero,
          ).animate(widget.animation),
          child: FadeTransition(
            opacity: widget.animation,
            child: child,
          ),
        );

      case OverlayAnimationType.bounceScale:
        return ScaleTransition(
          scale: CurvedAnimation(
            parent: widget.animation,
            curve: Curves.elasticOut,
          ),
          child: FadeTransition(
            opacity: widget.animation,
            child: child,
          ),
        );

      case OverlayAnimationType.elasticScale:
        return ScaleTransition(
          scale: CurvedAnimation(
            parent: widget.animation,
            curve: Curves.easeOutBack,
          ),
          child: FadeTransition(
            opacity: widget.animation,
            child: child,
          ),
        );

      case OverlayAnimationType.flipX:
        return AnimatedBuilder(
          animation: widget.animation,
          builder: (context, child) {
            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateX((1 - widget.animation.value) * 1.5708),
              child: Opacity(
                opacity: widget.animation.value,
                child: child,
              ),
            );
          },
          child: child,
        );

      case OverlayAnimationType.flipY:
        return AnimatedBuilder(
          animation: widget.animation,
          builder: (context, child) {
            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY((1 - widget.animation.value) * 1.5708),
              child: Opacity(
                opacity: widget.animation.value,
                child: child,
              ),
            );
          },
          child: child,
        );

      case OverlayAnimationType.zoomIn:
        return AnimatedBuilder(
          animation: widget.animation,
          builder: (context, child) {
            final scale = 0.5 + (widget.animation.value * 0.5);
            return Transform.scale(
              scale: scale,
              child: Opacity(
                opacity: widget.animation.value,
                child: child,
              ),
            );
          },
          child: child,
        );

      case OverlayAnimationType.none:
        return child;
    }
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
