// Spec 004-scroll-anchor-preservation — Out-of-scope view fall-through tests.
//
// Covers tests T36–T38 from plan §13. Verifies that for view types
// declared out of scope in v1 (reverse: true, PageView,
// ReorderableListView), the package's pre-feature behavior is preserved
// byte-identically: existing trigger paths continue to fire, no anchor
// state is armed, and no exceptions are thrown.
//
// All tests are stubs at this point (Phase 2 / T014). Bodies land in
// US2 phase (T035).

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Scroll Anchor — Out-of-Scope View Fall-Through (spec 004)', () {
    test(
      'T36: reverse: true on ListView — load-more fires whenever the '
      'original _shouldLoadMore says so; no anchor logic interferes',
      () {
        fail('not yet implemented');
      },
    );

    test(
      'T37: PageView — existing overflow-index trigger continues to call '
      'fetchPaginatedList',
      () {
        fail('not yet implemented');
      },
    );

    test(
      'T38: ReorderableListView — existing behavior unchanged',
      () {
        fail('not yet implemented');
      },
    );
  });
}
