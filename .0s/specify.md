
/speckit.specify

Add a new stability feature to the existing Flutter/Dart package `smart_pagination` to prevent infinite duplicate page fetching during rapid repeated scrolling.

## Problem

When the user scrolls quickly and repeatedly near the end of a paginated list, the package may trigger `load more` many times before the previous request finishes or before pagination state is updated correctly.

This causes uncontrolled repeated fetching of next pages. The list may keep requesting pages indefinitely, even when the end should have been reached. It may also fetch the same page multiple times, append duplicate data, skip correct stop conditions, or keep network/API calls running without a valid need.

The issue is visible when fast scroll gestures repeatedly hit the invisible-items threshold near the bottom of the list. The pagination trigger fires again and again while the previous load-more operation is still pending or while the cubit has not yet committed the next-page state.

## Goal

Implement robust load-more guarding so the package never starts duplicate, overlapping, stale, or unnecessary page requests during fast scrolling.

The package must correctly stop fetching when it reaches the end of available data.

## Core Requirements

1. Only one load-more request may be active per pagination scope at a time.
2. Repeated scroll notifications while `isLoadingMore == true` must not start another fetch.
3. The same page/request/cursor must not be fetched multiple times concurrently.
4. The cubit must ignore stale load-more responses from old request generations.
5. `hasReachedEnd` must reliably prevent additional load-more calls.
6. Empty or short page responses must mark the list as ended when appropriate.
7. Errors must not mark the list as ended incorrectly.
8. Refresh, reload, search change, and filter change must reset the load-more guard and end state safely.
9. Fast scrolling must not create an infinite fetch loop.
10. The UI must remain responsive and must not repeatedly append loading indicators.

## Expected User Behavior

When the user scrolls fast near the end:

- The first valid load-more request starts.
- Additional scroll threshold events are ignored while that request is active.
- When the request succeeds, the next page is appended once.
- If the returned page indicates there is no more data, loading stops permanently for that scope.
- If there is more data, a future load-more may happen only after the current request completes and the user reaches the threshold again.

## Non-Goals

Do not:

- Rewrite the whole package.
- Replace the Cubit architecture.
- Remove `.withProvider(...)` or `.withCubit(...)`.
- Break existing public API usage.
- Hide duplicate items silently without explicit identity rules.
- Treat API errors as end-of-list.
- Disable pagination entirely.

## Acceptance Criteria

The feature is accepted only if:

1. Fast repeated scrolling cannot trigger multiple simultaneous load-more requests.
2. The same page is not fetched twice concurrently.
3. The provider is not called again after `hasReachedEnd == true`.
4. Empty load-more response stops further loading for the current scope.
5. Short page response stops further loading when using page-size based pagination.
6. Errors do not set `hasReachedEnd` to true.
7. Refresh/reload resets the guards correctly.
8. Search/filter changes reset the guards correctly.
9. Stale responses cannot append items or change end state.
10. Unit/widget tests reproduce the fast-scroll issue and prove it is fixed.
11. README and CHANGELOG document the behavior.
