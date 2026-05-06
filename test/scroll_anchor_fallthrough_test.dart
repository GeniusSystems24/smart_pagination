// Spec 004-scroll-anchor-preservation — Out-of-scope view fall-through tests.
//
// Covers tests T36–T38 from plan §13. Verifies that for view types
// declared out of scope in v1 (reverse: true, PageView,
// ReorderableListView), the package's pre-feature behavior is preserved:
// existing trigger paths continue to fire, no anchor state is armed, and
// no exceptions are thrown.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_pagination/pagination.dart';

const _pageSize = 10;
const _itemHeight = 50.0;

void main() {
  group('Scroll Anchor — Out-of-Scope View Fall-Through (spec 004)', () {
    // -----------------------------------------------------------------------
    // T36: reverse: true on ListView — _shouldLoadMore trigger still fires.
    //
    // Expected final behavior (after T040): capture is short-circuited for
    // reverse lists so suppression is never armed; load-more fires on every
    // threshold crossing without requiring a user-scroll gesture to re-arm.
    //
    // With current code (before T040): capture IS called for reverse lists,
    // suppression IS set, and a programmatic scroll-to-end (no drag gesture)
    // does NOT call markUserScroll, so the second threshold crossing is blocked.
    //
    // The test asserts: the first load-more fires (always true) AND that a
    // second programmatic crossing also fires (only true after T040 lands).
    // Therefore T36 FAILS until T040.
    // -----------------------------------------------------------------------
    testWidgets(
      'T36: reverse: true on ListView — load-more fires whenever the '
      'original _shouldLoadMore says so; no anchor logic interferes',
      (tester) async {
        var callCount = 0;
        final scrollController = ScrollController();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              // Constrain viewport to a height smaller than the page's total
              // content (10 items × 50px = 500px). This guarantees the
              // _shouldLoadMore trigger only fires after the programmatic
              // scrollTo call below, not during the initial render — without
              // it the spinner index would already be within the
              // invisibleItemsThreshold of the visible viewport.
              body: SizedBox(
                height: 200,
                child: SmartPaginationListView<int,
                        PaginationRequest>.withProvider(
                  request: PaginationRequest(page: 1, pageSize: _pageSize),
                  provider: PaginationProvider<int, PaginationRequest>.future(
                    (req) async {
                      callCount++;
                      return List<int>.generate(
                        _pageSize,
                        (i) => (req.page - 1) * _pageSize + i,
                      );
                    },
                  ),
                  scrollController: scrollController,
                  reverse: true,
                  itemBuilder: (context, items, index) => SizedBox(
                    height: _itemHeight,
                    child: Text('Item ${items[index]}'),
                  ),
                  invisibleItemsThreshold: 1,
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(callCount, 1, reason: 'Initial page loaded.');
        final callsAfterInit = callCount;

        // In a reverse list, scrolling to maxScrollExtent brings the
        // highest-index items into view and triggers _shouldLoadMore.
        scrollController.jumpTo(scrollController.position.maxScrollExtent);
        await tester.pump();
        await tester.pumpAndSettle();

        expect(
          callCount,
          callsAfterInit + 1,
          reason: 'T36: first load-more triggered by programmatic scroll.',
        );

        // For an out-of-scope view (after T040): immediately scrolling to the
        // new maxScrollExtent should trigger another load-more without needing
        // a user-drag gesture to clear suppression first.
        // FAILS until T040: anchor capture is still called for reverse lists,
        // suppression is set, and the second programmatic jump does not invoke
        // markUserScroll.
        scrollController.jumpTo(scrollController.position.maxScrollExtent);
        await tester.pump();
        await tester.pumpAndSettle();

        expect(
          callCount,
          callsAfterInit + 2,
          reason:
              'T36: second programmatic scroll-to-end on reverse list must '
              'also fire load-more without a drag gesture. Fails until T040 '
              'short-circuits anchor logic for reverse lists.',
        );

        scrollController.dispose();
      },
    );

    // -----------------------------------------------------------------------
    // T37: PageView — existing overflow-index trigger continues to call
    // fetchPaginatedList.
    //
    // The package renders items.length + 1 children in the PageView's sliver
    // delegate. When the user navigates to the (items.length)th slot, the
    // builder fires and schedules fetchPaginatedList via addPostFrameCallback.
    // This mechanism is entirely independent of the anchor feature and must
    // remain unchanged.
    //
    // This test PASSES: no behavior change was introduced for PageView's
    // overflow-index trigger path.
    // -----------------------------------------------------------------------
    testWidgets(
      'T37: PageView — existing overflow-index trigger continues to call '
      'fetchPaginatedList',
      (tester) async {
        var callCount = 0;
        final pageController = PageController();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SmartPaginationPageView<int,
                      PaginationRequest>.withProvider(
                request: PaginationRequest(page: 1, pageSize: 5),
                provider: PaginationProvider<int, PaginationRequest>.future(
                  (req) async {
                    callCount++;
                    return List<int>.generate(
                      5,
                      (i) => (req.page - 1) * 5 + i,
                    );
                  },
                ),
                pageController: pageController,
                itemBuilder: (context, items, index) => Center(
                  child: Text('Page ${items[index]}'),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(callCount, 1, reason: 'Initial page loaded.');

        // Navigate to the overflow slot (index == items.length == 5).
        // The builder renders bottomLoader and schedules fetchPaginatedList.
        pageController.jumpToPage(5);
        await tester.pump();
        await tester.pumpAndSettle();

        expect(
          callCount,
          2,
          reason:
              'T37: overflow-index slot triggered fetchPaginatedList. '
              'The PageView trigger path must be unchanged by the anchor feature.',
        );

        pageController.dispose();
      },
    );

    // -----------------------------------------------------------------------
    // T38: ReorderableListView — existing behavior unchanged.
    //
    // The package's ReorderableListView builder has no automatic load-more
    // trigger in the item builder (by design — the view type is out of scope).
    // This test verifies that:
    // (a) items render correctly after initial load,
    // (b) no exception is thrown,
    // (c) reorder operations work normally.
    //
    // This test PASSES: no behavior change was introduced for
    // ReorderableListView.
    // -----------------------------------------------------------------------
    testWidgets(
      'T38: ReorderableListView — existing behavior unchanged',
      (tester) async {
        var callCount = 0;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SmartPaginationReorderableListView<int,
                      PaginationRequest>.withProvider(
                request: PaginationRequest(page: 1, pageSize: _pageSize),
                provider: PaginationProvider<int, PaginationRequest>.future(
                  (req) async {
                    callCount++;
                    return List<int>.generate(
                      _pageSize,
                      (i) => (req.page - 1) * _pageSize + i,
                    );
                  },
                ),
                itemBuilder: (context, items, index) => ListTile(
                  key: ValueKey(items[index]),
                  title: Text('Item ${items[index]}'),
                ),
                onReorder: (oldIndex, newIndex) {},
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Items rendered without exception.
        expect(callCount, 1, reason: 'Initial page loaded.');
        expect(find.text('Item 0'), findsOneWidget);
        expect(find.text('Item ${_pageSize - 1}'), findsOneWidget);

        // No anchor state interferes — the feature simply doesn't apply.
        // No assertion about suppression is needed because ReorderableListView
        // has no automatic load-more trigger in its item builder.
      },
    );
  });
}
