# Research: Load-More Guard

**Date**: 2026-05-05 | **Feature**: `003-load-more-guard`

All findings are grounded in the actual source code at
`lib/smart_pagination/bloc/pagination_cubit.dart` and
`lib/smart_pagination/widgets/paginate_api_view.dart`.

---

## R1 — In-Flight Flag Placement

**Decision**: Move `_isFetching = true` from inside `_fetch()` to `fetchPaginatedList()`,
immediately before `emit(isLoadingMore: true)`.

**Rationale**: Dart is single-threaded; no other task can preempt between the check and
the set. However, moving the flag before the emit makes the guard order explicit and
removes any conceptual gap. It also prevents a scenario where `cancelOngoingRequest()`
clears `_isFetching` externally while the synchronous preamble of `fetchPaginatedList()`
is still running.

**Alternatives considered**: Debounce / throttle scroll triggers (rejected per
Clarifications Q1); lock object (unnecessary in single-threaded Dart).

---

## R2 — Per-Request Key

**Decision**: Add `String? _activeLoadMoreKey` as `"${request.page}:${request.pageSize}"`.
For cursor-based, key is the cursor value itself or `"cursor:${cursor}"`.

**Rationale**: The `_isFetching` boolean guards against concurrency but cannot distinguish
"same page, different session" from "same page, same session". The key guard adds a
second check that rejects any duplicate page request without relying on flag state alone.

**Alternatives considered**: `Set<String> _activeRequestKeys` — more complete but adds
overhead; deferred to optional hardening if the key guard proves insufficient.

---

## R3 — Double Stream Factory Call

**Decision**: Capture `streamProvider(request)` once in `_fetch`, pass the same instance
to both `.first` and `_attachStream`.

**Rationale**: The current code calls the consumer's factory twice, creating two
independent stream objects. For cold streams this is two separate subscriptions to the
data source — exactly the duplicate-fetch bug for stream providers. Capturing once
eliminates the duplicate.

**Alternatives considered**: Keep two calls but cancel the first subscription before
attaching the second (rejected — more complex, still double-calls the factory).

---

## R4 — Cursor End-of-List

**Decision**: Extend `_computeHasNext` with optional `bool? serverHasNext` parameter.
Accept null next-cursor OR explicit `hasMore: false` as end signal.

**Rationale**: Confirmed by Clarifications Q4 — both signals must be accepted. The
current `_computeHasNext` uses only item count. Adding `serverHasNext` as an override
keeps backward compatibility (callers that don't pass it get current behaviour).

**Alternatives considered**: New `PaginationResponse<T>` wrapper type (deferred to
tasks — larger API change, better suited as a separate enhancement).

---

## R5 — Stream Registration Guard

**Decision**: In `_attachStream`, skip re-registration if the page already has a live
entry in `_pageStreams` for the current generation.

**Rationale**: During fast scroll, `fetchPaginatedList()` may complete and call
`_attachStream` twice for the same page before the widget tree rebuilds. The generation
check ensures we only register once per session.

**Alternatives considered**: Key-based dedup at the `fetchPaginatedList()` call site
(covered by R2); the `_attachStream` guard is defence in depth.

---

## R6 — Empty Page on Load-More

**Decision**: In `_fetch`, when `!reset && pageItems.isEmpty`, set `hasReachedEnd = true`
without appending the empty page to `_pages`. Emit updated state and return.

**Rationale**: Currently an empty page is appended (line 791: `_pages.add(pageItems)`)
before `_computeHasNext` detects it as end. The append itself is harmless (empty
list) but causes an unnecessary `emit` and confuses list-builder callbacks.

**Alternatives considered**: Allow empty append (current behaviour) — rejected because
it triggers `listBuilder` with an empty delta and may cause spurious repaints.

---

## R7 — Identity-Key Deduplication

**Decision**: Add `Object? Function(T item)? identityKey` as optional constructor
parameter. When non-null, apply deduplication before every page append using a
`LinkedHashSet` keyed by `identityKey(item)`.

**Rationale**: Confirmed by Clarifications Q5. The consumer controls identity; the
library provides the mechanism. Using `LinkedHashSet` preserves insertion order while
eliminating duplicates in O(n) time.

**Alternatives considered**: Deduplicate in `listBuilder` (consumer responsibility,
not library-provided); `Map<key, item>` approach (less idiomatic than `LinkedHashSet`).

---

## R8 — Widget-Layer Post-Frame Guard

**Decision**: Wrap `widget.fetchPaginatedList?.call()` in
`SchedulerBinding.instance.addPostFrameCallback((_) { ... })` in `paginate_api_view.dart`.

**Rationale**: Calling `fetchPaginatedList()` inside the item builder during a build
is technically a side-effect inside build (not recommended by Flutter). Moving to a
post-frame callback ensures the call happens after the build completes. Multiple
post-frame callbacks from the same build are harmless — the cubit guard stops all but
the first.

**Alternatives considered**: Pass a `ValueNotifier<bool>` to deduplicate at widget level
(overcomplicated); use a `bool _pendingLoadMore` flag in `_PaginateApiViewState`
(simpler but adds widget state; post-frame callback is cleaner).
