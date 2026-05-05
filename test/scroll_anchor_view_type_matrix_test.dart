// Spec 004-scroll-anchor-preservation — View-type support matrix tests.
//
// Covers tests T23–T29 from plan §13. Verifies the
// `contracts/view-type-matrix.md` contract end-to-end: in-scope views
// (ListView, GridView, CustomScrollView/slivers, StaggeredGridView)
// preserve the anchor; out-of-scope views (PageView, ReorderableListView,
// reverse: true) fall through to existing behavior with no exceptions.
//
// All tests are stubs at this point (Phase 2 / T012). Bodies land in
// US2 phase (T033, T034).

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Scroll Anchor — View-Type Matrix (spec 004)', () {
    // -----------------------------------------------------------------------
    // In-scope views (Spec FR-007 / US2 AS1–AS4)
    // -----------------------------------------------------------------------

    test(
      'T23: anchor preservation works on ListView (with and without '
      'itemKeyBuilder)',
      () {
        fail('not yet implemented');
      },
    );

    test(
      'T24: anchor preservation works on GridView (with and without '
      'itemKeyBuilder)',
      () {
        fail('not yet implemented');
      },
    );

    test(
      'T25: anchor preservation works on CustomScrollView/sliver layouts '
      'with the package\'s items sliver',
      () {
        fail('not yet implemented');
      },
    );

    test(
      'T26: anchor preservation works on StaggeredGridView via offset-delta',
      () {
        fail('not yet implemented');
      },
    );

    // -----------------------------------------------------------------------
    // Out-of-scope views (Spec FR-007 / US2 AS5)
    // -----------------------------------------------------------------------

    test(
      'T27: anchor preservation is a no-op on PageView (no markUserScroll '
      'flag set, no _pendingAnchor)',
      () {
        fail('not yet implemented');
      },
    );

    test(
      'T28: anchor preservation is a no-op on ReorderableListView',
      () {
        fail('not yet implemented');
      },
    );

    test(
      'T29: anchor preservation is a no-op on any view with reverse: true',
      () {
        fail('not yet implemented');
      },
    );
  });
}
