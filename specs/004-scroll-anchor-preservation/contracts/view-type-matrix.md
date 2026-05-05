# Contract — View-Type Support Matrix

**Feature**: `004-scroll-anchor-preservation` | **Plan**: [../plan.md](../plan.md)

This contract is the source-of-truth for which behaviors the package guarantees on each view type. It is the contract that the README's support matrix (Phase H) reproduces and that the test matrix (`scroll_anchor_view_type_matrix_test.dart`) verifies.

---

## Matrix

| View type | Default `itemBuilderType` | Anchor capture | Anchor restore | Suppression | User-scroll re-arm | Notes |
|---|---|---|---|---|---|---|
| `ListView` (non-animated) | `listView` | ✅ Key (if `itemKeyBuilder`) → Index | ✅ `_listObserverController.jumpTo(index, alignment: 1.0)` | ✅ | ✅ | Standard `SliverList`. |
| `ListView` (animated) | `listView` + `itemKeyBuilder` set | ✅ Key (always — animated requires `itemKeyBuilder`) | ✅ `_listObserverController.jumpTo(...)` | ✅ | ✅ | `SliverAnimatedList`. Restore happens *after* rebuild and *before* the insert animation. |
| `GridView` (non-animated) | `gridView` | ✅ Key (if `itemKeyBuilder`) → Index | ✅ `_gridObserverController.jumpTo(index, alignment: 1.0)` | ✅ | ✅ | Standard `SliverGrid`. |
| `GridView` (animated) | `gridView` + `itemKeyBuilder` set | ✅ Key (always) | ✅ `_gridObserverController.jumpTo(...)` | ✅ | ✅ | `SliverAnimatedGrid`. |
| `CustomScrollView` (sliver-based) | `listView` or `gridView` with custom `header`/`footer` slivers | ✅ Key/Index per active observer | ✅ Active observer's `jumpTo(...)` | ✅ | ✅ | `header` and `footer` slivers do not affect anchor logic; the items sliver is the only thing observed. |
| `StaggeredGridView` | `staggeredGridView` | ✅ Offset (no observer integration) | ✅ `controller.jumpTo(pixelsBefore)` | ✅ | ✅ | Append-only scope guarantees `pixelsBefore` is correct after append. |
| `PageView` | `pageView` | ❌ Out of scope (v1) | ❌ | ❌ | n/a | Falls through to existing behavior. No exception. README documents as unsupported. |
| `ReorderableListView` | `reorderableListView` | ❌ Out of scope (v1) | ❌ | ❌ | n/a | Falls through to existing behavior. No `_shouldLoadMore` call exists today; the load-more hook is missing entirely. README documents as unsupported. |
| Reverse-direction list (`reverse: true`) on any of the above | any | ❌ Out of scope (v1) | ❌ | ❌ | n/a | Detected by `widget.reverse == true` at capture time. Falls through. |
| `custom` (`PaginateBuilderType.custom`) | `custom` | ❌ Out of scope (v1) | ❌ | ❌ | n/a | The package has no rendered slivers/controller of its own to anchor against; consumers using `customViewBuilder` own the scroll behavior themselves. |

---

## Per-view-type behavior contract

### `ListView` and `GridView` (sliver-based, observer attached)

**Capture timing**: synchronously inside the `addPostFrameCallback` block in the item builder, immediately before `widget.fetchPaginatedList?.call()`.

**Capture inputs**: `_lastObservedSnapshot` (refreshed continuously by the observer's `onObserve` callback), `widget.itemKeyBuilder`, `widget.loadedState.items`, `_effectiveScrollController.position`.

**Restore timing**: in `WidgetsBinding.instance.addPostFrameCallback` after the cubit emits `SmartPaginationLoaded` with the new items.

**Fidelity guarantee**: anchor item lands at the bottom edge of the viewport (`alignment: 1.0`), which is the same on-screen position the user was looking at when they scrolled past the threshold. Tolerance: ±1 row (Spec SC-001).

### `CustomScrollView` (with package-supplied items sliver)

Same as `ListView`/`GridView` for the items sliver. Custom `header` / `footer` slivers from the consumer are inert with respect to anchor logic — they simply add their `RenderSliver` extents to the scrollview, but the observer is wired only to the items sliver, so the anchor is always identified from items.

If a consumer wraps the package's view in their own `CustomScrollView`, behavior is undefined for v1; the package's anchor logic only applies when the package itself owns the `CustomScrollView` instance (lines 507–523, 727–744 of `paginate_api_view.dart`).

### `StaggeredGridView`

**Capture timing**: inside the `NotificationListener<ScrollNotification>`'s `onNotification` callback at the moment the 80% threshold is crossed (line 871), in the same `addPostFrameCallback` block where `fetchPaginatedList` is invoked.

**Capture inputs**: `_effectiveScrollController.position.pixels` and `.maxScrollExtent`. No observer; no key/index.

**Restore timing**: same as the sliver-based views — post-frame after `SmartPaginationLoaded` with new items.

**Fidelity guarantee**: in append-only scope (FR-001a), `pixelsBefore` is the correct restore target because new items are appended *below* the user's offset, so `pixels` is unchanged by the append. The restore is therefore a no-op-equivalent (sets the same value the controller already has), but it formally completes the suppression-arming flow and ensures any in-flight programmatic adjustments are overridden back to the captured value.

### `PageView` (out of scope v1)

`PaginateBuilderType.pageView` triggers `fetchPaginatedList` from `if (index >= _items.length)` (line 833). In the post-frame block, the capture algorithm returns `proceed: false` because `viewType == _AnchorViewType.pageView`. The cubit does not store an anchor and does not arm `_suppressLoadMoreUntilUserScroll`. The fetch proceeds exactly as it does today; no restore happens.

Documented in README as: *"`PageView` is out of scope for v1. Anchor preservation does not apply; the existing pagination behavior on `PageView` is unchanged."*

### `ReorderableListView` (out of scope v1)

`_buildReorderableListView` does not currently include any `_shouldLoadMore` / `fetchPaginatedList` call (lines 757–816). `ReorderableListView` consumers must trigger pagination through some external mechanism (e.g., a "Load more" button). Capture is never invoked because there's no trigger; even if it were, the capture algorithm would return `proceed: false`.

Documented in README as: *"`ReorderableListView` is out of scope for v1. Auto-load-more is not currently supported on this view type; consumers managing pagination manually retain full control."*

### Reverse direction (`reverse: true`)

Detected at capture time via `widget.reverse == true`. The capture algorithm returns `proceed: false` regardless of view type. The cubit does not arm suppression. The fetch proceeds as today.

Documented in README as: *"Reverse-direction lists (`reverse: true`) are out of scope for v1. The package detects the reverse flag and falls through to existing behavior."*

### `custom` (`PaginateBuilderType.custom`)

The consumer-supplied `customViewBuilder` is opaque to the package — it returns a single `Widget` and the package has no visibility into its internal scroll structure. `proceed: false` for this view type.

---

## Backwards-compatibility surface (cross-cutting)

For every view type listed above (in scope and out), the following must hold post-feature:

| Property | Pre-feature | Post-feature | Status |
|---|---|---|---|
| `.withProvider(...)` constructor signature | (existing) | (unchanged) | Compatible |
| `.withCubit(...)` constructor signature | (existing) | (unchanged) | Compatible |
| `PaginateApiView` constructor signature | (existing) | (gains `preserveScrollAnchorOnAppend = true`, additive) | Compatible |
| `widget.fetchPaginatedList` call site | (existing) | (unchanged) | Compatible |
| `widget.scrollController` ownership | not disposed if external | not disposed if external | Compatible |
| `widget.itemKeyBuilder` semantics | optional, used for animation + findChildIndexCallback | optional, used for animation + findChildIndexCallback **+ key-based anchor** | Compatible (additive) |
| Existing tests | passing | passing | Required |
| README example call sites | valid | valid | Required |

---

## Test surface

| Test ID (from plan §13) | Verifies |
|---|---|
| T23 | `ListView` with and without `itemKeyBuilder`: capture and restore work end-to-end |
| T24 | `GridView` with and without `itemKeyBuilder`: capture and restore work end-to-end |
| T25 | `CustomScrollView`/sliver: capture and restore on the items sliver, custom `header`/`footer` slivers are inert |
| T26 | `StaggeredGridView`: offset-delta capture and restore |
| T27 | `PageView`: capture is no-op, suppression not armed, existing behavior preserved |
| T28 | `ReorderableListView`: capture is no-op (no trigger exists today), existing behavior preserved |
| T29 | `reverse: true` on any in-scope view: capture is no-op, existing behavior preserved |
| T36, T37, T38 | Out-of-scope view fall-through (no exceptions, no warnings, identical behavior to pre-feature) |
