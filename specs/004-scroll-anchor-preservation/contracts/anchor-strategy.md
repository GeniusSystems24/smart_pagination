# Contract — Anchor Strategy Selection

**Feature**: `004-scroll-anchor-preservation` | **Plan**: [../plan.md](../plan.md)

This contract defines the deterministic policy that selects an `AnchorStrategy` for a given capture site, given the available inputs. The policy is implemented inside `_PaginateApiViewState._computeAnchorSnapshot` (widget side) for views that own observers, and inside `SmartPaginationCubit.captureAnchorBeforeLoadMore` (cubit side) as a defensive fallback.

---

## Inputs

| Input | Source | When provided |
|---|---|---|
| `itemKeyBuilder` | `widget.itemKeyBuilder` | When the consumer supplied it |
| `itemBuilderType` | `widget.itemBuilderType` | Always |
| `reverse` | `widget.reverse` | Always |
| `observerSnapshot` | `_listObserverController` / `_gridObserverController` `onObserve` callback | When an observer is attached AND has fired at least once |
| `controllerPosition` | `_effectiveScrollController.position` | Always (controller exists by `_effectiveScrollController` lazy init) |
| `itemsLength` | `widget.loadedState.items.length` | Always |
| `bottomLoaderPresent` | `_buildBottomLoaderSliver` returned non-null at last build | Always |

---

## Output

```text
{
  proceed: bool          // false → no-op capture (out-of-scope view)
  strategy: AnchorStrategy?    // null when proceed == false
  index: int?
  key: Object?
  pixelsBefore: double?
  extentBefore: double?
  leadingEdgeOffset: double?
  viewType: _AnchorViewType
  reverse: bool
}
```

---

## Selection algorithm

```text
1. Determine viewType from itemBuilderType:
   - PaginateBuilderType.listView         → _AnchorViewType.listView
   - PaginateBuilderType.gridView         → _AnchorViewType.gridView
   - PaginateBuilderType.staggeredGridView → _AnchorViewType.staggeredGridView
   - PaginateBuilderType.pageView          → _AnchorViewType.pageView
   - PaginateBuilderType.reorderableListView → _AnchorViewType.reorderableListView
   - PaginateBuilderType.custom            → _AnchorViewType.custom

2. Out-of-scope check:
   if reverse == true:
     return { proceed: false, viewType, reverse }
   if viewType in {pageView, reorderableListView, custom}:
     return { proceed: false, viewType, reverse }

3. Strategy selection:
   if viewType == staggeredGridView:
     // No observer integration available.
     return {
       proceed: true,
       strategy: AnchorStrategy.offset,
       pixelsBefore: controllerPosition.pixels,
       extentBefore: controllerPosition.maxScrollExtent,
       viewType, reverse,
     }

   // viewType is listView or gridView (sliver-based).
   if observerSnapshot is null OR observerSnapshot.displayingChildModelList is empty:
     // Observer not yet ready; fall back to offset.
     return {
       proceed: true,
       strategy: AnchorStrategy.offset,
       pixelsBefore: controllerPosition.pixels,
       extentBefore: controllerPosition.maxScrollExtent,
       viewType, reverse,
     }

   // Observer is ready. Find the anchor item.
   anchorItem = findAnchorItem(observerSnapshot)
   if anchorItem is null:
     // Could not identify any item (viewport between items, etc.).
     // Fall back to offset.
     return {
       proceed: true,
       strategy: AnchorStrategy.offset,
       pixelsBefore: controllerPosition.pixels,
       extentBefore: controllerPosition.maxScrollExtent,
       viewType, reverse,
     }

   index = anchorItem.index
   leadingEdgeOffset = anchorItem.leadingEdge

   if itemKeyBuilder != null AND index < itemsLength:
     key = itemKeyBuilder(items[index], index)
     return {
       proceed: true,
       strategy: AnchorStrategy.key,
       index, key, leadingEdgeOffset,
       pixelsBefore: controllerPosition.pixels,
       extentBefore: controllerPosition.maxScrollExtent,
       viewType, reverse,
     }

   // No itemKeyBuilder → index strategy (still capture pixelsBefore as
   // fallback for the anchor-not-found edge case).
   return {
     proceed: true,
     strategy: AnchorStrategy.itemIndex,
     index, leadingEdgeOffset,
     pixelsBefore: controllerPosition.pixels,
     extentBefore: controllerPosition.maxScrollExtent,
     viewType, reverse,
   }
```

### `findAnchorItem(observerSnapshot)` algorithm

```text
fullyVisible = observerSnapshot.displayingChildModelList
  .where(item => item.displayPercentage >= 1.0)

if fullyVisible is non-empty:
  return fullyVisible.maxBy(item => item.index)   // last fully visible

// Fallback: topmost partially-visible item.
partiallyVisible = observerSnapshot.displayingChildModelList
  .where(item => item.displayPercentage > 0.0)

if partiallyVisible is non-empty:
  return partiallyVisible.minBy(item => item.index)

return null
```

This algorithm matches Spec FR-003b exactly.

---

## Restore mechanism by strategy (the receiving end)

The widget's `_performScrollAnchorRestore(snapshot)` consumes the snapshot via this restore policy. Implemented in the post-frame callback after `SmartPaginationLoaded` with new items is observed.

```text
1. If snapshot.generation != cubit._generation:
     no-op. Discard.

2. If snapshot.viewType in {pageView, reorderableListView, custom}
   OR snapshot.reverse == true:
     no-op. (Should not happen — capture should have rejected these,
     but guard against bugs.)

3. Strategy-specific restore:
   case AnchorStrategy.key:
     newIndex = items.indexWhere((item, i) =>
       itemKeyBuilder(item, i) == snapshot.key)
     if newIndex < 0:
       // Key not found → fall through to offset-delta.
       goto case AnchorStrategy.offset (using snapshot.pixelsBefore).
     activeObserver.jumpTo(index: newIndex, alignment: 1.0)

   case AnchorStrategy.itemIndex:
     // In append-only scope, snapshot.index is still valid at restore time.
     if snapshot.index >= items.length:
       // Defensive: snapshot.index out of range (should not happen
       // in append-only). Fall back to offset-delta.
       goto case AnchorStrategy.offset.
     activeObserver.jumpTo(index: snapshot.index, alignment: 1.0)

   case AnchorStrategy.offset:
     target = snapshot.pixelsBefore
     if target == null:
       // No usable target. Skip restore entirely.
       return.
     if target > controller.position.maxScrollExtent:
       // List somehow shrank. Skip.
       return.
     controller.jumpTo(target)
```

`activeObserver` resolves to the `_listObserverController` for `listView` and `_gridObserverController` for `gridView` / `customScrollView`.

---

## Invariants

| ID | Invariant |
|---|---|
| INV-1 | The capture algorithm is **pure** with respect to the cubit: it reads only widget-side inputs and the observer's last snapshot; it does not modify cubit state. |
| INV-2 | The restore algorithm is **idempotent**: calling it twice in the same post-frame produces the same final scroll position (the second `jumpTo` is a no-op because the position is already at target). |
| INV-3 | The restore algorithm is **defensive**: every code path includes a fallback. The flow `key → index → offset → no-op` is exhaustive. No path can throw. |
| INV-4 | The restore algorithm **never** sets cubit state directly. It only calls `jumpTo` on observer/controller. State management around `_pendingAnchor`, `_suppressLoadMoreUntilUserScroll`, and `_anchorRestoreInFlight` is done by the cubit's restore-orchestration code, not by this contract. |
| INV-5 | The capture algorithm **never** mutates `widget.loadedState.items` or any consumer-supplied state. |

---

## Test surface

| Test ID (from plan §13) | Maps to this contract |
|---|---|
| T01 | Strategy selection for `key` (`itemKeyBuilder` provided + observer attached) |
| T02 | Strategy selection for `index` (no `itemKeyBuilder`, observer attached) |
| T03 | Strategy selection for `offset` (StaggeredGridView path) |
| T04 | `findAnchorItem` returns last fully-visible |
| T05 | `findAnchorItem` falls back to topmost partially-visible |
| T06 | `findAnchorItem` falls back to offset when no item identifiable |
| T07 | Out-of-scope short-circuit (returns `proceed: false`) |
| T11, T12 | Restore mechanism dispatch (observer.jumpTo vs. controller.jumpTo) |
| T14 | Restore fall-through key → offset on missing key |
| T15 | Restore generation-mismatch no-op |
