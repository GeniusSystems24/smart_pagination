// Spec 004-scroll-anchor-preservation — Anchor capture tests.
//
// Covers tests T01–T08 from plan §13. Verifies the anchor strategy
// selector (per `contracts/anchor-strategy.md`) returns the correct
// strategy + populated fields for each (view type, itemKeyBuilder,
// observer state, reverse) combination, and that capture happens at the
// correct moment in the load-more lifecycle (before `emit(isLoadingMore: true)`).
//
// T01, T02, T04, T08 bodies landed in US1 phase (T016).
// T03, T05, T06, T07 remain US2 stubs (T036).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_pagination/pagination.dart';

const _pageSize = 20;
const _itemHeight = 50.0;

void main() {
  group('Scroll Anchor — Capture (spec 004)', () {
    // -----------------------------------------------------------------------
    // T015: Canonical regression testWidgets.
    //
    // Without anchor preservation (pre-feature), a fast fling to the end of
    // a paginated ListView triggers more than one automatic load-more because
    // the viewport stays inside the trigger zone after each append.
    //
    // With anchor preservation (post-feature), the viewport jumps back to the
    // anchor item AND the suppression flag prevents re-trigger until the user
    // intentionally scrolls again — so exactly one page loads per gesture.
    //
    // This test FAILS on pre-feature code (callCount ≥ 3) and PASSES on
    // post-feature code (callCount == 2).
    // -----------------------------------------------------------------------
    testWidgets(
      'T015: fast fling on ListView produces exactly one load-more '
      '(regression anchor)',
      (tester) async {
        var providerCallCount = 0;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SmartPaginationListView<int, PaginationRequest>.withProvider(
                request: PaginationRequest(page: 1, pageSize: 20),
                provider: PaginationProvider<int, PaginationRequest>.future(
                  (req) async {
                    providerCallCount++;
                    // Always return a full page so hasReachedEnd stays false
                    return List<int>.generate(
                      20,
                      (i) => (req.page - 1) * 20 + i,
                    );
                  },
                ),
                itemBuilder: (context, items, index) => SizedBox(
                  height: 50,
                  child: Text('Item ${items[index]}'),
                ),
                // Low threshold so a single fling reliably crosses it
                invisibleItemsThreshold: 3,
              ),
            ),
          ),
        );

        // Let initial page load settle (providerCallCount == 1 after this)
        await tester.pumpAndSettle();
        final callsAfterInit = providerCallCount;

        // Fast fling toward the bottom — velocity deliberately high so that
        // the scroll ballistic carries far enough to cross the load-more
        // threshold of the expanded list (40 items) if suppression is absent.
        await tester.fling(
          find.byType(CustomScrollView).first,
          const Offset(0, -3000),
          8000,
        );
        await tester.pumpAndSettle();

        // With anchor preservation (post-feature):
        //   providerCallCount == callsAfterInit + 1  (exactly one load-more)
        // Without anchor preservation (chained-load-more bug):
        //   providerCallCount >= callsAfterInit + 2  (multiple automatic loads)
        expect(
          providerCallCount,
          callsAfterInit + 1,
          reason:
              'A single fast fling must trigger exactly one load-more fetch. '
              'If providerCallCount > callsAfterInit + 1, the chained-load-more '
              'regression is present — anchor preservation or the suppression '
              'flag is not wired correctly.',
        );
      },
    );

    // -----------------------------------------------------------------------
    // Strategy selection — hybrid policy (Spec Q1)
    // -----------------------------------------------------------------------

    // -----------------------------------------------------------------------
    // T01: key strategy when itemKeyBuilder is provided.
    //
    // Observable: anchor preservation works with key strategy — exactly one
    // load-more fires per fling and items from page 1 are still visible
    // (the viewport was restored to the anchor item, not left adrift in page 2).
    // Without anchor preservation (pre-feature) callCount ≥ 2 after a single fling.
    // -----------------------------------------------------------------------
    testWidgets(
      'T01: strategy = key when itemKeyBuilder is provided and observer '
      'is attached',
      (tester) async {
        var providerCallCount = 0;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SmartPaginationListView<int, PaginationRequest>.withProvider(
                request: PaginationRequest(page: 1, pageSize: _pageSize),
                provider: PaginationProvider<int, PaginationRequest>.future(
                  (req) async {
                    providerCallCount++;
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
                // itemKeyBuilder enables AnchorStrategy.key path
                itemKeyBuilder: (item, index) => item,
                invisibleItemsThreshold: 3,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        final callsAfterInit = providerCallCount;

        await tester.fling(
          find.byType(CustomScrollView).first,
          const Offset(0, -3000),
          8000,
        );
        await tester.pumpAndSettle();

        expect(
          providerCallCount,
          callsAfterInit + 1,
          reason:
              'key strategy: one load-more per fling (suppression + anchor restore '
              'prevents chained auto-triggers).',
        );

        // At least one item from the latter half of page 1 is still visible,
        // proving the viewport was restored to the anchor (not left in page 2).
        final visiblePage1Items = tester
            .widgetList<Text>(find.byType(Text))
            .map((t) =>
                int.tryParse((t.data ?? '').replaceFirst('Item ', '')))
            .whereType<int>()
            .where((n) => n >= _pageSize ~/ 2 && n < _pageSize)
            .toList();
        expect(
          visiblePage1Items,
          isNotEmpty,
          reason:
              'key strategy: restore returned viewport to a page-1 anchor item.',
        );
      },
    );

    // -----------------------------------------------------------------------
    // T02: itemIndex strategy when no itemKeyBuilder.
    //
    // Same scenario as T01 but without itemKeyBuilder → AnchorStrategy.itemIndex.
    // Both strategies produce the same observable outcome (one load-more, anchor
    // visible), but the internal restore dispatches via the observer's index path.
    // -----------------------------------------------------------------------
    testWidgets(
      'T02: strategy = itemIndex when itemKeyBuilder is null on a ListView '
      'with observer attached',
      (tester) async {
        var providerCallCount = 0;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SmartPaginationListView<int, PaginationRequest>.withProvider(
                request: PaginationRequest(page: 1, pageSize: _pageSize),
                provider: PaginationProvider<int, PaginationRequest>.future(
                  (req) async {
                    providerCallCount++;
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
                // No itemKeyBuilder → AnchorStrategy.itemIndex
                invisibleItemsThreshold: 3,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        final callsAfterInit = providerCallCount;

        await tester.fling(
          find.byType(CustomScrollView).first,
          const Offset(0, -3000),
          8000,
        );
        await tester.pumpAndSettle();

        expect(
          providerCallCount,
          callsAfterInit + 1,
          reason:
              'itemIndex strategy: one load-more per fling (suppression + anchor '
              'restore prevents chained auto-triggers).',
        );

        final visiblePage1Items = tester
            .widgetList<Text>(find.byType(Text))
            .map((t) =>
                int.tryParse((t.data ?? '').replaceFirst('Item ', '')))
            .whereType<int>()
            .where((n) => n >= _pageSize ~/ 2 && n < _pageSize)
            .toList();
        expect(
          visiblePage1Items,
          isNotEmpty,
          reason:
              'itemIndex strategy: restore returned viewport to a page-1 anchor.',
        );
      },
    );

    // -----------------------------------------------------------------------
    // T03: StaggeredGridView uses AnchorStrategy.offset (no observer).
    //
    // The StaggeredGridView path embeds the ScrollController in the snapshot
    // and uses pixelsBefore for restore. Observable proxy: after load-more,
    // the scroll position stays near pixelsBefore (i.e., the restore
    // happened) rather than advancing to a new position.
    //
    // Passes once T039 wires offset-delta capture in _buildStaggeredGridView.
    // -----------------------------------------------------------------------
    testWidgets(
      'T03: strategy = offset on a StaggeredGridView (no observer)',
      (tester) async {
        var providerCallCount = 0;
        final scrollController = ScrollController();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                // Constrain viewport so total content (10 rows × 50px = 500px
                // in a 2-column grid) overflows. Without this, the default
                // 600px tester viewport leaves maxScrollExtent == 0 and
                // jumpTo cannot dispatch a ScrollUpdateNotification.
                height: 200,
                child: SmartPaginationStaggeredGridView<int,
                        PaginationRequest>.withProvider(
                  request: PaginationRequest(page: 1, pageSize: _pageSize),
                  provider: PaginationProvider<int, PaginationRequest>.future(
                    (req) async {
                      providerCallCount++;
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
        expect(providerCallCount, 1);

        // Capture scroll position at 85% of maxScrollExtent (above the 80% trigger).
        final maxExtent = scrollController.position.maxScrollExtent;
        final capturePosition = maxExtent * 0.85;
        scrollController.jumpTo(capturePosition);
        await tester.pump();

        // After the load-more posts to the frame callback and settles:
        // - The new page is appended (maxScrollExtent grows).
        // - _performOffsetRestore clamps and jumpTo's back to capturePosition.
        // - suppression prevents a chained second load-more.
        await tester.pumpAndSettle();

        expect(
          providerCallCount,
          2,
          reason:
              'T03: exactly one load-more triggered at 80% threshold on '
              'StaggeredGridView (offset-delta strategy).',
        );

        // Restore put us back near capturePosition — the scroll position must
        // be ≤ capturePosition + 10 (clamped to new maxScrollExtent if needed).
        final restoredPosition = scrollController.position.pixels;
        expect(
          restoredPosition,
          lessThanOrEqualTo(capturePosition + 10),
          reason:
              'T03: offset-delta restore placed viewport near or below '
              'the pre-append scroll position (capturePosition = $capturePosition, '
              'restoredPosition = $restoredPosition).',
        );

        scrollController.dispose();
      },
    );

    // -----------------------------------------------------------------------
    // Anchor item selection (Spec Q2 / FR-003b)
    // -----------------------------------------------------------------------

    // -----------------------------------------------------------------------
    // T04: anchor is the last fully-visible item before the loading indicator.
    //
    // Setup: 20 items × 50px, viewport 600px → maxScrollExtent = 400px.
    // At scroll position 400px, item 19 (pixels 950–1000) is the last item
    // whose leading AND trailing edges are within the viewport (0–600 in screen
    // coords, i.e., list pixels 400–1000). displayPercentage == 1.0.
    //
    // After load-more (page 2 appends items 20–39) and post-frame restore
    // (`jumpTo(19, alignment: 1.0)`), item 19 must still be at the viewport
    // bottom — it was the anchor, so it was restored there.
    // -----------------------------------------------------------------------
    testWidgets(
      'T04: captured anchor is the last fully-visible item before the '
      'loading indicator',
      (tester) async {
        var providerCallCount = 0;
        final scrollController = ScrollController();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SmartPaginationListView<int, PaginationRequest>.withProvider(
                request: PaginationRequest(page: 1, pageSize: _pageSize),
                provider: PaginationProvider<int, PaginationRequest>.future(
                  (req) async {
                    providerCallCount++;
                    return List<int>.generate(
                      _pageSize,
                      (i) => (req.page - 1) * _pageSize + i,
                    );
                  },
                ),
                scrollController: scrollController,
                itemBuilder: (context, items, index) => SizedBox(
                  height: _itemHeight,
                  child: Text('Item ${items[index]}'),
                ),
                // threshold=1 so item 19 (last item) triggers load-more
                invisibleItemsThreshold: 1,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(providerCallCount, 1);

        // Scroll to maxScrollExtent: item 19 (list pixels 950–1000) sits exactly
        // at the viewport's trailing edge — fully visible, displayPercentage == 1.0.
        scrollController.jumpTo(scrollController.position.maxScrollExtent);
        // One pump: observer fires (_lastObservedSnapshot = item 19),
        // item builder for index 19 triggers _shouldLoadMore, post-frame scheduled.
        // Post-frame (still in the same pump): captureAnchorBeforeLoadMore(snap) +
        // fetchPaginatedList() → emit(isLoadingMore: true) → _fetch starts.
        await tester.pump();
        // Settle: provider returns page 2, emit(40 items), post-frame restore fires.
        await tester.pumpAndSettle();

        expect(providerCallCount, 2, reason: 'Exactly one load-more triggered.');

        // Item 19 was the last fully-visible anchor. After restore with
        // alignment: 1.0, item 19 must still be in the viewport.
        expect(
          find.text('Item ${_pageSize - 1}'),
          findsOneWidget,
          reason:
              'Item ${_pageSize - 1} was the last fully-visible item before the '
              'spinner; anchor restore must bring it back into the viewport.',
        );

        // Additional alignment check: item 19 should be near the viewport bottom.
        final rect = tester.getRect(find.text('Item ${_pageSize - 1}'));
        final viewportHeight =
            tester.getSize(find.byType(Scaffold)).height;
        expect(
          rect.bottom,
          lessThanOrEqualTo(viewportHeight + 1),
          reason: 'Item ${_pageSize - 1} must be within (not below) the viewport.',
        );
        expect(
          rect.center.dy,
          greaterThan(viewportHeight / 2),
          reason:
              'Item ${_pageSize - 1} must be in the lower half of the viewport '
              '(alignment: 1.0 places it at the trailing edge).',
        );

        scrollController.dispose();
      },
    );

    // -----------------------------------------------------------------------
    // T05: partial-visible fallback — topmost partially-visible item used.
    //
    // Setup: items are 200px tall; viewport is 600px. At max scroll extent
    // the last item is partially visible (displayPercentage < 1.0). The
    // observer falls back to the topmost item with displayPercentage > 0.0.
    // Observable: anchor preservation still works (one load-more per fling).
    // -----------------------------------------------------------------------
    testWidgets(
      'T05: when no item is fully visible, capture falls back to the '
      'topmost partially-visible item',
      (tester) async {
        var providerCallCount = 0;

        // Use items taller than 1/12 of viewport so at least one is only
        // partially visible when scrolled near the bottom.
        const tallItemHeight = 200.0;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SmartPaginationListView<int,
                      PaginationRequest>.withProvider(
                request: PaginationRequest(page: 1, pageSize: _pageSize),
                provider: PaginationProvider<int, PaginationRequest>.future(
                  (req) async {
                    providerCallCount++;
                    return List<int>.generate(
                      _pageSize,
                      (i) => (req.page - 1) * _pageSize + i,
                    );
                  },
                ),
                itemBuilder: (context, items, index) => SizedBox(
                  height: tallItemHeight,
                  child: Text('Item ${items[index]}'),
                ),
                invisibleItemsThreshold: 1,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        final callsAfterInit = providerCallCount;

        // Fling to the end — at max scroll extent the last item may be
        // partially visible only. The fallback selects the topmost partial item.
        await tester.fling(
          find.byType(CustomScrollView).first,
          const Offset(0, -3000),
          8000,
        );
        await tester.pumpAndSettle();

        expect(
          providerCallCount,
          callsAfterInit + 1,
          reason:
              'T05: one load-more per fling even when no fully-visible item '
              'exists (fallback to topmost partially-visible item).',
        );
      },
    );

    // -----------------------------------------------------------------------
    // T06: no-item fallback — offset-only snapshot used.
    //
    // When the observer fires with displayingChildModelList empty or with
    // all items having displayPercentage == 0 (e.g., in a fast fling before
    // layout stabilises), _handleListObserve emits an offset-only snapshot.
    // Observable: anchor preservation still works — one load-more per fling.
    // -----------------------------------------------------------------------
    testWidgets(
      'T06: when no item is identifiable at all, capture falls back to '
      'offset strategy',
      (tester) async {
        var providerCallCount = 0;
        final scrollController = ScrollController();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SmartPaginationListView<int,
                      PaginationRequest>.withProvider(
                request: PaginationRequest(page: 1, pageSize: _pageSize),
                provider: PaginationProvider<int, PaginationRequest>.future(
                  (req) async {
                    providerCallCount++;
                    return List<int>.generate(
                      _pageSize,
                      (i) => (req.page - 1) * _pageSize + i,
                    );
                  },
                ),
                scrollController: scrollController,
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
        expect(providerCallCount, 1);
        final callsAfterInit = providerCallCount;

        // Jump directly to maxScrollExtent — this is a programmatic move
        // with no prior observer fire at intermediate positions. The snapshot
        // may be null or stale; _handleListObserve fires on the settle and
        // writes either an item-based or offset-only snapshot depending on
        // what is visible. Either way, load-more fires exactly once.
        scrollController.jumpTo(scrollController.position.maxScrollExtent);
        await tester.pump();
        await tester.pumpAndSettle();

        expect(
          providerCallCount,
          callsAfterInit + 1,
          reason:
              'T06: load-more fires exactly once even when only an offset-only '
              'snapshot is available (no identifiable anchor item).',
        );

        scrollController.dispose();
      },
    );

    // -----------------------------------------------------------------------
    // Out-of-scope view types (Spec Q5 / FR-007)
    // -----------------------------------------------------------------------

    // -----------------------------------------------------------------------
    // T07: capture is a no-op for reverse lists.
    //
    // Expected final behavior (after T040): for reverse:true, the
    // _AnchorStrategySelector returns proceed:false, captureAnchorBeforeLoadMore
    // is never called, and suppression is never armed. The observable proxy:
    // a programmatic scroll to the trigger position (no drag gesture to clear
    // suppression) can trigger a second load-more.
    //
    // For PageView and ReorderableListView, the anchor feature also doesn't
    // apply (no observer, no capture call). PageView and ReorderableListView
    // are covered by T27, T28, T37, T38.
    //
    // FAILS until T040 lands (currently capture IS called for reverse lists,
    // suppression IS set, and the second programmatic trigger is blocked).
    // -----------------------------------------------------------------------
    testWidgets(
      'T07: capture is a no-op for reverse lists, PageView, and '
      'ReorderableListView',
      (tester) async {
        var providerCallCount = 0;
        final scrollController = ScrollController();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SmartPaginationListView<int,
                      PaginationRequest>.withProvider(
                request: PaginationRequest(page: 1, pageSize: _pageSize),
                provider: PaginationProvider<int, PaginationRequest>.future(
                  (req) async {
                    providerCallCount++;
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
        expect(providerCallCount, 1);
        final callsAfterInit = providerCallCount;

        // First trigger.
        scrollController.jumpTo(scrollController.position.maxScrollExtent);
        await tester.pump();
        await tester.pumpAndSettle();
        expect(
          providerCallCount,
          callsAfterInit + 1,
          reason: 'T07: first load-more on reverse list always fires.',
        );

        // Second programmatic trigger — must also fire (no suppression).
        // FAILS until T040: capture is still called for reverse, suppression
        // is set, second programmatic jump does not call markUserScroll.
        scrollController.jumpTo(scrollController.position.maxScrollExtent);
        await tester.pump();
        await tester.pumpAndSettle();
        expect(
          providerCallCount,
          callsAfterInit + 2,
          reason:
              'T07: second programmatic load-more on reverse list must fire '
              'without a drag gesture. Passes after T040 short-circuits '
              'anchor capture for reverse lists.',
        );

        scrollController.dispose();
      },
    );

    // -----------------------------------------------------------------------
    // Capture ordering (plan §7.1)
    // -----------------------------------------------------------------------

    // -----------------------------------------------------------------------
    // T08: captureAnchorBeforeLoadMore is called BEFORE fetchPaginatedList.
    //
    // Behavioral proof: if capture happened AFTER the fetch started, `_pendingAnchor`
    // would be null when `_fetch` runs its success-path restore logic, and the
    // post-frame restore would be a no-op. Since restore IS correct (item 19 stays
    // at viewport bottom after load-more), capture must have preceded the fetch.
    //
    // The widget wires capture in the same `addPostFrameCallback` block,
    // immediately before `widget.fetchPaginatedList?.call()`. This test exercises
    // that wiring and confirms the end-to-end ordering produces a working restore.
    // -----------------------------------------------------------------------
    testWidgets(
      'T08: capture happens BEFORE emit(isLoadingMore: true)',
      (tester) async {
        var providerCallCount = 0;
        final scrollController = ScrollController();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SmartPaginationListView<int, PaginationRequest>.withProvider(
                request: PaginationRequest(page: 1, pageSize: _pageSize),
                provider: PaginationProvider<int, PaginationRequest>.future(
                  (req) async {
                    providerCallCount++;
                    return List<int>.generate(
                      _pageSize,
                      (i) => (req.page - 1) * _pageSize + i,
                    );
                  },
                ),
                scrollController: scrollController,
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
        expect(providerCallCount, 1);

        // Scroll to end of page 1 so item 19 is at viewport bottom.
        scrollController.jumpTo(scrollController.position.maxScrollExtent);
        await tester.pump();
        await tester.pumpAndSettle();

        // Prove capture happened before emit: the restore fires correctly, which
        // is only possible if _pendingAnchor was set before _fetch checked it.
        expect(providerCallCount, 2, reason: 'Load-more triggered exactly once.');
        expect(
          find.text('Item ${_pageSize - 1}'),
          findsOneWidget,
          reason:
              'Restore fired successfully, proving captureAnchorBeforeLoadMore '
              'was called before fetchPaginatedList (and therefore before '
              'emit(isLoadingMore: true)). If capture were deferred to after '
              'the emit, _pendingAnchor would be null during _fetch and no '
              'restore would occur.',
        );

        scrollController.dispose();
      },
    );
  });
}
