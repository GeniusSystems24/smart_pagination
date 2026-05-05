# Implementation Plan: Load-More Guard

**Branch**: `003-load-more-guard` | **Date**: 2026-05-05 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `specs/003-load-more-guard/spec.md`

---

## Summary

`SmartPaginationCubit` contains a class of stability bugs where rapid or repeated
scroll events can trigger multiple concurrent `fetchPaginatedList()` calls, causing
duplicate page fetches, widget-state desync, and potential infinite loading loops.
The fix adds a layered guard system — per-request key tracking, a strengthened
in-flight flag, cursor-aware end-of-list detection, and optional identity-key
deduplication — all internal to the cubit/provider layer, with no breaking changes
to the public API.

---

## Technical Context

**Language/Version**: Dart 3.x (null-safe)
**Primary Dependencies**: `flutter_bloc` (Cubit), `flutter` SDK
**Storage**: In-memory page cache (`_pages: List<List<T>>`, `_pageStreams: Map<int, _PageStreamEntry<T>>`)
**Testing**: `flutter_test`, `bloc_test`
**Target Platform**: Flutter (all platforms — this is a library package)
**Project Type**: Dart/Flutter library (pub-published)
**Performance Goals**: Zero duplicate provider calls per page under any scroll pattern; `fetchPaginatedList()` guard check must complete in O(1)
**Constraints**: No breaking changes to public API; no new required constructor parameters; backward compatibility is a hard constraint per Constitution §II

---

## Constitution Check

*GATE: Evaluated before Phase 0 research. Re-checked after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Library-First Design | ✅ PASS | No new required API; new optional `identityKey` param is additive |
| II. Backward Compatibility | ✅ PASS | All existing constructors, providers, and request types unchanged |
| III. Cubit Owns Pagination State | ✅ PASS | Guard lives in cubit; widget layer remains a passive renderer |
| IV. Stream Lifecycle Safety | ⚠️ NEEDS FIX | Double `streamProvider(request)` call in `_fetch` creates two stream instances; fix is in scope |
| V. Stream Accumulation Rule | ⚠️ NEEDS FIX | `_attachStream` must guard against duplicate page registration during fast scroll |
| VI. Correctness Before Convenience | ✅ PASS | All changes prioritise correctness; no silent data loss |
| VII. Explicit Duplicate Handling | ✅ PASS | New `identityKey` is opt-in and documented; deduplication is not silent when configured |

**Gate decision**: No violations that block Phase 0. Two FIX items are core deliverables of this feature (not exceptions).

---

## Project Structure

### Documentation (this feature)

```text
specs/003-load-more-guard/
├── plan.md              ← this file
├── research.md          ← Phase 0 output
├── data-model.md        ← Phase 1 output
├── quickstart.md        ← Phase 1 output
├── contracts/           ← Phase 1 output
│   ├── future-provider.md
│   ├── stream-provider.md
│   └── merged-stream-provider.md
└── tasks.md             ← Phase 2 output (/speckit-tasks)
```

### Source Code (repository root)

```text
lib/
├── pagination.dart                         # main barrel export
├── smart_pagination/
│   ├── bloc/
│   │   ├── pagination_cubit.dart           # PRIMARY CHANGE FILE
│   │   └── pagination_state.dart           # minor additions (_LoadMoreKey)
│   └── widgets/
│       └── paginate_api_view.dart          # secondary: _shouldLoadMore guard
├── core/
│   └── core.dart                           # PaginationProvider types (no change)
test/
├── load_more_guard_test.dart               # new: cubit-level guard tests
├── scroll_trigger_test.dart                # new: widget-level trigger tests
├── deduplication_test.dart                 # new: identity-key tests
├── end_of_list_test.dart                   # new: end-of-list detection tests
└── stream_guard_test.dart                  # new: stream registration guard tests
```

---

## Complexity Tracking

No Constitution violations requiring justification.

---

## Section 1 — Executive Summary

### The Bug

When a user scrolls quickly and repeatedly near the bottom of a paginated list, the
widget layer calls `fetchPaginatedList()` multiple times before the cubit's internal
state change (`isLoadingMore: true`) propagates back to the widget tree. The root
cause is architectural: scroll threshold detection fires *inside the item builder*
(`paginate_api_view.dart:444`), which means every item rendered near the end of
the list during a single build pass independently evaluates the load-more condition
against a stale build-time snapshot of `loadedState.isLoadingMore`.

The cubit's own `_isFetching` boolean flag provides the primary guard and correctly
blocks truly concurrent calls. However, several secondary gaps exist:

1. The widget-layer guard reads `widget.loadedState.isLoadingMore` (build-time
   snapshot) not the live cubit state, creating a one-frame lag.
2. No per-page request key tracks "which exact page is in flight", so if `_isFetching`
   is cleared by a `cancelOngoingRequest()` call mid-flight, the page can be re-fetched.
3. Stream providers call `streamProvider(request)` twice in `_fetch` — once for
   `.first` (initial snapshot) and once for `_attachStream` — creating two independent
   stream instances from the same factory.
4. End-of-list detection relies solely on item-count heuristics; cursor-based
   signals (null next-cursor, explicit `hasMore: false`) are not inspected.
5. No item-level deduplication across pages is available.

### Impact

- API/provider called multiple times for the same page number
- Duplicate items appended to the list
- Stream subscriptions potentially doubled for the same page
- List may never reach `hasReachedEnd` if the exact-page-size edge case hits a
  provider that always returns full pages
- `isLoadingMore` spinner appears and disappears repeatedly without user action

### Proposed Fix

A layered cubit-level guard:

1. **Per-request key guard** — track the page/cursor key of the active load-more
   request; reject any call targeting the same key while it is in flight.
2. **Strengthened `_isFetching`** — set it before `emit()`, not inside `_fetch()`,
   so there is zero window between the check and the set.
3. **Stream factory single-call** — capture the stream once for both `.first` and
   `_attachStream`; no duplicate factory calls.
4. **Cursor-aware end-of-list** — inspect `PaginationMeta.hasNext` or null cursor
   alongside item-count heuristics.
5. **Optional identity-key deduplication** — consumer-provided key extractor removes
   cross-page duplicates before append.

---

## Section 2 — Current Load-More Flow Review

### Scroll Threshold Detection

**File**: `lib/smart_pagination/widgets/paginate_api_view.dart`
**Method**: `_shouldLoadMore(int currentIndex)` (line 391–398)

```dart
bool _shouldLoadMore(int currentIndex) {
  if (widget.loadedState.hasReachedEnd || widget.loadedState.isLoadingMore) {
    return false;
  }
  return currentIndex >= _items.length - widget.invisibleItemsThreshold;
}
```

This method is called from **inside the item builder** for every item rendered near
the end of the list (e.g., lines 443–444 in `_buildGridView`):

```dart
if (_shouldLoadMore(index)) {
  widget.fetchPaginatedList?.call();
}
```

**Problem**: Both `hasReachedEnd` and `isLoadingMore` are read from
`widget.loadedState`, which is the state snapshot captured at the start of the
current build. Multiple items within the same build pass evaluate the same snapshot
and independently call `fetchPaginatedList()`.

### `fetchPaginatedList()` Entry Point

**File**: `lib/smart_pagination/bloc/pagination_cubit.dart` (line 666)

Guards applied in order:
1. `if (_isFetching) return;` — checks the internal boolean (line 668)
2. `if (_lastFetchWasError) { ... }` — error-retry strategy gate (line 676)
3. `if (checkAndResetIfExpired()) { ... }` — data age check (line 703)
4. `if (state is SmartPaginationInitial) { refreshPaginatedList(); return; }` (line 707)
5. `if (_hasReachedEnd) return;` — end-of-list guard (line 712)
6. `if (currentState.isLoadingMore) return;` — state-level guard (line 717)
7. `emit(isLoadingMore: true)` (line 720)
8. Call `_fetch()` (line 731)

**Gap**: `_isFetching` is set to `true` **inside** `_fetch()` at line 740, not before
calling it. The synchronous code between line 666 and line 735 (the `_fetch` call)
has `_isFetching = false`. In Dart's single-threaded model, no other event-loop task
can slip in here — but the widget-layer items in the same build pass call this
method repeatedly before `_fetch()` runs, relying on guard #6 (`isLoadingMore`) to
stop them. Guard #6 reads cubit `state`, which IS already updated by the `emit` on
line 720 before items 2..N check — so this is safe in the cubit. The widget-layer
reads `widget.loadedState`, which is NOT updated until the next build.

### `_fetch()` Implementation

**File**: `pagination_cubit.dart:735`

```
async _fetch():
  _isFetching = true        ← set synchronously (before first await)
  token = ++_fetchToken     ← stale-response guard
  
  await provider(request)   ← yields here; other tasks can run
  
  if (token != _fetchToken) return   ← stale check
  if (isClosed) return
  
  emit(SmartPaginationLoaded(..., isLoadingMore: false))
  
  // Stream registration (stream providers only)
  _attachStream(streamProvider(request), request)  ← SECOND factory call
  
finally:
  _isFetching = false
```

**Gap**: `streamProvider(request)` is called twice — once for `.first` (line ~758)
and once for `_attachStream` (line ~861). Both calls hit the consumer's factory
function, potentially creating two independent stream subscriptions to the data
source.

### `_isFetching` Usage

| Location | Action |
|----------|--------|
| `pagination_cubit.dart:179` | Declaration (`bool _isFetching = false`) |
| `pagination_cubit.dart:668` | Guard check in `fetchPaginatedList()` |
| `pagination_cubit.dart:740` | Set `true` in `_fetch()` |
| `pagination_cubit.dart:932` | Set `false` in `finally` of `_fetch()` |
| `pagination_cubit.dart:1186` | Set `false` in `cancelOngoingRequest()` |

**Gap**: `cancelOngoingRequest()` sets `_isFetching = false` without checking whether
a new fetch should be started. If called externally while `_fetch()` is awaiting,
it creates a window where a second `fetchPaginatedList()` call can pass guard #1.

### `isLoadingMore` Emission

Emitted as `true` before `_fetch()` is called (line 720). Cleared to `false` in:
- Successful completion (line 842)
- Error path, load-more (line 892)
- `_emitMergedLoaded` (line 1104)

### `_currentRequest` Advancement

`_buildRequest(reset: false)` increments `request.page` by 1 from `_currentRequest`
(line 943: `nextPage = base.page + 1`). `_currentRequest` is updated to `request`
only on successful fetch completion (line 776).

**Gap**: If two `_fetch()` calls somehow start for the same page, both compute
`page = _currentRequest.page + 1` since `_currentRequest` hasn't been advanced yet.
Both requests target the same page number.

### `hasReachedEnd` Calculation

**Primary path** (`_fetch` → `_computeHasNext`):
```dart
bool _computeHasNext(List<T> items, int? pageSize) {
  if (pageSize == null) return items.isNotEmpty;
  return items.length >= pageSize;
}
```
Sets `_currentMeta.hasNext = hasNext`. `_hasReachedEnd` returns
`_currentMeta != null && !_currentMeta!.hasNext`.

**Gap**: No cursor inspection, no explicit `hasMore` flag from response.
When the last page has exactly `pageSize` items, `hasNext = true` → one extra
unnecessary fetch.

**Stream path** (`_emitMergedLoaded`):
```dart
final endOfPagination = pageSize != null &&
    _pageStreams.values.any((e) => e.latestValue.length < pageSize);
```
Fires `hasReachedEnd: true` if ANY page's stream emits fewer items than `pageSize`.
This could false-trigger during initial stream warm-up when a page hasn't yet
emitted a full batch.

### `PaginationMeta.hasNext` Calculation

`PaginationMeta` is constructed in `_fetch` (line 807) and `_emitMergedLoaded`
(line 1089). Its `hasNext` field is computed from `_computeHasNext` only —
no server-side cursor or explicit boolean is plumbed through.

### Stale Request Tokens

`_fetchToken` (int, line 135) is incremented on every `_fetch()` call (line 741)
and by `cancelOngoingRequest()` (line 1186). After the `await`, the token is
compared (line 764): `if (token != _fetchToken) { _isFetching = false; return; }`.

This correctly discards stale future responses. **Stream emissions** are guarded by
the `_generation` counter in `_PageStreamEntry` (line ~1023).

### First-Page vs. Load-More Distinction

`_fetch(reset: true)` → initial load; `_fetch(reset: false)` → load-more.
`isLoadingMore` is only set to `true` on the load-more path (line 720). The initial
load emits `SmartPaginationLoading` (implicitly via `SmartPaginationInitial` state
being replaced by `SmartPaginationLoaded`).

---

## Section 3 — Root Cause Analysis

### Confirmed Causes

| ID | Root Cause | Location |
|----|-----------|----------|
| RC-1 | Widget-layer `_shouldLoadMore` reads stale `widget.loadedState.isLoadingMore` snapshot, not live cubit state. Multiple items in one build pass evaluate the same false value and each call `fetchPaginatedList()`. | `paginate_api_view.dart:392` |
| RC-2 | `_isFetching = true` is set inside `_fetch()` after cubit guards in `fetchPaginatedList()`, not before. Synchronously safe, but the gap exists conceptually and becomes real if `cancelOngoingRequest()` is called externally between checks. | `pagination_cubit.dart:740` |
| RC-3 | Stream factory `streamProvider(request)` is called twice per page load — once for `.first` and once for `_attachStream`. Creates two independent streams from the consumer's factory. | `pagination_cubit.dart:757–862` |
| RC-4 | `_computeHasNext` uses only item-count heuristics. Last full page returns `hasNext=true` → one extra fetch. Cursor-null and explicit `hasMore: false` signals are never inspected. | `pagination_cubit.dart:950` |
| RC-5 | No per-page request key tracks in-flight page number. If `_isFetching` is cleared externally, a duplicate request for the same page can start, both computing `page = _currentRequest.page + 1`. | `pagination_cubit.dart:179,1186` |
| RC-6 | Empty load-more response is appended as an empty page (line 791: `_pages.add(pageItems)`) before `_computeHasNext` returns false. This causes one empty-page append. | `pagination_cubit.dart:791` |
| RC-7 | Stream `_emitMergedLoaded` detects end-of-list via `any(page.length < pageSize)`. During stream warm-up, a page might not yet have emitted its full batch, triggering a premature end. | `pagination_cubit.dart:1081` |

### Potential (Unconfirmed) Causes

| ID | Potential Cause | Verdict |
|----|----------------|---------|
| PC-1 | Race between scroll notifications and cubit emission | Low risk — Dart is single-threaded; the `_isFetching` flag is set synchronously |
| PC-2 | `isLoadingMore` updated after multiple calls entered | Addressed by RC-1; within a cubit call the guard holds |
| PC-3 | Stale response modifies current state | Already guarded by `_fetchToken` (future) and `_generation` (stream) |
| PC-4 | `_pageStreams` duplicate registration for same page | `_attachStream` cancels existing entry before re-registering; safe today, but fix RC-3 to prevent double factory call |

---

## Section 4 — Load-More Guard Design

The guard operates at three levels: **per-request key**, **in-flight flag**, and
**end-of-list marker**.

### 4.1 Per-Request Key

Add `_activeLoadMoreKey` (nullable `String`) to `SmartPaginationCubit`:

```
_activeLoadMoreKey: String? — composite key "page:pageSize" or "cursor:X"
```

Before any load-more `_fetch()`:
- Compute `loadMoreKey = _buildLoadMoreKey(request)`
- If `_activeLoadMoreKey == loadMoreKey` → return (duplicate request for same page)
- Set `_activeLoadMoreKey = loadMoreKey`

On completion or error:
- Clear `_activeLoadMoreKey = null`

On session reset (refresh, filter, search):
- Clear `_activeLoadMoreKey = null`

This provides a second layer of duplicate prevention independent of `_isFetching`.

### 4.2 Strengthened In-Flight Flag

Move `_isFetching = true` from inside `_fetch()` to **before** calling `_fetch()`,
immediately after the `isLoadingMore` guard in `fetchPaginatedList()`:

```dart
// In fetchPaginatedList():
if (currentState.isLoadingMore) return;
_isFetching = true;           // ← moved here
_activeLoadMoreKey = key;     // ← set here too
emit(currentState.copyWith(isLoadingMore: true));
_fetch(request: request, reset: false);
```

This closes the gap between the guard check and the flag set.

### 4.3 Active Request Keys Set (Optional Hardening)

If per-request key is insufficient (e.g., cursor-based pagination where two
different cursors produce the same page number), maintain a `Set<String>`:

```
_activeRequestKeys: Set<String>
```

- Add key when request starts
- Remove key on completion, error, or session reset

For load-more, this provides a finite set of in-flight keys, preventing any key
from being fetched twice concurrently.

### 4.4 Blocking Provider Calls

In `fetchPaginatedList()` order of guards (revised):

```
1. if (_isFetching) return;
2. error-retry strategy check
3. data-age check
4. if (state is Initial) → refresh; return
5. if (_hasReachedEnd) return;
6. compute loadMoreKey
7. if (_activeLoadMoreKey == loadMoreKey) return;   ← NEW
8. if (currentState.isLoadingMore) return;
9. _isFetching = true;                              ← MOVED
10. _activeLoadMoreKey = loadMoreKey;               ← NEW
11. emit(isLoadingMore: true)
12. _fetch(request, reset: false)
```

### 4.5 Ignoring Stale Responses from Old Generations

Already implemented via `_fetchToken` (futures) and `_generation` (streams).
No change needed here — but the generation counter check must be verified in the
load-more path as well as the initial load path.

### 4.6 Stream Registration Guard

In `_attachStream`, add a check before registering a new subscription:

```dart
void _attachStream(Stream<List<T>> stream, R request) {
  final page = request.page;
  // If this exact page is already registered with the current generation, skip.
  if (_pageStreams.containsKey(page) &&
      _pageStreams[page]!.generation == _generation) {
    return;  // ← guard against double registration
  }
  _pageStreams.remove(page)?.subscription.cancel();
  // ... rest of existing logic
}
```

This prevents the fast-scroll-triggered scenario where `_attachStream` is called
twice for the same page number in the same session generation.

---

## Section 5 — Scroll Trigger Protection

**Decision**: State guard only (confirmed by Clarifications Q1 — no debounce/throttle).

### 5.1 Widget-Layer Guard (Secondary)

`_shouldLoadMore` in `paginate_api_view.dart` already checks
`widget.loadedState.isLoadingMore`. This guard lags by one build cycle.

**Fix**: Additionally check the cubit's live `_isFetching` state by passing a
synchronous predicate, OR restructure so the fetch call is scheduled with
`SchedulerBinding.addPostFrameCallback` rather than being called inline inside the
item builder.

Preferred approach — **post-frame callback**:

```dart
if (_shouldLoadMore(index)) {
  SchedulerBinding.instance.addPostFrameCallback((_) {
    widget.fetchPaginatedList?.call();
  });
}
```

This ensures only one post-frame callback fires per build cycle (subsequent
duplicate callbacks are harmless since `_isFetching` is now `true`).

### 5.2 Cubit-Layer Guard (Primary)

The primary fix is Section 4 — the per-request key and moved `_isFetching` flag.
Even if the widget calls `fetchPaginatedList()` multiple times in a build cycle, the
cubit rejects all but the first.

### 5.3 Hysteresis (Not Required)

The spec and clarifications explicitly selected state-guard-only. Threshold
hysteresis (preventing re-trigger at the same viewport position) is NOT
implemented. The cubit guard is sufficient.

---

## Section 6 — End-of-List Stop Logic

### 6.1 Page-Size Pagination (Offset/Page-Number)

| Condition | Action |
|-----------|--------|
| `returnedItems.length < pageSize` | Set `hasNext = false` → `hasReachedEnd = true` |
| `returnedItems.isEmpty` on load-more | Set `hasNext = false` → `hasReachedEnd = true`; do NOT append the empty page |
| `returnedItems.length == pageSize` | Set `hasNext = true` → allow next fetch (one extra fetch may happen on the true last page) |

**Fix for empty-page append (RC-6)**:

```dart
if (!reset && pageItems.isEmpty) {
  // Empty load-more page → end of list; do not append
  final meta = PaginationMeta(page: request.page, pageSize: request.pageSize,
      hasNext: false, hasPrevious: request.page > 1);
  _currentMeta = meta;
  emit(currentState.copyWith(hasReachedEnd: true, isLoadingMore: false));
  return;
}
```

### 6.2 Explicit Server Metadata

`PaginationMeta.hasNext` currently is computed by the library, not by the server.
To support explicit server signals, providers can return a `PaginationResponse<T>`
wrapper (see contracts section). When `hasNext == false` in the server response,
set `_currentMeta.hasNext = false` directly.

### 6.3 Cursor-Based Pagination

End-of-list is detected when EITHER:
- Response carries no next-cursor (null/empty) — cubit checks `response.nextCursor == null`
- Server returns explicit `hasMore: false` field

`_computeHasNext` is extended to accept an optional `bool? serverHasNext` override:

```dart
bool _computeHasNext(List<T> items, int? pageSize, {bool? serverHasNext}) {
  if (serverHasNext != null) return serverHasNext;
  if (pageSize == null) return items.isNotEmpty;
  return items.length >= pageSize;
}
```

This preserves backward compatibility (old providers pass nothing; new cursor-aware
providers pass the server's signal).

### 6.4 Error Does Not Mean End

Already correct in the current implementation: error path emits `loadMoreError`
without setting `hasReachedEnd = true`. No change needed. Confirmed by FR-006.

### 6.5 Stale Empty Response Does Not Mean End

The generation counter already discards stale responses before they can modify
state. A stale empty response never reaches the `hasReachedEnd` logic.

### 6.6 Reset Clears End State

`refreshPaginatedList()` and `_resetToInitial()` both set `_currentMeta = null`,
which makes `_hasReachedEnd` return `false` (since `_currentMeta == null`). Correct.

### 6.7 Stream End-of-List Fix (RC-7)

Replace the `any(page.length < pageSize)` heuristic in `_emitMergedLoaded` with
a more precise check: only pages that have completed their initial emission (i.e.,
not still warming up) contribute to end-of-list detection.

Add `bool isComplete` flag to `_PageStreamEntry` to mark pages that have confirmed
their data shape. Alternatively: use the `_fetchToken` snapshot at registration time
and only apply the short-page check once the page's `.first` has resolved.

---

## Section 7 — Future Provider Behavior

`FuturePaginationProvider` guard plan:

| Scenario | Current | Fix |
|----------|---------|-----|
| Duplicate active future for same page | Blocked by `_isFetching` | Strengthen with `_activeLoadMoreKey` (Section 4) |
| Same page fetched twice concurrently | Blocked by `_isFetching` | No change needed beyond Section 4 |
| Stale future response | `_fetchToken` check | Verified — no change needed |
| Provider called after end state | `_hasReachedEnd` guard | No change needed |
| Load-more error preserves retry | `_lastFetchWasError` + `errorRetryStrategy` | No change needed; error does NOT set `hasReachedEnd` |
| Retry uses same request key | Retry re-enters `fetchPaginatedList()` — `_buildRequest` computes next page; not same key | Correct |

The only change in the future provider path: move `_isFetching = true` before the
`emit(isLoadingMore: true)` call (Section 4.2).

---

## Section 8 — Stream Provider Behavior

`StreamPaginationProvider` guard plan:

### 8.1 Eliminate Double Factory Call (RC-3)

In `_fetch`, capture the stream once:

```dart
// BEFORE (two factory calls):
final pageItems = await provider.streamProvider(request).first;
// ...
_attachStream(provider.streamProvider(request), request);  // second call

// AFTER (one factory call):
final stream = provider.streamProvider(request);
final pageItems = await stream.first;
// ...
_attachStream(stream, request);  // reuse same instance
```

**Note**: `stream.first` subscribes, waits for the first event, then cancels.
The same stream instance is then passed to `_attachStream` for the persistent
subscription. For cold streams this means one subscription (the `.first` one)
completes before the new persistent subscription starts. For hot/broadcast streams,
the behavior is the same as today but with a single factory call.

### 8.2 Prevent Duplicate Page Stream Registration

Apply the `_attachStream` guard from Section 4.6. If a page's stream is already
registered in the current generation, skip re-registration.

### 8.3 End-of-List in Stream Path

Apply the corrected stream end-of-list logic from Section 6.7.

### 8.4 Active Streams Remain Until Reset

No change needed — `_cancelAllPageStreams()` is called on all reset paths.

### 8.5 Stale Scope Emissions

Already guarded by `entry.generation == _generation` check in `_attachStream`'s
`onData` handler (line 1023). Confirmed correct.

---

## Section 9 — Merged Stream Provider Behavior

`MergedStreamPaginationProvider` guard plan (mirrors Section 8):

| Requirement | Current | Fix |
|-------------|---------|-----|
| Prevent repeated registration from fast scroll | `_isFetching` | Add `_attachStream` duplicate guard (§4.6) |
| Respect end-of-list state | `_hasReachedEnd` in `fetchPaginatedList()` | No change |
| Cancel on reset/dispose | `_cancelAllPageStreams()` | No change |
| Avoid duplicate subscriptions for identical stream keys | None | `_attachStream` generation guard (§4.6) |
| Eliminate double factory call | Two calls to `getMergedStream(request)` | Capture once, same as §8.1 |

---

## Section 10 — State Model Updates

### New Internal Fields (not exposed in public API)

| Field | Type | Purpose |
|-------|------|---------|
| `_activeLoadMoreKey` | `String?` | Per-request key of the in-flight load-more; cleared on completion/error/reset |
| `_activeRequestKeys` | `Set<String>` | Set of all in-flight keys (future hardening; optional in v1) |

### Existing Fields (behaviour changes only)

| Field | Change |
|-------|--------|
| `_isFetching` | Set to `true` before `emit(isLoadingMore: true)`, not inside `_fetch()` |
| `_pageStreams` | Guard added in `_attachStream` to block duplicate page registration in same generation |
| `_currentMeta.hasNext` | Extended to accept server-side cursor/boolean signal via `_computeHasNext` |

### New Optional Constructor Parameter (public API addition)

```dart
SmartPaginationCubit({
  ...
  Object? Function(T item)? identityKey,   // ← NEW, optional
})
```

When `identityKey` is non-null, the library deduplicates items before appending
using this extractor. Existing callers that don't provide it receive identical
behaviour to today (no deduplication).

### No New Public State Fields

All new guard fields are private. `SmartPaginationLoaded` is not changed.
`PaginationMeta` gains no new public fields (server signal is an implementation
detail handled inside the cubit).

---

## Section 11 — Error Handling Plan

### First-Page Error

No change. `SmartPaginationError` is emitted. `_isFetching` and `_activeLoadMoreKey`
are cleared in `finally`.

### Load-More Error

No change to emission. `isLoadingMore: false` and `loadMoreError: error` are set.
`hasReachedEnd` remains `false`.

Additional: `_activeLoadMoreKey` is cleared in `finally` so a retry can proceed.

### Retry After Load-More Error

Retry re-enters `fetchPaginatedList()`. Since `_activeLoadMoreKey` was cleared,
the same page key is not blocked. Since `_lastFetchWasError = true`, the
`errorRetryStrategy` gates the retry:
- `none` (default): user must call `retryAfterError()` or refresh
- `automatic`: retry immediately on next `fetchPaginatedList()` call
- `manual`: retry only via explicit `retryAfterError()` call

The retry uses the same page key as the failed request (same `_currentRequest`
since it wasn't advanced on failure).

### Preventing Immediate Repeated Failure Loops

With `errorRetryStrategy.none` (default), fast scrolling after an error is
rejected by the `_lastFetchWasError` check. No loop is possible. With
`automatic`, repeated fast scrolling could loop on error. The `_isFetching`
flag prevents concurrent retries; between retries, the cubit is not in a loading
state, so the widget CAN trigger another call. This is acceptable for `automatic`
strategy — the consumer opted into it. If desired, a `_retryAttempts` counter
can be added as a future improvement.

---

## Section 12 — Tests Required

### Test File: `test/load_more_guard_test.dart`

| # | Test Description | Verifies |
|---|-----------------|----------|
| T01 | Calling `fetchPaginatedList()` 10 times synchronously triggers exactly one provider call | FR-001 |
| T02 | Second `fetchPaginatedList()` during in-flight request returns without provider call | FR-001 |
| T03 | Same page is not fetched twice concurrently | FR-002 |
| T04 | Load-more success clears `_isFetching` and `_activeLoadMoreKey` | FR-001 |
| T05 | Load-more error clears `_isFetching` and `_activeLoadMoreKey` but does not set `hasReachedEnd` | FR-006 |
| T06 | Retry after error is possible via `retryAfterError()` | FR-006 |
| T07 | Empty load-more response sets `hasReachedEnd = true` and does not append empty page | FR-005 |
| T08 | Short page (< pageSize) sets `hasReachedEnd = true` | FR-005 |
| T09 | After `hasReachedEnd = true`, additional `fetchPaginatedList()` calls do not reach provider | FR-004 |
| T10 | `refreshPaginatedList()` clears `hasReachedEnd`, `_isFetching`, and `_activeLoadMoreKey` | FR-007 |
| T11 | Filter/search change via `refreshPaginatedList()` resets all guards | FR-007 |
| T12 | Stale response (old `_fetchToken`) does not modify list or state | FR-003 |
| T13 | Stale empty response does not set `hasReachedEnd` | FR-003 |

### Test File: `test/stream_guard_test.dart`

| # | Test Description | Verifies |
|---|-----------------|----------|
| T14 | Stream provider does not call `streamProvider(request)` twice per page load | RC-3 fix |
| T15 | `_attachStream` does not register duplicate for same page in same generation | §4.6 |
| T16 | Accumulated stream provider stops registering new streams after confirmed end | FR-004 |
| T17 | Stale scope stream emission (old generation) does not update new-scope state | FR-003 |
| T18 | Stream subscription is cancelled on `refreshPaginatedList()` | Constitution §IV |
| T19 | Per-page stream error isolates only the failing page; siblings keep emitting | FR-006 (stream) |

### Test File: `test/deduplication_test.dart`

| # | Test Description | Verifies |
|---|-----------------|----------|
| T20 | With `identityKey` configured, items duplicated across pages appear once | FR-012 |
| T21 | Without `identityKey`, items are appended as-is regardless of duplicates | FR-012 |
| T22 | Deduplication runs before `listBuilder` and `onInsertionCallback` | §4 |

### Test File: `test/end_of_list_test.dart`

| # | Test Description | Verifies |
|---|-----------------|----------|
| T23 | Cursor-null response sets `hasReachedEnd = true` | FR-004 |
| T24 | Explicit `hasMore: false` in server response sets `hasReachedEnd = true` | FR-004 |
| T25 | Both cursor-null AND `hasMore: false` signals work independently | FR-004 |
| T26 | Error response does not set `hasReachedEnd` | FR-006 |

### Test File: `test/scroll_trigger_test.dart` (widget-level)

| # | Test Description | Verifies |
|---|-----------------|----------|
| T27 | Widget-level fast scroll simulation triggers exactly one load-more request | SC-001 |
| T28 | Widget-level scroll after `hasReachedEnd = true` does not call provider | SC-002 |
| T29 | Widget-level scroll after error allows retry on next scroll | SC-003 |

---

## Section 13 — Documentation Plan

### `README.md`

Add section: **Load-More Safety Behaviour**

- Explain the state-guard-only approach (no debounce/throttle)
- Document that only one load-more request is active per list instance at any time
- Document `identityKey` optional parameter with example
- Document `errorRetryStrategy` options with fast-scroll context

### `CHANGELOG.md`

Add entry under new patch/minor version:

```markdown
## [x.x.x] - 2026-05-05

### Fixed
- Load-more guard: rapid scrolling can no longer trigger duplicate concurrent
  page requests; `_isFetching` flag is now set before the state emit
- Stream providers: `streamProvider(request)` is now called once per page load,
  not twice
- `_attachStream` now guards against duplicate page registration in the same
  generation

### Added
- Optional `identityKey` parameter on `SmartPaginationCubit` for consumer-
  configured item deduplication across pages
- Cursor-based end-of-list detection: accepts null next-cursor or explicit
  `hasMore: false` server signal in addition to item-count heuristics
```

### Provider Behaviour Notes

Update inline documentation in `pagination_cubit.dart` for:
- `fetchPaginatedList()`: document guard order
- `_isFetching`: document when set, when cleared
- `_activeLoadMoreKey`: document purpose
- `_attachStream`: document the duplicate-registration guard

### End-of-List Documentation

Update `PaginationMeta` dartdoc to explain how `hasNext` is computed and how
cursor-based providers can influence it.

### Fast Scrolling Behaviour Notes

Add to README: "The library uses a state-based guard. Scroll events while a
load-more request is in progress are silently discarded at the cubit level.
No debounce or throttle timer is used."

### Retry Behaviour Notes

Add to README: "After a load-more error, the `errorRetryStrategy` parameter
controls retry behaviour. The default (`none`) requires an explicit
`retryAfterError()` call or a refresh."

---

## Section 14 — Implementation Phases

### Phase A — Failing Tests (Reproduce the Bug)

Write tests T01–T03, T07, T13, T14, T15, T27 against the current code.
All must **fail** before any fix is applied. These are the regression anchors.

### Phase B — Cubit Guard (Core Fix)

1. Move `_isFetching = true` before `emit(isLoadingMore: true)` in `fetchPaginatedList()`
2. Add `_activeLoadMoreKey` field and set/clear logic
3. Add the `_activeLoadMoreKey == loadMoreKey` guard in `fetchPaginatedList()`
4. Update `cancelOngoingRequest()` and `_resetToInitial()` to clear `_activeLoadMoreKey`
5. Run T01–T05 — all must pass

### Phase C — Stale Generation Tests

Write and run T12, T13, T17. Verify `_fetchToken` and `_generation` logic
correctly discards stale responses (expected to already pass; confirms no regression).

### Phase D — End-of-List Fixes

1. Fix empty-page append in load-more path (Section 6.1)
2. Extend `_computeHasNext` to accept `serverHasNext` (Section 6.3)
3. Fix stream `_emitMergedLoaded` end-of-list heuristic (Section 6.7)
4. Run T07–T09, T23–T26

### Phase E — Stream Registration Guard

1. Capture stream once in `_fetch` (fix RC-3)
2. Add duplicate-page guard in `_attachStream`
3. Run T14–T19

### Phase F — Item Deduplication

1. Add optional `identityKey` constructor parameter
2. Apply deduplication in `_fetch` before page append and in `_emitMergedLoaded`
3. Run T20–T22

### Phase G — Widget-Layer Guard

1. Wrap `widget.fetchPaginatedList?.call()` in `SchedulerBinding.addPostFrameCallback`
   in `paginate_api_view.dart`
2. Run T27–T29

### Phase H — Documentation and Changelog

1. Update `README.md` per Section 13
2. Update `CHANGELOG.md`
3. Update inline dartdoc comments

### Phase I — Analysis and Full Test Suite

```bash
flutter analyze
flutter test
```

All new tests must pass. Existing tests must not regress.

---

## Section 15 — Acceptance Criteria

The implementation is accepted only when ALL of the following are true:

1. Rapid repeated calls to `fetchPaginatedList()` (10+ per second, simulated in tests)
   produce exactly one provider call per page — verified by T01–T03.

2. The same page is never fetched by two concurrent requests — verified by T02, T03.

3. `_hasReachedEnd == true` permanently blocks further provider calls until a reset —
   verified by T09.

4. Empty load-more response sets `hasReachedEnd = true` without appending — T07.

5. Short page (< pageSize) sets `hasReachedEnd = true` — T08.

6. Load-more error does NOT set `hasReachedEnd = true` — T05.

7. Refresh resets all guards and allows fresh pagination — T10.

8. Filter/search reset clears all guards — T11.

9. Stale responses (old generation or old token) cannot append items or change state —
   T12, T13, T17.

10. All new tests (T01–T29) pass at 100%.

11. Existing test suite passes at 100% — no regressions.

12. `flutter analyze` reports no new issues.

The fix operates at the cubit/provider level. Widget-level throttling (Phase G) is
additive defense in depth, not the primary safeguard. Acceptance is met even if
Phase G is deferred, as long as the cubit-level guard (Phases B–F) satisfies
criteria 1–12.
