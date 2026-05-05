// Spec 004-scroll-anchor-preservation — Anchor capture tests.
//
// Covers tests T01–T08 from plan §13. Verifies the anchor strategy
// selector (per `contracts/anchor-strategy.md`) returns the correct
// strategy + populated fields for each (view type, itemKeyBuilder,
// observer state, reverse) combination, and that capture happens at the
// correct moment in the load-more lifecycle (before `emit(isLoadingMore: true)`).
//
// All tests are stubs at this point (Phase 2 / T009). Bodies land in
// US1 phase (T015–T018, T036).

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Scroll Anchor — Capture (spec 004)', () {
    // -----------------------------------------------------------------------
    // T015 will replace this with the canonical regression `testWidgets`
    // that fast-flings a paginated ListView and asserts exactly one
    // load-more fires. Without anchor preservation, the assertion fails.
    // -----------------------------------------------------------------------
    test(
      'T015: fast fling on ListView produces exactly one load-more '
      '(regression anchor)',
      () {
        fail('not yet implemented');
      },
    );

    // -----------------------------------------------------------------------
    // Strategy selection — hybrid policy (Spec Q1)
    // -----------------------------------------------------------------------

    test(
      'T01: strategy = key when itemKeyBuilder is provided and observer '
      'is attached',
      () {
        fail('not yet implemented');
      },
    );

    test(
      'T02: strategy = itemIndex when itemKeyBuilder is null on a ListView '
      'with observer attached',
      () {
        fail('not yet implemented');
      },
    );

    test(
      'T03: strategy = offset on a StaggeredGridView (no observer)',
      () {
        fail('not yet implemented');
      },
    );

    // -----------------------------------------------------------------------
    // Anchor item selection (Spec Q2 / FR-003b)
    // -----------------------------------------------------------------------

    test(
      'T04: captured anchor is the last fully-visible item before the '
      'loading indicator',
      () {
        fail('not yet implemented');
      },
    );

    test(
      'T05: when no item is fully visible, capture falls back to the '
      'topmost partially-visible item',
      () {
        fail('not yet implemented');
      },
    );

    test(
      'T06: when no item is identifiable at all, capture falls back to '
      'offset strategy',
      () {
        fail('not yet implemented');
      },
    );

    // -----------------------------------------------------------------------
    // Out-of-scope view types (Spec Q5 / FR-007)
    // -----------------------------------------------------------------------

    test(
      'T07: capture is a no-op for reverse lists, PageView, and '
      'ReorderableListView',
      () {
        fail('not yet implemented');
      },
    );

    // -----------------------------------------------------------------------
    // Capture ordering (plan §7.1)
    // -----------------------------------------------------------------------

    test(
      'T08: capture happens BEFORE emit(isLoadingMore: true)',
      () {
        fail('not yet implemented');
      },
    );
  });
}
