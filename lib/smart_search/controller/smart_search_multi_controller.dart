part of '../../pagination.dart';

/// Controller for managing multi-selection search state.
///
/// This controller handles:
/// - Multiple item selection from search results
/// - Search query state management
/// - Connection to pagination cubit for data fetching
/// - Overlay visibility state
/// - Keyboard navigation
///
/// Example:
/// ```dart
/// final controller = SmartSearchMultiController<Product>(
///   cubit: productsCubit,
///   searchRequestBuilder: (query) => PaginationRequest(
///     page: 1,
///     pageSize: 20,
///     searchQuery: query,
///   ),
/// );
/// ```
class SmartSearchMultiController<T> extends ChangeNotifier {
  SmartSearchMultiController({
    required SmartPaginationCubit<T> cubit,
    required PaginationRequest Function(String query) searchRequestBuilder,
    SmartSearchConfig config = const SmartSearchConfig(),
    ValueChanged<List<T>>? onSelectionChanged,
    List<T>? initialSelectedValues,
    int? maxSelections,
  })  : _cubit = cubit,
        _searchRequestBuilder = searchRequestBuilder,
        _config = config,
        _onSelectionChanged = onSelectionChanged,
        _selectedItems = List<T>.from(initialSelectedValues ?? []),
        _maxSelections = maxSelections {
    _textController = TextEditingController();
    _focusNode = FocusNode();
    _textController.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  final SmartPaginationCubit<T> _cubit;
  final PaginationRequest Function(String query) _searchRequestBuilder;
  final SmartSearchConfig _config;
  ValueChanged<List<T>>? _onSelectionChanged;
  final int? _maxSelections;

  late final TextEditingController _textController;
  late final FocusNode _focusNode;

  Timer? _debounceTimer;
  String _lastSearchQuery = '';
  bool _isOverlayVisible = false;
  bool _isSearching = false;
  int _focusedIndex = -1;

  /// The list of currently selected items.
  final List<T> _selectedItems;

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
      _maxSelections != null && _selectedItems.length >= _maxSelections;

  /// Sets the selection changed callback.
  set onSelectionChanged(ValueChanged<List<T>>? callback) {
    _onSelectionChanged = callback;
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
    if (_selectedItems.contains(item)) {
      removeItem(item);
    } else {
      addItem(item);
    }
  }

  /// Adds an item to the selection.
  void addItem(T item) {
    if (isMaxSelectionsReached) return;
    if (_selectedItems.contains(item)) return;

    _selectedItems.add(item);
    _notifySelectionChanged();

    // Clear search after selection for next search
    clearSearch();
    notifyListeners();
  }

  /// Removes an item from the selection.
  void removeItem(T item) {
    if (_selectedItems.remove(item)) {
      _notifySelectionChanged();
      notifyListeners();
    }
  }

  /// Removes an item at the given index.
  void removeItemAt(int index) {
    if (index >= 0 && index < _selectedItems.length) {
      _selectedItems.removeAt(index);
      _notifySelectionChanged();
      notifyListeners();
    }
  }

  /// Clears all selected items.
  void clearAllSelections() {
    if (_selectedItems.isNotEmpty) {
      _selectedItems.clear();
      _notifySelectionChanged();
      notifyListeners();
    }
  }

  /// Sets the selected items programmatically.
  void setSelectedItems(List<T> items) {
    _selectedItems.clear();
    if (_maxSelections != null) {
      _selectedItems.addAll(items.take(_maxSelections));
    } else {
      _selectedItems.addAll(items);
    }
    _notifySelectionChanged();
    notifyListeners();
  }

  void _notifySelectionChanged() {
    _onSelectionChanged?.call(List.unmodifiable(_selectedItems));
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
    _textController.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChanged);
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}
