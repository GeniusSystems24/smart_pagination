// Foundational regression test for spec 002-stabilize-provider, Phase 2 (T006).
//
// Asserts that `SmartPaginationLoaded.pageErrors` is additive and
// backward-compatible: existing call sites that construct the state without
// supplying `pageErrors` must continue to compile and produce a state whose
// `pageErrors` field is the canonical empty map.

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_pagination/pagination.dart';

void main() {
  group('SmartPaginationLoaded.pageErrors (additive field, BC anchor)', () {
    test('defaults to const <int, Object>{} when not supplied', () {
      final state = SmartPaginationLoaded<int>(
        items: const <int>[],
        allItems: const <int>[],
        meta: PaginationMeta(
          page: 1,
          pageSize: 20,
          hasNext: false,
          hasPrevious: false,
        ),
        hasReachedEnd: true,
      );

      expect(state.pageErrors, isEmpty);
      expect(state.pageErrors, isA<Map<int, Object>>());
    });

    test('survives copyWith without pageErrors override', () {
      final original = SmartPaginationLoaded<int>(
        items: const <int>[1, 2, 3],
        allItems: const <int>[1, 2, 3],
        meta: PaginationMeta(
          page: 1,
          pageSize: 20,
          hasNext: true,
          hasPrevious: false,
        ),
        hasReachedEnd: false,
        pageErrors: const <int, Object>{2: 'boom'},
      );

      final copied = original.copyWith(items: const <int>[1, 2, 3, 4]);

      expect(copied.pageErrors, equals(<int, Object>{2: 'boom'}));
    });

    test('copyWith can set a new pageErrors map', () {
      final original = SmartPaginationLoaded<int>(
        items: const <int>[1],
        allItems: const <int>[1],
        meta: PaginationMeta(
          page: 1,
          pageSize: 20,
          hasNext: true,
          hasPrevious: false,
        ),
        hasReachedEnd: false,
      );

      final updated = original.copyWith(
        pageErrors: const <int, Object>{3: 'page 3 failed'},
      );

      expect(updated.pageErrors, equals(<int, Object>{3: 'page 3 failed'}));
      expect(original.pageErrors, isEmpty,
          reason: 'original state must be unchanged');
    });

    test('pageErrors difference breaks equality (isolated)', () {
      // Note: we don't assert `base == sameAsBase` because PaginationMeta
      // (a pre-existing type) lacks value equality and instantiates a fresh
      // `fetchedAt = DateTime.now()` per construction. Instead we use
      // copyWith to keep meta reference-identical, so the only difference
      // between the two states under test is `pageErrors`.
      final base = SmartPaginationLoaded<int>(
        items: const <int>[],
        allItems: const <int>[],
        meta: PaginationMeta(
          page: 1,
          pageSize: 20,
          hasNext: false,
          hasPrevious: false,
        ),
        hasReachedEnd: true,
      );
      final selfCopy = base.copyWith();
      final withError = base.copyWith(
        pageErrors: const <int, Object>{2: 'err'},
      );

      expect(base, equals(selfCopy),
          reason: 'copyWith() with no changes must produce an equal state');
      expect(base == withError, isFalse,
          reason: 'pageErrors difference must break equality');
    });
  });
}
