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

class _OverlayContent<T> extends StatelessWidget {
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

  @override
  Widget build(BuildContext context) {
    final renderBox =
        searchBoxKey.currentContext?.findRenderObject() as RenderBox?;
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
        config.maxWidth ?? searchBoxSize.width,
        config.maxHeight,
      ),
      screenSize: screenSize,
      config: config,
      padding: padding,
    );

    return Stack(
      children: [
        // Barrier
        if (config.barrierDismissible)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onDismiss,
              child: config.barrierColor != null
                  ? FadeTransition(
                      opacity: fadeAnimation,
                      child: Container(color: config.barrierColor),
                    )
                  : const SizedBox.expand(),
            ),
          ),

        // Overlay content
        Positioned(
          left: positionData.offset.dx,
          top: positionData.offset.dy,
          child: FadeTransition(
            opacity: fadeAnimation,
            child: Material(
              elevation: config.elevation,
              borderRadius: BorderRadius.circular(config.borderRadius),
              clipBehavior: Clip.antiAlias,
              child: Container(
                width: positionData.size.width,
                constraints: BoxConstraints(
                  maxHeight: positionData.size.height,
                ),
                decoration: overlayDecoration ??
                    BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(config.borderRadius),
                    ),
                child: _buildContent(context),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    return BlocBuilder<SmartPaginationCubit<T>, SmartPaginationState<T>>(
      bloc: controller.cubit,
      builder: (context, state) {
        return switch (state) {
          SmartPaginationError<T>(:final error) => _buildError(context, error),
          SmartPaginationLoaded<T>(:final items) => _buildResults(context, items),
          _ => _buildInitialOrLoading(context),
        };
      },
    );
  }

  Widget _buildInitialOrLoading(BuildContext context) {
    if (loadingBuilder != null) {
      return loadingBuilder!(context);
    }

    return const Padding(
      padding: EdgeInsets.all(24),
      child: Center(
        child: CircularProgressIndicator.adaptive(),
      ),
    );
  }

  Widget _buildError(BuildContext context, Exception error) {
    if (errorBuilder != null) {
      return errorBuilder!(context, error);
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            color: Theme.of(context).colorScheme.error,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            'An error occurred',
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => controller.searchNow(),
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

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (headerBuilder != null) headerBuilder!(context),
        Flexible(
          child: ListView.separated(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            itemCount: items.length,
            separatorBuilder: separatorBuilder ??
                (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = items[index];
              return InkWell(
                onTap: () => onItemSelected(item),
                child: itemBuilder(context, item),
              );
            },
          ),
        ),
        if (footerBuilder != null) footerBuilder!(context),
      ],
    );
  }

  Widget _buildEmpty(BuildContext context) {
    if (emptyBuilder != null) {
      return emptyBuilder!(context);
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off,
              size: 48,
              color: Theme.of(context).disabledColor,
            ),
            const SizedBox(height: 8),
            Text(
              'No results found',
              style: TextStyle(
                color: Theme.of(context).disabledColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
