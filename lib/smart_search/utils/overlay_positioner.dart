part of '../../pagination.dart';

/// Calculated position and size for the overlay.
class OverlayPositionData {
  const OverlayPositionData({
    required this.offset,
    required this.size,
    required this.resolvedPosition,
  });

  /// The offset from the top-left of the screen.
  final Offset offset;

  /// The calculated size of the overlay.
  final Size size;

  /// The resolved position (useful when auto was specified).
  final OverlayPosition resolvedPosition;
}

/// Utility class for calculating overlay position.
class OverlayPositioner {
  const OverlayPositioner._();

  /// Calculates the best position for the overlay based on available space.
  ///
  /// [targetRect] - The rectangle of the search box.
  /// [overlaySize] - The desired size of the overlay.
  /// [screenSize] - The size of the screen.
  /// [config] - The overlay configuration.
  /// [padding] - Safe area padding to avoid.
  static OverlayPositionData calculatePosition({
    required Rect targetRect,
    required Size overlaySize,
    required Size screenSize,
    required SmartSearchOverlayConfig config,
    EdgeInsets padding = EdgeInsets.zero,
  }) {
    final position = config.position;
    final offset = config.offset;

    // Calculate available space in each direction
    final spaceAbove = targetRect.top - padding.top;
    final spaceBelow = screenSize.height - targetRect.bottom - padding.bottom;
    final spaceLeft = targetRect.left - padding.left;
    final spaceRight = screenSize.width - targetRect.right - padding.right;

    // Determine the best position if auto
    OverlayPosition resolvedPosition;
    if (position == OverlayPosition.auto) {
      resolvedPosition = _findBestPosition(
        overlaySize: overlaySize,
        spaceAbove: spaceAbove,
        spaceBelow: spaceBelow,
        spaceLeft: spaceLeft,
        spaceRight: spaceRight,
        offset: offset,
      );
    } else {
      resolvedPosition = position;
    }

    // Calculate the actual position and size
    return _calculatePositionData(
      targetRect: targetRect,
      overlaySize: overlaySize,
      screenSize: screenSize,
      config: config,
      padding: padding,
      resolvedPosition: resolvedPosition,
      spaceAbove: spaceAbove,
      spaceBelow: spaceBelow,
      spaceLeft: spaceLeft,
      spaceRight: spaceRight,
    );
  }

  static OverlayPosition _findBestPosition({
    required Size overlaySize,
    required double spaceAbove,
    required double spaceBelow,
    required double spaceLeft,
    required double spaceRight,
    required double offset,
  }) {
    final requiredHeight = overlaySize.height + offset;
    final requiredWidth = overlaySize.width + offset;

    // Priority: bottom > top > right > left
    // Check if the overlay fits in each direction
    final fitsBelow = spaceBelow >= requiredHeight;
    final fitsAbove = spaceAbove >= requiredHeight;
    final fitsRight = spaceRight >= requiredWidth;
    final fitsLeft = spaceLeft >= requiredWidth;

    if (fitsBelow) return OverlayPosition.bottom;
    if (fitsAbove) return OverlayPosition.top;
    if (fitsRight) return OverlayPosition.right;
    if (fitsLeft) return OverlayPosition.left;

    // If nothing fits perfectly, choose the direction with most space
    final spaces = {
      OverlayPosition.bottom: spaceBelow,
      OverlayPosition.top: spaceAbove,
      OverlayPosition.right: spaceRight,
      OverlayPosition.left: spaceLeft,
    };

    return spaces.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  static OverlayPositionData _calculatePositionData({
    required Rect targetRect,
    required Size overlaySize,
    required Size screenSize,
    required SmartSearchOverlayConfig config,
    required EdgeInsets padding,
    required OverlayPosition resolvedPosition,
    required double spaceAbove,
    required double spaceBelow,
    required double spaceLeft,
    required double spaceRight,
  }) {
    final offset = config.offset;
    final maxHeight = config.maxHeight;
    final maxWidth = config.maxWidth ?? targetRect.width;

    double dx, dy;
    double width, height;

    switch (resolvedPosition) {
      case OverlayPosition.bottom:
        dx = targetRect.left;
        dy = targetRect.bottom + offset;
        width = math.min(maxWidth, screenSize.width - dx - padding.right);
        height = math.min(maxHeight, spaceBelow - offset);
        break;

      case OverlayPosition.top:
        dx = targetRect.left;
        height = math.min(maxHeight, spaceAbove - offset);
        dy = targetRect.top - offset - height;
        width = math.min(maxWidth, screenSize.width - dx - padding.right);
        break;

      case OverlayPosition.right:
        dx = targetRect.right + offset;
        dy = targetRect.top;
        width = math.min(maxWidth, spaceRight - offset);
        height = math.min(maxHeight, screenSize.height - dy - padding.bottom);
        break;

      case OverlayPosition.left:
        width = math.min(maxWidth, spaceLeft - offset);
        dx = targetRect.left - offset - width;
        dy = targetRect.top;
        height = math.min(maxHeight, screenSize.height - dy - padding.bottom);
        break;

      case OverlayPosition.auto:
        // This shouldn't happen as auto should be resolved above
        dx = targetRect.left;
        dy = targetRect.bottom + offset;
        width = maxWidth;
        height = maxHeight;
        break;
    }

    // Ensure we don't go off screen
    dx = dx.clamp(padding.left, screenSize.width - width - padding.right);
    dy = dy.clamp(padding.top, screenSize.height - height - padding.bottom);
    width = math.max(0, width);
    height = math.max(0, height);

    return OverlayPositionData(
      offset: Offset(dx, dy),
      size: Size(width, height),
      resolvedPosition: resolvedPosition,
    );
  }
}
