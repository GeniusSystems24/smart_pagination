part of '../../pagination.dart';

/// A convenient widget that combines search functionality with a dropdown
/// overlay showing paginated results from a SmartPaginationCubit.
///
/// This widget provides a complete search-with-results solution that can be
/// placed anywhere in your UI. The results dropdown automatically positions
/// itself in the best available space.
///
/// ## Generic Types
///
/// - `T`: The data type of items (e.g., Product, User)
/// - `K`: The key type used for identification (e.g., String, int)
///
/// ## Key-based Selection
///
/// When using key-based selection, you can:
/// - Set initial selection by key even before data loads
/// - Compare items by key instead of object equality
/// - Get notified of both item and key when selection happens
///
/// Example with key-based selection:
/// ```dart
/// SmartSearchDropdown<Product, String>.withProvider(
///   request: PaginationRequest(page: 1, pageSize: 20),
///   provider: PaginationProvider.future((request) async {
///     return await api.searchProducts(request.searchQuery ?? '');
///   }),
///   searchRequestBuilder: (query) => PaginationRequest(...),
///   itemBuilder: (context, product) => ListTile(title: Text(product.name)),
///   keyExtractor: (product) => product.sku,
///   selectedKey: 'SKU-001',
///   selectedKeyLabelBuilder: (key) => 'Product: $key',
///   onSelected: (product, key) => print('Selected: ${product.name} with key: $key'),
/// )
/// ```
///
/// Example with showSelected mode:
/// ```dart
/// SmartSearchDropdown<Product, String>.withProvider(
///   // ... other properties
///   showSelected: true,
///   selectedItemBuilder: (context, product, onClear) => ListTile(
///     title: Text(product.name),
///     trailing: IconButton(
///       icon: Icon(Icons.close),
///       onPressed: onClear,
///     ),
///   ),
/// )
/// ```
///
/// Example with external cubit:
/// ```dart
/// SmartSearchDropdown<Product, String>.withCubit(
///   cubit: productSearchCubit,
///   searchRequestBuilder: (query) => PaginationRequest(
///     page: 1,
///     pageSize: 20,
///     searchQuery: query,
///   ),
///   itemBuilder: (context, product) => ListTile(
///     title: Text(product.name),
///   ),
///   keyExtractor: (product) => product.sku,
///   onSelected: (product, key) {
///     print('Selected: ${product.name}');
///   },
/// )
/// ```
class SmartSearchDropdown<T, K> extends StatefulWidget {
  /// Creates a search dropdown with an internal cubit.
  const SmartSearchDropdown.withProvider({
    super.key,
    required PaginationRequest request,
    required PaginationProvider<T> provider,
    required this.searchRequestBuilder,
    required this.itemBuilder,
    this.onSelected,
    this.searchConfig = const SmartSearchConfig(),
    this.overlayConfig = const SmartSearchOverlayConfig(),
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
    this.showSelected = false,
    this.selectedItemBuilder,
    this.selectedKeyBuilder,
    this.initialSelectedValue,
    this.selectedKey,
    this.keyExtractor,
    this.selectedKeyLabelBuilder,
    this.validator,
    this.textInputAction = TextInputAction.search,
    this.inputFormatters,
    this.autovalidateMode,
    this.onChanged,
    this.maxLength,
    this.textCapitalization = TextCapitalization.none,
    this.keyboardType = TextInputType.text,
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

  /// Creates a search dropdown with an external cubit.
  const SmartSearchDropdown.withCubit({
    super.key,
    required SmartPaginationCubit<T> cubit,
    required this.searchRequestBuilder,
    required this.itemBuilder,
    this.onSelected,
    this.searchConfig = const SmartSearchConfig(),
    this.overlayConfig = const SmartSearchOverlayConfig(),
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
    this.showSelected = false,
    this.selectedItemBuilder,
    this.selectedKeyBuilder,
    this.initialSelectedValue,
    this.selectedKey,
    this.keyExtractor,
    this.selectedKeyLabelBuilder,
    this.validator,
    this.textInputAction = TextInputAction.search,
    this.inputFormatters,
    this.autovalidateMode,
    this.onChanged,
    this.maxLength,
    this.textCapitalization = TextCapitalization.none,
    this.keyboardType = TextInputType.text,
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

  /// Called when an item is selected with its key.
  /// Requires [keyExtractor] to be provided.
  final void Function(T item, K key)? onSelected;

  /// Configuration for search behavior.
  final SmartSearchConfig searchConfig;

  /// Configuration for the overlay appearance.
  final SmartSearchOverlayConfig overlayConfig;

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

  /// Whether to show the selected item instead of the search box after selection.
  ///
  /// When true, selecting an item will replace the search box with the selected
  /// item display. Tapping on the selected item will clear the selection and
  /// show the search box again.
  final bool showSelected;

  /// Builder for displaying the selected item when [showSelected] is true.
  ///
  /// The builder receives:
  /// - `context`: The build context
  /// - `item`: The selected item
  /// - `onClear`: Callback to clear the selection and show the search box
  ///
  /// If not provided, a default display using [itemBuilder] will be used.
  final Widget Function(BuildContext context, T item, VoidCallback onClear)?
      selectedItemBuilder;

  /// The initially selected value.
  ///
  /// When provided, the widget will start with this item selected if
  /// [showSelected] is true.
  final T? initialSelectedValue;

  /// The initially selected key.
  ///
  /// When provided with [keyExtractor], the widget will try to find and select
  /// the item with this key. If the item hasn't been loaded yet, it will be
  /// selected when the data loads.
  final K? selectedKey;

  /// Function to extract the key from an item.
  ///
  /// When provided, selections are compared by key instead of object equality.
  /// This enables key-based initial selection and comparison.
  final K Function(T item)? keyExtractor;

  /// Function to build a display label for a key when the item is not yet loaded.
  ///
  /// This is used when [selectedKey] is provided but the data hasn't been
  /// loaded yet. If not provided, the key's toString() will be used.
  final String Function(K key)? selectedKeyLabelBuilder;

  /// Builder for displaying the selected key when item is not yet loaded.
  ///
  /// If not provided, a default display using [selectedKeyLabelBuilder] or
  /// key.toString() will be used.
  final Widget Function(BuildContext context, K key, VoidCallback onClear)?
      selectedKeyBuilder;

  /// Validator function for form validation.
  ///
  /// Returns an error string if validation fails, null otherwise.
  /// When provided, a TextFormField is used instead of TextField.
  final String? Function(String?)? validator;

  /// The action button on the keyboard (e.g., search, done, next).
  final TextInputAction textInputAction;

  /// Input formatters to restrict or format input.
  ///
  /// Example:
  /// ```dart
  /// inputFormatters: [
  ///   FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\s]')),
  ///   LengthLimitingTextInputFormatter(50),
  /// ]
  /// ```
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

  @override
  State<SmartSearchDropdown<T, K>> createState() =>
      _SmartSearchDropdownState<T, K>();
}

class _SmartSearchDropdownState<T, K> extends State<SmartSearchDropdown<T, K>> {
  SmartPaginationCubit<T>? _internalCubit;
  SmartSearchController<T, K>? _searchController;

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
    _searchController = SmartSearchController<T, K>(
      cubit: _cubit,
      searchRequestBuilder: widget.searchRequestBuilder,
      config: widget.searchConfig,
      onSelected: widget.onSelected,
      initialSelectedValue: widget.initialSelectedValue,
      selectedKey: widget.selectedKey,
      keyExtractor: widget.keyExtractor,
      selectedKeyLabelBuilder: widget.selectedKeyLabelBuilder,
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
        // Show selected item if showSelected is true and an item is selected
        if (widget.showSelected && _searchController!.hasSelectedItem) {
          return _buildSelectedItemDisplay(context);
        }

        // Show pending key display if showSelected is true and we have a pending key
        if (widget.showSelected && _searchController!.hasPendingKey) {
          return _buildPendingKeyDisplay(context);
        }

        // Show the search overlay
        return SmartSearchOverlay<T, K>(
          controller: _searchController!,
          itemBuilder: widget.itemBuilder,
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
        );
      },
    );
  }

  Widget _buildPendingKeyDisplay(BuildContext context) {
    final pendingKey = _searchController!.selectedKey;
    if (pendingKey == null) return const SizedBox.shrink();

    final searchTheme = SmartSearchTheme.of(context);

    // Use custom selectedKeyBuilder if provided
    if (widget.selectedKeyBuilder != null) {
      return widget.selectedKeyBuilder!(
        context,
        pendingKey,
        () => _searchController!.clearSelection(),
      );
    }

    // Default pending key display
    final label = _searchController!.getKeyLabel(pendingKey);
    return _DefaultPendingKeyDisplay<K>(
      keyLabel: label,
      onClear: () => _searchController!.clearSelection(),
      borderRadius: widget.borderRadius ?? searchTheme.searchBoxBorderRadius,
      backgroundColor: searchTheme.searchBoxBackgroundColor,
      borderColor: searchTheme.searchBoxBorderColor,
      iconColor: searchTheme.searchBoxIconColor,
    );
  }

  Widget _buildSelectedItemDisplay(BuildContext context) {
    final selectedItem = _searchController!.selectedItem!;
    final searchTheme = SmartSearchTheme.of(context);

    // Use custom selectedItemBuilder if provided
    if (widget.selectedItemBuilder != null) {
      return widget.selectedItemBuilder!(
        context,
        selectedItem,
        () => _searchController!.clearSelection(),
      );
    }

    // Default selected item display
    return _DefaultSelectedItemDisplay<T>(
      item: selectedItem,
      itemBuilder: widget.itemBuilder,
      onClear: () => _searchController!.clearSelection(),
      borderRadius: widget.borderRadius ?? searchTheme.searchBoxBorderRadius,
      backgroundColor: searchTheme.searchBoxBackgroundColor,
      borderColor: searchTheme.searchBoxBorderColor,
      iconColor: searchTheme.searchBoxIconColor,
    );
  }
}

/// Default display widget for selected items.
class _DefaultSelectedItemDisplay<T> extends StatelessWidget {
  const _DefaultSelectedItemDisplay({
    required this.item,
    required this.itemBuilder,
    required this.onClear,
    this.borderRadius,
    this.backgroundColor,
    this.borderColor,
    this.iconColor,
  });

  final T item;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final VoidCallback onClear;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final effectiveBorderRadius = borderRadius ?? BorderRadius.circular(12);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onClear,
        borderRadius: effectiveBorderRadius,
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor ?? Theme.of(context).cardColor,
            borderRadius: effectiveBorderRadius,
            border: Border.all(
              color: borderColor ?? Colors.grey[300]!,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: itemBuilder(context, item),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(
                  Icons.close,
                  size: 20,
                  color: iconColor ?? Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Default display widget for pending key (item not yet loaded).
class _DefaultPendingKeyDisplay<K> extends StatelessWidget {
  const _DefaultPendingKeyDisplay({
    required this.keyLabel,
    required this.onClear,
    this.borderRadius,
    this.backgroundColor,
    this.borderColor,
    this.iconColor,
  });

  final String keyLabel;
  final VoidCallback onClear;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final effectiveBorderRadius = borderRadius ?? BorderRadius.circular(12);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onClear,
        borderRadius: effectiveBorderRadius,
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor ?? Theme.of(context).cardColor,
            borderRadius: effectiveBorderRadius,
            border: Border.all(
              color: borderColor ?? Colors.grey[300]!,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator.adaptive(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
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
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(
                  Icons.close,
                  size: 20,
                  color: iconColor ?? Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
