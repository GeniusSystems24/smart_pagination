/speckit.specify

Maintain and stabilize the `PaginationProvider` system in the existing Flutter/Dart package `smart_pagination`.

The goal is to improve provider correctness, stream lifecycle safety, accumulated stream behavior, merged stream behavior, error handling, type safety, documentation, and test coverage without rewriting the package or breaking the public API unnecessarily.

## Problem

The package currently supports multiple data provider styles:

- `PaginationProvider.future(...)` for Future-based pagination.
- `PaginationProvider.stream(...)` for stream-based realtime pagination.
- `PaginationProvider.mergeStreams(...)` for combining multiple streams.

The provider layer needs professional maintenance to ensure it behaves correctly in real applications, especially when using stream-based pagination.

The key requirement is that `StreamPaginationProvider` must support accumulated page streams. When the user loads page 1, page 1 stream remains active. When the user loads page 2, page 2 stream is added without cancelling page 1. When the user loads page 3, page 3 stream is added without cancelling page 1 or page 2.

All active streams in the same pagination scope must be merged into one coherent paginated state.

Old streams should be cancelled only when the pagination scope resets.

## Goals

1. Preserve existing public API behavior as much as possible.
2. Stabilize `FuturePaginationProvider` behavior.
3. Stabilize `StreamPaginationProvider` behavior.
4. Add accumulated stream support for stream pagination.
5. Stabilize `MergedStreamPaginationProvider` lifecycle behavior.
6. Prevent memory leaks from stream subscriptions or controllers.
7. Prevent stale emissions from old requests or old scopes.
8. Keep duplicate handling explicit.
9. Preserve generic request typing with `R extends PaginationRequest`.
10. Improve error handling and completion behavior.
11. Add complete tests for provider behavior.
12. Update README and CHANGELOG.

## Non-Goals

1. Do not rewrite the whole package.
2. Do not replace `SmartPaginationCubit`.
3. Do not remove `.withProvider(...)`.
4. Do not remove `.withCubit(...)`.
5. Do not silently deduplicate items.
6. Do not introduce heavy dependencies unless necessary.
7. Do not make providers responsible for UI state.
8. Do not break existing examples unless unavoidable.

## Required Behavior

### Future Provider

`PaginationProvider.future(...)` must continue to support normal REST/API pagination.

It must handle:

- Successful page fetch.
- First-page errors.
- Load-more errors.
- Stale response protection.
- Request cancellation semantics through cubit token/generation logic.
- Retry integration owned by the cubit.
- Disposal safety.

### Stream Provider

`PaginationProvider.stream(...)` must support realtime paginated streams.

It must handle:

- Initial stream registration.
- Load-more stream registration.
- Accumulating active streams within the same pagination scope.
- Emissions from any active stream.
- Aggregating all active stream latest values into one list.
- Stream error handling.
- Stream completion handling.
- Scope reset cancellation.
- Disposal cancellation.
- Page eviction cancellation.
- Stale-scope emission protection.

### Merged Stream Provider

`PaginationProvider.mergeStreams(...)` must be lifecycle-safe.

It must handle:

- Zero streams.
- One stream.
- Multiple streams.
- Child stream errors.
- Child stream completion.
- Cancelling all child subscriptions.
- Closing internal controllers.
- Avoiding memory leaks.

## Pagination Scope Definition

A pagination scope represents one logical query context.

The same scope means:

- Same provider instance.
- Same filters.
- Same search query.
- Same logical request family.
- Same pagination session.

A new scope begins when:

- Refresh is called.
- Reload is called.
- Search query changes.
- Filters change.
- Provider instance changes.
- Request scope identity changes.
- Cubit is disposed.

## Stream Accumulation Requirement

When the same scope is active:

- Page 1 stream remains active.
- Page 2 stream is added.
- Page 3 stream is added.
- Emissions from page 1 update page 1 items.
- Emissions from page 2 update page 2 items.
- Emissions from page 3 update page 3 items.
- Final state is page 1 + page 2 + page 3 in a coherent order.

When scope resets:

- All active streams are cancelled.
- Registry is cleared.
- New scope starts from a clean stream collection.

## Acceptance Criteria

1. Existing Future provider usage still works.
2. Existing Stream provider usage still works.
3. Existing Merged Streams usage still works.
4. Stream load-more adds a new stream instead of replacing the old stream.
5. Refresh/reload cancels old accumulated streams.
6. Filter/search reset cancels old accumulated streams.
7. Cubit dispose cancels all active streams.
8. Page eviction cancels the related stream if stream accumulation uses page-based ownership.
9. No stale stream from an old scope can update current state.
10. Merged streams do not leak subscriptions or controllers.
11. Duplicate handling is explicit.
12. Custom `PaginationRequest` subclasses still reach provider callbacks correctly.
13. README and CHANGELOG are updated.
14. Tests cover all new behavior.
