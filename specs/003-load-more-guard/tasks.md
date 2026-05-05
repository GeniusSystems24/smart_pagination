# Tasks: Load-More Guard

**Input**: Design documents from `specs/003-load-more-guard/`
**Feature Branch**: `003-load-more-guard`
**Date**: 2026-05-05
**Approach**: Test-First (TDD) — Write failing tests before each implementation phase

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[Story]**: US1–US4 maps to user stories from spec.md
- **Test-First Rule**: Within each user story phase, ALL tests must be written and confirmed failing BEFORE implementation begins

---

## Phase 1: Audit — Load-More Trigger Path

**Purpose**: Read and annotate the current flow before any changes. No code is written here.

- [ ] T001 Annotate `fetchPaginatedList()` guard sequence in `lib/smart_pagination/bloc/pagination_cubit.dart`
  - **Files**: `pagination_cubit.dart` (lines 666–731)
  - **Description**: Read lines 666–731. Add inline TODO comments labelling each guard with its root-cause tag from plan.md Section 3. Confirm `_isFetching = true` is set at line 740 (inside `_fetch`), not at line 719 (before emit). Confirm line numbers match plan.md Section 2.
  - **Acceptance**: All 8 guards are labelled; RC-1, RC-2, RC-5 tags are present as comments.
  - **Dependencies**: none
  - **Parallel**: No — must be read before other annotation tasks touch the same file

- [ ] T002 [P] Annotate `_shouldLoadMore` scroll trigger in `lib/smart_pagination/widgets/paginate_api_view.dart`
  - **Files**: `paginate_api_view.dart` (lines 391–444)
  - **Description**: Read `_shouldLoadMore(int)` and every item-builder call site. Confirm the stale `widget.loadedState` snapshot is the RC-1 issue. Add TODO comment at line ~443: `// TODO RC-1: snapshot is stale — fix with addPostFrameCallback`.
  - **Acceptance**: Comment present; file compiles unchanged.
  - **Dependencies**: none
  - **Parallel**: Yes — different file from T001

- [ ] T003 [P] Annotate double stream factory call in `lib/smart_pagination/bloc/pagination_cubit.dart`
  - **Files**: `pagination_cubit.dart` (lines ~757–862)
  - **Description**: Locate both `streamProvider(request)` call sites (one for `.first`, one passed to `_attachStream`). Add `// TODO RC-3` comment at each. Also locate the `getMergedStream(request)` double-call for the merged-stream branch.
  - **Acceptance**: Both RC-3 call sites annotated.
  - **Dependencies**: T001 (file already in context)
  - **Parallel**: Yes after T001

- [ ] T004 [P] Annotate `_attachStream` duplicate-registration gap in `lib/smart_pagination/bloc/pagination_cubit.dart`
  - **Files**: `pagination_cubit.dart` (lines ~1004–1050)
  - **Description**: Confirm `_attachStream` cancels-then-replaces with no generation check. Add: `// TODO: add generation guard — skip if same page+generation already registered`.
  - **Acceptance**: Comment at ~line 1007.
  - **Dependencies**: T001
  - **Parallel**: Yes after T001

- [ ] T005 [P] Annotate `_computeHasNext` and `_emitMergedLoaded` end-of-list gaps in `lib/smart_pagination/bloc/pagination_cubit.dart`
  - **Files**: `pagination_cubit.dart` (lines ~950, ~1081)
  - **Description**: Confirm `_computeHasNext` uses only item-count (no cursor/boolean). Confirm `_emitMergedLoaded` uses `any(length < pageSize)` without `isComplete` guard. Add `// TODO RC-4` and `// TODO RC-7` comments respectively.
  - **Acceptance**: Both gaps annotated.
  - **Dependencies**: T001
  - **Parallel**: Yes after T001

---

## Phase 2: Foundational — Test Infrastructure

**Purpose**: Create test file scaffolds with group/test stubs. All test bodies are `fail('not yet implemented')` — this is what makes the red baseline.

- [ ] T006 Create `test/load_more_guard_test.dart` with 13 test stubs (T01–T13)
  - **Files**: `test/load_more_guard_test.dart` (new file)
  - **Description**: Create a Dart test file with `group('Load-More Guard', () { ... })` containing 13 `test(...)` calls — each named exactly as in plan.md Section 12 table, body = `fail('not yet implemented')`. Add imports: `flutter_test`, `bloc_test`, the cubit, state, and request classes.
  - **Acceptance**: `flutter test test/load_more_guard_test.dart` reports 13 failures with message "not yet implemented".
  - **Dependencies**: Phase 1 complete
  - **Parallel**: No — must exist before any US test tasks

- [ ] T007 [P] Create `test/stream_guard_test.dart` with 6 test stubs (T14–T19)
  - **Files**: `test/stream_guard_test.dart` (new file)
  - **Description**: `group('Stream Guard', () { ... })` with 6 stubs named per plan Section 12.
  - **Acceptance**: 6 failures on run.
  - **Dependencies**: Phase 1 complete
  - **Parallel**: Yes — different file

- [ ] T008 [P] Create `test/deduplication_test.dart` with 3 test stubs (T20–T22)
  - **Files**: `test/deduplication_test.dart` (new file)
  - **Description**: `group('Item Deduplication', () { ... })` with 3 stubs.
  - **Acceptance**: 3 failures on run.
  - **Dependencies**: Phase 1 complete
  - **Parallel**: Yes

- [ ] T009 [P] Create `test/end_of_list_test.dart` with 4 test stubs (T23–T26)
  - **Files**: `test/end_of_list_test.dart` (new file)
  - **Description**: `group('End-of-List Detection', () { ... })` with 4 stubs.
  - **Acceptance**: 4 failures on run.
  - **Dependencies**: Phase 1 complete
  - **Parallel**: Yes

- [ ] T010 [P] Create `test/scroll_trigger_test.dart` with 3 test stubs (T27–T29)
  - **Files**: `test/scroll_trigger_test.dart` (new file)
  - **Description**: `group('Scroll Trigger', () { ... })` with 3 stubs.
  - **Acceptance**: 3 failures on run.
  - **Dependencies**: Phase 1 complete
  - **Parallel**: Yes

**Checkpoint**: All 5 test files exist; `flutter test` reports exactly 29 failures. No production code has been touched.

---

## Phase 3: User Story 1 — Single Active Request Guard (Priority: P1) 🎯 MVP

**Goal**: Only one load-more request is active at a time per cubit instance, even under 10+ rapid scroll triggers.

**Independent Test**: T01–T04 in `load_more_guard_test.dart` + T27 in `scroll_trigger_test.dart` all pass.

### Tests for US1 — Write and Confirm Failing BEFORE T016 ⚠️

- [ ] T011 [US1] Implement T01 body: 10 rapid calls → exactly 1 provider call in `test/load_more_guard_test.dart`
  - **Files**: `test/load_more_guard_test.dart`
  - **Description**: Create a `FuturePaginationProvider` counting calls. After initial load, reset counter. Call `cubit.fetchPaginatedList()` 10 times synchronously. `await Future.delayed(Duration.zero)`. Assert `providerCallCount == 1` and `items.length == 20`.
  - **Acceptance**: Fails on un-patched code with `providerCallCount >= 2`.
  - **Dependencies**: T006
  - **Parallel**: No

- [ ] T012 [P] [US1] Implement T02 body: second call during in-flight returns without provider call in `test/load_more_guard_test.dart`
  - **Files**: `test/load_more_guard_test.dart`
  - **Description**: Use `Completer`-backed provider. Start load-more (do not complete). Call `fetchPaginatedList()` again. Complete the completer. Assert `providerCallCount == 1`.
  - **Acceptance**: Fails on un-patched code if second call slips through.
  - **Dependencies**: T006
  - **Parallel**: Yes — same file, independent test body

- [ ] T013 [P] [US1] Implement T03 body: same page not fetched twice concurrently in `test/load_more_guard_test.dart`
  - **Files**: `test/load_more_guard_test.dart`
  - **Description**: Provider tracks calls by page number (`Map<int, int> pageCallCounts`). Trigger two load-more calls for page 2 before either completes. Assert `pageCallCounts[2] == 1`.
  - **Acceptance**: Fails (shows count == 2) on un-patched code.
  - **Dependencies**: T006
  - **Parallel**: Yes

- [ ] T014 [US1] Implement T04 body: success clears guards, allowing next page load in `test/load_more_guard_test.dart`
  - **Files**: `test/load_more_guard_test.dart`
  - **Description**: After successful page 2 load, call `fetchPaginatedList()` for page 3. Assert provider is called (guard was cleared after success). Confirms cleanup works on the happy path.
  - **Acceptance**: Passes after T021 is implemented; use as regression anchor.
  - **Dependencies**: T011
  - **Parallel**: No

- [ ] T015 [P] [US1] Implement T27 body: widget-level fast scroll triggers exactly one load-more in `test/scroll_trigger_test.dart`
  - **Files**: `test/scroll_trigger_test.dart`
  - **Description**: Widget test using `pumpWidget` with a `SmartPagination` widget backed by a call-counting provider. Simulate 5 scroll threshold crossings in one pump. Assert `providerCallCount == 1` for page 2.
  - **Acceptance**: Fails on un-patched code (multiple calls without `addPostFrameCallback`).
  - **Dependencies**: T010
  - **Parallel**: Yes — different file from T011–T014

> **Verify baseline**: `flutter test test/load_more_guard_test.dart test/scroll_trigger_test.dart` — T01–T03, T27 must fail. T04 may pass. Proceed to implementation only after confirming.

### Implementation for US1

- [ ] T016 [US1] Move `_isFetching = true` before `emit(isLoadingMore: true)` in `lib/smart_pagination/bloc/pagination_cubit.dart`
  - **Files**: `pagination_cubit.dart` (line ~719 and ~740)
  - **Description**: In `fetchPaginatedList()`, immediately after guard #6 (`if (currentState.isLoadingMore) return;`), add `_isFetching = true;`. Remove `_isFetching = true` from the top of `_fetch()`. The `_isFetching = false` in `_fetch()`'s `finally` block stays.
  - **Acceptance**: T02 passes; T01 still failing (needs T017–T020).
  - **Dependencies**: T011–T013 confirmed failing
  - **Parallel**: No

- [ ] T017 [US1] Add `_activeLoadMoreKey: String?` field to `SmartPaginationCubit` in `lib/smart_pagination/bloc/pagination_cubit.dart`
  - **Files**: `pagination_cubit.dart` (field declarations ~line 179)
  - **Description**: Add `String? _activeLoadMoreKey;` alongside `_isFetching`. Initialized to `null` implicitly.
  - **Acceptance**: File compiles.
  - **Dependencies**: T016
  - **Parallel**: No

- [ ] T018 [US1] Add `_buildLoadMoreKey(R request)` private method in `lib/smart_pagination/bloc/pagination_cubit.dart`
  - **Files**: `pagination_cubit.dart` (near `_buildRequest` method)
  - **Description**: `String _buildLoadMoreKey(R request) => '${request.page}:${request.pageSize ?? 'null'}';`
  - **Acceptance**: `PaginationRequest(page: 2, pageSize: 10)` → `"2:10"`.
  - **Dependencies**: T017
  - **Parallel**: No

- [ ] T019 [US1] Add `_activeLoadMoreKey == key` guard in `fetchPaginatedList()` in `lib/smart_pagination/bloc/pagination_cubit.dart`
  - **Files**: `pagination_cubit.dart` (lines ~706–720)
  - **Description**: After guard #5 (`if (_hasReachedEnd) return;`), compute `final loadMoreKey = _buildLoadMoreKey(nextRequest);` and add `if (_activeLoadMoreKey == loadMoreKey) return;`. Place BEFORE the `isLoadingMore` guard (guard order per plan Section 4.4 step 7).
  - **Acceptance**: T01 and T03 pass.
  - **Dependencies**: T018
  - **Parallel**: No

- [ ] T020 [US1] Set `_activeLoadMoreKey = key` before emit in `fetchPaginatedList()` in `lib/smart_pagination/bloc/pagination_cubit.dart`
  - **Files**: `pagination_cubit.dart` (lines ~719–721)
  - **Description**: After `_isFetching = true`, add `_activeLoadMoreKey = loadMoreKey;` before `emit(currentState.copyWith(isLoadingMore: true))`.
  - **Acceptance**: Key is set in the synchronous window before any `await`.
  - **Dependencies**: T019
  - **Parallel**: No

- [ ] T021 [US1] Clear `_activeLoadMoreKey` in `finally` block of `_fetch()` in `lib/smart_pagination/bloc/pagination_cubit.dart`
  - **Files**: `pagination_cubit.dart` (finally block ~line 932)
  - **Description**: In `finally { _isFetching = false; }`, also add `_activeLoadMoreKey = null;`. Runs on success, error, and cancellation.
  - **Acceptance**: T04 passes (success path clears guard; next page can load).
  - **Dependencies**: T020
  - **Parallel**: No

- [ ] T022 [US1] Clear `_activeLoadMoreKey` in `cancelOngoingRequest()` in `lib/smart_pagination/bloc/pagination_cubit.dart`
  - **Files**: `pagination_cubit.dart` (line ~1186)
  - **Description**: In `cancelOngoingRequest()`, alongside `_isFetching = false`, add `_activeLoadMoreKey = null;`.
  - **Acceptance**: After external cancellation, new `fetchPaginatedList()` is not blocked.
  - **Dependencies**: T021
  - **Parallel**: No

- [ ] T023 [P] [US1] Wrap scroll trigger in `addPostFrameCallback` in `lib/smart_pagination/widgets/paginate_api_view.dart`
  - **Files**: `paginate_api_view.dart` (lines ~443–444 and all other item-builder `fetchPaginatedList` call sites)
  - **Description**: Replace `widget.fetchPaginatedList?.call();` (inside every `_shouldLoadMore` check in item builders) with `SchedulerBinding.instance.addPostFrameCallback((_) { widget.fetchPaginatedList?.call(); });`. Add `import 'package:flutter/scheduler.dart';` if absent. Apply to grid, list, and staggered list builders.
  - **Acceptance**: T27 passes; multiple items in one build pass produce at most one provider call.
  - **Dependencies**: T015 confirmed failing
  - **Parallel**: Yes — different file from T016–T022; can run after T015 is confirmed failing

**Checkpoint — US1 Done**: `flutter test test/load_more_guard_test.dart test/scroll_trigger_test.dart` → T01–T04, T27 green. No regressions.

---

## Phase 4: User Story 2 — End-of-List Detection (Priority: P2)

**Goal**: Permanently stop fetching once the data source signals no more pages exist.

**Independent Test**: T07–T09 in `load_more_guard_test.dart` + T23–T26 in `end_of_list_test.dart` + T28 in `scroll_trigger_test.dart` all pass.

### Tests for US2 — Write and Confirm Failing BEFORE T031 ⚠️

- [ ] T024 [US2] Implement T07 body: empty load-more → hasReachedEnd=true, no append in `test/load_more_guard_test.dart`
  - **Files**: `test/load_more_guard_test.dart`
  - **Description**: Provider returns `[]` for page 2. After load-more resolves, assert `state.hasReachedEnd == true` and `state.items.length == 10` (page 1 only; empty page NOT appended).
  - **Acceptance**: Fails on un-patched code.
  - **Dependencies**: T006; Phase 3 implementation complete
  - **Parallel**: Yes [P]

- [ ] T025 [P] [US2] Implement T08 body: short page (< pageSize) → hasReachedEnd=true in `test/load_more_guard_test.dart`
  - **Files**: `test/load_more_guard_test.dart`
  - **Description**: Provider returns `pageSize - 1` items on page 2. Assert `state.hasReachedEnd == true` and items include the partial page (it IS appended).
  - **Acceptance**: Fails or passes on un-patched code — confirm either way before implementing.
  - **Dependencies**: T006
  - **Parallel**: Yes

- [ ] T026 [P] [US2] Implement T09 body: after hasReachedEnd, no further provider calls in `test/load_more_guard_test.dart`
  - **Files**: `test/load_more_guard_test.dart`
  - **Description**: After `hasReachedEnd == true`, call `fetchPaginatedList()` five more times. Assert provider receives 0 additional calls.
  - **Acceptance**: Fails if guard is cleared prematurely.
  - **Dependencies**: T006
  - **Parallel**: Yes

- [ ] T027 [P] [US2] Implement T23 body: null next-cursor → hasReachedEnd=true in `test/end_of_list_test.dart`
  - **Files**: `test/end_of_list_test.dart`
  - **Description**: Provider returns a response with `nextCursor: null`. Assert `state.hasReachedEnd == true`.
  - **Acceptance**: Fails on un-patched code (cursor signal not inspected).
  - **Dependencies**: T009
  - **Parallel**: Yes

- [ ] T028 [P] [US2] Implement T24 body: explicit hasMore=false → hasReachedEnd=true in `test/end_of_list_test.dart`
  - **Files**: `test/end_of_list_test.dart`
  - **Description**: Provider returns a response with explicit `hasMore: false`. Assert `state.hasReachedEnd == true`.
  - **Acceptance**: Fails on un-patched code.
  - **Dependencies**: T009
  - **Parallel**: Yes

- [ ] T029 [P] [US2] Implement T25 body: both cursor signals work independently in `test/end_of_list_test.dart`
  - **Files**: `test/end_of_list_test.dart`
  - **Description**: Two sub-cases: (a) only `nextCursor == null`, (b) only `hasMore == false`. Each independently triggers `hasReachedEnd = true`.
  - **Acceptance**: Both sub-cases fail on un-patched code.
  - **Dependencies**: T009
  - **Parallel**: Yes

- [ ] T030 [P] [US2] Implement T28 body: widget scroll after hasReachedEnd → no provider call in `test/scroll_trigger_test.dart`
  - **Files**: `test/scroll_trigger_test.dart`
  - **Description**: Load list to end; simulate scroll threshold crossings. Assert `providerCallCount == 0` for those scroll events.
  - **Acceptance**: Confirms widget respects `hasReachedEnd`.
  - **Dependencies**: T010
  - **Parallel**: Yes

> **Verify baseline**: T07, T09, T23–T24 should fail; T08, T25, T28 may pass. Confirm before implementing.

### Implementation for US2

- [ ] T031 [US2] Fix empty-page early return in load-more path of `lib/smart_pagination/bloc/pagination_cubit.dart`
  - **Files**: `pagination_cubit.dart` (load-more path ~line 791)
  - **Description**: Before `_pages.add(pageItems)`, add: `if (!reset && pageItems.isEmpty) { _currentMeta = PaginationMeta(page: request.page, pageSize: request.pageSize, hasNext: false, hasPrevious: request.page > 1); emit(currentState.copyWith(hasReachedEnd: true, isLoadingMore: false)); return; }` — implements plan Section 6.1.
  - **Acceptance**: T07 passes; `items.length` unchanged; `hasReachedEnd == true`.
  - **Dependencies**: T024 confirmed failing; Phase 3 complete
  - **Parallel**: No

- [ ] T032 [US2] Extend `_computeHasNext` with optional `serverHasNext` param in `lib/smart_pagination/bloc/pagination_cubit.dart`
  - **Files**: `pagination_cubit.dart` (line ~950)
  - **Description**: Change signature to `bool _computeHasNext(List<T> items, int? pageSize, {bool? serverHasNext})`. Add `if (serverHasNext != null) return serverHasNext;` as the first line. Update `_fetch()` and `_emitMergedLoaded` callers to pass `serverHasNext` when the provider response carries a null cursor or explicit `hasMore: false`.
  - **Acceptance**: T23–T25 pass. Existing callers compile unchanged.
  - **Dependencies**: T031
  - **Parallel**: No

- [ ] T033 [US2] Add `isComplete` flag to `_PageStreamEntry` and fix stream end-of-list heuristic in `lib/smart_pagination/bloc/pagination_cubit.dart`
  - **Files**: `pagination_cubit.dart` (lines ~1004–1089)
  - **Description**: Add `bool isComplete = false;` field to `_PageStreamEntry<T>`. Set `isComplete = true` once the page's `.first` snapshot resolves. In `_emitMergedLoaded`, change `any(e.latestValue.length < pageSize)` to `any(e.isComplete && e.latestValue.length < pageSize)`. Fixes RC-7 — prevents premature end-of-list during stream warm-up.
  - **Acceptance**: No premature `hasReachedEnd` during warm-up; T16 (stream_guard_test) passes.
  - **Dependencies**: T032
  - **Parallel**: No

**Checkpoint — US2 Done**: T07–T09, T23–T26, T28 all pass. US1 tests still pass.

---

## Phase 5: User Story 3 — Error Recovery (Priority: P3)

**Goal**: A failed load-more does not mark the list as ended and allows immediate retry.

**Independent Test**: T05, T06 in `load_more_guard_test.dart`; T26 in `end_of_list_test.dart`; T29 in `scroll_trigger_test.dart` all pass.

### Tests for US3 — Write and Confirm Failing BEFORE T038 ⚠️

- [ ] T034 [P] [US3] Implement T05 body: load-more error clears guards but NOT hasReachedEnd in `test/load_more_guard_test.dart`
  - **Files**: `test/load_more_guard_test.dart`
  - **Description**: Provider throws on page 2. After error, assert: (a) `state.hasReachedEnd == false`, (b) `state.loadMoreError != null`, (c) a fresh `fetchPaginatedList()` is not blocked (confirms `_activeLoadMoreKey` cleared in finally).
  - **Acceptance**: Fails if key is not cleared on error path.
  - **Dependencies**: T006; Phase 3 complete
  - **Parallel**: Yes

- [ ] T035 [P] [US3] Implement T06 body: retry via `retryAfterError()` succeeds in `test/load_more_guard_test.dart`
  - **Files**: `test/load_more_guard_test.dart`
  - **Description**: After load-more error, call `cubit.retryAfterError()`. Assert provider is called and `items.length == 20` after retry.
  - **Acceptance**: Verifies full recovery path.
  - **Dependencies**: T006
  - **Parallel**: Yes

- [ ] T036 [P] [US3] Implement T26 body: error does NOT set hasReachedEnd in `test/end_of_list_test.dart`
  - **Files**: `test/end_of_list_test.dart`
  - **Description**: Provider throws `Exception('network error')`. Assert `state.hasReachedEnd == false`.
  - **Acceptance**: Should already pass — write to confirm no regression.
  - **Dependencies**: T009
  - **Parallel**: Yes

- [ ] T037 [P] [US3] Implement T29 body: widget scroll after error allows retry in `test/scroll_trigger_test.dart`
  - **Files**: `test/scroll_trigger_test.dart`
  - **Description**: Load-more fails; scroll threshold fires again. Assert a new provider call occurs (not blocked by stale `_activeLoadMoreKey`).
  - **Acceptance**: Fails if `_activeLoadMoreKey` is not cleared on error.
  - **Dependencies**: T010
  - **Parallel**: Yes

> **Verify baseline**: T05, T29 should fail on un-patched code. Confirm before implementing.

### Implementation for US3

- [ ] T038 [US3] Verify `_activeLoadMoreKey = null` runs on error path in `finally` of `_fetch()` in `lib/smart_pagination/bloc/pagination_cubit.dart`
  - **Files**: `pagination_cubit.dart` (finally block ~line 932)
  - **Description**: T021 already added `_activeLoadMoreKey = null` to the `finally` block. Verify this covers the load-more error emit path (~line 892) — i.e., the error branch does not short-circuit before `finally`. Also confirm `_resetToInitial()` clears `_activeLoadMoreKey`. If any gap exists, add the null assignment explicitly in the error branch as well.
  - **Acceptance**: T05, T29 pass. After any error, the next `fetchPaginatedList()` is not blocked.
  - **Dependencies**: T021; T034, T037 confirmed failing
  - **Parallel**: No

**Checkpoint — US3 Done**: T05, T06, T26, T29 all pass.

---

## Phase 6: User Story 4 — State Reset (Priority: P4)

**Goal**: Refresh, search, or filter change clears all guards and allows fresh pagination from page 1.

**Independent Test**: T10–T13 in `load_more_guard_test.dart` all pass.

### Tests for US4 — Write and Confirm Failing BEFORE T043 ⚠️

- [ ] T039 [P] [US4] Implement T10 body: refresh clears all guards in `test/load_more_guard_test.dart`
  - **Files**: `test/load_more_guard_test.dart`
  - **Description**: Load to `hasReachedEnd == true`; call `refreshPaginatedList()`. Assert `state.hasReachedEnd == false` and a new `fetchPaginatedList()` reaches the provider.
  - **Acceptance**: Fails if `_activeLoadMoreKey` persists across refresh.
  - **Dependencies**: T006; Phase 3 complete
  - **Parallel**: Yes

- [ ] T040 [P] [US4] Implement T11 body: search/filter reset clears all guards in `test/load_more_guard_test.dart`
  - **Files**: `test/load_more_guard_test.dart`
  - **Description**: Load to end with filter A; call `refreshPaginatedList()` with filter B params. Assert page 1 of filter B loads and further pages continue normally.
  - **Acceptance**: Fails if guards from filter A persist.
  - **Dependencies**: T006
  - **Parallel**: Yes

- [ ] T041 [P] [US4] Implement T12 body: stale future response (old `_fetchToken`) is discarded in `test/load_more_guard_test.dart`
  - **Files**: `test/load_more_guard_test.dart`
  - **Description**: Start load-more via `Completer`; call `refreshPaginatedList()` (bumps `_fetchToken`); then complete the original completer. Assert the stale page is NOT appended; list shows only the refresh result.
  - **Acceptance**: Should already pass — write to confirm no regression.
  - **Dependencies**: T006
  - **Parallel**: Yes

- [ ] T042 [P] [US4] Implement T13 body: stale empty response does NOT set hasReachedEnd in `test/load_more_guard_test.dart`
  - **Files**: `test/load_more_guard_test.dart`
  - **Description**: Start load-more for page 2; refresh; complete page 2 with `[]`. Assert `state.hasReachedEnd == false` in the refreshed session.
  - **Acceptance**: Confirms stale empty response cannot poison fresh session end-of-list state.
  - **Dependencies**: T006
  - **Parallel**: Yes

> **Verify baseline**: T10, T11 should fail; T12, T13 likely already pass. Confirm before implementing.

### Implementation for US4

- [ ] T043 [US4] Clear `_activeLoadMoreKey` in `refreshPaginatedList()` and `_resetToInitial()` in `lib/smart_pagination/bloc/pagination_cubit.dart`
  - **Files**: `pagination_cubit.dart` (refresh and reset methods)
  - **Description**: In `_resetToInitial()` and at the start of `refreshPaginatedList()`, add `_activeLoadMoreKey = null;` and `_isFetching = false;` (if not already present). Ensures a completely clean guard state for every new session.
  - **Acceptance**: T10, T11 pass; refresh allows full re-pagination.
  - **Dependencies**: T039, T040 confirmed failing
  - **Parallel**: No

- [ ] T044 [US4] Verify `_generation++` precedes `_cancelAllPageStreams()` in reset path of `lib/smart_pagination/bloc/pagination_cubit.dart`
  - **Files**: `pagination_cubit.dart` (refresh/reset path)
  - **Description**: Confirm the reset order is exactly: (1) `_generation++`, (2) `_cancelAllPageStreams()`, (3) `_resetToInitial()`. If order differs, correct it. This ensures in-flight stream emissions from the previous generation are discarded before subscriptions are formally cancelled.
  - **Acceptance**: T17 (stale generation emission) passes; no out-of-order state mutation.
  - **Dependencies**: T043
  - **Parallel**: No

**Checkpoint — US4 Done**: T10–T13 all pass. All prior checkpoints still hold.

---

## Phase 7: Stream Guard

**Goal**: Stream providers call the factory exactly once per page; `_attachStream` rejects duplicate registration for the same page in the same generation.

**Independent Test**: T14–T19 in `test/stream_guard_test.dart` all pass.

### Tests for Stream Guard — Write and Confirm Failing BEFORE T051 ⚠️

- [ ] T045 [P] Write T14 body: StreamProvider factory called once per page in `test/stream_guard_test.dart`
  - **Files**: `test/stream_guard_test.dart`
  - **Description**: Wrap `streamFactory` to count calls. Load pages 1 and 2. Assert `factoryCallCount == 2` (one per page, not 4). Mirrors quickstart.md Flow 3.
  - **Acceptance**: Fails on un-patched code (`factoryCallCount == 4`).
  - **Dependencies**: T007; Phase 3–6 complete
  - **Parallel**: Yes

- [ ] T046 [P] Write T15 body: `_attachStream` skips duplicate page+generation in `test/stream_guard_test.dart`
  - **Files**: `test/stream_guard_test.dart`
  - **Description**: After page 2 stream is registered, directly call `_attachStream` again for page 2 with the same generation. Assert `_pageStreams[2]` still has exactly 1 subscription entry (no replace/double).
  - **Acceptance**: Fails if no generation guard exists in `_attachStream`.
  - **Dependencies**: T007
  - **Parallel**: Yes

- [ ] T047 [P] Write T16 body: stream stops registering new pages after confirmed end in `test/stream_guard_test.dart`
  - **Files**: `test/stream_guard_test.dart`
  - **Description**: Stream provider returns `pageSize - 1` items with `isComplete = true` set. Assert no new stream subscription is created on subsequent `fetchPaginatedList()` calls.
  - **Acceptance**: Tests T033 `isComplete` implementation.
  - **Dependencies**: T007
  - **Parallel**: Yes

- [ ] T048 [P] Write T17 body: stale generation stream emission is discarded in `test/stream_guard_test.dart`
  - **Files**: `test/stream_guard_test.dart`
  - **Description**: Register stream for generation 1; bump `_generation` to 2; trigger old stream emission. Assert `state.items` is NOT modified by the stale emission.
  - **Acceptance**: Should already pass — write to confirm no regression.
  - **Dependencies**: T007
  - **Parallel**: Yes

- [ ] T049 [P] Write T18 body: stream subscriptions cancelled on `refreshPaginatedList()` in `test/stream_guard_test.dart`
  - **Files**: `test/stream_guard_test.dart`
  - **Description**: Load 2 pages via stream provider. Call `refreshPaginatedList()`. Assert both subscriptions' `cancel()` is called (use mock `StreamSubscription`).
  - **Acceptance**: Should already pass — confirms Constitution §IV compliance.
  - **Dependencies**: T007
  - **Parallel**: Yes

- [ ] T050 [P] Write T19 body: per-page stream error isolates failing page in `test/stream_guard_test.dart`
  - **Files**: `test/stream_guard_test.dart`
  - **Description**: Page 2 stream emits an error; page 1 stream continues. Assert page 1 items present; `pageErrors[2]` is non-null; page 2 items absent from merged list.
  - **Acceptance**: Confirms stream error isolation behavior.
  - **Dependencies**: T007
  - **Parallel**: Yes

> **Verify baseline**: T14, T15 must fail; T16–T19 may pass. Confirm before implementing.

### Implementation for Stream Guard

- [ ] T051 Capture stream instance once in `_fetch()` for both `.first` and `_attachStream` in `lib/smart_pagination/bloc/pagination_cubit.dart`
  - **Files**: `pagination_cubit.dart` (lines ~757–862)
  - **Description**: In the `StreamPaginationProvider` branch: `final stream = provider.streamProvider(request);` before `await stream.first`. Pass `stream` to `_attachStream(stream, request)` — remove the second `provider.streamProvider(request)` call. Apply the same pattern to the `MergedStreamPaginationProvider` branch: `final mergedStream = provider.getMergedStream(request);`.
  - **Acceptance**: T14 passes (`factoryCallCount == 2` for 2 pages, not 4).
  - **Dependencies**: T045, T046 confirmed failing
  - **Parallel**: No

- [ ] T052 [P] Add duplicate-page generation guard at top of `_attachStream` in `lib/smart_pagination/bloc/pagination_cubit.dart`
  - **Files**: `pagination_cubit.dart` (lines ~1004–1010)
  - **Description**: At the very top of `_attachStream`: `if (_pageStreams.containsKey(page) && _pageStreams[page]!.generation == _generation) return;`. Move the existing `_pageStreams.remove(page)?.subscription.cancel();` to after this guard.
  - **Acceptance**: T15 passes (duplicate `_attachStream` call for same page+generation is silently skipped).
  - **Dependencies**: T051
  - **Parallel**: Yes — different region of file from T051 if editors are careful

- [ ] T053 [P] Verify MergedStreamProvider branch also uses single factory call in `lib/smart_pagination/bloc/pagination_cubit.dart`
  - **Files**: `pagination_cubit.dart` (merged-stream provider branch in `_fetch`)
  - **Description**: Confirm T051 correctly patched the merged-stream branch as well. If the `getMergedStream(request)` variable was not captured in one shot, fix it now. Run the equivalent of T14 for merged stream to confirm factory call count == pages loaded.
  - **Acceptance**: `getMergedStream` factory called once per page.
  - **Dependencies**: T051
  - **Parallel**: Yes after T051

**Checkpoint — Stream Guard Done**: T14–T19 all pass.

---

## Phase 8: Item Deduplication

**Goal**: Optional `identityKey` parameter removes cross-page duplicates before append.

**Independent Test**: T20–T22 in `test/deduplication_test.dart` all pass.

### Tests for Deduplication — Write and Confirm Failing BEFORE T057 ⚠️

- [ ] T054 [P] Write T20 body: with identityKey, cross-page duplicates appear once in `test/deduplication_test.dart`
  - **Files**: `test/deduplication_test.dart`
  - **Description**: Pages 1 and 2 overlap on `item.id == 4` (quickstart.md Flow 4). Cubit configured with `identityKey: (item) => item.id`. Assert `state.items.length == 9` and all IDs are unique.
  - **Acceptance**: Fails on un-patched code (length == 10, duplicate present).
  - **Dependencies**: T008; Phase 3–7 complete
  - **Parallel**: Yes

- [ ] T055 [P] Write T21 body: without identityKey, items appended as-is in `test/deduplication_test.dart`
  - **Files**: `test/deduplication_test.dart`
  - **Description**: Same overlapping pages; no `identityKey`. Assert `state.items.length == 10`.
  - **Acceptance**: Should already pass — confirms deduplication is opt-in.
  - **Dependencies**: T008
  - **Parallel**: Yes

- [ ] T056 [P] Write T22 body: deduplication runs before `onInsertionCallback` in `test/deduplication_test.dart`
  - **Files**: `test/deduplication_test.dart`
  - **Description**: Provide `onInsertionCallback` recording every inserted item. With `identityKey` configured, assert callback never receives an item with a duplicate ID.
  - **Acceptance**: Fails if deduplication runs after callback.
  - **Dependencies**: T008
  - **Parallel**: Yes

> **Verify baseline**: T20, T22 fail; T21 passes. Confirm before implementing.

### Implementation for Deduplication

- [ ] T057 Add optional `identityKey` constructor parameter to `SmartPaginationCubit` in `lib/smart_pagination/bloc/pagination_cubit.dart`
  - **Files**: `pagination_cubit.dart` (constructor and field declarations)
  - **Description**: Add `final Object? Function(T item)? identityKey;` field. Add `this.identityKey` to the constructor as an optional named parameter with no default. Existing consumers not providing it receive `null` (no deduplication).
  - **Acceptance**: Existing consumers compile unchanged; new consumers can pass `identityKey`.
  - **Dependencies**: T054 confirmed failing
  - **Parallel**: No

- [ ] T058 Apply deduplication in `_fetch()` before page append in `lib/smart_pagination/bloc/pagination_cubit.dart`
  - **Files**: `pagination_cubit.dart` (load-more path ~line 791)
  - **Description**: Before `_pages.add(pageItems)` in the load-more path: if `identityKey != null`, build `final seen = _pages.expand((p) => p).map(identityKey!).toSet();` then `pageItems = pageItems.where((item) => seen.add(identityKey!(item))).toList();`. Apply deduplication BEFORE the empty-page check (T031) so a post-dedup empty list also triggers end-of-list.
  - **Acceptance**: T20 passes (9 unique items); T21 passes (10 items when no key).
  - **Dependencies**: T057
  - **Parallel**: No

- [ ] T059 [P] Apply deduplication in `_emitMergedLoaded` for stream-accumulated pages in `lib/smart_pagination/bloc/pagination_cubit.dart`
  - **Files**: `pagination_cubit.dart` (lines ~1089)
  - **Description**: In `_emitMergedLoaded`, when constructing the merged items list from all `_pageStreams[n].latestValue` in ascending page order: if `identityKey != null`, deduplicate using a `Set<Object>`. Process pages in order; first occurrence wins; duplicates dropped.
  - **Acceptance**: T22 passes (callback never receives duplicate when `identityKey` configured).
  - **Dependencies**: T058
  - **Parallel**: Yes after T058

**Checkpoint — Deduplication Done**: T20–T22 all pass.

---

## Phase 9: Polish & Documentation

**Purpose**: Documentation, changelog, version bump, analysis, and full test run.

- [ ] T060 [P] Update `README.md` — add "Load-More Safety Behaviour" section
  - **Files**: `README.md`
  - **Description**: Add new section per plan Section 13 covering: (a) state-guard-only approach — no debounce/throttle; (b) exactly one active load-more per instance; (c) `identityKey` parameter with a code example; (d) `errorRetryStrategy` options with fast-scroll context; (e) retry-after-error note.
  - **Acceptance**: Section is present; `identityKey` code example compiles if pasted into a Dart file.
  - **Dependencies**: All implementation phases complete
  - **Parallel**: Yes

- [ ] T061 [P] Update `CHANGELOG.md` — add version entry for this feature
  - **Files**: `CHANGELOG.md`
  - **Description**: Add entry per plan Section 13 changelog template. Include `### Fixed` (load-more guard, stream factory dedup, `_attachStream` generation guard) and `### Added` (`identityKey`, cursor end-of-list detection). Version must match the bump in T062.
  - **Acceptance**: Entry present and correctly formatted under new version heading.
  - **Dependencies**: All implementation phases complete
  - **Parallel**: Yes

- [ ] T062 [P] Bump minor version in `pubspec.yaml` for new optional parameter
  - **Files**: `pubspec.yaml`
  - **Description**: Increment minor version (e.g., `2.3.x` → `2.4.0`) since `identityKey` is a new public optional constructor parameter. Update the `version:` field only.
  - **Acceptance**: Version is a valid semver minor bump; no breaking change.
  - **Dependencies**: All implementation phases complete
  - **Parallel**: Yes

- [ ] T063 Update dartdoc on `fetchPaginatedList()` documenting guard order in `lib/smart_pagination/bloc/pagination_cubit.dart`
  - **Files**: `pagination_cubit.dart` (fetchPaginatedList doc comment)
  - **Description**: Add/replace dartdoc listing all 10 guard steps from plan Section 4.4. Document when `_isFetching` is set and cleared, and the purpose of `_activeLoadMoreKey`.
  - **Acceptance**: `dart doc` generates without warnings for this method.
  - **Dependencies**: T060, T061, T062 complete
  - **Parallel**: No

- [ ] T064 [P] Update dartdoc on `_attachStream` and `_isFetching` in `lib/smart_pagination/bloc/pagination_cubit.dart`
  - **Files**: `pagination_cubit.dart`
  - **Description**: `_attachStream`: add comment "If the page is already registered under the current generation, the call is a no-op." `_isFetching`: add comment "Set in `fetchPaginatedList()` before `emit`; cleared in `_fetch()` finally block and `cancelOngoingRequest()`."
  - **Acceptance**: Comments are accurate and complete.
  - **Dependencies**: T063
  - **Parallel**: Yes — different lines from T063

- [ ] T065 Run `flutter analyze` and fix any new issues across changed files
  - **Files**: All files changed in phases 3–9
  - **Description**: Run `flutter analyze`. Address any new warnings or errors introduced by this feature. The ~49 pre-existing warnings are not in scope.
  - **Acceptance**: `flutter analyze` reports 0 new issues relative to pre-feature baseline.
  - **Dependencies**: T063, T064
  - **Parallel**: No

- [ ] T066 Run `flutter test` — all 29 new tests + full existing suite must pass at 100%
  - **Files**: `test/` (all 5 new test files + existing tests)
  - **Description**: Run `flutter test`. All 29 new tests (T01–T29) must pass. All pre-existing tests must pass. Zero regressions.
  - **Acceptance**: `flutter test` exits with code 0; output shows 0 failures across all files.
  - **Dependencies**: T065
  - **Parallel**: No

**DONE** — All 15 acceptance criteria from plan Section 15 are met.

---

## Dependencies & Execution Order

### Phase Dependencies

| Phase | Depends On | Blocks |
|-------|-----------|--------|
| Phase 1 (Audit) | nothing | Phase 2 |
| Phase 2 (Foundational) | Phase 1 | Phase 3–8 |
| Phase 3 (US1) | Phase 2 | Phase 4, 5, 6, 7 |
| Phase 4 (US2) | Phase 3 | Phase 9 |
| Phase 5 (US3) | Phase 3 | Phase 9 |
| Phase 6 (US4) | Phase 3, 5 | Phase 9 |
| Phase 7 (Stream Guard) | Phase 3 | Phase 8, 9 |
| Phase 8 (Deduplication) | Phase 7 | Phase 9 |
| Phase 9 (Polish) | All above | — |

### Within Each Phase: TDD Order

1. Write all failing test bodies for the phase
2. Run tests — confirm expected failures
3. Implement to make tests pass
4. Run full test suite — confirm no regressions
5. Commit; move to next phase

### Test-to-Phase Mapping

| Tests | Phase | Plan Section 12 file |
|-------|-------|---------------------|
| T01–T04 | Phase 3 (US1) | `load_more_guard_test.dart` |
| T05–T06 | Phase 5 (US3) | `load_more_guard_test.dart` |
| T07–T09 | Phase 4 (US2) | `load_more_guard_test.dart` |
| T10–T13 | Phase 6 (US4) | `load_more_guard_test.dart` |
| T14–T19 | Phase 7 (Stream Guard) | `stream_guard_test.dart` |
| T20–T22 | Phase 8 (Deduplication) | `deduplication_test.dart` |
| T23–T26 | Phase 4 (US2) | `end_of_list_test.dart` |
| T27–T29 | Phase 3 (US1) / 5 (US3) | `scroll_trigger_test.dart` |

---

## Parallel Opportunities

### Phase 2 — All scaffolds are independent
T007, T008, T009, T010 can all be created simultaneously (different files).

### Phase 3 — Tests vs. widget test
T011–T014 (load_more_guard_test.dart) are sequential within same file.
T015 (scroll_trigger_test.dart) is independent — run in parallel with T011.
T023 (paginate_api_view.dart) can run in parallel with T016–T022 (different file).

### Phase 4 — All US2 tests are parallel
T024–T030 are all independent — write in parallel.

### Phase 9 — Documentation tasks are parallel
T060, T061, T062 are all independent files — run in parallel.

---

## Implementation Strategy

### MVP First (Phase 3 — US1 Only)

1. Phase 1: Audit
2. Phase 2: Create test scaffolds
3. Phase 3: US1 guard + tests
4. **STOP and VALIDATE**: `flutter test test/load_more_guard_test.dart test/scroll_trigger_test.dart` → T01–T04, T27 green
5. Demo/review the core guard fix before proceeding to US2–US4

### Incremental Delivery

- US1 (Phase 3) → proves primary duplicate-fetch bug is fixed
- US2 (Phase 4) → adds reliable end-of-list detection
- US3 (Phase 5) → ensures error recovery
- US4 (Phase 6) → completes session-reset safety
- Stream Guard (Phase 7) → fixes RC-3 and RC-7 for stream providers
- Deduplication (Phase 8) → optional consumer-configured feature
- Polish (Phase 9) → documentation + verification

---

## Notes

- **[P]** tasks = different files or independent code regions; no unmet dependency
- Each user story phase ends with a checkpoint — run full test suite before advancing
- Commit after each checkpoint to preserve a passing baseline
- T021 (finally block) is a prerequisite for T038 (US3 error path) — verify coverage applies to both success and error branches
- The `identityKey` parameter (Phase 8) is additive — do not treat it as a prerequisite for US1–US4
- `addPostFrameCallback` in T023 is defense-in-depth; the cubit-level guard (T016–T022) is the primary fix
- All 29 tests map 1:1 to plan.md Section 12; use Section 12 as the authoritative test specification
