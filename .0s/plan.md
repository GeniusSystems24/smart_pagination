/speckit.plan

Create a technical implementation plan for a new stability feature in `smart_pagination`: prevent infinite duplicate page fetching during rapid repeated scrolling.

## Technical Context

The package is a Flutter/Dart pagination library that uses `SmartPaginationCubit`, provider-based data sources, and UI widgets such as ListView, GridView, PageView, StaggeredGridView, and other pagination views.

The bug appears when scroll notifications repeatedly trigger load-more near the end of the list. Because fast scrolling can fire multiple threshold events, the cubit/provider pipeline may start repeated next-page requests without waiting for the active request to finish or without respecting the final end state.

## Required Plan Sections

### 1. Executive Summary

Explain the bug, its impact, and the proposed high-level fix.

### 2. Current Load-More Flow Review

Inspect and document:

- Where scroll threshold detection happens.
- Where `fetchPaginatedList()` or load-more is triggered.
- How `isFetching` is used.
- How `isLoadingMore` is emitted.
- How `_currentRequest` is advanced.
- How `hasReachedEnd` is calculated.
- How `PaginationMeta.hasNext` is calculated.
- How stale request tokens are used.
- How first-page loading differs from load-more loading.

### 3. Root Cause Analysis

Identify possible causes:

- Scroll threshold fires repeatedly before state changes.
- `isFetching` is not checked early enough.
- `isLoadingMore` is updated after multiple calls already entered.
- Same page request is built multiple times.
- End-of-list state is not committed before new threshold events.
- Empty page is appended or ignored incorrectly.
- Stale response modifies current state.
- Race condition between scroll notifications and cubit state emission.
- Stream provider may register new page streams repeatedly.

### 4. Load-More Guard Design

Design a robust guard that prevents duplicate fetching.

The plan must cover:

- A per-scope `isLoadMoreInFlight` guard.
- A request generation token.
- A unique request/page/cursor key.
- A set of active request keys.
- A set of completed/end request keys if needed.
- Blocking provider calls when `hasReachedEnd == true`.
- Blocking provider calls when the same request key is already active.
- Ignoring stale responses from old generations.

### 5. Scroll Trigger Protection

Define how UI scroll events should be handled.

Evaluate:

- State-based guard only.
- Throttle scroll-triggered load-more calls.
- Debounce scroll-triggered load-more calls.
- Post-frame scheduling to avoid repeated same-frame triggers.
- Threshold hysteresis so the same viewport position does not repeatedly trigger load more.

Important:
The main fix should be in the cubit/request guard, not only in the widget layer. Widget throttling may be added as a secondary protection.

### 6. End-of-List Stop Logic

Define exactly when loading must stop.

Cover:

- `returnedItems.length < pageSize` means end for offset/page-size pagination.
- `returnedItems.isEmpty` on load-more means end and must not append an empty page.
- `hasNext == false` means end when server metadata exists.
- `nextCursor == null` means end for cursor pagination.
- Error does not mean end.
- Stale empty response does not mean end.
- Refresh/reload/search/filter resets end state.

### 7. Future Provider Behavior

Plan behavior for `PaginationProvider.future(...)`:

- Prevent duplicate active future requests.
- Do not fetch same page twice concurrently.
- Ignore stale future responses.
- Do not call provider after end state.
- Preserve load-more error state without marking end.

### 8. Stream Provider Behavior

Plan behavior for `PaginationProvider.stream(...)`:

- Do not register duplicate page streams for the same request key.
- If stream accumulation is enabled, page 1 stream remains active and page 2 stream is added only once.
- Once end is reached, do not register more page streams.
- Existing active streams remain active until reset, eviction, completion policy, or dispose.
- Stale scope stream emissions are ignored.

### 9. Merged Stream Provider Behavior

Plan behavior for `PaginationProvider.mergeStreams(...)`:

- Prevent repeated registration from fast scroll events.
- Respect end-of-list state.
- Cancel and cleanup on reset/dispose.
- Avoid duplicate subscriptions for identical stream keys.

### 10. State Model Updates

Determine whether new internal state is needed:

- `activeLoadMoreRequestKey`
- `activeRequestKeys`
- `lastCompletedRequestKey`
- `requestGeneration`
- `paginationScopeId`
- `hasReachedEnd`
- `lastLoadMoreTriggeredAt`
- `isLoadMoreInFlight`

Do not expose internal fields publicly unless necessary.

### 11. Error Handling Plan

Define:

- First-page error behavior.
- Load-more error behavior.
- Retry after load-more error.
- Whether retry can use the same request key after failure.
- Whether failed request key should be removed from active keys.
- How to prevent immediate repeated failure loops during fast scrolling.

### 12. Tests Required

Add tests for:

- Fast repeated scroll calls trigger only one provider call.
- Multiple immediate `fetchPaginatedList()` calls trigger only one load-more request.
- Same page is not fetched twice while in flight.
- Load-more success clears the in-flight guard.
- Load-more error clears the in-flight guard but does not mark end.
- Retry after error is possible only through valid retry path.
- Empty load-more response marks end.
- Short load-more response marks end for page-size pagination.
- After end, additional scroll triggers do not call provider.
- Refresh resets end and in-flight guards.
- Reload resets end and in-flight guards.
- Filter/search reset clears old request keys.
- Stale response from old generation is ignored.
- Stale empty response does not mark current scope ended.
- Stream provider does not register duplicate page stream for same request.
- Accumulated stream provider stops registering new streams after confirmed end.
- Widget-level scroll simulation reproduces the original bug and verifies the fix.

### 13. Documentation Plan

Update:

- README.md with load-more safety behavior.
- CHANGELOG.md with bug fix / stability feature.
- Provider documentation.
- End-of-list documentation.
- Fast scrolling behavior notes.
- Retry behavior notes.

### 14. Implementation Phases

Break implementation into phases:

1. Add failing tests reproducing fast-scroll infinite fetching.
2. Add request key and in-flight guard tests.
3. Implement cubit-level load-more guard.
4. Add stale generation protection where missing.
5. Fix end-of-list state transitions.
6. Add stream registration guard.
7. Add widget-level throttle/hysteresis only if cubit guard is not enough.
8. Update docs and changelog.
9. Run analysis and tests.

### 15. Acceptance Criteria

The plan is accepted only if it prevents infinite fetching at the cubit/provider level, not only visually in the UI.

The final implementation must prove that rapid repeated scrolling cannot create duplicate page fetches, cannot bypass end-of-list state, and cannot leave the cubit stuck in loading state.

Do not implement code yet.
Produce the plan only.
