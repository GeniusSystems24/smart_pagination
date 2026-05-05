# Phase 1 Data Model — Scroll Anchor Preservation

**Branch**: `004-scroll-anchor-preservation` | **Date**: 2026-05-05 | **Plan**: [plan.md](plan.md)

This feature is library-internal: no public types are added, no persistence is introduced, no wire format is involved. The "data model" here is the set of private types and field additions inside `SmartPaginationCubit` and `_PaginateApiViewState` that carry anchor state across the capture → fetch → restore lifecycle.

---

## 1. `_PendingScrollAnchor`

A snapshot of the user's viewport position taken immediately before a load-more fetch starts. Private to the cubit, never serialised, never exposed via the public API.

### Declaration site

`lib/smart_pagination/bloc/pagination_state.dart` (alongside `_PageStreamEntry`).

### Schema

```dart
/// Snapshot of the visible viewport at the moment a load-more fetch is
/// initiated. Captured by the widget layer (via the scrollview_observer
/// integration) and passed to the cubit via `captureAnchorBeforeLoadMore`.
/// Consumed in a post-frame callback after the new page is appended.
///
/// Spec 004-scroll-anchor-preservation §4.3, data-model §1.
class _PendingScrollAnchor {
  _PendingScrollAnchor({
    required this.strategy,
    required this.viewType,
    required this.reverse,
    required this.generation,
    this.key,
    this.index,
    this.leadingEdgeOffset,
    this.pixelsBefore,
    this.extentBefore,
  });

  /// Selected strategy for this snapshot. Determines which fields are
  /// populated and which restore mechanism is used.
  final AnchorStrategy strategy;

  /// View type the snapshot was captured against. Used to gate restore
  /// (no-op for out-of-scope view types).
  final _AnchorViewType viewType;

  /// Whether the source scrollable was `reverse: true`. v1 treats reverse
  /// lists as out of scope; restore is a no-op when this is true.
  final bool reverse;

  /// `_generation` value at capture time. The restore is discarded if the
  /// cubit's `_generation` no longer matches at restore time, which is the
  /// signal that a scope reset (refresh/filter/search) interleaved.
  final int generation;

  /// Anchor item's identity key, computed via the consumer's `itemKeyBuilder`.
  /// Populated only when [strategy] == [AnchorStrategy.key].
  final Object? key;

  /// Anchor item's index in the items list at capture time.
  /// Populated when [strategy] in {key, index}.
  final int? index;

  /// Pixels from the viewport top to the anchor item's leading edge at
  /// capture time. Diagnostic / fidelity-validation field; not required
  /// for the standard restore path.
  final double? leadingEdgeOffset;

  /// `controller.position.pixels` at capture time.
  /// Populated when [strategy] == [AnchorStrategy.offset], also captured
  /// for the other strategies as a fallback for the
  /// `_anchorItemNoLongerPresent` edge case (FR-008).
  final double? pixelsBefore;

  /// `controller.position.maxScrollExtent` at capture time.
  /// Diagnostic / future-use field.
  final double? extentBefore;
}
```

### Field validity by strategy

| Field | `AnchorStrategy.key` | `AnchorStrategy.itemIndex` | `AnchorStrategy.offset` |
|---|---|---|---|
| `strategy` | required | required | required |
| `viewType` | required | required | required |
| `reverse` | required | required | required |
| `generation` | required | required | required |
| `key` | **required** | nullable | nullable |
| `index` | required | **required** | nullable |
| `leadingEdgeOffset` | optional | optional | optional |
| `pixelsBefore` | recommended (fallback) | recommended (fallback) | **required** |
| `extentBefore` | optional | optional | optional |

### Lifecycle

```text
Created   : `_PaginateApiViewState` constructs it from the latest observer
            snapshot at the moment `_shouldLoadMore == true` is observed
            in an item builder (or 80%-threshold for staggered).
Pushed    : Widget calls `cubit.captureAnchorBeforeLoadMore(snapshot)`.
            The cubit stores it as `_pendingAnchor`.
Validated : Inside the cubit's `fetchPaginatedList` guard chain, the snapshot's
            `generation` is checked against `_generation`. Mismatch → discarded.
Consumed  : Post-frame callback after fetch success reads `_pendingAnchor`,
            performs the restore, then sets `_pendingAnchor = null`.
Discarded : On error, scope reset, or generation mismatch — the field is
            cleared and never used.
```

### Equality

`_PendingScrollAnchor` does not need `==` / `hashCode` overrides; it is referenced by identity from the single `_pendingAnchor` field and never compared.

---

## 2. `AnchorStrategy` enum

Hybrid policy from Spec Q1.

### Declaration site

`lib/smart_pagination/bloc/pagination_state.dart`.

### Schema

```dart
/// The strategy used to identify and restore a scroll anchor.
/// Selected at capture time based on the available inputs.
///
/// Spec 004-scroll-anchor-preservation §4 (Anchor Capture Strategy).
enum AnchorStrategy {
  /// Anchor identified by the consumer-supplied `itemKeyBuilder` value.
  /// Highest fidelity. Used when `itemKeyBuilder != null`.
  key,

  /// Anchor identified by item index in the items list.
  /// Used for finite-item builders (`ListView` / `GridView`) when no
  /// `itemKeyBuilder` is supplied. Safe under append-only scope.
  /// (Named `itemIndex` because Dart's built-in `Enum.index` getter
  /// reserves the name `index`.)
  itemIndex,

  /// Anchor identified by scroll-controller pixel offset and extent delta.
  /// Used as a fallback for `StaggeredGridView` and any view without a
  /// `scrollview_observer` integration.
  offset,
}
```

### State transitions

The enum is a value type; no transitions. Each `_PendingScrollAnchor` instance carries a single, immutable `strategy` value chosen at capture time by `_AnchorStrategySelector` (see contracts/anchor-strategy.md).

---

## 3. `_AnchorViewType` enum

Discriminator for which view type a snapshot was captured against. Used to short-circuit restore for out-of-scope views.

### Declaration site

`lib/smart_pagination/bloc/pagination_state.dart` (private).

### Schema

```dart
/// View type the anchor snapshot was captured against. Not exposed publicly.
/// Out-of-scope views (pageView, reorderableListView) cause the cubit to
/// short-circuit restore as a no-op.
enum _AnchorViewType {
  listView,
  gridView,
  customScrollView,
  staggeredGridView,
  pageView,            // out of scope (v1) — short-circuit
  reorderableListView, // out of scope (v1) — short-circuit
  custom,              // unknown view type — short-circuit
}
```

---

## 4. New private fields on `SmartPaginationCubit`

These fields live alongside the existing `_isFetching`, `_activeLoadMoreKey`, `_currentRequest`, `_generation`, etc.

### Declaration site

`lib/smart_pagination/bloc/pagination_cubit.dart` (in the field declarations block, around lines 161–230).

### Schema

```dart
class SmartPaginationCubit<T, R extends PaginationRequest> {
  // ... existing fields ...

  /// Pending anchor snapshot pushed by the widget layer's
  /// `captureAnchorBeforeLoadMore`. Consumed in the post-frame restore
  /// after a successful load-more append. Cleared on error, scope reset,
  /// or generation mismatch.
  ///
  /// Spec 004-scroll-anchor-preservation §4, data-model §1.
  _PendingScrollAnchor? _pendingAnchor;

  /// When `true`, `fetchPaginatedList` rejects load-more calls until a
  /// user-initiated `ScrollStartNotification` (with non-null `dragDetails`)
  /// is observed via `markUserScroll()`.
  ///
  /// Set to `true` immediately before `emit(isLoadingMore: true)` in
  /// `fetchPaginatedList`. Cleared by:
  ///  - `markUserScroll()` (the canonical clear path)
  ///  - load-more error path (`_fetch` finally on exception)
  ///  - scope reset (`_resetToInitial`, `refreshPaginatedList`, `dispose`)
  ///
  /// Spec 004-scroll-anchor-preservation §6.
  bool _suppressLoadMoreUntilUserScroll = false;

  /// Monotonic counter of observed user-scroll events. Incremented by
  /// every successful `markUserScroll()` call. Used by tests to assert
  /// "exactly one user gesture per allowed load-more". Not consumed by
  /// production logic.
  ///
  /// Spec 004-scroll-anchor-preservation §6.4 / Test infrastructure.
  int _lastUserScrollGeneration = 0;

  /// When `true`, `markUserScroll()` is a no-op. Set immediately before
  /// the post-frame restore is scheduled; cleared at the next frame
  /// boundary (`SchedulerBinding.instance.endOfFrame`). Defends against
  /// the unlikely case of a synthetic `ScrollStartNotification` with
  /// non-null `dragDetails` arriving during the restore.
  ///
  /// Spec 004-scroll-anchor-preservation §5, R5.
  bool _anchorRestoreInFlight = false;
}
```

### Field interactions

| Field | Set by | Cleared by |
|---|---|---|
| `_pendingAnchor` | `captureAnchorBeforeLoadMore` | post-frame restore consumer; scope reset; generation mismatch |
| `_suppressLoadMoreUntilUserScroll` | `fetchPaginatedList` accept path (step 11 in §7.1) | `markUserScroll`; load-more error; scope reset |
| `_lastUserScrollGeneration` | `markUserScroll` | (monotonic; never cleared) |
| `_anchorRestoreInFlight` | post-frame restore scheduler | `SchedulerBinding.instance.endOfFrame` after restore |

---

## 5. New private state on `_PaginateApiViewState`

### Declaration site

`lib/smart_pagination/widgets/paginate_api_view.dart` (in the state class, around lines 192–229).

### Schema

```dart
class _PaginateApiViewState<T, R extends PaginationRequest> {
  // ... existing state ...

  /// Most recent anchor snapshot computed from the observer controller.
  /// Refreshed on every observer `onObserve` callback (each meaningful
  /// viewport change). Pushed to the cubit via
  /// `cubit.captureAnchorBeforeLoadMore` immediately before each
  /// `fetchPaginatedList` invocation.
  ///
  /// Null when:
  ///  - no observer is attached (e.g., StaggeredGridView path uses a
  ///    fresh offset-only snapshot constructed at trigger time instead),
  ///  - the observer has not yet fired its first callback,
  ///  - the active view type is out-of-scope (pageView, reorderableListView,
  ///    or any reverse list).
  _PendingScrollAnchor? _lastObservedSnapshot;

  /// Subscription to the observer's onObserve stream / callback.
  /// Cancelled in `dispose`.
  /// Implementation note: `scrollview_observer` exposes onObserve as a
  /// callback parameter on the observer widget; the subscription
  /// abstraction here may be a simple closure-removal pattern rather
  /// than a `StreamSubscription`, depending on the package surface.
  Object? _observerSubscription;
}
```

### Lifecycle

```text
initState  : `_observerSubscription` is established in `_initializeObserver`.
              `_lastObservedSnapshot` starts as null.
on observe : every time the observer fires, the callback computes a fresh
              `_PendingScrollAnchor` describing the last fully-visible item
              before the spinner, replaces `_lastObservedSnapshot`.
on trigger : item builder evaluates `_shouldLoadMore == true`; in the
              post-frame callback, before `widget.fetchPaginatedList?.call()`,
              if `_lastObservedSnapshot != null` and the view is in scope,
              push the snapshot via `widget.cubit?.captureAnchorBeforeLoadMore`.
on dispose : cancel `_observerSubscription`; clear references.
```

---

## 6. State transitions across the lifecycle

The complete state-machine diagram for the four interacting fields.

```text
                              ┌─────────────────────────┐
                              │ Initial / scope-reset   │
                              │  _pendingAnchor = null  │
                              │  _suppressLoad… = false │
                              │  _anchorRestore… = false│
                              └────────────┬────────────┘
                                           │
                  user scrolls to bottom; _shouldLoadMore == true
                                           │
                                           ▼
                              ┌─────────────────────────┐
                              │ widget computes anchor  │
                              │ snapshot from observer  │
                              │ (or offset-delta for    │
                              │  StaggeredGridView)     │
                              └────────────┬────────────┘
                                           │
                          cubit.captureAnchorBeforeLoadMore(snapshot)
                                           │
                                           ▼
                              ┌─────────────────────────┐
                              │  _pendingAnchor = snap  │
                              └────────────┬────────────┘
                                           │
                            widget.fetchPaginatedList()
                                           │
                                           ▼
                              ┌─────────────────────────┐
                              │ guard chain passes      │
                              │ (incl. _suppress check) │
                              └────────────┬────────────┘
                                           │
                  set _isFetching, _activeLoadMoreKey,
                  _suppressLoadMoreUntilUserScroll = true,
                  emit(isLoadingMore: true), _fetch
                                           │
                                           ▼
                                       ┌───────┐
                                       │ await │
                                       └───┬───┘
                                ┌──────────┴──────────┐
                          success                    error
                                │                      │
                                ▼                      ▼
                      ┌──────────────────┐  ┌───────────────────────┐
                      │ emit Loaded with │  │ emit Loaded with      │
                      │ new items        │  │ loadMoreError         │
                      └────────┬─────────┘  └───────────┬───────────┘
                               │                        │
                  schedule post-frame:                  clear:
                  - _anchorRestoreIn… = true            - _isFetching = false
                  - perform jumpTo                      - _activeLoadMoreKey = null
                  - clear _pendingAnchor                - _suppress… = false
                  - on endOfFrame: clear                - _pendingAnchor = null
                    _anchorRestoreInFlight              - _anchorRestoreIn… = false
                  also clear:                                       │
                  - _isFetching = false                             │
                  - _activeLoadMoreKey = null                       │
                  - (_suppress… stays true)                         │
                               │                                    │
                               ▼                                    ▼
                    ┌─────────────────────────┐         ┌────────────────────────┐
                    │ Suspended state         │         │ Initial-like state     │
                    │ _suppress… = true       │         │ (suppress flag clear)  │
                    │ awaiting user scroll    │         │ allows retry           │
                    └────────────┬────────────┘         └────────────────────────┘
                                 │
            user-initiated ScrollStartNotification (dragDetails != null)
                                 │
                                 ▼
                          markUserScroll()
                                 │
                  if !_anchorRestoreInFlight:
                      _suppress… = false
                      _lastUserScrollGeneration++
                                 │
                                 ▼
                    ┌─────────────────────────┐
                    │ Re-armed; load-more     │
                    │ may fire again on next  │
                    │ threshold cross         │
                    └─────────────────────────┘
```

---

## 7. Constraints

| ID | Constraint |
|---|---|
| C1 | Only one `_pendingAnchor` may exist at a time. The widget pushes once per `fetchPaginatedList` invocation; double-push within a single in-flight fetch is silently overwritten (the latest snapshot wins). |
| C2 | `_pendingAnchor.generation` MUST equal `_generation` at consume time, or the snapshot is discarded and restore is a no-op. |
| C3 | `_suppressLoadMoreUntilUserScroll = true` MUST NOT be cleared by any programmatic scroll (`controller.jumpTo`, `controller.animateTo`, public scroll-navigation API). |
| C4 | `_anchorRestoreInFlight = true` MUST be cleared on the frame boundary AFTER the restore's `jumpTo` was issued, to allow real user gestures arriving during that frame to clear the suppression normally. |
| C5 | Out-of-scope view types (`_AnchorViewType.pageView`, `.reorderableListView`, or `reverse: true`) MUST cause the cubit to NOT set `_suppressLoadMoreUntilUserScroll = true` and to NOT consume `_pendingAnchor` (i.e., capture is a no-op for those types). |
| C6 | Externally-supplied `ScrollController`s MUST NOT be disposed by the package (preserved from existing behavior; the cubit only reads `controller.position` for offset-delta capture). |

---

## 8. What this data model does NOT include

| Excluded item | Reason |
|---|---|
| Public types | The feature is library-internal (Spec FR-009); no new public types. |
| Persistence | The anchor is ephemeral, valid only between capture and restore in a single fetch lifecycle. No need for serialisation. |
| New entities for `PaginationMeta` | The server's `hasNext` signal is unaffected by this feature; no new metadata flows. |
| New tracking for non-load-more mutations | Out of scope per Spec Q4 (append-on-load-more only). |
