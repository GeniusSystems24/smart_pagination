part of '../../pagination.dart';

/// Controller for managing search state and connecting to SmartPaginationCubit.
///
/// This controller handles:
/// - Debounced search input
/// - Search query state management
/// - Connection to pagination cubit for data fetching
/// - Overlay visibility state
/// - Keyboard navigation (up/down arrows)
/// - Focus state persistence
/// - Selected item state (for showSelected mode)
///
/// Example:
/// ```dart
/// final searchController = SmartSearchController<Product>(
///   cubit: productsCubit,
///   searchFieldBuilder: (query) => PaginationRequest(
///     page: 1,
///     pageSize: 20,
///     searchQuery: query,
///   ),
/// );
/// ```
class SmartSearchController<T> extends ChangeNotifier {
  SmartSearchController({
    required SmartPaginationCubit<T> cubit,
    required PaginationRequest Function(String query) searchRequestBuilder,
    SmartSearchConfig config = const SmartSearchConfig(),
    ValueChanged<T>? onItemSelected,
    T? initialSelectedValue,
  })  : _cubit = cubit,
        _searchRequestBuilder = searchRequestBuilder,
        _config = config,
        _onItemSelected = onItemSelected,
        _selectedItem = initialSelectedValue {
    _textController = TextEditingController();
    _focusNode = FocusNode();
    _textController.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  final SmartPaginationCubit<T> _cubit;
  final PaginationRequest Function(String query) _searchRequestBuilder;
  final SmartSearchConfig _config;
  ValueChanged<T>? _onItemSelected;

  /// Sets the item selection callback.
  set onItemSelected(ValueChanged<T>? callback) {
    _onItemSelected = callback;
  }

  late final TextEditingController _textController;
  late final FocusNode _focusNode;

  Timer? _debounceTimer;
  String _lastSearchQuery = '';
  bool _isOverlayVisible = false;
  bool _isSearching = false;

  /// The index of the currently focused item in the results list.
  int _focusedIndex = -1;

  /// The currently selected item (for showSelected mode).
  T? _selectedItem;

  /// A custom value passed when overlay is shown programmatically.
  /// This can be used to determine what content to display in the overlay.
  Object? _overlayValue;

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

  /// Alias for hasFocus for consistency.
  bool get isFocused => _focusNode.hasFocus;

  /// Whether the search field has text.
  bool get hasText => _textController.text.isNotEmpty;

  /// The index of the currently focused item (-1 if none).
  int get focusedIndex => _focusedIndex;

  /// Whether an item is currently focused.
  bool get hasItemFocus => _focusedIndex >= 0;

  /// The currently selected item (for showSelected mode).
  T? get selectedItem => _selectedItem;

  /// Whether an item is currently selected.
  bool get hasSelectedItem => _selectedItem != null;

  /// The custom value passed when overlay was shown.
  /// Use this to determine overlay content type.
  ///
  /// Example:
  /// ```dart
  /// controller.showOverlay(value: 'user'); // Show user search
  /// controller.showOverlay(value: 1); // Show category 1
  ///
  /// // In your widget:
  /// if (controller.overlayValue == 'user') {
  ///   return UserSearchContent();
  /// }
  /// ```
  Object? get overlayValue => _overlayValue;

  /// Whether a custom overlay value is set.
  bool get hasOverlayValue => _overlayValue != null;

  /// Gets the overlay value cast to a specific type.
  /// Returns null if the value is not of the expected type.
  V? getOverlayValue<V>() {
    final value = _overlayValue;
    return value is V ? value : null;
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

    // Reset focused index when search text changes
    _focusedIndex = -1;

    // If text is empty and searchOnEmpty is false, don't search
    if (text.isEmpty && !_config.searchOnEmpty) {
      notifyListeners();
      return;
    }

    // If text length is less than minimum and not empty, don't search yet
    if (text.isNotEmpty && text.length < _config.minSearchLength) {
      notifyListeners();
      return;
    }

    // Always use debounce timer before searching
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
    _focusedIndex = -1; // Reset focus on new search
    notifyListeners();

    final request = _searchRequestBuilder(query);
    _cubit.refreshPaginatedList(requestOverride: request);

    // Listen to state changes to detect when search is complete
    _isSearching = false;
    notifyListeners();
  }

  /// Shows the search overlay with an optional value.
  ///
  /// The [value] parameter can be used to pass context-specific data
  /// that determines what content to display in the overlay.
  ///
  /// Example:
  /// ```dart
  /// // Show overlay for user search
  /// controller.showOverlay(value: 'user');
  ///
  /// // Show overlay for category selection
  /// controller.showOverlay(value: CategoryType.products);
  ///
  /// // Show overlay with numeric identifier
  /// controller.showOverlay(value: 1);
  /// ```
  void showOverlay({Object? value}) {
    if (_isOverlayVisible) {
      // If already visible but value changed, update it
      if (value != null && _overlayValue != value) {
        _overlayValue = value;
        notifyListeners();
      }
      return;
    }

    _isOverlayVisible = true;
    _overlayValue = value;
    // Preserve the focused index when reopening

    // If cubit is in initial state and searchOnEmpty is true, trigger initial fetch
    if (_cubit.state is SmartPaginationInitial && _config.searchOnEmpty) {
      _performSearch(_textController.text);
    }

    notifyListeners();
  }

  /// Hides the search overlay.
  ///
  /// If [clearValue] is true (default), the overlay value will be cleared.
  void hideOverlay({bool clearValue = true}) {
    if (!_isOverlayVisible) return;
    _isOverlayVisible = false;
    // Don't reset _focusedIndex here - preserve it for when overlay reopens

    if (clearValue) {
      _overlayValue = null;
    }

    if (_config.clearOnClose) {
      clearSearch();
    }

    notifyListeners();
  }

  /// Sets the overlay value without showing the overlay.
  void setOverlayValue(Object? value) {
    _overlayValue = value;
    notifyListeners();
  }

  /// Clears the overlay value.
  void clearOverlayValue() {
    _overlayValue = null;
    notifyListeners();
  }

  /// Toggles the overlay visibility with an optional value.
  void toggleOverlay({Object? value}) {
    if (_isOverlayVisible) {
      hideOverlay();
    } else {
      showOverlay(value: value);
    }
  }

  /// Clears the search text and resets the query.
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

  /// Moves focus to the next item in the list.
  /// Returns true if focus was moved, false if at the end.
  bool moveToNextItem() {
    if (_itemCount == 0) return false;

    if (_focusedIndex < _itemCount - 1) {
      _focusedIndex++;
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Moves focus to the previous item in the list.
  /// Returns true if focus was moved, false if at the beginning.
  bool moveToPreviousItem() {
    if (_itemCount == 0) return false;

    if (_focusedIndex > 0) {
      _focusedIndex--;
      notifyListeners();
      return true;
    } else if (_focusedIndex == -1 && _itemCount > 0) {
      // If no item is focused, focus the last item
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

  /// Clears the item focus (sets to -1).
  void clearItemFocus() {
    _focusedIndex = -1;
    notifyListeners();
  }

  /// Selects the currently focused item.
  /// Returns the item if one was focused and selected, null otherwise.
  T? selectFocusedItem() {
    final item = focusedItem;
    if (item != null) {
      selectItem(item);
      return item;
    }
    return null;
  }

  /// Selects an item from the search results.
  /// This will store the selected item, hide the overlay, call the onItemSelected callback,
  /// and optionally clear the search.
  void selectItem(T item) {
    _selectedItem = item;
    _onItemSelected?.call(item);
    hideOverlay();
    unfocus();
    notifyListeners();
  }

  /// Sets the selected item programmatically.
  void setSelectedItem(T? item) {
    _selectedItem = item;
    notifyListeners();
  }

  /// Clears the selected item and shows the search box.
  /// Optionally requests focus on the search field.
  void clearSelection({bool requestFocus = true}) {
    _selectedItem = null;
    clearSearch();
    if (requestFocus) {
      this.requestFocus();
    }
    notifyListeners();
  }

  /// Handles keyboard events for navigation.
  /// Returns true if the event was handled.
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
          // Move 5 items down or to the end
          final newIndex = (_focusedIndex + 5).clamp(0, _itemCount - 1);
          setFocusedIndex(newIndex);
          return true;
        }
        return false;

      case LogicalKeyboardKey.pageUp:
        if (_isOverlayVisible && _itemCount > 0) {
          // Move 5 items up or to the beginning
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
