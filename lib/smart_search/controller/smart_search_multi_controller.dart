part of '../../pagination.dart';

/// Controller for managing multi-selection search state.
///
/// This controller handles:
/// - Multiple item selection from search results
/// - Search query state management
/// - Connection to pagination cubit for data fetching
/// - Overlay visibility state
/// - Keyboard navigation
/// - Key-based selection with automatic data synchronization
///
/// The controller supports two generic types:
/// - `T`: The data type of items (e.g., Product, User)
/// - `K`: The key type used for identification (e.g., String, int)
///
/// Example with key-based selection:
/// ```dart
/// final controller = SmartSearchMultiController<Product, String>(
///   cubit: productsCubit,
///   searchRequestBuilder: (query) => PaginationRequest(
///     page: 1,
///     pageSize: 20,
///     searchQuery: query,
///   ),
///   keyExtractor: (product) => product.sku,
///   selectedKeys: ['SKU-001', 'SKU-002', 'SKU-003'],
///   selectedKeyLabelBuilder: (key) => 'Product: $key',
///   onSelected: (items, keys) => print('Selected ${items.length} items'),
/// );
/// ```
class SmartSearchMultiController<T, K> extends ChangeNotifier {
  SmartSearchMultiController({
    required SmartPaginationCubit<T> cubit,
    required PaginationRequest Function(String query) searchRequestBuilder,
    SmartSearchConfig config = const SmartSearchConfig(),
    void Function(List<T> items, List<K> keys)? onSelected,
    List<T>? initialSelectedValues,
    List<K>? selectedKeys,
    K Function(T item)? keyExtractor,
    String Function(K key)? selectedKeyLabelBuilder,
    int? maxSelections,
  })  : _cubit = cubit,
        _searchRequestBuilder = searchRequestBuilder,
        _config = config,
        _onSelected = onSelected,
        _keyExtractor = keyExtractor,
        _selectedKeyLabelBuilder = selectedKeyLabelBuilder,
        _selectedItems = List<T>.from(initialSelectedValues ?? []),
        _selectedKeys = _initializeSelectedKeys(
          initialSelectedValues,
          selectedKeys,
          keyExtractor,
        ),
        _pendingKeys = selectedKeys != null && initialSelectedValues == null
            ? Set<K>.from(selectedKeys)
            : <K>{},
        _maxSelections = maxSelections {
    _textController = TextEditingController();
    _focusNode = FocusNode();
    _textController.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);

    // Listen to cubit state changes to sync pending keys with loaded data
    if (_pendingKeys.isNotEmpty) {
      _cubitSubscription = _cubit.stream.listen(_onCubitStateChanged);
    }
  }

  /// Helper to initialize selected keys from values or provided keys.
  static List<K> _initializeSelectedKeys<T, K>(
    List<T>? initialSelectedValues,
    List<K>? selectedKeys,
    K Function(T item)? keyExtractor,
  ) {
    if (selectedKeys != null) {
      return List<K>.from(selectedKeys);
    }
    if (initialSelectedValues != null && keyExtractor != null) {
      return initialSelectedValues.map(keyExtractor).toList();
    }
    return <K>[];
  }

  final SmartPaginationCubit<T> _cubit;
  final PaginationRequest Function(String query) _searchRequestBuilder;
  final SmartSearchConfig _config;
  void Function(List<T> items, List<K> keys)? _onSelected;
  final int? _maxSelections;

  /// Function to extract the key from an item.
  final K Function(T item)? _keyExtractor;

  /// Function to build a display label for a key when the item is not yet loaded.
  final String Function(K key)? _selectedKeyLabelBuilder;

  /// Subscription to cubit state changes for syncing pending keys.
  StreamSubscription<SmartPaginationState<T>>? _cubitSubscription;

  late final TextEditingController _textController;
  late final FocusNode _focusNode;

  Timer? _debounceTimer;
  String _lastSearchQuery = '';
  bool _isOverlayVisible = false;
  bool _isSearching = false;
  int _focusedIndex = -1;

  /// The list of currently selected items.
  final List<T> _selectedItems;

  /// The list of currently selected keys.
  final List<K> _selectedKeys;

  /// Set of pending keys that haven't been resolved to items yet.
  final Set<K> _pendingKeys;

  /// The connected pagination cubit.
  SmartPaginationCubit<T> get cubit => _cubit;

  /// The text editing controller for the search field.
  TextEditingController get textController => _textController;

  /// The focus node for the search field.
  FocusNode get focusNode => _focusNode;

  /// The current search configuration.
  SmartSearchConfig get config => _config;

  /// The current search query text.
  String get query => _textController.text;

  /// Whether the overlay is currently visible.
  bool get isOverlayVisible => _isOverlayVisible;

  /// Whether a search is currently in progress.
  bool get isSearching => _isSearching;

  /// Whether the search field has focus.
  bool get hasFocus => _focusNode.hasFocus;

  /// Whether the search field has text.
  bool get hasText => _textController.text.isNotEmpty;

  /// The index of the currently focused item (-1 if none).
  int get focusedIndex => _focusedIndex;

  /// Whether an item is currently focused.
  bool get hasItemFocus => _focusedIndex >= 0;

  /// The list of currently selected items (unmodifiable).
  List<T> get selectedItems => List.unmodifiable(_selectedItems);

  /// The number of selected items.
  int get selectionCount => _selectedItems.length;

  /// Whether any items are selected.
  bool get hasSelectedItems => _selectedItems.isNotEmpty;

  /// Maximum number of items that can be selected.
  int? get maxSelections => _maxSelections;

  /// Whether max selections has been reached.
  bool get isMaxSelectionsReached =>
      _maxSelections != null && _selectedItems.length >= _maxSelections!;

  /// Sets the selection callback.
  set onSelected(void Function(List<T> items, List<K> keys)? callback) {
    _onSelected = callback;
  }

  /// The list of currently selected keys (unmodifiable).
  List<K> get selectedKeys => List.unmodifiable(_selectedKeys);

  /// The number of selected keys (including pending ones).
  int get totalSelectionCount => _selectedKeys.length;

  /// Whether there are any pending keys that haven't been resolved yet.
  bool get hasPendingKeys => _pendingKeys.isNotEmpty;

  /// The set of pending keys (unmodifiable).
  Set<K> get pendingKeys => Set.unmodifiable(_pendingKeys);

  /// The key extractor function.
  K Function(T item)? get keyExtractor => _keyExtractor;

  /// Returns the display label for a specific key.
  String getKeyLabel(K key) {
    if (_selectedKeyLabelBuilder != null) {
      return _selectedKeyLabelBuilder!(key);
    }
    return key.toString();
  }

  /// Checks if a key is currently selected.
  bool isKeySelected(K key) {
    return _selectedKeys.contains(key);
  }

  /// Checks if a key is pending (not yet resolved to an item).
  bool isKeyPending(K key) {
    return _pendingKeys.contains(key);
  }

  /// Returns the currently focused item, or null if none.
  T? get focusedItem {
    final state = _cubit.state;
    if (state is SmartPaginationLoaded<T>) {
      final items = state.items;
      if (_focusedIndex >= 0 && _focusedIndex < items.length) {
        return items[_focusedIndex];
      }
    }
    return null;
  }

  /// Returns the total number of items in the current results.
  int get _itemCount {
    final state = _cubit.state;
    if (state is SmartPaginationLoaded<T>) {
      return state.items.length;
    }
    return 0;
  }

  void _onTextChanged() {
    _debounceTimer?.cancel();

    final text = _textController.text;
    _focusedIndex = -1;

    if (text.isEmpty && !_config.searchOnEmpty) {
      notifyListeners();
      return;
    }

    if (text.isNotEmpty && text.length < _config.minSearchLength) {
      notifyListeners();
      return;
    }

    // Skip debounce and search immediately when text is empty
    if (text.isEmpty && _config.skipDebounceOnEmpty) {
      _performSearch(text);
      notifyListeners();
      return;
    }

    _debounceTimer = Timer(_config.debounceDelay, () {
      _performSearch(text);
    });

    notifyListeners();
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus && !_isOverlayVisible) {
      showOverlay();
    }
    notifyListeners();
  }

  /// Called when cubit state changes to sync pending keys with loaded data.
  void _onCubitStateChanged(SmartPaginationState<T> state) {
    if (_pendingKeys.isEmpty || _keyExtractor == null) return;

    if (state is SmartPaginationLoaded<T>) {
      bool hasResolved = false;

      // Try to find items matching the pending keys
      for (final item in state.items) {
        final key = _keyExtractor!(item);
        if (_pendingKeys.contains(key)) {
          _selectedItems.add(item);
          _pendingKeys.remove(key);
          hasResolved = true;
        }
      }

      // If we've resolved all pending keys, cancel subscription
      if (_pendingKeys.isEmpty) {
        _cubitSubscription?.cancel();
        _cubitSubscription = null;
      }

      if (hasResolved) {
        notifyListeners();
      }
    }
  }

  void _performSearch(String query) {
    if (query == _lastSearchQuery) return;

    _lastSearchQuery = query;
    _isSearching = true;
    _focusedIndex = -1;
    notifyListeners();

    final request = _searchRequestBuilder(query);
    _cubit.refreshPaginatedList(requestOverride: request);

    _isSearching = false;
    notifyListeners();
  }

  /// Shows the search overlay.
  void showOverlay() {
    if (_isOverlayVisible) return;
    _isOverlayVisible = true;

    if (_cubit.state is SmartPaginationInitial && _config.searchOnEmpty) {
      _performSearch(_textController.text);
    }

    notifyListeners();
  }

  /// Hides the search overlay.
  void hideOverlay() {
    if (!_isOverlayVisible) return;
    _isOverlayVisible = false;

    if (_config.clearOnClose) {
      clearSearch();
    }

    notifyListeners();
  }

  /// Toggles the overlay visibility.
  void toggleOverlay() {
    if (_isOverlayVisible) {
      hideOverlay();
    } else {
      showOverlay();
    }
  }

  /// Clears the search text.
  void clearSearch() {
    _debounceTimer?.cancel();
    _textController.clear();
    _lastSearchQuery = '';
    _focusedIndex = -1;

    if (_config.searchOnEmpty) {
      _performSearch('');
    }

    notifyListeners();
  }

  /// Sets the search text programmatically.
  void setSearchText(String text) {
    _textController.text = text;
    _textController.selection = TextSelection.fromPosition(
      TextPosition(offset: text.length),
    );
  }

  /// Triggers an immediate search with the current text.
  void searchNow() {
    _debounceTimer?.cancel();
    _performSearch(_textController.text);
  }

  /// Requests focus on the search field.
  void requestFocus() {
    _focusNode.requestFocus();
  }

  /// Removes focus from the search field.
  void unfocus() {
    _focusNode.unfocus();
  }

  /// Moves focus to the next item.
  bool moveToNextItem() {
    if (_itemCount == 0) return false;

    if (_focusedIndex < _itemCount - 1) {
      _focusedIndex++;
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Moves focus to the previous item.
  bool moveToPreviousItem() {
    if (_itemCount == 0) return false;

    if (_focusedIndex > 0) {
      _focusedIndex--;
      notifyListeners();
      return true;
    } else if (_focusedIndex == -1 && _itemCount > 0) {
      _focusedIndex = _itemCount - 1;
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Moves focus to the first item.
  void moveToFirstItem() {
    if (_itemCount > 0) {
      _focusedIndex = 0;
      notifyListeners();
    }
  }

  /// Moves focus to the last item.
  void moveToLastItem() {
    if (_itemCount > 0) {
      _focusedIndex = _itemCount - 1;
      notifyListeners();
    }
  }

  /// Sets focus to a specific index.
  void setFocusedIndex(int index) {
    if (index >= -1 && index < _itemCount) {
      _focusedIndex = index;
      notifyListeners();
    }
  }

  /// Clears the item focus.
  void clearItemFocus() {
    _focusedIndex = -1;
    notifyListeners();
  }

  /// Checks if an item is selected.
  bool isItemSelected(T item) {
    if (_keyExtractor != null) {
      final key = _keyExtractor!(item);
      return _selectedKeys.contains(key);
    }
    return _selectedItems.contains(item);
  }

  /// Selects the currently focused item.
  T? selectFocusedItem() {
    final item = focusedItem;
    if (item != null) {
      toggleItemSelection(item);
      return item;
    }
    return null;
  }

  /// Toggles selection of an item.
  void toggleItemSelection(T item) {
    if (isItemSelected(item)) {
      removeItem(item);
    } else {
      addItem(item);
    }
  }

  /// Toggles selection by key.
  void toggleKeySelection(K key) {
    if (_selectedKeys.contains(key)) {
      removeByKey(key);
    } else {
      addByKey(key);
    }
  }

  /// Adds an item to the selection.
  void addItem(T item) {
    if (isMaxSelectionsReached) return;

    if (_keyExtractor != null) {
      final key = _keyExtractor!(item);
      if (_selectedKeys.contains(key)) return;

      _selectedItems.add(item);
      _selectedKeys.add(key);
      _pendingKeys.remove(key);
    } else {
      if (_selectedItems.contains(item)) return;
      _selectedItems.add(item);
    }

    _notifySelectionChanged();

    // Clear search after selection for next search
    clearSearch();
    notifyListeners();
  }

  /// Adds an item by its key.
  /// If the item is already loaded, it will be added immediately.
  /// Otherwise, the key will be stored as pending.
  void addByKey(K key) {
    if (_keyExtractor == null) {
      throw StateError('Cannot add by key without keyExtractor');
    }

    if (isMaxSelectionsReached) return;
    if (_selectedKeys.contains(key)) return;

    // Try to find the item in current data
    final state = _cubit.state;
    if (state is SmartPaginationLoaded<T>) {
      for (final item in state.items) {
        if (_keyExtractor!(item) == key) {
          addItem(item);
          return;
        }
      }
    }

    // Item not found - add key and mark as pending
    _selectedKeys.add(key);
    _pendingKeys.add(key);

    // Start listening for data if not already
    _cubitSubscription ??= _cubit.stream.listen(_onCubitStateChanged);

    _notifySelectionChanged();
    notifyListeners();
  }

  /// Removes an item from the selection.
  void removeItem(T item) {
    bool removed = false;

    if (_keyExtractor != null) {
      final key = _keyExtractor!(item);
      if (_selectedKeys.remove(key)) {
        _pendingKeys.remove(key);
        removed = true;
      }
    }

    if (_selectedItems.remove(item)) {
      removed = true;
    }

    if (removed) {
      _notifySelectionChanged();
      notifyListeners();
    }
  }

  /// Removes an item by its key.
  void removeByKey(K key) {
    if (_keyExtractor == null) {
      throw StateError('Cannot remove by key without keyExtractor');
    }

    if (!_selectedKeys.contains(key)) return;

    _selectedKeys.remove(key);
    _pendingKeys.remove(key);

    // Also remove from items if present
    _selectedItems.removeWhere((item) => _keyExtractor!(item) == key);

    _notifySelectionChanged();
    notifyListeners();
  }

  /// Removes an item at the given index.
  void removeItemAt(int index) {
    if (index >= 0 && index < _selectedItems.length) {
      final item = _selectedItems[index];
      removeItem(item);
    }
  }

  /// Removes a key at the given index.
  void removeKeyAt(int index) {
    if (index >= 0 && index < _selectedKeys.length) {
      final key = _selectedKeys[index];
      removeByKey(key);
    }
  }

  /// Clears all selected items.
  void clearAllSelections() {
    if (_selectedItems.isNotEmpty || _selectedKeys.isNotEmpty) {
      _selectedItems.clear();
      _selectedKeys.clear();
      _pendingKeys.clear();
      _notifySelectionChanged();
      notifyListeners();
    }
  }

  /// Sets the selected items programmatically.
  void setSelectedItems(List<T> items) {
    _selectedItems.clear();
    _selectedKeys.clear();
    _pendingKeys.clear();

    final itemsToAdd = _maxSelections != null
        ? items.take(_maxSelections!)
        : items;

    for (final item in itemsToAdd) {
      _selectedItems.add(item);
      if (_keyExtractor != null) {
        _selectedKeys.add(_keyExtractor!(item));
      }
    }

    _notifySelectionChanged();
    notifyListeners();
  }

  /// Sets the selected keys programmatically.
  /// This will try to resolve to items if data is loaded.
  void setSelectedKeys(List<K> keys) {
    if (_keyExtractor == null) {
      throw StateError('Cannot set selected keys without keyExtractor');
    }

    _selectedItems.clear();
    _selectedKeys.clear();
    _pendingKeys.clear();

    final keysToAdd = _maxSelections != null
        ? keys.take(_maxSelections!)
        : keys;

    for (final key in keysToAdd) {
      _selectedKeys.add(key);

      // Try to find the item
      final state = _cubit.state;
      if (state is SmartPaginationLoaded<T>) {
        bool found = false;
        for (final item in state.items) {
          if (_keyExtractor!(item) == key) {
            _selectedItems.add(item);
            found = true;
            break;
          }
        }
        if (!found) {
          _pendingKeys.add(key);
        }
      } else {
        _pendingKeys.add(key);
      }
    }

    // Start listening for data if there are pending keys
    if (_pendingKeys.isNotEmpty) {
      _cubitSubscription ??= _cubit.stream.listen(_onCubitStateChanged);
    }

    _notifySelectionChanged();
    notifyListeners();
  }

  void _notifySelectionChanged() {
    _onSelected?.call(
      List.unmodifiable(_selectedItems),
      List.unmodifiable(_selectedKeys),
    );
  }

  /// Handles keyboard events for navigation.
  bool handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return false;

    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowDown:
        if (!_isOverlayVisible) {
          showOverlay();
          return true;
        }
        return moveToNextItem();

      case LogicalKeyboardKey.arrowUp:
        if (!_isOverlayVisible) {
          showOverlay();
          return true;
        }
        return moveToPreviousItem();

      case LogicalKeyboardKey.enter:
        if (hasItemFocus) {
          selectFocusedItem();
          return true;
        }
        return false;

      case LogicalKeyboardKey.escape:
        if (_isOverlayVisible) {
          hideOverlay();
          return true;
        }
        return false;

      case LogicalKeyboardKey.home:
        if (_isOverlayVisible && _itemCount > 0) {
          moveToFirstItem();
          return true;
        }
        return false;

      case LogicalKeyboardKey.end:
        if (_isOverlayVisible && _itemCount > 0) {
          moveToLastItem();
          return true;
        }
        return false;

      case LogicalKeyboardKey.pageDown:
        if (_isOverlayVisible && _itemCount > 0) {
          final newIndex = (_focusedIndex + 5).clamp(0, _itemCount - 1);
          setFocusedIndex(newIndex);
          return true;
        }
        return false;

      case LogicalKeyboardKey.pageUp:
        if (_isOverlayVisible && _itemCount > 0) {
          final newIndex = (_focusedIndex - 5).clamp(0, _itemCount - 1);
          setFocusedIndex(newIndex);
          return true;
        }
        return false;

      default:
        return false;
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _cubitSubscription?.cancel();
    _textController.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChanged);
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}
