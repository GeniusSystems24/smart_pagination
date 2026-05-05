/speckit.specify

Add a new scroll stability feature to the existing Flutter/Dart package `smart_pagination`: preserve the user's scroll anchor after appending new paginated items.

## Problem

The infinite load-more issue can still happen even after adding request guards because the scroll position remains near the bottom after new items are appended.

When the user scrolls quickly to the end of the list, the load-more threshold is triggered. The next page is fetched and appended. However, after the new items are inserted, the scroll viewport may still remain inside or near the load-more trigger area. This immediately triggers another load-more request, then another one, creating a chain of repeated page fetches.

The core issue is that the package does not preserve focus on the item where the user stopped scrolling. After appending items, the list should keep the user's visual position stable relative to a known anchor item.

## Goal

Implement scroll anchor preservation so that when new paginated items are appended, the user's viewport remains focused on the item that was visible before the append operation.

The package should prevent the scroll position from staying stuck in the load-more trigger zone after new items are added.

## Core Requirement

Before starting a load-more operation, capture a scroll anchor from the current viewport.

After the new page is appended and the list is rebuilt, restore or preserve the scroll position relative to that anchor.

The anchor may be based on:

- item key
- item index
- first visible item
- last visible item before the loading indicator
- nearest stable visible item
- viewport offset delta

The implementation must choose the safest strategy for Flutter scrollable widgets.

## Expected Behavior

When the user reaches the bottom and load-more starts:

1. The package captures the current visible anchor item.
2. The next page is fetched once.
3. New items are appended to the list.
4. The package preserves the viewport position relative to the captured anchor.
5. The same anchor item remains visually stable after insertion.
6. The scroll position no longer remains artificially stuck inside the load-more threshold.
7. Load-more is not triggered again unless the user scrolls again toward the new end.

## Supported Views

The feature should be evaluated for all supported paginated views:

- ListView
- GridView
- CustomScrollView / Sliver variants
- StaggeredGridView
- PageView if applicable
- ReorderableListView if applicable

If exact anchor preservation cannot be implemented for all views, document the supported behavior and limitations.

## Non-Goals

Do not:

- Disable pagination.
- Hide the load-more indicator without fixing scroll behavior.
- Depend only on throttling or debouncing.
- Force users to manually manage scroll correction.
- Break existing `ScrollController` support.
- Break `.withProvider(...)` or `.withCubit(...)` constructors.
- Rewrite the full rendering system.

## Acceptance Criteria

The feature is accepted only if:

1. When new items are appended, the visible anchor item remains stable.
2. The scroll position does not remain stuck inside the load-more trigger zone after append.
3. Fast repeated scrolling no longer causes automatic chained load-more calls after each append.
4. The next load-more can happen only after the user intentionally scrolls near the new end again.
5. The behavior works with externally provided `ScrollController`.
6. The behavior works with internal scroll controllers.
7. The behavior is tested for normal lists.
8. The behavior is tested for variable-height items if possible.
9. The behavior is tested with custom slivers if supported.
10. Existing API compatibility is preserved.
11. README and CHANGELOG document the new scroll anchor preservation behavior.
