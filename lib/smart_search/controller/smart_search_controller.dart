part of '../../pagination.dart';

/// Controller for managing search state and connecting to SmartPaginationCubit.
///
/// This controller handles:
/// - Debounced search input
/// - Search query state management
/// - Connection to pagination cubit for data fetching
/// - Overlay visibility state
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

  void _onTextChanged() {
    _debounceTimer?.cancel();

    final text = _textController.text;

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

  /// Clears the search text and resets the query.
  void clearSearch() {
    _debounceTimer?.cancel();
    _textController.clear();
    _lastSearchQuery = '';

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

  /// Selects an item from the search results.
  /// This will hide the overlay and optionally clear the search.
  void selectItem(T item) {
    hideOverlay();
    unfocus();
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
