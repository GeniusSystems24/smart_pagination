// Spec 004-scroll-anchor-preservation — Post-frame anchor restore tests.
//
// Covers tests T09–T15 from plan §13. Verifies the post-frame restore
// mechanics (per `contracts/anchor-strategy.md` "Restore mechanism by
// strategy") for each captured strategy, plus the fallback chain
// (key → itemIndex → offset → no-op) and generation-mismatch handling.
//
// All tests are stubs at this point (Phase 2 / T010). Bodies land in US1
// phase (T017) and US2 phase (T042, T043).

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Scroll Anchor — Restore (spec 004)', () {
    // -----------------------------------------------------------------------
    // Visual stability after append (Spec SC-001 / FR-002)
    // -----------------------------------------------------------------------

    test(
      'T09: after load-more append, anchor item is at approximately the '
      'same on-screen offset (±1 row tolerance)',
      () {
        fail('not yet implemented');
      },
    );

    // -----------------------------------------------------------------------
    // Restore timing (Spec Q3 / FR-004a)
    // -----------------------------------------------------------------------

    test(
      'T10: restore happens in a post-frame callback, not synchronously',
      () {
        fail('not yet implemented');
      },
    );

    // -----------------------------------------------------------------------
    // Restore dispatch by strategy (plan §5.1)
    // -----------------------------------------------------------------------

    test(
      'T11: ListView restore uses _listObserverController.jumpTo with '
      'alignment: 1.0',
      () {
        fail('not yet implemented');
      },
    );

    test(
      'T12: StaggeredGridView restore uses controller.jumpTo(pixelsBefore)',
      () {
        fail('not yet implemented');
      },
    );

    // -----------------------------------------------------------------------
    // Variable-height items (Spec FR-012(b) / SC-005)
    // -----------------------------------------------------------------------

    test(
      'T13: anchor stays at same row index across variable-height items',
      () {
        fail('not yet implemented');
      },
    );

    // -----------------------------------------------------------------------
    // Fallback chain (Spec FR-008)
    // -----------------------------------------------------------------------

    test(
      'T14: when captured anchor key is no longer present, restore falls '
      'through to offset-delta path and does not throw',
      () {
        fail('not yet implemented');
      },
    );

    test(
      'T15: when generation advanced (scope reset between capture and '
      'restore), anchor is discarded and no jumpTo is called',
      () {
        fail('not yet implemented');
      },
    );
  });
}
