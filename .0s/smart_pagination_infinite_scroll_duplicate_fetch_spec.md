# Spec Kit Feature Prompt — Prevent Infinite Duplicate Page Fetching During Fast Scrolling

## وصف مختصر للمشكلة

عند استخدام مكتبة `smart_pagination`، تظهر مشكلة عند تنفيذ scrolling سريع ومتكرر باتجاه نهاية القائمة. عند الاقتراب من نهاية العناصر، يقوم منطق التحميل باستدعاء جلب الصفحة التالية بشكل متكرر وسريع، حتى قبل انتهاء الطلب السابق أو قبل تحديث حالة `hasReachedEnd` / `isLoadingMore` بشكل صحيح.

النتيجة هي أن المكتبة تدخل في حلقة تحميل غير منضبطة، حيث تستمر بطلب صفحات جديدة بدون توقف، وقد تظهر نفس الصفحات أو عناصر مكررة، أو يتم تجاوز حدود النهاية، أو تستمر طلبات الشبكة حتى بعد الوصول الفعلي لآخر صفحة.

هذه المشكلة يجب التعامل معها كميزة إصلاح واستقرار جديدة في Spec Kit، وليست مجرد تعديل بسيط، لأنها تؤثر على:

- منطق pagination الأساسي.
- حماية الطلبات المتزامنة.
- منع تكرار fetch للصفحة نفسها.
- منطق الوصول إلى النهاية.
- تجربة المستخدم أثناء scroll سريع.
- الأداء واستهلاك الشبكة والذاكرة.
- تكامل `FuturePaginationProvider` و`StreamPaginationProvider` مع `SmartPaginationCubit`.

---

# /speckit.specify Prompt

```markdown
/speckit.specify

Add a new stability feature to the existing Flutter/Dart package `smart_pagination` to prevent infinite duplicate page fetching during rapid repeated scrolling.

## Problem

When the user scrolls quickly and repeatedly near the end of a paginated list, the package may trigger `load more` many times before the previous request finishes or before pagination state is updated correctly.

This causes uncontrolled repeated fetching of next pages. The list may keep requesting pages indefinitely, even when the end should have been reached. It may also fetch the same page multiple times, append duplicate data, skip correct stop conditions, or keep network/API calls running without a valid need.

The issue is visible when fast scroll gestures repeatedly hit the invisible-items threshold near the bottom of the list. The pagination trigger fires again and again while the previous load-more operation is still pending or while the cubit has not yet committed the next-page state.

## Goal

Implement robust load-more guarding so the package never starts duplicate, overlapping, stale, or unnecessary page requests during fast scrolling.

The package must correctly stop fetching when it reaches the end of available data.

## Core Requirements

1. Only one load-more request may be active per pagination scope at a time.
2. Repeated scroll notifications while `isLoadingMore == true` must not start another fetch.
3. The same page/request/cursor must not be fetched multiple times concurrently.
4. The cubit must ignore stale load-more responses from old request generations.
5. `hasReachedEnd` must reliably prevent additional load-more calls.
6. Empty or short page responses must mark the list as ended when appropriate.
7. Errors must not mark the list as ended incorrectly.
8. Refresh, reload, search change, and filter change must reset the load-more guard and end state safely.
9. Fast scrolling must not create an infinite fetch loop.
10. The UI must remain responsive and must not repeatedly append loading indicators.

## Expected User Behavior

When the user scrolls fast near the end:

- The first valid load-more request starts.
- Additional scroll threshold events are ignored while that request is active.
- When the request succeeds, the next page is appended once.
- If the returned page indicates there is no more data, loading stops permanently for that scope.
- If there is more data, a future load-more may happen only after the current request completes and the user reaches the threshold again.

## Non-Goals

Do not:

- Rewrite the whole package.
- Replace the Cubit architecture.
- Remove `.withProvider(...)` or `.withCubit(...)`.
- Break existing public API usage.
- Hide duplicate items silently without explicit identity rules.
- Treat API errors as end-of-list.
- Disable pagination entirely.

## Acceptance Criteria

The feature is accepted only if:

1. Fast repeated scrolling cannot trigger multiple simultaneous load-more requests.
2. The same page is not fetched twice concurrently.
3. The provider is not called again after `hasReachedEnd == true`.
4. Empty load-more response stops further loading for the current scope.
5. Short page response stops further loading when using page-size based pagination.
6. Errors do not set `hasReachedEnd` to true.
7. Refresh/reload resets the guards correctly.
8. Search/filter changes reset the guards correctly.
9. Stale responses cannot append items or change end state.
10. Unit/widget tests reproduce the fast-scroll issue and prove it is fixed.
11. README and CHANGELOG document the behavior.
```

---

# /speckit.clarify Prompt

```markdown
/speckit.clarify

Clarify the new stability feature for preventing infinite duplicate page fetching during rapid repeated scrolling in `smart_pagination`.

Important language rule:
All clarification questions must be bilingual: English first, then Arabic. Use the same numbering and preserve the same technical meaning in both languages.

Required format:

### Question N
**English:** ...
**Arabic:** ...

Focus only on questions that affect implementation decisions.

Clarify these topics:

1. Whether pagination is page-number based, cursor-based, or both.
2. How the package should identify duplicate load-more requests.
3. Whether the same page can be retried after failure.
4. Whether fast scroll events should be throttled, debounced, or guarded by state only.
5. Whether `isFetching`, `isLoadingMore`, and `hasReachedEnd` are sufficient guards.
6. How empty pages should be handled.
7. How short pages should be handled.
8. How cursor metadata should define end-of-list.
9. How stream-based providers should stop loading more page streams.
10. How refresh/reload/search/filter resets should clear the guard state.
11. Whether duplicate item handling should be part of this feature or handled separately.
12. What tests are required to reproduce the bug.

Do not ask generic questions.
Ask only questions that help decide the design and implementation.
```

---

# /speckit.plan Prompt

```markdown
/speckit.plan

Create a technical implementation plan for a new stability feature in `smart_pagination`: prevent infinite duplicate page fetching during rapid repeated scrolling.

## Technical Context

The package is a Flutter/Dart pagination library that uses `SmartPaginationCubit`, provider-based data sources, and UI widgets such as ListView, GridView, PageView, StaggeredGridView, and other pagination views.

The bug appears when scroll notifications repeatedly trigger load-more near the end of the list. Because fast scrolling can fire multiple threshold events, the cubit/provider pipeline may start repeated next-page requests without waiting for the active request to finish or without respecting the final end state.

## Required Plan Sections

### 1. Executive Summary

Explain the bug, its impact, and the proposed high-level fix.

### 2. Current Load-More Flow Review

Inspect and document:

- Where scroll threshold detection happens.
- Where `fetchPaginatedList()` or load-more is triggered.
- How `isFetching` is used.
- How `isLoadingMore` is emitted.
- How `_currentRequest` is advanced.
- How `hasReachedEnd` is calculated.
- How `PaginationMeta.hasNext` is calculated.
- How stale request tokens are used.
- How first-page loading differs from load-more loading.

### 3. Root Cause Analysis

Identify possible causes:

- Scroll threshold fires repeatedly before state changes.
- `isFetching` is not checked early enough.
- `isLoadingMore` is updated after multiple calls already entered.
- Same page request is built multiple times.
- End-of-list state is not committed before new threshold events.
- Empty page is appended or ignored incorrectly.
- Stale response modifies current state.
- Race condition between scroll notifications and cubit state emission.
- Stream provider may register new page streams repeatedly.

### 4. Load-More Guard Design

Design a robust guard that prevents duplicate fetching.

The plan must cover:

- A per-scope `isLoadMoreInFlight` guard.
- A request generation token.
- A unique request/page/cursor key.
- A set of active request keys.
- A set of completed/end request keys if needed.
- Blocking provider calls when `hasReachedEnd == true`.
- Blocking provider calls when the same request key is already active.
- Ignoring stale responses from old generations.

### 5. Scroll Trigger Protection

Define how UI scroll events should be handled.

Evaluate:

- State-based guard only.
- Throttle scroll-triggered load-more calls.
- Debounce scroll-triggered load-more calls.
- Post-frame scheduling to avoid repeated same-frame triggers.
- Threshold hysteresis so the same viewport position does not repeatedly trigger load more.

Important:
The main fix should be in the cubit/request guard, not only in the widget layer. Widget throttling may be added as a secondary protection.

### 6. End-of-List Stop Logic

Define exactly when loading must stop.

Cover:

- `returnedItems.length < pageSize` means end for offset/page-size pagination.
- `returnedItems.isEmpty` on load-more means end and must not append an empty page.
- `hasNext == false` means end when server metadata exists.
- `nextCursor == null` means end for cursor pagination.
- Error does not mean end.
- Stale empty response does not mean end.
- Refresh/reload/search/filter resets end state.

### 7. Future Provider Behavior

Plan behavior for `PaginationProvider.future(...)`:

- Prevent duplicate active future requests.
- Do not fetch same page twice concurrently.
- Ignore stale future responses.
- Do not call provider after end state.
- Preserve load-more error state without marking end.

### 8. Stream Provider Behavior

Plan behavior for `PaginationProvider.stream(...)`:

- Do not register duplicate page streams for the same request key.
- If stream accumulation is enabled, page 1 stream remains active and page 2 stream is added only once.
- Once end is reached, do not register more page streams.
- Existing active streams remain active until reset, eviction, completion policy, or dispose.
- Stale scope stream emissions are ignored.

### 9. Merged Stream Provider Behavior

Plan behavior for `PaginationProvider.mergeStreams(...)`:

- Prevent repeated registration from fast scroll events.
- Respect end-of-list state.
- Cancel and cleanup on reset/dispose.
- Avoid duplicate subscriptions for identical stream keys.

### 10. State Model Updates

Determine whether new internal state is needed:

- `activeLoadMoreRequestKey`
- `activeRequestKeys`
- `lastCompletedRequestKey`
- `requestGeneration`
- `paginationScopeId`
- `hasReachedEnd`
- `lastLoadMoreTriggeredAt`
- `isLoadMoreInFlight`

Do not expose internal fields publicly unless necessary.

### 11. Error Handling Plan

Define:

- First-page error behavior.
- Load-more error behavior.
- Retry after load-more error.
- Whether retry can use the same request key after failure.
- Whether failed request key should be removed from active keys.
- How to prevent immediate repeated failure loops during fast scrolling.

### 12. Tests Required

Add tests for:

- Fast repeated scroll calls trigger only one provider call.
- Multiple immediate `fetchPaginatedList()` calls trigger only one load-more request.
- Same page is not fetched twice while in flight.
- Load-more success clears the in-flight guard.
- Load-more error clears the in-flight guard but does not mark end.
- Retry after error is possible only through valid retry path.
- Empty load-more response marks end.
- Short load-more response marks end for page-size pagination.
- After end, additional scroll triggers do not call provider.
- Refresh resets end and in-flight guards.
- Reload resets end and in-flight guards.
- Filter/search reset clears old request keys.
- Stale response from old generation is ignored.
- Stale empty response does not mark current scope ended.
- Stream provider does not register duplicate page stream for same request.
- Accumulated stream provider stops registering new streams after confirmed end.
- Widget-level scroll simulation reproduces the original bug and verifies the fix.

### 13. Documentation Plan

Update:

- README.md with load-more safety behavior.
- CHANGELOG.md with bug fix / stability feature.
- Provider documentation.
- End-of-list documentation.
- Fast scrolling behavior notes.
- Retry behavior notes.

### 14. Implementation Phases

Break implementation into phases:

1. Add failing tests reproducing fast-scroll infinite fetching.
2. Add request key and in-flight guard tests.
3. Implement cubit-level load-more guard.
4. Add stale generation protection where missing.
5. Fix end-of-list state transitions.
6. Add stream registration guard.
7. Add widget-level throttle/hysteresis only if cubit guard is not enough.
8. Update docs and changelog.
9. Run analysis and tests.

### 15. Acceptance Criteria

The plan is accepted only if it prevents infinite fetching at the cubit/provider level, not only visually in the UI.

The final implementation must prove that rapid repeated scrolling cannot create duplicate page fetches, cannot bypass end-of-list state, and cannot leave the cubit stuck in loading state.

Do not implement code yet.
Produce the plan only.
```

---

# /speckit.tasks Prompt

```markdown
/speckit.tasks

Generate an actionable task list for implementing the `smart_pagination` stability feature that prevents infinite duplicate page fetching during rapid repeated scrolling.

The task list must be test-first and incremental.

Required phases:

1. Audit current load-more trigger path.
2. Add failing tests that reproduce rapid-scroll duplicate fetches.
3. Add tests for duplicate request keys.
4. Add tests for end-of-list stop behavior.
5. Add tests for stale responses.
6. Implement cubit-level in-flight load-more guard.
7. Implement request key tracking.
8. Implement stale generation guard if missing.
9. Fix end-of-list transitions.
10. Fix stream provider duplicate page stream registration.
11. Add widget-level scroll trigger protection only if needed.
12. Update README and CHANGELOG.
13. Run analysis and tests.

Each task must include:

- Task ID.
- Title.
- Files likely affected.
- Description.
- Acceptance criteria.
- Dependencies.
- Whether it can be done in parallel.

Do not implement code yet.
Generate tasks only.
```

---

# Short Problem Statement for GitHub Issue or Feature Title

```markdown
Fast repeated scrolling can trigger infinite duplicate load-more requests before pagination state reaches the end
```

---

# Arabic Summary

```markdown
عند التمرير السريع والمتكرر قرب نهاية القائمة، يتم إطلاق طلبات load-more بشكل متكرر قبل انتهاء الطلب السابق أو قبل تحديث حالة الوصول للنهاية. هذا يؤدي إلى حلقة تحميل غير منتهية، وتكرار جلب نفس الصفحات، واستهلاك زائد للشبكة والذاكرة. المطلوب إضافة حارس تحميل قوي يمنع الطلبات المتزامنة والمكررة، ويحترم حالة `hasReachedEnd`، ويميز بين الخطأ والنهاية الفعلية، ويمنع الاستجابات القديمة من التأثير على الحالة الحالية.
```

