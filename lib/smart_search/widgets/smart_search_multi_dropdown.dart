part of '../../pagination.dart';

/// A widget that provides multi-selection search functionality with a dropdown.
///
/// This widget allows users to search and select multiple items. The selected
/// items are displayed below the search box with individual remove buttons.
///
/// ## Generic Types
///
/// - `T`: The data type of items (e.g., Product, User)
/// - `K`: The key type used for identification (e.g., String, int)
///
/// ## Key-based Selection
///
/// When using key-based selection, you can:
/// - Set initial selections by keys even before data loads
/// - Compare items by key instead of object equality
/// - Get notified of selected keys in addition to items
///
/// Example with key-based selection:
/// ```dart
/// SmartSearchMultiDropdown<Product, String>.withProvider(
///   request: PaginationRequest(page: 1, pageSize: 20),
///   provider: PaginationProvider.future((request) async {
///     return await api.searchProducts(request.searchQuery ?? '');
///   }),
///   searchRequestBuilder: (query) => PaginationRequest(...),
///   itemBuilder: (context, product) => ListTile(title: Text(product.name)),
///   keyExtractor: (product) => product.sku,
///   selectedKeys: ['SKU-001', 'SKU-002', 'SKU-003'],
///   selectedKeyLabelBuilder: (key) => 'Product: $key',
///   onSelected: (products, keys) => print('Selected ${products.length} items with keys: $keys'),
/// )
/// ```
///
/// Example with showSelected:
/// ```dart
/// SmartSearchMultiDropdown<Product, String>.withProvider(
///   // ... other properties
///   showSelected: true,
///   selectedItemBuilder: (context, product, onRemove) => Chip(
///     label: Text(product.name),
///     onDeleted: onRemove,
///   ),
/// )
/// ```
class SmartSearchMultiDropdown<T, K> extends StatefulWidget {
  /// Creates a multi-selection search dropdown with an internal cubit.
  const SmartSearchMultiDropdown.withProvider({
    super.key,
    required PaginationRequest request,
    required PaginationProvider<T> provider,
    required this.searchRequestBuilder,
    required this.itemBuilder,
    this.onSelected,
    this.displayMode = SearchDisplayMode.overlay,
    this.searchConfig = const SmartSearchConfig(),
    this.overlayConfig = const SmartSearchOverlayConfig(),
    this.bottomSheetConfig = const SmartSearchBottomSheetConfig(),
    this.decoration,
    this.style,
    this.prefixIcon,
    this.suffixIcon,
    this.showClearButton = true,
    this.borderRadius,
    this.loadingBuilder,
    this.emptyBuilder,
    this.errorBuilder,
    this.separatorBuilder,
    this.headerBuilder,
    this.footerBuilder,
    this.overlayDecoration,
    this.showSelected = true,
    this.selectedItemBuilder,
    this.selectedKeyBuilder,
    this.initialSelectedValues,
    this.selectedKeys,
    this.keyExtractor,
    this.selectedKeyLabelBuilder,
    this.maxSelections,
    this.validator,
    this.textInputAction = TextInputAction.search,
    this.inputFormatters,
    this.autovalidateMode,
    this.onChanged,
    this.maxLength,
    this.textCapitalization = TextCapitalization.none,
    this.keyboardType = TextInputType.text,
    this.selectedItemsWrap = true,
    this.selectedItemsSpacing = 8.0,
    this.selectedItemsRunSpacing = 8.0,
    this.selectedItemsPadding = const EdgeInsets.only(top: 12),
    this.hintText,
    this.onMaxSelectionsReached,
    ListBuilder<T>? listBuilder,
    OnInsertionCallback<T>? onInsertionCallback,
    int maxPagesInMemory = 5,
    Logger? logger,
    RetryConfig? retryConfig,
    Duration? dataAge,
    SortOrderCollection<T>? orders,
  })  : _cubit = null,
        _request = request,
        _provider = provider,
        _listBuilder = listBuilder,
        _onInsertionCallback = onInsertionCallback,
        _maxPagesInMemory = maxPagesInMemory,
        _logger = logger,
        _retryConfig = retryConfig,
        _dataAge = dataAge,
        _orders = orders;

  /// Creates a multi-selection search dropdown with an external cubit.
  const SmartSearchMultiDropdown.withCubit({
    super.key,
    required SmartPaginationCubit<T> cubit,
    required this.searchRequestBuilder,
    required this.itemBuilder,
    this.onSelected,
    this.displayMode = SearchDisplayMode.overlay,
    this.searchConfig = const SmartSearchConfig(),
    this.overlayConfig = const SmartSearchOverlayConfig(),
    this.bottomSheetConfig = const SmartSearchBottomSheetConfig(),
    this.decoration,
    this.style,
    this.prefixIcon,
    this.suffixIcon,
    this.showClearButton = true,
    this.borderRadius,
    this.loadingBuilder,
    this.emptyBuilder,
    this.errorBuilder,
    this.separatorBuilder,
    this.headerBuilder,
    this.footerBuilder,
    this.overlayDecoration,
    this.showSelected = true,
    this.selectedItemBuilder,
    this.selectedKeyBuilder,
    this.initialSelectedValues,
    this.selectedKeys,
    this.keyExtractor,
    this.selectedKeyLabelBuilder,
    this.maxSelections,
    this.validator,
    this.textInputAction = TextInputAction.search,
    this.inputFormatters,
    this.autovalidateMode,
    this.onChanged,
    this.maxLength,
    this.textCapitalization = TextCapitalization.none,
    this.keyboardType = TextInputType.text,
    this.selectedItemsWrap = true,
    this.selectedItemsSpacing = 8.0,
    this.selectedItemsRunSpacing = 8.0,
    this.selectedItemsPadding = const EdgeInsets.only(top: 12),
    this.hintText,
    this.onMaxSelectionsReached,
  })  : _cubit = cubit,
        _request = null,
        _provider = null,
        _listBuilder = null,
        _onInsertionCallback = null,
        _maxPagesInMemory = 5,
        _logger = null,
        _retryConfig = null,
        _dataAge = null,
        _orders = null;

  final SmartPaginationCubit<T>? _cubit;
  final PaginationRequest? _request;
  final PaginationProvider<T>? _provider;
  final ListBuilder<T>? _listBuilder;
  final OnInsertionCallback<T>? _onInsertionCallback;
  final int _maxPagesInMemory;
  final Logger? _logger;
  final RetryConfig? _retryConfig;
  final Duration? _dataAge;
  final SortOrderCollection<T>? _orders;

  /// Builds the pagination request for a search query.
  final PaginationRequest Function(String query) searchRequestBuilder;

  /// Builder for each result item.
  final Widget Function(BuildContext context, T item) itemBuilder;

  /// Called when the selection changes with both items and keys.
  /// Requires [keyExtractor] to be provided for keys.
  final void Function(List<T> items, List<K> keys)? onSelected;

  /// Display mode: overlay dropdown or bottom sheet.
  final SearchDisplayMode displayMode;

  /// Configuration for search behavior.
  final SmartSearchConfig searchConfig;

  /// Configuration for the overlay appearance.
  final SmartSearchOverlayConfig overlayConfig;

  /// Configuration for the bottom sheet appearance.
  final SmartSearchBottomSheetConfig bottomSheetConfig;

  /// Decoration for the search text field.
  final InputDecoration? decoration;

  /// Text style for the search input.
  final TextStyle? style;

  /// Prefix icon for the search box.
  final Widget? prefixIcon;

  /// Suffix icon for the search box.
  final Widget? suffixIcon;

  /// Whether to show a clear button.
  final bool showClearButton;

  /// Border radius for the search box.
  final BorderRadius? borderRadius;

  /// Builder for the loading state.
  final WidgetBuilder? loadingBuilder;

  /// Builder for the empty state.
  final WidgetBuilder? emptyBuilder;

  /// Builder for the error state.
  final Widget Function(BuildContext context, Exception error)? errorBuilder;

  /// Builder for separators between items.
  final IndexedWidgetBuilder? separatorBuilder;

  /// Builder for a header in the dropdown.
  final WidgetBuilder? headerBuilder;

  /// Builder for a footer in the dropdown.
  final WidgetBuilder? footerBuilder;

  /// Decoration for the overlay container.
  final BoxDecoration? overlayDecoration;

  /// Whether to show selected items below the search box.
  final bool showSelected;

  /// Builder for displaying selected items.
  ///
  /// The builder receives:
  /// - `context`: The build context
  /// - `item`: The selected item
  /// - `onRemove`: Callback to remove this item from selection
  final Widget Function(BuildContext context, T item, VoidCallback onRemove)?
      selectedItemBuilder;

  /// The initially selected values.
  final List<T>? initialSelectedValues;

  /// The initially selected keys.
  ///
  /// When provided with [keyExtractor], the widget will try to find and select
  /// items with these keys. If items haven't been loaded yet, they will be
  /// selected when the data loads.
  final List<K>? selectedKeys;

  /// Function to extract the key from an item.
  ///
  /// When provided, selections are compared by key instead of object equality.
  /// This enables key-based initial selection and comparison.
  final K Function(T item)? keyExtractor;

  /// Function to build a display label for a key when the item is not yet loaded.
  ///
  /// This is used when [selectedKeys] is provided but items haven't been
  /// loaded yet. If not provided, the key's toString() will be used.
  final String Function(K key)? selectedKeyLabelBuilder;

  /// Builder for displaying a selected key when the item is not yet loaded.
  ///
  /// If not provided, a default display using [selectedKeyLabelBuilder] or
  /// key.toString() will be used.
  final Widget Function(BuildContext context, K key, VoidCallback onRemove)?
      selectedKeyBuilder;

  /// Maximum number of items that can be selected.
  final int? maxSelections;

  /// Validator function for form validation.
  final String? Function(String?)? validator;

  /// The action button on the keyboard.
  final TextInputAction textInputAction;

  /// Input formatters to restrict or format input.
  final List<TextInputFormatter>? inputFormatters;

  /// When to validate the input.
  final AutovalidateMode? autovalidateMode;

  /// Called when the text changes.
  final ValueChanged<String>? onChanged;

  /// Maximum length of the input.
  final int? maxLength;

  /// Text capitalization behavior.
  final TextCapitalization textCapitalization;

  /// The type of keyboard to display.
  final TextInputType keyboardType;

  /// Whether to wrap selected items or use horizontal scroll.
  final bool selectedItemsWrap;

  /// Spacing between selected items horizontally.
  final double selectedItemsSpacing;

  /// Spacing between selected items vertically (when wrapped).
  final double selectedItemsRunSpacing;

  /// Padding around the selected items container.
  final EdgeInsets selectedItemsPadding;

  /// Hint text for the search box or trigger button.
  final String? hintText;

  /// Called when maximum selections limit is reached.
  final VoidCallback? onMaxSelectionsReached;

  @override
  State<SmartSearchMultiDropdown<T, K>> createState() =>
      _SmartSearchMultiDropdownState<T, K>();
}

class _SmartSearchMultiDropdownState<T, K>
    extends State<SmartSearchMultiDropdown<T, K>> {
  SmartPaginationCubit<T>? _internalCubit;
  SmartSearchMultiController<T, K>? _searchController;

  SmartPaginationCubit<T> get _cubit => widget._cubit ?? _internalCubit!;

  @override
  void initState() {
    super.initState();
    _initializeCubit();
    _initializeController();
  }

  void _initializeCubit() {
    if (widget._cubit == null) {
      _internalCubit = SmartPaginationCubit<T>(
        request: widget._request!,
        provider: widget._provider!,
        listBuilder: widget._listBuilder,
        onInsertionCallback: widget._onInsertionCallback,
        maxPagesInMemory: widget._maxPagesInMemory,
        logger: widget._logger,
        retryConfig: widget._retryConfig,
        dataAge: widget._dataAge,
        orders: widget._orders,
      );
    }
  }

  void _initializeController() {
    _searchController = SmartSearchMultiController<T, K>(
      cubit: _cubit,
      searchRequestBuilder: widget.searchRequestBuilder,
      config: widget.searchConfig,
      onSelected: widget.onSelected,
      initialSelectedValues: widget.initialSelectedValues,
      selectedKeys: widget.selectedKeys,
      keyExtractor: widget.keyExtractor,
      selectedKeyLabelBuilder: widget.selectedKeyLabelBuilder,
      maxSelections: widget.maxSelections,
    );
  }

  @override
  void dispose() {
    _searchController?.dispose();
    _internalCubit?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _searchController!,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Search input based on display mode
            if (widget.displayMode == SearchDisplayMode.overlay)
              _SmartSearchMultiOverlay<T, K>(
                controller: _searchController!,
                itemBuilder: _buildResultItem,
                onItemSelected: (item) {
                  _searchController!.toggleItemSelection(item);
                  if (widget.maxSelections != null &&
                      _searchController!.selectedItems.length >= widget.maxSelections!) {
                    widget.onMaxSelectionsReached?.call();
                  }
                },
                searchBoxDecoration: widget.decoration,
                overlayConfig: widget.overlayConfig,
                loadingBuilder: widget.loadingBuilder,
                emptyBuilder: widget.emptyBuilder,
                errorBuilder: widget.errorBuilder,
                separatorBuilder: widget.separatorBuilder,
                headerBuilder: widget.headerBuilder,
                footerBuilder: widget.footerBuilder,
                overlayDecoration: widget.overlayDecoration,
                searchBoxStyle: widget.style,
                searchBoxPrefixIcon: widget.prefixIcon,
                searchBoxSuffixIcon: widget.suffixIcon,
                showClearButton: widget.showClearButton,
                searchBoxBorderRadius: widget.borderRadius,
                searchBoxValidator: widget.validator,
                searchBoxInputFormatters: widget.inputFormatters,
                searchBoxAutovalidateMode: widget.autovalidateMode,
                searchBoxOnChanged: widget.onChanged,
                searchBoxMaxLength: widget.maxLength,
                searchBoxTextInputAction: widget.textInputAction,
                searchBoxTextCapitalization: widget.textCapitalization,
                searchBoxKeyboardType: widget.keyboardType,
              )
            else
              _buildBottomSheetTrigger(context),

            // Selected items (shown below search box)
            if (widget.showSelected &&
                (_searchController!.hasSelectedItems ||
                    _searchController!.hasPendingKeys))
              _buildSelectedItems(context),
          ],
        );
      },
    );
  }

  Widget _buildBottomSheetTrigger(BuildContext context) {
    final searchTheme = SmartSearchTheme.of(context);
    final effectiveBorderRadius =
        widget.borderRadius ?? searchTheme.searchBoxBorderRadius ?? BorderRadius.circular(12);

    final selectedCount = _searchController!.selectedItems.length +
        _searchController!.pendingKeys.length;

    return InkWell(
      onTap: () => _showBottomSheet(context),
      borderRadius: effectiveBorderRadius,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: searchTheme.searchBoxBackgroundColor,
          borderRadius: effectiveBorderRadius,
          border: Border.all(
            color: searchTheme.searchBoxBorderColor ?? Colors.grey[300]!,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.search,
              color: searchTheme.searchBoxIconColor ?? Colors.grey[600],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                selectedCount > 0
                    ? '$selectedCount selected'
                    : widget.hintText ?? 'Tap to search...',
                style: TextStyle(
                  color: selectedCount > 0
                      ? searchTheme.searchBoxTextColor
                      : searchTheme.searchBoxHintColor ?? Colors.grey[500],
                  fontSize: 16,
                ),
              ),
            ),
            Icon(
              Icons.arrow_drop_down,
              color: searchTheme.searchBoxIconColor ?? Colors.grey[600],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showBottomSheet(BuildContext context) async {
    final config = widget.bottomSheetConfig;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: config.isScrollControlled,
      enableDrag: config.enableDrag,
      useSafeArea: config.useSafeArea,
      backgroundColor: config.backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
      barrierColor: config.barrierColor,
      showDragHandle: config.showDragHandle,
      shape: RoundedRectangleBorder(borderRadius: config.borderRadius),
      builder: (bottomSheetContext) {
        return _SmartSearchBottomSheetContent<T, K>(
          controller: _searchController!,
          cubit: _cubit,
          config: config,
          itemBuilder: widget.itemBuilder,
          loadingBuilder: widget.loadingBuilder,
          emptyBuilder: widget.emptyBuilder,
          errorBuilder: widget.errorBuilder,
          separatorBuilder: widget.separatorBuilder,
          headerBuilder: widget.headerBuilder,
          footerBuilder: widget.footerBuilder,
          decoration: widget.decoration,
          style: widget.style,
          prefixIcon: widget.prefixIcon,
          showClearButton: widget.showClearButton,
          borderRadius: widget.borderRadius,
          hintText: widget.hintText,
          maxSelections: widget.maxSelections,
          onMaxSelectionsReached: widget.onMaxSelectionsReached,
          heightFactor: config.heightFactor,
        );
      },
    );
  }

  Widget _buildResultItem(BuildContext context, T item) {
    final isSelected = _searchController!.isItemSelected(item);
    final searchTheme = SmartSearchTheme.of(context);

    return Stack(
      children: [
        widget.itemBuilder(context, item),
        if (isSelected)
          Positioned(
            right: 8,
            top: 0,
            bottom: 0,
            child: Center(
              child: Icon(
                Icons.check_circle,
                color: searchTheme.loadingIndicatorColor ??
                    Theme.of(context).colorScheme.primary,
                size: 20,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSelectedItems(BuildContext context) {
    final searchTheme = SmartSearchTheme.of(context);

    // Build list of widgets: selected items + pending keys
    final List<Widget> children = [];

    // Add selected items
    for (final item in _searchController!.selectedItems) {
      children.add(_buildSelectedItemChip(context, item, searchTheme));
    }

    // Add pending keys (keys that haven't been resolved to items yet)
    for (final key in _searchController!.pendingKeys) {
      children.add(_buildPendingKeyChip(context, key, searchTheme));
    }

    if (children.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: widget.selectedItemsPadding,
      child: widget.selectedItemsWrap
          ? Wrap(
              spacing: widget.selectedItemsSpacing,
              runSpacing: widget.selectedItemsRunSpacing,
              children: children,
            )
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: children.map((child) {
                  return Padding(
                    padding: EdgeInsets.only(right: widget.selectedItemsSpacing),
                    child: child,
                  );
                }).toList(),
              ),
            ),
    );
  }

  Widget _buildPendingKeyChip(
    BuildContext context,
    K key,
    SmartSearchTheme searchTheme,
  ) {
    if (widget.selectedKeyBuilder != null) {
      return widget.selectedKeyBuilder!(
        context,
        key,
        () => _searchController!.removeByKey(key),
      );
    }

    // Default pending key chip display
    final label = _searchController!.getKeyLabel(key);
    return _DefaultPendingKeyChip<K>(
      keyLabel: label,
      onRemove: () => _searchController!.removeByKey(key),
      backgroundColor: searchTheme.itemSelectedColor ??
          Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5),
      iconColor: searchTheme.searchBoxIconColor,
      borderRadius: widget.borderRadius ?? searchTheme.searchBoxBorderRadius,
    );
  }

  Widget _buildSelectedItemChip(
    BuildContext context,
    T item,
    SmartSearchTheme searchTheme,
  ) {
    if (widget.selectedItemBuilder != null) {
      return widget.selectedItemBuilder!(
        context,
        item,
        () => _searchController!.removeItem(item),
      );
    }

    // Default chip display
    return _DefaultMultiSelectedItemChip<T>(
      item: item,
      itemBuilder: widget.itemBuilder,
      onRemove: () => _searchController!.removeItem(item),
      backgroundColor: searchTheme.itemSelectedColor ??
          Theme.of(context).colorScheme.primaryContainer,
      iconColor: searchTheme.searchBoxIconColor,
      borderRadius: widget.borderRadius ?? searchTheme.searchBoxBorderRadius,
    );
  }
}

/// Default chip widget for displaying selected items.
class _DefaultMultiSelectedItemChip<T> extends StatelessWidget {
  const _DefaultMultiSelectedItemChip({
    required this.item,
    required this.itemBuilder,
    required this.onRemove,
    this.backgroundColor,
    this.iconColor,
    this.borderRadius,
  });

  final T item;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final VoidCallback onRemove;
  final Color? backgroundColor;
  final Color? iconColor;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? Theme.of(context).colorScheme.primaryContainer,
        borderRadius: borderRadius ?? BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: DefaultTextStyle(
                style: Theme.of(context).textTheme.bodyMedium!,
                child: itemBuilder(context, item),
              ),
            ),
          ),
          InkWell(
            onTap: onRemove,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.close,
                size: 18,
                color: iconColor ?? Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}

/// Overlay widget for multi-selection search.
class _SmartSearchMultiOverlay<T, K> extends StatefulWidget {
  const _SmartSearchMultiOverlay({
    required this.controller,
    required this.itemBuilder,
    required this.onItemSelected,
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

  final SmartSearchMultiController<T, K> controller;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final ValueChanged<T> onItemSelected;
  final InputDecoration? searchBoxDecoration;
  final SmartSearchOverlayConfig overlayConfig;
  final WidgetBuilder? loadingBuilder;
  final WidgetBuilder? emptyBuilder;
  final Widget Function(BuildContext context, Exception error)? errorBuilder;
  final IndexedWidgetBuilder? separatorBuilder;
  final WidgetBuilder? headerBuilder;
  final WidgetBuilder? footerBuilder;
  final BoxDecoration? overlayDecoration;
  final TextStyle? searchBoxStyle;
  final Widget? searchBoxPrefixIcon;
  final Widget? searchBoxSuffixIcon;
  final bool showClearButton;
  final BorderRadius? searchBoxBorderRadius;
  final String? Function(String?)? searchBoxValidator;
  final List<TextInputFormatter>? searchBoxInputFormatters;
  final AutovalidateMode? searchBoxAutovalidateMode;
  final ValueChanged<String>? searchBoxOnChanged;
  final int? searchBoxMaxLength;
  final TextInputAction searchBoxTextInputAction;
  final TextCapitalization searchBoxTextCapitalization;
  final TextInputType searchBoxKeyboardType;

  @override
  State<_SmartSearchMultiOverlay<T, K>> createState() =>
      _SmartSearchMultiOverlayState<T, K>();
}

class _SmartSearchMultiOverlayState<T, K>
    extends State<_SmartSearchMultiOverlay<T, K>>
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
        return _MultiOverlayContent<T, K>(
          layerLink: _layerLink,
          searchBoxKey: _searchBoxKey,
          controller: widget.controller,
          config: widget.overlayConfig,
          fadeAnimation: _fadeAnimation,
          itemBuilder: widget.itemBuilder,
          onItemSelected: widget.onItemSelected,
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

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: _SmartSearchMultiBox<T, K>(
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
  }
}

/// Search box widget for multi-selection.
class _SmartSearchMultiBox<T, K> extends StatelessWidget {
  const _SmartSearchMultiBox({
    super.key,
    required this.controller,
    this.decoration,
    this.style,
    this.prefixIcon,
    this.suffixIcon,
    this.showClearButton = true,
    this.borderRadius,
    this.validator,
    this.inputFormatters,
    this.autovalidateMode,
    this.onChanged,
    this.maxLength,
    this.textInputAction = TextInputAction.search,
    this.textCapitalization = TextCapitalization.none,
    this.keyboardType = TextInputType.text,
  });

  final SmartSearchMultiController<T, K> controller;
  final InputDecoration? decoration;
  final TextStyle? style;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool showClearButton;
  final BorderRadius? borderRadius;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;
  final AutovalidateMode? autovalidateMode;
  final ValueChanged<String>? onChanged;
  final int? maxLength;
  final TextInputAction textInputAction;
  final TextCapitalization textCapitalization;
  final TextInputType keyboardType;

  @override
  Widget build(BuildContext context) {
    final searchTheme = SmartSearchTheme.of(context);

    final effectiveBorderRadius =
        borderRadius ?? searchTheme.searchBoxBorderRadius ?? BorderRadius.circular(12);

    final effectiveDecoration = decoration ??
        InputDecoration(
          hintText: 'Search...',
          hintStyle: TextStyle(color: searchTheme.searchBoxHintColor),
          filled: true,
          fillColor: searchTheme.searchBoxBackgroundColor,
          prefixIcon: prefixIcon ??
              Icon(Icons.search, color: searchTheme.searchBoxIconColor),
          suffixIcon: _buildSuffixIcon(context, searchTheme),
          border: OutlineInputBorder(
            borderRadius: effectiveBorderRadius,
            borderSide: BorderSide(
              color: searchTheme.searchBoxBorderColor ?? Colors.grey[300]!,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: effectiveBorderRadius,
            borderSide: BorderSide(
              color: searchTheme.searchBoxBorderColor ?? Colors.grey[300]!,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: effectiveBorderRadius,
            borderSide: BorderSide(
              color: searchTheme.searchBoxFocusedBorderColor ??
                  Theme.of(context).colorScheme.primary,
              width: 2,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        );

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return Focus(
          skipTraversal: true,
          onKeyEvent: (node, event) {
            if (controller.handleKeyEvent(event)) {
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: validator != null
              ? TextFormField(
                  controller: controller.textController,
                  focusNode: controller.focusNode,
                  decoration: effectiveDecoration,
                  style: style ?? TextStyle(color: searchTheme.searchBoxTextColor),
                  cursorColor: searchTheme.searchBoxCursorColor,
                  textInputAction: textInputAction,
                  textCapitalization: textCapitalization,
                  keyboardType: keyboardType,
                  inputFormatters: inputFormatters,
                  maxLength: maxLength,
                  validator: validator,
                  autovalidateMode: autovalidateMode,
                  onChanged: onChanged,
                )
              : TextField(
                  controller: controller.textController,
                  focusNode: controller.focusNode,
                  decoration: effectiveDecoration,
                  style: style ?? TextStyle(color: searchTheme.searchBoxTextColor),
                  cursorColor: searchTheme.searchBoxCursorColor,
                  textInputAction: textInputAction,
                  textCapitalization: textCapitalization,
                  keyboardType: keyboardType,
                  inputFormatters: inputFormatters,
                  maxLength: maxLength,
                  onChanged: onChanged,
                ),
        );
      },
    );
  }

  Widget? _buildSuffixIcon(BuildContext context, SmartSearchTheme searchTheme) {
    if (suffixIcon != null) return suffixIcon;

    if (showClearButton && controller.hasText) {
      return IconButton(
        icon: Icon(Icons.clear, color: searchTheme.searchBoxIconColor),
        onPressed: controller.clearSearch,
      );
    }

    return null;
  }
}

/// Overlay content widget for multi-selection.
class _MultiOverlayContent<T, K> extends StatefulWidget {
  const _MultiOverlayContent({
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
  final SmartSearchMultiController<T, K> controller;
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
  State<_MultiOverlayContent<T, K>> createState() =>
      _MultiOverlayContentState<T, K>();
}

class _MultiOverlayContentState<T, K> extends State<_MultiOverlayContent<T, K>> {
  final ScrollController _scrollController = ScrollController();
  static const double _itemHeight = 56.0;

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
    if (widget.controller.hasItemFocus) {
      _scrollToFocusedItem();
    }
  }

  void _scrollToFocusedItem() {
    final focusedIndex = widget.controller.focusedIndex;
    if (focusedIndex < 0 || !_scrollController.hasClients) return;

    const padding = 8.0;
    final targetOffset = focusedIndex * _itemHeight;
    final viewportHeight = _scrollController.position.viewportDimension;
    final currentOffset = _scrollController.offset;
    final maxOffset = _scrollController.position.maxScrollExtent;

    final itemTop = targetOffset;
    final itemBottom = targetOffset + _itemHeight;
    final viewTop = currentOffset + padding;
    final viewBottom = currentOffset + viewportHeight - padding;

    if (itemTop >= viewTop && itemBottom <= viewBottom) {
      return;
    }

    double newOffset;
    if (itemTop < viewTop) {
      newOffset = targetOffset - padding;
    } else {
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

    final searchTheme = SmartSearchTheme.of(context);

    return Stack(
      children: [
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
        Positioned(
          left: positionData.offset.dx,
          top: positionData.offset.dy,
          child: FadeTransition(
            opacity: widget.fadeAnimation,
            child: _ThemedMultiOverlayContainer(
              config: widget.config,
              overlayDecoration: widget.overlayDecoration,
              width: positionData.size.width,
              maxHeight: positionData.size.height,
              child: _buildContent(context, searchTheme),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context, SmartSearchTheme searchTheme) {
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
                  searchTheme,
                ),
              SmartPaginationLoaded<T>(:final items) => _buildResults(
                  context,
                  items,
                  searchTheme,
                ),
              _ => _buildInitialOrLoading(context, searchTheme),
            };
          },
        );
      },
    );
  }

  Widget _buildInitialOrLoading(BuildContext context, SmartSearchTheme searchTheme) {
    if (widget.loadingBuilder != null) {
      return widget.loadingBuilder!(context);
    }

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

  Widget _buildError(
    BuildContext context,
    Exception error,
    SmartSearchTheme searchTheme,
  ) {
    if (widget.errorBuilder != null) {
      return widget.errorBuilder!(context, error);
    }

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

  Widget _buildResults(
    BuildContext context,
    List<T> items,
    SmartSearchTheme searchTheme,
  ) {
    if (items.isEmpty) {
      return _buildEmpty(context, searchTheme);
    }

    final focusedIndex = widget.controller.focusedIndex;

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
              separatorBuilder: widget.separatorBuilder ??
                  (context, index) => Divider(
                        height: 1,
                        color: searchTheme.itemDividerColor,
                      ),
              itemBuilder: (context, index) {
                final item = items[index];
                final isFocused = index == focusedIndex;
                final isSelected = widget.controller.isItemSelected(item);

                return _FocusableMultiItem<T>(
                  item: item,
                  isFocused: isFocused,
                  isSelected: isSelected,
                  focusedColor: searchTheme.itemFocusedColor ??
                      Theme.of(context)
                          .colorScheme
                          .primaryContainer
                          .withValues(alpha: 0.3),
                  selectedColor: searchTheme.itemSelectedColor ??
                      Theme.of(context)
                          .colorScheme
                          .primaryContainer
                          .withValues(alpha: 0.5),
                  hoverColor: searchTheme.itemHoverColor,
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

  Widget _buildEmpty(BuildContext context, SmartSearchTheme searchTheme) {
    if (widget.emptyBuilder != null) {
      return widget.emptyBuilder!(context);
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

/// Themed container for multi-selection overlay.
class _ThemedMultiOverlayContainer extends StatelessWidget {
  const _ThemedMultiOverlayContainer({
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

/// Focusable item widget for multi-selection.
class _FocusableMultiItem<T> extends StatefulWidget {
  const _FocusableMultiItem({
    required this.item,
    required this.isFocused,
    required this.isSelected,
    required this.focusedColor,
    required this.selectedColor,
    required this.onTap,
    required this.onHover,
    required this.child,
    this.hoverColor,
  });

  final T item;
  final bool isFocused;
  final bool isSelected;
  final Color focusedColor;
  final Color selectedColor;
  final Color? hoverColor;
  final VoidCallback onTap;
  final ValueChanged<bool> onHover;
  final Widget child;

  @override
  State<_FocusableMultiItem<T>> createState() => _FocusableMultiItemState<T>();
}

class _FocusableMultiItemState<T> extends State<_FocusableMultiItem<T>> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    Color? backgroundColor;
    if (widget.isSelected) {
      backgroundColor = widget.selectedColor;
    } else if (widget.isFocused) {
      backgroundColor = widget.focusedColor;
    } else if (_isHovering) {
      backgroundColor = widget.hoverColor;
    }

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
          color: backgroundColor,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Default chip widget for displaying pending keys (items not yet loaded).
class _DefaultPendingKeyChip<K> extends StatelessWidget {
  const _DefaultPendingKeyChip({
    required this.keyLabel,
    required this.onRemove,
    this.backgroundColor,
    this.iconColor,
    this.borderRadius,
  });

  final String keyLabel;
  final VoidCallback onRemove;
  final Color? backgroundColor;
  final Color? iconColor;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ??
            Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5),
        borderRadius: borderRadius ?? BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator.adaptive(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      keyLabel,
                      style: Theme.of(context).textTheme.bodyMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          InkWell(
            onTap: onRemove,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.close,
                size: 18,
                color:
                    iconColor ?? Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}

/// Bottom sheet content for multi-selection search.
class _SmartSearchBottomSheetContent<T, K> extends StatefulWidget {
  const _SmartSearchBottomSheetContent({
    required this.controller,
    required this.cubit,
    required this.config,
    required this.itemBuilder,
    required this.heightFactor,
    this.loadingBuilder,
    this.emptyBuilder,
    this.errorBuilder,
    this.separatorBuilder,
    this.headerBuilder,
    this.footerBuilder,
    this.decoration,
    this.style,
    this.prefixIcon,
    this.showClearButton = true,
    this.borderRadius,
    this.hintText,
    this.maxSelections,
    this.onMaxSelectionsReached,
  });

  final SmartSearchMultiController<T, K> controller;
  final SmartPaginationCubit<T> cubit;
  final SmartSearchBottomSheetConfig config;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final double heightFactor;
  final WidgetBuilder? loadingBuilder;
  final WidgetBuilder? emptyBuilder;
  final Widget Function(BuildContext context, Exception error)? errorBuilder;
  final IndexedWidgetBuilder? separatorBuilder;
  final WidgetBuilder? headerBuilder;
  final WidgetBuilder? footerBuilder;
  final InputDecoration? decoration;
  final TextStyle? style;
  final Widget? prefixIcon;
  final bool showClearButton;
  final BorderRadius? borderRadius;
  final String? hintText;
  final int? maxSelections;
  final VoidCallback? onMaxSelectionsReached;

  @override
  State<_SmartSearchBottomSheetContent<T, K>> createState() =>
      _SmartSearchBottomSheetContentState<T, K>();
}

class _SmartSearchBottomSheetContentState<T, K>
    extends State<_SmartSearchBottomSheetContent<T, K>> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);
    // Trigger initial search
    widget.controller.searchNow();
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    widget.controller.textController.text = _textController.text;
  }

  @override
  Widget build(BuildContext context) {
    final config = widget.config;
    final theme = Theme.of(context);
    final searchTheme = SmartSearchTheme.of(context);

    return SizedBox(
      height: MediaQuery.of(context).size.height * widget.heightFactor,
      child: Column(
        children: [
          // Header with title and actions
          _buildHeader(context, config, theme, searchTheme),

          // Search box
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: _buildSearchBox(context, searchTheme),
          ),

          // Results list
          Expanded(
            child: ListenableBuilder(
              listenable: widget.controller,
              builder: (context, _) {
                return BlocBuilder<SmartPaginationCubit<T>, SmartPaginationState<T>>(
                  bloc: widget.cubit,
                  builder: (context, state) {
                    return switch (state) {
                      SmartPaginationError<T>(:final error) =>
                        _buildError(context, error, searchTheme),
                      SmartPaginationLoaded<T>(:final items) =>
                        _buildResults(context, items, searchTheme),
                      _ => _buildLoading(context, searchTheme),
                    };
                  },
                );
              },
            ),
          ),

          // Footer with confirm button
          if (config.showConfirmButton)
            _buildFooter(context, config, theme),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    SmartSearchBottomSheetConfig config,
    ThemeData theme,
    SmartSearchTheme searchTheme,
  ) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final selectedCount = widget.controller.selectedItems.length +
            widget.controller.pendingKeys.length;

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
          child: Row(
            children: [
              // Title
              Expanded(
                child: config.titleBuilder?.call(selectedCount) ??
                    Text(
                      config.title ??
                          (config.showSelectedCount && selectedCount > 0
                              ? 'Selected ($selectedCount)'
                              : 'Select Items'),
                      style: theme.textTheme.titleLarge,
                    ),
              ),

              // Clear all button
              if (config.showClearAllButton && selectedCount > 0)
                TextButton(
                  onPressed: () {
                    widget.controller.clearAllSelections();
                  },
                  child: Text(config.clearAllText),
                ),

              // Cancel button
              if (config.showCancelButton)
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchBox(BuildContext context, SmartSearchTheme searchTheme) {
    final effectiveBorderRadius =
        widget.borderRadius ?? searchTheme.searchBoxBorderRadius ?? BorderRadius.circular(12);

    return TextField(
      controller: _textController,
      autofocus: true,
      decoration: widget.decoration ??
          InputDecoration(
            hintText: widget.hintText ?? 'Search...',
            hintStyle: TextStyle(color: searchTheme.searchBoxHintColor),
            filled: true,
            fillColor: searchTheme.searchBoxBackgroundColor,
            prefixIcon: widget.prefixIcon ??
                Icon(Icons.search, color: searchTheme.searchBoxIconColor),
            suffixIcon: widget.showClearButton && _textController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear, color: searchTheme.searchBoxIconColor),
                    onPressed: () {
                      _textController.clear();
                      widget.controller.clearSearch();
                    },
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: effectiveBorderRadius,
              borderSide: BorderSide(
                color: searchTheme.searchBoxBorderColor ?? Colors.grey[300]!,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: effectiveBorderRadius,
              borderSide: BorderSide(
                color: searchTheme.searchBoxBorderColor ?? Colors.grey[300]!,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: effectiveBorderRadius,
              borderSide: BorderSide(
                color: searchTheme.searchBoxFocusedBorderColor ??
                    Theme.of(context).colorScheme.primary,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
      style: widget.style ?? TextStyle(color: searchTheme.searchBoxTextColor),
      cursorColor: searchTheme.searchBoxCursorColor,
    );
  }

  Widget _buildLoading(BuildContext context, SmartSearchTheme searchTheme) {
    if (widget.loadingBuilder != null) {
      return widget.loadingBuilder!(context);
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: CircularProgressIndicator.adaptive(
          valueColor: AlwaysStoppedAnimation<Color>(
            searchTheme.loadingIndicatorColor ?? Theme.of(context).primaryColor,
          ),
        ),
      ),
    );
  }

  Widget _buildError(
    BuildContext context,
    Exception error,
    SmartSearchTheme searchTheme,
  ) {
    if (widget.errorBuilder != null) {
      return widget.errorBuilder!(context, error);
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              color: searchTheme.errorIconColor ?? Theme.of(context).colorScheme.error,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'An error occurred',
              style: TextStyle(
                color: searchTheme.errorTextColor ?? Theme.of(context).colorScheme.error,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => widget.controller.searchNow(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults(
    BuildContext context,
    List<T> items,
    SmartSearchTheme searchTheme,
  ) {
    if (items.isEmpty) {
      return _buildEmpty(context, searchTheme);
    }

    return Column(
      children: [
        if (widget.headerBuilder != null) widget.headerBuilder!(context),
        Expanded(
          child: Scrollbar(
            controller: _scrollController,
            thumbVisibility: true,
            child: ListView.separated(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: items.length,
              separatorBuilder: widget.separatorBuilder ??
                  (context, index) => Divider(
                        height: 1,
                        color: searchTheme.itemDividerColor,
                      ),
              itemBuilder: (context, index) {
                final item = items[index];
                final isSelected = widget.controller.isItemSelected(item);

                return _BottomSheetItem<T>(
                  item: item,
                  isSelected: isSelected,
                  selectedColor: searchTheme.itemSelectedColor ??
                      Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5),
                  hoverColor: searchTheme.itemHoverColor,
                  checkColor: searchTheme.loadingIndicatorColor ??
                      Theme.of(context).colorScheme.primary,
                  onTap: () {
                    widget.controller.toggleItemSelection(item);
                    if (widget.maxSelections != null &&
                        widget.controller.selectedItems.length >= widget.maxSelections! &&
                        isSelected == false) {
                      widget.onMaxSelectionsReached?.call();
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

  Widget _buildEmpty(BuildContext context, SmartSearchTheme searchTheme) {
    if (widget.emptyBuilder != null) {
      return widget.emptyBuilder!(context);
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: searchTheme.emptyStateIconColor ?? Theme.of(context).disabledColor,
            ),
            const SizedBox(height: 16),
            Text(
              'No results found',
              style: TextStyle(
                color: searchTheme.emptyStateTextColor ?? Theme.of(context).disabledColor,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(
    BuildContext context,
    SmartSearchBottomSheetConfig config,
    ThemeData theme,
  ) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final selectedCount = widget.controller.selectedItems.length +
            widget.controller.pendingKeys.length;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  selectedCount > 0
                      ? '${config.confirmText} ($selectedCount)'
                      : config.confirmText,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Item widget for bottom sheet list.
class _BottomSheetItem<T> extends StatefulWidget {
  const _BottomSheetItem({
    required this.item,
    required this.isSelected,
    required this.selectedColor,
    required this.checkColor,
    required this.onTap,
    required this.child,
    this.hoverColor,
  });

  final T item;
  final bool isSelected;
  final Color selectedColor;
  final Color checkColor;
  final Color? hoverColor;
  final VoidCallback onTap;
  final Widget child;

  @override
  State<_BottomSheetItem<T>> createState() => _BottomSheetItemState<T>();
}

class _BottomSheetItemState<T> extends State<_BottomSheetItem<T>> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    Color? backgroundColor;
    if (widget.isSelected) {
      backgroundColor = widget.selectedColor;
    } else if (_isHovering) {
      backgroundColor = widget.hoverColor;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: InkWell(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          color: backgroundColor,
          child: Row(
            children: [
              Expanded(child: widget.child),
              if (widget.isSelected)
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Icon(
                    Icons.check_circle,
                    color: widget.checkColor,
                    size: 24,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
