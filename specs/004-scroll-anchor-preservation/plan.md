# Implementation Plan: Scroll Anchor Preservation

**Branch**: `004-scroll-anchor-preservation` | **Date**: 2026-05-05 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `specs/004-scroll-anchor-preservation/spec.md`

---

## Summary

Even with the load-more **request guard** from feature `003-load-more-guard` in place, fast scrolling near the bottom of a paginated list can still produce a chain of automatic page fetches. The request guard prevents *concurrent* duplicate fetches, but it cannot prevent *sequential* re-triggers: after each successful append, the viewport is still parked inside the load-more threshold zone, the layout settles, scroll notifications fire, and the guard re-arms — so the next fetch starts immediately, with no user input in between.

This feature closes that gap by capturing a **scroll anchor** (the last fully-visible item before the loading indicator) immediately before each load-more starts, then **restoring** the viewport relative to that anchor in a post-frame callback after the new page is appended, AND **suppressing** the load-more callback until a user-initiated `ScrollNotification` is observed. Anchor strategy is **hybrid**: key-based when `itemKeyBuilder` is supplied, index-based for finite-item builders, viewport-offset-delta for slivers. Scope is **append-on-load-more only**; reverse lists, `PageView`, and `ReorderableListView` are explicitly out of scope for v1 and fall through to existing behavior. Zero breaking changes to `.withProvider(...)` / `.withCubit(...)`; `itemKeyBuilder` remains optional and unchanged.

---

## Technical Context

**Language/Version**: Dart 3.x (null-safe), `>=3.10.0 <4.0.0`
**Primary Dependencies**: `flutter_bloc` (Cubit), `flutter` SDK, `scrollview_observer ^1.26.2` (already a dependency — provides `ListObserverController` / `GridObserverController` with `dispatchOnceObserve()` for visible-item capture and `jumpTo(index, alignment)` for precise restore), `flutter_staggered_grid_view ^0.7.0`
**Storage**: In-memory anchor snapshot fields on `SmartPaginationCubit` (no persistence)
**Testing**: `flutter_test` (`testWidgets` for scroll/anchor behavior), `bloc_test`, `mocktail`
**Target Platform**: Flutter (all platforms — pub-published library package)
**Project Type**: Dart/Flutter library
**Performance Goals**: Anchor capture and restore must each complete within a single frame budget (≤16 ms on target devices); zero perceivable jank during the append → restore sequence
**Constraints**:
- No breaking changes to `.withProvider(...)` / `.withCubit(...)` constructors (Constitution §II)
- `itemKeyBuilder` remains optional; consumers without it must get correct fallback behavior with no warnings (Spec FR-003a)
- The fix must not depend on debounce/throttle (Spec FR-010)
- Must compose with the existing `_isFetching` / `_activeLoadMoreKey` request guard from feature 003 (Spec Assumption — `003-load-more-guard` is in place)
- Must not take ownership of an externally-provided `ScrollController` (Spec FR-005)

---

## Constitution Check

*GATE: Evaluated before Phase 0 research. Re-checked after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Library-First Design | ✅ PASS | No new required parameters; anchor preservation is internal. New optional `preserveScrollAnchorOnAppend` flag is additive and defaults to `true` (matches FR-011's default-on requirement). |
| II. Backward Compatibility First | ✅ PASS | All existing constructors, providers, and request types unchanged. Existing call sites compile and run identically. README examples remain valid. |
| III. Cubit Owns Pagination State | ✅ PASS | Anchor snapshot lives on the cubit (`_pendingAnchor`, `_suppressLoadMoreUntilUserScroll`); the widget layer only reports visible-item ranges to the cubit and listens to it for restore commands. No UI state leaks into the provider layer. |
| IV. Stream Lifecycle Safety | ✅ PASS | No new streams or subscriptions introduced. The user-scroll detector reuses the existing `NotificationListener<ScrollNotification>` plumbing. |
| V. Stream Accumulation Rule | ✅ PASS | Append-on-load-more is the only mutation hooked; other mutations (refresh, filter, search) explicitly clear the anchor state via the existing scope-reset paths in `_resetToInitial` / `refreshPaginatedList` (FR-001a). |
| VI. Correctness Before Convenience | ✅ PASS | Restore is post-frame and gated on user-scroll re-arm — no silent chain-trigger possible (Spec Q3 / FR-004b). Anchor-not-found falls through to documented offset-delta fallback (FR-008), no silent jump to bottom. |
| VII. Explicit Duplicate Handling | ✅ PASS | Out of scope — this feature does not touch deduplication. |
| VIII. Testing Required | ✅ PASS | Phase A of the implementation breaks down required tests; coverage matches Spec FR-012 and the per-view-type matrix. |
| IX. Documentation Required | ✅ PASS | Phase H updates README, CHANGELOG, dartdoc per Spec FR-013. |
| X. Bilingual Clarification Questions Rule | ✅ PASS | Already satisfied by `/speckit-clarify` session. |

**Gate decision**: No violations. No items in Complexity Tracking required.

---

## Project Structure

### Documentation (this feature)

```text
specs/004-scroll-anchor-preservation/
├── plan.md                       ← this file
├── research.md                   ← Phase 0 output
├── data-model.md                 ← Phase 1 output
├── quickstart.md                 ← Phase 1 output
├── contracts/                    ← Phase 1 output
│   ├── anchor-strategy.md
│   ├── view-type-matrix.md
│   └── public-api-surface.md
├── checklists/
│   └── requirements.md           ← from /speckit-specify
└── tasks.md                      ← Phase 2 output (/speckit-tasks)
```

### Source Code (repository root)

```text
lib/
├── pagination.dart                                    # main barrel export
├── smart_pagination/
│   ├── bloc/
│   │   ├── pagination_cubit.dart                      # PRIMARY CHANGE FILE
│   │   │                                              #   - new fields: _pendingAnchor,
│   │   │                                              #     _suppressLoadMoreUntilUserScroll,
│   │   │                                              #     _lastUserScrollGeneration
│   │   │                                              #   - hooks in fetchPaginatedList()
│   │   │                                              #     and the load-more append site
│   │   └── pagination_state.dart                      # internal entity additions only
│   ├── controller/
│   │   └── controller.dart                            # no public API change
│   └── widgets/
│       ├── paginate_api_view.dart                     # PRIMARY CHANGE FILE
│       │                                              #   - capture-before-fetch hook
│       │                                              #   - post-frame restore hook
│       │                                              #   - user-scroll re-arm via
│       │                                              #     NotificationListener
│       ├── smart_pagination_list_view.dart            # no change (passes through)
│       ├── smart_pagination_grid_view.dart            # no change
│       ├── smart_pagination_staggered_grid_view.dart  # no change
│       └── (others)                                   # no change
test/
├── scroll_anchor_capture_test.dart                    # NEW
├── scroll_anchor_restore_test.dart                    # NEW
├── scroll_anchor_suppression_test.dart                # NEW
├── scroll_anchor_view_type_matrix_test.dart           # NEW (ListView, GridView, slivers, staggered)
├── scroll_anchor_compatibility_test.dart              # NEW (.withProvider / .withCubit, external ScrollController)
└── scroll_anchor_fallthrough_test.dart                # NEW (reverse, PageView, Reorderable: no-op proof)
```

**Structure Decision**: Single-package Flutter library. No new top-level directories. All changes localised to `lib/smart_pagination/bloc/pagination_cubit.dart` and `lib/smart_pagination/widgets/paginate_api_view.dart`. New tests live alongside existing tests in `test/`, named with the `scroll_anchor_*` prefix to group them.

---

## Complexity Tracking

No Constitution violations requiring justification.

---

## Section 1 — Executive Summary

### Why request guards alone are not enough

Feature `003-load-more-guard` solved the *concurrent duplicate request* class of bugs:

- `_isFetching` flag is set before `emit(isLoadingMore: true)`, closing the synchronous gap.
- `_activeLoadMoreKey` rejects same-page double calls.
- Scroll-trigger calls in the item builder are wrapped in `SchedulerBinding.addPostFrameCallback` so multiple item builders firing in one build pass collapse to a single call.

These fixes guarantee **at most one in-flight load-more at a time**. They do not — and cannot — guarantee that *consecutive* load-more calls require user input between them. The current loop after `003-load-more-guard`:

1. User scrolls to the bottom; threshold crossed; `fetchPaginatedList()` called once. ✅ guarded.
2. Cubit emits `isLoadingMore: true`, fetches page N+1, appends items, emits `isLoadingMore: false`.
3. The viewport is now positioned just above the loading indicator. The new items extend the list downward, but the viewport's `pixels` did not move — so the viewport is now sitting at exactly the same offset, which is **still inside the load-more trigger zone** (`currentIndex >= _items.length - invisibleItemsThreshold`) for whatever new bottom items are now within the threshold window.
4. The framework rebuilds (because `loadedState` changed). The item builder near the new bottom evaluates `_shouldLoadMore` and finds it true. Post-frame callback fires `fetchPaginatedList()`.
5. `_isFetching` is `false` (the previous fetch completed), `_activeLoadMoreKey` is `null` (cleared on completion), `loadedState.isLoadingMore` is `false`. All guards say "go". A new fetch starts.
6. Goto 2.

This loop terminates only when (a) the server returns an empty/short page and `hasReachedEnd = true` flips, (b) an error fires, or (c) the user happens to scroll back up far enough to leave the threshold zone. Until one of those, the package burns network and CPU and the user sees a runaway scroll.

### Why scroll anchor preservation is required

The chain in step 3 above breaks if and only if **either**:

- (a) The viewport's `pixels` are corrected after append so it is no longer inside the threshold zone — i.e., the viewport "follows" the user's pre-append focus item rather than its absolute pixel position, OR
- (b) The load-more callback is suppressed until we observe a user-driven scroll event after the append.

Anchor preservation does (a). User-scroll re-arm does (b). Spec Q3 selected **both**, because (a) alone can be defeated by late layout settle (image loads, async height resolves) which moves the viewport inside the threshold zone again without user input. Doing (a) gives the right *visual* outcome; doing (b) gives the right *correctness* outcome. Both together produce: "exactly one load-more per intentional scroll-to-end gesture", which is Spec SC-002.

---

## Section 2 — Current Scroll Behavior Review

### 2.1 Where scroll notifications are handled

| View type | Trigger surface | File:line |
|-----------|-----------------|-----------|
| `ListView` (`SliverList`) | `_shouldLoadMore(itemIndex)` called from inside `SliverChildBuilderDelegate.builder` for each item rendered | `paginate_api_view.dart:685` |
| `ListView` animated (`SliverAnimatedList`) | Same, called from `itemBuilder` | `paginate_api_view.dart:645` |
| `GridView` (`SliverGrid`) | Same, called from `SliverChildBuilderDelegate.builder` | `paginate_api_view.dart:474` |
| `GridView` animated (`SliverAnimatedGrid`) | Same | `paginate_api_view.dart:443` |
| `PageView` | `if (index >= _items.length)` in `SliverChildBuilderDelegate.builder` | `paginate_api_view.dart:833` |
| `StaggeredGridView` | `NotificationListener<ScrollNotification>` with 80% scroll threshold | `paginate_api_view.dart:864` |
| `ReorderableListView` | None — does not trigger load-more in current code (no `_shouldLoadMore` call) | `paginate_api_view.dart:770` |

Each trigger site already wraps the `widget.fetchPaginatedList?.call()` in `SchedulerBinding.addPostFrameCallback` (per `003-load-more-guard` §5.1).

### 2.2 How the invisible-items threshold is calculated

```dart
// lib/smart_pagination/widgets/paginate_api_view.dart:392-398
bool _shouldLoadMore(int currentIndex) {
  if (widget.loadedState.hasReachedEnd || widget.loadedState.isLoadingMore) {
    return false;
  }
  return currentIndex >= _items.length - widget.invisibleItemsThreshold;
}
```

`invisibleItemsThreshold` defaults to `3` and is configurable per-widget. The check fires whenever the rendered item index is within the last `threshold` items of the list. **Crucially, this is read against `widget.loadedState`**, the build-time snapshot — which is the same snapshot the post-frame callback runs against.

For `StaggeredGridView` the threshold is fixed at 80% of `maxScrollExtent` (`paginate_api_view.dart:871`).

### 2.3 How load-more is triggered

Trigger paths:

1. Item builder in supported sliver views → `addPostFrameCallback(fetchPaginatedList)`.
2. `StaggeredGridView` notification listener → `addPostFrameCallback(fetchPaginatedList)`.
3. `PageView` overflow index → `addPostFrameCallback(fetchPaginatedList)`.

`fetchPaginatedList()` enters the cubit at `pagination_cubit.dart:741`, runs the guard chain (`_isFetching`, `_activeLoadMoreKey`, error-retry, end-of-list, `isLoadingMore`), and on pass calls `_fetch(reset: false)` which performs the await and emits `SmartPaginationLoaded` with `isLoadingMore: false` plus the new items.

### 2.4 How appended items affect scroll metrics

When a new page is appended:

- `_items.length` increases by N.
- `maxScrollExtent` increases by approximately `N × averageItemExtent`.
- `pixels` (current scroll offset) stays the same in absolute pixels.
- `pixels / maxScrollExtent` decreases (the user appears to be "less far down" the new, longer list).

The framework rebuilds the affected slivers. Items that were previously in-viewport remain in-viewport at the same absolute pixel offset *if no other layout change happens*. However:

- If the new bottom is now within `invisibleItemsThreshold` of the new last-visible index, `_shouldLoadMore` fires true again immediately on rebuild.
- Variable-height items, late image loads, or `keepAlive: false` items that drop off-screen and re-resolve cause `pixels` to drift after the post-frame, which can re-cross the threshold even if the immediate post-frame state was clear.

### 2.5 How the scroll controller is managed

```dart
// paginate_api_view.dart:194, 211-212
ScrollController? _internalScrollController;
ScrollController get _effectiveScrollController =>
    widget.scrollController ?? (_internalScrollController ??= ScrollController());
```

The widget falls through to a consumer-supplied `ScrollController` if provided, otherwise lazily allocates one. The same `_effectiveScrollController` is also used by the `scrollview_observer` package (`ListObserverController(controller: _effectiveScrollController)` at line 238) — so the observer and the consumer's listeners share one controller.

`dispose()` only disposes the controller it owns (`_internalScrollController?.dispose()` at line 356); a consumer-supplied controller is not touched.

### 2.6 How external scroll controllers are supported

Already covered above: when `widget.scrollController` is non-null, the package uses it directly and never disposes it. Consumer-attached `addListener()` callbacks continue to fire because they live on the same controller instance the package's machinery is reading.

### 2.7 How custom slivers and animated list updates affect scroll position

- `SliverAnimatedList` / `SliverAnimatedGrid` are used when `itemKeyBuilder` is provided. New items are inserted with a fade+size animation (default 300 ms). During the animation, items grow from zero height to full height, so `maxScrollExtent` grows incrementally rather than instantly. This makes the immediate post-frame scroll position **more** stable visually, but the animation duration is a window during which the scroll metrics are still settling.
- `findChildIndexCallback` is wired up when `itemKeyBuilder` is non-null (`paginate_api_view.dart:488`, `:708`). This is what allows Flutter to identify the same logical item across rebuilds even when its index changes — exactly the property the key-based anchor strategy will rely on.
- Custom slivers (consumer-supplied via `header` / `footer` slivers in the `CustomScrollView`) are passive containers; they don't participate in the load-more trigger and don't influence anchor logic.

### 2.8 Existing observer integration (key lever for clean restore)

The `scrollview_observer` package is **already integrated** end-to-end:

- `_listObserverController = ListObserverController(controller: _effectiveScrollController)` at `paginate_api_view.dart:238`.
- Attached to the cubit at `paginate_api_view.dart:242`: `widget.cubit?.attachListObserverController(...)`.
- The cubit holds it as `_listObserverController` (and `_gridObserverController`) at `pagination_cubit.dart:2352, 2355`.
- The cubit already calls `_listObserverController!.animateTo(index, alignment)` and `.jumpTo(index, alignment)` at `pagination_cubit.dart:2466, 2542`.
- The observer's `dispatchOnceObserve()` returns the currently-visible items with their first/last indices, top/bottom pixel offsets, and per-item display percent — exactly the data needed to identify "last fully-visible item before the spinner".
- The observer's `jumpTo(index: anchorIndex, alignment: 1.0)` will land that index at the bottom of the viewport — exactly the position we captured it at.

This means the implementation reuses the existing observer plumbing and does not introduce a new scroll-watching mechanism.

---

## Section 3 — Root Cause Analysis

| ID | Root Cause | Location |
|----|-----------|----------|
| RC-1 | After append, the viewport's absolute `pixels` does not change, so it remains at the same on-screen position relative to the **bottom-of-list** trigger zone. | `paginate_api_view.dart:392` (`_shouldLoadMore`) |
| RC-2 | The cubit clears `_isFetching` and `_activeLoadMoreKey` in `finally` at the end of `_fetch` (`pagination_cubit.dart:1095-1096`), with no carry-over guard against immediate re-fetch. The threshold-based widget layer is the only thing that decides whether the next call goes through. | `pagination_cubit.dart:1095-1096` |
| RC-3 | `_shouldLoadMore` only checks `hasReachedEnd` and `isLoadingMore`. It has no notion of "this fetch was just satisfied; wait for user input before allowing another". | `paginate_api_view.dart:392-398` |
| RC-4 | The post-frame callback after rebuild fires `fetchPaginatedList()` from the new last-visible item's render pass. There is no signal carried from the previous load-more completion that says "the trigger zone you're sitting in was just satisfied". | `paginate_api_view.dart:651, 480, 691` (per-view trigger sites) |
| RC-5 | Variable-height items (especially with async image resolution) settle their final height **after** the immediate post-frame, which causes `pixels` to drift inside the threshold window without any user input. The current code has no path to discard scroll notifications attributable to layout settle versus user gesture. | `paginate_api_view.dart` (no current handler) |
| RC-6 | The package never captures or restores the user's anchor item across the append. Whatever the user was reading scrolls down by N rows in real screen terms (because new items appended below pushed the visual content up... no, wait — new items appended below **don't** push the visual content; they extend the list downward. The user's reading focus stays at the same on-screen pixel, but that pixel is now a different item, because the *list* of items below the focus grew. The reading focus is the same visual spot; the "last item" that this spot is close to is no longer item N but item N+M). The threshold continues to evaluate against the absolute `_items.length`, so the user is always within `threshold` of the new last item until a fetch literally overshoots the visible window. | (Conceptual) |

### Why the `003-load-more-guard` fixes do not catch this

| `003` Mechanism | Catches this? | Why / why not |
|---|---|---|
| `_isFetching` flag (synchronous) | ❌ No | The chained calls are not concurrent — they are sequential, with the previous fetch fully complete before the next one starts. `_isFetching` is `false` between them. |
| `_activeLoadMoreKey` per-page rejection | ❌ No | Each fetch in the chain advances `_currentRequest.page`, so each new call has a different page key. The guard correctly allows them all. |
| Post-frame collapse in item builder | ❌ No | This collapses calls within a *single build pass* into one. It does nothing about calls across *successive* build passes after `loadedState` changes. |
| End-of-list (`hasReachedEnd`) | Partially | Only stops the chain when the server cooperates by returning a short or empty page. For unbounded test data or "always full page" providers, the chain never stops on its own. |

---

## Section 4 — Anchor Capture Strategy

**Decision (per Spec Q1, Q2)**: hybrid strategy with selection in this order, anchored on the **last fully-visible item before the loading indicator**:

| Order | Strategy | Condition for selection |
|---|---|---|
| 1 | **Key-based** | `widget.itemKeyBuilder != null`. Capture `key = itemKeyBuilder(item, index)`. Restore via `findChildIndexCallback` to look up the new index of the same key, then `_listObserverController.jumpTo(index: newIndex, alignment: 1.0)`. |
| 2 | **Index-based** | `itemKeyBuilder == null` AND active view is `ListView` / `GridView` / `SliverList` / `SliverGrid` (finite-item builders with stable index addressing). Capture `anchorIndex`. Restore via `_listObserverController.jumpTo(index: anchorIndex, alignment: 1.0)`. Index does not change in append-only scope (FR-001a), so this is safe. |
| 3 | **Offset-delta** | Active view is `StaggeredGridView` (no `ListObserverController` integration), or the observer's `dispatchOnceObserve` returned no usable result. Capture `pixelsBefore = controller.position.pixels` and `extentBefore = controller.position.maxScrollExtent`. After post-frame, restore via `controller.jumpTo(pixelsBefore + (extentAfter - extentBefore))` — but in append-only scope where new items only extend `maxScrollExtent` downward and the user's existing offset is preserved, the *delta* is zero and the simple `pixels` value is already correct; the delta term only differs from zero if list items above the anchor changed, which append-only scope forbids. |

### 4.1 Identifying "last fully-visible item before the loading indicator"

For `ListView` / `GridView` (observer attached):

```text
1. Call _listObserverController.dispatchOnceObserve(isForce: true).
2. The observer returns ListViewObserveModel with displayingChildModelList: List<ItemModel>.
3. Filter to items where displayPercentage >= 1.0 (fully visible).
4. From that filtered list, take the one with the highest index.
5. That is the anchor item; capture its index AND its key (if itemKeyBuilder is provided).
   Also capture the item's leadingEdge offset for fidelity validation.
```

The "loading indicator" lives in a separate sliver (`_buildBottomLoaderSliver`, `paginate_api_view.dart:590`), so it is **not** part of the observer's item-sliver model. The observer naturally only sees the items sliver, which means filtering on `displayPercentage >= 1.0` automatically excludes the spinner.

For `StaggeredGridView`: there is no observer controller; fall through to offset-delta.

### 4.2 Capture timing

Capture happens **at the start of `fetchPaginatedList()`**, immediately after the `003-load-more-guard` guard chain has accepted the call but **before** `emit(isLoadingMore: true)`. This is the latest moment when the viewport is still in the pre-append state.

The cubit cannot directly call `dispatchOnceObserve()` from the request guard path (the call is async-ish — it schedules a frame callback in some configurations). The widget layer captures the snapshot synchronously off the observer and passes it to the cubit via a new internal call **before** the widget's post-frame `fetchPaginatedList` invocation completes the cubit-side guard chain.

**Sequence (decided)**:

1. Item builder evaluates `_shouldLoadMore(index) == true`.
2. Inside the existing `addPostFrameCallback` block, before `widget.fetchPaginatedList?.call()`:
   - Compute the anchor synchronously from the observer's last-known visible-items model (the observer maintains an in-memory snapshot updated on every scroll).
   - Pass it to the cubit via `widget.cubit!.captureAnchorBeforeLoadMore(snapshot)`.
3. Then call `widget.fetchPaginatedList?.call()` as today.

If the cubit is not exposed to the widget (legacy `.withProvider(...)` path where the widget sees only `loadedState`), the capture is a no-op and the offset-delta fallback takes over inside the cubit by reading `_effectiveScrollController.position` directly from a registered `ScrollController` reference (see Section 11.2 for the controller-registration mechanism).

### 4.3 Captured snapshot fields

See `data-model.md` §1 for the full schema. Summary:

```text
PendingScrollAnchor {
  AnchorStrategy strategy;        // key | index | offset
  Object? key;                    // populated when strategy == key
  int? index;                     // populated when strategy in {key, index}
  double? leadingEdgeOffset;      // px from viewport top of anchor's leading edge at capture
  double? pixelsBefore;           // controller.position.pixels at capture
  double? extentBefore;           // controller.position.maxScrollExtent at capture
  int generation;                 // _generation snapshot — invalidated on scope reset
  int loadMoreKey;                // bound to _activeLoadMoreKey for cross-check
}
```

### 4.4 Strategies the spec lists but the plan does NOT recommend

| Considered | Rejected because |
|---|---|
| **First visible item** | User's eyes are at the bottom when load-more fires; pinning the top item still allows the visual focus area to drift. Weaker bug-fix value. (Spec Q2 evaluation.) |
| **Center visible item** | Hard to identify deterministically with variable-height items and slivers; rounding/partial-visibility issues; marginal benefit since user is rarely focused at center. (Spec Q2 evaluation.) |
| **Item at current scroll focus point** | "Focus point" is undefined for free-scrolling lists; collapses to either first-visible or center-visible, both rejected. |
| **Index-based as default** | Fragile if `itemKeyBuilder` is provided AND items can be reordered/inserted mid-list elsewhere; key-based is strictly safer when keys are available. (Spec Q1.) |

---

## Section 5 — Anchor Restore Strategy

**Decision (per Spec Q3)**: post-frame restore via `WidgetsBinding.instance.addPostFrameCallback`, using the strategy that was captured.

### 5.1 Restore mechanics by strategy

| Captured strategy | Restore mechanic |
|---|---|
| **Key-based** | After post-frame: scan `_items` to find the index where `itemKeyBuilder(_items[i], i) == anchor.key` (linear scan; for typical page sizes ≤200 this is O(n) once per append, negligible). Call `_listObserverController.jumpTo(index: foundIndex, alignment: 1.0)` (or `_gridObserverController.jumpTo(...)` for grids). The `alignment: 1.0` parameter pins the **bottom edge** of the item to the bottom of the viewport — which is exactly the "last fully-visible item before the spinner" position the user was at. |
| **Index-based** | After post-frame: in append-only scope (FR-001a), the captured `index` is still valid (no items were removed or inserted before it). Call `_listObserverController.jumpTo(index: anchor.index, alignment: 1.0)` directly. |
| **Offset-delta** | After post-frame: read `controller.position.pixels` (it should still be `pixelsBefore` since append-only doesn't move the viewport) and verify. If the position has drifted (e.g., `StaggeredGridView` with async image loads adjusted layout), compute `target = pixelsBefore + max(0, controller.position.maxScrollExtent - extentBefore - viewportHeight + threshold)` — but in practice for append-only this simplifies to `controller.jumpTo(pixelsBefore)` because the new items are all *below* the user's position. |

### 5.2 Why `_listObserverController.jumpTo` instead of `controller.jumpTo`

The `scrollview_observer` package's `jumpTo(index, alignment)` knows how to compute the exact pixel offset needed to position a given item index at a given alignment within the viewport, **including for variable-height items**, because it inspects the rendered item models live. A naïve `controller.jumpTo(pixelsBefore)` does not — it just sets the pixel offset, which may now point to a different visual position if intervening items have settled to different heights.

For variable-height correctness (Spec FR-012(b) test target), the observer-driven jump is the right tool.

### 5.3 Avoiding visible jump or flicker

The post-frame callback fires after the framework has laid out the new items but before the next paint. The `jumpTo` call sets the new pixel offset before that paint. The user sees a single coherent frame: new items appended, viewport at the corrected position. No intermediate state where the viewport is at the wrong offset is ever painted.

For animated lists (`SliverAnimatedList` with `itemKeyBuilder`), the animation grows new items from zero height. The restore happens *after* the rebuild but *before* the animation begins — so the captured anchor's position is correct at restore time, and the animation grows the new items below the restored anchor, which is the visually correct outcome.

### 5.4 What if the anchor item is gone at restore time

Only possible if a concurrent mutation (refresh, filter, search) interleaves with the load-more between capture and restore. In that case, the scope-reset path (`_resetToInitial` / `refreshPaginatedList`) bumps `_generation`. At restore time, the cubit checks `_pendingAnchor.generation == _generation`. Mismatch → discard the anchor entirely; do not call `jumpTo`; let the consumer's refresh/filter behavior take over (FR-008).

For the rarer case where the captured anchor's key/index was somehow removed mid-fetch without a scope reset (e.g., a mid-list delete triggered by external logic — out of scope for this feature but defensive), the lookup returns `null`. The cubit falls back to offset-delta restore, which is correct because no items were appended at the time of restore (the fetch failed or was discarded).

---

## Section 6 — Trigger Re-entry Prevention

**Decision (per Spec Q3 / FR-004b)**: keep the load-more callback **suppressed** between the start of a load-more fetch and the next user-initiated `ScrollNotification` observed after restore.

### 6.1 Suppression flag

```text
SmartPaginationCubit._suppressLoadMoreUntilUserScroll: bool = false
```

State transitions:

| Event | Flag value after event |
|---|---|
| `fetchPaginatedList()` accepts a load-more (after all guards pass, before `emit`) | `true` |
| Scope reset (`_resetToInitial`, `refreshPaginatedList`, dispose) | `false` (or rather: cleared) |
| User-initiated `ScrollNotification` received | `false` |
| Programmatic `jumpTo` / `animateTo` from anchor restore | (does NOT clear) |
| Programmatic `jumpTo` / `animateTo` from public scroll-navigation API (`animateToIndex` etc.) | (does NOT clear; consumer is in control) |

### 6.2 How `fetchPaginatedList` honors the flag

The guard chain in `fetchPaginatedList` already has 8 ordered checks. Insert the new check **between** the `_activeLoadMoreKey` check and the `isLoadingMore` check:

```text
1. _isFetching
2. error-retry
3. data-age
4. initial-state → refresh
5. _hasReachedEnd
6. _activeLoadMoreKey == loadMoreKey
6b. ─── NEW ───  _suppressLoadMoreUntilUserScroll → return
7. isLoadingMore
8. set _isFetching, _activeLoadMoreKey, capture anchor (already done by widget layer in step 4.2.2), emit
```

A load-more call while suppressed is silently dropped. No state change, no provider call.

### 6.3 Detecting "user-initiated" scroll vs. programmatic

`ScrollNotification.dragDetails != null` is the canonical signal in Flutter that a user gesture is driving the scroll. More robust:

```text
A scroll notification is treated as "user-initiated" if any of:
  - notification is ScrollStartNotification AND notification.dragDetails != null
  - notification is ScrollUpdateNotification AND notification.dragDetails != null
  - notification.context.findAncestorStateOfType<ScrollableState>().position.activity is BallisticScrollActivity
    AND that activity was started from a user drag (the framework tracks this internally;
    expose via wrapping NotificationListener)
```

For v1, the simpler check is sufficient: `notification is ScrollStartNotification && notification.dragDetails != null`. This fires on the *first* drag-driven scroll after the suppression begins; it does not fire for `jumpTo`/`animateTo` calls (which produce no `dragDetails`). False negatives (e.g., a fling from an earlier user drag continuing past the restore) are acceptable — they only delay the next load-more by one user touch.

### 6.4 Where the user-scroll detector lives

Wrap the existing `CustomScrollView` / `SingleChildScrollView` in each builder (`_buildListView`, `_buildGridView`, `_buildStaggeredGridView`) with a `NotificationListener<ScrollNotification>`. (`StaggeredGridView` already has one; the others gain a new outer listener that does NOT consume the notification, so existing listeners further out continue to fire.)

```dart
NotificationListener<ScrollNotification>(
  onNotification: (n) {
    if (n is ScrollStartNotification && n.dragDetails != null) {
      widget.cubit?.markUserScroll();
    }
    return false; // do not consume
  },
  child: <existing scrollview>,
)
```

`SmartPaginationCubit.markUserScroll()` clears `_suppressLoadMoreUntilUserScroll` if set.

### 6.5 What this is NOT

| Anti-pattern | Why we don't do it |
|---|---|
| Permanent disable of load-more | The flag clears on the next user scroll; the package always remains capable of fetching more. |
| Time-based suppression window | Spec Q3 explicitly rejected this — duration tuning is fragile across devices. |
| Throttling/debouncing of `fetchPaginatedList` | Spec FR-010 forbids this as a sole mitigation. |
| Hiding the load-more indicator | Spec FR-010 forbids this. |
| `lastLoadMoreScrollOffset` hysteresis (preventing trigger at the same pixel) | Already considered and rejected in `003-load-more-guard` §5.3 (state-guard-only was selected there). User-scroll re-arm is the strictly stronger replacement. |

---

## Section 7 — Interaction with Request Guard (`003-load-more-guard`)

The two features compose into a four-layer defense:

| Layer | Source feature | What it prevents |
|---|---|---|
| **L1**: Per-call collapse via `addPostFrameCallback` in item builder | `003-load-more-guard` §5.1 | Multiple item builders in one build pass → one call |
| **L2**: `_isFetching` synchronous flag set before `emit(isLoadingMore: true)` | `003-load-more-guard` §4.2 | Concurrent calls within the same async-microtask window |
| **L3**: `_activeLoadMoreKey` per-page rejection | `003-load-more-guard` §4.1 | Same-page double fetch (e.g., after `cancelOngoingRequest()` clears `_isFetching`) |
| **L4**: Anchor restore + `_suppressLoadMoreUntilUserScroll` (this feature) | `004-scroll-anchor-preservation` | Sequential auto-chained fetches across successive build passes; layout-settle re-triggers; runaway scroll |
| **L0**: `hasReachedEnd` | Both | Stops fetching when the server signals end |

L1–L3 guarantee at most one in-flight fetch. L4 guarantees that the *next* fetch requires user input. L0 is the eventual termination condition. None of L1–L4 is sufficient alone; all four together fully eliminate the chained-load-more behavior described in Spec User Story 1.

### 7.1 Order of evaluation in `fetchPaginatedList`

```text
fetchPaginatedList() entry guards (revised, in order):
  1. _isFetching                           [003 L2]
  2. error-retry strategy                   [pre-existing]
  3. data-age                               [pre-existing]
  4. initial-state → refresh                [pre-existing]
  5. _hasReachedEnd                         [L0]
  6. _activeLoadMoreKey == loadMoreKey      [003 L3]
  7. _suppressLoadMoreUntilUserScroll       [004 L4 — NEW]
  8. isLoadingMore                          [pre-existing]
  9. set _isFetching = true                 [003 L2]
 10. set _activeLoadMoreKey = loadMoreKey   [003 L3]
 11. set _suppressLoadMoreUntilUserScroll = true   [004 L4 — NEW]
 12. capture _pendingAnchor                 [004 L4 — NEW; consumes the snapshot
                                              the widget layer pushed via
                                              captureAnchorBeforeLoadMore()]
 13. emit(isLoadingMore: true)              [pre-existing]
 14. _fetch(reset: false)                   [pre-existing]
```

### 7.2 Order of evaluation on fetch completion

```text
_fetch finally / success path:
  1. emit SmartPaginationLoaded with new items + isLoadingMore: false
  2. clear _isFetching = false                          [003]
  3. clear _activeLoadMoreKey = null                    [003]
  4. (do NOT clear _suppressLoadMoreUntilUserScroll)   [004 — only user-scroll clears it]
  5. schedule WidgetsBinding.instance.addPostFrameCallback:
       restoreScrollAnchor(_pendingAnchor)              [004]
       _pendingAnchor = null                            [004]
```

### 7.3 Error path

```text
_fetch finally / error path:
  1. emit SmartPaginationLoaded with loadMoreError + isLoadingMore: false
  2. clear _isFetching = false                          [003]
  3. clear _activeLoadMoreKey = null                    [003]
  4. clear _suppressLoadMoreUntilUserScroll = false    [004 — error path: re-arm load-more so
                                                         retry can proceed without forcing the user
                                                         to scroll. Aligns with FR-004 only blocking
                                                         "after a successful append-and-restore".]
  5. discard _pendingAnchor (no items appended → nothing to restore against)
```

This keeps the existing error-retry behavior of `003-load-more-guard` unchanged.

### 7.4 Scope-reset path

```text
_resetToInitial / refreshPaginatedList:
  1. existing scope-reset logic [003 + earlier]
  2. clear _suppressLoadMoreUntilUserScroll = false    [004]
  3. discard _pendingAnchor                             [004]
```

---

## Section 8 — View-Type Support Plan

Per Spec Q5 / FR-007:

| View type | Support level | Anchor strategy used | Restore mechanism | Suppression applies |
|---|---|---|---|---|
| `ListView` (`SliverList`) | **Full** | key (if `itemKeyBuilder`) → index | `_listObserverController.jumpTo(index, alignment: 1.0)` | Yes |
| `ListView` animated (`SliverAnimatedList`) | **Full** | key (always — animated requires `itemKeyBuilder`) | `_listObserverController.jumpTo(...)` | Yes |
| `GridView` (`SliverGrid`) | **Full** | key (if `itemKeyBuilder`) → index | `_gridObserverController.jumpTo(index, alignment: 1.0)` | Yes |
| `GridView` animated (`SliverAnimatedGrid`) | **Full** | key (always) | `_gridObserverController.jumpTo(...)` | Yes |
| `CustomScrollView` / sliver variants | **Full** | key (if `itemKeyBuilder`) → index → offset-delta | observer `jumpTo` if observer attached, else `controller.jumpTo(pixelsBefore)` | Yes |
| `StaggeredGridView` | **Full (offset-delta)** | offset-delta only (no observer integration in current code) | `controller.jumpTo(pixelsBefore)` (append-only scope guarantees correctness) | Yes |
| `PageView` | **Out of scope (v1)** | — | No-op; falls through to existing behavior | No |
| `ReorderableListView` | **Out of scope (v1)** | — | No-op; falls through to existing behavior | No |
| Reverse lists (`reverse: true`) on any of the above | **Out of scope (v1)** | — | No-op; falls through to existing behavior. Detected via `widget.reverse == true`. | No |

### 8.1 How "out of scope" is implemented

In the cubit's `captureAnchorBeforeLoadMore(snapshot)` entry point, if the widget passes `snapshot.viewType` as one of the out-of-scope types (or `snapshot.reverse == true`), the cubit ignores the snapshot and does NOT set `_suppressLoadMoreUntilUserScroll = true`. The result: existing behavior is preserved end-to-end on those views.

### 8.2 README support matrix

The README's new "Scroll Anchor Preservation" section (Phase H) reproduces the table above so consumers can read at a glance which views give which guarantees.

---

## Section 9 — Reverse List Support

**Decision (per Spec Q5)**: reverse lists are **out of scope for v1**. The package detects `widget.reverse == true` at the widget layer and does not call `captureAnchorBeforeLoadMore`. The cubit's anchor logic is therefore never invoked for reverse lists; existing behavior (whatever it produces) is preserved.

### 9.1 Why reverse is harder than it looks

- "Last fully-visible item before the loading indicator" inverts to "first fully-visible item after the leading indicator" in a reversed list.
- The viewport's pixels math inverts.
- Chat-style apps prepend older items at the *visual top* of the viewport while the user reads at the visual bottom; the threshold logic for triggering load-older is symmetric but mirror-imaged.
- Both alignment math and the user-scroll detector need separate edge cases.

These are not insurmountable, but they double the test matrix for an edge case (chat UIs) that is not the bug being fixed in this feature. v1 keeps the scope clean.

### 9.2 Documented future work

The README's support matrix lists reverse lists with a footnote: *"Out of scope for v1. Tracked for future work; in the meantime, reverse-direction lists fall through to existing behavior."*

---

## Section 10 — Variable Height Items

### 10.1 Why index-based offset alone is unsafe with variable heights

A naïve "remember the pixel offset, then `controller.jumpTo(pixelsBefore)`" approach fails when items have variable heights AND items have been laid out lazily. After the post-frame, an item that was at pixel offset 1200 might now be at offset 1180 (because an image above it loaded and added 20 px) — `jumpTo(1200)` lands you 20 px below where you wanted to be. For a normally-paced layout settle this is invisible (≤5 px); for a list with many late-loading images it can be 50–100 px and visible as a "creep".

### 10.2 Why key-based anchors via the observer are safe

`scrollview_observer.jumpTo(index, alignment)` queries the live render-tree state at jump time — it computes the new pixel offset from the *current* layout of item N, not from a stale captured pixel value. Late image loads and height resolutions before the jump are absorbed into the computation. Late loads *after* the jump still cause minor drift, but only in the direction of the new content (downward), not toward the trigger zone — so they do not chain-trigger.

### 10.3 When key-based anchors are required vs. recommended

Per Spec Q1: `itemKeyBuilder` is **optional, never required**. The plan delivers correct behavior at three levels:

| Situation | Result |
|---|---|
| `itemKeyBuilder` is provided AND items have variable heights | Best fidelity. Anchor is restored exactly. |
| `itemKeyBuilder` is NOT provided AND items have variable heights AND view is `ListView`/`GridView` (observer attached) | Index-based restore via observer's `jumpTo(index, alignment)`. Still correct: the observer queries live layout. Fidelity is `±0.5 row` (row alignment is exact; sub-pixel offset within the row depends on the alignment param). |
| `itemKeyBuilder` is NOT provided AND view is `StaggeredGridView` (no observer) | Offset-delta restore. Append-only scope guarantees the user's `pixels` value is still correct because no items were inserted above the user's current position. |
| `itemKeyBuilder` is NOT provided AND items have variable heights AND late-loading content (images, measured text) above the anchor | Edge case. Index-based restore via observer is still correct because the observer accounts for live layout. Offset-delta would drift; the plan only uses offset-delta for views without an observer. |

### 10.4 Documentation guidance

The README's "Recommended use of `itemKeyBuilder`" section will explain:

- For `ListView` / `GridView` with simple fixed-height items: `itemKeyBuilder` is not needed for anchor preservation; index-based works.
- For animated insert/remove (`SliverAnimatedList` / `SliverAnimatedGrid`): `itemKeyBuilder` is already required by the existing animation feature.
- For lists where item heights settle late (image-heavy feeds, async-measured content): providing `itemKeyBuilder` gives the highest-fidelity anchor and is recommended.
- For `StaggeredGridView`: `itemKeyBuilder` does not improve anchor fidelity (the package falls back to offset-delta regardless), but is still useful for animated operations.

---

## Section 11 — Public API Design

**Goal (per Spec FR-009 / FR-011)**: zero breaking changes; anchor preservation is on by default; consumers can opt out only if they have a specific reason.

### 11.1 New optional parameter on `PaginateApiView` (and its public wrappers)

```dart
class PaginateApiView<T, R extends PaginationRequest> extends StatefulWidget {
  const PaginateApiView({
    // ... existing params ...
    this.preserveScrollAnchorOnAppend = true,  // ← NEW; defaults to true
  });

  /// Whether to capture the visible scroll anchor before each load-more fetch
  /// and restore the viewport relative to that anchor after the new page is
  /// appended.
  ///
  /// Defaults to `true`. Set to `false` only if you have a specific reason to
  /// disable anchor preservation for this list (e.g., a custom scroll-correction
  /// flow that conflicts).
  ///
  /// On reverse-direction lists, `PageView`, and `ReorderableListView`, this
  /// parameter has no effect: anchor preservation is unsupported on those views
  /// in this version and the package falls through to existing behavior.
  final bool preserveScrollAnchorOnAppend;
}
```

The same parameter is mirrored on the public wrappers (`SmartPaginationListView`, `SmartPaginationGridView`, etc.) and forwarded.

### 11.2 New optional parameter on `SmartPaginationCubit`

None at construction time. The cubit gains two new internal methods that the widget layer calls:

```dart
class SmartPaginationCubit<T, R extends PaginationRequest> {
  // ... existing public API ...

  /// Internal — called by PaginateApiView immediately before a load-more
  /// fetch starts. Captures the anchor snapshot for use during the post-fetch
  /// restore. Idempotent within a single fetch; subsequent calls during the
  /// same in-flight fetch are ignored.
  ///
  /// This method is part of the package's internal contract and is NOT
  /// recommended for external use.
  @internal
  void captureAnchorBeforeLoadMore(_PendingScrollAnchor snapshot);

  /// Internal — called by PaginateApiView's NotificationListener whenever a
  /// user-initiated drag-scroll starts. Clears the post-append load-more
  /// suppression flag if set.
  ///
  /// Public-but-internal annotation: documented and tested, but not
  /// guaranteed-stable for direct consumer use.
  @internal
  void markUserScroll();
}
```

Both methods are annotated `@internal` (`package:meta`). They are not in the README; they are documented in dartdoc only. Direct consumers of `SmartPaginationCubit` (which is supported per Constitution §II) should not call them — but even if they did, `captureAnchorBeforeLoadMore` is idempotent and `markUserScroll` is a flag-clearing operation, so misuse is safe.

### 11.3 Parameters considered but NOT added

| Considered parameter | Reason for rejection |
|---|---|
| `scrollAnchorStrategy` enum | The hybrid policy (Spec Q1) auto-selects the right strategy from the inputs already available. Exposing the choice would burden every consumer with a decision they don't need to make. |
| `loadMoreTriggerPolicy` enum | The user-scroll re-arm policy is the only correct one (Spec Q3); other policies were explicitly rejected. |
| `suppressLoadMoreUntilUserScrolls` flag | This is the *behavior* of the feature; toggling it off would regress the bug being fixed. If `preserveScrollAnchorOnAppend == false`, suppression is also off (they travel together as one feature flag). |
| `requireItemKeyBuilder` flag | `itemKeyBuilder` is optional by Spec Q1; flagging requirement would contradict that. |

### 11.4 Existing parameters: no change

`itemKeyBuilder`, `scrollController`, `invisibleItemsThreshold`, `reverse`, all builders, and every existing parameter retain their current signatures, names, defaults, and semantics.

---

## Section 12 — Internal State Model

See `data-model.md` for the full schema. Summary:

### 12.1 New private fields on `SmartPaginationCubit`

| Field | Type | Purpose | Cleared on |
|---|---|---|---|
| `_pendingAnchor` | `_PendingScrollAnchor?` | Snapshot of the visible viewport anchor captured before load-more starts; consumed by post-fetch restore | success/error/scope-reset |
| `_suppressLoadMoreUntilUserScroll` | `bool` (default `false`) | When `true`, `fetchPaginatedList` rejects calls until a user-scroll is observed | user-scroll, scope-reset, error |
| `_lastUserScrollGeneration` | `int` (default `0`) | Monotonic counter of observed user-scroll events; used by tests to assert "exactly one user gesture per fetch" | not cleared (monotonic) |
| `_anchorRestoreInFlight` | `bool` (default `false`) | When `true`, the post-frame restore is scheduled or running; used by `markUserScroll` to ignore the synthetic scroll notification produced by `jumpTo` itself | post-frame restore completion |

### 12.2 Existing fields: no semantic change

`_isFetching`, `_activeLoadMoreKey`, `_currentRequest`, `_currentMeta`, `_pages`, `_pageStreams`, `_generation`, `_fetchToken` — all retain the semantics established by features `001-…` through `003-load-more-guard`.

### 12.3 New private state on `_PaginateApiViewState`

| Field | Type | Purpose |
|---|---|---|
| `_lastObservedSnapshot` | `_PendingScrollAnchor?` | The most recent anchor snapshot computed from the observer; updated on every `dispatchOnceObserve` callback. Used to populate `captureAnchorBeforeLoadMore` synchronously when load-more fires. |

The widget does not own the suppression flag; that lives on the cubit.

---

## Section 13 — Tests Required

Mapping from Spec acceptance scenarios and FRs to test files:

### Test file: `test/scroll_anchor_capture_test.dart`

| # | Test description | Verifies |
|---|---|---|
| T01 | When `fetchPaginatedList` is called with `itemKeyBuilder` provided and an observer attached, `_pendingAnchor.strategy == AnchorStrategy.key` | FR-003(a), Q1 |
| T02 | When `fetchPaginatedList` is called WITHOUT `itemKeyBuilder` on a `ListView`, `_pendingAnchor.strategy == AnchorStrategy.index` | FR-003(b), Q1 |
| T03 | When `fetchPaginatedList` is called on a `StaggeredGridView` (no observer), `_pendingAnchor.strategy == AnchorStrategy.offset` | FR-003(c), Q1 |
| T04 | The captured anchor is the **last fully-visible item before the loading indicator**, not the first or center | FR-003b, Q2 |
| T05 | If no item is fully visible (viewport shorter than item), capture falls back to topmost partially-visible item | FR-003b |
| T06 | If no item is identifiable at all, capture falls back to offset strategy | FR-003b |
| T07 | Capture is a no-op for reverse lists, `PageView`, `ReorderableListView` | FR-007, Q5 |
| T08 | Capture happens BEFORE `emit(isLoadingMore: true)` (verified by ordering tests with synchronous emit-listener) | §7.1 |

### Test file: `test/scroll_anchor_restore_test.dart`

| # | Test description | Verifies |
|---|---|---|
| T09 | After load-more append, the anchor item is at approximately the same on-screen offset (±1 row tolerance) | SC-001, FR-002 |
| T10 | Restore happens in a post-frame callback, not synchronously | FR-004a, Q3 |
| T11 | Restore uses `_listObserverController.jumpTo(index, alignment: 1.0)` for ListView | §5.1 |
| T12 | Restore uses `controller.jumpTo(pixelsBefore)` for `StaggeredGridView` | §5.1 |
| T13 | Restore handles variable-height items: anchor stays at same row even if items below settle to different heights | SC-005, §10 |
| T14 | If the captured anchor key is no longer present at restore time, the fallback offset-delta path is used and no exception is thrown | FR-008 |
| T15 | If `_generation` advanced (scope reset) between capture and restore, the anchor is discarded; no `jumpTo` is called | §5.4 |

### Test file: `test/scroll_anchor_suppression_test.dart`

| # | Test description | Verifies |
|---|---|---|
| T16 | Immediately after a successful append + restore, `fetchPaginatedList` is rejected with no provider call | SC-002, FR-004, FR-004b |
| T17 | After a user-initiated `ScrollStartNotification` is fired, the next `fetchPaginatedList` is allowed through | FR-004 |
| T18 | A programmatic `controller.jumpTo` (e.g., from public `animateToIndex`) does NOT clear the suppression flag | §6.1 |
| T19 | The synthetic scroll notification produced by anchor restore's own `jumpTo` does NOT clear the suppression flag | §6.1, §12.1 (`_anchorRestoreInFlight`) |
| T20 | Late layout settle (image loads adjusting `maxScrollExtent` after restore) does NOT trigger another `fetchPaginatedList` while suppressed | FR-004b |
| T21 | A load-more error clears the suppression flag (so retry can proceed without forcing user scroll) | §7.3 |
| T22 | Refresh / filter change clears the suppression flag and discards the pending anchor | §7.4 |

### Test file: `test/scroll_anchor_view_type_matrix_test.dart`

| # | Test description | Verifies |
|---|---|---|
| T23 | Anchor preservation works on `ListView` (with and without `itemKeyBuilder`) | FR-007, US2 AS1 |
| T24 | Anchor preservation works on `GridView` (with and without `itemKeyBuilder`) | FR-007, US2 AS2 |
| T25 | Anchor preservation works on `CustomScrollView`/sliver layouts with the package's items sliver | FR-007, US2 AS3 |
| T26 | Anchor preservation works on `StaggeredGridView` via offset-delta | FR-007, US2 AS4 |
| T27 | Anchor preservation is a no-op on `PageView` (verified: no `markUserScroll` flag set, no `_pendingAnchor`) | FR-007, US2 AS5 |
| T28 | Anchor preservation is a no-op on `ReorderableListView` | FR-007, US2 AS5 |
| T29 | Anchor preservation is a no-op on any view with `reverse: true` | FR-007, US2 AS5 |

### Test file: `test/scroll_anchor_compatibility_test.dart`

| # | Test description | Verifies |
|---|---|---|
| T30 | `.withProvider(...)` constructor: anchor preservation works with the package's internal `ScrollController` | US3 AS1, FR-006 |
| T31 | `.withCubit(...)` constructor: anchor preservation works with an externally-supplied `ScrollController` | US3 AS2, FR-005 |
| T32 | An external `ScrollController`'s `addListener` callbacks continue to fire during anchor capture and restore | FR-005 |
| T33 | The package does NOT dispose an external `ScrollController` (verified by reusing it in a sibling widget after the paginated view is unmounted) | FR-005 |
| T34 | `preserveScrollAnchorOnAppend: false` disables capture, restore, and suppression entirely; behavior reverts to pre-feature | FR-009 |
| T35 | All call sites from the README examples for `.withProvider` and `.withCubit` compile and run without modification | US3 AS3, FR-009 |

### Test file: `test/scroll_anchor_fallthrough_test.dart`

| # | Test description | Verifies |
|---|---|---|
| T36 | `reverse: true` on `ListView`: load-more fires whenever the original `_shouldLoadMore` says so; no anchor logic interferes | §9, FR-007 |
| T37 | `PageView`: existing overflow-index trigger continues to call `fetchPaginatedList` | §8.1 |
| T38 | `ReorderableListView`: existing behavior unchanged | §8.1 |

### Test mapping summary

| Spec FR / SC | Tests |
|---|---|
| FR-001, FR-001a | T07, T22 |
| FR-002 | T09, T13 |
| FR-003, FR-003a, FR-003b | T01, T02, T03, T04, T05, T06 |
| FR-004, FR-004a, FR-004b | T10, T16, T17, T20 |
| FR-005, FR-006 | T30, T31, T32, T33 |
| FR-007 | T07, T23–T29 |
| FR-008 | T14, T15 |
| FR-009 | T34, T35 |
| FR-010 | (negative test absent — no debounce/throttle code path exists, asserted by code review) |
| FR-011 | T34 (default-on verified) |
| FR-012 | T13 (variable height), T25 (slivers), T23 (normal list) |
| FR-013 | (documentation review in Phase H) |
| SC-001 | T09 |
| SC-002 | T16, T17 |
| SC-003 | T35 |
| SC-004 | (documentation review in Phase H) |
| SC-005 | T13, T23, T25 |

### Test infrastructure

- All tests use `testWidgets` with synthetic gesture pumps (`tester.fling`, `tester.drag`, `tester.pump(Duration)`) to simulate fast scroll.
- The mock provider records every `getList(request)` call, enabling exact-call-count assertions.
- A `FakeScrollController` is used in unit-level cubit tests where a full widget tree is unnecessary; widget-level tests use the real `ScrollController` to validate the observer integration.
- Variable-height tests use a builder that returns alternating `SizedBox(height: 50)` / `SizedBox(height: 200)` widgets; the assertion is on row index alignment, not pixel offset, to keep the test robust across platforms.

---

## Section 14 — Documentation Plan

### `README.md` — new section

```markdown
## Scroll Anchor Preservation

Smart Pagination keeps your user's scroll position stable when a new page is appended.

When the user scrolls to the bottom of a paginated list, the package fetches the next page,
appends the new items, and **restores the viewport so the item the user was reading remains
in the same on-screen position**. This prevents the runaway-scroll bug where appending one
page silently triggers another, and another, without the user ever lifting their finger.

### How it works

1. **Before** each load-more fetch, the package captures the *last fully-visible item before
   the loading indicator* as the scroll anchor.
2. **After** the new page is appended and laid out, the package restores the viewport so
   that anchor item is at the same on-screen position it was at before.
3. **Until** the user produces a new drag-scroll gesture, no further automatic load-more
   fires — even if late layout settle (image loads, etc.) would otherwise re-cross the
   threshold.

### Anchor strategies

| Strategy | When used |
|---|---|
| **Key-based** | When you supply `itemKeyBuilder`. Highest fidelity; recommended for image-heavy
   feeds. |
| **Index-based** | Default for `ListView` / `GridView` when no `itemKeyBuilder` is supplied. |
| **Offset-delta** | Fallback for `StaggeredGridView` and views without an observer. |

`itemKeyBuilder` is optional — the package automatically falls back to the right strategy
based on the view type and what's available.

### View-type support

| View | Supported in v1 |
|---|---|
| `ListView` (incl. animated) | ✅ Full |
| `GridView` (incl. animated) | ✅ Full |
| `CustomScrollView` / sliver variants | ✅ Full |
| `StaggeredGridView` | ✅ Full (offset-delta) |
| `PageView` | ⚠️ Out of scope (v1) — falls through to existing behavior |
| `ReorderableListView` | ⚠️ Out of scope (v1) — falls through to existing behavior |
| Reverse lists (`reverse: true`) | ⚠️ Out of scope (v1) — falls through to existing behavior |

### Disabling

Anchor preservation is on by default. To disable for a specific list:

    SmartPaginationListView<Item, Req>.withProvider(
      // ...
      preserveScrollAnchorOnAppend: false,
    )

### Troubleshooting

> **My list still chain-loads on fast scroll.**
> Make sure you are on smart_pagination ≥ <version>. Both the load-more guard
> (`003-load-more-guard`) and the scroll anchor preservation (`004-scroll-anchor-preservation`)
> are required for the full fix; one alone is not enough.

> **The anchor item drifts up by ~5 pixels after append.**
> This is normal sub-pixel drift on variable-height lists without `itemKeyBuilder`.
> Adding `itemKeyBuilder` upgrades the strategy from index-based to key-based, which
> eliminates the drift.
```

### `CHANGELOG.md` — new entry

```markdown
## [3.5.0] - 2026-05-XX

### Added
- **Scroll anchor preservation** (#004): the package now captures the user's visible
  anchor before each load-more fetch and restores the viewport relative to that anchor
  after the new page is appended. Combined with the load-more guard from 3.4.x, this
  fully eliminates the chained-load-more behavior on fast scroll.
- New optional `preserveScrollAnchorOnAppend` parameter on `PaginateApiView` (default: `true`).
- Suppression of automatic load-more between successful append and the next user-initiated
  drag-scroll, preventing runaway fetches caused by late layout settle.

### Changed
- `fetchPaginatedList` guard chain now includes a `_suppressLoadMoreUntilUserScroll`
  check (after `_activeLoadMoreKey`, before `isLoadingMore`).

### Compatibility
- No breaking changes. All `.withProvider(...)` and `.withCubit(...)` call sites continue
  to work unchanged.
- `itemKeyBuilder` remains optional; key-based anchoring is used when provided, with
  graceful fallback to index-based / offset-delta when not.
- Reverse lists, `PageView`, and `ReorderableListView` are explicitly out of scope for v1
  and fall through to existing behavior.
```

### Inline dartdoc updates

| File | Updates |
|---|---|
| `pagination_cubit.dart` | Document `_pendingAnchor`, `_suppressLoadMoreUntilUserScroll`, `captureAnchorBeforeLoadMore`, `markUserScroll`. Update `fetchPaginatedList` guard-order doc to include the new step. |
| `paginate_api_view.dart` | Document `preserveScrollAnchorOnAppend`. Document the new outer `NotificationListener<ScrollNotification>` and what it triggers. |
| `pagination_state.dart` | No changes (anchor entities are private to the cubit). |

---

## Section 15 — Implementation Phases

### Phase A — Failing widget test reproducing the chained load-more after append

Write a `testWidgets` test that:

1. Sets up a paginated `ListView` backed by a mock provider that always returns full pages of 20 items.
2. Uses `tester.fling` to scroll to the bottom in one gesture.
3. Pumps frames for 2 seconds.
4. Asserts that `getList` was called **exactly twice** (initial + one load-more), not 3+.

Without anchor preservation, this test fails (3+ calls). It is the regression anchor.

### Phase B — Cubit-side anchor data model and capture entry point

1. Add `_PendingScrollAnchor` private class (see `data-model.md`).
2. Add `_pendingAnchor`, `_suppressLoadMoreUntilUserScroll`, `_lastUserScrollGeneration`, `_anchorRestoreInFlight` fields to `SmartPaginationCubit`.
3. Add `@internal void captureAnchorBeforeLoadMore(_PendingScrollAnchor snapshot)` and `@internal void markUserScroll()` methods.
4. Insert the suppression check into the `fetchPaginatedList` guard chain (between `_activeLoadMoreKey` and `isLoadingMore` checks).
5. On successful fetch completion, schedule the post-frame restore. On scope reset/error, clear/discard appropriately (per §7).

No tests pass yet — the widget side has not been wired up.

### Phase C — Widget-side observer snapshot and capture/restore wiring

1. Subscribe to the `ListObserverController` / `GridObserverController` snapshot stream in `_PaginateApiViewState` to maintain `_lastObservedSnapshot`.
2. In each item-builder trigger site (`_buildListView`, `_buildGridView`, etc.), before the `addPostFrameCallback(fetchPaginatedList)` call, push the snapshot to the cubit via `captureAnchorBeforeLoadMore`.
3. Add the outer `NotificationListener<ScrollNotification>` in each scrollview builder; on user-initiated scroll, call `cubit.markUserScroll()`.
4. Listen on the cubit's anchor-restore signal (a new internal stream or a direct callback hook); on the post-frame, call `_listObserverController!.jumpTo(...)` or fall back to `controller.jumpTo(pixelsBefore)`.

### Phase D — View-type matrix coverage

1. Validate behavior on `ListView` animated and non-animated. Run T01, T02, T04, T08, T09, T11, T16, T23.
2. Validate behavior on `GridView` animated and non-animated. Run T24.
3. Validate behavior on `CustomScrollView` / sliver. Run T25.
4. Validate offset-delta behavior on `StaggeredGridView`. Run T03, T12, T26.
5. Validate no-op behavior on `PageView`, `ReorderableListView`, and `reverse: true`. Run T07, T27, T28, T29, T36, T37, T38.

### Phase E — Edge case coverage

1. Variable-height items (T13).
2. Anchor item missing at restore time (T14).
3. Scope reset during in-flight fetch (T15, T22).
4. Programmatic vs. user-initiated scroll discrimination (T18, T19).
5. Late layout settle suppression (T20).
6. Load-more error clears suppression (T21).

### Phase F — Public API and compatibility

1. Add the `preserveScrollAnchorOnAppend` parameter (default `true`) on `PaginateApiView` and forward through public wrappers.
2. Run T30–T35.

### Phase G — Tests for anchor capture and restoration (full suite)

Run the full new test suite (T01–T38). All must pass. Re-run the existing test suite — all must still pass with no regressions.

### Phase H — Documentation and changelog

1. Update `README.md` with the new "Scroll Anchor Preservation" section (§14).
2. Update `CHANGELOG.md` (§14).
3. Update inline dartdoc per §14.

### Phase I — Analysis and full test suite

```bash
flutter analyze
flutter test
```

`flutter analyze` reports no new issues. All tests pass.

---

## Section 16 — Acceptance Criteria

The implementation is accepted only when ALL of the following are true:

1. After a single fast `tester.fling` to the bottom of a paginated `ListView` backed by an always-full-page provider, exactly one load-more fetch is called — verified by T16, T17, and the Phase A regression test.

2. The anchor item remains within ±1 row of its pre-append on-screen position across `ListView`, `GridView`, `CustomScrollView`/slivers, and `StaggeredGridView` — verified by T09, T23, T24, T25, T26.

3. After a successful append, no further load-more is auto-fired until a user-initiated `ScrollStartNotification` is observed — verified by T16, T17, T20.

4. A load-more error clears the suppression flag so retry can proceed without forcing user scroll — verified by T21.

5. Scope reset (refresh, filter, search) clears all anchor and suppression state — verified by T22, T15.

6. `.withProvider(...)` and `.withCubit(...)` constructors compile and run without modification across all README examples — verified by T35.

7. Externally-supplied `ScrollController` is not taken over and its listeners continue to fire — verified by T31, T32, T33.

8. `preserveScrollAnchorOnAppend: false` reverts behavior to pre-feature — verified by T34.

9. Reverse lists, `PageView`, and `ReorderableListView` fall through to existing behavior with no new exceptions or warnings — verified by T29, T27, T28, T36, T37, T38.

10. README documents the supported view-type matrix and the `itemKeyBuilder` recommendation; CHANGELOG documents the new feature with no breaking-change note.

11. `flutter analyze` reports no new issues. `flutter test` passes the full new + existing suite at 100%.

The fix operates jointly at the cubit and widget layers. Both sides are required: the cubit owns the suppression flag and pending anchor; the widget owns the observer snapshot and the user-scroll detector. Acceptance requires the integrated behavior, not either side alone.

---

## Phase 0 — Outline & Research

See [research.md](research.md) for decisions, alternatives, and rationale.

## Phase 1 — Design & Contracts

See:
- [data-model.md](data-model.md) for entity schemas (private types).
- [contracts/anchor-strategy.md](contracts/anchor-strategy.md) for the strategy-selection contract.
- [contracts/view-type-matrix.md](contracts/view-type-matrix.md) for the per-view-type behavior contract.
- [contracts/public-api-surface.md](contracts/public-api-surface.md) for the public API delta.
- [quickstart.md](quickstart.md) for a consumer-facing 60-second walkthrough.
