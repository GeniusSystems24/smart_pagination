// Spec 004-scroll-anchor-preservation — Load-more suppression tests.
//
// Covers tests T16–T22 from plan §13. Verifies the
// `_suppressLoadMoreUntilUserScroll` flag's full state machine:
//   - armed on load-more accept,
//   - cleared by user-initiated ScrollStartNotification,
//   - NOT cleared by programmatic jumpTo / animateTo (incl. anchor restore's
//     own synthetic notification),
//   - cleared on load-more error,
//   - cleared on scope reset (refresh / filter).
//
// All tests are stubs at this point (Phase 2 / T011). Bodies land in
// US1 phase (T018).

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Scroll Anchor — Load-More Suppression (spec 004)', () {
    // -----------------------------------------------------------------------
    // Suppression armed after successful append (Spec SC-002 / FR-004 / FR-004b)
    // -----------------------------------------------------------------------

    test(
      'T16: immediately after a successful append, fetchPaginatedList '
      'is rejected with no provider call',
      () {
        fail('not yet implemented');
      },
    );

    // -----------------------------------------------------------------------
    // User-scroll re-arm (Spec FR-004)
    // -----------------------------------------------------------------------

    test(
      'T17: after a user-initiated ScrollStartNotification fires, the '
      'next fetchPaginatedList is allowed through',
      () {
        fail('not yet implemented');
      },
    );

    // -----------------------------------------------------------------------
    // Programmatic vs. user-initiated discrimination (plan §6.3, R3)
    // -----------------------------------------------------------------------

    test(
      'T18: programmatic controller.jumpTo (e.g. from public '
      'animateToIndex) does NOT clear the suppression flag',
      () {
        fail('not yet implemented');
      },
    );

    test(
      'T19: synthetic scroll notification produced by anchor restore\'s '
      'own jumpTo does NOT clear the suppression flag',
      () {
        fail('not yet implemented');
      },
    );

    // -----------------------------------------------------------------------
    // Late layout-settle resilience (Spec FR-004b)
    // -----------------------------------------------------------------------

    test(
      'T20: late layout settle (image loads adjusting maxScrollExtent '
      'after restore) does NOT trigger another fetchPaginatedList while '
      'suppressed',
      () {
        fail('not yet implemented');
      },
    );

    // -----------------------------------------------------------------------
    // Error path clears suppression (plan §7.3)
    // -----------------------------------------------------------------------

    test(
      'T21: a load-more error clears the suppression flag (so retry can '
      'proceed without forcing user scroll)',
      () {
        fail('not yet implemented');
      },
    );

    // -----------------------------------------------------------------------
    // Scope reset clears suppression (plan §7.4)
    // -----------------------------------------------------------------------

    test(
      'T22: refresh / filter change clears the suppression flag and '
      'discards the pending anchor',
      () {
        fail('not yet implemented');
      },
    );
  });
}
