<!--
SYNC IMPACT REPORT
==================
Version change: 0.0.0 (uninitialized template) → 1.0.0
Bump rationale: MAJOR — first complete constitution establishment; all placeholder tokens replaced.

Modified principles:
  [PRINCIPLE_1_NAME] → I. Library-First Design (new)
  [PRINCIPLE_2_NAME] → II. Backward Compatibility First (new)
  [PRINCIPLE_3_NAME] → III. Cubit Owns Pagination State (new)
  [PRINCIPLE_4_NAME] → IV. Stream Lifecycle Safety (new)
  [PRINCIPLE_5_NAME] → V. Stream Accumulation Rule (new)
  (added) VI. Correctness Before Convenience
  (added) VII. Explicit Duplicate Handling

Added sections:
  "Quality Standards" — VIII. Testing Required + IX. Documentation Required
  "Process Standards" — X. Bilingual Clarification Questions Rule
  "Governance" — amendment procedure, versioning policy, compliance review

Removed sections:
  [SECTION_2_NAME] / [SECTION_3_NAME] stubs replaced with concrete sections

Templates reviewed:
  .specify/templates/plan-template.md ✅ Constitution Check gate is dynamic; aligned.
  .specify/templates/spec-template.md ✅ Requirements structure is compatible.
  .specify/templates/tasks-template.md ✅ Phase and testing discipline compatible.

Deferred items:
  None — all tokens resolved.
-->

# Smart Pagination Constitution

## Core Principles

### I. Library-First Design

The package MUST remain reusable, framework-consistent, and safe for public consumption.

- Public APIs MUST be stable and predictable.
- Breaking changes MUST be avoided unless correctness or security requires them.
- Any breaking change MUST include a migration guide before release.
- Widgets MUST remain composable; no widget may mandate a specific parent or child.
- Business-specific assumptions MUST NOT be hardcoded into the package.

### II. Backward Compatibility First

Existing users MUST NOT be forced to rewrite normal usage without strong technical justification.

- The `.withProvider(...)` constructor MUST be preserved across versions.
- The `.withCubit(...)` constructor MUST be preserved across versions.
- `PaginationProvider.future(...)` MUST be preserved.
- `PaginationProvider.stream(...)` MUST be preserved.
- `PaginationProvider.mergeStreams(...)` MUST be preserved.
- Custom `PaginationRequest` subclasses MUST continue to function without modification.
- README code examples MUST remain valid until explicitly deprecated with documented migration.

### III. Cubit Owns Pagination State

The cubit layer is the single source of truth for all pagination UI state.
The provider layer is a data-source adapter only.

- `SmartPaginationCubit` MUST own all pagination state: loading, loaded, empty, and error.
- Providers MUST supply data streams or future results only.
- Providers MUST NOT emit UI state directly.
- Providers MUST NOT decide which UI state (loading, loaded, empty, error) to render.
- Providers MUST NOT bypass the cubit state pipeline.

### IV. Stream Lifecycle Safety

All stream-based behavior MUST be deterministic and leak-free.

- Every `StreamSubscription` MUST have a clear, documented owner.
- Every active subscription MUST be cancelled on scope reset, eviction, or dispose.
- Any internally created `StreamController` MUST be closed before or at the same point
  the owning object is disposed.
- Old-scope stream emissions MUST NOT update new-scope state after a scope reset.
- No stream emission MUST occur after cubit dispose.

### V. Stream Accumulation Rule

`StreamPaginationProvider` MUST support accumulated page streams within a pagination scope.

- Loading a new stream within the same pagination scope MUST add it to the set of previously
  active streams; it MUST NOT replace them.
- Previous page streams MUST remain active within the same scope.
- All active streams MUST be cancelled when the scope resets.
- Scope reset is triggered by: refresh, reload, filter change, search query change, provider
  change, page eviction, and cubit dispose.
- Active streams MUST be merged into one coherent paginated result.
- Duplicate handling MUST be explicit and MUST NOT occur silently.

### VI. Correctness Before Convenience

Pagination correctness is more important than brevity or convenience.

- Stale responses MUST NOT update the current pagination state.
- Duplicate active stream registrations MUST NOT be allowed.
- Silent data loss MUST NOT occur under any condition.
- Hidden deduplication MUST NOT be applied without an explicit user-defined identity rule.
- Memory leaks MUST NOT be introduced in provider or cubit implementations.
- Ambiguous stream pagination behavior MUST NOT exist in the public API.

### VII. Explicit Duplicate Handling

The package MUST NOT silently remove duplicates without a user-defined identity rule.

- Duplicate removal MAY be delegated to the `listBuilder` callback.
- Or duplicate removal MAY be supported through an explicit key extractor or merge strategy
  provided by the user.
- Whichever strategy is used MUST be documented and covered by tests.

## Quality Standards

### VIII. Testing Required for Every Behavior Change

Every provider change or cubit behavior change MUST include tests before the change is merged.

Required test categories for every provider-level or cubit-level change:

| Category | Description |
| --- | --- |
| Future provider | Correct behavior for `PaginationProvider.future(...)` |
| Stream provider | Correct behavior for `PaginationProvider.stream(...)` |
| Merged streams | Correct behavior for `PaginationProvider.mergeStreams(...)` |
| Stream accumulation | Page streams accumulate and merge correctly within scope |
| Cancellation & disposal | Subscriptions cancelled, controllers closed on dispose |
| Refresh/reload reset | Scope resets fully on refresh and reload |
| Filter/search reset | Scope resets fully on filter and search query change |
| Error handling | Errors are surfaced to cubit state correctly |
| Completion | Pagination terminates correctly when no more pages exist |
| Custom request types | Custom `PaginationRequest` subclasses pass through unmodified |
| Backward compatibility | Existing README-level usage patterns continue to compile and run |

### IX. Documentation Required

Every public behavior change MUST update documentation before the change is merged.

Required documentation updates:

- `README.md` — updated usage examples if API surface changes.
- `CHANGELOG.md` — entry under the correct version heading.
- Usage examples — working example added or updated in `example/lib/`.
- Migration notes — required if the change is a breaking change.
- Provider behavior notes — updated if provider semantics change.
- Stream lifecycle notes — updated if stream lifecycle behavior changes.
- Accumulated streams notes — updated if stream accumulation behavior changes.

## Process Standards

### X. Bilingual Clarification Questions Rule

All clarification questions produced by `/speckit-clarify` for this project MUST be written in
both English and Arabic.

Required format for every clarification question:

```markdown
### Question N
**English:** Write the clarification question in clear technical English.

**Arabic:** اكتب نفس سؤال التوضيح باللغة العربية مع الحفاظ على نفس المعنى التقني.
```

Rules:

- English MUST always appear first.
- Arabic MUST always appear second.
- The Arabic version MUST preserve the same technical meaning as the English question.
- English-only or Arabic-only clarification questions MUST NOT be produced.
- If the question includes choices, choices MUST be provided in both English and Arabic.
- If technical terms are used, the English term MUST be kept; an Arabic explanation MUST be
  added where clarification aids comprehension.
- Only ask questions that affect requirements, architecture, implementation, testing,
  compatibility, or user experience. Generic or low-value questions MUST be omitted.

## Governance

This constitution supersedes all other development guidelines for the `smart_pagination` package.
No principle may be relaxed by convention, time pressure, or individual preference.

**Amendment procedure**:

1. Open a PR that modifies this file.
2. State the principle being changed, the rationale, and the version bump type.
3. If the change is breaking (MAJOR), include a migration guide.
4. Two reviews MUST approve the PR before merge.
5. Update `LAST_AMENDED_DATE` and `CONSTITUTION_VERSION` in this file.

**Versioning policy** (SemVer):

- MAJOR: Backward-incompatible governance change — principle removal, redefinition, or
  removal of a mandatory requirement.
- MINOR: New principle or section added, or materially expanded guidance.
- PATCH: Clarification, wording improvement, typo fix, non-semantic refinement.

**Compliance review**:

- Every implementation plan (`plan.md`) MUST include a Constitution Check gate.
- The gate MUST be evaluated before Phase 0 research and re-checked after Phase 1 design.
- Any compliance violation MUST be justified in the plan's Complexity Tracking table.

**Version**: 1.0.0 | **Ratified**: 2026-05-04 | **Last Amended**: 2026-05-04
