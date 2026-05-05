# Feature Specification: Load-More Guard

**Feature Branch**: `003-load-more-guard`
**Created**: 2026-05-05
**Status**: Draft
**Input**: User description: "Add a stability feature to prevent infinite duplicate page fetching during rapid repeated scrolling"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Single Active Request During Fast Scrolling (Priority: P1)

When a user scrolls quickly and repeatedly toward the end of a paginated list, the list should only ever send one request at a time for the next page. Additional scroll triggers that arrive while that request is still in progress must be quietly discarded — they must not start a second, third, or fourth concurrent request.

**Why this priority**: This is the core problem. Without this guard, fast scrolling causes multiple overlapping requests, duplicate items in the list, runaway API calls, and potential infinite loading loops. Fixing this delivers the primary value of this feature.

**Independent Test**: Can be fully tested by simulating rapid scroll-to-bottom gestures against a list that has multiple pages, observing that the data source is called exactly once per page and items appear exactly once.

**Acceptance Scenarios**:

1. **Given** a paginated list displaying page 1, **When** the user scrolls to the bottom rapidly and the load-more request for page 2 is still in progress, **Then** no additional load-more requests are made until page 2 finishes loading.
2. **Given** a load-more request for page 2 is in progress, **When** the scroll threshold is crossed ten more times in quick succession, **Then** only one request for page 2 is ever sent.
3. **Given** page 2 has finished loading and appended to the list, **When** the user scrolls to the new bottom, **Then** a single request for page 3 is sent.

---

### User Story 2 - Reliable End-of-List Detection (Priority: P2)

When the data source signals that there are no more pages available — either explicitly or because the last returned page had fewer items than expected — the list must permanently stop requesting more data for that session.

**Why this priority**: Without reliable end detection, the list continues sending requests after all data is exhausted, wasting resources and potentially flooding the data source.

**Independent Test**: Can be fully tested by presenting a list whose data source returns a short final page (or an explicit "no more data" signal), then simulating further scrolling to confirm no additional requests are made.

**Acceptance Scenarios**:

1. **Given** a list has loaded all available pages, **When** the user scrolls to the bottom, **Then** no further data requests are made and no loading indicator appears.
2. **Given** the data source returns a page with fewer items than the configured page size, **When** the user scrolls to the bottom, **Then** the list treats this as the final page and sends no further requests.
3. **Given** the list has reached its end, **When** the user scrolls up and back down repeatedly, **Then** no new requests are made.

---

### User Story 3 - Error Recovery Without False End-of-List (Priority: P3)

When a load-more request fails due to a temporary problem (such as a network interruption), the list must not mark itself as ended. The user must be able to try again by scrolling, and a subsequent successful request must work normally.

**Why this priority**: Treating errors as end-of-list silently locks the user out of more data without any explanation. This breaks the user experience and requires a full refresh to recover.

**Independent Test**: Can be fully tested by triggering a load-more request that fails, verifying end-of-list is not set, then triggering another scroll and confirming a new request is made and succeeds.

**Acceptance Scenarios**:

1. **Given** a load-more request fails, **When** the user scrolls to the bottom again, **Then** a new load-more request is attempted.
2. **Given** a load-more request fails, **Then** the list does not append items, does not mark itself as ended, and does not display duplicate loading indicators.
3. **Given** a load-more request fails and then the user scrolls again, **When** the retry request succeeds, **Then** the next page of items is appended correctly.

---

### User Story 4 - State Reset on Refresh, Search, or Filter Change (Priority: P4)

When the user explicitly refreshes the list, changes a search query, or applies a filter, all active load guards and end-of-list markers must be reset so the new request set can start cleanly from page one.

**Why this priority**: If the end-of-list guard or in-flight guard is not cleared on reset, subsequent searches or refreshes appear to work but silently stop loading after the first page, causing invisible data loss.

**Independent Test**: Can be fully tested by loading a list to its end, then changing the search query or refreshing, and confirming that page 1 of the new query loads and subsequent pages continue to load normally.

**Acceptance Scenarios**:

1. **Given** a list has reached its end, **When** the user pulls to refresh, **Then** the end-of-list state is cleared and the list reloads from the beginning.
2. **Given** a load-more request is in progress, **When** the user changes the search query, **Then** the in-progress request is treated as stale, its response is discarded, and the new query loads from page one.
3. **Given** a filter change is applied, **When** the list reloads, **Then** subsequent scrolling correctly loads additional pages of the filtered results.
4. **Given** a stale response arrives after a refresh or filter change, **Then** its data is not appended to the new list.

---

### Edge Cases

- What happens when the data source returns an empty page on the very first load? The list must display an empty state, not a loading indicator, and must not retry.
- What happens when the data source returns exactly the page-size number of items on the last page? End-of-list must be detected via the explicit signal from the data source, not just item count.
- What happens if the same scroll threshold is crossed during the brief window after a request completes but before the state updates? The guard must hold until the state is fully committed.
- What happens when two different list instances with different filters run concurrently? Each instance must maintain its own independent guard without interfering with the other.
- What happens when a stream-based provider emits a new page event while a guard is active? The event must be buffered or discarded according to the same state-guard rules; stream subscriptions from prior generations must be cancelled on session reset.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The list MUST allow only one active load-more request at a time per list instance; any additional scroll triggers while one is in progress MUST be silently discarded by checking the in-flight state flag — no debounce or throttle timing is used.
- **FR-002**: The list MUST NOT send a load-more request for a page or cursor position that is already being fetched.
- **FR-003**: Responses that arrive after the list has been refreshed, restarted, or had its query changed MUST be discarded without modifying list contents or state. Staleness MUST be determined by comparing the response's request generation number against the current session generation counter.
- **FR-004**: The list MUST permanently stop sending load-more requests when the data source signals that no further pages exist. For cursor-based pagination, end-of-list is detected when either (a) the response carries a null or absent next-cursor, or (b) the data source returns an explicit boolean end-of-data flag — whichever signal the data source provides is sufficient.
- **FR-005**: The list MUST permanently stop sending load-more requests when a returned page contains fewer items than the configured page size.
- **FR-006**: A failed load-more request MUST NOT mark the list as ended; the list MUST remain open to future load-more attempts.
- **FR-007**: A refresh, reload, search-query change, or filter change MUST reset the in-flight guard, the end-of-list marker, and any stale-response tracking before the new request begins.
- **FR-008**: The loading indicator MUST appear at most once in the list at any given time, regardless of how many scroll threshold crossings occur concurrently.
- **FR-009**: An empty initial load MUST result in an empty-state display with no loading indicator and no further requests.
- **FR-010**: Each list instance MUST maintain its own independent guard state so that multiple concurrent list instances do not interfere with each other.
- **FR-011**: Stream-based providers MUST apply the same in-flight guard and generation counter rules as future-based providers; stream subscriptions from prior request generations MUST be cancelled when a session reset occurs.
- **FR-012**: Before appending any page of items to the list, the library MUST remove items whose identity key matches an item already present in the list. The identity key MUST be configurable by the consumer; no default key is assumed. If no key is configured, deduplication is skipped.

### Key Entities

- **List Session**: A single lifecycle of a paginated list from initial load until the next refresh or query change. Holds the current guard state, end-of-list marker, and request generation counter.
- **Load Guard**: A boolean flag per list session that is set when a load-more request starts and cleared when it completes or is cancelled. Prevents concurrent requests.
- **End-of-List Marker**: A per-session flag set when the data source confirms no further pages exist. Cleared on session reset.
- **Request Generation**: An internal counter incremented on every session reset (refresh, search, filter change). Every response carries the generation number active when it was dispatched; responses whose generation does not match the current counter are identified as stale and discarded without modifying list state. This counter is internal and does not appear in the public API.
- **Page Size Threshold**: The configured number of items per page, used to infer end-of-list from short responses when an explicit signal is absent.
- **End-of-List Signal**: Either a null/absent next-cursor (cursor-based) or an explicit boolean end-of-data flag returned by the data source. Both are valid and either alone is sufficient to set the End-of-List Marker.
- **Item Identity Key**: A consumer-configured function or field selector that extracts a unique identifier from each item. Used by the library to detect and remove duplicate items before they are appended to the list. Optional — when not configured, deduplication is skipped entirely.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Fast repeated scrolling (simulated as 10+ threshold crossings per second) never produces more than one concurrent data request per list instance — validated by automated tests covering this scenario.
- **SC-002**: After the final page is reached, zero additional data requests are made for that list session regardless of continued scrolling — validated by automated tests.
- **SC-003**: After a load error, the user can successfully load more data by scrolling again — the list is not permanently stuck — validated by automated tests.
- **SC-004**: When a consumer-configured identity key is provided, items are never duplicated in the list regardless of API page overlap or concurrent requests — validated by automated tests that compare rendered item keys against expected unique sets. When no key is configured, item deduplication does not occur and the list appends exactly what the API returns.
- **SC-005**: After a refresh or query change, zero responses from the previous session appear in the new list — validated by automated tests that simulate stale-response arrival.
- **SC-006**: All automated tests covering fast-scroll, end-of-list, error-recovery, and state-reset scenarios pass at 100%.
- **SC-007**: The change introduces no regressions in existing pagination, search, or error-handling behavior — existing test suite continues to pass at 100%.

## Clarifications

### Session 2026-05-05

- Q: How should the library prevent a second load-more request from starting while the first is still in progress? → A: State guard only — check the in-flight flag before any fetch; no timing logic (debounce/throttle explicitly excluded).
- Q: Are existing state flags sufficient or does the state model need a generation counter? → A: Existing flags (`isLoadingMore`, `hasReachedEnd`) plus an internal per-session request generation counter incremented on every reset to identify and discard stale responses.
- Q: Should the load-more guard apply to stream-based data providers in this feature? → A: In scope, same guard rules — stream-based providers use the identical state guard and generation counter as future-based providers.
- Q: For cursor-based pagination, how should end-of-list be determined? → A: Both signals accepted — end-of-list is detected when either a null/absent next-cursor is received OR the data source returns an explicit boolean end-of-data flag; whichever the data source provides is sufficient.
- Q: Should item-level deduplication (same item appearing across consecutive pages) be in scope? → A: In scope — the library auto-deduplicates items before appending using a consumer-configurable identity key; items with a duplicate key are silently dropped.

## Assumptions

- The library's state management architecture and public API surface remain unchanged; this feature adds protective behavior within the existing design without altering how library consumers configure or invoke the library.
- Both page-number–based and cursor-based pagination patterns are treated equivalently by the guard. Stream-based providers are also in scope and apply the same state guard and generation counter rules as future-based providers.
- "Page size" is a value already available in the library's pagination configuration; no new configuration is required to determine when a short page signals end-of-list.
- The data source (consumer-provided function) is the authoritative source of truth for end-of-list signals; the library does not attempt to infer end-of-list from network timing or response latency.
- Concurrent list instances on the same screen (e.g., two separate paginated lists) are independent and do not share guard state.
- The library is used within a standard list-scrolling interaction model; non-scroll-based load triggers (e.g., button-triggered load) are subject to the same guard rules.
- Backward compatibility is a hard constraint: no existing public API changes, no breaking changes to existing consumer code.
- The item identity key is an optional configuration; existing consumers who do not provide one experience no change in behavior (items appended as-is).
