import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_pagination/pagination.dart';

void main() {
  Future<void> waitForState<T>(
    SmartPaginationCubit<T> cubit,
    bool Function(SmartPaginationState<T> state) predicate, {
    Duration timeout = const Duration(seconds: 2),
  }) async {
    final stopwatch = Stopwatch()..start();
    while (!predicate(cubit.state)) {
      if (stopwatch.elapsed > timeout) {
        fail(
          'Timed out waiting for cubit state. Last state: ${cubit.state.runtimeType}',
        );
      }
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
  }

  SmartPaginationCubit<int> createCubit(
    Future<List<int>> Function(PaginationRequest request) provider,
  ) {
    return SmartPaginationCubit<int>(
      request: const PaginationRequest(page: 1, pageSize: 2),
      provider: PaginationProvider<int>.future(provider),
    );
  }

  group('SmartPaginationCubit retry behavior', () {
    test('fetchPaginatedList does not auto-retry after an error', () async {
      var calls = 0;
      final cubit = createCubit((request) async {
        calls++;
        throw Exception('boom');
      });
      addTearDown(cubit.dispose);

      cubit.fetchPaginatedList();
      await waitForState<int>(
        cubit,
        (state) => state is SmartPaginationError<int>,
      );
      expect(calls, 1);
      expect(cubit.hasError, isTrue);

      cubit.fetchPaginatedList();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(calls, 1);
      expect(cubit.state, isA<SmartPaginationError<int>>());
    });

    test('retryAfterError retries failed initial load', () async {
      var calls = 0;
      final cubit = createCubit((request) async {
        calls++;
        if (calls == 1) {
          throw Exception('first failure');
        }
        return <int>[1, 2];
      });
      addTearDown(cubit.dispose);

      cubit.fetchPaginatedList();
      await waitForState<int>(
        cubit,
        (state) => state is SmartPaginationError<int>,
      );
      expect(calls, 1);

      cubit.retryAfterError();
      await waitForState<int>(
        cubit,
        (state) => state is SmartPaginationLoaded<int>,
      );

      final loaded = cubit.state as SmartPaginationLoaded<int>;
      expect(calls, 2);
      expect(loaded.items, <int>[1, 2]);
      expect(cubit.hasError, isFalse);
    });

    test(
      'retryAfterError retries failed load-more and keeps pagination flow',
      () async {
        var calls = 0;
        final cubit = createCubit((request) async {
          calls++;
          if (calls == 1) {
            return <int>[1, 2];
          }
          if (calls == 2) {
            throw Exception('load more failed');
          }
          return <int>[3, 4];
        });
        addTearDown(cubit.dispose);

        cubit.fetchPaginatedList();
        await waitForState<int>(
          cubit,
          (state) =>
              state is SmartPaginationLoaded<int> && state.items.length == 2,
        );

        cubit.fetchPaginatedList();
        await waitForState<int>(
          cubit,
          (state) =>
              state is SmartPaginationLoaded<int> &&
              state.loadMoreError != null,
        );

        expect(calls, 2);
        expect(cubit.hasError, isTrue);

        cubit.fetchPaginatedList();
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(calls, 2);

        cubit.retryAfterError();
        await waitForState<int>(
          cubit,
          (state) =>
              state is SmartPaginationLoaded<int> &&
              state.items.length == 4 &&
              state.loadMoreError == null,
        );

        final loaded = cubit.state as SmartPaginationLoaded<int>;
        expect(calls, 3);
        expect(loaded.items, <int>[1, 2, 3, 4]);
        expect(cubit.hasError, isFalse);
      },
    );
  });

  test(
    'removed auto-retry/connectivity API symbols are absent from source',
    () {
      final cubitSource = File(
        'lib/smart_pagination/bloc/pagination_cubit.dart',
      ).readAsStringSync();
      final widgetSource = File(
        'lib/smart_pagination/pagination.dart',
      ).readAsStringSync();

      expect(cubitSource.contains('enum ErrorRetryStrategy'), isFalse);
      expect(cubitSource.contains('errorRetryStrategy'), isFalse);
      expect(cubitSource.contains('connectivityStream'), isFalse);
      expect(cubitSource.contains('onConnectivityRestored('), isFalse);

      expect(widgetSource.contains('preserveCenteredItemOnInsert'), isTrue);
    },
  );
}
