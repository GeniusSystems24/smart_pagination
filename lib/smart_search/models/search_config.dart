part of '../../pagination.dart';

/// Display mode for search dropdowns.
enum SearchDisplayMode {
  /// Shows results in an overlay dropdown below/above the search box.
  overlay,

  /// Opens a fullscreen page for search and selection.
  /// Better for mobile devices and complex selection scenarios.
  bottomSheet,
}

/// Animation types for overlay show/hide transitions.
enum OverlayAnimationType {
  /// Simple fade in/out animation.
  fade,

  /// Scale animation from center.
  scale,

  /// Scale with fade combined.
  fadeScale,

  /// Slide from top with fade.
  slideDown,

  /// Slide from bottom with fade.
  slideUp,

  /// Slide from left with fade.
  slideLeft,

  /// Slide from right with fade.
  slideRight,

  /// Bounce scale animation.
  bounceScale,

  /// Elastic scale animation.
  elasticScale,

  /// Flip animation on X axis.
  flipX,

  /// Flip animation on Y axis.
  flipY,

  /// Zoom in animation.
  zoomIn,

  /// No animation (instant show/hide).
  none,
}

/// Configuration for search behavior.
class SmartSearchConfig {
  const SmartSearchConfig({
    this.debounceDelay = const Duration(seconds: 1),
    this.minSearchLength = 0,
    this.searchOnEmpty = true,
    this.skipDebounceOnEmpty = true,
    this.clearOnClose = true,
    this.autoFocus = false,
  });

  /// Delay before triggering search after user stops typing (default: 1 second).
  final Duration debounceDelay;

  /// Minimum characters required to trigger search (default: 0 - search on any input).
  final int minSearchLength;

  /// Whether to trigger search when input is empty (default: true - fetch all data).
  final bool searchOnEmpty;

  /// Whether to skip debounce delay when search text is empty (default: true).
  /// When true and [searchOnEmpty] is also true, the search will be triggered
  /// immediately when the text becomes empty, without waiting for the debounce delay.
  /// This is useful for showing all data immediately when the user clears the search.
  final bool skipDebounceOnEmpty;

  /// Whether to clear search text when overlay is closed.
  final bool clearOnClose;

  /// Whether to auto-focus the search field.
  final bool autoFocus;

  SmartSearchConfig copyWith({
    Duration? debounceDelay,
    int? minSearchLength,
    bool? searchOnEmpty,
    bool? skipDebounceOnEmpty,
    bool? clearOnClose,
    bool? autoFocus,
  }) {
    return SmartSearchConfig(
      debounceDelay: debounceDelay ?? this.debounceDelay,
      minSearchLength: minSearchLength ?? this.minSearchLength,
      searchOnEmpty: searchOnEmpty ?? this.searchOnEmpty,
      skipDebounceOnEmpty: skipDebounceOnEmpty ?? this.skipDebounceOnEmpty,
      clearOnClose: clearOnClose ?? this.clearOnClose,
      autoFocus: autoFocus ?? this.autoFocus,
    );
  }
}

/// Position preference for the search overlay.
enum OverlayPosition {
  /// Automatically choose the best position based on available space.
  auto,

  /// Position the overlay above the search box.
  top,

  /// Position the overlay below the search box.
  bottom,

  /// Position the overlay to the left of the search box.
  left,

  /// Position the overlay to the right of the search box.
  right,
}

/// Configuration for the search overlay appearance and behavior.
class SmartSearchOverlayConfig {
  const SmartSearchOverlayConfig({
    this.position = OverlayPosition.auto,
    this.maxHeight = 300.0,
    this.maxWidth,
    this.offset = 4.0,
    this.borderRadius = 8.0,
    this.elevation = 8.0,
    this.barrierColor,
    this.barrierDismissible = true,
    this.animationDuration = const Duration(milliseconds: 200),
    this.animationType = OverlayAnimationType.fade,
    this.animationCurve = Curves.easeOutCubic,
    this.constraints,
    this.followTargetOnScroll = true,
  });

  /// Preferred position for the overlay.
  final OverlayPosition position;

  /// Maximum height of the overlay.
  final double maxHeight;

  /// Maximum width of the overlay. If null, uses the search box width.
  final double? maxWidth;

  /// Gap between search box and overlay.
  final double offset;

  /// Border radius of the overlay.
  final double borderRadius;

  /// Elevation/shadow of the overlay.
  final double elevation;

  /// Color of the barrier behind the overlay. If null, no barrier is shown.
  final Color? barrierColor;

  /// Whether tapping the barrier dismisses the overlay.
  final bool barrierDismissible;

  /// Duration of the show/hide animation.
  final Duration animationDuration;

  /// Type of animation for show/hide transitions.
  final OverlayAnimationType animationType;

  /// Animation curve for the transition.
  final Curve animationCurve;

  /// Additional constraints for the overlay.
  final BoxConstraints? constraints;

  /// Whether the overlay should follow the target widget when scrolling.
  /// When true, the overlay position updates in real-time as the user scrolls.
  /// Default is true for better UX with scrollable content.
  final bool followTargetOnScroll;

  SmartSearchOverlayConfig copyWith({
    OverlayPosition? position,
    double? maxHeight,
    double? maxWidth,
    double? offset,
    double? borderRadius,
    double? elevation,
    Color? barrierColor,
    bool? barrierDismissible,
    Duration? animationDuration,
    OverlayAnimationType? animationType,
    Curve? animationCurve,
    BoxConstraints? constraints,
    bool? followTargetOnScroll,
  }) {
    return SmartSearchOverlayConfig(
      position: position ?? this.position,
      maxHeight: maxHeight ?? this.maxHeight,
      maxWidth: maxWidth ?? this.maxWidth,
      offset: offset ?? this.offset,
      borderRadius: borderRadius ?? this.borderRadius,
      elevation: elevation ?? this.elevation,
      barrierColor: barrierColor ?? this.barrierColor,
      barrierDismissible: barrierDismissible ?? this.barrierDismissible,
      animationDuration: animationDuration ?? this.animationDuration,
      animationType: animationType ?? this.animationType,
      animationCurve: animationCurve ?? this.animationCurve,
      constraints: constraints ?? this.constraints,
      followTargetOnScroll: followTargetOnScroll ?? this.followTargetOnScroll,
    );
  }
}

/// Configuration for the bottom sheet search appearance.
class SmartSearchBottomSheetConfig {
  const SmartSearchBottomSheetConfig({
    this.title,
    this.titleBuilder,
    this.confirmText = 'Done',
    this.cancelText = 'Cancel',
    this.showConfirmButton = true,
    this.showCancelButton = true,
    this.showSelectedCount = true,
    this.showClearAllButton = true,
    this.clearAllText = 'Clear All',
    this.heightFactor = 0.85,
    this.borderRadius = const BorderRadius.vertical(top: Radius.circular(16)),
    this.backgroundColor,
    this.barrierColor,
    this.enableDrag = true,
    this.isScrollControlled = true,
    this.useSafeArea = true,
    this.showDragHandle = true,
  });

  /// Title for the bottom sheet.
  final String? title;

  /// Builder for custom title widget.
  final Widget Function(int selectedCount)? titleBuilder;

  /// Text for the confirm button.
  final String confirmText;

  /// Text for the cancel button.
  final String cancelText;

  /// Whether to show the confirm button.
  final bool showConfirmButton;

  /// Whether to show the cancel button.
  final bool showCancelButton;

  /// Whether to show the selected count in the title.
  final bool showSelectedCount;

  /// Whether to show the clear all button.
  final bool showClearAllButton;

  /// Text for the clear all button.
  final String clearAllText;

  /// Height factor for the bottom sheet (0.0 to 1.0).
  final double heightFactor;

  /// Border radius for the bottom sheet.
  final BorderRadius borderRadius;

  /// Background color for the bottom sheet.
  final Color? backgroundColor;

  /// Barrier color behind the bottom sheet.
  final Color? barrierColor;

  /// Whether the bottom sheet can be dragged.
  final bool enableDrag;

  /// Whether the bottom sheet should be scrollable.
  final bool isScrollControlled;

  /// Whether to use safe area.
  final bool useSafeArea;

  /// Whether to show the drag handle.
  final bool showDragHandle;

  SmartSearchBottomSheetConfig copyWith({
    String? title,
    Widget Function(int selectedCount)? titleBuilder,
    String? confirmText,
    String? cancelText,
    bool? showConfirmButton,
    bool? showCancelButton,
    bool? showSelectedCount,
    bool? showClearAllButton,
    String? clearAllText,
    double? heightFactor,
    BorderRadius? borderRadius,
    Color? backgroundColor,
    Color? barrierColor,
    bool? enableDrag,
    bool? isScrollControlled,
    bool? useSafeArea,
    bool? showDragHandle,
  }) {
    return SmartSearchBottomSheetConfig(
      title: title ?? this.title,
      titleBuilder: titleBuilder ?? this.titleBuilder,
      confirmText: confirmText ?? this.confirmText,
      cancelText: cancelText ?? this.cancelText,
      showConfirmButton: showConfirmButton ?? this.showConfirmButton,
      showCancelButton: showCancelButton ?? this.showCancelButton,
      showSelectedCount: showSelectedCount ?? this.showSelectedCount,
      showClearAllButton: showClearAllButton ?? this.showClearAllButton,
      clearAllText: clearAllText ?? this.clearAllText,
      heightFactor: heightFactor ?? this.heightFactor,
      borderRadius: borderRadius ?? this.borderRadius,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      barrierColor: barrierColor ?? this.barrierColor,
      enableDrag: enableDrag ?? this.enableDrag,
      isScrollControlled: isScrollControlled ?? this.isScrollControlled,
      useSafeArea: useSafeArea ?? this.useSafeArea,
      showDragHandle: showDragHandle ?? this.showDragHandle,
    );
  }
}
