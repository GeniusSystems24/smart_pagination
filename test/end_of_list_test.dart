// Spec 003-load-more-guard — End-of-list detection tests.
//
// Covers FR-004, FR-005, FR-006: end-of-list inference from short/empty
// pages and the rule that errors do NOT set hasReachedEnd.
//
// Plan §6.3 / contract `future-provider.md`: cursor-null and explicit
// `hasMore: false` signals are accepted via `_computeHasNext`'s optional
// `serverHasNext` override. Wiring that override through a public
// `PaginationResponse` wrapper is marked "future enhancement, not part of
// this feature" — so T23/T24/T25 below assert the practical inference
// behaviour the cubit performs today (short-page / empty-page heuristics).

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_pagination/pagination.dart';

void main() {
  group('End-of-List Detection (spec 003)', () {
    test('T23 (adapted): a final partial page sets hasReachedEnd', () async {
      // Cursor-null pagination: when the data source has no more pages it
      // returns fewer items than `pageSize`. The library treats that as
      // end-of-list — equivalent semantics to a null next-cursor without
      // requiring a public response-wrapper change.
      final cubit = SmartPaginationCubit<int, PaginationRequest>(
        request: PaginationRequest(page: 1, pageSize: 10),
        provider: PaginationProvider<int, PaginationRequest>.future((req) async {
          if (req.page == 1) return List<int>.generate(10, (i) => i);
          return [10, 11, 12]; // "final" page — server has no more
        }),
      );

      cubit.refreshPaginatedList();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      cubit.fetchPaginatedList();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final loaded = cubit.state as SmartPaginationLoaded<int>;
      expect(loaded.hasReachedEnd, isTrue);
      expect(loaded.items.length, 13);

      await cubit.close();
    });

    test('T24 (adapted): explicit empty response sets hasReachedEnd', () async {
      // Explicit "no more data" signal: an empty page on load-more is the
      // practical equivalent of `hasMore: false`. The plan §6.1 dictates
      // the empty page is NOT appended.
      final cubit = SmartPaginationCubit<int, PaginationRequest>(
        request: PaginationRequest(page: 1, pageSize: 10),
        provider: PaginationProvider<int, PaginationRequest>.future((req) async {
          if (req.page == 1) return List<int>.generate(10, (i) => i);
          return <int>[];
        }),
      );

      cubit.refreshPaginatedList();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      cubit.fetchPaginatedList();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final loaded = cubit.state as SmartPaginationLoaded<int>;
      expect(loaded.hasReachedEnd, isTrue);
      expect(loaded.items.length, 10,
          reason: 'empty page must not be appended');

      await cubit.close();
    });

    test('T25: full-page response does NOT set hasReachedEnd', () async {
      // The complement: a full page (length == pageSize) leaves `hasNext`
      // truthy so the cubit allows another fetch.
      final cubit = SmartPaginationCubit<int, PaginationRequest>(
        request: PaginationRequest(page: 1, pageSize: 5),
        provider: PaginationProvider<int, PaginationRequest>.future((req) async {
          return List<int>.generate(5, (i) => (req.page - 1) * 5 + i);
        }),
      );

      cubit.refreshPaginatedList();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      cubit.fetchPaginatedList();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final loaded = cubit.state as SmartPaginationLoaded<int>;
      expect(loaded.hasReachedEnd, isFalse,
          reason: 'every page is full ⇒ pagination keeps going');
      expect(loaded.meta.hasNext, isTrue);

      await cubit.close();
    });

    test('T26: load-more error does NOT set hasReachedEnd', () async {
      var attempt = 0;
      final cubit = SmartPaginationCubit<int, PaginationRequest>(
        request: PaginationRequest(page: 1, pageSize: 5),
        errorRetryStrategy: ErrorRetryStrategy.manual,
        provider: PaginationProvider<int, PaginationRequest>.future((req) async {
          attempt++;
          if (attempt == 1) return [0, 1, 2, 3, 4];
          throw Exception('network down');
        }),
      );

      cubit.refreshPaginatedList();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      cubit.fetchPaginatedList();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final loaded = cubit.state as SmartPaginationLoaded<int>;
      expect(loaded.hasReachedEnd, isFalse,
          reason: 'errors must never end pagination silently');
      expect(loaded.loadMoreError, isNotNull);

      await cubit.close();
    });
  });
}
