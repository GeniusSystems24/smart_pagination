# Feature Specification: Stabilize PaginationProvider

**Feature Branch**: `002-stabilize-provider`
**Created**: 2026-05-05
**Status**: Draft
**Input**: User description: "Maintain and stabilize the `PaginationProvider` system in the existing Flutter/Dart package `smart_pagination`. Improve provider correctness, stream lifecycle safety, accumulated stream behavior, merged stream behavior, error handling, type safety, documentation, and test coverage without rewriting the package or breaking the public API unnecessarily."

## Clarifications

### Session 2026-05-05

- Q: When one page's underlying stream errors, what is the contract for sibling pages and the overall pagination state? → A: Isolate the failing page — cancel only its subscription, surface the error as a per-page annotation, keep sibling pages live and emitting.
- Q: When a page's underlying stream emits an empty list `[]` (or any list shorter than the page size), how should pagination state respond? → A: Honor the emission as the page's latest value (clear/shrink the slice). Treat any page whose latest value has `count < pageSize` as **end-of-pagination** for the current scope (no further `loadMore` allowed). If a later emission grows that page back to `count == pageSize` (page becomes full), re-enable `loadMore`. This rule is dynamic and re-evaluates on every emission.
- Q: Is page eviction (capping the number of simultaneously active page subscriptions) in scope for this iteration? → A: **Out of scope.** The cubit accumulates pages without an enforced limit until the scope resets. Eviction is deferred to a future iteration once the core accumulation behavior is stable.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Accumulated Realtime Stream Pagination (Priority: P1)

A developer building a chat, feed, or live-list screen wires `PaginationProvider.stream(...)` to a paginated cubit. As the user scrolls, page 1, page 2, and page 3 each register their own stream. Updates arriving on any of those streams continue to update their respective page slices, and the screen always reflects the union of every active page's latest emission in correct page order. No emission from a previous query (after a refresh, search change, or filter change) ever leaks into the current view.

**Why this priority**: This is the headline behavior requested by users of the library. Today, stream-based pagination either replaces the previous page's stream or leaks across scopes; without correct accumulation, the package cannot be used for realtime paginated lists at all. Every other improvement is supportive.

**Independent Test**: Build a stream-backed paginated list, load three pages, push synthetic emissions onto each underlying stream, assert that the merged state contains items from all three pages in page order; then trigger a refresh and assert that subsequent emissions on the original three streams are ignored.

**Acceptance Scenarios**:

1. **Given** an active stream pagination scope with page 1 loaded, **When** the consumer requests page 2, **Then** the page 1 stream remains subscribed and a page 2 stream is added.
2. **Given** an active stream pagination scope with pages 1, 2, and 3 loaded, **When** any page's underlying stream emits, **Then** only that page's slice updates and the merged paginated state reflects page 1 + page 2 + page 3 in that order.
3. **Given** an active stream pagination scope with multiple pages loaded, **When** the scope resets (refresh, reload, search change, filter change, or provider replacement), **Then** all previously accumulated stream subscriptions are cancelled before the new scope begins.
4. **Given** a cancelled scope, **When** an old stream emits after cancellation, **Then** the emission is discarded and the current state is unchanged.

---

### User Story 2 - Lifecycle-Safe Merged Streams (Priority: P1)

A developer combines several upstream sources (e.g., local cache + websocket + remote refresh) using `PaginationProvider.mergeStreams(...)`. Subscribing, unsubscribing, hot-reloading, and disposing the cubit never leaves dangling subscriptions or open controllers, regardless of whether the input list is empty, has one stream, or has many.

**Why this priority**: Memory leaks and orphaned subscriptions cause silent bugs in production apps and only surface under load. This must be correct on day one for the package to be production-grade.

**Independent Test**: Construct a merged-stream provider with 0, 1, and N child streams; instrument subscription and controller lifecycles; dispose the cubit and assert that every child subscription is cancelled and every internal controller is closed. Inject a child error and a child completion; assert the merged provider behaves as specified without leaking.

**Acceptance Scenarios**:

1. **Given** a merged-stream provider with zero input streams, **When** it is created and disposed, **Then** no subscriptions are opened and no controllers are left open.
2. **Given** a merged-stream provider with multiple input streams, **When** the cubit is disposed, **Then** every child subscription is cancelled and every internal controller is closed.
3. **Given** a merged-stream provider with multiple input streams, **When** one child stream errors, **Then** the merged provider surfaces the error per its documented contract without leaking the other subscriptions.
4. **Given** a merged-stream provider with multiple input streams, **When** one child stream completes, **Then** remaining streams continue and the merged provider reports completion only when all children are done.

---

### User Story 3 - Stable Future Pagination With Stale-Response Protection (Priority: P2)

A developer wires a normal REST/API list to `PaginationProvider.future(...)`. Rapid refreshes, filter changes, and concurrent load-more calls never let an older in-flight response overwrite the current state, errors on the first page and on load-more are reported distinctly, and disposing the cubit while a request is in flight does not throw or update disposed state.

**Why this priority**: Future-backed pagination is the most common use case; correctness here protects every consumer of the library, not just stream users. It is P2 because the existing implementation is closer to correct than the stream path.

**Independent Test**: Drive the future provider through a sequence of rapid refresh calls and a load-more, stub the underlying fetcher with controllable delays, and assert that only the latest scope's response is applied; assert distinct first-page-error vs load-more-error states; dispose mid-flight and assert no late callback mutates state.

**Acceptance Scenarios**:

1. **Given** a successful page fetch, **When** the response arrives, **Then** items are appended and pagination metadata reflects the new page.
2. **Given** an in-flight first-page request, **When** a refresh starts a new scope before the response arrives, **Then** the late response is discarded.
3. **Given** an in-flight load-more request, **When** the cubit is disposed, **Then** no state mutation occurs after the response arrives.
4. **Given** a load-more request that fails, **When** the error returns, **Then** previously loaded items remain visible and the error is surfaced as a load-more error (distinct from a first-page error).

---

### User Story 4 - Type-Safe Custom Request Subclasses (Priority: P2)

A developer extends `PaginationRequest` with a feature-specific subclass (extra filter fields, sort options, etc.). All provider variants pass that exact subclass through to the developer's fetch/stream callback without erasing or downcasting the type, so the callback can read its custom fields directly.

**Why this priority**: Without this, real applications resort to casts or duplicated types, which the rest of the codebase already avoids. It is P2 because today's behavior is mostly correct but incomplete around the new stream-accumulation paths.

**Independent Test**: Define a custom `PaginationRequest` subclass; wire it to each provider variant; assert that the subclass instance reaching the user callback is reference-identical to the one supplied by the cubit and that its custom fields are readable without a cast.

**Acceptance Scenarios**:

1. **Given** a custom `PaginationRequest` subclass `R`, **When** the provider invokes the user callback, **Then** the callback receives an `R` (not the base class).
2. **Given** custom fields on the subclass, **When** the provider hands the request to the callback across a stream-accumulation load-more, **Then** custom fields are preserved.

---

### User Story 5 - Documentation and Test Coverage Refresh (Priority: P3)

A developer reading the README and CHANGELOG can quickly understand which provider variant to pick, how scope reset works, how stream accumulation behaves, and which behavior changed in this release. Library maintainers can run a single test command and see all provider behavior covered.

**Why this priority**: Important for adoption and long-term maintenance, but not blocking on the runtime correctness work above.

**Independent Test**: Review the updated README for sections covering each provider variant, scope semantics, and accumulation rules; run the test suite and confirm every acceptance scenario above is exercised by at least one test.

**Acceptance Scenarios**:

1. **Given** the updated README, **When** a new developer reads it, **Then** they can identify which provider variant matches their use case and understand scope-reset rules without reading source.
2. **Given** the updated CHANGELOG, **When** an existing consumer upgrades, **Then** they can identify any behavior change relevant to their integration.
3. **Given** the test suite, **When** it is run, **Then** every acceptance scenario in this spec is covered by at least one passing test.

---

### Edge Cases

- An old stream emits **after** its scope has been cancelled (e.g., a slow source flushes a buffered event) — the emission must be discarded.
- The same scope receives a load-more before page 1's first emission has arrived — both pages remain registered and emissions are correctly attributed when they arrive.
- The underlying source completes a page's stream while other pages remain active — the merged paginated state continues to reflect the last value of the completed page; remaining pages keep updating.
- The underlying source errors a page's stream — only that page's subscription is cancelled, the error is surfaced as a per-page annotation through the cubit's error channel, and sibling page streams remain live and continue emitting.
- The cubit is disposed mid-load (future in flight, or stream awaiting first emission) — no state mutation occurs after disposal and no subscription remains.
- `mergeStreams` is constructed with zero input streams — it produces no emissions, completes per its documented contract, and leaks nothing.
- Two emissions arrive concurrently for two different pages — both are applied; final order is page 1 + page 2 + page 3 regardless of arrival order.
- Duplicate items appear across pages — duplicates are preserved (no silent dedup); the consumer is responsible for explicit dedup if desired.
- A page's stream emits `[]` — that page's slice is cleared, the merged state shrinks, and the scope flips to end-of-pagination (no further `loadMore`).
- A page's stream emits a list shorter than `pageSize` — same as above: end-of-pagination is set; sibling pages remain unaffected.
- After end-of-pagination is set, a later emission grows the same page back to `count == pageSize` — end-of-pagination clears and `loadMore` is allowed again within the same scope.

## Requirements *(mandatory)*

### Functional Requirements

**Future Provider**

- **FR-001**: The Future provider MUST deliver successful page results to the cubit with their items and pagination metadata intact.
- **FR-002**: The Future provider MUST distinguish first-page errors from load-more errors when reporting failures, so the cubit can render them differently.
- **FR-003**: The Future provider MUST discard responses from a request whose scope is no longer current (stale-response protection).
- **FR-004**: The Future provider MUST cooperate with the cubit's request token / generation mechanism to support cancellation semantics.
- **FR-005**: The Future provider MUST not mutate any state after the owning cubit has been disposed.
- **FR-006**: Retry behavior MUST remain owned by the cubit; the Future provider MUST NOT implement its own retry policy.

**Stream Provider**

- **FR-010**: The Stream provider MUST register a new stream subscription for each page load within a scope without cancelling earlier pages' subscriptions.
- **FR-011**: The Stream provider MUST attribute each emission to the page that produced it and update only that page's slice.
- **FR-012**: The Stream provider MUST aggregate the latest value from every active page stream into a single ordered list (page 1 + page 2 + ... + page N).
- **FR-013**: The Stream provider MUST cancel all accumulated stream subscriptions when the scope resets (refresh, reload, search change, filter change, provider instance change, or request scope identity change).
- **FR-014**: The Stream provider MUST cancel all accumulated stream subscriptions when the cubit is disposed.
- **FR-016**: The Stream provider MUST discard emissions arriving from a stream whose scope has been cancelled.
- **FR-017**: The Stream provider MUST surface stream errors through the cubit's error channel and MUST NOT swallow them. On a per-page stream error the provider MUST cancel only that page's subscription, attach the error as a per-page annotation, and leave every sibling page subscription live and emitting.
- **FR-018**: The Stream provider MUST handle stream completion without cancelling sibling page streams; the merged state retains the last value of the completed page.
- **FR-019a**: The Stream provider MUST treat each emission as the **authoritative latest value** of the emitting page's slice; an emission of `[]` MUST clear that slice rather than be ignored.
- **FR-019b**: The Stream provider MUST flag the current scope as **end-of-pagination** whenever the latest value of any active page has `count < pageSize`. While this flag is set, the cubit MUST reject `loadMore` calls (no new page subscription is registered).
- **FR-019c**: The end-of-pagination flag MUST be re-evaluated on every emission. If a later emission grows the offending page's slice so that all active pages now satisfy `count == pageSize` (i.e., every page is full), the flag MUST clear and `loadMore` MUST be re-enabled in the same scope.

**Merged Stream Provider**

- **FR-020**: The Merged Stream provider MUST support zero, one, and many input streams.
- **FR-021**: The Merged Stream provider MUST cancel every child subscription and close every internal controller on disposal, with no exceptions for empty or single-stream cases.
- **FR-022**: The Merged Stream provider MUST surface child stream errors per its documented contract.
- **FR-023**: The Merged Stream provider MUST report completion only when every child stream has completed.

**Cross-cutting**

- **FR-030**: All provider variants MUST preserve the developer-supplied `PaginationRequest` subclass type when invoking user callbacks (no erasure to the base class).
- **FR-031**: All provider variants MUST NOT silently deduplicate items; duplicate handling remains the consumer's responsibility.
- **FR-032**: The public API surface (`PaginationProvider.future`, `PaginationProvider.stream`, `PaginationProvider.mergeStreams`, `.withProvider(...)`, `.withCubit(...)`, `SmartPaginationCubit`) MUST remain backward compatible; any breaking change MUST be explicitly justified.
- **FR-033**: The README MUST document each provider variant, scope-reset rules, and stream accumulation semantics.
- **FR-034**: The CHANGELOG MUST record every behavior change introduced by this work.
- **FR-035**: The test suite MUST cover every acceptance scenario listed in this specification.

### Key Entities *(include if feature involves data)*

- **PaginationProvider**: Strategy abstraction representing how a paginated source produces pages — Future, Stream, or Merged Stream variants.
- **PaginationRequest** (and subclasses `R extends PaginationRequest`): Carries page index, page size, filters, search query, and any consumer-defined fields identifying a single load.
- **Pagination Scope**: A logical query context defined by the tuple (provider instance, filters, search query, request scope identity, pagination session). Scope identity changes on refresh, reload, filter change, search change, provider replacement, or cubit disposal.
- **Page Stream Registration**: An entry tracking a single page's stream subscription within a scope — used by `StreamPaginationProvider` to accumulate active subscriptions and to cancel them on scope reset or disposal.
- **Stream Accumulation Registry**: The ordered collection of active page stream registrations belonging to the current scope; cleared atomically on scope reset.
- **SmartPaginationCubit**: Owns scope identity, request generation tokens, retry policy, and the public state stream consumed by the UI; delegates fetching to the configured provider.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of acceptance scenarios in this specification are covered by automated tests in the package's test suite.
- **SC-002**: Zero stream subscriptions and zero internal controllers remain open after a `SmartPaginationCubit` configured with any provider variant is disposed, verified by an instrumented test.
- **SC-003**: Zero emissions from a cancelled scope reach the cubit's published state, verified by a test that injects a delayed emission after scope reset and asserts state is unchanged.
- **SC-004**: A consumer using a custom `PaginationRequest` subclass can read its custom fields inside the user callback without a runtime cast, verified by a test that would fail to compile or fail at runtime if type erasure occurred.
- **SC-005**: Existing example apps and consumer integrations continue to work without code changes (backward-compatible public API), verified by running the package's existing examples and tests unchanged.
- **SC-006**: A developer new to the package can identify which provider variant to use and how scope reset works by reading only the README, with no source-code reading required (validated by README review).
- **SC-007**: After three load-more calls in stream mode, the visible list contains items from all three pages in page order, verified by an integration-style test driving real (in-memory) streams.
- **SC-008**: When any active page's latest emission has `count < pageSize`, a subsequent `loadMore` call is rejected; when a later emission restores `count == pageSize` for every active page, `loadMore` succeeds — both verified by an integration test that toggles a page's slice between full and partial.

## Assumptions

- The `SmartPaginationCubit` continues to own scope identity, request generation tokens, and retry policy; providers cooperate with these mechanisms but do not duplicate them.
- "Same logical request family" for scope identity is determined by equality of the `PaginationRequest` subclass instance under whatever equality the consumer defines; the library does not introduce a new identity scheme.
- Page-based ownership of stream subscriptions is the default accumulation strategy; alternative strategies (if any) are out of scope for this iteration.
- The merged-state ordering rule "page 1 + page 2 + ... + page N" reflects monotonically increasing page numbers within a scope; the library does not attempt to re-sort items inside a page.
- Duplicate detection across pages remains the consumer's responsibility; the library will not introduce implicit dedup.
- The library will not adopt new heavy dependencies; lifecycle handling uses the Dart/Flutter standard library (`StreamSubscription`, `StreamController`, `Cubit`) and existing direct dependencies (`flutter_bloc`, `provider`).
- Existing behavior of `.withProvider(...)` and `.withCubit(...)` constructors is preserved; no removal or rename in this release.
- Documentation language is English (matching existing README/CHANGELOG); localization is out of scope.
- The work targets the current supported Flutter/Dart version range declared in `pubspec.yaml`; no SDK constraint changes are planned.
- Page eviction (capping simultaneous active page subscriptions) is **out of scope** for this iteration; pages accumulate until the scope resets. A future iteration may introduce a configurable limit once the core accumulation behavior is proven stable.
