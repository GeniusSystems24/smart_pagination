# Contract: StreamPaginationProvider

**Surface**: `PaginationProvider.stream(...)` factory → `StreamPaginationProvider<T, R extends PaginationRequest>`.

## Preserved signature (backward-compatibility anchor)

```dart
sealed class PaginationProvider<T, R extends PaginationRequest> {
  const factory PaginationProvider.stream(
    Stream<List<T>> Function(R request) streamProvider,
  ) = StreamPaginationProvider<T, R>;
}
```

Removing, renaming, or altering the parameter shape is **forbidden** under Constitution II.

## Inputs the cubit supplies

- `R request` — exact subclass preserved (FR-030).
- An implicit generation token (the cubit's `_generation` at registration time). The cubit tags every registry entry with this generation and uses it to drop late emissions.

## Emissions the provider may produce per call

- Zero or more `List<T>` emissions over time (FR-010, FR-011).
- An empty list `[]` is a **valid** emission and represents the page's authoritative current value (FR-019a).
- A list shorter than `pageSize` is a valid emission; the cubit derives end-of-pagination from this state (FR-019b).
- A stream error — surfaced through the cubit's error channel as a per-page annotation; only the failing page's subscription is cancelled (FR-017 / spec Clarifications Q1).
- Stream completion — no-op for state; the page's last value is retained (FR-018).

## Lifecycle obligations imposed by the cubit

- The cubit registers **one entry per page load** in `_pageStreams[page]`. A new load-more does **not** cancel earlier pages' entries (FR-010).
- On scope reset (refresh, reload, filter change, search change, provider replacement, dispose), the cubit:
  1. Bumps `_generation`.
  2. Calls `registry.clearAll()` which cancels every `StreamSubscription` and clears `_pageStreams`.
  3. Discards any in-flight emissions whose `entry.generation` is no longer current (FR-016).
- On `maxPagesInMemory` eviction (existing feature), the cubit calls `registry.cancelAndRemove(evictedPage)` to keep `_pageStreams` aligned with `_pages`. This is lifecycle propagation, not a new eviction feature (per Research R6).
- On per-page error: cancel only that page's subscription; set `_pageErrors[page] = error`; leave siblings live (FR-017 / spec Clarifications Q1).

## Required test scenarios (mapped to acceptance criteria)

1. **Stream load-more accumulates instead of replacing** (FR-010 / US1 #1) — after `loadMore()`, both page 1 and page 2 subscriptions are alive.
2. **Per-page emission attribution** (FR-011, FR-012 / US1 #2) — pushing onto page 2's stream updates only page 2's slice; merged view = page 1 + page 2 + page 3.
3. **Scope reset cancels all entries** (FR-013 / US1 #3) — after refresh, every prior `StreamSubscription` is cancelled (verified via `Stream.listen`'s `onCancel`).
4. **Stale emission protection** (FR-016 / US1 #4) — push a buffered emission after `_generation` bump; assert state unchanged.
5. **Empty-list emission clears the slice and sets end-of-pagination** (FR-019a/b / Clarifications Q2) — emit `[]` on page 2; `items` shrinks to page 1; `loadMore()` is rejected.
6. **End-of-pagination clears when page becomes full again** (FR-019c / Clarifications Q2) — emit a full page on the same stream; `loadMore()` is re-enabled.
7. **Per-page error isolation** (FR-017 / Clarifications Q1) — page 2 errors; page 2's subscription is cancelled; `pageErrors[2]` is set; pages 1 and 3 keep emitting.
8. **Stream completion does not cancel siblings** (FR-018) — page 2 completes normally; pages 1 and 3 still emit; merged view retains page 2's last value.
9. **Cubit dispose cancels every entry** (FR-014 / US2 cross-applies) — close the cubit; assert every page's subscription is cancelled.
10. **`maxPagesInMemory` eviction cancels the dropped page's subscription** (Research R6 / Constitution IV) — load enough pages to trigger eviction; assert the evicted page's subscription is cancelled.
11. **Custom request subclass passes through unchanged across load-more** (FR-030 / US4) — load-more on page 2 with a custom `R` subclass; provider callback receives the exact subclass instance.
