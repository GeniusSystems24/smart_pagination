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
  })  : _cubit = cubit,
        _searchRequestBuilder = searchRequestBuilder,
        _config = config {
    _textController = TextEditingController();
    _focusNode = FocusNode();
    _textController.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  final SmartPaginationCubit<T> _cubit;
  final PaginationRequest Function(String query) _searchRequestBuilder;
  final SmartSearchConfig _config;

  late final TextEditingController _textController;
  late final FocusNode _focusNode;

  Timer? _debounceTimer;
  String _lastSearchQuery = '';
  bool _isOverlayVisible = false;
  bool _isSearching = false;

  /// The index of the currently focused item in the results list.
  int _focusedIndex = -1;

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

    // Check minimum length requirement
    if (text.length < _config.minSearchLength && !_config.searchOnEmpty) {
      if (text.isEmpty && _config.searchOnEmpty) {
        _performSearch(text);
      }
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
    _focusedIndex = -1; // Reset focus on new search
    notifyListeners();

    final request = _searchRequestBuilder(query);
    _cubit.refreshPaginatedList(requestOverride: request);

    // Listen to state changes to detect when search is complete
    _isSearching = false;
    notifyListeners();
  }

  /// Shows the search overlay.
  void showOverlay() {
    if (_isOverlayVisible) return;
    _isOverlayVisible = true;
    // Preserve the focused index when reopening
    notifyListeners();
  }

  /// Hides the search overlay.
  void hideOverlay() {
    if (!_isOverlayVisible) return;
    _isOverlayVisible = false;
    // Don't reset _focusedIndex here - preserve it for when overlay reopens

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
  /// This will hide the overlay and optionally clear the search.
  void selectItem(T item) {
    hideOverlay();
    unfocus();
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
