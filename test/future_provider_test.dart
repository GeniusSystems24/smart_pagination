// US3 acceptance tests for spec 002-stabilize-provider, Phase 5 (T036–T039).
//
// Covers `FuturePaginationProvider` behaviour:
// - Successful page fetch (FR-001).
// - Stale response after refresh (FR-003).
// - Disposal mid-flight (FR-005).
// - First-page-error vs load-more-error routing (FR-002).

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_pagination/pagination.dart';

void main() {
  group('US3: future provider stale-response protection (T036–T039)', () {
    test('T036: successful page fetch produces a Loaded state', () async {
      final cubit = SmartPaginationCubit<int, PaginationRequest>(
        request: PaginationRequest(page: 1, pageSize: 5),
        provider: PaginationProvider<int, PaginationRequest>.future(
          (req) async => List<int>.generate(5, (i) => req.page * 10 + i),
        ),
      );

      cubit.refreshPaginatedList();
      await cubit.stream.firstWhere((s) => s is SmartPaginationLoaded<int>);

      final loaded = cubit.state as SmartPaginationLoaded<int>;
      expect(loaded.items, [10, 11, 12, 13, 14]);
      expect(loaded.meta.page, 1);

      await cubit.close();
    });

    test('T037: stale response from a superseded request is discarded',
        () async {
      // Each call gets its own Completer so the test can resolve them out
      // of order and verify the cubit drops the stale one.
      final completers = <int, Completer<List<int>>>{};
      final cubit = SmartPaginationCubit<int, PaginationRequest>(
        request: PaginationRequest(page: 1, pageSize: 5),
        provider: PaginationProvider<int, PaginationRequest>.future((req) {
          final c = Completer<List<int>>();
          // Map each call by attempt order: 1 = first refresh, 2 = second.
          completers[completers.length + 1] = c;
          return c.future;
        }),
      );

      cubit.refreshPaginatedList(); // attempt 1, generation/token bumped
      // Allow microtask for the dataProvider call to be invoked.
      await Future<void>.delayed(Duration.zero);

      cubit.refreshPaginatedList(); // attempt 2, generation/token bumped again
      await Future<void>.delayed(Duration.zero);

      // Resolve attempt 1 (stale) — it should be discarded.
      completers[1]!.complete(<int>[1, 1, 1, 1, 1]);
      await Future<void>.delayed(Duration.zero);

      // Resolve attempt 2 (current) — it should land in state.
      completers[2]!.complete(<int>[2, 2, 2, 2, 2]);
      await cubit.stream.firstWhere((s) => s is SmartPaginationLoaded<int>);

      final loaded = cubit.state as SmartPaginationLoaded<int>;
      expect(loaded.items, [2, 2, 2, 2, 2],
          reason: 'stale attempt-1 response must be ignored');

      await cubit.close();
    });

    test('T038: in-flight request resolving after close does not throw',
        () async {
      final completer = Completer<List<int>>();
      final cubit = SmartPaginationCubit<int, PaginationRequest>(
        request: PaginationRequest(page: 1, pageSize: 5),
        provider: PaginationProvider<int, PaginationRequest>.future(
          (req) => completer.future,
        ),
      );

      cubit.refreshPaginatedList();
      await Future<void>.delayed(Duration.zero);

      await cubit.close();
      expect(cubit.isClosed, isTrue);

      // Resolve AFTER close. The cubit must drop the response silently.
      completer.complete(<int>[1, 2, 3, 4, 5]);
      await Future<void>.delayed(Duration.zero);
      // No exception => pass.
    });

    test('T039: load-more error annotates the existing Loaded state',
        () async {
      var attempt = 0;
      final cubit = SmartPaginationCubit<int, PaginationRequest>(
        request: PaginationRequest(page: 1, pageSize: 5),
        provider: PaginationProvider<int, PaginationRequest>.future((req) async {
          attempt++;
          if (attempt == 1) return [1, 2, 3, 4, 5];
          throw Exception('load-more failed');
        }),
      );

      cubit.refreshPaginatedList();
      await cubit.stream.firstWhere((s) => s is SmartPaginationLoaded<int>);

      cubit.fetchPaginatedList();
      // Wait for the loadMoreError annotation to land.
      await cubit.stream.firstWhere(
        (s) => s is SmartPaginationLoaded<int> && s.loadMoreError != null,
      );

      final loaded = cubit.state as SmartPaginationLoaded<int>;
      expect(loaded.items, [1, 2, 3, 4, 5],
          reason: 'previously loaded items must remain visible');
      expect(loaded.loadMoreError, isA<Exception>());
      expect(loaded.isLoadingMore, isFalse);
      expect(cubit.state, isA<SmartPaginationLoaded<int>>(),
          reason: 'load-more error MUST NOT transition to SmartPaginationError');

      await cubit.close();
    });

    test('T039b: first-page error transitions to SmartPaginationError',
        () async {
      final cubit = SmartPaginationCubit<int, PaginationRequest>(
        request: PaginationRequest(page: 1, pageSize: 5),
        provider: PaginationProvider<int, PaginationRequest>.future(
          (req) async => throw Exception('first page failed'),
        ),
      );

      cubit.refreshPaginatedList();
      await cubit.stream.firstWhere((s) => s is SmartPaginationError<int>);

      expect(cubit.state, isA<SmartPaginationError<int>>());

      await cubit.close();
    });
  });
}
