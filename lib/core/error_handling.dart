import 'dart:async';

/// Configuration for retry behavior.
///
/// Defines how pagination should retry failed requests with exponential backoff.
///
/// Example:
/// ```dart
/// final retryConfig = RetryConfig(
///   maxAttempts: 3,
///   initialDelay: Duration(seconds: 1),
///   maxDelay: Duration(seconds: 10),
///   timeoutDuration: Duration(seconds: 30),
/// );
/// ```
class RetryConfig {
  const RetryConfig({
    this.maxAttempts = 3,
    this.initialDelay = const Duration(seconds: 1),
    this.maxDelay = const Duration(seconds: 10),
    this.timeoutDuration = const Duration(seconds: 30),
    this.shouldRetry,
  }) : assert(maxAttempts > 0, 'maxAttempts must be greater than 0');

  /// Maximum number of retry attempts before giving up.
  final int maxAttempts;

  /// Initial delay before the first retry.
  final Duration initialDelay;

  /// Maximum delay between retries (for exponential backoff).
  final Duration maxDelay;

  /// Timeout duration for each request attempt.
  final Duration timeoutDuration;

  /// Optional callback to determine if a specific error should trigger a retry.
  ///
  /// If null, all errors will trigger a retry (up to maxAttempts).
  /// Return true to retry, false to fail immediately.
  final bool Function(Exception error)? shouldRetry;

  /// Calculates the delay for a specific attempt using exponential backoff.
  ///
  /// Formula: min(initialDelay * 2^attempt, maxDelay)
  Duration delayForAttempt(int attempt) {
    final exponentialDelay = initialDelay * (1 << attempt);
    return exponentialDelay > maxDelay ? maxDelay : exponentialDelay;
  }

  /// Creates a copy with updated values.
  RetryConfig copyWith({
    int? maxAttempts,
    Duration? initialDelay,
    Duration? maxDelay,
    Duration? timeoutDuration,
    bool Function(Exception error)? shouldRetry,
  }) {
    return RetryConfig(
      maxAttempts: maxAttempts ?? this.maxAttempts,
      initialDelay: initialDelay ?? this.initialDelay,
      maxDelay: maxDelay ?? this.maxDelay,
      timeoutDuration: timeoutDuration ?? this.timeoutDuration,
      shouldRetry: shouldRetry ?? this.shouldRetry,
    );
  }
}

/// Custom exception types for pagination errors.
///
/// Provides more specific error information than generic Exception.
abstract class PaginationException implements Exception {
  const PaginationException(this.message, {this.originalError, this.stackTrace});

  final String message;
  final Object? originalError;
  final StackTrace? stackTrace;

  @override
  String toString() {
    if (originalError != null) {
      return '$runtimeType: $message\nOriginal error: $originalError';
    }
    return '$runtimeType: $message';
  }
}

/// Exception thrown when a network request times out.
class PaginationTimeoutException extends PaginationException {
  const PaginationTimeoutException({
    String message = 'Request timed out',
    Object? originalError,
    StackTrace? stackTrace,
  }) : super(message, originalError: originalError, stackTrace: stackTrace);
}

/// Exception thrown when a network request fails.
class PaginationNetworkException extends PaginationException {
  const PaginationNetworkException({
    String message = 'Network request failed',
    Object? originalError,
    StackTrace? stackTrace,
  }) : super(message, originalError: originalError, stackTrace: stackTrace);
}

/// Exception thrown when data parsing fails.
class PaginationParseException extends PaginationException {
  const PaginationParseException({
    String message = 'Failed to parse data',
    Object? originalError,
    StackTrace? stackTrace,
  }) : super(message, originalError: originalError, stackTrace: stackTrace);
}

/// Exception thrown when all retry attempts have been exhausted.
class PaginationRetryExhaustedException extends PaginationException {
  const PaginationRetryExhaustedException({
    required this.attempts,
    String message = 'All retry attempts exhausted',
    Object? originalError,
    StackTrace? stackTrace,
  }) : super(message, originalError: originalError, stackTrace: stackTrace);

  /// The number of attempts that were made.
  final int attempts;

  @override
  String toString() {
    return 'PaginationRetryExhaustedException: $message after $attempts attempts\n'
        'Original error: $originalError';
  }
}

/// Utility class for executing functions with retry and timeout logic.
class RetryHandler {
  const RetryHandler(this.config);

  final RetryConfig config;

  /// Executes a function with retry and timeout logic.
  ///
  /// Returns the result if successful, throws an exception if all retries fail.
  ///
  /// Example:
  /// ```dart
  /// final handler = RetryHandler(RetryConfig(maxAttempts: 3));
  ///
  /// final data = await handler.execute(
  ///   () => fetchData(),
  ///   onRetry: (attempt, error) {
  ///     print('Retry attempt $attempt after error: $error');
  ///   },
  /// );
  /// ```
  Future<T> execute<T>(
    Future<T> Function() function, {
    void Function(int attempt, Exception error)? onRetry,
  }) async {
    Exception? lastError;

    for (int attempt = 0; attempt < config.maxAttempts; attempt++) {
      try {
        // Add timeout to the function
        final result = await function().timeout(
          config.timeoutDuration,
          onTimeout: () {
            throw TimeoutException(
              'Request timed out after ${config.timeoutDuration.inSeconds} seconds',
            );
          },
        );

        return result;
      } on TimeoutException catch (e, stack) {
        lastError = PaginationTimeoutException(
          message: e.message ?? 'Request timed out',
          originalError: e,
          stackTrace: stack,
        );
      } on PaginationException catch (e) {
        lastError = e;
      } catch (e, stack) {
        // Wrap unknown errors
        lastError = PaginationNetworkException(
          message: 'Unexpected error: ${e.toString()}',
          originalError: e,
          stackTrace: stack,
        );
      }

      // Check if we should retry
      final shouldRetry = config.shouldRetry?.call(lastError) ?? true;

      if (!shouldRetry || attempt == config.maxAttempts - 1) {
        // Don't retry or this was the last attempt
        break;
      }

      // Notify about retry
      onRetry?.call(attempt + 1, lastError);

      // Wait before retrying
      final delay = config.delayForAttempt(attempt);
      await Future.delayed(delay);
    }

    // All retries exhausted
    throw PaginationRetryExhaustedException(
      attempts: config.maxAttempts,
      message: 'Failed after ${config.maxAttempts} attempts',
      originalError: lastError,
      // stackTrace: lastError?.stackTrace,
    );
  }
}
