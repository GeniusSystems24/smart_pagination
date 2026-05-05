# Quickstart — Scroll Anchor Preservation

**Feature**: `004-scroll-anchor-preservation` | **Plan**: [plan.md](plan.md)

A 60-second walkthrough for consumers and contributors. **No code changes required for consumers**: the feature is on by default and applies automatically.

---

## For consumers (60 seconds)

### What changes for me?

If you use `smart_pagination` and your app is showing a paginated list, fast scrolling to the bottom of the list now produces **exactly one** automatic load-more per scroll gesture. Before this feature, fast scrolling could chain-trigger 2, 3, or more page fetches in a row even though the user only scrolled once.

### What do I need to change?

Nothing. Upgrade the package version and the fix takes effect on:

- `ListView`-backed paginated views (animated and non-animated)
- `GridView`-backed paginated views (animated and non-animated)
- `CustomScrollView` / sliver layouts
- `StaggeredGridView`

### Want better anchor fidelity for image-heavy lists?

Pass `itemKeyBuilder` to your `SmartPagination*View` if you haven't already. With `itemKeyBuilder`, the package uses **key-based** anchoring (highest fidelity, immune to late layout settle). Without it, the package falls back to **index-based** anchoring on `ListView`/`GridView` (still correct, slightly less robust to late image loads above the viewport — which is rare in append-only flows).

```dart
SmartPaginationListView<Product, ProductRequest>.withProvider(
  request: ProductRequest(page: 1),
  provider: PaginationProvider.future(getProducts),
  itemKeyBuilder: (product, _) => product.id,  // ← recommended for feeds with images
  itemBuilder: (context, products, index) => ProductTile(products[index]),
);
```

### What if I want to disable it?

Pass `preserveScrollAnchorOnAppend: false`. The package reverts to pre-feature behavior. (Most consumers will not need this; it exists only for the rare case of a custom scroll-correction flow that conflicts.)

### Out of scope in v1

Reverse-direction lists (`reverse: true`), `PageView`, and `ReorderableListView` are unsupported in v1 and continue to behave exactly as they did before. No exceptions; no warnings.

---

## For contributors (60 seconds)

### Where does the work happen?

Two files do the heavy lifting:

- `lib/smart_pagination/bloc/pagination_cubit.dart` — owns the suppression flag, the pending anchor, and the post-frame restore orchestration.
- `lib/smart_pagination/widgets/paginate_api_view.dart` — captures the anchor snapshot from the `scrollview_observer` integration and pushes it to the cubit immediately before each `fetchPaginatedList` invocation, and listens for user-initiated `ScrollStartNotification` to re-arm the cubit.

A new private type `_PendingScrollAnchor` and a new private enum `AnchorStrategy` live in `lib/smart_pagination/bloc/pagination_state.dart` (alongside the existing `_PageStreamEntry` from feature `002-stabilize-provider`).

### What's the lifecycle?

```text
[User scrolls toward end]
        │
[item builder evaluates _shouldLoadMore == true]
        │
[post-frame block in item builder]
        │
        ├── widget computes anchor snapshot from observer
        │   (last fully-visible item before the spinner)
        │
        ├── widget pushes snapshot to cubit
        │   via captureAnchorBeforeLoadMore(snapshot)
        │
        └── widget calls cubit.fetchPaginatedList()
                │
[cubit guard chain runs]
                │
                ├── existing guards (_isFetching, _activeLoadMoreKey, ...)
                │
                ├── NEW: _suppressLoadMoreUntilUserScroll → reject if true
                │
                └── accept: arm _suppressLoadMoreUntilUserScroll = true
                            store _pendingAnchor = snapshot
                            emit(isLoadingMore: true), call _fetch
                                │
[await provider; success]
                                │
[cubit emits Loaded with new items]
                                │
[schedule WidgetsBinding.addPostFrameCallback]
                                │
[post-frame fires]
                                │
                                ├── set _anchorRestoreInFlight = true
                                ├── perform jumpTo(index, alignment: 1.0)
                                │   (or controller.jumpTo(pixelsBefore) for staggered)
                                ├── clear _pendingAnchor
                                └── on next endOfFrame: clear _anchorRestoreInFlight
                                        │
[user makes a new drag gesture]
                                        │
[outer NotificationListener fires markUserScroll]
                                        │
[cubit clears _suppressLoadMoreUntilUserScroll]
                                        │
[next threshold cross is allowed]
```

### What's the test surface?

Six new test files, all under `test/`:

- `scroll_anchor_capture_test.dart` — strategy selection (key/index/offset)
- `scroll_anchor_restore_test.dart` — post-frame restore mechanics, fallbacks
- `scroll_anchor_suppression_test.dart` — suppression flag and user-scroll re-arm
- `scroll_anchor_view_type_matrix_test.dart` — per-view-type behavior (the matrix in `contracts/view-type-matrix.md`)
- `scroll_anchor_compatibility_test.dart` — `.withProvider`/`.withCubit` and external `ScrollController`
- `scroll_anchor_fallthrough_test.dart` — out-of-scope view types are no-ops

Each test maps back to specific Spec FRs and the plan's Section 13. A regression-anchor `testWidgets` in the capture test file fails on pre-feature code and passes after the fix.

### How do I run the new tests?

```bash
flutter test test/scroll_anchor_capture_test.dart
flutter test test/scroll_anchor_restore_test.dart
# ... or run them all:
flutter test test/scroll_anchor_*.dart
```

### How do I verify backward compatibility?

```bash
flutter analyze
flutter test            # whole suite — must pass with no new failures
```

The README's `.withProvider` and `.withCubit` examples are compiled and run as part of `scroll_anchor_compatibility_test.dart`. Any breaking change to those examples fails CI.

---

## Key design decisions, in one breath

- **Hybrid anchor strategy**: key when keys are available, index when not, offset-delta as fallback. (Spec Q1)
- **Anchor target**: last fully-visible item before the spinner. (Spec Q2)
- **Restore timing**: post-frame, not synchronous. (Spec Q3)
- **Suppression**: load-more rejected until next user drag-scroll. (Spec Q3)
- **Scope**: append-on-load-more only. (Spec Q4)
- **View support**: standard scrollables in v1; reverse / PageView / Reorderable explicitly out. (Spec Q5)
- **No new public API except one optional bool flag** (`preserveScrollAnchorOnAppend = true`). (Plan §11)

---

## Where to read more

| For | Read |
|---|---|
| The full requirements and clarifications | [spec.md](spec.md) |
| The full implementation plan, root cause analysis, and phase breakdown | [plan.md](plan.md) |
| The technical decisions and alternatives considered | [research.md](research.md) |
| The data model (private types and field additions) | [data-model.md](data-model.md) |
| The strategy-selection algorithm contract | [contracts/anchor-strategy.md](contracts/anchor-strategy.md) |
| The per-view-type behavior contract | [contracts/view-type-matrix.md](contracts/view-type-matrix.md) |
| The public API delta and compatibility verification | [contracts/public-api-surface.md](contracts/public-api-surface.md) |
