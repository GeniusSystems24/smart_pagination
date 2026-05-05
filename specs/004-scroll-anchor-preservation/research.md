# Phase 0 Research — Scroll Anchor Preservation

**Branch**: `004-scroll-anchor-preservation` | **Date**: 2026-05-05 | **Plan**: [plan.md](plan.md)

This document records the technical decisions made during Phase 0, the alternatives considered, and the rationale. The five Spec Clarifications session decisions (Q1–Q5) are inputs to this phase, not outputs of it; this phase resolves the remaining technical "how" questions.

---

## R1 — How to identify the visible item range without writing a new observer

### Decision

Reuse the existing `scrollview_observer ^1.26.2` integration. The package already attaches a `ListObserverController` (line 238 of `paginate_api_view.dart`) and a `GridObserverController` (line 247) to the cubit. Both expose `dispatchOnceObserve()` which returns a model containing `displayingChildModelList` — a list of currently-rendered items with per-item `displayPercentage`, `index`, and `leadingEdge` / `trailingEdge` pixel offsets relative to the viewport.

### Rationale

- Zero new dependencies.
- Zero new scroll-watching mechanism.
- Already used by the cubit's public scroll-navigation API (`animateToIndex`, `jumpToIndex`), so the package is already battle-tested against this surface.
- `dispatchOnceObserve` runs synchronously in most paths (it inspects current render-tree state); when async, it's a single-frame callback. Capture-before-fetch can rely on the most recent in-memory snapshot, refreshed continuously via the observer's listener stream.

### Alternatives considered

| Alternative | Rejected because |
|---|---|
| Hand-roll a `ScrollController.addListener` mechanism that walks the render tree | Reinvents the wheel; would duplicate `scrollview_observer`'s logic and create two sources of truth for "what's visible". |
| Use `RenderSliverList.firstChild` / `lastChild` directly via `scrollController.position.context.notificationContext` | Tightly couples the package to internal Flutter render-object structure; fragile across Flutter versions. |
| Add a new package dependency (e.g., `visibility_detector`) | Adds a per-item widget overhead; `scrollview_observer` already provides equivalent data with no per-item cost. |

---

## R2 — Where to capture the anchor: widget side or cubit side

### Decision

Capture **at the widget side**, push the snapshot to the cubit synchronously via a new `@internal` method `captureAnchorBeforeLoadMore(snapshot)` immediately before the existing `widget.fetchPaginatedList?.call()` invocation in each item builder's post-frame callback.

### Rationale

- The observer controllers are wired up at the widget side (`paginate_api_view.dart:238`); the widget is the natural owner of the visible-items snapshot.
- The cubit cannot synchronously query the observer because the observer is keyed off a `ScrollController` that the cubit doesn't directly own (it's stored in the widget's state).
- Pushing the snapshot from widget → cubit makes the cubit the single source of truth for anchor *state* without having to know about the observer plumbing. Tests exercising the cubit alone can construct snapshots manually.
- The push is synchronous: the snapshot is already in memory (continuously updated by the observer's listener); the cubit method is a simple field set.

### Alternatives considered

| Alternative | Rejected because |
|---|---|
| Have the cubit hold the observer controller as the canonical reference and `dispatchOnceObserve` on demand | Couples the cubit to the `scrollview_observer` lifecycle; complicates the cubit's existing scroll-navigation methods (which already work this way but are read-only); breaks separation between "data state" and "render state". |
| Capture lazily inside `_fetch` after `await provider(request)` returns | Too late — the viewport is in pre-restore state by then, so the snapshot reflects the in-flight fetch's pre-append state, but only by accident. Ordering becomes implicit instead of explicit. Risk of snapshotting at a moment that subtly differs from "user's intent at trigger time". |
| Capture in a global `WidgetsBinding.instance.addPostFrameCallback` after the `loadedState` change | Fires after the new items are already laid out; the snapshot would describe the *post-append* viewport, which is exactly the wrong moment. |

---

## R3 — How to discriminate user-initiated vs. programmatic scroll

### Decision

Treat a `ScrollNotification` as user-initiated if and only if it is a `ScrollStartNotification` with `dragDetails != null`. Track an internal `_anchorRestoreInFlight` flag on the cubit that suppresses any user-scroll signal arriving during the post-frame restore (defensive, even though `jumpTo` should not produce a `ScrollStartNotification` with `dragDetails`).

### Rationale

- `ScrollStartNotification.dragDetails != null` is the canonical Flutter signal that a user gesture (drag/touch) initiated the scroll. `controller.jumpTo` and `controller.animateTo` produce `ScrollStartNotification` with `dragDetails == null` (they go through the `position.beginActivity` path, not the gesture path).
- Filtering on `ScrollStartNotification` (not `ScrollUpdateNotification`) means we don't fire on every pixel-level update during a gesture — just once per gesture start. Cleaner semantics; cheaper.
- A fling continuing past the post-frame restore *will* fire a fresh `ScrollStartNotification` (the user lifted their finger and the ballistic activity carries on, which is a new activity start). Whether to count that as "user-initiated" is a judgment call; the plan counts it as user-initiated because the user did, in fact, drive the scroll velocity that started this fling.

### Alternatives considered

| Alternative | Rejected because |
|---|---|
| Filter on `ScrollUpdateNotification.dragDetails != null` | Fires on every pixel of a drag — too noisy for a one-shot flag-clearing trigger. The first one would clear the flag, making subsequent ones no-ops, but the bookkeeping is harder and unit-testing requires more boilerplate. |
| Use `ScrollMetrics.physics` or activity inspection via `position.activity` | Requires reflecting through internal Flutter state; not part of the public `ScrollNotification` surface; fragile across Flutter versions. |
| Time-based suppression window (e.g., 200 ms) | Spec Q3 explicitly rejected this. Duration tuning is fragile across devices. |
| Boolean "any scroll notification clears the flag" | Would clear on `jumpTo`'s synthetic notification, defeating the purpose. |

---

## R4 — Anchor restore mechanism by view type

### Decision

| View type | Restore mechanism |
|---|---|
| `ListView` (any) — observer attached | `_listObserverController.jumpTo(index: anchor.index, alignment: 1.0)` |
| `GridView` (any) — observer attached | `_gridObserverController.jumpTo(index: anchor.index, alignment: 1.0)` |
| `CustomScrollView` / sliver — observer attached | Same as ListView/GridView depending on which observer is active |
| `StaggeredGridView` — no observer | `controller.jumpTo(anchor.pixelsBefore)` |
| `PageView`, `ReorderableListView`, `reverse: true` | No-op (out of scope per Spec Q5) |

### Rationale

- `_listObserverController.jumpTo(index, alignment)` queries live render-tree state at jump time, so it correctly handles variable-height items and late layout settle. This is the ground truth for "land item N at position P" in this package.
- `alignment: 1.0` pins the *bottom edge* of the item to the bottom of the viewport. Combined with capturing "the last fully-visible item before the loading indicator" as the anchor, this restores the exact pre-append position: the same item, at the same on-screen location.
- `StaggeredGridView` has no observer because it uses `SingleChildScrollView` + `StaggeredGrid` rather than a sliver-based scrollview. Its trigger logic is offset-based (the 80 % `maxScrollExtent` rule). For append-only scope, the user's `pixels` value is unchanged by the append (new items extend below); a simple `controller.jumpTo(pixelsBefore)` is correct.

### Alternatives considered

| Alternative | Rejected because |
|---|---|
| `controller.jumpTo(pixelsBefore)` everywhere | Fails on variable-height items: late layout settle moves items from pre-capture pixel positions, so `pixelsBefore` may now point to a different visual position. |
| `Scrollable.ensureVisible(anchorContext)` | Requires a `BuildContext` for the anchor item, which the package doesn't have at restore time (the post-frame may run after the item's render object has rebuilt under a different element). The observer's index-based jump is more robust. |
| `findChildIndexCallback` to find the new index, then a custom pixel computation | The observer already does this internally; reimplementing is duplicate work. |
| Animate the restore (`animateTo` instead of `jumpTo`) | An animation between the wrong and right offset would be visible flicker — exactly what we're trying to avoid. The post-frame restore must be instant. |

---

## R5 — How to suppress the synthetic scroll notification produced by anchor restore

### Decision

Set an `_anchorRestoreInFlight` flag on the cubit before scheduling the post-frame restore; clear it after the `jumpTo` call returns and one frame has passed (`await SchedulerBinding.instance.endOfFrame`). While the flag is set, `markUserScroll()` is a no-op.

### Rationale

- `controller.jumpTo()` and `_listObserverController.jumpTo()` both produce a `ScrollStartNotification`, but with `dragDetails == null`. Per R3's decision, we already filter on `dragDetails != null`, so the synthetic notification is naturally ignored.
- The `_anchorRestoreInFlight` flag is **defense in depth**: if a future Flutter version or a code path we haven't anticipated produces a `ScrollStartNotification` with non-null `dragDetails` during the restore, the flag still suppresses the spurious user-scroll signal.
- The flag is cleared on the next frame boundary, not synchronously after `jumpTo`, because the notification dispatch happens during the frame's notification phase, not during the call.

### Alternatives considered

| Alternative | Rejected because |
|---|---|
| Skip the flag and rely solely on `dragDetails` filtering | Works in current Flutter, but a cross-version regression could silently break the suppression. The flag costs one bool. |
| Use `ScrollNotificationObserver` to register/unregister around the jump | Heavier; introduces a tree-walk for every notification; the flag is O(1). |
| Save the pre-jump `pixels` and ignore notifications until pixels match | Brittle on async settle; works for the immediate jump but not for continued layout settle in the same frame. |

---

## R6 — Generation tracking for anchor invalidation

### Decision

Reuse the existing `_generation` counter (introduced by feature `002-stabilize-provider`). When `captureAnchorBeforeLoadMore` is called, snapshot `generation: _generation`. At restore time, compare `_pendingAnchor.generation == _generation`; mismatch → discard. Scope-reset paths (`_resetToInitial`, `refreshPaginatedList`, `dispose`) already bump `_generation`.

### Rationale

- No new generation counter needed.
- The existing counter is already the canonical "scope identity" marker in the cubit; aligning anchor invalidation with it means anchor state automatically follows the established scope-reset semantics with zero new bookkeeping.
- A mismatched generation is the only condition under which the captured anchor's index/key may no longer be meaningful (because items were potentially replaced wholesale). All other cases (success, error, normal completion) keep `_generation` stable.

### Alternatives considered

| Alternative | Rejected because |
|---|---|
| Introduce `_anchorGeneration` independent of `_generation` | Two counters, two reset paths to keep in sync; redundant. |
| Use `_currentRequest` identity (`identical(snapshot.requestRef, _currentRequest)`) | `_currentRequest` is updated on success, not on scope reset; doesn't capture all the cases where the anchor should be invalidated. |
| No invalidation; trust `findChildIndexCallback` to return null on missing keys | Works for missing-key case but doesn't cover "anchor item was deleted by an external mutation while we were fetching"; the generation check covers both. |

---

## R7 — Capture for `StaggeredGridView` without an observer

### Decision

For `StaggeredGridView`, capture an offset-based snapshot:

```text
PendingScrollAnchor {
  strategy: AnchorStrategy.offset,
  pixelsBefore: controller.position.pixels,
  extentBefore: controller.position.maxScrollExtent,
  generation: _generation,
}
```

Restore via `controller.jumpTo(pixelsBefore)` only if `pixelsBefore < controller.position.maxScrollExtent` (defensive against negative scenarios). No `index` or `key` is captured.

### Rationale

- `StaggeredGridView` in this package uses `SingleChildScrollView` + `StaggeredGrid.count(children: [...])`. It does not use the `scrollview_observer` integration; the observer was not designed for this layout.
- For append-only scope (FR-001a), the user's `pixels` value is preserved by the append: new items extend `maxScrollExtent` downward; the user's offset is unchanged. So `controller.jumpTo(pixelsBefore)` lands the user at the exact same pixel position as before — which means the same on-screen content, since nothing visible above the viewport changed.
- `extentBefore` is captured for diagnostic / future use only; the v1 restore path doesn't use it.

### Alternatives considered

| Alternative | Rejected because |
|---|---|
| Add an observer integration for `StaggeredGridView` | The `scrollview_observer` package doesn't support `StaggeredGrid`'s non-sliver layout. Adding it would require either a fork or a parallel mechanism — outside this feature's scope. |
| Use a `ValueKey` lookup via `findChildIndexCallback` | `StaggeredGrid` is built with a `children: [...]` list directly (line 897 of `paginate_api_view.dart`); there's no `findChildIndexCallback` surface. Adding one would require restructuring the view to use a sliver-based delegate, which is out of scope. |
| Skip support for `StaggeredGridView` entirely | The monorepo uses staggered grids in real screens (galleries). Skipping would leave the bug unfixed for them. Offset-delta is correct for append-only scope. |

---

## R8 — Test infrastructure for fast-scroll regression

### Decision

Use `tester.fling(finder, Offset(0, -2000), 5000)` (downward fling at 5000 px/s) inside `testWidgets`, followed by `await tester.pumpAndSettle(Duration(milliseconds: 100))` to let the ballistic complete. Assertions are on:

1. `mockProvider.callCount` — exact value (initial + intentional load-mores only).
2. The position of the captured anchor's row index in the post-append viewport (read via the observer's `dispatchOnceObserve` after the test's `pumpAndSettle`).

### Rationale

- `tester.fling` is the canonical way to simulate a fast user scroll in widget tests. Combined with a mock provider that records every call, it gives an unambiguous regression signal.
- `pumpAndSettle` runs all pending frames including the post-frame restore. After it returns, the test can assert on the final state.
- Reading the observer's snapshot in the assertion phase gives row-level fidelity, which matches Spec SC-001's "±1 row/cell" tolerance.

### Alternatives considered

| Alternative | Rejected because |
|---|---|
| `tester.drag` (single drag) | Doesn't simulate fast scroll well; a slow drag rarely crosses the threshold multiple times in chained fashion. `fling` is the right primitive for the bug. |
| `tester.scrollUntilVisible` | Stops as soon as a target is visible; doesn't simulate runaway scroll. |
| Pixel-level assertions on `controller.position.pixels` | Brittle across platforms (different scroll physics, different device pixel ratios). Row-level assertions are platform-stable. |

---

## R9 — Observer snapshot freshness

### Decision

Subscribe to the observer's `onObserve` callback and update `_lastObservedSnapshot` on every call. The observer fires on every meaningful viewport change (scroll, layout settle); the in-memory snapshot is therefore always within one frame of current reality.

### Rationale

- `dispatchOnceObserve(isForce: true)` works but adds latency (it triggers a frame schedule in some configurations). Continuous subscription is cheaper and gives synchronous access.
- The observer already supports this via `controller.controller!.position.addListener(...)` internally; `onObserve` is the package-public callback.

### Alternatives considered

| Alternative | Rejected because |
|---|---|
| `dispatchOnceObserve(isForce: true)` synchronously inside the trigger site | Works but adds ~1 frame of delay; for the chained-load-more case, every frame of delay matters. |
| Read `RenderSliverList.firstChild`/`lastChild` directly | Bypasses the observer; reintroduces the duplicated-source-of-truth problem from R1. |

---

## R10 — Zero-breaking-change verification strategy

### Decision

Phase F adds tests that compile and run the README's existing `.withProvider(...)` and `.withCubit(...)` examples verbatim. Any source-level change to those examples constitutes a breaking change and fails the test.

### Rationale

- Per Constitution §II, README examples MUST remain valid until explicitly deprecated.
- A "compile and run" test is a stronger guarantee than a code review for backward compatibility.
- The new `preserveScrollAnchorOnAppend` parameter has a default value, so existing examples don't need to mention it.

### Alternatives considered

| Alternative | Rejected because |
|---|---|
| Manual code review of public API surface | Subjective; reviewers can miss subtle defaults or signature changes. Tests are deterministic. |
| Snapshot-test the `dart doc` output for the public API | Heavyweight; tooling-specific; hard to keep stable across Dart SDK versions. |

---

## Summary of resolved unknowns

| Topic | Status |
|---|---|
| Visible-items detection without new dependencies | ✅ Resolved (R1) |
| Capture timing and call site | ✅ Resolved (R2) |
| User-scroll vs. programmatic discrimination | ✅ Resolved (R3) |
| Restore mechanism by view type | ✅ Resolved (R4) |
| Suppressing the restore's own synthetic scroll | ✅ Resolved (R5) |
| Generation tracking for invalidation | ✅ Resolved (R6) |
| `StaggeredGridView` capture without observer | ✅ Resolved (R7) |
| Fast-scroll regression test infrastructure | ✅ Resolved (R8) |
| Observer snapshot freshness | ✅ Resolved (R9) |
| Zero-breaking-change verification strategy | ✅ Resolved (R10) |

No `[NEEDS CLARIFICATION]` markers remain.
