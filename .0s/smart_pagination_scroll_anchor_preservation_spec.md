# Spec Kit Feature Prompt — Preserve Scroll Anchor After Appending New Items

## Feature Title

```markdown
Preserve scroll anchor after appending new paginated items
```

## وصف المشكلة

ما زالت مشكلة التحميل المتكرر تظهر لأن مؤشر التمرير يبقى قريباً من أسفل القائمة بعد إضافة عناصر جديدة. عند إضافة الصفحة التالية إلى القائمة، لا يتم الحفاظ على موضع المستخدم بالنسبة للعنصر الذي توقف عنده، فيبقى الـviewport داخل منطقة تفعيل `load-more threshold`. نتيجة لذلك يتم إطلاق طلب تحميل جديد مباشرة، ثم آخر، ثم آخر، وكأن المستخدم لا يزال عند نهاية القائمة دائماً.

المشكلة ليست فقط في منع الطلبات المتزامنة. حتى لو تم منع الطلب أثناء التنفيذ، بعد انتهاء الطلب وإضافة العناصر الجديدة، قد يبقى scroll position في مكان يؤدي إلى تفعيل التحميل التالي فوراً. لذلك نحتاج إلى ميزة جديدة تحافظ على تركيز التمرير على **العنصر المرجعي / anchor item** الذي كان مرئياً عند لحظة بدء تحميل الصفحة التالية.

الفكرة الأساسية: عند بدء `load more`، تحفظ المكتبة العنصر أو الفهرس أو المفتاح الذي كان المستخدم متوقفاً عنده. وبعد إضافة العناصر الجديدة وتحديث القائمة، تعيد المكتبة ضبط موضع التمرير بحيث يبقى نفس العنصر في نفس المنطقة المرئية تقريباً، بدلاً من ترك المؤشر عالقاً عند الأسفل.

---

# /speckit.specify Prompt

```markdown
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
```

---

# /speckit.clarify Prompt

```markdown
/speckit.clarify

Clarify the new scroll stability feature for preserving the user's scroll anchor after appending new paginated items in `smart_pagination`.

Important language rule:
All clarification questions must be bilingual: English first, then Arabic. Use the same numbering and preserve the same technical meaning in both languages.

Required format:

### Question N
**English:** ...
**Arabic:** ...

Focus only on questions that affect implementation decisions.

Clarify these topics:

1. Which visible item should be used as the scroll anchor.
2. Whether the anchor should be key-based, index-based, or offset-based.
3. Whether users must provide `itemKeyBuilder` for accurate preservation.
4. Whether the feature should be enabled by default.
5. How to handle variable-height list items.
6. How to handle GridView and StaggeredGridView.
7. How to handle reverse lists.
8. How to handle externally supplied `ScrollController`.
9. Whether anchor preservation should happen for append only or also insert/remove/update.
10. How to prevent load-more trigger re-entry after append.
11. Whether a post-frame correction is allowed.
12. Whether temporary trigger suppression is needed after append.
13. How to test the behavior with widget tests.

Do not ask generic questions.
Ask only questions that help decide the design and implementation.
```

---

# /speckit.plan Prompt

```markdown
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
```

---

# /speckit.tasks Prompt

```markdown
/speckit.tasks

Generate an actionable task list for implementing scroll anchor preservation after appending new paginated items in `smart_pagination`.

The task list must be test-first and incremental.

Required phases:

1. Audit current scroll trigger and append behavior.
2. Add failing widget test reproducing repeated load-more after append.
3. Add test for anchor capture before load-more.
4. Add test for anchor preservation after append.
5. Add test for suppressing load-more until next user scroll.
6. Add internal anchor state model.
7. Implement anchor capture before load-more.
8. Implement post-append anchor restoration.
9. Implement trigger re-entry suppression.
10. Integrate with request guard and end-of-list guard.
11. Add support/fallback for supported view types.
12. Add reverse-list tests if reverse mode is supported.
13. Add variable-height item tests if possible.
14. Update README and CHANGELOG.
15. Run analysis and tests.

Each task must include:

- Task ID.
- Title.
- Files likely affected.
- Description.
- Acceptance criteria.
- Dependencies.
- Whether it can run in parallel.

Do not implement code yet.
Generate tasks only.
```

---

# Short GitHub Issue Description

```markdown
Fast scrolling still causes chained load-more calls because after new items are appended, the scroll position remains inside the load-more threshold. The package must preserve the user's scroll anchor after append so the same visible item remains stable and load-more does not immediately re-trigger without a new user scroll.
```

