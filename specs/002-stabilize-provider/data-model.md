# Phase 1 Data Model — Stabilize PaginationProvider

**Branch**: `002-stabilize-provider` | **Date**: 2026-05-05

This document captures the conceptual entities (already named in [spec.md](spec.md)) plus the concrete Dart-level shapes the cubit will use to deliver per-page stream accumulation, end-of-pagination derivation, and per-page error isolation. Field-level details guide implementation; behavior contracts live in [contracts/](contracts/).

---

## Conceptual entities (from spec)

### 1. PaginationProvider

Strategy abstraction for how a paginated source produces pages. Three concrete subclasses, all preserved from the existing public API:

- `FuturePaginationProvider<T, R>` — `Future<List<T>> Function(R request) dataProvider`.
- `StreamPaginationProvider<T, R>` — `Stream<List<T>> Function(R request) streamProvider`.
- `MergedStreamPaginationProvider<T, R>` — `List<Stream<List<T>>> Function(R request) streamsProvider`.

**Constraints**:
- `R extends PaginationRequest` is preserved through every provider call (FR-030).
- Providers do not own state; they are pure adapters (Constitution III).

### 2. PaginationRequest (and subclasses)

Carrier for page index, page size, filters, search query, and any consumer-defined fields identifying a single load. The cubit treats request equality as the *scope identity*: a different request value indicates a new scope.

**Constraints**:
- The library does not introduce a new identity scheme; consumer-supplied equality (`==` / `hashCode`) is authoritative (per spec Assumption).
- Request type parameter `R` flows through `SmartPaginationCubit<T, R>` and the provider callback unchanged.

### 3. Pagination Scope

A logical query context defined by the tuple `(provider instance, filters, search query, request scope identity, pagination session)`. Scope identity changes on:

- Refresh / reload.
- Filter change.
- Search-query change.
- Provider replacement.
- Cubit dispose.

**Internally**: represented by an integer `_generation` field on the cubit. Bumped before any cancellation begins; every emission and every future response is checked against the current generation before mutating state.

### 4. Page Stream Registration

Tracks a single page's stream subscription within a scope. Used by the stream provider path to accumulate active subscriptions and to cancel them on scope reset, eviction (via `maxPagesInMemory`), or dispose.

**Concrete shape** (private, inside `SmartPaginationCubit`):

```dart
class _PageStreamEntry<T> {
  _PageStreamEntry({
    required this.subscription,
    required this.generation,
    required this.latestValue,
    this.error,
  });

  final StreamSubscription<List<T>> subscription;
  final int generation;
  List<T> latestValue;
  Object? error;
}
```

Fields:
- `subscription` — the live `StreamSubscription` for this page; cancelled exactly once.
- `generation` — the scope generation in effect when the entry was registered. Used to drop late emissions whose entry was already cancelled but whose buffer still flushed.
- `latestValue` — the most recent emission for this page, mutated in place on each accepted emission.
- `error` — if non-null, the entry is in a per-page error state and its `subscription` has already been cancelled. Sibling pages remain unaffected.

### 5. Stream Accumulation Registry

The ordered collection of active page stream registrations belonging to the current scope. Cleared atomically on scope reset.

**Concrete shape**: `Map<int, _PageStreamEntry<T>>` keyed by 1-based page index.

**Operations**:
- `register(page, subscription, generation)` — insert; replaces any prior entry for that page (which should not happen under correct usage).
- `cancelAndRemove(page)` — cancel the entry's subscription and remove it.
- `clearAll()` — cancel every subscription and clear the map. Called on scope reset and dispose.
- `mergedView()` — concatenate every entry's `latestValue` in ascending page order; this is the source of the cubit's published items list.
- `endOfPagination()` — `true` iff any entry has `latestValue.length < pageSize`. Re-evaluated on every emission.

### 6. SmartPaginationCubit

Owns scope identity, request generation tokens, retry policy, the new registry, and the public state stream.

**State fields** (additions / changes only — existing fields preserved):

- `int _generation` *(new)* — bumped on every scope reset.
- `Map<int, _PageStreamEntry<T>> _pageStreams` *(new)* — replaces the previous singular `StreamSubscription<List<T>>? _streamSubscription` for the stream provider path. Future provider path is unaffected by this field.
- `Map<int, Object> _pageErrors` *(new, surfaced via state)* — populated when a per-page stream errors.
- `bool _endOfPagination` *(derived, not stored)* — computed from `_pageStreams` on demand.

**Backward-compatibility note**: `_streamSubscription` may remain as an unused field for one release, marked `@deprecated` and never assigned, to ease internal refactor risk; preferred path is to delete it cleanly since it was always private. Final call belongs to the tasks phase.

---

## State machine (cubit)

The existing public state hierarchy is preserved. `SmartPaginationLoaded<T>` gains an additive `pageErrors` field:

```dart
class SmartPaginationLoaded<T> extends SmartPaginationState<T> {
  const SmartPaginationLoaded({
    required this.items,
    required this.meta,
    this.pageErrors = const <int, Object>{}, // additive, BC-safe default
  });

  final List<T> items;
  final PaginationMeta meta;
  final Map<int, Object> pageErrors;
}
```

Transitions:

```
            ┌────────────────┐
            │     Initial     │
            └────────┬───────┘
                     │ load(page=1)
                     ▼
            ┌────────────────┐
            │     Loading     │
            └────────┬───────┘
       success │            │ first-page error
              ▼              ▼
   ┌────────────────┐   ┌────────────────┐
   │     Loaded      │   │  FirstPageError │
   │ pageErrors={}   │   └────────┬───────┘
   └─────┬──┬───────┘            │ refresh
         │  │                    ▼
load-more │  │            (back to Initial)
   ▼      │
┌────────────────────┐
│ LoadMoreLoading     │
└──────┬───────────┬──┘
success│           │ load-more error (page-level)
       ▼           ▼
┌────────────────┐  ┌──────────────────────┐
│   Loaded         │  │ Loaded               │
│ pageErrors={}   │  │ pageErrors={p:err}   │  ← per-page error annotation
└────┬────────────┘  └──┬──────────────────┘
     │ scope reset       │ scope reset
     ▼                    ▼
   (back to Initial; registry.clearAll())
```

Notes:
- Per-page errors **do not** transition the state to a global error state; siblings keep emitting and the merged list keeps shrinking/growing per the end-of-pagination rule.
- Stream completion of a page is a no-op for state; the page's `latestValue` is retained.

---

## Validation rules (derived from FRs)

- FR-003 / FR-016: every emission and every future response is gated by `entry.generation == cubit._generation`. Mismatch → discard silently (no state mutation, no error surface).
- FR-010 / FR-012: `mergedView()` is the only path from registry to the cubit's published `items`. There is no per-emission append step.
- FR-019b/c: `loadMore` checks `endOfPagination()` before registering a new entry; if true, the call returns silently (or surfaces a benign no-op state transition — to be decided in tasks based on existing `loadMore` failure-mode conventions).
- FR-021 / FR-022: `MergedStreamPaginationProvider`'s controller cancels all child subscriptions in `onCancel`; the empty path uses `Stream.value([])` (no resources); the single-stream path is wrapped in a controller for symmetry (per Research R5).

---

## Out-of-scope (recorded for traceability)

- Page eviction as a *new feature* (per spec clarification). Existing `maxPagesInMemory` cap is preserved and now propagates cancellation to the registry — this is lifecycle safety, not a new feature (per Research R6).
- New public knobs (e.g., `maxStreamsInMemory`). None added.
- Implicit deduplication. Never (Constitution VII).
