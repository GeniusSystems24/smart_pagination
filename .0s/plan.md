/speckit.plan

Create a technical implementation plan for maintaining and stabilizing the `PaginationProvider` system in the existing Flutter/Dart package `smart_pagination`.

## Technical Context

The package uses Flutter, Dart, `flutter_bloc`, and a Cubit-based pagination architecture.

The provider system includes:

- `PaginationProvider<T, R extends PaginationRequest>`
- `FuturePaginationProvider<T, R>`
- `StreamPaginationProvider<T, R>`
- `MergedStreamPaginationProvider<T, R>`
- `SmartPaginationCubit<T, R>`
- `.withProvider(...)` constructors
- `.withCubit(...)` constructors
- Smart Search widgets that depend on pagination providers

## Core Technical Requirement

`StreamPaginationProvider` must support accumulated page streams.

Current conceptual behavior to avoid:

- Attach one stream.
- Cancel previous stream whenever a new stream is fetched.

Required conceptual behavior:

- Within the same pagination scope, register each new page stream.
- Keep previous streams active.
- Merge all active stream outputs.
- Emit one coherent paginated list.
- Cancel all active streams only when scope resets or page is evicted.

## Required Plan Sections

### 1. Executive Summary

Summarize the maintenance goal and the high-level solution.

### 2. Current Provider Architecture Review

Review:

- Future provider.
- Stream provider.
- Merged stream provider.
- Cubit/provider integration.
- Widget constructors.
- Smart Search dependency.

### 3. Risks Found

Identify provider risks such as:

- Stream subscription leaks.
- Stream controller leaks.
- Stale emissions.
- Duplicate stream registration.
- Ambiguous stream pagination semantics.
- Hidden duplicate items.
- Broken request typing.
- Error states stuck in loading.

### 4. Proposed Internal Design

Propose a small internal component such as:

- `ActiveStreamRegistry<T, R>`
- `StreamPageRegistry<T, R>`
- `StreamMultiplexer<T, R>`

The design must own:

- Active stream subscriptions.
- Stream keys.
- Scope keys.
- Latest emitted items per stream.
- Completion state.
- Error state.
- Cancellation.
- Cleanup.
- Aggregated output.

### 5. Pagination Scope Model

Define:

- What is a scope?
- What creates a new scope?
- How to generate a `scopeToken` or `requestGeneration`?
- How to ignore old-scope emissions?
- How refresh/reload/filter/search resets behave?

### 6. Stream Key Strategy

Define stream identity.

Evaluate:

- Page-based key.
- Cursor-based key.
- Request-based key.
- Custom key extractor.

The same stream key must not create duplicate active subscriptions unless intentionally replaced.

### 7. Stream Aggregation Strategy

Define how multiple stream emissions become one list.

Evaluate:

1. Concatenate stream pages by page order.
2. Merge by item key.
3. Delegate duplicate handling to `listBuilder`.
4. Add optional merge strategy.

Do not silently deduplicate items without an explicit identity rule.

### 8. Future Provider Plan

Plan improvements for:

- Error propagation.
- Stale response protection.
- Retry integration.
- Disposal safety.
- Request generation checks.

### 9. Stream Provider Plan

Plan improvements for:

- Initial stream registration.
- Load-more stream accumulation.
- Refresh/reload reset.
- Filter/search reset.
- Stream error policy.
- Stream completion policy.
- Page eviction cleanup.
- Memory limits.

### 9A. End-of-List / Stop Loading Logic Plan

Add a dedicated plan for the logic that stops additional loading when the provider reaches the end of available data.

The plan must define how `SmartPaginationCubit` decides that there are no more items to fetch, especially for Future-based pagination, Stream-based pagination, and accumulated stream pagination.

Cover:

- How `hasReachedEnd` is calculated.
- How `PaginationMeta.hasNext` is calculated.
- How page-size based end detection works.
- How cursor-based end detection works.
- How empty responses should be handled.
- How repeated empty responses should be prevented.
- How load-more requests are blocked after reaching the end.
- How refresh/reload resets the end state.
- How filters/search reset the end state.
- How stream providers communicate that a page has no more data.
- How accumulated streams should stop requesting new pages while keeping already loaded streams active.
- How `loadMoreNoMoreItemsBuilder` is shown.
- How first-page empty state differs from end-of-list state.
- How errors should not incorrectly mark the list as ended.
- How stale responses must not incorrectly set `hasReachedEnd`.

Important rules:

- Do not continue calling the provider after a confirmed end state.
- Do not mark the list as ended because of an error.
- Do not mark the list as ended because a stale request returned empty.
- Do not mark a stream scope as ended until the active request/page proves there is no next page.
- Refresh/reload/filter/search must clear the old end state and start a new scope.
- End-of-list logic must work for both offset pagination and cursor pagination.

Required design considerations:

1. Offset-based pagination:
   - If returned item count is less than `pageSize`, mark `hasReachedEnd=true`.
   - If returned item count is zero on a non-first page, mark `hasReachedEnd=true` and do not append duplicate empty pages.
   - If `pageSize` is null, require a clear fallback rule or metadata-based detection.

2. Cursor-based pagination:
   - Prefer explicit server metadata such as `nextCursor == null` or `hasNext == false` when available.
   - Do not rely only on item count if the backend can return partial pages while still having more data.
   - Preserve cursor state safely across refresh and load-more.

3. Stream pagination:
   - A stream page may continue to emit updates even after load-more has reached the end.
   - Reaching the end should stop requesting new page streams, not cancel already active streams in the same scope.
   - Existing active streams should remain subscribed until reset, eviction, completion policy, or dispose.

4. Merged stream pagination:
   - End detection must be explicit and documented.
   - If merged streams do not provide pagination metadata, the plan must define whether end detection is unsupported, page-size based, or user-provided.

Tests required:

- First page returns fewer than `pageSize` marks end.
- Load more returns fewer than `pageSize` marks end.
- Load more returns empty list marks end without appending empty page.
- After end is reached, additional load-more calls do not call provider again.
- First page empty shows first-page empty state, not load-more no-more state.
- Refresh clears `hasReachedEnd` and allows loading again.
- Filter/search reset clears `hasReachedEnd`.
- Error does not mark `hasReachedEnd=true`.
- Stale empty response does not mark current scope as ended.
- Cursor-based response with no `nextCursor` marks end.
- Cursor-based response with partial page but valid `nextCursor` does not mark end.
- Stream page end stops requesting new page streams but keeps existing streams active.
- Accumulated stream provider does not register new page streams after confirmed end.
- `loadMoreNoMoreItemsBuilder` appears only after confirmed end.

Acceptance criteria:

- Loading stops reliably when the end is reached.
- Provider is not called repeatedly after end state.
- End state resets correctly on new scope.
- Empty state and no-more-items state are distinct.
- Errors and stale responses do not produce false end states.
- Behavior is documented and tested for Future, Stream, and accumulated Stream providers.

### 10. Merged Streams Provider Plan

Plan improvements for:

- Cancelling child subscriptions.
- Closing internal controllers.
- Handling zero streams.
- Handling one stream.
- Handling multiple streams.
- Handling errors.
- Handling completion.
- Avoiding leaks.

### 11. Cubit Integration Plan

Define required changes in `SmartPaginationCubit`.

Cover:

- `_fetch` behavior.
- Stream fetch behavior.
- Load-more with streams.
- Reset behavior.
- Page trimming and stream eviction.
- Sorting and `listBuilder` integration.
- Error state handling.
- Data age behavior.
- Request token behavior.

### 12. Backward Compatibility Plan

Classify each planned change as:

- Patch-safe.
- Minor version.
- Breaking change.

Prefer patch-safe or minor changes.

If breaking changes are needed, include migration steps.

### 13. Test Plan

Create tests for:

- Future success.
- Future error.
- Future stale response ignored.
- Stream initial load.
- Stream page 2 accumulation.
- Stream page 3 accumulation.
- Page 1 emission after page 2 updates page 1 data.
- Page 2 emission updates page 2 data.
- Aggregated state remains coherent.
- Refresh cancels all streams.
- Reload cancels all streams.
- Filter/search reset cancels all streams.
- Dispose cancels all streams.
- Page eviction cancels related streams.
- Duplicate stream key does not duplicate subscriptions.
- Stream error from page 2 keeps page 1 data.
- Completed stream keeps last emitted data.
- Old scope emission ignored after refresh.
- Merged stream zero streams.
- Merged stream one stream.
- Merged stream multiple streams.
- Merged stream cancellation.
- Merged stream controller close.
- Custom request subclass preservation.
- `.withProvider(...)` compatibility.
- `.withCubit(...)` compatibility.
- README examples compile.

### 14. Documentation Plan

Update:

- README.md
- CHANGELOG.md
- Provider examples
- Stream provider docs
- Merged stream docs
- Stream accumulation docs
- Duplicate handling docs
- Error handling docs
- Migration guide if needed

### 15. Implementation Phases

Break the implementation into safe phases:

1. Audit current provider and cubit behavior.
2. Add tests that capture current behavior and desired behavior.
3. Implement internal stream registry/multiplexer.
4. Integrate stream accumulation with cubit.
5. Fix merged stream lifecycle safety.
6. Add error/completion handling.
7. Add cleanup and disposal guards.
8. Update docs and examples.
9. Run analysis and tests.
10. Prepare changelog.

### 16. Acceptance Criteria

The plan is accepted only if it clearly explains how the package will ensure:

- Accumulated stream pagination works.
- Old streams are cancelled on scope reset.
- No stream subscriptions leak.
- No controllers leak.
- No old-scope emissions update current state.
- Duplicate handling is explicit.
- Future provider remains compatible.
- Stream provider remains compatible.
- Merged stream provider remains compatible.
- Tests prove all critical behavior.
- Docs explain the behavior clearly.

Do not implement code yet.
Produce the plan only.