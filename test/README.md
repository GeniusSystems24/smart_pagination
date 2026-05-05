# Test Suite — Spec 002 Stabilize Provider

This directory holds the automated tests for the work tracked in [`specs/002-stabilize-provider/`](../specs/002-stabilize-provider/). Each test file maps to one user story (or to the foundational layer); each `test(...)` inside a file maps to one acceptance scenario via a `Tnnn:` prefix on the test name.

## Run

```bash
flutter test
```

## Coverage map

Below is the cross-reference between every acceptance scenario in [spec.md](../specs/002-stabilize-provider/spec.md) and the test that exercises it. A row marked **MISSING** indicates a gap that must be closed before the spec is considered fully covered.

### Foundational (Phase 2)

| Item | Test file | Test name |
|------|-----------|-----------|
| FR-005 / pageErrors default = `const {}` | [foundational_state_shape_test.dart](foundational_state_shape_test.dart) | defaults to const {} when not supplied |
| pageErrors copyWith preservation | [foundational_state_shape_test.dart](foundational_state_shape_test.dart) | survives copyWith without pageErrors override |
| pageErrors copyWith override | [foundational_state_shape_test.dart](foundational_state_shape_test.dart) | copyWith can set a new pageErrors map |
| pageErrors equality | [foundational_state_shape_test.dart](foundational_state_shape_test.dart) | pageErrors difference breaks equality (isolated) |

### US1 — Accumulated Realtime Stream Pagination (P1, MVP)

| Scenario / FR | Test file | Test name |
|---------------|-----------|-----------|
| US1 #1 / FR-010 — load-more accumulates | [stream_accumulation_test.dart](stream_accumulation_test.dart) | T007: stream load-more accumulates instead of replacing |
| US1 #2 / FR-011, FR-012 — per-page emission attribution | [stream_accumulation_test.dart](stream_accumulation_test.dart) | T008: per-page emission attribution (3 pages, in order) |
| US1 #3 / FR-013, FR-014 — scope reset cancels every entry | [stream_accumulation_test.dart](stream_accumulation_test.dart) | T009: scope reset cancels every active page subscription |
| US1 #4 / FR-016 — stale emissions dropped | [stream_accumulation_test.dart](stream_accumulation_test.dart) | T010: stale emissions from old scope are discarded |
| Q2 / FR-019a, FR-019b — empty-list emission ⇒ end-of-pagination | [stream_accumulation_test.dart](stream_accumulation_test.dart) | T011: empty-list emission clears slice and signals end-of-pagination |
| Q2 / FR-019c — end-of-pagination clears when full | [stream_accumulation_test.dart](stream_accumulation_test.dart) | T012: end-of-pagination clears when page becomes full again |
| Q1 / FR-017 — per-page error isolation | [stream_accumulation_test.dart](stream_accumulation_test.dart) | T013: per-page error isolates the failing page |
| FR-018 — completion does not cancel siblings | [stream_accumulation_test.dart](stream_accumulation_test.dart) | T014: stream completion does not cancel siblings |
| FR-014 — dispose cancels every entry | [stream_accumulation_test.dart](stream_accumulation_test.dart) | T015: cubit close cancels every registry subscription |
| Research R6 — eviction propagation | [stream_accumulation_test.dart](stream_accumulation_test.dart) | T016: maxPagesInMemory eviction cancels evicted page subscription |

### US2 — Lifecycle-Safe Merged Streams (P1)

| Scenario / FR | Test file | Test name |
|---------------|-----------|-----------|
| US2 #1 / FR-020 — zero streams: no resources held | [merged_stream_lifecycle_test.dart](merged_stream_lifecycle_test.dart) | T027: zero streams emits empty page and holds no resources |
| US2 / FR-021 — single-stream cancels underlying on cancel | [merged_stream_lifecycle_test.dart](merged_stream_lifecycle_test.dart) | T028: single-stream branch cancels underlying subscription on cancel |
| US2 #2 / FR-021 — multi-stream cancels every child | [merged_stream_lifecycle_test.dart](merged_stream_lifecycle_test.dart) | T029: multi-stream branch cancels every child on cancel |
| US2 #3 / FR-022 — child error surfaces, siblings live | [merged_stream_lifecycle_test.dart](merged_stream_lifecycle_test.dart) | T030: child error surfaces and does not cancel siblings |
| US2 #4 / FR-023 — completion only when all complete | [merged_stream_lifecycle_test.dart](merged_stream_lifecycle_test.dart) | T031: merged stream completes only when every child completes |
| FR-014, FR-021 — cubit dispose closes everything | [merged_stream_lifecycle_test.dart](merged_stream_lifecycle_test.dart) | T032: cubit dispose with merged-stream provider closes cleanly |

### US3 — Stable Future Pagination (P2)

| Scenario / FR | Test file | Test name |
|---------------|-----------|-----------|
| US3 #1 / FR-001 — successful page fetch | [future_provider_test.dart](future_provider_test.dart) | T036: successful page fetch produces a Loaded state |
| US3 #2 / FR-003 — stale response after refresh | [future_provider_test.dart](future_provider_test.dart) | T037: stale response from a superseded request is discarded |
| US3 #3 / FR-005 — disposal mid-flight | [future_provider_test.dart](future_provider_test.dart) | T038: in-flight request resolving after close does not throw |
| US3 #4 / FR-002 — load-more error annotation | [future_provider_test.dart](future_provider_test.dart) | T039: load-more error annotates the existing Loaded state |
| FR-002 — first-page error transitions to error state | [future_provider_test.dart](future_provider_test.dart) | T039b: first-page error transitions to SmartPaginationError |

### US4 — Type-Safe Custom Request Subclasses (P2)

| Scenario / FR | Test file | Test name |
|---------------|-----------|-----------|
| US4 #1 / FR-030 — future provider preserves subclass | [custom_request_type_test.dart](custom_request_type_test.dart) | T043: future provider receives the custom subclass unchanged |
| US4 #2 / FR-030 — stream provider preserves subclass | [custom_request_type_test.dart](custom_request_type_test.dart) | T044: stream provider preserves custom subclass across load-more |
| FR-030 — merged-stream provider preserves subclass | [custom_request_type_test.dart](custom_request_type_test.dart) | T045: merged-stream provider preserves custom subclass |

## Test infrastructure notes

- **Synchronous broadcast controllers**: `StreamController<List<T>>.broadcast(sync: true)` is the default test double. Synchronous emission removes event-loop ordering flakes. Per Research R7.
- **Two streamProvider invocations per page load**: the cubit calls `streamProvider(req)` once for `.first` (to seed the page) and once for the live subscription. Test factories must return a stream that supports two listeners — broadcast controllers are the simplest fit.
- **No `bloc_test` dependency**: tests rely on plain `flutter_test` plus `cubit.stream.firstWhere(...)` for state-transition assertions. Adding `bloc_test` was considered and skipped — see Research R7.
