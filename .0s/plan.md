/speckit.plan

Create a technical implementation plan for a new scroll stability feature in `smart_pagination`: preserve the user's scroll anchor after appending new paginated items.

## Technical Context

The package supports multiple paginated Flutter views and triggers load-more when the user scrolls near the end of the list.

A bug remains because after new items are appended, the scroll position may still be near the end threshold. This causes immediate chained load-more requests without a new intentional scroll gesture from the user.

The fix must combine load-more guarding with viewport anchor preservation.

## Required Plan Sections

### 1. Executive Summary

Explain why request guards alone are not enough and why scroll anchor preservation is required.

### 2. Current Scroll Behavior Review

Inspect and document:

- Where scroll notifications are handled.
- How the invisible items threshold is calculated.
- How load-more is triggered.
- How appended items affect scroll metrics.
- How the scroll controller is managed.
- How external scroll controllers are supported.
- How custom slivers and animated list updates affect scroll position.

### 3. Root Cause Analysis

Identify why the issue happens:

- The viewport remains near the bottom after append.
- The threshold condition remains true after new items are inserted.
- Scroll notifications or rebuilds trigger load-more again.
- New content does not shift the user's visual focus away from the trigger area.
- The list does not preserve the item the user was viewing before append.

### 4. Anchor Capture Strategy

Define how to capture the scroll anchor before load-more starts.

Evaluate:

- First visible item as anchor.
- Last visible item before loading indicator as anchor.
- Center visible item as anchor.
- Item at current scroll focus point.
- Index-based anchor.
- Key-based anchor using `itemKeyBuilder`.
- Offset-based anchor using scroll pixel delta.

The plan must recommend the safest default strategy.

### 5. Anchor Restore Strategy

Define how to restore or preserve position after new items are appended.

Evaluate:

- Using `ScrollController.jumpTo(...)` with offset delta.
- Using item position observers if available.
- Using `findChildIndexCallback` where supported.
- Using post-frame correction after rebuild.
- Using sliver-aware correction for custom slivers.
- Avoiding visible jump or flicker.

### 6. Trigger Re-entry Prevention

Define how to prevent immediate load-more re-trigger after append.

Cover:

- Temporary suppression until the next user scroll event.
- Suppression until scroll metrics change meaningfully.
- Requiring the user to leave and re-enter threshold area.
- Using a `lastLoadMoreAnchorKey` or `lastLoadMoreScrollOffset`.
- Avoiding repeated load-more from rebuild-only notifications.

Important:
The feature should not permanently disable load-more. It should only prevent automatic chained triggers caused by append/rebuild stabilization.

### 7. Interaction with Request Guard

Explain how this feature works with the existing load-more guard.

The final behavior should include:

- Request guard prevents concurrent duplicate requests.
- End-of-list logic stops loading after the final page.
- Anchor preservation prevents viewport from staying inside the trigger zone after append.
- Trigger re-entry guard prevents rebuild-caused fetch loops.

### 8. View-Type Support Plan

Plan behavior for:

- ListView
- GridView
- SliverList
- SliverGrid
- CustomScrollView
- StaggeredGridView
- PageView
- ReorderableListView

For each view type, define:

- Supported.
- Partially supported.
- Not supported yet.
- Required fallback behavior.

### 9. Reverse List Support

If the package supports reverse scrolling, define how anchor preservation works when:

- Newer items are at bottom.
- Older items are loaded at top.
- `reverse == true`.
- Chat-like lists append or prepend items.

### 10. Variable Height Items

Define behavior when item heights are not fixed.

Cover:

- Why index-based offset is unsafe with variable heights.
- Whether key-based anchors are required.
- Whether observer-based item position tracking is needed.
- How to avoid visible jumps.

### 11. Public API Design

Decide whether new options are needed.

Possible options:

- `preserveScrollAnchorOnAppend`
- `scrollAnchorStrategy`
- `loadMoreTriggerPolicy`
- `suppressLoadMoreUntilUserScrolls`
- `itemKeyBuilder` requirement or recommendation

Avoid adding public API unless necessary.

### 12. Internal State Model

Determine whether internal state is needed:

- `lastAnchorKey`
- `lastAnchorIndex`
- `lastAnchorScrollOffset`
- `lastLoadMoreTriggerOffset`
- `isRestoringScrollAnchor`
- `suppressLoadMoreUntilUserScroll`
- `lastUserScrollGeneration`
- `lastAppendOperationId`

### 13. Tests Required

Add tests for:

- Fast scrolling to bottom triggers one load-more.
- After append, scroll anchor remains stable.
- After append, load-more is not triggered again without user scroll.
- User scrolls again near new end and load-more can trigger correctly.
- Variable-height items do not cause repeated chained fetches.
- External `ScrollController` still works.
- Internal `ScrollController` still works.
- End-of-list still stops loading.
- Error state does not break anchor restoration.
- Refresh resets anchor state.
- Reload resets anchor state.
- Filter/search reset clears anchor state.
- Custom sliver case if supported.
- Reverse list behavior if supported.

### 14. Documentation Plan

Update:

- README.md
- CHANGELOG.md
- Load-more behavior docs
- Scroll anchor preservation docs
- Known limitations for view types
- Recommended use of `itemKeyBuilder`
- Troubleshooting section for fast scroll repeated fetching

### 15. Implementation Phases

Break implementation into phases:

1. Add failing widget test reproducing repeated chained load-more after append.
2. Add tests for anchor capture and restoration.
3. Add internal anchor capture model.
4. Add post-append anchor restoration.
5. Add trigger re-entry suppression.
6. Integrate with request guard and end-of-list guard.
7. Add support/fallback per view type.
8. Update docs and changelog.
9. Run analysis and tests.

### 16. Acceptance Criteria

The implementation is accepted only if:

- The user's viewport remains stable after appending new items.
- Appending a page does not automatically trigger the next page unless the user scrolls again.
- The feature works with the load-more request guard.
- The feature works with end-of-list logic.
- No visible infinite fetch loop remains during fast scroll testing.
- Behavior is tested and documented.

Do not implement code yet.
Produce the plan only.