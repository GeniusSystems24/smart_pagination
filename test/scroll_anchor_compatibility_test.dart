// Spec 004-scroll-anchor-preservation — Backward compatibility tests.
//
// Covers tests T30–T35 from plan §13. Verifies Spec FR-009 (zero breaking
// changes) and Constitution §II ("Backward Compatibility First"):
//   - .withProvider(...) and .withCubit(...) work unchanged,
//   - external ScrollController is NOT taken over,
//   - external listeners continue to fire,
//   - preserveScrollAnchorOnAppend: false reverts to pre-feature behavior,
//   - README example call sites compile and run unmodified.
//
// All tests are stubs at this point (Phase 2 / T013). Bodies land in
// US3 phase (T045, T046, T050).

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Scroll Anchor — Backward Compatibility (spec 004)', () {
    // -----------------------------------------------------------------------
    // .withProvider / .withCubit constructor compatibility
    // (Spec US3 AS1, US3 AS2 / FR-005, FR-006)
    // -----------------------------------------------------------------------

    test(
      'T30: .withProvider(...) constructor — anchor preservation works '
      'with the package\'s internal ScrollController',
      () {
        fail('not yet implemented');
      },
    );

    test(
      'T31: .withCubit(...) constructor — anchor preservation works with '
      'an externally-supplied ScrollController',
      () {
        fail('not yet implemented');
      },
    );

    // -----------------------------------------------------------------------
    // External controller listener semantics (Spec FR-005)
    // -----------------------------------------------------------------------

    test(
      'T32: external ScrollController\'s addListener callbacks continue '
      'to fire during anchor capture and during the post-frame restore',
      () {
        fail('not yet implemented');
      },
    );

    test(
      'T33: external ScrollController is NOT disposed by the package '
      '(reusable in a sibling widget after the paginated view is unmounted)',
      () {
        fail('not yet implemented');
      },
    );

    // -----------------------------------------------------------------------
    // Disable flag (Spec FR-009 / FR-011)
    // -----------------------------------------------------------------------

    test(
      'T34: preserveScrollAnchorOnAppend: false disables capture, '
      'restore, and suppression entirely; behavior reverts to pre-feature',
      () {
        fail('not yet implemented');
      },
    );

    // -----------------------------------------------------------------------
    // README example compatibility (Spec US3 AS3)
    // -----------------------------------------------------------------------

    test(
      'T35: all call sites from the README examples for .withProvider '
      'and .withCubit compile and run without modification',
      () {
        fail('not yet implemented');
      },
    );
  });
}
