// Spec 003-load-more-guard — Item identity-key deduplication tests.
//
// Covers FR-012: opt-in cross-page deduplication via consumer-configured
// identity key. Tests T20–T22 from plan §12.

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_pagination/pagination.dart';

class _Item {
  const _Item(this.id, this.label);
  final int id;
  final String label;
}

void main() {
  group('Item Deduplication (spec 003)', () {
    test('T20: with identityKey, cross-page duplicates appear once', () async {
      final cubit = SmartPaginationCubit<_Item, PaginationRequest>(
        request: PaginationRequest(page: 1, pageSize: 5),
        identityKey: (item) => item.id,
        provider: PaginationProvider<_Item, PaginationRequest>.future((req) async {
          if (req.page == 1) {
            return const [
              _Item(0, 'a'),
              _Item(1, 'b'),
              _Item(2, 'c'),
              _Item(3, 'd'),
              _Item(4, 'e'),
            ];
          }
          // Page 2 overlaps on id=4 — that duplicate must be dropped.
          return const [
            _Item(4, 'e2'),
            _Item(5, 'f'),
            _Item(6, 'g'),
            _Item(7, 'h'),
            _Item(8, 'i'),
          ];
        }),
      );

      cubit.refreshPaginatedList();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      cubit.fetchPaginatedList();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final loaded = cubit.state as SmartPaginationLoaded<_Item>;
      expect(loaded.items.length, 9,
          reason: 'duplicate id=4 from page 2 must be dropped');
      expect(loaded.items.map((i) => i.id).toSet().length, 9);
      // First occurrence wins (page 1's label='e' kept).
      expect(loaded.items.firstWhere((i) => i.id == 4).label, 'e');

      await cubit.close();
    });

    test('T21: without identityKey, items are appended as-is', () async {
      final cubit = SmartPaginationCubit<_Item, PaginationRequest>(
        request: PaginationRequest(page: 1, pageSize: 5),
        // No identityKey configured.
        provider: PaginationProvider<_Item, PaginationRequest>.future((req) async {
          if (req.page == 1) {
            return const [
              _Item(0, 'a'),
              _Item(1, 'b'),
              _Item(2, 'c'),
              _Item(3, 'd'),
              _Item(4, 'e'),
            ];
          }
          return const [
            _Item(4, 'e2'),
            _Item(5, 'f'),
            _Item(6, 'g'),
            _Item(7, 'h'),
            _Item(8, 'i'),
          ];
        }),
      );

      cubit.refreshPaginatedList();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      cubit.fetchPaginatedList();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final loaded = cubit.state as SmartPaginationLoaded<_Item>;
      expect(loaded.items.length, 10,
          reason: 'no identityKey ⇒ every server item is appended verbatim');

      await cubit.close();
    });

    test('T22: deduplication runs before onInsertionCallback', () async {
      final receivedKeys = <List<int>>[];
      final cubit = SmartPaginationCubit<_Item, PaginationRequest>(
        request: PaginationRequest(page: 1, pageSize: 5),
        identityKey: (item) => item.id,
        onInsertionCallback: (items) {
          receivedKeys.add(items.map((i) => i.id).toList());
        },
        provider: PaginationProvider<_Item, PaginationRequest>.future((req) async {
          if (req.page == 1) {
            return const [
              _Item(0, 'a'),
              _Item(1, 'b'),
              _Item(2, 'c'),
              _Item(3, 'd'),
              _Item(4, 'e'),
            ];
          }
          return const [
            _Item(4, 'e2'),
            _Item(5, 'f'),
            _Item(6, 'g'),
            _Item(7, 'h'),
            _Item(8, 'i'),
          ];
        }),
      );

      cubit.refreshPaginatedList();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      cubit.fetchPaginatedList();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Every callback invocation must have unique ids — never a duplicate.
      for (final keys in receivedKeys) {
        expect(keys.toSet().length, keys.length,
            reason: 'callback received duplicate keys $keys');
      }
      // Last invocation (post-load-more) should have all 9 unique ids.
      expect(receivedKeys.last, [0, 1, 2, 3, 4, 5, 6, 7, 8]);

      await cubit.close();
    });
  });
}
