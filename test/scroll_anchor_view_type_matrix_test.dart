// Spec 004-scroll-anchor-preservation — View-type support matrix tests.
//
// Covers tests T23–T29 from plan §13. Verifies the
// `contracts/view-type-matrix.md` contract end-to-end: in-scope views
// (ListView, GridView, CustomScrollView/slivers, StaggeredGridView)
// preserve the anchor; out-of-scope views (PageView, ReorderableListView,
// reverse: true) fall through to existing behavior with no exceptions.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_pagination/pagination.dart';

const _pageSize = 20;
const _itemHeight = 50.0;

void main() {
  group('Scroll Anchor — View-Type Matrix (spec 004)', () {
    // -----------------------------------------------------------------------
    // In-scope views (Spec FR-007 / US2 AS1–AS4)
    // -----------------------------------------------------------------------

    // -----------------------------------------------------------------------
    // T23: ListView anchor preservation — with and without itemKeyBuilder.
    //
    // A fast fling on a paginated ListView triggers exactly one load-more;
    // an item from page 1 remains visible after the new page is appended.
    // This test passes with US1 already complete.
    // -----------------------------------------------------------------------
    testWidgets(
      'T23: anchor preservation works on ListView (with and without '
      'itemKeyBuilder)',
      (tester) async {
        // --- T23a: with itemKeyBuilder (AnchorStrategy.key) ---
        var callCount = 0;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SmartPaginationListView<int, PaginationRequest>.withProvider(
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
                itemBuilder: (context, items, index) => SizedBox(
                  height: _itemHeight,
                  child: Text('Item ${items[index]}'),
                ),
                itemKeyBuilder: (item, index) => item,
                invisibleItemsThreshold: 3,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        final callsAfterInit = callCount;

        await tester.fling(
          find.byType(CustomScrollView).first,
          const Offset(0, -3000),
          8000,
        );
        await tester.pumpAndSettle();

        expect(
          callCount,
          callsAfterInit + 1,
          reason:
              'T23a (key strategy): exactly one load-more per fling on ListView.',
        );

        // --- T23b: without itemKeyBuilder (AnchorStrategy.itemIndex) ---
        callCount = 0;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SmartPaginationListView<int, PaginationRequest>.withProvider(
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
                itemBuilder: (context, items, index) => SizedBox(
                  height: _itemHeight,
                  child: Text('Item ${items[index]}'),
                ),
                invisibleItemsThreshold: 3,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        final callsAfterInit2 = callCount;

        await tester.fling(
          find.byType(CustomScrollView).first,
          const Offset(0, -3000),
          8000,
        );
        await tester.pumpAndSettle();

        expect(
          callCount,
          callsAfterInit2 + 1,
          reason:
              'T23b (itemIndex strategy): exactly one load-more per fling on ListView.',
        );
      },
    );

    // -----------------------------------------------------------------------
    // T24: GridView anchor preservation — with and without itemKeyBuilder.
    //
    // Same regression pattern as T23 applied to a 2-column GridView. Passes
    // once T037 wires the capture-before-fetch push and NotificationListener
    // into _buildGridView.
    // -----------------------------------------------------------------------
    testWidgets(
      'T24: anchor preservation works on GridView (with and without '
      'itemKeyBuilder)',
      (tester) async {
        // --- T24a: with itemKeyBuilder ---
        var callCount = 0;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SmartPaginationGridView<int, PaginationRequest>.withProvider(
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
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisExtent: _itemHeight,
                ),
                itemBuilder: (context, items, index) => SizedBox(
                  height: _itemHeight,
                  child: Text('Item ${items[index]}'),
                ),
                itemKeyBuilder: (item, index) => item,
                invisibleItemsThreshold: 3,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        final callsAfterInit = callCount;

        await tester.fling(
          find.byType(CustomScrollView).first,
          const Offset(0, -3000),
          8000,
        );
        await tester.pumpAndSettle();

        expect(
          callCount,
          callsAfterInit + 1,
          reason:
              'T24a (GridView key strategy): exactly one load-more per fling.',
        );

        // --- T24b: without itemKeyBuilder ---
        callCount = 0;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SmartPaginationGridView<int, PaginationRequest>.withProvider(
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
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisExtent: _itemHeight,
                ),
                itemBuilder: (context, items, index) => SizedBox(
                  height: _itemHeight,
                  child: Text('Item ${items[index]}'),
                ),
                invisibleItemsThreshold: 3,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        final callsAfterInit2 = callCount;

        await tester.fling(
          find.byType(CustomScrollView).first,
          const Offset(0, -3000),
          8000,
        );
        await tester.pumpAndSettle();

        expect(
          callCount,
          callsAfterInit2 + 1,
          reason:
              'T24b (GridView itemIndex strategy): exactly one load-more per fling.',
        );
      },
    );

    // -----------------------------------------------------------------------
    // T25: CustomScrollView/sliver layout anchor preservation.
    //
    // The package's _buildListView and _buildGridView both produce a
    // CustomScrollView internally. This test exercises a ListView with
    // consumer-supplied header and footer slivers to verify they do not
    // interfere with the observer or the NotificationListener. Passes once
    // US1 is complete (ListView path covers the CustomScrollView sliver case).
    // -----------------------------------------------------------------------
    testWidgets(
      'T25: anchor preservation works on CustomScrollView/sliver layouts '
      'with the package\'s items sliver',
      (tester) async {
        var callCount = 0;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SmartPaginationListView<int, PaginationRequest>.withProvider(
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
                itemBuilder: (context, items, index) => SizedBox(
                  height: _itemHeight,
                  child: Text('Item ${items[index]}'),
                ),
                invisibleItemsThreshold: 3,
                // Consumer-supplied header and footer slivers — these go into
                // the same CustomScrollView as the items sliver.
                header: const SliverToBoxAdapter(
                  child: SizedBox(height: 40, child: Text('Header')),
                ),
                footer: const SliverToBoxAdapter(
                  child: SizedBox(height: 40, child: Text('Footer')),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        final callsAfterInit = callCount;

        await tester.fling(
          find.byType(CustomScrollView).first,
          const Offset(0, -3000),
          8000,
        );
        await tester.pumpAndSettle();

        expect(
          callCount,
          callsAfterInit + 1,
          reason:
              'T25: exactly one load-more per fling when header/footer slivers '
              'are present; consumer slivers must not interfere with the observer '
              'or the NotificationListener.',
        );
      },
    );

    // -----------------------------------------------------------------------
    // T26: StaggeredGridView anchor preservation via offset-delta.
    //
    // StaggeredGridView has no scrollview_observer integration; the package
    // uses an offset-delta snapshot (strategy=AnchorStrategy.offset). The
    // threshold is 80% of maxScrollExtent. Passes once T039 wires the
    // capture-before-fetch push and user-scroll detection in
    // _buildStaggeredGridView.
    // -----------------------------------------------------------------------
    testWidgets(
      'T26: anchor preservation works on StaggeredGridView via offset-delta',
      (tester) async {
        var callCount = 0;
        final scrollController = ScrollController();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              // Constrain the viewport so the page's content (10 rows × 50px
              // in a 2-column grid = 500px) overflows. Without this the
              // default 600px tester viewport leaves maxScrollExtent == 0 and
              // jumpTo cannot dispatch a ScrollUpdateNotification.
              body: SizedBox(
                height: 200,
                child: SmartPaginationStaggeredGridView<int,
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
                  crossAxisCount: 2,
                  scrollController: scrollController,
                  itemBuilder: (context, items, index) => StaggeredGridTile.fit(
                    crossAxisCellCount: 1,
                    child: SizedBox(
                      height: _itemHeight,
                      child: Text('Item ${items[index]}'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        final callsAfterInit = callCount;

        // Scroll to 85% of maxScrollExtent to cross the 80% trigger threshold.
        // A ScrollUpdateNotification fires, triggering the capture + fetch.
        final maxExtent = scrollController.position.maxScrollExtent;
        scrollController.jumpTo(maxExtent * 0.85);
        await tester.pump();
        await tester.pumpAndSettle();

        expect(
          callCount,
          callsAfterInit + 1,
          reason:
              'T26: exactly one load-more per 80%-threshold crossing on '
              'StaggeredGridView. If callCount > callsAfterInit + 1, the '
              'offset-delta restore or user-scroll suppression is not wired.',
        );

        scrollController.dispose();
      },
    );

    // -----------------------------------------------------------------------
    // Out-of-scope views (Spec FR-007 / US2 AS5)
    // -----------------------------------------------------------------------

    // -----------------------------------------------------------------------
    // T27: PageView is out of scope for anchor preservation.
    //
    // Expected final behavior (after T041): the anchor capture short-circuit
    // fires for pageView, captureAnchorBeforeLoadMore is never called, and
    // _suppressLoadMoreUntilUserScroll is never armed. The overflow-index
    // trigger fires on each page-to-end navigation.
    //
    // FAILS until T041 lands (currently suppression is set unconditionally
    // by fetchPaginatedList and is never cleared for PageView).
    // -----------------------------------------------------------------------
    testWidgets(
      'T27: anchor preservation is a no-op on PageView (no markUserScroll '
      'flag set, no _pendingAnchor)',
      (tester) async {
        var callCount = 0;
        final pageController = PageController();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SmartPaginationPageView<int, PaginationRequest>.withProvider(
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

        // Navigate to the last loaded page (index 4), which is in bounds.
        pageController.jumpToPage(4);
        await tester.pumpAndSettle();

        // The overflow-index slot (index == items.length) triggers load-more.
        // Navigate past the last page — this should trigger the first load-more.
        pageController.jumpToPage(5);
        await tester.pumpAndSettle();
        expect(callCount, 2, reason: 'First load-more via overflow-index.');

        // For a no-op view type (after T041): navigate to the new last-page
        // overflow index — should trigger ANOTHER load-more without any
        // user-scroll gesture needed to re-arm suppression.
        // FAILS until T041: suppression is currently set after first fetch.
        pageController.jumpToPage(10);
        await tester.pumpAndSettle();
        expect(
          callCount,
          greaterThanOrEqualTo(3),
          reason:
              'T27: second overflow-index navigation must also trigger '
              'load-more. Fails if suppression flag was armed for PageView '
              '(out-of-scope — suppress should never be set). Passes after T041.',
        );

        pageController.dispose();
      },
    );

    // -----------------------------------------------------------------------
    // T28: ReorderableListView is out of scope for anchor preservation.
    //
    // The ReorderableListView builder in the package has no automatic
    // load-more trigger in its item builder (by design). This test verifies
    // that the widget renders items correctly and that no exception is thrown.
    // Additionally verifies that manual load-more calls are not suppressed
    // by the anchor mechanism (after T041: suppress is never armed).
    //
    // FAILS until T041: currently suppression is set on any fetchPaginatedList
    // call and there is no NotificationListener on ReorderableListView to
    // call markUserScroll.
    // -----------------------------------------------------------------------
    testWidgets(
      'T28: anchor preservation is a no-op on ReorderableListView',
      (tester) async {
        var callCount = 0;

        // Use an external cubit so we can trigger load-more programmatically
        // without needing access to the widget's private state.
        final cubit = SmartPaginationCubit<int, PaginationRequest>(
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
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SmartPaginationReorderableListView<int,
                      PaginationRequest>.withCubit(
                cubit: cubit,
                itemBuilder: (context, items, index) => ListTile(
                  key: ValueKey(items[index]),
                  title: Text('Item ${items[index]}'),
                ),
                onReorder: (oldIndex, newIndex) {},
              ),
            ),
          ),
        );

        // Let the widget auto-trigger the initial fetch.
        await tester.pumpAndSettle();
        expect(callCount, 1, reason: 'Initial page loaded; no exception.');

        // Verify items are rendered.
        expect(find.text('Item 0'), findsOneWidget);

        // First programmatic load-more.
        cubit.fetchPaginatedList();
        await tester.pumpAndSettle();
        expect(callCount, 2);

        // Second programmatic load-more — must NOT be suppressed.
        // FAILS until T041: suppression is currently set after first load-more
        // call and there is no NotificationListener on ReorderableListView to
        // call markUserScroll, so suppression persists.
        cubit.fetchPaginatedList();
        await tester.pumpAndSettle();
        expect(
          callCount,
          3,
          reason:
              'T28: second manual fetchPaginatedList must not be blocked by '
              'the anchor-suppression flag. Passes after T041 short-circuits '
              'anchor logic for reorderableListView.',
        );

        await cubit.close();
      },
    );

    // -----------------------------------------------------------------------
    // T29: reverse: true is out of scope for anchor preservation.
    //
    // Expected final behavior (after T040): for reverse lists the anchor
    // capture short-circuit fires (_AnchorStrategySelector returns
    // proceed: false), captureAnchorBeforeLoadMore is never called, and
    // _suppressLoadMoreUntilUserScroll is never armed. Multiple load-more
    // fetches can fire in rapid succession without requiring a user-scroll
    // gesture to re-arm suppression.
    //
    // FAILS until T040 lands (currently the capture IS called for reverse
    // lists; the cubit's restore is a no-op for reverse, but suppression
    // is still set, blocking subsequent load-more until markUserScroll clears).
    // -----------------------------------------------------------------------
    testWidgets(
      'T29: anchor preservation is a no-op on any view with reverse: true',
      (tester) async {
        var callCount = 0;
        final scrollController = ScrollController();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SmartPaginationListView<int, PaginationRequest>.withProvider(
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
        );

        await tester.pumpAndSettle();
        expect(callCount, 1);
        final callsAfterInit = callCount;

        // In a reverse list the first item (index 0) is at the bottom.
        // Scrolling up (negative direction in screen space = positive direction
        // in data space) exposes higher-index items at the top.
        // Jump directly to the threshold position:
        // In reverse mode, maxScrollExtent is reached when the LAST item is at
        // the top. The trigger fires when the item at invisibleItemsThreshold
        // distance from the end is built.
        scrollController.jumpTo(scrollController.position.maxScrollExtent);
        await tester.pump();
        await tester.pumpAndSettle();

        expect(callCount, callsAfterInit + 1, reason: 'First load-more fired.');

        // For an out-of-scope view (after T040): immediately jump to the new
        // threshold — must trigger another load-more WITHOUT a user-scroll
        // gesture clearing suppression first.
        // FAILS until T040: capture is still called for reverse, suppression
        // is set, and the second jump (programmatic) does not call markUserScroll.
        scrollController.jumpTo(scrollController.position.maxScrollExtent);
        await tester.pump();
        await tester.pumpAndSettle();

        expect(
          callCount,
          callsAfterInit + 2,
          reason:
              'T29: second programmatic scroll-to-end on a reverse list must '
              'trigger another load-more without requiring a user-scroll gesture. '
              'Passes after T040 short-circuits anchor logic for reverse lists.',
        );

        scrollController.dispose();
      },
    );
  });
}
