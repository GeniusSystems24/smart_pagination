# Implementation Plan: Stabilize PaginationProvider

**Branch**: `002-stabilize-provider` | **Date**: 2026-05-05 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from [specs/002-stabilize-provider/spec.md](spec.md)

## Summary

Stabilize the existing `PaginationProvider` system in the `smart_pagination` Dart/Flutter package without breaking its public API. The headline change is a **per-page stream subscription registry** inside `SmartPaginationCubit` (replacing the current single `_streamSubscription` field) so that stream-based pagination accumulates pages within a scope instead of replacing the previous page's stream. The cubit aggregates each page's latest emission into the merged paginated state, applies the new clarified end-of-pagination rule (`count < pageSize` ⇒ block `loadMore`; re-evaluated on every emission), isolates per-page errors (cancel only the failing page's subscription), tightens stale-response protection on the future path via the existing generation token, and audits `MergedStreamPaginationProvider`'s controller/subscription lifecycle. Eviction is **out of scope** as a new feature, but the existing `maxPagesInMemory` knob must propagate page drops to the new registry so that the corresponding subscription is cancelled (lifecycle safety, not a new feature). README, CHANGELOG, and tests are updated to cover every acceptance scenario.

## Technical Context

**Language/Version**: Dart `>=3.10.0 <4.0.0`, Flutter `>=3.0.0` (from `pubspec.yaml`).
**Primary Dependencies**: `flutter_bloc` (Cubit), `provider` (DI), `flutter_staggered_grid_view` (UI). No new heavy dependencies.
**Storage**: N/A — in-memory pagination state owned by the cubit.
**Testing**: `flutter_test` + `bloc_test` for cubit behavior, fake `Stream`/`Future` test doubles for provider variants.
**Target Platform**: Flutter (iOS, Android, Web, Desktop) — pure Dart logic, no platform channels.
**Project Type**: Library package (single Dart package, not an app).
**Performance Goals**: No new perf targets — the existing pagination throughput is unchanged. Bookkeeping overhead of the new per-page registry must remain `O(1)` per emission and `O(N)` (N = active pages) per scope reset.
**Constraints**: Backward-compatible public API surface (Constitution II); zero leaks of `StreamSubscription` or `StreamController` (Constitution IV); no silent dedup (Constitution VII); no new public knobs in this iteration; existing `maxPagesInMemory` semantics preserved.
**Scale/Scope**: Library used by ClubApp Mobile and external consumers; a typical screen has 1–10 active pages × 1 stream each. Worst-case bound for the registry is `maxPagesInMemory` simultaneous subscriptions per scope.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **I. Library-First Design** — ✅ — No business assumptions added. New behavior is internal to the cubit; widgets unchanged.
- **II. Backward Compatibility First** — ✅ — `.withProvider`, `.withCubit`, `PaginationProvider.future/stream/mergeStreams`, custom `PaginationRequest` subclasses all preserved. README examples remain valid.
- **III. Cubit Owns Pagination State** — ✅ — Per-page registry lives **inside** the cubit; providers stay as data-source adapters.
- **IV. Stream Lifecycle Safety** — ✅ — Every registry entry has a single owner (the cubit). Cancellation paths: scope reset, `maxPagesInMemory` eviction, dispose. `MergedStreamPaginationProvider`'s internal controller is audited for `onCancel` correctness in the empty/single/many cases.
- **V. Stream Accumulation Rule** — ✅ — This is the headline behavior — directly implemented by the per-page registry.
- **VI. Correctness Before Convenience** — ✅ — Stale future responses dropped by generation token; stale stream emissions dropped by registry+scope check; no silent dedup.
- **VII. Explicit Duplicate Handling** — ✅ — Existing `listBuilder` callback is unchanged; no implicit dedup added.
- **VIII. Testing Required** — ✅ — Phase 1 produces a contract test plan and a quickstart that covers every acceptance scenario in the spec.
- **IX. Documentation Required** — ✅ — README and CHANGELOG entries are scheduled in Phase 2 tasks (the `/speckit-tasks` step). Provider behavior notes and stream lifecycle notes are documented in `data-model.md` for downstream tasks.
- **X. Bilingual Clarification Questions** — ✅ — Already honored during `/speckit-clarify` (English + Arabic). Not a planning-phase concern.

**Initial gate**: PASS. No violations to track.

## Project Structure

### Documentation (this feature)

```text
specs/002-stabilize-provider/
├── plan.md              # This file (/speckit-plan output)
├── spec.md              # Feature spec (clarified)
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output (provider behavior contracts)
│   ├── future-provider.md
│   ├── stream-provider.md
│   └── merged-stream-provider.md
├── checklists/
│   └── requirements.md  # Spec quality checklist
└── tasks.md             # Phase 2 output (created by /speckit-tasks)
```

### Source Code (repository root)

```text
packages/smart_pagination/
├── lib/
│   ├── pagination.dart              # Main barrel export
│   ├── core/
│   │   └── core.dart                # PaginationProvider sealed hierarchy (✏ audit MergedStream lifecycle)
│   ├── data/                        # PaginationRequest, PaginationMeta, models
│   ├── smart_pagination/
│   │   ├── pagination.dart
│   │   ├── bloc/
│   │   │   ├── pagination_cubit.dart      # ✏ Replace _streamSubscription with per-page registry; add end-of-pagination rule; per-page error isolation; eviction → cancel
│   │   │   ├── pagination_state.dart      # ✏ Add per-page error annotation field; preserve existing state shapes (BC)
│   │   │   └── pagination_listeners.dart
│   │   ├── controller/
│   │   └── widgets/                       # No changes expected
│   └── smart_search/                      # Unrelated; no changes
└── test/                              # ✏ Add test suites covering every acceptance scenario
    ├── future_provider_test.dart
    ├── stream_provider_test.dart
    ├── stream_accumulation_test.dart
    ├── stream_error_isolation_test.dart
    ├── stream_end_of_pagination_test.dart
    ├── merged_stream_lifecycle_test.dart
    └── disposal_safety_test.dart
```

**Structure Decision**: Single Dart package (Option 1 from the template). All work is contained inside `packages/smart_pagination/`. The cubit changes are concentrated in `lib/smart_pagination/bloc/pagination_cubit.dart` and `pagination_state.dart`; provider changes are limited to a lifecycle audit of `MergedStreamPaginationProvider` in `lib/core/core.dart`. Tests live under `test/` per Dart convention. No new directories are introduced.

## Phase 0 — Outline & Research

The clarification session resolved the three previously-Partial categories (per-page error semantics, empty-emission semantics, eviction scope), so there are **no `NEEDS CLARIFICATION` markers remaining in the spec**. Phase 0 research focuses on the few implementation choices that depend on Dart/Flutter idioms rather than spec ambiguities:

1. **Per-page registry data structure** — `Map<int, _PageStreamEntry<T>>` keyed by page index vs. parallel `List<StreamSubscription>` aligned with `_pages`. Decision: index-keyed map (decouples cancellation from list mutation).
2. **End-of-pagination flag location** — track on the cubit (one boolean per scope) vs. derive every emission from registry state. Decision: derive on every emission so the flag stays consistent with `count < pageSize` reality after every update.
3. **Per-page error annotation shape** — extend `SmartPaginationState` with a `Map<int, Object> pageErrors` vs. emit a sibling event channel. Decision: extend the state via a new `pageErrors` field with a `const {}` default (additive, BC-safe).
4. **Stale-emission filter for stream pagination** — re-use the existing generation/token approach used by the future path; tag every registry entry with the generation it was created under and discard emissions whose generation no longer matches the cubit's current generation.
5. **`MergedStreamPaginationProvider` empty/single shortcut paths** — current code returns `Stream.value([])` for empty and `streams.first` for single; decision: keep the empty/single shortcuts but wrap the single case in a controller that owns the subscription, so disposal is symmetric across all three branches.

Output: [research.md](research.md) consolidating decisions, rationale, and rejected alternatives.

## Phase 1 — Design & Contracts

Prerequisite: `research.md` complete.

1. **Data model** ([data-model.md](data-model.md)) — capture the conceptual entities that already live in spec (Pagination Scope, Page Stream Registration, Stream Accumulation Registry, etc.) plus the concrete Dart-level shapes the cubit will use: the new `_PageStreamEntry<T>` record, the registry map, the `pageErrors` annotation map, and the generation-token field. Document the state-machine transitions (idle → loading → loaded → loadMoreLoading → loaded with `pageErrors` non-empty → end-of-pagination → reset).

2. **Contracts** ([contracts/](contracts/)) — one markdown contract per provider variant (`future-provider.md`, `stream-provider.md`, `merged-stream-provider.md`). Each contract enumerates: the constructor's preserved signature (BC anchor), the lifecycle obligations the cubit imposes, the inputs the provider receives from the cubit (request, generation token), the emissions the provider may produce, and the failure modes the cubit must accept. These contracts become the source of truth for the contract-style tests in Phase 2.

3. **Quickstart** ([quickstart.md](quickstart.md)) — a runnable, copy-paste-friendly walkthrough showing the three flows: (a) future pagination with a refresh + load-more sequence; (b) stream pagination with three accumulated pages and a per-page error injection; (c) merged-stream provider with empty/single/many shapes. Each flow ends with the assertion that distinguishes the new behavior from the old.

4. **Agent context update** — update the `<!-- SPECKIT START -->` … `<!-- SPECKIT END -->` block in `CLAUDE.md` to point to this plan file.

Output: `data-model.md`, `contracts/future-provider.md`, `contracts/stream-provider.md`, `contracts/merged-stream-provider.md`, `quickstart.md`, updated `CLAUDE.md`.

## Phase 2 — Tasks (handled by `/speckit-tasks`)

Out of scope for `/speckit-plan`. Listed here only so reviewers see the chain:

1. Refactor cubit: replace `_streamSubscription` with per-page registry; thread generation token; add `pageErrors` to state; cancellation in `dispose`/`reset`/`_evictOldPages`.
2. Implement end-of-pagination derivation rule + `loadMore` guard.
3. Implement per-page error isolation.
4. Audit `MergedStreamPaginationProvider` (single-stream branch wrapped in a controller; explicit teardown).
5. Tests (one suite per acceptance scenario, mapped 1-for-1 against `contracts/*.md`).
6. README + CHANGELOG entries.
7. Bump `pubspec.yaml` version per SemVer (PATCH if pure correctness; MINOR if any additive public surface like `pageErrors` getter is shipped — to be decided by the tasks step).

## Re-check Constitution after Phase 1 design

- **I. Library-First** — ✅ — no business hardcoding introduced; design lives in cubit.
- **II. Backward Compatibility** — ✅ — every public constructor and signature unchanged; `pageErrors` is additive on `SmartPaginationState`.
- **III. Cubit Owns State** — ✅ — registry and end-of-pagination flag live in cubit; providers untouched semantically.
- **IV. Stream Lifecycle Safety** — ✅ — registry has documented owner and three cancellation triggers (reset, eviction, dispose); merged-stream's single-stream branch is audited and aligned with empty/many.
- **V. Stream Accumulation** — ✅ — directly delivered.
- **VI. Correctness Before Convenience** — ✅ — generation tokens drop stale future responses and stale stream emissions; no implicit dedup.
- **VII. Explicit Duplicate Handling** — ✅ — `listBuilder` path unchanged.
- **VIII. Testing Required** — ✅ — contracts/ + quickstart enumerate the test set.
- **IX. Documentation Required** — ✅ — README and CHANGELOG updates scheduled by Phase 2; data-model.md captures provider behavior notes.
- **X. Bilingual Clarification** — ✅ — N/A at planning phase.

**Post-design gate**: PASS. No violations to track in Complexity Tracking.

## Complexity Tracking

No constitution violations to track. Initial gate and post-design gate both PASS. Table intentionally omitted.
