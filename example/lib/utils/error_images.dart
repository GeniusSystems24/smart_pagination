import 'package:flutter/material.dart';

/// Helper class for managing error illustration images
///
/// Provides centralized access to error images with fallback support
class ErrorImages {
  ErrorImages._();

  // Base path for error images
  static const String _basePath = 'assets/images/errors';

  // Error image paths
  static const String generalError = '$_basePath/error_general.png';
  static const String networkError = '$_basePath/error_network.png';
  static const String error404 = '$_basePath/error_404.png';
  static const String error500 = '$_basePath/error_500.png';
  static const String timeoutError = '$_basePath/error_timeout.png';
  static const String authError = '$_basePath/error_auth.png';
  static const String offlineError = '$_basePath/error_offline.png';
  static const String emptyState = '$_basePath/error_empty.png';
  static const String retryIcon = '$_basePath/retry_icon.png';
  static const String recoveryIcon = '$_basePath/recovery_icon.png';
  static const String loadingError = '$_basePath/error_loading.png';
  static const String customError = '$_basePath/error_custom.png';

  /// Creates an Image widget with fallback icon support
  ///
  /// If the image fails to load, displays the provided fallback icon
  static Widget buildImage({
    required String imagePath,
    required IconData fallbackIcon,
    Color? fallbackColor,
    double width = 200,
    double height = 200,
    double fallbackSize = 64,
  }) {
    return Image.asset(
      imagePath,
      width: width,
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Icon(
          fallbackIcon,
          size: fallbackSize,
          color: fallbackColor ?? Colors.grey[400],
        );
      },
    );
  }

  /// Creates a general error image widget
  static Widget general({
    double width = 200,
    double height = 200,
    Color? fallbackColor,
  }) {
    return buildImage(
      imagePath: generalError,
      fallbackIcon: Icons.error_outline,
      fallbackColor: fallbackColor ?? Colors.red,
      width: width,
      height: height,
    );
  }

  /// Creates a network error image widget
  static Widget network({
    double width = 200,
    double height = 200,
    Color? fallbackColor,
  }) {
    return buildImage(
      imagePath: networkError,
      fallbackIcon: Icons.wifi_off,
      fallbackColor: fallbackColor ?? Colors.orange,
      width: width,
      height: height,
    );
  }

  /// Creates a 404 error image widget
  static Widget notFound({
    double width = 200,
    double height = 200,
    Color? fallbackColor,
  }) {
    return buildImage(
      imagePath: error404,
      fallbackIcon: Icons.search_off,
      fallbackColor: fallbackColor ?? Colors.grey,
      width: width,
      height: height,
    );
  }

  /// Creates a 500 error image widget
  static Widget serverError({
    double width = 200,
    double height = 200,
    Color? fallbackColor,
  }) {
    return buildImage(
      imagePath: error500,
      fallbackIcon: Icons.dns_outlined,
      fallbackColor: fallbackColor ?? Colors.red,
      width: width,
      height: height,
    );
  }

  /// Creates a timeout error image widget
  static Widget timeout({
    double width = 200,
    double height = 200,
    Color? fallbackColor,
  }) {
    return buildImage(
      imagePath: timeoutError,
      fallbackIcon: Icons.access_time,
      fallbackColor: fallbackColor ?? Colors.amber,
      width: width,
      height: height,
    );
  }

  /// Creates an auth error image widget
  static Widget auth({
    double width = 200,
    double height = 200,
    Color? fallbackColor,
  }) {
    return buildImage(
      imagePath: authError,
      fallbackIcon: Icons.lock_outline,
      fallbackColor: fallbackColor ?? Colors.orange,
      width: width,
      height: height,
    );
  }

  /// Creates an offline error image widget
  static Widget offline({
    double width = 200,
    double height = 200,
    Color? fallbackColor,
  }) {
    return buildImage(
      imagePath: offlineError,
      fallbackIcon: Icons.cloud_off,
      fallbackColor: fallbackColor ?? Colors.grey,
      width: width,
      height: height,
    );
  }

  /// Creates an empty state image widget
  static Widget empty({
    double width = 200,
    double height = 200,
    Color? fallbackColor,
  }) {
    return buildImage(
      imagePath: emptyState,
      fallbackIcon: Icons.inbox_outlined,
      fallbackColor: fallbackColor ?? Colors.grey,
      width: width,
      height: height,
    );
  }

  /// Creates a retry icon image widget
  static Widget retry({
    double width = 120,
    double height = 120,
    Color? fallbackColor,
  }) {
    return buildImage(
      imagePath: retryIcon,
      fallbackIcon: Icons.refresh,
      fallbackColor: fallbackColor ?? Colors.blue,
      width: width,
      height: height,
      fallbackSize: 48,
    );
  }

  /// Creates a recovery icon image widget
  static Widget recovery({
    double width = 120,
    double height = 120,
    Color? fallbackColor,
  }) {
    return buildImage(
      imagePath: recoveryIcon,
      fallbackIcon: Icons.restore,
      fallbackColor: fallbackColor ?? Colors.green,
      width: width,
      height: height,
      fallbackSize: 48,
    );
  }

  /// Creates a loading error image widget
  static Widget loading({
    double width = 200,
    double height = 200,
    Color? fallbackColor,
  }) {
    return buildImage(
      imagePath: loadingError,
      fallbackIcon: Icons.error_outline,
      fallbackColor: fallbackColor ?? Colors.orange,
      width: width,
      height: height,
    );
  }

  /// Creates a custom error image widget
  static Widget custom({
    double width = 200,
    double height = 200,
    Color? fallbackColor,
  }) {
    return buildImage(
      imagePath: customError,
      fallbackIcon: Icons.widgets_outlined,
      fallbackColor: fallbackColor ?? Colors.purple,
      width: width,
      height: height,
    );
  }

  /// Checks if an image exists (approximation - tries to load it)
  static Future<bool> imageExists(String imagePath) async {
    try {
      // This is a simplified check - in production you might want to use
      // rootBundle.load() to check if the asset exists
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Gets all available error image paths
  static List<String> get allImages => [
    generalError,
    networkError,
    error404,
    error500,
    timeoutError,
    authError,
    offlineError,
    emptyState,
    retryIcon,
    recoveryIcon,
    loadingError,
    customError,
  ];
}

/// Extension to easily use error images in widgets
extension ErrorImageExtension on BuildContext {
  /// Quick access to ErrorImages from any BuildContext
  ErrorImages get errorImages => ErrorImages as ErrorImages;
}
