import 'package:custom_pagination/pagination.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RetryConfig', () {
    test('should create with default values', () {
      const config = RetryConfig();

      expect(config.maxAttempts, equals(3));
      expect(config.initialDelay, equals(Duration(seconds: 1)));
      expect(config.maxDelay, equals(Duration(seconds: 10)));
      expect(config.timeoutDuration, equals(Duration(seconds: 30)));
      expect(config.shouldRetry, isNull);
    });

    test('should create with custom values', () {
      final config = RetryConfig(
        maxAttempts: 5,
        initialDelay: Duration(milliseconds: 500),
        maxDelay: Duration(seconds: 20),
        timeoutDuration: Duration(seconds: 60),
        shouldRetry: (error) => true,
      );

      expect(config.maxAttempts, equals(5));
      expect(config.initialDelay, equals(Duration(milliseconds: 500)));
      expect(config.maxDelay, equals(Duration(seconds: 20)));
      expect(config.timeoutDuration, equals(Duration(seconds: 60)));
      expect(config.shouldRetry, isNotNull);
    });

    test('should assert maxAttempts > 0', () {
      expect(
        () => RetryConfig(maxAttempts: 0),
        throwsA(isA<AssertionError>()),
      );

      expect(
        () => RetryConfig(maxAttempts: -1),
        throwsA(isA<AssertionError>()),
      );
    });

    test('should calculate exponential backoff delay', () {
      const config = RetryConfig(
        initialDelay: Duration(seconds: 1),
        maxDelay: Duration(seconds: 10),
      );

      expect(config.delayForAttempt(0), equals(Duration(seconds: 1)));
      expect(config.delayForAttempt(1), equals(Duration(seconds: 2)));
      expect(config.delayForAttempt(2), equals(Duration(seconds: 4)));
      expect(config.delayForAttempt(3), equals(Duration(seconds: 8)));
      // Should cap at maxDelay
      expect(config.delayForAttempt(4), equals(Duration(seconds: 10)));
      expect(config.delayForAttempt(5), equals(Duration(seconds: 10)));
    });

    test('should copy with new values', () {
      const config = RetryConfig(maxAttempts: 3);

      final copied = config.copyWith(
        maxAttempts: 5,
        initialDelay: Duration(milliseconds: 500),
      );

      expect(copied.maxAttempts, equals(5));
      expect(copied.initialDelay, equals(Duration(milliseconds: 500)));
      expect(copied.maxDelay, equals(Duration(seconds: 10))); // unchanged
    });
  });

  group('RetryHandler', () {
    test('should execute function successfully on first attempt', () async {
      const config = RetryConfig(maxAttempts: 3);
      final handler = RetryHandler(config);

      int callCount = 0;
      final result = await handler.execute(() async {
        callCount++;
        return 'success';
      });

      expect(result, equals('success'));
      expect(callCount, equals(1));
    });

    test('should retry on failure and succeed', () async {
      const config = RetryConfig(
        maxAttempts: 3,
        initialDelay: Duration(milliseconds: 10),
      );
      final handler = RetryHandler(config);

      int callCount = 0;
      final result = await handler.execute(() async {
        callCount++;
        if (callCount < 3) {
          throw Exception('Temporary error');
        }
        return 'success';
      });

      expect(result, equals('success'));
      expect(callCount, equals(3));
    });

    test('should exhaust all retries and throw', () async {
      const config = RetryConfig(
        maxAttempts: 3,
        initialDelay: Duration(milliseconds: 10),
      );
      final handler = RetryHandler(config);

      int callCount = 0;

      expect(
        handler.execute(() async {
          callCount++;
          throw Exception('Permanent error');
        }),
        throwsA(isA<PaginationRetryExhaustedException>()),
      );

      await Future.delayed(Duration(milliseconds: 200));
      expect(callCount, equals(3));
    });

    test('should handle timeout', () async {
      const config = RetryConfig(
        maxAttempts: 2,
        initialDelay: Duration(milliseconds: 10),
        timeoutDuration: Duration(milliseconds: 50),
      );
      final handler = RetryHandler(config);

      expect(
        handler.execute(() async {
          await Future.delayed(Duration(milliseconds: 100));
          return 'success';
        }),
        throwsA(isA<PaginationRetryExhaustedException>()),
      );
    });

    test('should call onRetry callback', () async {
      const config = RetryConfig(
        maxAttempts: 3,
        initialDelay: Duration(milliseconds: 10),
      );
      final handler = RetryHandler(config);

      final retryAttempts = <int>[];
      final retryErrors = <Exception>[];

      int callCount = 0;
      try {
        await handler.execute(
          () async {
            callCount++;
            throw Exception('Error $callCount');
          },
          onRetry: (attempt, error) {
            retryAttempts.add(attempt);
            retryErrors.add(error);
          },
        );
      } catch (e) {
        // Expected to fail
      }

      expect(retryAttempts, equals([1, 2])); // 2 retries after initial failure
      expect(retryErrors.length, equals(2));
    });

    test('should respect shouldRetry callback', () async {
      final config = RetryConfig(
        maxAttempts: 3,
        initialDelay: Duration(milliseconds: 10),
        shouldRetry: (error) {
          // Only retry network exceptions
          return error is PaginationNetworkException;
        },
      );
      final handler = RetryHandler(config);

      int callCount = 0;

      // Should not retry non-network errors
      expect(
        handler.execute(() async {
          callCount++;
          throw PaginationTimeoutException();
        }),
        throwsA(isA<PaginationRetryExhaustedException>()),
      );

      await Future.delayed(Duration(milliseconds: 50));
      expect(callCount, equals(1)); // No retries
    });

    test('should wrap unknown errors in PaginationNetworkException', () async {
      const config = RetryConfig(
        maxAttempts: 2,
        initialDelay: Duration(milliseconds: 10),
      );
      final handler = RetryHandler(config);

      try {
        await handler.execute(() async {
          throw 'Unknown error';
        });
        fail('Should have thrown');
      } on PaginationRetryExhaustedException catch (e) {
        expect(e.originalError, isA<PaginationNetworkException>());
      }
    });
  });

  group('PaginationException', () {
    test('PaginationTimeoutException should have correct message', () {
      const exception = PaginationTimeoutException(
        message: 'Request timed out after 30 seconds',
      );

      expect(exception.message, contains('timed out'));
      expect(exception.toString(), contains('PaginationTimeoutException'));
    });

    test('PaginationNetworkException should wrap original error', () {
      final originalError = Exception('Connection refused');
      final exception = PaginationNetworkException(
        message: 'Network request failed',
        originalError: originalError,
      );

      expect(exception.message, equals('Network request failed'));
      expect(exception.originalError, equals(originalError));
      expect(exception.toString(), contains('Connection refused'));
    });

    test('PaginationRetryExhaustedException should include attempts', () {
      const exception = PaginationRetryExhaustedException(
        attempts: 3,
        message: 'Failed after 3 attempts',
      );

      expect(exception.attempts, equals(3));
      expect(exception.toString(), contains('3 attempts'));
    });
  });
}
