# Contract: FuturePaginationProvider

**Surface**: `PaginationProvider.future(...)` factory → `FuturePaginationProvider<T, R extends PaginationRequest>`.

## Preserved signature (backward-compatibility anchor)

```dart
sealed class PaginationProvider<T, R extends PaginationRequest> {
  const factory PaginationProvider.future(
    Future<List<T>> Function(R request) dataProvider,
  ) = FuturePaginationProvider<T, R>;
}
```

Removing or renaming this factory or changing the parameter shape is **forbidden** under Constitution II.

## Inputs the cubit supplies

- `R request` — the consumer-defined request, exact subclass preserved (FR-030).
- An implicit generation token (the cubit's `_generation` at call time). The provider does not see the token; the cubit captures it before invoking the provider and validates it on the response.

## Emissions / responses the provider may produce

- A successful `Future<List<T>>` resolving to the page's items (FR-001).
- A failed `Future` (any thrown error) — the cubit treats it as a first-page error or a load-more error depending on the page index that triggered the call (FR-002).

## Lifecycle obligations

- The provider holds **no** state across calls. Each call is independent.
- The provider does **not** retry; retry policy is owned by the cubit (FR-006, Constitution III).
- The provider does **not** cancel anything. Cancellation semantics are simulated by the cubit dropping stale responses on generation mismatch (FR-003, FR-005).

## Required test scenarios (mapped to acceptance criteria)

1. **Successful page fetch** (FR-001 / US3 #1) — provider returns `[a, b, c]`; cubit appends them and updates `meta`.
2. **Stale response after refresh** (FR-003 / US3 #2) — fetch starts with `_generation=1`; before the future resolves, refresh bumps `_generation=2`; the late response is discarded.
3. **Disposal mid-flight** (FR-005 / US3 #3) — fetch starts; cubit is closed; future resolves; no state mutation occurs.
4. **First-page error vs load-more error** (FR-002 / US3 #4) — page-1 error transitions to first-page-error state; page-2 error keeps existing items and surfaces a load-more error annotation.
5. **Custom request subclass passes through unmodified** (FR-030 / US4) — provider callback receives the exact `R` instance the cubit was given; custom fields readable without cast.

## Failure modes the cubit must accept

- Network errors, timeouts, unexpected exceptions thrown by `dataProvider` — all mapped to the cubit's existing error channel.
- The provider returning an empty list — treated as the end of pagination on the future path (existing behavior; not changed by this iteration).
