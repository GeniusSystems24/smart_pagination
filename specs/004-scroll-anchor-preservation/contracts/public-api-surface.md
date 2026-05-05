# Contract — Public API Surface Delta

**Feature**: `004-scroll-anchor-preservation` | **Plan**: [../plan.md](../plan.md)

This contract enumerates every change to the package's public API surface. The exhaustive list is the verification surface for Constitution §II ("Backward Compatibility First") and Spec FR-009 ("no breaking changes to `.withProvider(...)` or `.withCubit(...)`").

---

## Additions

### A1 — `PaginateApiView.preserveScrollAnchorOnAppend`

**File**: `lib/smart_pagination/widgets/paginate_api_view.dart`

**Type**: `bool`, defaults to `true`.

**Signature delta**:

```dart
class PaginateApiView<T, R extends PaginationRequest> extends StatefulWidget {
  const PaginateApiView({
    // ... existing params unchanged ...
    this.preserveScrollAnchorOnAppend = true,  // ← NEW
  });

  // ... existing fields unchanged ...

  /// Whether to capture the visible scroll anchor before each load-more
  /// fetch and restore the viewport relative to that anchor after the new
  /// page is appended.
  ///
  /// Defaults to `true`. Set to `false` only if you have a specific reason
  /// to disable anchor preservation for this list (e.g., a custom
  /// scroll-correction flow that conflicts).
  ///
  /// On reverse-direction lists, `PageView`, and `ReorderableListView`,
  /// this parameter has no effect: anchor preservation is unsupported on
  /// those views in this version and the package falls through to
  /// existing behavior regardless of this flag.
  final bool preserveScrollAnchorOnAppend;
}
```

**Compatibility**: Additive with default. Existing call sites compile unchanged.

### A2 — `SmartPaginationListView.preserveScrollAnchorOnAppend` (and other view-type wrappers)

The same parameter is forwarded through the public wrapper widgets that ultimately compose `PaginateApiView`:

- `SmartPaginationListView`
- `SmartPaginationGridView`
- `SmartPaginationStaggeredGridView`
- (any other public wrapper that composes `PaginateApiView`)

**Compatibility**: Additive with default. Existing call sites compile unchanged.

### A3 — `SmartPaginationCubit.captureAnchorBeforeLoadMore` (annotated `@internal`)

**File**: `lib/smart_pagination/bloc/pagination_cubit.dart`

**Visibility**: Annotated `@internal` (from `package:meta`). Not appearing in README or marketing docs. Documented in dartdoc.

**Signature**:

```dart
/// Internal — called by `PaginateApiView` immediately before a load-more
/// fetch starts. Captures the anchor snapshot for use during the
/// post-fetch restore. Idempotent within a single fetch; subsequent calls
/// during the same in-flight fetch overwrite (the latest snapshot wins).
///
/// Direct external use is not recommended. The method is part of the
/// package's internal contract; misuse is safe (idempotent + flag-based)
/// but does not produce correct anchor behavior without the matching
/// `markUserScroll` plumbing.
@internal
void captureAnchorBeforeLoadMore(_PendingScrollAnchor snapshot);
```

**Compatibility**: New method. `_PendingScrollAnchor` is a private type, so external consumers cannot construct an argument; even if they could, the method is idempotent and safe under misuse.

### A4 — `SmartPaginationCubit.markUserScroll` (annotated `@internal`)

**File**: `lib/smart_pagination/bloc/pagination_cubit.dart`

**Visibility**: Annotated `@internal`.

**Signature**:

```dart
/// Internal — called by `PaginateApiView`'s `NotificationListener` whenever
/// a user-initiated drag-scroll starts. Clears the post-append load-more
/// suppression flag if set.
///
/// Direct external use is not recommended.
@internal
void markUserScroll();
```

**Compatibility**: New method. Safe under misuse (just clears a flag).

---

## Modifications

### M1 — `SmartPaginationCubit.fetchPaginatedList` guard chain

**File**: `lib/smart_pagination/bloc/pagination_cubit.dart`

**Method signature**: unchanged (`void fetchPaginatedList({R? requestOverride, int? limit})`).

**Behavior delta**: a new guard step (`_suppressLoadMoreUntilUserScroll`) is inserted between the existing `_activeLoadMoreKey` check and the `isLoadingMore` check. When the flag is `true`, the method returns silently without calling the provider.

**Compatibility implications**:

- ✅ Existing code that calls `fetchPaginatedList` and expects it to be a no-op when state is loading remains correct.
- ✅ Existing code that retries via `retryAfterError` after a load-more error remains correct (the error path clears the suppression flag).
- ✅ Existing tests asserting that `fetchPaginatedList` does not call the provider after `hasReachedEnd` remain correct.
- ⚠️ Tests that simulate a load-more, observe the new items, and immediately call `fetchPaginatedList` again *without* a synthetic user-scroll WILL now find that the second call is rejected. This is **intentional and is the bug fix**, not a regression. Two existing test files may need a one-line update:
  - Any test that calls `cubit.fetchPaginatedList()` twice in a row to simulate fast scroll → call `cubit.markUserScroll()` between them.
  - This is enumerated explicitly in the migration notes (Phase F).

### M2 — `_PaginateApiViewState` adds an outer `NotificationListener<ScrollNotification>`

**File**: `lib/smart_pagination/widgets/paginate_api_view.dart`

**Behavior delta**: `_buildListView`, `_buildGridView`, and `_buildStaggeredGridView` wrap their existing scrollview in a new outer `NotificationListener<ScrollNotification>` whose `onNotification` returns `false` (does NOT consume the notification). Consumer-attached `NotificationListener`s further up the tree continue to fire as before.

**Compatibility implications**:

- ✅ Consumer `NotificationListener<ScrollNotification>` instances above the package widget continue to receive notifications.
- ✅ Consumer `ScrollController.addListener` callbacks continue to fire.
- ✅ The `StaggeredGridView` already has a `NotificationListener<ScrollNotification>` (line 864); the new outer listener composes safely (notifications propagate up; both fire).

---

## Removals

None.

---

## No-change surfaces (explicit confirmation)

| Surface | Status |
|---|---|
| `SmartPaginationController` constructor and methods | unchanged |
| `SmartPaginationController.of` factory | unchanged |
| `PaginationProvider.future` | unchanged |
| `PaginationProvider.stream` | unchanged |
| `PaginationProvider.mergeStreams` | unchanged |
| `PaginationRequest` and all consumer subclasses | unchanged |
| `SmartPaginationLoaded` / `SmartPaginationError` / `SmartPaginationInitial` | unchanged |
| `PaginationMeta` | unchanged |
| `PaginationOperation*` sealed hierarchy | unchanged |
| `errorRetryStrategy` and `ErrorRetryStrategy` enum | unchanged |
| `SmartPaginationCubit.identityKey` constructor parameter (from `003-load-more-guard`) | unchanged |
| Public scroll-navigation methods on the cubit (`animateToIndex`, `jumpToIndex`, `scrollToIndex`, `animateFirstWhere`, `jumpFirstWhere`, `scrollFirstWhere`) | unchanged |
| `attachListObserverController` / `attachGridObserverController` / `detach*` | unchanged |
| `widget.scrollController` ownership semantics | unchanged (external is not disposed) |
| `widget.itemKeyBuilder` semantics for animation and `findChildIndexCallback` | unchanged (key-based anchor is an additional use, not a replacement) |
| `widget.invisibleItemsThreshold` | unchanged |
| `widget.reverse` semantics for the underlying scrollables | unchanged (the package detects this flag for anchor purposes only) |
| All `loadMore*Builder` parameters | unchanged |

---

## Migration impact

| Audience | Action required |
|---|---|
| Consumers using `.withProvider(...)` | None. Behavior improves automatically (no chained load-more). |
| Consumers using `.withCubit(...)` with internal `ScrollController` | None. |
| Consumers using `.withCubit(...)` with external `ScrollController` | None. |
| Consumers who currently set `preserveScrollAnchorOnAppend` (it doesn't exist pre-feature) | n/a |
| Test code that called `cubit.fetchPaginatedList()` twice in a row to simulate fast scroll | Insert `cubit.markUserScroll()` between the calls (see M1). |
| Code that subclassed `SmartPaginationCubit` to override `fetchPaginatedList` | Re-check the guard chain order; the new `_suppressLoadMoreUntilUserScroll` step is between `_activeLoadMoreKey` and `isLoadingMore`. |
| Code that depends on the precise sequence of emitted states from a single load-more | No emission order changed; only `fetchPaginatedList`'s entry-side guards changed. |
| README examples | Continue to work unchanged. Documented in T35. |

---

## Verification matrix

| Compatibility property | Verifying test |
|---|---|
| `.withProvider(...)` README example compiles unchanged | T35 |
| `.withCubit(...)` README example compiles unchanged | T35 |
| External `ScrollController` listeners still fire | T32 |
| External `ScrollController` is not disposed by the package | T33 |
| Existing test suite passes 100% | (Phase G CI) |
| Disabling via `preserveScrollAnchorOnAppend: false` reverts to pre-feature | T34 |
| `flutter analyze` reports no new issues | (Phase I CI) |
