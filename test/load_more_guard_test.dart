// Spec 003-load-more-guard — Cubit-level load-more guard tests.
//
// Covers user stories US1 (single active request), US2 (end-of-list),
// US3 (error recovery), US4 (state reset). Tests T01–T13 from plan §12.
//
// Pattern: every test waits via `Future.delayed` then asserts on
// `cubit.state` directly. `firstWhere` on a broadcast stream is brittle when
// the matching state has already been emitted before the listener attaches.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_pagination/pagination.dart';

const _settle = Duration(milliseconds: 50);

void main() {
  group('Load-More Guard (spec 003)', () {
    // -----------------------------------------------------------------------
    // US1: Single active request guard
    // -----------------------------------------------------------------------

    test('T01: 10 rapid fetchPaginatedList calls produce exactly 1 provider '
        'call', () async {
      var providerCallCount = 0;
      final cubit = SmartPaginationCubit<int, PaginationRequest>(
        request: PaginationRequest(page: 1, pageSize: 10),
        provider: PaginationProvider<int, PaginationRequest>.future((req) async {
          providerCallCount++;
          return List<int>.generate(10, (i) => (req.page - 1) * 10 + i);
        }),
      );

      cubit.refreshPaginatedList();
      await Future<void>.delayed(_settle);
      providerCallCount = 0;

      for (var i = 0; i < 10; i++) {
        cubit.fetchPaginatedList();
      }
      await Future<void>.delayed(_settle);

      expect(providerCallCount, 1,
          reason: '10 rapid calls must collapse to 1 provider call');
      expect(cubit.state, isA<SmartPaginationLoaded<int>>());
      final loaded = cubit.state as SmartPaginationLoaded<int>;
      expect(loaded.items.length, 20);
      expect(loaded.isLoadingMore, isFalse);

      await cubit.close();
    });

    test('T02: second call during in-flight load-more is dropped', () async {
      final completer = Completer<List<int>>();
      var providerCallCount = 0;
      final cubit = SmartPaginationCubit<int, PaginationRequest>(
        request: PaginationRequest(page: 1, pageSize: 5),
        provider: PaginationProvider<int, PaginationRequest>.future((req) async {
          providerCallCount++;
          if (req.page == 1) return [0, 1, 2, 3, 4];
          return completer.future;
        }),
      );

      cubit.refreshPaginatedList();
      await Future<void>.delayed(_settle);
      providerCallCount = 0;

      cubit.fetchPaginatedList(); // start in-flight
      await Future<void>.delayed(Duration.zero);
      cubit.fetchPaginatedList(); // must be dropped
      await Future<void>.delayed(_settle);

      expect(providerCallCount, 1);

      completer.complete([5, 6, 7, 8, 9]);
      await Future<void>.delayed(_settle);

      final loaded = cubit.state as SmartPaginationLoaded<int>;
      expect(loaded.items.length, 10);
      expect(loaded.isLoadingMore, isFalse);

      await cubit.close();
    });

    test('T03: same page is never fetched by two concurrent calls', () async {
      final pageCallCounts = <int, int>{};
      final completers = <int, Completer<List<int>>>{};
      final cubit = SmartPaginationCubit<int, PaginationRequest>(
        request: PaginationRequest(page: 1, pageSize: 5),
        provider: PaginationProvider<int, PaginationRequest>.future((req) async {
          pageCallCounts.update(req.page, (v) => v + 1, ifAbsent: () => 1);
          if (req.page == 1) return [0, 1, 2, 3, 4];
          completers.putIfAbsent(req.page, () => Completer<List<int>>());
          return completers[req.page]!.future;
        }),
      );

      cubit.refreshPaginatedList();
      await Future<void>.delayed(_settle);

      cubit.fetchPaginatedList();
      cubit.fetchPaginatedList();
      await Future<void>.delayed(_settle);

      expect(pageCallCounts[2], 1,
          reason: 'page 2 must be fetched once even with concurrent triggers');

      completers[2]!.complete([5, 6, 7, 8, 9]);
      await Future<void>.delayed(_settle);

      await cubit.close();
    });

    test('T04: success clears guards so the next page can load', () async {
      var providerCallCount = 0;
      final cubit = SmartPaginationCubit<int, PaginationRequest>(
        request: PaginationRequest(page: 1, pageSize: 5),
        provider: PaginationProvider<int, PaginationRequest>.future((req) async {
          providerCallCount++;
          return List<int>.generate(5, (i) => (req.page - 1) * 5 + i);
        }),
      );

      cubit.refreshPaginatedList();
      await Future<void>.delayed(_settle);

      cubit.fetchPaginatedList(); // page 2
      await Future<void>.delayed(_settle);
      final beforePage3 = providerCallCount;

      cubit.fetchPaginatedList(); // page 3
      await Future<void>.delayed(_settle);

      expect(providerCallCount, beforePage3 + 1,
          reason: 'next page key must not be blocked after success');
      final loaded = cubit.state as SmartPaginationLoaded<int>;
      expect(loaded.items.length, 15);

      await cubit.close();
    });

    // -----------------------------------------------------------------------
    // US3: Error recovery — error must NOT mark hasReachedEnd
    // -----------------------------------------------------------------------

    test('T05: load-more error clears guards but not hasReachedEnd', () async {
      var attempt = 0;
      final cubit = SmartPaginationCubit<int, PaginationRequest>(
        request: PaginationRequest(page: 1, pageSize: 5),
        errorRetryStrategy: ErrorRetryStrategy.automatic,
        provider: PaginationProvider<int, PaginationRequest>.future((req) async {
          attempt++;
          if (attempt == 1) return [0, 1, 2, 3, 4];
          throw PaginationNetworkException(message: 'boom');
        }),
      );

      cubit.refreshPaginatedList();
      await Future<void>.delayed(_settle);
      cubit.fetchPaginatedList();
      await Future<void>.delayed(_settle);

      final loaded = cubit.state as SmartPaginationLoaded<int>;
      expect(loaded.hasReachedEnd, isFalse);
      expect(loaded.loadMoreError, isNotNull);
      expect(loaded.isLoadingMore, isFalse);

      await cubit.close();
    });

    test('T06: retry after load-more error succeeds', () async {
      var attempt = 0;
      final cubit = SmartPaginationCubit<int, PaginationRequest>(
        request: PaginationRequest(page: 1, pageSize: 5),
        errorRetryStrategy: ErrorRetryStrategy.manual,
        provider: PaginationProvider<int, PaginationRequest>.future((req) async {
          attempt++;
          if (req.page == 1) return [0, 1, 2, 3, 4];
          if (attempt == 2) {
            throw PaginationNetworkException(message: 'first try');
          }
          return [5, 6, 7, 8, 9];
        }),
      );

      cubit.refreshPaginatedList();
      await Future<void>.delayed(_settle);

      cubit.fetchPaginatedList(); // attempt 2 — fails
      await Future<void>.delayed(_settle);
      expect((cubit.state as SmartPaginationLoaded<int>).loadMoreError,
          isNotNull);

      cubit.retryAfterError();
      await Future<void>.delayed(_settle);

      final loaded = cubit.state as SmartPaginationLoaded<int>;
      expect(loaded.items.length, 10);
      expect(loaded.loadMoreError, isNull);

      await cubit.close();
    });

    // -----------------------------------------------------------------------
    // US2: End-of-list detection
    // -----------------------------------------------------------------------

    test('T07: empty load-more response sets hasReachedEnd, no append',
        () async {
      var providerCalls = 0;
      final cubit = SmartPaginationCubit<int, PaginationRequest>(
        request: PaginationRequest(page: 1, pageSize: 10),
        provider: PaginationProvider<int, PaginationRequest>.future((req) async {
          providerCalls++;
          if (req.page == 1) return List<int>.generate(10, (i) => i);
          return <int>[];
        }),
      );

      cubit.refreshPaginatedList();
      await Future<void>.delayed(_settle);
      cubit.fetchPaginatedList();
      await Future<void>.delayed(_settle);

      final loaded = cubit.state as SmartPaginationLoaded<int>;
      expect(loaded.items.length, 10,
          reason: 'empty page must NOT be appended');
      expect(loaded.hasReachedEnd, isTrue);
      expect(providerCalls, 2);

      await cubit.close();
    });

    test('T08: short page (< pageSize) sets hasReachedEnd', () async {
      final cubit = SmartPaginationCubit<int, PaginationRequest>(
        request: PaginationRequest(page: 1, pageSize: 10),
        provider: PaginationProvider<int, PaginationRequest>.future((req) async {
          if (req.page == 1) return List<int>.generate(10, (i) => i);
          return [10, 11, 12]; // short page
        }),
      );

      cubit.refreshPaginatedList();
      await Future<void>.delayed(_settle);
      cubit.fetchPaginatedList();
      await Future<void>.delayed(_settle);

      final loaded = cubit.state as SmartPaginationLoaded<int>;
      expect(loaded.items.length, 13,
          reason: 'short page IS appended; only the empty case is dropped');
      expect(loaded.hasReachedEnd, isTrue);

      await cubit.close();
    });

    test('T09: after hasReachedEnd, additional calls do not reach provider',
        () async {
      var providerCalls = 0;
      final cubit = SmartPaginationCubit<int, PaginationRequest>(
        request: PaginationRequest(page: 1, pageSize: 5),
        provider: PaginationProvider<int, PaginationRequest>.future((req) async {
          providerCalls++;
          if (req.page == 1) return [0, 1, 2, 3, 4];
          return <int>[];
        }),
      );

      cubit.refreshPaginatedList();
      await Future<void>.delayed(_settle);
      cubit.fetchPaginatedList();
      await Future<void>.delayed(_settle);
      final callsAtEnd = providerCalls;

      for (var i = 0; i < 5; i++) {
        cubit.fetchPaginatedList();
      }
      await Future<void>.delayed(_settle);

      expect(providerCalls, callsAtEnd,
          reason: 'no further provider calls after hasReachedEnd');

      await cubit.close();
    });

    // -----------------------------------------------------------------------
    // US4: State reset
    // -----------------------------------------------------------------------

    test('T10: refresh clears hasReachedEnd, _isFetching, and _activeLoadMoreKey',
        () async {
      var providerCalls = 0;
      final cubit = SmartPaginationCubit<int, PaginationRequest>(
        request: PaginationRequest(page: 1, pageSize: 5),
        provider: PaginationProvider<int, PaginationRequest>.future((req) async {
          providerCalls++;
          if (req.page == 1) return [0, 1, 2, 3, 4];
          return <int>[];
        }),
      );

      cubit.refreshPaginatedList();
      await Future<void>.delayed(_settle);
      cubit.fetchPaginatedList();
      await Future<void>.delayed(_settle);
      final beforeRefresh = providerCalls;

      cubit.refreshPaginatedList();
      await Future<void>.delayed(_settle);

      expect(providerCalls, beforeRefresh + 1);
      final loaded = cubit.state as SmartPaginationLoaded<int>;
      expect(loaded.hasReachedEnd, isFalse);
      expect(cubit.isFetching, isFalse);

      await cubit.close();
    });

    test('T11: search/filter change resets all guards', () async {
      var queryParam = 'a';
      var providerCalls = 0;
      final cubit = SmartPaginationCubit<int, PaginationRequest>(
        request: PaginationRequest(page: 1, pageSize: 5),
        provider: PaginationProvider<int, PaginationRequest>.future((req) async {
          providerCalls++;
          if (queryParam == 'a' && req.page == 1) return [0, 1, 2, 3, 4];
          if (queryParam == 'a') return <int>[];
          if (queryParam == 'b' && req.page == 1) return [10, 11, 12, 13, 14];
          return [15, 16, 17, 18, 19];
        }),
      );

      cubit.refreshPaginatedList();
      await Future<void>.delayed(_settle);
      cubit.fetchPaginatedList();
      await Future<void>.delayed(_settle);
      expect((cubit.state as SmartPaginationLoaded<int>).hasReachedEnd, isTrue);

      queryParam = 'b';
      cubit.refreshPaginatedList();
      await Future<void>.delayed(_settle);
      expect((cubit.state as SmartPaginationLoaded<int>).hasReachedEnd,
          isFalse);
      expect((cubit.state as SmartPaginationLoaded<int>).items, contains(10));

      final beforePage2 = providerCalls;
      cubit.fetchPaginatedList();
      await Future<void>.delayed(_settle);
      expect(providerCalls, beforePage2 + 1);
      expect((cubit.state as SmartPaginationLoaded<int>).items.length, 10);

      await cubit.close();
    });

    test('T12: stale future response (old token) is discarded', () async {
      final completers = <int, Completer<List<int>>>{};
      var attempt = 0;
      final cubit = SmartPaginationCubit<int, PaginationRequest>(
        request: PaginationRequest(page: 1, pageSize: 5),
        provider: PaginationProvider<int, PaginationRequest>.future((req) {
          attempt++;
          final c = Completer<List<int>>();
          completers[attempt] = c;
          return c.future;
        }),
      );

      cubit.refreshPaginatedList(); // attempt 1
      await Future<void>.delayed(Duration.zero);

      cubit.refreshPaginatedList(); // attempt 2
      await Future<void>.delayed(Duration.zero);

      completers[1]!.complete([99, 99, 99, 99, 99]); // stale
      await Future<void>.delayed(Duration.zero);

      completers[2]!.complete([7, 7, 7, 7, 7]); // current
      await Future<void>.delayed(_settle);

      final loaded = cubit.state as SmartPaginationLoaded<int>;
      expect(loaded.items, [7, 7, 7, 7, 7],
          reason: 'stale attempt-1 must be discarded');

      await cubit.close();
    });

    test('T13: stale empty load-more response does not set hasReachedEnd',
        () async {
      final completers = <int, Completer<List<int>>>{};
      var loadMoreAttempt = 0;
      final cubit = SmartPaginationCubit<int, PaginationRequest>(
        request: PaginationRequest(page: 1, pageSize: 5),
        provider: PaginationProvider<int, PaginationRequest>.future((req) async {
          if (req.page == 1) return [0, 1, 2, 3, 4];
          loadMoreAttempt++;
          final c = Completer<List<int>>();
          completers[loadMoreAttempt] = c;
          return c.future;
        }),
      );

      cubit.refreshPaginatedList();
      await Future<void>.delayed(_settle);

      cubit.fetchPaginatedList(); // load-more 1 (page 2) — pending
      await Future<void>.delayed(Duration.zero);

      cubit.refreshPaginatedList();
      await Future<void>.delayed(_settle);

      // Stale page 2 returns empty.
      completers[1]!.complete(<int>[]);
      await Future<void>.delayed(_settle);

      final loaded = cubit.state as SmartPaginationLoaded<int>;
      expect(loaded.hasReachedEnd, isFalse,
          reason: 'stale empty response must not set hasReachedEnd');
      expect(loaded.items.length, 5);

      await cubit.close();
    });
  });
}
