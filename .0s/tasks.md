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