// Spec 003-load-more-guard — Scroll-trigger behaviour tests.
//
// The widget layer wraps `fetchPaginatedList?.call()` in
// `SchedulerBinding.addPostFrameCallback` (defense in depth). The primary
// guard is the cubit-level `_isFetching` + `_activeLoadMoreKey` pair, which
// these tests exercise via simulated widget-style trigger patterns.
//
// Plan §12: T27–T29.

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_pagination/pagination.dart';

const _settle = Duration(milliseconds: 50);

void main() {
  group('Scroll Trigger Behaviour (spec 003)', () {
    test('T27: simulated burst of scroll triggers produces one fetch',
        () async {
      var providerCalls = 0;
      final cubit = SmartPaginationCubit<int, PaginationRequest>(
        request: PaginationRequest(page: 1, pageSize: 10),
        provider: PaginationProvider<int, PaginationRequest>.future((req) async {
          providerCalls++;
          return List<int>.generate(10, (i) => (req.page - 1) * 10 + i);
        }),
      );

      cubit.refreshPaginatedList();
      await Future<void>.delayed(_settle);
      providerCalls = 0;

      for (var i = 0; i < 5; i++) {
        cubit.fetchPaginatedList();
      }
      await Future<void>.delayed(_settle);

      expect(providerCalls, 1);
      final loaded = cubit.state as SmartPaginationLoaded<int>;
      expect(loaded.items.length, 20);

      await cubit.close();
    });

    test('T28: scroll triggers after hasReachedEnd produce no fetch',
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

      for (var i = 0; i < 10; i++) {
        cubit.fetchPaginatedList();
      }
      await Future<void>.delayed(_settle);

      expect(providerCalls, callsAtEnd,
          reason: 'no provider call after hasReachedEnd');

      await cubit.close();
    });

    test('T29: scroll triggers after error allow retry on next attempt',
        () async {
      var attempt = 0;
      final cubit = SmartPaginationCubit<int, PaginationRequest>(
        request: PaginationRequest(page: 1, pageSize: 5),
        errorRetryStrategy: ErrorRetryStrategy.automatic,
        provider: PaginationProvider<int, PaginationRequest>.future((req) async {
          attempt++;
          if (req.page == 1) return [0, 1, 2, 3, 4];
          if (attempt == 2) {
            throw Exception('transient failure');
          }
          return [5, 6, 7, 8, 9];
        }),
      );

      cubit.refreshPaginatedList();
      await Future<void>.delayed(_settle);

      cubit.fetchPaginatedList();
      await Future<void>.delayed(_settle);
      var loaded = cubit.state as SmartPaginationLoaded<int>;
      expect(loaded.loadMoreError, isNotNull);
      expect(loaded.hasReachedEnd, isFalse);

      cubit.fetchPaginatedList();
      await Future<void>.delayed(_settle);

      loaded = cubit.state as SmartPaginationLoaded<int>;
      expect(loaded.items.length, 10);
      expect(loaded.loadMoreError, isNull);

      await cubit.close();
    });
  });
}
