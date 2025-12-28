part of '../../pagination.dart';

/// Theme extension for SmartSearch widgets.
///
/// This extension provides customizable theming for all SmartSearch components
/// including the search box, overlay dropdown, and result items.
///
/// ## Usage
///
/// Add the theme extension to your app's theme:
///
/// ```dart
/// MaterialApp(
///   theme: ThemeData.light().copyWith(
///     extensions: [SmartSearchTheme.light()],
///   ),
///   darkTheme: ThemeData.dark().copyWith(
///     extensions: [SmartSearchTheme.dark()],
///   ),
/// )
/// ```
///
/// Or create a custom theme:
///
/// ```dart
/// SmartSearchTheme(
///   searchBoxBackgroundColor: Colors.grey[100],
///   searchBoxTextColor: Colors.black87,
///   // ... other properties
/// )
/// ```
class SmartSearchTheme extends ThemeExtension<SmartSearchTheme> {
  /// Creates a SmartSearchTheme with the given properties.
  const SmartSearchTheme({
    // Search Box
    this.searchBoxBackgroundColor,
    this.searchBoxTextColor,
    this.searchBoxHintColor,
    this.searchBoxBorderColor,
    this.searchBoxFocusedBorderColor,
    this.searchBoxIconColor,
    this.searchBoxCursorColor,
    this.searchBoxBorderRadius,
    this.searchBoxElevation,
    this.searchBoxShadowColor,

    // Overlay
    this.overlayBackgroundColor,
    this.overlayBorderColor,
    this.overlayBorderRadius,
    this.overlayElevation,
    this.overlayShadowColor,

    // Items
    this.itemBackgroundColor,
    this.itemHoverColor,
    this.itemFocusedColor,
    this.itemSelectedColor,
    this.itemTextColor,
    this.itemSubtitleColor,
    this.itemIconColor,
    this.itemDividerColor,

    // States
    this.loadingIndicatorColor,
    this.emptyStateIconColor,
    this.emptyStateTextColor,
    this.errorIconColor,
    this.errorTextColor,
    this.errorButtonColor,

    // Scrollbar
    this.scrollbarColor,
    this.scrollbarThickness,
    this.scrollbarRadius,
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Search Box Properties
  // ─────────────────────────────────────────────────────────────────────────

  /// Background color of the search box.
  final Color? searchBoxBackgroundColor;

  /// Text color in the search box.
  final Color? searchBoxTextColor;

  /// Hint text color in the search box.
  final Color? searchBoxHintColor;

  /// Border color of the search box.
  final Color? searchBoxBorderColor;

  /// Border color when the search box is focused.
  final Color? searchBoxFocusedBorderColor;

  /// Icon color in the search box (prefix/suffix icons).
  final Color? searchBoxIconColor;

  /// Cursor color in the search box.
  final Color? searchBoxCursorColor;

  /// Border radius of the search box.
  final BorderRadius? searchBoxBorderRadius;

  /// Elevation of the search box.
  final double? searchBoxElevation;

  /// Shadow color of the search box.
  final Color? searchBoxShadowColor;

  // ─────────────────────────────────────────────────────────────────────────
  // Overlay Properties
  // ─────────────────────────────────────────────────────────────────────────

  /// Background color of the overlay dropdown.
  final Color? overlayBackgroundColor;

  /// Border color of the overlay dropdown.
  final Color? overlayBorderColor;

  /// Border radius of the overlay dropdown.
  final BorderRadius? overlayBorderRadius;

  /// Elevation of the overlay dropdown.
  final double? overlayElevation;

  /// Shadow color of the overlay dropdown.
  final Color? overlayShadowColor;

  // ─────────────────────────────────────────────────────────────────────────
  // Item Properties
  // ─────────────────────────────────────────────────────────────────────────

  /// Default background color of items.
  final Color? itemBackgroundColor;

  /// Background color when hovering over an item.
  final Color? itemHoverColor;

  /// Background color of the focused item (keyboard navigation).
  final Color? itemFocusedColor;

  /// Background color of the selected item.
  final Color? itemSelectedColor;

  /// Primary text color of items.
  final Color? itemTextColor;

  /// Subtitle/secondary text color of items.
  final Color? itemSubtitleColor;

  /// Icon color in items.
  final Color? itemIconColor;

  /// Divider color between items.
  final Color? itemDividerColor;

  // ─────────────────────────────────────────────────────────────────────────
  // State Properties
  // ─────────────────────────────────────────────────────────────────────────

  /// Color of the loading indicator.
  final Color? loadingIndicatorColor;

  /// Icon color in the empty state.
  final Color? emptyStateIconColor;

  /// Text color in the empty state.
  final Color? emptyStateTextColor;

  /// Icon color in the error state.
  final Color? errorIconColor;

  /// Text color in the error state.
  final Color? errorTextColor;

  /// Button color in the error state (retry button).
  final Color? errorButtonColor;

  // ─────────────────────────────────────────────────────────────────────────
  // Scrollbar Properties
  // ─────────────────────────────────────────────────────────────────────────

  /// Color of the scrollbar.
  final Color? scrollbarColor;

  /// Thickness of the scrollbar.
  final double? scrollbarThickness;

  /// Radius of the scrollbar.
  final Radius? scrollbarRadius;

  // ─────────────────────────────────────────────────────────────────────────
  // Factory Constructors
  // ─────────────────────────────────────────────────────────────────────────

  /// Creates a light theme for SmartSearch widgets.
  factory SmartSearchTheme.light() {
    return SmartSearchTheme(
      // Search Box
      searchBoxBackgroundColor: Colors.white,
      searchBoxTextColor: const Color(0xFF1F2937),
      searchBoxHintColor: const Color(0xFF9CA3AF),
      searchBoxBorderColor: const Color(0xFFE5E7EB),
      searchBoxFocusedBorderColor: const Color(0xFF6366F1),
      searchBoxIconColor: const Color(0xFF9CA3AF),
      searchBoxCursorColor: const Color(0xFF6366F1),
      searchBoxBorderRadius: BorderRadius.circular(12),
      searchBoxElevation: 0,
      searchBoxShadowColor: Colors.black.withValues(alpha: 0.05),

      // Overlay
      overlayBackgroundColor: Colors.white,
      overlayBorderColor: const Color(0xFFE5E7EB),
      overlayBorderRadius: BorderRadius.circular(12),
      overlayElevation: 8,
      overlayShadowColor: Colors.black.withValues(alpha: 0.1),

      // Items
      itemBackgroundColor: Colors.transparent,
      itemHoverColor: const Color(0xFFF3F4F6),
      itemFocusedColor: const Color(0xFFEEF2FF),
      itemSelectedColor: const Color(0xFFE0E7FF),
      itemTextColor: const Color(0xFF1F2937),
      itemSubtitleColor: const Color(0xFF6B7280),
      itemIconColor: const Color(0xFF6B7280),
      itemDividerColor: const Color(0xFFF3F4F6),

      // States
      loadingIndicatorColor: const Color(0xFF6366F1),
      emptyStateIconColor: const Color(0xFFD1D5DB),
      emptyStateTextColor: const Color(0xFF9CA3AF),
      errorIconColor: const Color(0xFFEF4444),
      errorTextColor: const Color(0xFF6B7280),
      errorButtonColor: const Color(0xFF6366F1),

      // Scrollbar
      scrollbarColor: const Color(0xFFD1D5DB),
      scrollbarThickness: 6,
      scrollbarRadius: const Radius.circular(3),
    );
  }

  /// Creates a dark theme for SmartSearch widgets.
  factory SmartSearchTheme.dark() {
    return SmartSearchTheme(
      // Search Box
      searchBoxBackgroundColor: const Color(0xFF1F2937),
      searchBoxTextColor: const Color(0xFFF9FAFB),
      searchBoxHintColor: const Color(0xFF6B7280),
      searchBoxBorderColor: const Color(0xFF374151),
      searchBoxFocusedBorderColor: const Color(0xFF818CF8),
      searchBoxIconColor: const Color(0xFF6B7280),
      searchBoxCursorColor: const Color(0xFF818CF8),
      searchBoxBorderRadius: BorderRadius.circular(12),
      searchBoxElevation: 0,
      searchBoxShadowColor: Colors.black.withValues(alpha: 0.2),

      // Overlay
      overlayBackgroundColor: const Color(0xFF1F2937),
      overlayBorderColor: const Color(0xFF374151),
      overlayBorderRadius: BorderRadius.circular(12),
      overlayElevation: 8,
      overlayShadowColor: Colors.black.withValues(alpha: 0.3),

      // Items
      itemBackgroundColor: Colors.transparent,
      itemHoverColor: const Color(0xFF374151),
      itemFocusedColor: const Color(0xFF312E81),
      itemSelectedColor: const Color(0xFF3730A3),
      itemTextColor: const Color(0xFFF9FAFB),
      itemSubtitleColor: const Color(0xFF9CA3AF),
      itemIconColor: const Color(0xFF9CA3AF),
      itemDividerColor: const Color(0xFF374151),

      // States
      loadingIndicatorColor: const Color(0xFF818CF8),
      emptyStateIconColor: const Color(0xFF4B5563),
      emptyStateTextColor: const Color(0xFF6B7280),
      errorIconColor: const Color(0xFFF87171),
      errorTextColor: const Color(0xFF9CA3AF),
      errorButtonColor: const Color(0xFF818CF8),

      // Scrollbar
      scrollbarColor: const Color(0xFF4B5563),
      scrollbarThickness: 6,
      scrollbarRadius: const Radius.circular(3),
    );
  }

  /// Gets the SmartSearchTheme from the current context.
  ///
  /// Falls back to light or dark theme based on the system brightness
  /// if no theme extension is found.
  static SmartSearchTheme of(BuildContext context) {
    final theme = Theme.of(context).extension<SmartSearchTheme>();
    if (theme != null) return theme;

    // Fall back to system theme based on brightness
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? SmartSearchTheme.dark()
        : SmartSearchTheme.light();
  }

  /// Gets the SmartSearchTheme from the current context, or null if not found.
  static SmartSearchTheme? maybeOf(BuildContext context) {
    return Theme.of(context).extension<SmartSearchTheme>();
  }

  @override
  SmartSearchTheme copyWith({
    // Search Box
    Color? searchBoxBackgroundColor,
    Color? searchBoxTextColor,
    Color? searchBoxHintColor,
    Color? searchBoxBorderColor,
    Color? searchBoxFocusedBorderColor,
    Color? searchBoxIconColor,
    Color? searchBoxCursorColor,
    BorderRadius? searchBoxBorderRadius,
    double? searchBoxElevation,
    Color? searchBoxShadowColor,

    // Overlay
    Color? overlayBackgroundColor,
    Color? overlayBorderColor,
    BorderRadius? overlayBorderRadius,
    double? overlayElevation,
    Color? overlayShadowColor,

    // Items
    Color? itemBackgroundColor,
    Color? itemHoverColor,
    Color? itemFocusedColor,
    Color? itemSelectedColor,
    Color? itemTextColor,
    Color? itemSubtitleColor,
    Color? itemIconColor,
    Color? itemDividerColor,

    // States
    Color? loadingIndicatorColor,
    Color? emptyStateIconColor,
    Color? emptyStateTextColor,
    Color? errorIconColor,
    Color? errorTextColor,
    Color? errorButtonColor,

    // Scrollbar
    Color? scrollbarColor,
    double? scrollbarThickness,
    Radius? scrollbarRadius,
  }) {
    return SmartSearchTheme(
      searchBoxBackgroundColor:
          searchBoxBackgroundColor ?? this.searchBoxBackgroundColor,
      searchBoxTextColor: searchBoxTextColor ?? this.searchBoxTextColor,
      searchBoxHintColor: searchBoxHintColor ?? this.searchBoxHintColor,
      searchBoxBorderColor: searchBoxBorderColor ?? this.searchBoxBorderColor,
      searchBoxFocusedBorderColor:
          searchBoxFocusedBorderColor ?? this.searchBoxFocusedBorderColor,
      searchBoxIconColor: searchBoxIconColor ?? this.searchBoxIconColor,
      searchBoxCursorColor: searchBoxCursorColor ?? this.searchBoxCursorColor,
      searchBoxBorderRadius:
          searchBoxBorderRadius ?? this.searchBoxBorderRadius,
      searchBoxElevation: searchBoxElevation ?? this.searchBoxElevation,
      searchBoxShadowColor: searchBoxShadowColor ?? this.searchBoxShadowColor,
      overlayBackgroundColor:
          overlayBackgroundColor ?? this.overlayBackgroundColor,
      overlayBorderColor: overlayBorderColor ?? this.overlayBorderColor,
      overlayBorderRadius: overlayBorderRadius ?? this.overlayBorderRadius,
      overlayElevation: overlayElevation ?? this.overlayElevation,
      overlayShadowColor: overlayShadowColor ?? this.overlayShadowColor,
      itemBackgroundColor: itemBackgroundColor ?? this.itemBackgroundColor,
      itemHoverColor: itemHoverColor ?? this.itemHoverColor,
      itemFocusedColor: itemFocusedColor ?? this.itemFocusedColor,
      itemSelectedColor: itemSelectedColor ?? this.itemSelectedColor,
      itemTextColor: itemTextColor ?? this.itemTextColor,
      itemSubtitleColor: itemSubtitleColor ?? this.itemSubtitleColor,
      itemIconColor: itemIconColor ?? this.itemIconColor,
      itemDividerColor: itemDividerColor ?? this.itemDividerColor,
      loadingIndicatorColor:
          loadingIndicatorColor ?? this.loadingIndicatorColor,
      emptyStateIconColor: emptyStateIconColor ?? this.emptyStateIconColor,
      emptyStateTextColor: emptyStateTextColor ?? this.emptyStateTextColor,
      errorIconColor: errorIconColor ?? this.errorIconColor,
      errorTextColor: errorTextColor ?? this.errorTextColor,
      errorButtonColor: errorButtonColor ?? this.errorButtonColor,
      scrollbarColor: scrollbarColor ?? this.scrollbarColor,
      scrollbarThickness: scrollbarThickness ?? this.scrollbarThickness,
      scrollbarRadius: scrollbarRadius ?? this.scrollbarRadius,
    );
  }

  @override
  SmartSearchTheme lerp(ThemeExtension<SmartSearchTheme>? other, double t) {
    if (other is! SmartSearchTheme) return this;

    return SmartSearchTheme(
      searchBoxBackgroundColor: Color.lerp(
          searchBoxBackgroundColor, other.searchBoxBackgroundColor, t),
      searchBoxTextColor:
          Color.lerp(searchBoxTextColor, other.searchBoxTextColor, t),
      searchBoxHintColor:
          Color.lerp(searchBoxHintColor, other.searchBoxHintColor, t),
      searchBoxBorderColor:
          Color.lerp(searchBoxBorderColor, other.searchBoxBorderColor, t),
      searchBoxFocusedBorderColor: Color.lerp(
          searchBoxFocusedBorderColor, other.searchBoxFocusedBorderColor, t),
      searchBoxIconColor:
          Color.lerp(searchBoxIconColor, other.searchBoxIconColor, t),
      searchBoxCursorColor:
          Color.lerp(searchBoxCursorColor, other.searchBoxCursorColor, t),
      searchBoxBorderRadius:
          BorderRadius.lerp(searchBoxBorderRadius, other.searchBoxBorderRadius, t),
      searchBoxElevation:
          lerpDouble(searchBoxElevation, other.searchBoxElevation, t),
      searchBoxShadowColor:
          Color.lerp(searchBoxShadowColor, other.searchBoxShadowColor, t),
      overlayBackgroundColor:
          Color.lerp(overlayBackgroundColor, other.overlayBackgroundColor, t),
      overlayBorderColor:
          Color.lerp(overlayBorderColor, other.overlayBorderColor, t),
      overlayBorderRadius:
          BorderRadius.lerp(overlayBorderRadius, other.overlayBorderRadius, t),
      overlayElevation: lerpDouble(overlayElevation, other.overlayElevation, t),
      overlayShadowColor:
          Color.lerp(overlayShadowColor, other.overlayShadowColor, t),
      itemBackgroundColor:
          Color.lerp(itemBackgroundColor, other.itemBackgroundColor, t),
      itemHoverColor: Color.lerp(itemHoverColor, other.itemHoverColor, t),
      itemFocusedColor: Color.lerp(itemFocusedColor, other.itemFocusedColor, t),
      itemSelectedColor:
          Color.lerp(itemSelectedColor, other.itemSelectedColor, t),
      itemTextColor: Color.lerp(itemTextColor, other.itemTextColor, t),
      itemSubtitleColor:
          Color.lerp(itemSubtitleColor, other.itemSubtitleColor, t),
      itemIconColor: Color.lerp(itemIconColor, other.itemIconColor, t),
      itemDividerColor: Color.lerp(itemDividerColor, other.itemDividerColor, t),
      loadingIndicatorColor:
          Color.lerp(loadingIndicatorColor, other.loadingIndicatorColor, t),
      emptyStateIconColor:
          Color.lerp(emptyStateIconColor, other.emptyStateIconColor, t),
      emptyStateTextColor:
          Color.lerp(emptyStateTextColor, other.emptyStateTextColor, t),
      errorIconColor: Color.lerp(errorIconColor, other.errorIconColor, t),
      errorTextColor: Color.lerp(errorTextColor, other.errorTextColor, t),
      errorButtonColor: Color.lerp(errorButtonColor, other.errorButtonColor, t),
      scrollbarColor: Color.lerp(scrollbarColor, other.scrollbarColor, t),
      scrollbarThickness:
          lerpDouble(scrollbarThickness, other.scrollbarThickness, t),
      scrollbarRadius: Radius.lerp(scrollbarRadius, other.scrollbarRadius, t),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! SmartSearchTheme) return false;

    return searchBoxBackgroundColor == other.searchBoxBackgroundColor &&
        searchBoxTextColor == other.searchBoxTextColor &&
        searchBoxHintColor == other.searchBoxHintColor &&
        searchBoxBorderColor == other.searchBoxBorderColor &&
        searchBoxFocusedBorderColor == other.searchBoxFocusedBorderColor &&
        searchBoxIconColor == other.searchBoxIconColor &&
        searchBoxCursorColor == other.searchBoxCursorColor &&
        searchBoxBorderRadius == other.searchBoxBorderRadius &&
        searchBoxElevation == other.searchBoxElevation &&
        searchBoxShadowColor == other.searchBoxShadowColor &&
        overlayBackgroundColor == other.overlayBackgroundColor &&
        overlayBorderColor == other.overlayBorderColor &&
        overlayBorderRadius == other.overlayBorderRadius &&
        overlayElevation == other.overlayElevation &&
        overlayShadowColor == other.overlayShadowColor &&
        itemBackgroundColor == other.itemBackgroundColor &&
        itemHoverColor == other.itemHoverColor &&
        itemFocusedColor == other.itemFocusedColor &&
        itemSelectedColor == other.itemSelectedColor &&
        itemTextColor == other.itemTextColor &&
        itemSubtitleColor == other.itemSubtitleColor &&
        itemIconColor == other.itemIconColor &&
        itemDividerColor == other.itemDividerColor &&
        loadingIndicatorColor == other.loadingIndicatorColor &&
        emptyStateIconColor == other.emptyStateIconColor &&
        emptyStateTextColor == other.emptyStateTextColor &&
        errorIconColor == other.errorIconColor &&
        errorTextColor == other.errorTextColor &&
        errorButtonColor == other.errorButtonColor &&
        scrollbarColor == other.scrollbarColor &&
        scrollbarThickness == other.scrollbarThickness &&
        scrollbarRadius == other.scrollbarRadius;
  }

  @override
  int get hashCode {
    return Object.hashAll([
      searchBoxBackgroundColor,
      searchBoxTextColor,
      searchBoxHintColor,
      searchBoxBorderColor,
      searchBoxFocusedBorderColor,
      searchBoxIconColor,
      searchBoxCursorColor,
      searchBoxBorderRadius,
      searchBoxElevation,
      searchBoxShadowColor,
      overlayBackgroundColor,
      overlayBorderColor,
      overlayBorderRadius,
      overlayElevation,
      overlayShadowColor,
      itemBackgroundColor,
      itemHoverColor,
      itemFocusedColor,
      itemSelectedColor,
      itemTextColor,
      itemSubtitleColor,
      itemIconColor,
      itemDividerColor,
      loadingIndicatorColor,
      emptyStateIconColor,
      emptyStateTextColor,
      errorIconColor,
      errorTextColor,
      errorButtonColor,
      scrollbarColor,
      scrollbarThickness,
      scrollbarRadius,
    ]);
  }
}
