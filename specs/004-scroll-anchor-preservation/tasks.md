# Tasks: Scroll Anchor Preservation

**Input**: Design documents from `specs/004-scroll-anchor-preservation/`
**Feature Branch**: `004-scroll-anchor-preservation`
**Date**: 2026-05-05
**Approach**: Test-First (TDD) — Write failing tests before each implementation phase

## Format: `[TaskID] [P?] [Story?] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[Story]**: US1 / US2 / US3 maps to user stories from spec.md
- **Test-First Rule**: Within each user-story phase, all tests for that phase must be written and confirmed failing BEFORE implementation begins
- Each task lists: Files affected, Description, Acceptance, Dependencies, Parallel

---

## Phase 1: Audit — Current Scroll Trigger and Append Behavior

**Purpose**: Read and annotate the current flow before any code changes. No production code is modified here. This phase has no user-story label.

- [x] T001 Annotate `fetchPaginatedList` guard chain in `lib/smart_pagination/bloc/pagination_cubit.dart`
  - **Files**: `pagination_cubit.dart` (lines ~741–820, the existing 8-step guard chain landed by feature `003-load-more-guard`)
  - **Description**: Read the existing guards in order. Add inline `// AUDIT 004:` comments labelling where the new `_suppressLoadMoreUntilUserScroll` step will be inserted (between `_activeLoadMoreKey == loadMoreKey` and `currentState.isLoadingMore`), and where the new flag-setting and `_pendingAnchor` consumption will live. Confirm line numbers match plan.md §7.1.
  - **Acceptance**: Insertion sites for the new guard step (between current step 6 and step 7) and for the flag-set / capture-consume (currently between step 9 and step 10 conceptually) are explicitly marked with `// AUDIT 004:` comments. File compiles unchanged.
  - **Dependencies**: none
  - **Parallel**: No — must be read before T002 and other annotations touch the same file

- [x] T002 [P] Annotate item-builder load-more trigger sites in `lib/smart_pagination/widgets/paginate_api_view.dart`
  - **Files**: `paginate_api_view.dart` (lines 392–398 `_shouldLoadMore`; lines 443–452, 474–483, 645–654, 685–694 `addPostFrameCallback` blocks)
  - **Description**: Confirm each existing item-builder trigger wraps `widget.fetchPaginatedList?.call()` in `SchedulerBinding.instance.addPostFrameCallback`. Add `// AUDIT 004:` comments at each block marking the spot where the new `cubit.captureAnchorBeforeLoadMore(snapshot)` call will be inserted *immediately before* the existing `fetchPaginatedList` call.
  - **Acceptance**: All four item-builder trigger sites and the `_buildPageView` overflow-index trigger (line 833) carry `// AUDIT 004:` annotations. No production-code changes.
  - **Dependencies**: none
  - **Parallel**: Yes — different file from T001

- [x] T003 [P] Annotate `scrollview_observer` integration points in `lib/smart_pagination/widgets/paginate_api_view.dart` and `lib/smart_pagination/bloc/pagination_cubit.dart`
  - **Files**: `paginate_api_view.dart` (lines 195–197, 211–212, 234–258); `pagination_cubit.dart` (lines 2352–2427)
  - **Description**: Confirm `_listObserverController` / `_gridObserverController` are constructed in `_initializeObserver` and attached to the cubit via `attachListObserverController` / `attachGridObserverController`. Confirm the cubit already exposes them via `listObserverController` / `gridObserverController` getters. Add `// AUDIT 004:` comments marking where `onObserve` callback wiring will be added (initState path) for `_lastObservedSnapshot` maintenance.
  - **Acceptance**: Observer construction, attachment, and detachment paths are annotated; the place to subscribe to `onObserve` is identified.
  - **Dependencies**: T001 (file in cache) — but different file in widget side, runs alongside
  - **Parallel**: Yes after T001 starts

- [x] T004 [P] Annotate `StaggeredGridView` notification path in `lib/smart_pagination/widgets/paginate_api_view.dart`
  - **Files**: `paginate_api_view.dart` (lines 855–917, `_buildStaggeredGridView`)
  - **Description**: Confirm the existing `NotificationListener<ScrollNotification>` block fires `addPostFrameCallback(fetchPaginatedList)` when `pixels >= maxScrollExtent * 0.8`. Add `// AUDIT 004:` annotations marking (a) the spot to capture `pixelsBefore` / `extentBefore` for offset-delta strategy and push to cubit, and (b) the spot to wire user-scroll detection (a `ScrollStartNotification` filter on the same listener).
  - **Acceptance**: Both insertion points annotated.
  - **Dependencies**: none
  - **Parallel**: Yes

- [x] T005 [P] Annotate dispose paths and scope-reset paths in `lib/smart_pagination/bloc/pagination_cubit.dart`
  - **Files**: `pagination_cubit.dart` (around lines 555–568 `_resetToInitial`, lines 625–680 `refreshPaginatedList`, the `dispose` site, and lines 1095–1096 in `_fetch` finally)
  - **Description**: Confirm where the existing `_isFetching = false` and `_activeLoadMoreKey = null` clears happen. Add `// AUDIT 004:` comments listing the three new fields that must be cleared on these paths: `_pendingAnchor = null`, `_suppressLoadMoreUntilUserScroll = false`, `_anchorRestoreInFlight = false`.
  - **Acceptance**: All three scope-reset code sites are annotated with the list of new fields to clear.
  - **Dependencies**: T001
  - **Parallel**: Yes after T001

**Checkpoint**: Audit complete. Insertion sites for every code change in subsequent phases are explicitly marked. No production behavior changed.

---

## Phase 2: Foundational — Internal State Model and Test Scaffolds

**Purpose**: Add the private types and field declarations that all subsequent phases depend on, plus create empty test files with stubs so each phase can fill in test bodies in red-baseline order. This phase has no user-story label.

**⚠️ CRITICAL**: No user-story phase can begin until this phase completes.

- [x] T006 Add `_PendingScrollAnchor`, `AnchorStrategy`, `_AnchorViewType` private types in `lib/smart_pagination/bloc/pagination_state.dart`
  - **Files**: `pagination_state.dart` (alongside the existing `_PageStreamEntry`)
  - **Description**: Implement the three private types per `data-model.md` §1, §2, §3. Include dartdoc per the schemas. No public exports change.
  - **Acceptance**: File compiles. `flutter analyze` reports no new issues. The types exist but are not yet used.
  - **Dependencies**: T001–T005 (audit complete)
  - **Parallel**: No — must be in place before T007 and tests

- [x] T007 Add new private fields to `SmartPaginationCubit` in `lib/smart_pagination/bloc/pagination_cubit.dart`
  - **Files**: `pagination_cubit.dart` (declarations block around lines 161–230)
  - **Description**: Add `_pendingAnchor`, `_suppressLoadMoreUntilUserScroll = false`, `_lastUserScrollGeneration = 0`, `_anchorRestoreInFlight = false` fields per `data-model.md` §4. Also add `import 'package:meta/meta.dart' show internal;` if not already present. Initialize all in declaration; no behavior wired yet.
  - **Acceptance**: File compiles; existing tests still pass (no behavior change yet).
  - **Dependencies**: T006
  - **Parallel**: No — same file as later cubit changes

- [x] T008 Add stub `@internal` methods `captureAnchorBeforeLoadMore` and `markUserScroll` to `SmartPaginationCubit` in `lib/smart_pagination/bloc/pagination_cubit.dart`
  - **Files**: `pagination_cubit.dart`
  - **Description**: Add the two methods per `contracts/public-api-surface.md` §A3, §A4. Bodies are no-ops in this task: `captureAnchorBeforeLoadMore` does `_pendingAnchor = snapshot;` only; `markUserScroll` does `_lastUserScrollGeneration++;` only. The full clearing/guard logic lands in US1 phase.
  - **Acceptance**: File compiles. Methods are callable. Existing tests still pass.
  - **Dependencies**: T007
  - **Parallel**: No — same file as T007

- [x] T009 [P] Create `test/scroll_anchor_capture_test.dart` with 8 test stubs (T01–T08 from plan §13)
  - **Files**: `test/scroll_anchor_capture_test.dart` (new file)
  - **Description**: Create a Dart test file with `group('Scroll Anchor — Capture', () { ... })` containing 8 `test(...)` calls — names match plan §13 exactly. Each body = `fail('not yet implemented');`. Add imports for `flutter_test`, `bloc_test`, the cubit/state, and `mocktail`.
  - **Acceptance**: `flutter test test/scroll_anchor_capture_test.dart` reports 8 failures with message "not yet implemented".
  - **Dependencies**: T006
  - **Parallel**: Yes — different files from T010–T014

- [x] T010 [P] Create `test/scroll_anchor_restore_test.dart` with 7 test stubs (T09–T15)
  - **Files**: `test/scroll_anchor_restore_test.dart` (new file)
  - **Description**: `group('Scroll Anchor — Restore', () { ... })` with 7 stubs named per plan §13.
  - **Acceptance**: 7 failures on run.
  - **Dependencies**: T006
  - **Parallel**: Yes

- [x] T011 [P] Create `test/scroll_anchor_suppression_test.dart` with 7 test stubs (T16–T22)
  - **Files**: `test/scroll_anchor_suppression_test.dart` (new file)
  - **Description**: `group('Scroll Anchor — Load-More Suppression', () { ... })` with 7 stubs.
  - **Acceptance**: 7 failures on run.
  - **Dependencies**: T006
  - **Parallel**: Yes

- [x] T012 [P] Create `test/scroll_anchor_view_type_matrix_test.dart` with 7 test stubs (T23–T29)
  - **Files**: `test/scroll_anchor_view_type_matrix_test.dart` (new file)
  - **Description**: `group('Scroll Anchor — View-Type Matrix', () { ... })` with 7 stubs.
  - **Acceptance**: 7 failures on run.
  - **Dependencies**: T006
  - **Parallel**: Yes

- [x] T013 [P] Create `test/scroll_anchor_compatibility_test.dart` with 6 test stubs (T30–T35)
  - **Files**: `test/scroll_anchor_compatibility_test.dart` (new file)
  - **Description**: `group('Scroll Anchor — Backward Compatibility', () { ... })` with 6 stubs.
  - **Acceptance**: 6 failures on run.
  - **Dependencies**: T006
  - **Parallel**: Yes

- [x] T014 [P] Create `test/scroll_anchor_fallthrough_test.dart` with 3 test stubs (T36–T38)
  - **Files**: `test/scroll_anchor_fallthrough_test.dart` (new file)
  - **Description**: `group('Scroll Anchor — Out-of-Scope View Fall-Through', () { ... })` with 3 stubs.
  - **Acceptance**: 3 failures on run.
  - **Dependencies**: T006
  - **Parallel**: Yes

**Checkpoint**: Foundation ready. All test files exist with red baselines. The cubit's anchor data fields exist but no anchor logic is wired yet. User-story phases can now proceed.

---

## Phase 3: User Story 1 — Stable viewport after appending a page (Priority: P1) 🎯 MVP

**Goal**: A single fast scroll-to-end on a paginated `ListView` produces exactly one load-more, and the previously-visible last item remains in the same on-screen position after the new page is appended.

**Independent Test**: `tester.fling` on a paginated `ListView` backed by an always-full-page mock provider; pump for 2 seconds; assert (a) `mockProvider.callCount == 2` (initial + 1 load-more), (b) the row that was at the bottom of the viewport before the fling is still at the bottom of the viewport (±1 row) after the fling completes, (c) no further load-more fires until the test simulates a new drag-scroll gesture.

### Tests for User Story 1 (TDD red baseline)

- [ ] T015 [US1] Add the canonical regression `testWidgets` to `test/scroll_anchor_capture_test.dart`
  - **Files**: `test/scroll_anchor_capture_test.dart`
  - **Description**: Replace the appropriate stub with a `testWidgets('fast fling on ListView produces exactly one load-more', (tester) async { ... })` that builds a `SmartPaginationListView` backed by a mock provider returning 20 items per page, performs `tester.fling(find.byType(ListView), Offset(0, -2000), 5000)`, then `await tester.pumpAndSettle(Duration(milliseconds: 200))`. Assertions: `mockProvider.callCount == 2`. Without anchor preservation, `callCount` ≥ 3.
  - **Acceptance**: Test compiles; runs against current code; **fails** with `mockProvider.callCount` > 2. This is the regression anchor.
  - **Dependencies**: T009
  - **Parallel**: No — same file as later capture-test bodies

- [ ] T016 [P] [US1] Implement capture test bodies in `test/scroll_anchor_capture_test.dart` for the in-scope `ListView` path (T01, T02, T04, T08)
  - **Files**: `test/scroll_anchor_capture_test.dart`
  - **Description**: Replace four stubs with full bodies: T01 strategy=key when `itemKeyBuilder` provided, T02 strategy=index when not, T04 anchor is the last fully-visible item before spinner, T08 capture happens before `emit(isLoadingMore: true)` (verified via a synchronous emit-listener that snapshots `cubit._pendingAnchor` at emit time). Use a `_TestFakeObserverSnapshot` helper that lets the test feed a synthetic `displayingChildModelList`.
  - **Acceptance**: All four tests run; **fail** because capture is not yet wired.
  - **Dependencies**: T015
  - **Parallel**: Yes once T015 is in (different segments of same file? No — same file). Mark `[P]` only if tests live in separate files.
  - **Note**: This task lives in the same file as T015, so it is **not** parallelisable with T015 — execute sequentially. The `[P]` here applies to the relationship with T017 / T018 (which are in different files).

- [ ] T017 [P] [US1] Implement restore test bodies in `test/scroll_anchor_restore_test.dart` for `ListView` (T09, T10, T11, T15)
  - **Files**: `test/scroll_anchor_restore_test.dart`
  - **Description**: Fill four stubs: T09 anchor item within ±1 row of pre-append position after fling+append, T10 restore happens in a post-frame callback (verified by spying on `WidgetsBinding.instance.scheduleFrameCallback`), T11 restore goes through `_listObserverController.jumpTo(index, alignment: 1.0)` (verified via a fake observer controller that records calls), T15 generation mismatch causes restore to no-op.
  - **Acceptance**: Four tests **fail** before implementation.
  - **Dependencies**: T010
  - **Parallel**: Yes — different file from T016, T018

- [ ] T018 [P] [US1] Implement suppression test bodies in `test/scroll_anchor_suppression_test.dart` (T16–T22)
  - **Files**: `test/scroll_anchor_suppression_test.dart`
  - **Description**: Fill seven stubs: T16 reject second `fetchPaginatedList` immediately after append, T17 user-`ScrollStartNotification` clears suppression, T18 programmatic `controller.jumpTo` does NOT clear, T19 anchor-restore's own jumpTo does NOT clear, T20 late image-load layout settle does NOT trigger another fetch, T21 load-more error clears suppression, T22 refresh/filter clears.
  - **Acceptance**: Seven tests **fail** before implementation.
  - **Dependencies**: T011
  - **Parallel**: Yes

### Implementation for User Story 1

- [ ] T019 [US1] Subscribe to observer's `onObserve` callback in `_PaginateApiViewState._initializeObserver` in `lib/smart_pagination/widgets/paginate_api_view.dart`
  - **Files**: `paginate_api_view.dart` (around lines 234–258)
  - **Description**: Add a private method `_handleObserve(ObserveModel model)` that computes a fresh `_PendingScrollAnchor` snapshot per `contracts/anchor-strategy.md` §`findAnchorItem` (last fully-visible item). Wire it via `ListObserverController(controller: _effectiveScrollController, onObserve: _handleObserve)` and the equivalent for `GridObserverController`. Store the result in `_lastObservedSnapshot`. Add subscription cleanup in `dispose`.
  - **Acceptance**: `_lastObservedSnapshot` is non-null after the first observer fire on a populated list. No existing tests break.
  - **Dependencies**: T002, T003, T007, T008
  - **Parallel**: No — same file as T020, T021, T027

- [ ] T020 [US1] Implement `_AnchorStrategySelector.compute(...)` policy in `_PaginateApiViewState` in `lib/smart_pagination/widgets/paginate_api_view.dart`
  - **Files**: `paginate_api_view.dart` (new private method on state class)
  - **Description**: Implement the selection algorithm from `contracts/anchor-strategy.md` precisely: out-of-scope short-circuit → staggered → no-snapshot fallback → key vs. index → field population. Returns `_PendingScrollAnchor?` (null when `proceed: false`).
  - **Acceptance**: Unit-callable from tests via a package-internal export (`@internal` re-export from `pagination.dart`). Returns the right strategy for every input combination per the contract table.
  - **Dependencies**: T019
  - **Parallel**: No — same file

- [ ] T021 [US1] Wire capture-before-fetch push from `_buildListView` trigger sites in `lib/smart_pagination/widgets/paginate_api_view.dart`
  - **Files**: `paginate_api_view.dart` (lines 645–654 animated path, 685–694 sliver-list path)
  - **Description**: Inside each `addPostFrameCallback` block, before the existing `widget.fetchPaginatedList?.call()`, add: `if (widget.preserveScrollAnchorOnAppend && widget.cubit != null) { final snap = _AnchorStrategySelector.compute(...); if (snap != null) widget.cubit!.captureAnchorBeforeLoadMore(snap); }`. Note: `preserveScrollAnchorOnAppend` parameter does not exist yet (added in US3) — for US1 use a feature-flag boolean private constant `const _kCaptureEnabled = true;` and replace with the parameter in T046.
  - **Acceptance**: T01, T02, T04, T08 from T016 still fail because cubit-side consume + restore are not wired yet, but the snapshot now reaches `cubit._pendingAnchor`. Existing tests still pass.
  - **Dependencies**: T020
  - **Parallel**: No — same file

- [ ] T022 [US1] Add `_suppressLoadMoreUntilUserScroll` guard step into `fetchPaginatedList` in `lib/smart_pagination/bloc/pagination_cubit.dart`
  - **Files**: `pagination_cubit.dart` (lines ~801–820)
  - **Description**: Per `plan.md` §7.1, insert the new guard between the existing `_activeLoadMoreKey == loadMoreKey` check and the `currentState.isLoadingMore` check: `if (_suppressLoadMoreUntilUserScroll) { return; }`. Update the inline comment block enumerating the guard order.
  - **Acceptance**: T16 from T018 turns from generic-fail to "second call returns silently" (still fails because suppression flag is not yet set anywhere — that's T024).
  - **Dependencies**: T007, T021
  - **Parallel**: No — same file as T024–T030

- [ ] T023 [US1] Set suppression flag and capture timing in `fetchPaginatedList` accept path in `lib/smart_pagination/bloc/pagination_cubit.dart`
  - **Files**: `pagination_cubit.dart` (lines ~815–820, immediately before `emit(isLoadingMore: true)`)
  - **Description**: Per `plan.md` §7.1 step 11, add `_suppressLoadMoreUntilUserScroll = true;` immediately after `_activeLoadMoreKey = loadMoreKey;` and before `emit(...)`. The capture flag setting happens via the widget's `captureAnchorBeforeLoadMore` push earlier in the call chain (T021); ensure that when the cubit accepts this fetch, `_pendingAnchor` is already populated (or null, in which case no restore happens).
  - **Acceptance**: T16 now passes the "second call rejected" assertion. Other suppression tests still fail (they need user-scroll re-arm + restore).
  - **Dependencies**: T022
  - **Parallel**: No — same file

- [ ] T024 [US1] Implement post-frame restore orchestration in `_fetch` success path in `lib/smart_pagination/bloc/pagination_cubit.dart`
  - **Files**: `pagination_cubit.dart` (after the `emit(SmartPaginationLoaded(... isLoadingMore: false ...))` for the load-more success branch)
  - **Description**: After the success emit, if `_pendingAnchor != null`, set `_anchorRestoreInFlight = true` and schedule `WidgetsBinding.instance.addPostFrameCallback((_) async { _performAnchorRestore(_pendingAnchor!); _pendingAnchor = null; await SchedulerBinding.instance.endOfFrame; _anchorRestoreInFlight = false; });`. The `_performAnchorRestore` private method dispatches by strategy per `contracts/anchor-strategy.md` "Restore mechanism by strategy".
  - **Acceptance**: T09, T10, T11, T15 turn green. T16 stays green.
  - **Dependencies**: T023
  - **Parallel**: No — same file

- [ ] T025 [US1] Implement `_performAnchorRestore(_PendingScrollAnchor anchor)` dispatcher in `lib/smart_pagination/bloc/pagination_cubit.dart`
  - **Files**: `pagination_cubit.dart`
  - **Description**: Implement the strategy-dispatch per `contracts/anchor-strategy.md` "Restore mechanism by strategy": generation check → `key` strategy looks up new index via the consumer-supplied key extractor exposed through the cubit, then calls `_listObserverController!.jumpTo(...)` (or grid). `index` strategy goes directly. `offset` falls back to the `_effectiveScrollController` reference. Defensive: every branch can no-op safely. The cubit holds a weak reference to the active controller via the existing observer integration; for the offset-only `StaggeredGridView` path, the widget pushes a controller-position-reading closure into the snapshot itself (the `pixelsBefore` field is already populated at capture time).
  - **Acceptance**: All paths execute without throwing; T11, T12 (when staggered lands in US2) pass for `ListView`.
  - **Dependencies**: T024
  - **Parallel**: No — same file

- [ ] T026 [US1] Add outer `NotificationListener<ScrollNotification>` to `_buildListView` in `lib/smart_pagination/widgets/paginate_api_view.dart`
  - **Files**: `paginate_api_view.dart` (around lines 727–744 — wrap the existing `CustomScrollView` and the optional `ListViewObserver`)
  - **Description**: Wrap the returned scroll view in `NotificationListener<ScrollNotification>(onNotification: (n) { if (n is ScrollStartNotification && n.dragDetails != null && widget.cubit != null) { widget.cubit!.markUserScroll(); } return false; }, child: <existing>)`. The `return false` is critical — it MUST NOT consume the notification.
  - **Acceptance**: T17 (user-scroll clears suppression) passes. Existing scroll-related tests still pass.
  - **Dependencies**: T025
  - **Parallel**: No — same file

- [ ] T027 [US1] Implement full `markUserScroll()` body in `lib/smart_pagination/bloc/pagination_cubit.dart`
  - **Files**: `pagination_cubit.dart`
  - **Description**: Replace the T008 stub: `void markUserScroll() { _lastUserScrollGeneration++; if (!_anchorRestoreInFlight) { _suppressLoadMoreUntilUserScroll = false; } }`. Per `contracts/public-api-surface.md` §A4 and `data-model.md` §4 transitions.
  - **Acceptance**: T17 stays green. T19 (anchor-restore's own jumpTo does NOT clear) turns green because `_anchorRestoreInFlight` is true during the synthetic notification. T18 (programmatic `controller.jumpTo` does NOT clear) turns green because the synthetic notification has `dragDetails == null` so `markUserScroll` is never called.
  - **Dependencies**: T026
  - **Parallel**: No — same file as T024–T029

- [ ] T028 [US1] Wire scope-reset clearing of new fields in `_resetToInitial`, `refreshPaginatedList`, and `dispose` in `lib/smart_pagination/bloc/pagination_cubit.dart`
  - **Files**: `pagination_cubit.dart` (around lines 555–568, 625–680, dispose site)
  - **Description**: At each scope-reset path identified in T005, clear all three flags: `_pendingAnchor = null; _suppressLoadMoreUntilUserScroll = false; _anchorRestoreInFlight = false;`. The existing scope-reset logic (e.g., bumping `_generation`, calling `_cancelAllPageStreams`) is unchanged.
  - **Acceptance**: T22 (refresh/filter clears suppression) passes.
  - **Dependencies**: T027
  - **Parallel**: No — same file

- [ ] T029 [US1] Wire error-path clearing of suppression flag in `_fetch` finally branch in `lib/smart_pagination/bloc/pagination_cubit.dart`
  - **Files**: `pagination_cubit.dart` (near lines 1095–1096, the existing `_isFetching = false; _activeLoadMoreKey = null;` clearing block; specifically the load-more-error branch)
  - **Description**: In the error branch (where `loadMoreError` is emitted, NOT in the success branch), additionally do `_suppressLoadMoreUntilUserScroll = false; _pendingAnchor = null;` per `plan.md` §7.3. The success branch keeps the suppression flag set (only user-scroll clears it post-success).
  - **Acceptance**: T21 (error clears suppression) passes. T16, T17 stay green.
  - **Dependencies**: T028
  - **Parallel**: No — same file

- [ ] T030 [US1] Implement late-layout-settle resilience: ensure `markUserScroll` filtering on `dragDetails != null` is correct in `lib/smart_pagination/widgets/paginate_api_view.dart`
  - **Files**: `paginate_api_view.dart` (the new `NotificationListener` from T026)
  - **Description**: Verify in the test (T20) that synthetic `ScrollUpdateNotification` events caused by image-load layout settle (which have `dragDetails == null`) do NOT call `markUserScroll`. If T20 is failing because `ScrollUpdateNotification` is being mistakenly accepted, tighten the filter to `n is ScrollStartNotification && n.dragDetails != null`. (This is the stated rule in `plan.md` §6.3 and `research.md` R3, but it is worth a confirming edit if the initial T026 implementation was looser.)
  - **Acceptance**: T20 passes.
  - **Dependencies**: T026
  - **Parallel**: No — same file

### Verification for User Story 1

- [ ] T031 [US1] Run T01, T02, T04, T08 (capture), T09, T10, T11, T15 (restore), T16–T22 (suppression) — all pass
  - **Files**: `test/scroll_anchor_*_test.dart`
  - **Description**: `flutter test test/scroll_anchor_capture_test.dart test/scroll_anchor_restore_test.dart test/scroll_anchor_suppression_test.dart`. Confirm green.
  - **Acceptance**: All US1-relevant tests pass; the regression test T015 also passes.
  - **Dependencies**: T029, T030
  - **Parallel**: No

- [ ] T032 [US1] Confirm no regressions in existing test suite after US1 lands
  - **Files**: `test/`
  - **Description**: `flutter test` without filters. Compare against pre-US1 baseline.
  - **Acceptance**: Existing tests (load_more_guard, stream_guard, deduplication, end_of_list, scroll_trigger, etc.) all still pass.
  - **Dependencies**: T031
  - **Parallel**: No

**Checkpoint**: User Story 1 complete. The MVP — fast fling on a `ListView` produces exactly one load-more and the anchor item stays put — is demonstrable. Halt here and validate before proceeding if desired.

---

## Phase 4: User Story 2 — Anchor preservation across supported scrollable views (Priority: P2)

**Goal**: The same stability the user gets on `ListView` works on `GridView`, `CustomScrollView`/slivers, and `StaggeredGridView`. Out-of-scope view types (`PageView`, `ReorderableListView`, `reverse: true`) explicitly fall through to existing behavior with no exceptions.

**Independent Test**: For each supported view type, run the same fast-fling regression and verify (a) one load-more, (b) anchor stable. For each out-of-scope view type, verify the package's pre-feature behavior is unchanged (no anchor capture, no suppression flag set).

### Tests for User Story 2

- [ ] T033 [P] [US2] Implement view-matrix test bodies for in-scope views (T23, T24, T25, T26)
  - **Files**: `test/scroll_anchor_view_type_matrix_test.dart`
  - **Description**: Fill four stubs: T23 ListView (with and without `itemKeyBuilder`), T24 GridView (same), T25 CustomScrollView with consumer header/footer slivers, T26 StaggeredGridView via offset-delta. Each test mirrors the regression pattern: build → fling → assert one fetch + anchor stable.
  - **Acceptance**: T23 already passes (US1). T24, T25, T26 fail until T037–T039 land.
  - **Dependencies**: T012, T031
  - **Parallel**: Yes — different file from T034, T035, T036

- [ ] T034 [P] [US2] Implement out-of-scope view-matrix test bodies (T27, T28, T29)
  - **Files**: `test/scroll_anchor_view_type_matrix_test.dart`
  - **Description**: Fill three stubs: T27 PageView (capture is no-op, suppression flag stays false, existing overflow-index trigger fires unchanged), T28 ReorderableListView (no auto-load-more trigger today; verify nothing changes), T29 reverse-direction ListView (`reverse: true`) — capture short-circuits.
  - **Acceptance**: All three fail until T040, T041 land.
  - **Dependencies**: T012, T031
  - **Parallel**: Yes — same file but distinct test bodies; can be implemented concurrently with T033 if developers split the file

- [ ] T035 [P] [US2] Implement fall-through test bodies (T36, T37, T38)
  - **Files**: `test/scroll_anchor_fallthrough_test.dart`
  - **Description**: Fill three stubs: T36 reverse list still fires existing `_shouldLoadMore` triggers; T37 PageView's overflow-index trigger continues to call `fetchPaginatedList`; T38 ReorderableListView behavior is byte-identical.
  - **Acceptance**: T37, T38 likely already pass (no behavior change). T36 may fail if the reverse short-circuit isn't yet wired.
  - **Dependencies**: T014, T031
  - **Parallel**: Yes

- [ ] T036 [P] [US2] Implement remaining capture edge-case tests (T03 staggered offset; T05 partial-visible fallback; T06 no-item fallback; T07 reverse no-op)
  - **Files**: `test/scroll_anchor_capture_test.dart`
  - **Description**: Fill four remaining stubs in the capture file. T03: StaggeredGridView path returns `strategy: AnchorStrategy.offset` with `pixelsBefore` populated. T05: viewport shorter than any item → fallback to topmost partially-visible. T06: no item identifiable → strategy=offset. T07: capture is no-op for reverse.
  - **Acceptance**: All four fail until T039–T040 land.
  - **Dependencies**: T009, T031
  - **Parallel**: Yes — different file from T033, T034, T035

### Implementation for User Story 2

- [ ] T037 [US2] Wire capture-before-fetch push from `_buildGridView` trigger sites in `lib/smart_pagination/widgets/paginate_api_view.dart`
  - **Files**: `paginate_api_view.dart` (lines 443–452 animated, 474–483 sliver-grid)
  - **Description**: Mirror T021 for the grid paths: insert the same `_AnchorStrategySelector.compute(...)` + `cubit.captureAnchorBeforeLoadMore(snap)` block before each existing `addPostFrameCallback(fetchPaginatedList)`. Also wrap the returned `CustomScrollView` in the outer `NotificationListener<ScrollNotification>` from T026.
  - **Acceptance**: T24 passes. T17, T20 still pass on grids.
  - **Dependencies**: T032
  - **Parallel**: No — same file as T038, T039

- [ ] T038 [US2] Confirm `CustomScrollView`/sliver path is covered by the existing `_buildListView` and `_buildGridView` branches in `lib/smart_pagination/widgets/paginate_api_view.dart`
  - **Files**: `paginate_api_view.dart`
  - **Description**: The package's `_buildListView` and `_buildGridView` already build their items inside a `CustomScrollView` (lines 507, 727). Verify that consumer-supplied `header` and `footer` slivers (which are added to the same `CustomScrollView`) do not interfere with the observer or the `NotificationListener`. If T25 fails, identify the cause and fix; otherwise this task is verification-only.
  - **Acceptance**: T25 passes; consumer-supplied slivers don't break capture or restore.
  - **Dependencies**: T037
  - **Parallel**: No — same file

- [ ] T039 [US2] Wire offset-delta capture and restore for `_buildStaggeredGridView` in `lib/smart_pagination/widgets/paginate_api_view.dart`
  - **Files**: `paginate_api_view.dart` (lines 864–917)
  - **Description**: In the existing `NotificationListener<ScrollNotification>` block, when the load-more threshold is crossed, before the existing `addPostFrameCallback(fetchPaginatedList)` call, build a `_PendingScrollAnchor` with `strategy: AnchorStrategy.offset`, `pixelsBefore: notification.metrics.pixels`, `extentBefore: notification.metrics.maxScrollExtent`, and push it via `cubit.captureAnchorBeforeLoadMore`. Also extend the same listener's `onNotification` to call `markUserScroll` on `ScrollStartNotification && dragDetails != null`. The cubit's `_performAnchorRestore` already handles the offset case (T025); the staggered controller is `_effectiveScrollController` which the cubit can reach via its own observer-integration (already attached) — but for staggered specifically, the observer is NOT attached, so the cubit must use the controller passed via the snapshot. Update `_performAnchorRestore` to accept a controller closure or to read the snapshot's `pixelsBefore` and call `controller.jumpTo` via a registered fallback path.
  - **Acceptance**: T03, T26 pass. T36 (reverse fall-through) confirms the staggered listener's user-scroll detection works on reverse staggered too.
  - **Dependencies**: T037
  - **Parallel**: No — same file

- [ ] T040 [US2] Add reverse-direction short-circuit to `_AnchorStrategySelector.compute(...)` in `lib/smart_pagination/widgets/paginate_api_view.dart`
  - **Files**: `paginate_api_view.dart`
  - **Description**: Per `contracts/anchor-strategy.md` §"Selection algorithm" step 2: when `widget.reverse == true`, return `proceed: false` regardless of view type. The cubit's `captureAnchorBeforeLoadMore` simply does not get called from the widget, so the suppression flag is never armed for reverse lists. Existing trigger paths fire unchanged.
  - **Acceptance**: T07, T29, T36 pass.
  - **Dependencies**: T039
  - **Parallel**: No — same file

- [ ] T041 [US2] Add view-type short-circuit for `pageView`, `reorderableListView`, `custom` to `_AnchorStrategySelector.compute(...)` in `lib/smart_pagination/widgets/paginate_api_view.dart`
  - **Files**: `paginate_api_view.dart`
  - **Description**: Per `contracts/anchor-strategy.md` §"Selection algorithm" step 2: when `viewType in {pageView, reorderableListView, custom}`, return `proceed: false`. Confirm `_buildPageView` (line 833 `addPostFrameCallback`) and `_buildCustomView` continue to call `widget.fetchPaginatedList` directly without an upstream capture push. Also: do NOT add the outer `NotificationListener<ScrollNotification>` to these builders (no need to listen for user-scroll on out-of-scope views — the cubit's flag is never armed for them).
  - **Acceptance**: T27, T28, T37, T38 pass.
  - **Dependencies**: T040
  - **Parallel**: No — same file

- [ ] T042 [US2] Implement variable-height test (T13) in `test/scroll_anchor_restore_test.dart`
  - **Files**: `test/scroll_anchor_restore_test.dart`
  - **Description**: Fill the T13 stub: build a `ListView` whose `itemBuilder` returns `SizedBox(height: index.isEven ? 50 : 200, child: ...)`. Fling, await settle. Assert the anchor row's index in the post-append observer snapshot equals the captured anchor row's index ±1.
  - **Acceptance**: T13 passes. The `_listObserverController.jumpTo(index, alignment: 1.0)` correctly handles variable heights because it queries live render-tree state.
  - **Dependencies**: T010, T031
  - **Parallel**: No — sequence after the implementation lands so the green→red→green cycle matters

- [ ] T043 [US2] Implement T14 anchor-not-found fallback in `test/scroll_anchor_restore_test.dart`
  - **Files**: `test/scroll_anchor_restore_test.dart`
  - **Description**: Fill the T14 stub: capture an anchor with `strategy: AnchorStrategy.key` whose `key` value is removed from the items list before restore (e.g., consumer-driven mid-list delete simulated in the test). Assert restore falls through to offset-delta path and does NOT throw.
  - **Acceptance**: T14 passes; `_performAnchorRestore` correctly cascades key→index→offset→no-op.
  - **Dependencies**: T025
  - **Parallel**: No

### Verification for User Story 2

- [ ] T044 [US2] Run all view-type matrix and fall-through tests — all pass
  - **Files**: `test/scroll_anchor_view_type_matrix_test.dart`, `test/scroll_anchor_fallthrough_test.dart`, full capture/restore suite
  - **Description**: `flutter test test/scroll_anchor_view_type_matrix_test.dart test/scroll_anchor_fallthrough_test.dart`. Plus T03, T05, T06, T07, T13, T14 in capture/restore.
  - **Acceptance**: All US2-related tests green. T015 regression still green. No regressions in existing suite.
  - **Dependencies**: T041, T042, T043
  - **Parallel**: No

**Checkpoint**: User Story 2 complete. Anchor preservation works on every supported view type; out-of-scope views fall through cleanly.

---

## Phase 5: User Story 3 — Compatibility with existing controllers and constructors (Priority: P2)

**Goal**: Existing `.withProvider(...)` and `.withCubit(...)` call sites — including those passing an external `ScrollController` — work unchanged after upgrade. The new `preserveScrollAnchorOnAppend` parameter defaults to `true`; setting it to `false` reverts to pre-feature behavior.

**Independent Test**: Take the README's existing `.withProvider` and `.withCubit` examples verbatim, compile and run them in `testWidgets`. Assert no API changes, external controller listeners fire, controller is not disposed.

### Tests for User Story 3

- [ ] T045 [P] [US3] Implement compatibility test bodies (T30, T31, T32, T33)
  - **Files**: `test/scroll_anchor_compatibility_test.dart`
  - **Description**: Fill four stubs: T30 `.withProvider(...)` with internal controller — anchor preservation works. T31 `.withCubit(...)` with external `ScrollController` — works. T32 external controller's `addListener` callback fires during anchor capture and during the post-frame restore. T33 external controller is not disposed when the paginated view is unmounted (verified by reusing it in a subsequent widget tree).
  - **Acceptance**: T30, T31, T32 may already pass (US1/US2 work); T33 passes since the existing `dispose` only disposes `_internalScrollController`.
  - **Dependencies**: T013, T044
  - **Parallel**: Yes — different file from T046, T047

- [ ] T046 [P] [US3] Implement disable-flag test (T34) and README-example compat test (T35)
  - **Files**: `test/scroll_anchor_compatibility_test.dart`
  - **Description**: T34: build a `SmartPaginationListView` with `preserveScrollAnchorOnAppend: false`; assert no capture, no suppression flag set, behavior matches pre-feature (chained-load-more reproduces). T35: copy the existing `.withProvider` and `.withCubit` README examples verbatim into the test; assert they compile and run; instrument them with the same regression pattern.
  - **Acceptance**: T34 passes after T048 lands. T35 passes immediately if no breaking changes were introduced.
  - **Dependencies**: T013, T044
  - **Parallel**: Yes

### Implementation for User Story 3

- [ ] T047 [US3] Add `preserveScrollAnchorOnAppend` parameter to `PaginateApiView` in `lib/smart_pagination/widgets/paginate_api_view.dart`
  - **Files**: `paginate_api_view.dart` (constructor and field declarations)
  - **Description**: Per `contracts/public-api-surface.md` §A1: add `final bool preserveScrollAnchorOnAppend;` field with `this.preserveScrollAnchorOnAppend = true` in the constructor. Add full dartdoc per the contract. Replace the temporary `_kCaptureEnabled = true` constant from T021 with `widget.preserveScrollAnchorOnAppend`.
  - **Acceptance**: All capture-push sites now read the parameter; default behavior is unchanged.
  - **Dependencies**: T044
  - **Parallel**: No — same file as T048

- [ ] T048 [US3] Honor `preserveScrollAnchorOnAppend == false` end-to-end in `lib/smart_pagination/widgets/paginate_api_view.dart`
  - **Files**: `paginate_api_view.dart`
  - **Description**: When the flag is `false`: (a) `_AnchorStrategySelector.compute` returns `proceed: false`, (b) the outer `NotificationListener<ScrollNotification>` from T026 still wraps but its `onNotification` is a no-op (or alternatively, the `NotificationListener` is omitted entirely — pick the cleaner path). The cubit-side flags are never armed because no `captureAnchorBeforeLoadMore` is called.
  - **Acceptance**: T34 passes — pre-feature chained-load-more behavior is reproducible.
  - **Dependencies**: T047
  - **Parallel**: No — same file

- [ ] T049 [US3] Forward `preserveScrollAnchorOnAppend` through public wrappers in `lib/smart_pagination/widgets/smart_pagination_list_view.dart`, `smart_pagination_grid_view.dart`, `smart_pagination_staggered_grid_view.dart`, and any other public wrapper composing `PaginateApiView`
  - **Files**: `smart_pagination_list_view.dart`, `smart_pagination_grid_view.dart`, `smart_pagination_staggered_grid_view.dart` (and others that wrap `PaginateApiView`)
  - **Description**: Per `contracts/public-api-surface.md` §A2: each public wrapper adds the same `bool preserveScrollAnchorOnAppend = true` parameter and forwards it to its inner `PaginateApiView`. No other API changes.
  - **Acceptance**: All public wrappers expose the parameter; existing call sites compile unchanged. T35 passes.
  - **Dependencies**: T047
  - **Parallel**: Yes — these are different files from T047/T048 if the wrappers don't import each other (they don't); can be edited concurrently

- [ ] T050 [US3] Confirm external `ScrollController` listeners continue to fire by adding an explicit assertion test
  - **Files**: `test/scroll_anchor_compatibility_test.dart`
  - **Description**: T32's body should already verify this; if not, beef it up: attach a listener via `externalController.addListener(onTick)`, perform fling, count `onTick` invocations, assert the count matches the package's internal observed scroll events 1:1. The new outer `NotificationListener<ScrollNotification>` MUST return `false` (does not consume) — verified indirectly by the listener firing.
  - **Acceptance**: T32 passes with strict 1:1 invocation count.
  - **Dependencies**: T049
  - **Parallel**: No

### Verification for User Story 3

- [ ] T051 [US3] Run all compatibility tests — all pass
  - **Files**: `test/scroll_anchor_compatibility_test.dart`
  - **Description**: `flutter test test/scroll_anchor_compatibility_test.dart`.
  - **Acceptance**: T30–T35 all green.
  - **Dependencies**: T050
  - **Parallel**: No

**Checkpoint**: User Story 3 complete. Backwards compatibility verified end-to-end. Existing call sites are byte-identical; the new parameter is purely additive.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Documentation, version bump, full-suite verification. No functional changes.

- [ ] T052 [P] Update `README.md` with the "Scroll Anchor Preservation" section
  - **Files**: `README.md`
  - **Description**: Add the section template from `plan.md` §14, including: overview, how-it-works numbered list, anchor-strategy table, view-type support matrix, `preserveScrollAnchorOnAppend` opt-out, troubleshooting block. Cross-reference the existing load-more guard section (added by feature `003`).
  - **Acceptance**: README contains a clear support-matrix table. SC-004 satisfied.
  - **Dependencies**: T051
  - **Parallel**: Yes — different file from T053, T054, T055, T056

- [ ] T053 [P] Update `CHANGELOG.md` with the 3.5.0 entry
  - **Files**: `CHANGELOG.md`
  - **Description**: Add the entry from `plan.md` §14 under a new `## [3.5.0] - YYYY-MM-DD` heading. Sections: Added, Changed, Compatibility. Mecca time zone for the date per `CLAUDE.md` "Documentation comments use Flutter-style `///`; changelog entries use Mecca time zone".
  - **Acceptance**: CHANGELOG entry is in Keep-a-Changelog format with no breaking-change note.
  - **Dependencies**: T051
  - **Parallel**: Yes

- [ ] T054 [P] Update inline dartdoc in `lib/smart_pagination/bloc/pagination_cubit.dart`
  - **Files**: `pagination_cubit.dart`
  - **Description**: Document the four new private fields (`_pendingAnchor`, `_suppressLoadMoreUntilUserScroll`, `_lastUserScrollGeneration`, `_anchorRestoreInFlight`), the two `@internal` methods (`captureAnchorBeforeLoadMore`, `markUserScroll`), and update the `fetchPaginatedList` guard-order comment block to include the new step.
  - **Acceptance**: `dart doc` (or IDE hover) shows the documented surface; no warnings.
  - **Dependencies**: T051
  - **Parallel**: Yes — different file from T055

- [ ] T055 [P] Update inline dartdoc in `lib/smart_pagination/widgets/paginate_api_view.dart`
  - **Files**: `paginate_api_view.dart`
  - **Description**: Document the new `preserveScrollAnchorOnAppend` parameter per `contracts/public-api-surface.md` §A1 (already drafted). Document the new outer `NotificationListener<ScrollNotification>` and what it triggers.
  - **Acceptance**: Public parameter is fully documented; private `NotificationListener` purpose is annotated.
  - **Dependencies**: T051
  - **Parallel**: Yes

- [ ] T056 Bump `pubspec.yaml` version from 3.4.0 to 3.5.0
  - **Files**: `pubspec.yaml`
  - **Description**: Increment `version: 3.4.0` to `version: 3.5.0`. Minor bump (additive feature, no breaking change).
  - **Acceptance**: pubspec parses; `flutter pub get` succeeds.
  - **Dependencies**: T052, T053
  - **Parallel**: No — coordinates with the changelog entry

- [ ] T057 Run `flutter analyze` and verify no new issues
  - **Files**: (whole package)
  - **Description**: `flutter analyze`. Compare against pre-feature baseline. The known ~49 pre-existing warnings (per root `CLAUDE.md`) are acceptable; no NEW issues may be introduced.
  - **Acceptance**: Zero new analyze findings.
  - **Dependencies**: T056
  - **Parallel**: No

- [ ] T058 Run full `flutter test` and verify entire suite passes
  - **Files**: `test/`
  - **Description**: `flutter test` without filters. Includes the 38 new tests plus all existing test files.
  - **Acceptance**: 100% pass rate. No flaky tests.
  - **Dependencies**: T057
  - **Parallel**: No

- [ ] T059 Walk through `quickstart.md` consumer snippets and verify they compile and run
  - **Files**: `specs/004-scroll-anchor-preservation/quickstart.md`
  - **Description**: Copy the consumer-facing code snippets from `quickstart.md` (the `SmartPaginationListView<Product, ProductRequest>.withProvider(...)` example) into a temporary widget test or example file. Confirm they compile against the published API and produce the expected behavior.
  - **Acceptance**: Quickstart code is current and accurate.
  - **Dependencies**: T058
  - **Parallel**: No

**Checkpoint**: Feature complete. Documentation up-to-date. Version bumped. CI green.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Audit)**: No dependencies — start immediately.
- **Phase 2 (Foundational)**: Depends on Phase 1 — blocks all user-story phases.
- **Phase 3 (US1)**: Depends on Phase 2 — MVP path.
- **Phase 4 (US2)**: Depends on Phase 3 (US1 establishes the core capture/restore/suppression machinery on `ListView`; US2 extends to other view types and adds the out-of-scope short-circuits).
- **Phase 5 (US3)**: Depends on Phase 4 (the public `preserveScrollAnchorOnAppend` parameter cleanly slots in only after the feature flag's behavior is fully implemented and verified).
- **Phase 6 (Polish)**: Depends on Phase 5.

### User-Story Dependencies

- **US1 (P1)**: Independent of US2 / US3. Delivers the MVP — the bug fix on the most common view type.
- **US2 (P2)**: Builds on US1's machinery; not strictly independent (the strategy selector, suppression flag, and post-frame restore are already in place). However, the *outcome* per view type is independently testable.
- **US3 (P2)**: Builds on US1 + US2. The public `preserveScrollAnchorOnAppend` parameter cleanly flips the feature off in one place; it lands after the feature is otherwise complete to avoid a half-flag-implemented intermediate state.

### Within Each User Story

- All tests for that story MUST be written and confirmed failing BEFORE implementation begins (TDD red baseline).
- Within tests: stub creation (Phase 2) → test bodies (US-specific) — sequential within a single file, parallel across files.
- Within implementation: cubit changes are mostly sequential (same file); widget changes are mostly sequential (same file); cubit and widget changes can interleave within a story phase if developers split them.

### Parallel Opportunities

- Phase 1: T002, T003, T004, T005 are all `[P]` — different annotation regions/files.
- Phase 2: T009–T014 are all `[P]` — six different new test files.
- Phase 3 (US1): T016, T017, T018 are `[P]` across three different test files (the [P] applies to inter-task parallelism; same-file work is sequential).
- Phase 4 (US2): T033, T034, T035, T036 are `[P]` across test files. Implementation T037–T041 are sequential (same file: `paginate_api_view.dart`). T042, T043 can run in parallel after T041 lands.
- Phase 5 (US3): T045, T046 are `[P]`. T049 is `[P]` against T047/T048 across wrapper files.
- Phase 6: T052, T053, T054, T055 are `[P]` — different documentation files.

---

## Parallel Example: Phase 2 — Test Scaffolds

```bash
# All six test-file scaffolds can be created in parallel:
Task: "Create test/scroll_anchor_capture_test.dart with 8 stubs"
Task: "Create test/scroll_anchor_restore_test.dart with 7 stubs"
Task: "Create test/scroll_anchor_suppression_test.dart with 7 stubs"
Task: "Create test/scroll_anchor_view_type_matrix_test.dart with 7 stubs"
Task: "Create test/scroll_anchor_compatibility_test.dart with 6 stubs"
Task: "Create test/scroll_anchor_fallthrough_test.dart with 3 stubs"

# Then within US1 phase, three test bodies can be filled in parallel:
Task: "Implement capture test bodies T01, T02, T04, T08"
Task: "Implement restore test bodies T09, T10, T11, T15"
Task: "Implement suppression test bodies T16–T22"
```

---

## Implementation Strategy

### MVP First (User Story 1 only)

1. Complete Phase 1 (Audit): T001–T005.
2. Complete Phase 2 (Foundational): T006–T014.
3. Complete Phase 3 (US1): T015–T032.
4. **STOP and VALIDATE**: Demonstrate the regression fix on a `ListView`. Run `flutter test` to confirm no regressions. The MVP — fast fling produces exactly one load-more, anchor stable — is shippable.
5. Tag a pre-release version if useful.

### Incremental Delivery

1. Setup + Foundational + US1 → **MVP** (`ListView` works; out-of-scope views fall through silently). 32 tasks done.
2. + US2 → **Full view-type coverage** (`GridView`, slivers, staggered all work). 44 tasks done.
3. + US3 → **Public API and disable flag** (call sites unchanged, opt-out available). 51 tasks done.
4. + Polish → **Release-ready** (docs, version, full CI). 59 tasks done.

Each increment adds value without breaking previous increments.

### Parallel Team Strategy (if multiple developers)

- Phase 1 (Audit): all developers read in parallel.
- Phase 2 (Foundational): T006–T008 sequential on cubit; T009–T014 split across developers (one test file each).
- Phase 3 (US1): one developer focuses on cubit-side (T022–T029), another on widget-side (T019–T021, T026, T030); test bodies T015–T018 can be a third stream.
- Phase 4 (US2): one developer on grid path (T037), one on staggered (T039), one on out-of-scope short-circuits (T040, T041).
- Phase 5 (US3): one developer on the parameter (T047, T048), another on wrappers (T049), tests in parallel (T045, T046).
- Phase 6 (Polish): docs split per file (T052–T055), then sequential T056–T059.

---

## Notes

- `[P]` tasks = different files OR different non-overlapping regions, no dependencies on incomplete tasks.
- `[Story]` label maps task to specific user story for traceability.
- TDD discipline: tests fail before implementation lands. The plan explicitly checkpoints "fail" states.
- Commit after each task or logical group (per `CLAUDE.md` "Commit after each task or logical group").
- Stop at any phase checkpoint to validate independently — US1 checkpoint is the MVP gate.
- Avoid: vague tasks, same-file conflicts (the cubit and `paginate_api_view.dart` are heavily edited; respect sequential order within them), cross-story dependencies that break independence.
- Per project `CLAUDE.md`: this feature must NOT introduce a `Co-Authored-By: Claude ...` trailer in commit messages, and git operations (push, branch, PR) must be handed off to the user — Claude prepares commands but does not run remote-affecting git commands.
