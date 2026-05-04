# Smart Pagination — Spec Kit Professional Prompts

This document contains ready-to-use prompts for adding GitHub Spec Kit to the existing `smart_pagination` Flutter/Dart package and using it professionally for the `PaginationProvider` maintenance work.

---

## 0. Initialize Spec Kit in the Existing Project

Run this from the root of the existing `smart_pagination` repository.

```bash
uvx --from git+https://github.com/github/spec-kit.git specify init .
```

Optional PowerShell-specific initialization:

```bash
uvx --from git+https://github.com/github/spec-kit.git specify init . --script ps
```

Optional POSIX shell initialization:

```bash
uvx --from git+https://github.com/github/spec-kit.git specify init . --script sh
```

---

## 1. Constitution Prompt

Use this first after initializing Spec Kit.

```markdown
/speckit.constitution

Establish the permanent engineering constitution for the existing Flutter/Dart package `smart_pagination`.

This project is a reusable Flutter package, not an application. All future specifications, plans, tasks, and implementations must follow these principles.

## Core Project Principles

### 1. Library-First Design

The package must remain reusable, framework-consistent, and safe for public consumption.

Rules:

- Public APIs must be stable and predictable.
- Breaking changes must be avoided unless correctness requires them.
- Any breaking change must include a migration guide.
- Widgets must remain composable.
- Business-specific assumptions must not be hardcoded into the package.

### 2. Backward Compatibility First

Existing users of the package must not be forced to rewrite normal usage without a strong reason.

Rules:

- Preserve `.withProvider(...)` constructors.
- Preserve `.withCubit(...)` constructors.
- Preserve `PaginationProvider.future(...)`.
- Preserve `PaginationProvider.stream(...)`.
- Preserve `PaginationProvider.mergeStreams(...)`.
- Preserve custom `PaginationRequest` subclasses.
- Preserve README examples unless the change is explicitly documented.

### 3. Cubit Owns Pagination State

The provider layer is a data-source adapter, not a UI state manager.

Rules:

- `SmartPaginationCubit` owns pagination state.
- Providers supply data streams or future results only.
- Providers must not emit UI state directly.
- Providers must not decide loading, loaded, empty, or error UI states.
- Providers must not bypass the cubit state pipeline.

### 4. Stream Lifecycle Safety

All stream-based behavior must be deterministic and leak-free.

Rules:

- Every `StreamSubscription` must have a clear owner.
- Every active subscription must be cancelled on reset, eviction, or dispose.
- Any internally created `StreamController` must be closed.
- Old-scope stream emissions must never update new-scope state.
- No stream emission should happen after cubit dispose.

### 5. Stream Accumulation Rule

`StreamPaginationProvider` must support accumulated page streams.

Rules:

- Loading a new stream within the same pagination scope must add it to previous active streams.
- Previous page streams must remain active in the same scope.
- Old streams must be cancelled when scope resets.
- Scope reset includes refresh, reload, filter change, search query change, provider change, page eviction, and cubit dispose.
- Active streams must be merged into one coherent paginated result.
- Duplicate handling must be explicit, not hidden.

### 6. Correctness Before Convenience

Pagination correctness is more important than short code.

Rules:

- Avoid stale responses.
- Avoid duplicate active stream registrations.
- Avoid silent data loss.
- Avoid hidden deduplication.
- Avoid memory leaks.
- Avoid ambiguous stream pagination behavior.

### 7. Explicit Duplicate Handling

The package must not silently remove duplicates without a user-defined identity rule.

Rules:

- Duplicate handling may be delegated to `listBuilder`.
- Or supported through an explicit key extractor or merge strategy.
- The behavior must be documented and tested.

### 8. Testing Required for Every Behavior Change

Every provider change must include tests.

Required test categories:

- Future provider behavior.
- Stream provider behavior.
- Merged stream behavior.
- Stream accumulation behavior.
- Cancellation and disposal.
- Refresh/reload scope reset.
- Filter/search scope reset.
- Error handling.
- Completion behavior.
- Custom request type preservation.
- Backward compatibility examples.

### 9. Documentation Required

Every public behavior change must update documentation.

Required documentation:

- README.md
- CHANGELOG.md
- Usage examples
- Migration notes if needed
- Provider behavior notes
- Stream lifecycle notes
- Accumulated streams notes

### 10. Bilingual Clarification Questions Rule

All clarification questions must always be written in both English and Arabic.

This applies to every `/speckit.clarify` operation in this project.

Required format:

### Question N
**English:** Write the clarification question in clear technical English.

**Arabic:** اكتب نفس سؤال التوضيح باللغة العربية مع الحفاظ على نفس المعنى التقني.

Rules:

- English must always appear first.
- Arabic must always appear second.
- The Arabic version must preserve the same technical meaning as the English question.
- Do not ask English-only clarification questions.
- Do not ask Arabic-only clarification questions.
- If the question includes choices, provide the choices in both English and Arabic.
- If technical terms are used, keep the English term and add Arabic explanation when needed.
- Ask only clarification questions that affect requirements, architecture, implementation, testing, compatibility, or user experience.
- Avoid generic or low-value questions.
```

---

## 2. Specify Prompt

Use this to create the feature specification.

```markdown
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
```

---

## 3. Clarify Prompt

Use this after `/speckit.specify`.

```markdown
/speckit.clarify

Clarify the requirements for maintaining the `PaginationProvider` system in `smart_pagination`.

Important language rule:
All clarification questions must be bilingual: English first, then Arabic. Use the same numbering and preserve the same technical meaning in both languages.

Required format:

### Question N
**English:** ...
**Arabic:** ...

Focus only on questions that affect implementation decisions.

Clarify these topics:

1. Stream accumulation behavior.
2. Pagination scope boundaries.
3. Stream key strategy.
4. Stream aggregation strategy.
5. Duplicate handling strategy.
6. Stream error behavior.
7. Stream completion behavior.
8. Memory limits and max active streams.
9. Page eviction behavior.
10. Refresh and reload reset behavior.
11. Filter and search query reset behavior.
12. Cubit disposal behavior.
13. Backward compatibility.
14. Documentation requirements.
15. Test coverage requirements.

Specific clarification context:

`StreamPaginationProvider` must support accumulated page streams. Loading a new stream within the same pagination scope must add it to previous active streams, not replace them. Old streams are cancelled only when the scope resets, such as refresh, reload, filter/search change, provider change, page eviction, or cubit dispose.

Do not ask generic questions.
Ask only questions that help decide the design and implementation.
```

---

## 4. Plan Prompt

Use this after answering clarification questions.

```markdown
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
```

---

## 5. Tasks Prompt

Use this after the technical plan is approved.

```markdown
/speckit.tasks

Generate an actionable implementation task list for the approved `PaginationProvider` maintenance plan.

The task list must be safe, incremental, test-driven, and suitable for a Flutter/Dart package maintainer.

## Task Requirements

Organize tasks into phases:

### Phase 1 — Baseline Audit

- Inspect provider classes.
- Inspect cubit/provider integration.
- Inspect `.withProvider(...)` constructors.
- Inspect Smart Search usage.
- Inspect current tests.
- Inspect README and CHANGELOG.

### Phase 2 — Characterization Tests

Create tests that describe current behavior before changing implementation.

Include:

- Future provider baseline tests.
- Stream provider baseline tests.
- Merged streams baseline tests.
- Cubit integration baseline tests.

### Phase 3 — Stream Accumulation Tests

Create failing tests for the required behavior.

Include:

- Page 1 stream active.
- Page 2 stream added without cancelling page 1.
- Page 3 stream added without cancelling previous streams.
- Emissions from any active page update final aggregated state.
- Refresh cancels all active streams.
- Dispose cancels all active streams.
- Old-scope emissions ignored.

### Phase 4 — Internal Registry Implementation

Implement an internal stream registry/multiplexer.

Tasks:

- Add stream registry class.
- Add stream metadata model.
- Add scope token support.
- Add stream key handling.
- Add aggregation logic.
- Add cancellation logic.
- Add completion tracking.
- Add error tracking.

### Phase 5 — Cubit Integration

Integrate stream accumulation into `SmartPaginationCubit`.

Tasks:

- Adjust stream fetch path.
- Register new page streams instead of replacing streams in same scope.
- Reset registry on refresh/reload/filter/search.
- Cancel stream by page when page is evicted.
- Ensure sorting/listBuilder still applies.
- Ensure loading/error states are correct.
- Ensure request token guards still work.

### Phase 6 — Merged Stream Safety

Fix lifecycle behavior in `MergedStreamPaginationProvider`.

Tasks:

- Cancel all child subscriptions.
- Close internal controllers.
- Handle child completion.
- Handle all streams completed.
- Handle child stream errors.
- Add tests for zero, one, and multiple streams.

### Phase 7 — Error Handling and Completion

Implement clear error and completion policy.

Tasks:

- First page stream error behavior.
- Later page stream error behavior.
- Preserve loaded data when later page fails.
- Avoid stuck loading states.
- Keep completed stream last emitted items.
- Cancel completed streams only when evicted or reset.

### Phase 8 — Documentation

Update:

- README.md
- CHANGELOG.md
- Provider examples
- Stream accumulation explanation
- Merged stream lifecycle notes
- Duplicate handling notes
- Migration notes if needed

### Phase 9 — Validation

Run:

- `flutter analyze`
- `dart analyze`
- Unit tests
- Example compile check if available
- README example validation if possible

## Task Format

Each task must include:

- Task ID.
- Title.
- Files likely affected.
- Description.
- Acceptance criteria.
- Dependencies.
- Whether it can run in parallel.

Do not implement code yet.
Generate tasks only.
```

---

## 6. Analyze Prompt

Use this after tasks are generated and before implementation.

```markdown
/speckit.analyze

Analyze the generated specification, clarifications, technical plan, and tasks for consistency and completeness.

Focus on the `PaginationProvider` maintenance feature.

Check for:

1. Contradictions between spec and plan.
2. Missing tasks for any requirement.
3. Missing tests for any behavior change.
4. Missing documentation tasks.
5. Backward compatibility risks.
6. Stream lifecycle gaps.
7. Missing cleanup logic.
8. Missing stale-scope protection.
9. Missing duplicate handling decisions.
10. Missing error handling policy.
11. Missing completion behavior policy.
12. Missing page eviction behavior.
13. Missing Smart Search compatibility checks.
14. Missing README and CHANGELOG updates.
15. Any task that starts implementation before tests.

Produce:

- Critical issues.
- Important issues.
- Nice-to-have issues.
- Required fixes before `/speckit.implement`.

Do not implement code.
Only analyze and report.
```

---

## 7. Implement Prompt

Use only after analysis is clean.

```markdown
/speckit.implement

Implement the approved tasks for the `PaginationProvider` maintenance feature.

Follow the generated task order strictly.

## Implementation Rules

- Do not rewrite unrelated package areas.
- Preserve public API compatibility unless the approved plan says otherwise.
- Add or update tests before or alongside implementation.
- Keep the cubit as the owner of pagination state.
- Keep providers as data-source adapters.
- Implement accumulated stream pagination safely.
- Cancel streams on refresh, reload, filter/search reset, page eviction, and dispose.
- Prevent stale old-scope emissions.
- Do not silently deduplicate items.
- Preserve custom `PaginationRequest` subclasses.
- Update README and CHANGELOG.

## Validation Required

After implementation, run or prepare commands for:

- `flutter analyze`
- `dart analyze`
- `flutter test` or `dart test`

Report:

- Files changed.
- Tests added.
- Behavior changed.
- Backward compatibility status.
- Any known limitations.
```

---

## 8. Post-Implementation Review Prompt

Use this after implementation.

```markdown
Review the completed `PaginationProvider` maintenance implementation as a senior Flutter package maintainer.

Check:

1. Does `StreamPaginationProvider` accumulate page streams correctly?
2. Are previous streams kept active within the same pagination scope?
3. Are all streams cancelled on refresh/reload/filter/search/provider change/dispose?
4. Are streams related to evicted pages cancelled?
5. Are stale stream emissions ignored?
6. Is duplicate handling explicit?
7. Does `MergedStreamPaginationProvider` close controllers and cancel subscriptions?
8. Does error handling preserve valid loaded data?
9. Are completed streams handled safely?
10. Are custom request subclasses preserved?
11. Are `.withProvider(...)` and `.withCubit(...)` still compatible?
12. Are README and CHANGELOG updated?
13. Are tests sufficient?
14. Is there any memory leak risk?
15. Is there any breaking change that needs migration notes?

Return:

- Final review summary.
- Blocking issues.
- Non-blocking issues.
- Suggested improvements.
- Release readiness decision.
```

