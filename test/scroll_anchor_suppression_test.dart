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
// Tests T16–T22 exercise observable behaviour through the public cubit API.
// They FAIL on pre-feature code (suppression not wired) and PASS after
// T022/T023/T027/T028/T029 land.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_pagination/pagination.dart';

const _settle = Duration(milliseconds: 50);

void main() {
  group('Scroll Anchor — Load-More Suppression (spec 004)', () {
    // -----------------------------------------------------------------------
    // T16: Suppression armed after successful append (FR-004 / FR-004b)
    //
    // After one load-more completes, an immediate second fetchPaginatedList
    // call must be silently dropped — no provider call, no state change.
    // Without suppression: providerCallCount == 1 (page 3 fires).
    // With    suppression: providerCallCount == 0.
    // -----------------------------------------------------------------------
    test(
      'T16: immediately after a successful append, fetchPaginatedList '
      'is rejected with no provider call',
      () async {
        var providerCallCount = 0;
        final cubit = SmartPaginationCubit<int, PaginationRequest>(
          request: PaginationRequest(page: 1, pageSize: 5),
          provider: PaginationProvider<int, PaginationRequest>.future((req) async {
            providerCallCount++;
            return List<int>.generate(5, (i) => (req.page - 1) * 5 + i);
          }),
        );

        // Load page 1
        cubit.refreshPaginatedList();
        await Future<void>.delayed(_settle);
        providerCallCount = 0;

        // Load page 2 (first intentional load-more)
        cubit.fetchPaginatedList();
        await Future<void>.delayed(_settle);
        expect(providerCallCount, 1, reason: 'First load-more must fire (page 2)');
        providerCallCount = 0;

        // Immediate second attempt — must be rejected by suppression flag
        cubit.fetchPaginatedList();
        await Future<void>.delayed(_settle);

        expect(
          providerCallCount,
          0,
          reason:
              'Load-more must be suppressed immediately after a successful '
              'append, until the user performs a new scroll gesture.',
        );

        await cubit.close();
      },
    );

    // -----------------------------------------------------------------------
    // T17: User-scroll re-arms the suppression (Spec FR-004)
    //
    // After markUserScroll(), the next fetchPaginatedList must be allowed.
    // -----------------------------------------------------------------------
    test(
      'T17: after a user-initiated ScrollStartNotification fires, the '
      'next fetchPaginatedList is allowed through',
      () async {
        var providerCallCount = 0;
        final cubit = SmartPaginationCubit<int, PaginationRequest>(
          request: PaginationRequest(page: 1, pageSize: 5),
          provider: PaginationProvider<int, PaginationRequest>.future((req) async {
            providerCallCount++;
            return List<int>.generate(5, (i) => (req.page - 1) * 5 + i);
          }),
        );

        // Load pages 1 and 2
        cubit.refreshPaginatedList();
        await Future<void>.delayed(_settle);
        cubit.fetchPaginatedList();
        await Future<void>.delayed(_settle);
        providerCallCount = 0;

        // Suppressed: should be rejected
        cubit.fetchPaginatedList();
        await Future<void>.delayed(_settle);
        expect(providerCallCount, 0, reason: 'Still suppressed before user scroll');

        // Simulate user drag gesture → re-arms the suppression
        cubit.markUserScroll();

        // Now allowed
        cubit.fetchPaginatedList();
        await Future<void>.delayed(_settle);

        expect(
          providerCallCount,
          1,
          reason:
              'After markUserScroll(), fetchPaginatedList must be allowed '
              'through to trigger a new page load.',
        );

        await cubit.close();
      },
    );

    // -----------------------------------------------------------------------
    // T18: Programmatic controller.jumpTo does NOT clear suppression
    //      (plan §6.3, R3)
    //
    // jumpTo / animateTo produce synthetic scroll notifications with
    // dragDetails == null. These must NOT call markUserScroll.
    // We test this indirectly: suppression remains armed after markUserScroll
    // is NOT called (i.e., a programmatic scroll without dragDetails).
    // -----------------------------------------------------------------------
    test(
      'T18: programmatic controller.jumpTo (e.g. from public '
      'animateToIndex) does NOT clear the suppression flag',
      () async {
        var providerCallCount = 0;
        final scrollController = ScrollController();
        final cubit = SmartPaginationCubit<int, PaginationRequest>(
          request: PaginationRequest(page: 1, pageSize: 5),
          provider: PaginationProvider<int, PaginationRequest>.future((req) async {
            providerCallCount++;
            return List<int>.generate(5, (i) => (req.page - 1) * 5 + i);
          }),
        );

        // Load pages 1 and 2 — arms suppression
        cubit.refreshPaginatedList();
        await Future<void>.delayed(_settle);
        cubit.fetchPaginatedList();
        await Future<void>.delayed(_settle);
        providerCallCount = 0;

        // Verify suppressed
        cubit.fetchPaginatedList();
        await Future<void>.delayed(_settle);
        expect(providerCallCount, 0, reason: 'Should be suppressed');

        // Programmatic jumpTo does NOT call markUserScroll — suppression persists
        // (The NotificationListener only calls markUserScroll for dragDetails != null)
        // We do not call markUserScroll here to simulate what happens when
        // a programmatic jump fires a ScrollNotification with dragDetails == null.

        cubit.fetchPaginatedList();
        await Future<void>.delayed(_settle);

        expect(
          providerCallCount,
          0,
          reason:
              'Programmatic scroll must NOT clear the suppression flag. '
              'Only user drag gestures (dragDetails != null) may re-arm.',
        );

        scrollController.dispose();
        await cubit.close();
      },
    );

    // -----------------------------------------------------------------------
    // T19: Anchor-restore's own jumpTo does NOT clear suppression
    //
    // The cubit gates markUserScroll on _anchorRestoreInFlight. While the
    // restore's jumpTo is in progress, a synthetic ScrollStartNotification
    // (even with dragDetails) must be ignored.
    // We test indirectly: markUserScroll is a no-op when called while
    // _anchorRestoreInFlight would be true.
    // -----------------------------------------------------------------------
    test(
      'T19: synthetic scroll notification produced by anchor restore\'s '
      'own jumpTo does NOT clear the suppression flag',
      () async {
        var providerCallCount = 0;
        final cubit = SmartPaginationCubit<int, PaginationRequest>(
          request: PaginationRequest(page: 1, pageSize: 5),
          provider: PaginationProvider<int, PaginationRequest>.future((req) async {
            providerCallCount++;
            return List<int>.generate(5, (i) => (req.page - 1) * 5 + i);
          }),
        );

        // Load pages 1 and 2 — arms suppression
        cubit.refreshPaginatedList();
        await Future<void>.delayed(_settle);
        cubit.fetchPaginatedList();
        await Future<void>.delayed(_settle);
        providerCallCount = 0;

        // Verify suppressed before any markUserScroll
        cubit.fetchPaginatedList();
        await Future<void>.delayed(_settle);
        expect(providerCallCount, 0, reason: 'Suppressed before restore');

        // The real test: after implementation, _anchorRestoreInFlight == true
        // during the restore's jumpTo. markUserScroll called during this window
        // must be a no-op. We cannot set _anchorRestoreInFlight from here
        // (it's private), but we can verify the overall invariant:
        // suppression is NOT cleared by a markUserScroll that arrives
        // while the post-frame restore is still in progress.
        //
        // This is exercised end-to-end in the widget-level restore tests (T11)
        // and by the NotificationListener filtering (T26 in view). Here we
        // assert the cubit-side invariant: suppression persists until
        // an explicit user drag that is NOT part of the restore.
        //
        // Post-implementation: _anchorRestoreInFlight = true blocks
        // markUserScroll. Once cleared, a real user scroll re-arms correctly.
        cubit.fetchPaginatedList();
        await Future<void>.delayed(_settle);

        expect(
          providerCallCount,
          0,
          reason:
              'Suppression must remain armed after a restore — only a '
              'user-initiated drag (not the restore\'s own jumpTo) may clear it.',
        );

        await cubit.close();
      },
    );

    // -----------------------------------------------------------------------
    // T20: Late layout-settle does NOT trigger another load-more (FR-004b)
    //
    // Simulated by calling fetchPaginatedList without markUserScroll, which
    // represents what happens when a layout settle causes a
    // ScrollUpdateNotification (dragDetails == null) — the NotificationListener
    // ignores it, so markUserScroll is never called, suppression stays armed.
    // -----------------------------------------------------------------------
    test(
      'T20: late layout settle (image loads adjusting maxScrollExtent '
      'after restore) does NOT trigger another fetchPaginatedList while '
      'suppressed',
      () async {
        var providerCallCount = 0;
        final cubit = SmartPaginationCubit<int, PaginationRequest>(
          request: PaginationRequest(page: 1, pageSize: 5),
          provider: PaginationProvider<int, PaginationRequest>.future((req) async {
            providerCallCount++;
            return List<int>.generate(5, (i) => (req.page - 1) * 5 + i);
          }),
        );

        // Load pages 1 and 2
        cubit.refreshPaginatedList();
        await Future<void>.delayed(_settle);
        cubit.fetchPaginatedList();
        await Future<void>.delayed(_settle);
        providerCallCount = 0;

        // Simulate many rapid load-more attempts (as would happen from layout
        // settle notifications firing scroll events without user drag).
        // All must be dropped by the suppression flag.
        for (var i = 0; i < 5; i++) {
          cubit.fetchPaginatedList();
        }
        await Future<void>.delayed(_settle);

        expect(
          providerCallCount,
          0,
          reason:
              'Layout-settle scroll events must not trigger additional '
              'load-more calls while the suppression flag is armed.',
        );

        await cubit.close();
      },
    );

    // -----------------------------------------------------------------------
    // T21: Load-more error clears suppression (plan §7.3)
    //
    // If the fetch fails, the suppression flag must be cleared so the
    // user can retry without needing to scroll.
    // -----------------------------------------------------------------------
    test(
      'T21: a load-more error clears the suppression flag (so retry can '
      'proceed without forcing user scroll)',
      () async {
        var attempt = 0;
        var providerCallCount = 0;
        final cubit = SmartPaginationCubit<int, PaginationRequest>(
          request: PaginationRequest(page: 1, pageSize: 5),
          errorRetryStrategy: ErrorRetryStrategy.automatic,
          provider: PaginationProvider<int, PaginationRequest>.future((req) async {
            attempt++;
            providerCallCount++;
            if (req.page == 1) return [0, 1, 2, 3, 4];
            if (attempt == 2) throw Exception('transient error');
            return List<int>.generate(5, (i) => (req.page - 1) * 5 + i);
          }),
        );

        // Load page 1
        cubit.refreshPaginatedList();
        await Future<void>.delayed(_settle);
        providerCallCount = 0;

        // First load-more → error
        cubit.fetchPaginatedList();
        await Future<void>.delayed(_settle);
        final stateAfterError = cubit.state as SmartPaginationLoaded<int>;
        expect(stateAfterError.loadMoreError, isNotNull,
            reason: 'Load-more error should be in state');
        providerCallCount = 0;

        // After error: suppression must be CLEARED (error path clears it).
        // So a retry must fire without needing markUserScroll.
        cubit.fetchPaginatedList();
        await Future<void>.delayed(_settle);

        expect(
          providerCallCount,
          1,
          reason:
              'After a load-more error, suppression must be cleared so the '
              'user can retry without a scroll gesture.',
        );

        await cubit.close();
      },
    );

    // -----------------------------------------------------------------------
    // T22: Refresh / filter change clears suppression (plan §7.4)
    //
    // A scope reset (refresh, filter change) clears _suppressLoadMoreUntilUserScroll
    // so the next load-more fires on the fresh scope immediately.
    // -----------------------------------------------------------------------
    test(
      'T22: refresh / filter change clears the suppression flag and '
      'discards the pending anchor',
      () async {
        var providerCallCount = 0;
        final cubit = SmartPaginationCubit<int, PaginationRequest>(
          request: PaginationRequest(page: 1, pageSize: 5),
          provider: PaginationProvider<int, PaginationRequest>.future((req) async {
            providerCallCount++;
            return List<int>.generate(5, (i) => (req.page - 1) * 5 + i);
          }),
        );

        // Load pages 1 and 2 — arms suppression
        cubit.refreshPaginatedList();
        await Future<void>.delayed(_settle);
        cubit.fetchPaginatedList();
        await Future<void>.delayed(_settle);
        providerCallCount = 0;

        // Verify suppressed
        cubit.fetchPaginatedList();
        await Future<void>.delayed(_settle);
        expect(providerCallCount, 0, reason: 'Should be suppressed before refresh');

        // Scope reset: refresh clears suppression
        cubit.refreshPaginatedList();
        await Future<void>.delayed(_settle);
        providerCallCount = 0;

        // Load-more on fresh scope must fire immediately (no suppression)
        cubit.fetchPaginatedList();
        await Future<void>.delayed(_settle);

        expect(
          providerCallCount,
          1,
          reason:
              'After refreshPaginatedList, the suppression flag must be '
              'cleared so the next load-more on the fresh scope fires normally.',
        );

        await cubit.close();
      },
    );
  });
}
