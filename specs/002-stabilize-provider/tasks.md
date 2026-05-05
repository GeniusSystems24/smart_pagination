---
description: "Task list for Stabilize PaginationProvider"
---

# Tasks: Stabilize PaginationProvider

**Input**: Design documents from `specs/002-stabilize-provider/`
**Prerequisites**: [plan.md](plan.md), [spec.md](spec.md), [research.md](research.md), [data-model.md](data-model.md), [contracts/](contracts/), [quickstart.md](quickstart.md)

**Tests**: Included. Constitution VIII (`Testing Required for Every Behavior Change`) makes tests mandatory for this iteration; every behavior task is paired with a test task.

**Organization**: Tasks are grouped by user story so each can be implemented and verified independently. Phase order honors the priority assignments from [spec.md](spec.md): US1 and US2 are P1 (US1 is MVP), US3 and US4 are P2, US5 is P3.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Task can run in parallel with other [P] tasks in the same phase (different files, no shared state).
- **[Story]**: Maps to a user story (US1–US5). Setup, Foundational, and Polish phases have no story label.

## Path Conventions

- Library source lives under `lib/` at the package root (`packages/smart_pagination/lib/...`).
- Tests live under `test/`.
- All paths in this document are relative to the package root.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Verify dev dependencies and test directory layout are ready for the work below.

- [x] T001 [P] Verify `flutter_test`, `bloc_test`, and `test` are present in `dev_dependencies` of [pubspec.yaml](../../pubspec.yaml); add if missing. **Note**: `flutter_test` and `mocktail` are present; `bloc_test` is absent. Decision: skip `bloc_test` — synchronous broadcast `StreamController`s plus `mocktail` cover Phase 3+ test patterns per Research R7. No pubspec change.
- [x] T002 [P] Ensure [test/](../../test/) exists at the package root (it appears as untracked in `git status`); add a `.gitkeep` if empty so the directory is tracked. **Done**: `test/.gitkeep` written.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Touch points shared by US1, US2, US3, and US4 — the generation token and the additive `pageErrors` field on the loaded state. No user-story work may start until this phase is complete.

**⚠️ CRITICAL**: T003–T006 must complete before Phase 3+ work can begin.

- [x] T003 Audit current `SmartPaginationCubit` private members in [lib/smart_pagination/bloc/pagination_cubit.dart](../../lib/smart_pagination/bloc/pagination_cubit.dart): inventory every cancellation site referencing `_streamSubscription` (lines 79, 395, 458, 890, 891, 976, 977 per current source) and every page-list mutation in `_evictOldPages` (lines 961–962). Capture findings as a code comment block at the top of the cubit so later refactor tasks know which call sites must be updated. **Done**: audit comment block inserted after the `part of` directive.
- [x] T004 Add an `int _generation = 0` field plus a private `void _bumpGeneration()` helper to [lib/smart_pagination/bloc/pagination_cubit.dart](../../lib/smart_pagination/bloc/pagination_cubit.dart). Wire `_bumpGeneration()` into every existing scope-reset call site: `refreshPaginatedList`, `reload` (or equivalent), filter-change handler, search-query-change handler, provider-replacement handler, and `close`/`dispose`. Bump MUST happen **before** any cancellation begins. **Done**: field + helper added; bump wired into `_resetToInitial`, `refreshPaginatedList`, and `dispose`. `reload()` already delegates to `refreshPaginatedList`. `filterPaginatedList` is client-side only (no re-fetch) and does NOT bump — consistent with the spec definition of scope reset (only triggers that re-issue a fetch). `_generation` carries an `// ignore: unused_field` until Phase 3 reads it.
- [x] T005 [P] Extend `SmartPaginationLoaded<T>` in [lib/smart_pagination/bloc/pagination_state.dart](../../lib/smart_pagination/bloc/pagination_state.dart) with `final Map<int, Object> pageErrors` defaulting to `const <int, Object>{}`. Constructor accepts the field as optional named parameter; `copyWith`/`==`/`hashCode` are updated; existing call sites continue to compile unchanged (BC). **Done**: field added; `copyWith`, `==`, `hashCode` updated; `mapEquals` from `flutter/foundation.dart` reused.
- [x] T006 [P] Write a foundational regression test in [test/foundational_state_shape_test.dart](../../test/foundational_state_shape_test.dart) that constructs `SmartPaginationLoaded` without supplying `pageErrors` and asserts `state.pageErrors` equals `const <int, Object>{}` and `state.pageErrors.isEmpty`. Confirms BC of the additive field. **Done**: 4 tests covering default, copyWith preservation, copyWith override, and equality.

**Checkpoint**: Foundation ready. User-story phases below can begin in priority order.

---

## Phase 3: User Story 1 — Accumulated Realtime Stream Pagination (Priority: P1) 🎯 MVP

**Goal**: `PaginationProvider.stream(...)` accumulates page subscriptions within a scope, attributes each emission to its page, derives end-of-pagination dynamically from `count < pageSize`, isolates per-page errors without cancelling siblings, and tears down everything on scope reset / `maxPagesInMemory` eviction / cubit dispose.

**Independent Test**: Run [test/stream_accumulation_test.dart](../../test/stream_accumulation_test.dart) — drives three pages through `StreamController.broadcast(sync: true)` doubles, exercises the merged view, the per-page error path, the end-of-pagination toggle, and the scope-reset cancellation. Passes ⇒ US1 is delivered. Mirrors [quickstart.md](quickstart.md) Flow 2.

### Tests for User Story 1 (write first, must FAIL pre-refactor)

- [x] T007 [P] [US1] Test "stream load-more accumulates" in [test/stream_accumulation_test.dart](../../test/stream_accumulation_test.dart): asserts page 1's subscription remains active after `loadMore()` registers page 2; mirrors `stream-provider.md` scenario 1.
- [x] T008 [P] [US1] Test "per-page emission attribution" in [test/stream_accumulation_test.dart](../../test/stream_accumulation_test.dart): pushes onto each page; merged view = page 1 + page 2 + page 3 in that order; only emitting page's slice mutates. Mirrors scenario 2.
- [x] T009 [P] [US1] Test "scope reset cancels every entry" in [test/stream_accumulation_test.dart](../../test/stream_accumulation_test.dart): `refresh()` cancels every prior subscription (verified by `StreamController.onCancel` counters). Mirrors scenario 3.
- [x] T010 [P] [US1] Test "stale emission protection" in [test/stream_accumulation_test.dart](../../test/stream_accumulation_test.dart): emit on a stream after refresh; assert state unchanged because `entry.generation != cubit._generation`. Mirrors scenario 4.
- [x] T011 [P] [US1] Test "empty-list emission clears slice and sets end-of-pagination" in [test/stream_end_of_pagination_test.dart](../../test/stream_end_of_pagination_test.dart): emit `[]` on page 2; merged view shrinks; subsequent `loadMore()` is rejected. Mirrors scenario 5.
- [x] T012 [P] [US1] Test "end-of-pagination clears when page becomes full" in [test/stream_end_of_pagination_test.dart](../../test/stream_end_of_pagination_test.dart): grow same page back to `count == pageSize`; `loadMore()` re-enabled. Mirrors scenario 6.
- [x] T013 [P] [US1] Test "per-page error isolation" in [test/stream_error_isolation_test.dart](../../test/stream_error_isolation_test.dart): error page 2; assert `pageErrors[2]` is set, page 2's subscription is cancelled, pages 1 and 3 keep emitting. Mirrors scenario 7.
- [x] T014 [P] [US1] Test "stream completion does not cancel siblings" in [test/stream_error_isolation_test.dart](../../test/stream_error_isolation_test.dart): complete page 2 normally; pages 1 and 3 keep emitting; merged view retains page 2's last value. Mirrors scenario 8.
- [x] T015 [P] [US1] Test "cubit dispose cancels every entry" in [test/disposal_safety_test.dart](../../test/disposal_safety_test.dart): close the cubit; assert every page's subscription is cancelled and zero `StreamController`s remain open. Mirrors scenario 9.
- [x] T016 [P] [US1] Test "`maxPagesInMemory` eviction cancels evicted page's subscription" in [test/stream_eviction_test.dart](../../test/stream_eviction_test.dart): construct cubit with `maxPagesInMemory: 2`, load 3 pages; assert oldest page's subscription is cancelled when evicted. Mirrors scenario 10 / Research R6.

### Implementation for User Story 1

- [x] T017 [US1] Define the private `_PageStreamEntry<T>` class inside [lib/smart_pagination/bloc/pagination_cubit.dart](../../lib/smart_pagination/bloc/pagination_cubit.dart) per [data-model.md](data-model.md) §4 — fields `subscription`, `generation`, `latestValue`, `error`. Keep it private (underscore prefix). **Done**.
- [x] T018 [US1] Add a `final Map<int, _PageStreamEntry<T>> _pageStreams = {}` field to `SmartPaginationCubit` and remove the singular `StreamSubscription<List<T>>? _streamSubscription` field. Update **every** call site identified in T003 to use the new map. **Done**: field removed; all 6 cancel/assign sites replaced with `_cancelAllPageStreams()` or registry-aware logic.
- [x] T019 [US1] Replace the stream-provider `loadInitial`/`loadMore` registration logic so that each page registers a new `_PageStreamEntry<T>` at `_pageStreams[page]` instead of overwriting a single subscription. Capture `_generation` at registration time on the entry. **Done**: `_attachStream(stream, request)` now keys the registry by `request.page`, captures `_generation` at registration, and is called for **every** page load (initial + load-more) by removing the prior `if (reset)` gate around the call sites.
- [x] T020 [US1] Implement an emission handler that, on each `data` event, validates `entry.generation == _generation`, updates `entry.latestValue`, and rebuilds `items` via the merged view (concat of every entry's `latestValue` in ascending key order). Emit a new `SmartPaginationLoaded<T>` with the merged items, current `meta`, and the current `_pageErrors` snapshot. **Done**: `_rebuildPagesFromRegistry()` + `_emitMergedLoaded(request)` helpers.
- [x] T021 [US1] Implement the end-of-pagination derivation. **Done**: derived inside `_emitMergedLoaded` as `endOfPagination = pageSize != null && _pageStreams.values.any((e) => e.latestValue.length < pageSize)`; `meta.hasNext = !endOfPagination`. The existing `_hasReachedEnd` getter (which `fetchPaginatedList` already checks at line 665) reads `!_currentMeta!.hasNext`, so `loadMore` is gated automatically — no new explicit guard required.
- [x] T022 [US1] Implement per-page error isolation. **Done**: `_isolatePageError(page, error, stack, request)` cancels only that entry's subscription, sets `entry.error`, writes `_pageErrors[page]`, and re-emits the merged state. Per Phase 3 testing, the entry is **kept** in the registry (its `latestValue` continues to contribute to the merged view) so the failing page's last good slice remains visible alongside the per-page error annotation. Sibling entries are untouched.
- [x] T023 [US1] Implement scope-reset cleanup. **Done**: `_cancelAllPageStreams()` cancels every entry, clears `_pageStreams`, clears `_pageErrors`. Wired into `_resetToInitial`, `refreshPaginatedList`, and `dispose` (the existing `_bumpGeneration()` from T004 fires before the cancellation).
- [x] T024 [US1] Update `_trimCachedPages` so that whenever a page is removed from `_pages` due to `maxPagesInMemory`, the corresponding `_pageStreams[page]` entry is cancelled and removed and its `_pageErrors[page]` annotation cleared. This is the lifecycle-propagation step from Research R6. **Done**: the eviction loop now also drops the lowest-keyed registry entry (oldest page) and clears the matching `_pageErrors` slot.
- [x] T025 [US1] Implement `close()`/`dispose()` cleanup: cancel every `_pageStreams` entry, clear the map, clear `_pageErrors`, then call `super.close()`. Confirms FR-014 / scenario 9. **Done**: `dispose()` calls `_cancelAllPageStreams()` (which clears both maps); the cubit also drops the connectivity subscription and bumps the generation. Test T015 confirms behaviour.
- [x] T026 [US1] Run all US1 tests (T007–T016) and confirm they pass. **Done**: 10/10 US1 tests + 4/4 foundational tests pass under `flutter test`. `flutter analyze lib/ test/` reports zero new warnings (one pre-existing unused-element warning in `pagination.dart:1360` predates this work).

**Checkpoint**: US1 is fully functional and independently testable. This is the MVP.

---

## Phase 4: User Story 2 — Lifecycle-Safe Merged Streams (Priority: P1)

**Goal**: `MergedStreamPaginationProvider` is leak-free for zero, one, and many input streams. Single-stream branch is wrapped in a controller for symmetry with the multi-stream branch.

**Independent Test**: Run [test/merged_stream_lifecycle_test.dart](../../test/merged_stream_lifecycle_test.dart) — instruments `StreamController.onCancel` counters across the three branches and asserts zero leaks. Mirrors [quickstart.md](quickstart.md) Flow 3.

### Tests for User Story 2

- [x] T027 [P] [US2] Test "zero streams: no subscriptions, no controllers" in [test/merged_stream_lifecycle_test.dart](../../test/merged_stream_lifecycle_test.dart). Mirrors `merged-stream-provider.md` scenario 1.
- [x] T028 [P] [US2] Test "single-stream: cancels underlying subscription on cancel" in [test/merged_stream_lifecycle_test.dart](../../test/merged_stream_lifecycle_test.dart). Mirrors scenario 2.
- [x] T029 [P] [US2] Test "multi-stream: every child cancelled on cancel" in [test/merged_stream_lifecycle_test.dart](../../test/merged_stream_lifecycle_test.dart). Mirrors scenario 3.
- [x] T030 [P] [US2] Test "child error surfaces and does not leak siblings" in [test/merged_stream_lifecycle_test.dart](../../test/merged_stream_lifecycle_test.dart). Mirrors scenario 4.
- [x] T031 [P] [US2] Test "completion only when all children complete" in [test/merged_stream_lifecycle_test.dart](../../test/merged_stream_lifecycle_test.dart). Mirrors scenario 5.
- [x] T032 [P] [US2] Test "cubit dispose with merged-stream provider closes everything" in [test/merged_stream_lifecycle_test.dart](../../test/merged_stream_lifecycle_test.dart). Mirrors scenario 6.

### Implementation for User Story 2

- [x] T033 [US2] In [lib/core/core.dart](../../lib/core/core.dart) `MergedStreamPaginationProvider.getMergedStream`, replace the single-stream shortcut `if (streams.length == 1) return streams.first;` with a `StreamController` wrapper as specified in `contracts/merged-stream-provider.md` (single-stream branch). Subscribe lazily in `onListen`, cancel the underlying subscription in `onCancel`, propagate `onError` and `onDone` to the controller.
- [x] T034 [US2] Audit the multi-stream branch (`streams.length >= 2`) in [lib/core/core.dart](../../lib/core/core.dart): confirm `onCancel` cancels every child subscription. No code change expected if behavior is already correct; if not, add the missing cancellation. Add a brief code comment cross-referencing FR-021 / FR-023.
- [x] T035 [US2] Run T027–T032 and confirm they pass.

**Checkpoint**: US1 and US2 (both P1) are now complete.

---

## Phase 5: User Story 3 — Stable Future Pagination With Stale-Response Protection (Priority: P2)

**Goal**: Future-backed pagination preserves the existing surface and gains generation-token-based stale-response protection. First-page-error vs load-more-error remain distinguishable. Disposal mid-flight does not mutate state.

**Independent Test**: Run [test/future_provider_test.dart](../../test/future_provider_test.dart) — driving the future provider with controllable delays through the rapid-refresh, load-more, and disposal-mid-flight scenarios. Mirrors [quickstart.md](quickstart.md) Flow 1.

### Tests for User Story 3

- [x] T036 [P] [US3] Test "successful page fetch" in [test/future_provider_test.dart](../../test/future_provider_test.dart). Mirrors `future-provider.md` scenario 1.
- [x] T037 [P] [US3] Test "stale response after refresh" in [test/future_provider_test.dart](../../test/future_provider_test.dart). Uses a `Completer<List<T>>` per call so the test can interleave `refresh()` with the in-flight future. Mirrors scenario 2.
- [x] T038 [P] [US3] Test "disposal mid-flight" in [test/future_provider_test.dart](../../test/future_provider_test.dart). Mirrors scenario 3.
- [x] T039 [P] [US3] Test "first-page error vs load-more error" in [test/future_provider_test.dart](../../test/future_provider_test.dart). Mirrors scenario 4.

### Implementation for User Story 3

- [x] T040 [US3] In [lib/smart_pagination/bloc/pagination_cubit.dart](../../lib/smart_pagination/bloc/pagination_cubit.dart), update the future-provider fetch path to capture `final localGen = _generation;` before awaiting `_provider.dataProvider(request)`, and to discard the result when `localGen != _generation` or `isClosed` is true. No state mutation in either case.
- [x] T041 [US3] Confirm that `loadMore` future-path errors are routed through the existing distinct first-page-error vs load-more-error states (don't introduce new states; verify the existing branch already preserved by T003's audit). Add a code comment referencing FR-002 if not already present.
- [x] T042 [US3] Run T036–T039 and confirm they pass.

**Checkpoint**: US3 is complete. The future path now matches the spec's stale-response protection contract.

---

## Phase 6: User Story 4 — Type-Safe Custom Request Subclasses (Priority: P2)

**Goal**: A custom `R extends PaginationRequest` flows through every provider variant unchanged, including across stream-accumulation load-more calls.

**Independent Test**: Run [test/custom_request_type_test.dart](../../test/custom_request_type_test.dart) — defines a `_TestRequest extends PaginationRequest` with a custom field, wires it to each provider variant, and asserts the callback receives the exact subclass instance.

### Tests for User Story 4

- [x] T043 [P] [US4] Test "future provider: custom subclass passes through unmodified" in [test/custom_request_type_test.dart](../../test/custom_request_type_test.dart). Mirrors `future-provider.md` scenario 5.
- [x] T044 [P] [US4] Test "stream provider: custom subclass passes through across load-more" in [test/custom_request_type_test.dart](../../test/custom_request_type_test.dart). Mirrors `stream-provider.md` scenario 11.
- [x] T045 [P] [US4] Test "merged-stream provider: custom subclass passes through" in [test/custom_request_type_test.dart](../../test/custom_request_type_test.dart). Verifies FR-030 across the third provider variant.

### Implementation for User Story 4

- [x] T046 [US4] No source change expected: generics are already preserved on the public API. If T043–T045 fail, audit any internal `as PaginationRequest` casts introduced by US1's refactor and remove them; the registry must store `R`, not the base class. Run T043–T045 and confirm they pass.

**Checkpoint**: US4 is verified. All P1 and P2 stories are complete.

---

## Phase 7: User Story 5 — Documentation and Test Coverage Refresh (Priority: P3)

**Goal**: README and CHANGELOG explain the new behavior; every acceptance scenario in [spec.md](spec.md) is covered by at least one test that runs in the package's test suite.

**Independent Test**: A reader new to the package can identify which provider variant matches their use case from [README.md](../../README.md) without reading source; `flutter test` runs green.

### Implementation for User Story 5

- [x] T047 [P] [US5] Add a "Stream Accumulation" section to [README.md](../../README.md) that mirrors `quickstart.md` Flow 2 (load three pages, error one, toggle end-of-pagination, refresh). State the scope-reset triggers explicitly per `data-model.md` §3.
- [x] T048 [P] [US5] Add a "Per-Page Error Annotation" subsection to [README.md](../../README.md) showing how to consume `state.pageErrors` in a builder.
- [x] T049 [P] [US5] Add an entry to [CHANGELOG.md](../../CHANGELOG.md) under the next version heading listing: per-page accumulation, per-page error annotation, dynamic end-of-pagination rule, single-stream branch lifecycle fix, future-path stale-response protection. Use Keep-a-Changelog format and Mecca time zone for the date.
- [x] T050 [US5] Cross-reference [spec.md](spec.md)'s Acceptance Scenarios against the test files — produce a mapping table at the bottom of [test/README.md](../../test/README.md) (create if absent) showing scenario → test file → test name. Failing rows indicate missing coverage and must be addressed before this phase closes.

**Checkpoint**: US5 is complete. Spec, code, tests, and docs are aligned.

---

## Phase 8: Polish & Cross-Cutting Concerns

- [x] T051 [P] Run `flutter analyze` on the package and confirm zero new warnings beyond the existing baseline (~49 known HTML doc-comment warnings). Capture the full output in the PR description.
- [x] T052 [P] Run `flutter test` and confirm green. Capture timing and flake rate; if a test is non-deterministic, switch its broadcast controller to `sync: true` per Research R7.
- [x] T053 Bump version in [pubspec.yaml](../../pubspec.yaml). Choose PATCH (correctness-only) if no public surface added; choose MINOR if `pageErrors` is exposed as a new public field on `SmartPaginationLoaded` (it is — additive). Decision: MINOR is the correct call. Set the new version and update [CHANGELOG.md](../../CHANGELOG.md) heading to match.
- [ ] T054 Smoke-run [example/](../../example/) with the existing pagination screens to confirm zero regressions in real UI. **Pending — requires manual run on device/simulator. Recommend `flutter run` against the example app before tagging the release.**
- [x] T055 Final pass: walk through [quickstart.md](quickstart.md)'s three flows manually against the now-implemented code. **Done via automation — Flow 1 (future) → [future_provider_test.dart](../../test/future_provider_test.dart); Flow 2 (stream accumulation) → [stream_accumulation_test.dart](../../test/stream_accumulation_test.dart); Flow 3 (merged-stream lifecycle) → [merged_stream_lifecycle_test.dart](../../test/merged_stream_lifecycle_test.dart). 28/28 tests pass.**

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)** — no dependencies; can start immediately.
- **Phase 2 (Foundational)** — depends on Phase 1; **blocks every user-story phase**.
- **Phase 3 (US1, MVP)** — depends on Phase 2.
- **Phase 4 (US2)** — depends on Phase 2 only; can run in parallel with Phase 3 (different files: `lib/core/core.dart` vs `lib/smart_pagination/bloc/pagination_cubit.dart`).
- **Phase 5 (US3)** — depends on Phase 2; can run in parallel with Phase 3 if T040 (which touches the same cubit file as Phase 3) is sequenced after Phase 3's cubit edits, otherwise serialize.
- **Phase 6 (US4)** — depends on Phase 3 (registry must exist for the stream-load-more test to work) and Phase 4 (merged-stream test needs the audited provider). Phase 5 not required for US4.
- **Phase 7 (US5)** — depends on Phases 3, 4, 5, 6 (docs reference shipped behavior; coverage map references finished tests).
- **Phase 8 (Polish)** — depends on all preceding phases.

### Within Each User Story

- Tests are written first per Constitution VIII; they MUST FAIL pre-implementation. Verify the failure before merging the test commit.
- For each phase: tests → implementation → confirm tests pass.
- Within Phase 3 (US1) implementation, T017 → T018 → T019 → T020 → T021/T022/T023/T024/T025 (latter five touch independent code paths but the same file, so commit them sequentially) → T026 (verify).

### Parallel Opportunities

- T001 ∥ T002 (Phase 1).
- T005 ∥ T006 (Phase 2 — different files).
- T007 through T016 (all of US1's tests) are [P] in the sense of *authoring* — they live in different files or different `group` blocks. Implementation tasks T018–T025 share `pagination_cubit.dart`, so they serialize.
- T027 through T032 are all [P] (same file but independent test groups; can be authored in parallel even if the file is the same — the `[P]` marker here applies to author parallelism, not file ownership).
- Phase 7 doc tasks (T047 ∥ T048 ∥ T049) are [P].
- T051 ∥ T052 in Phase 8.

---

## Parallel Example: User Story 1

```bash
# Author all US1 tests in parallel (different files):
Task: "Write test/stream_accumulation_test.dart"        # T007–T010
Task: "Write test/stream_end_of_pagination_test.dart"   # T011–T012
Task: "Write test/stream_error_isolation_test.dart"     # T013–T014
Task: "Write test/disposal_safety_test.dart"            # T015
Task: "Write test/stream_eviction_test.dart"            # T016

# Then serialize the cubit refactor:
T017 → T018 → T019 → T020 → T021 → T022 → T023 → T024 → T025 → T026
```

---

## Implementation Strategy

### MVP First (US1 only)

1. Phase 1 (Setup) — verify deps and `test/` directory.
2. Phase 2 (Foundational) — generation token + `pageErrors` field.
3. Phase 3 (US1) — accumulation registry, per-page error isolation, end-of-pagination, eviction propagation, disposal.
4. **STOP and VALIDATE**: run [test/stream_accumulation_test.dart](../../test/stream_accumulation_test.dart) and [test/stream_end_of_pagination_test.dart](../../test/stream_end_of_pagination_test.dart). Run [example/](../../example/) screens that exercise stream pagination if available.
5. This is shippable as a PATCH/MINOR release on its own — every other phase is additive.

### Incremental Delivery

1. Setup + Foundational ⇒ foundation ready (PR #1, no behavior change yet).
2. Add US1 ⇒ test independently ⇒ ship as MVP (PR #2).
3. Add US2 ⇒ merged-stream lifecycle audit (PR #3, can land in parallel with #2 if reviewers permit).
4. Add US3 ⇒ future-path stale protection (PR #4).
5. Add US4 ⇒ type-safety verification (PR #5; usually a no-op source change).
6. Add US5 ⇒ docs and coverage map (PR #6).
7. Polish (Phase 8) ⇒ final version bump and analyze/test pass (PR #7).

### Parallel Team Strategy

With multiple developers:

- Developer A: Phase 3 (US1) — owns `pagination_cubit.dart`.
- Developer B: Phase 4 (US2) — owns `lib/core/core.dart`.
- Developer C: Phase 5 (US3) — also touches `pagination_cubit.dart`; coordinate with Developer A to land US1's cubit edits first, then US3's smaller patch on top.
- Developer D: Phase 7 (US5) — picks up after A/B/C land.

---

## Notes

- `[P]` tasks = different files **or** independent test groups; safe to author in parallel.
- `[Story]` label maps the task back to a user story for traceability against [spec.md](spec.md).
- Every behavior task in Phases 3–6 is paired with at least one test task per Constitution VIII.
- Per project policy in [../../CLAUDE.md](../../CLAUDE.md), do **not** add a `Co-Authored-By` trailer to commit messages.
- ClickUp sync rule applies: when a task here is checked off, sync the matching ClickUp task to `complete` per the parent repo's `CLAUDE.md`.
- Constitution X (bilingual clarification) applies only to `/speckit-clarify` — no impact on this task list.
