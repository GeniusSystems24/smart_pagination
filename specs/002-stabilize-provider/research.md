# Phase 0 Research — Stabilize PaginationProvider

**Branch**: `002-stabilize-provider` | **Date**: 2026-05-05

The clarification session left no `NEEDS CLARIFICATION` markers in the spec. The questions below are the *implementation* questions that come up the moment the spec meets Dart/Flutter idioms. Each entry follows the format **Decision / Rationale / Alternatives considered**.

---

## R1. Per-page stream subscription registry — data structure

**Decision**: `Map<int, _PageStreamEntry<T>>` keyed by page index, where `_PageStreamEntry<T>` is a private value type carrying `(StreamSubscription<List<T>> subscription, int generation, List<T> latestValue, Object? error)`.

**Rationale**:
- Index-keyed lookup makes per-page cancellation, per-page error annotation, and per-page slice replacement all `O(1)`.
- Decouples cancellation from `_pages` list mutation — eviction can drop both atomically without index drift.
- The generation tag on each entry lets the cubit reject late emissions from a previous scope without consulting external state.

**Alternatives considered**:
- *Parallel `List<StreamSubscription>` aligned with `_pages` by index.* Rejected: any list mutation (insert at head on refresh, pop on eviction) forces realignment of parallel structures and creates off-by-one risk.
- *`StreamGroup` (from `package:async`).* Rejected: would add a new dependency, and `StreamGroup`'s semantics merge **emissions**, not page-attributed slices — we lose the "this emission belongs to page N" attribution we need for FR-011.

---

## R2. Where the end-of-pagination flag lives

**Decision**: Derived on every registry mutation (every emission, every page registration, every eviction). Not stored as an independent boolean. Defined as: `endOfPagination = registry.values.any((e) => e.latestValue.length < pageSize)`.

**Rationale**:
- The clarified rule is dynamic ("re-evaluates on every emission"). A derived flag stays consistent by construction; an independent boolean would need explicit invalidation on every state change and could drift.
- The check is `O(N)` over active pages; N is bounded by `maxPagesInMemory` (default 5), so the cost is negligible.

**Alternatives considered**:
- *Independent boolean updated on each emission.* Rejected: every registry mutation site would need to remember to recompute it. Bug-prone.
- *Track only the *latest* page's count.* Rejected: doesn't survive a stream re-emitting an older page back to a partial state — that scenario must also flip the flag.

---

## R3. Per-page error annotation — state shape

**Decision**: Extend `SmartPaginationState` (the loaded state subclass) with `final Map<int, Object> pageErrors` defaulting to `const <int, Object>{}`. Existing fields and constructors remain untouched.

**Rationale**:
- Additive change is backward compatible (Constitution II): consumers that ignore the field see no behavioral change; consumers that want per-page error UI can opt in.
- Map keyed by page index aligns with the registry shape — cancellation of a failing page sets `pageErrors[page] = error` and removes the registry entry in one transaction.
- A `const {}` default avoids per-state-instance allocation when no errors are present.

**Alternatives considered**:
- *Sibling stream (e.g., a `Stream<PageError>` exposed by the cubit).* Rejected: introduces a second state channel that the existing `BlocBuilder`/`BlocListener` consumers don't watch — bypasses Cubit Owns State (Constitution III).
- *Embed errors as sentinel items inside `_pages[page]`.* Rejected: violates Explicit Duplicate Handling (Constitution VII) and would corrupt list builders.

---

## R4. Stale-emission protection for stream pagination

**Decision**: Re-use the same generation/token mechanism the future path already uses. Each registry entry stores the generation under which it was registered. Every incoming emission compares its entry's generation with the cubit's current generation; mismatch ⇒ discard. Scope reset bumps the generation **before** any cancellation begins.

**Rationale**:
- Symmetric with the future path (one mental model, one bug surface).
- Bumping the generation before cancellation closes the race where a buffered emission arrives between the reset call and the actual subscription cancel.
- No new public surface required.

**Alternatives considered**:
- *`Stream.takeUntil(resetSignal)`.* Rejected: requires an external signal stream and complicates per-page lifecycle (each page would need its own takeUntil).
- *`isClosed` check on the cubit.* Rejected: handles dispose but not scope reset (the cubit is still alive after a refresh).

---

## R5. `MergedStreamPaginationProvider` lifecycle audit

**Decision**: Keep the empty (`Stream.value([])`) and single-stream (`streams.first`) shortcut paths, but wrap the single-stream path in a `StreamController` whose `onCancel` cancels the underlying subscription. The empty path remains a `Stream.value([])` that completes immediately and owns no resources.

**Rationale**:
- Symmetry: every non-empty path owns a controller and cancels its subscriptions in `onCancel`. The single-stream path becoming controller-managed eliminates the leak risk where the consumer subscribes to `streams.first` directly and the merge provider has no way to clean up if the parent never cancels.
- Empty path has nothing to leak, so `Stream.value([])` is fine.
- Aligns with FR-021 (zero/one/many cases all leak-free on disposal).

**Alternatives considered**:
- *Always go through the controller, including empty.* Rejected: extra allocation for a stream that emits nothing and completes immediately — measurable in tight test loops.
- *Document that the consumer is responsible for cancelling `streams.first` in the single case.* Rejected: pushes lifecycle responsibility onto the consumer, violating Stream Lifecycle Safety (Constitution IV).

---

## R6. Reconciling existing `maxPagesInMemory` with the "eviction out of scope" clarification

**Decision**: Preserve `maxPagesInMemory`'s existing semantics (page-list cap, default 5). The new per-page registry must subscribe to the same eviction event: when `_evictOldPages` removes a page from `_pages`, the corresponding registry entry's subscription is cancelled and removed. This is **lifecycle propagation**, not a new feature, so it remains consistent with the spec's "eviction out of scope" decision.

**Rationale**:
- `maxPagesInMemory` is already public (Constitution II — preserve).
- Without this propagation, evicting a page from `_pages` while leaving its stream subscription registered would be a guaranteed leak (Constitution IV violation).
- No new knob is added; no new policy is exposed; the spec's intent ("don't add eviction *as a feature*") is honored.

**Alternatives considered**:
- *Treat `maxPagesInMemory` as deprecated and skip propagation.* Rejected: backward-incompatible for any consumer that relies on the existing cap.
- *Add a separate `maxStreamsInMemory` knob.* Rejected: contradicts the "no new public knob" decision from clarification.

---

## R7. Test infrastructure — driving streams in tests

**Decision**: Use `StreamController<List<T>>.broadcast(sync: true)` test doubles per page so emissions are synchronous (eliminating event-loop ordering flakes). Pair with `bloc_test`'s `expectLater` for the cubit state transitions.

**Rationale**:
- Synchronous broadcast controllers make "emit on page 1; assert merged state immediately" tests deterministic.
- `bloc_test` already exists in the package's dev dependencies; no new dependency.
- Each test owns its controller and closes it in `tearDown` to validate the cubit's cancellation contract from both sides.

**Alternatives considered**:
- *`fake_async`.* Rejected: overkill for a library that doesn't depend on timer behavior in the affected paths.
- *Real Firestore/Socket fakes.* Rejected: out of scope; we are testing the provider/cubit contract, not network plumbing.

---

## Summary

All implementation choices above flow directly from the spec's clarified contract and the constitution's principles. No remaining unknowns. Plan is ready for Phase 1 design.
