# Feature Specification: Scroll Anchor Preservation

**Feature Branch**: `004-scroll-anchor-preservation`
**Created**: 2026-05-05
**Status**: Draft
**Input**: User description: "Add a new scroll stability feature to the existing Flutter/Dart package smart_pagination: preserve the user's scroll anchor after appending new paginated items."

## Clarifications

### Session 2026-05-05

- Q: Which scroll anchor strategy should the package use as its default, and should consumers be required to provide an `itemKeyBuilder`? → A: Hybrid — key-based when consumer supplies `itemKeyBuilder`, otherwise fall back to index-based for finite-item builders, and viewport-offset-delta for slivers / unknown-extent builders. `itemKeyBuilder` is optional, never required.
- Q: Which visible item should the package pick as the anchor at the moment a load-more fetch starts? → A: The last fully-visible item just before the loading indicator (excluding the trailing spinner slot). Anchoring on the user's actual reading position pins the viewport above every newly appended item and pushes the load-more threshold downward, defusing the chained-load-more bug at its root.
- Q: When and how should the package perform the viewport restore, and should it suppress further load-more triggers until the user scrolls again? → A: Schedule the viewport restore inside a post-frame callback (after the new items are laid out), AND keep the load-more callback suppressed until a user-initiated `ScrollNotification` is observed. This is the strongest correctness guarantee against chain-triggers from late layout settle.
- Q: Does anchor preservation apply only to the package's own load-more append, or also to other mutations (refresh, delete, manual insert, optimistic updates)? → A: Append-on-load-more only. Other mutations flow through with no automatic anchoring; consumers retain full control of scroll behavior for refresh, delete, and optimistic flows.
- Q: What is the scope of supported view types for v1, particularly regarding reverse lists, `PageView`, and `ReorderableListView`? → A: Standard scrollables only — `ListView`, `GridView`, `CustomScrollView`/slivers, and `StaggeredGridView` are fully supported. Reverse-direction lists (`reverse: true`), `PageView`, and `ReorderableListView` are explicitly out of scope for v1 and documented as such in the README; on those views the package falls through to existing behavior.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Stable viewport after appending a page (Priority: P1)

A consumer of `smart_pagination` is showing a long, scrollable list. The user scrolls quickly to the end of the visible items, which crosses the load-more threshold. The package fetches the next page and appends new items. The user expects the items they were just looking at to remain in the same visual location on screen — not to jump, snap to the bottom, or trigger a runaway chain of additional load-more requests.

**Why this priority**: This is the core promise of the feature. Without it, the load-more guard from the previous feature is undermined: even when only one request is in flight, the viewport can stay parked inside the trigger zone after each append, causing chained automatic loads, wasted bandwidth, and a disorienting reading experience. Solving this is what makes the package safe to use in real applications with fast scrollers.

**Independent Test**: Build a paginated list using the package, scroll fast to the bottom, observe that exactly one new page is appended per intentional scroll-to-bottom gesture, and that the item that was visible immediately before the append remains visible at approximately the same on-screen offset after the append.

**Acceptance Scenarios**:

1. **Given** a paginated list with 20 items per page where item 19 is currently the bottom-most visible item, **When** the user scrolls down past the load-more threshold and the next page is fetched and appended, **Then** item 19 remains visible at approximately the same vertical position in the viewport.
2. **Given** the same list immediately after a successful append, **When** no further user scroll input occurs, **Then** no additional load-more request is triggered.
3. **Given** the user continues scrolling down after a successful append, **When** the user reaches the new end of the list, **Then** the next load-more request is allowed to fire exactly once.

---

### User Story 2 - Anchor preservation across supported scrollable views (Priority: P2)

The package supports multiple scrollable view types. A consumer using a `GridView`, a `CustomScrollView` with slivers, or a `StaggeredGridView` expects the same stable behavior they get from a `ListView`. They do not want to discover that the anchor preservation only protects one view type and silently regresses on the others.

**Why this priority**: Many real consumers in this monorepo use grid and sliver layouts (galleries, feeds, mixed-content screens). If anchor preservation is silent and partial, those consumers will hit the chained-load-more bug again and assume the package is broken. Documenting which views are covered, with what fidelity, is therefore second only to making the primary list case work.

**Independent Test**: For each supported view type, run the same fast-scroll-to-end gesture and verify that either (a) the anchor is preserved with the same fidelity as in `ListView`, or (b) the documented fallback behavior takes effect (e.g., for views where exact anchor preservation is not feasible, the fallback still prevents chained load-more calls).

**Acceptance Scenarios**:

1. **Given** a `ListView`-backed paginated view, **When** a page is appended, **Then** the previously visible anchor item remains visible at approximately the same offset.
2. **Given** a `GridView`-backed paginated view, **When** a page is appended, **Then** the previously visible anchor item (or its row) remains visible at approximately the same offset.
3. **Given** a `CustomScrollView`/sliver-backed paginated view, **When** a page is appended, **Then** anchor preservation behaves as documented for slivers, and chained load-more calls do not occur.
4. **Given** a `StaggeredGridView`-backed paginated view, **When** a page is appended, **Then** anchor preservation behaves as documented for staggered grids, and chained load-more calls do not occur.
5. **Given** a `reverse: true` list, a `PageView`, or a `ReorderableListView` (all out of scope for v1), **When** a page is appended, **Then** the package falls through to its prior behavior without throwing and without attempting an anchor capture/restore, and the README explicitly lists these views as unsupported in v1.

---

### User Story 3 - Compatibility with existing controllers and constructors (Priority: P2)

A consumer has already integrated the package using `.withProvider(...)` or `.withCubit(...)`, and may be passing in their own `ScrollController` to coordinate with other UI (e.g., a custom scroll-to-top button, a sticky header, or a parent scroll listener). They want to upgrade to the version with anchor preservation without changing their constructor calls or losing control of their scroll controller.

**Why this priority**: Compatibility is what makes this a drop-in upgrade rather than a migration. If anchor preservation requires consumers to refactor their controller wiring, adoption stalls and the bug stays in production.

**Independent Test**: Take an existing app screen that uses `.withProvider(...)` with an externally provided `ScrollController`, upgrade the package version, run it without any code changes, and confirm both that anchor preservation works and that the external controller still receives scroll events and reflects accurate offsets.

**Acceptance Scenarios**:

1. **Given** a consumer using `.withProvider(...)` with no explicit `ScrollController`, **When** they upgrade to the version with this feature, **Then** anchor preservation works with the package's internally managed controller and no API changes are required.
2. **Given** a consumer using `.withCubit(...)` with an externally provided `ScrollController`, **When** they upgrade to the version with this feature, **Then** anchor preservation works without taking ownership of the external controller, and the consumer's own scroll listeners continue to fire correctly.
3. **Given** any consumer's existing call site, **When** they upgrade, **Then** no constructor signature, parameter name, or default behavior changes in a backwards-incompatible way.

---

### Edge Cases

- **Empty page returned**: Server responds with zero new items. The viewport should remain exactly where it was, and no further automatic load-more should fire.
- **Anchor item removed before restore**: The captured anchor item is removed from the list (e.g., due to a concurrent refresh or filter change) between capture and restore. The package falls back to a documented strategy (e.g., nearest stable item or viewport-offset delta) without crashing or jumping to the bottom.
- **Variable-height items**: Items have heights that depend on async-loaded content (images, expandable text). The anchor must remain visually stable even when item heights settle after layout.
- **Very small lists**: The list shorter than the viewport receives a new page that fits in one screen. Anchor preservation must not produce a visible jump in this case.
- **Reverse-scrolled lists** (e.g., chat-style, `reverse: true`): Out of scope for v1 — the package MUST detect a reverse-direction scrollable and fall through to existing behavior without attempting an anchor capture or restore. No exceptions, no warnings; just a no-op for the anchor logic.
- **Rapid back-to-back triggers**: User scrolls, an append finishes, and the user immediately scrolls again past the new threshold. Each intentional pass should produce exactly one append; no chained automatic appends in between.
- **External `ScrollController` jumps**: Consumer code calls `controller.jumpTo()` or `animateTo()` while a load-more is in flight. The package's anchor restore must not fight the consumer-initiated jump.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The package MUST capture a scroll anchor describing the user's current viewport position immediately before initiating any load-more fetch.
- **FR-001a**: Anchor preservation MUST apply ONLY to the package's own load-more append flow. The package MUST NOT capture or restore anchors around other state mutations such as pull-to-refresh, item deletion, mid-list insertion, optimistic updates, or any consumer-initiated state change. For those mutations, the scroll position behavior MUST remain whatever the consumer's existing code produces.
- **FR-002**: The package MUST restore or preserve the viewport position relative to the captured anchor after new items have been appended and the list has been rebuilt, so that the anchor item remains visually stable.
- **FR-003**: The package MUST choose an anchor strategy at runtime using a hybrid policy: (a) when the consumer supplies an `itemKeyBuilder`, use the key of the chosen anchor item (key-based); (b) otherwise, for finite-item builders (`ListView.builder`, `GridView.builder`, `StaggeredGrid` with index-addressable items), use the integer index of the anchor item (index-based); (c) for `CustomScrollView`/sliver compositions or builders without a stable item index, fall back to a viewport-offset delta (offset-based). The package MUST document the strategy that was selected per supported view type.
- **FR-003a**: The `itemKeyBuilder` parameter MUST be optional. The package MUST NOT throw, log a warning, or otherwise penalize consumers who do not supply it; it MUST automatically use the index-based or offset-based fallback in that case.
- **FR-003b**: The package MUST select, as the anchor item, the last item that is fully visible in the viewport at the moment a load-more fetch is initiated, excluding the trailing loading-indicator slot. If no item is fully visible (e.g., the viewport is shorter than a single item), the package MUST fall back to the topmost partially-visible item; if no item is identifiable at all, the package MUST fall back to the offset-based strategy described in FR-003(c).
- **FR-004**: After a successful append-and-restore, the package MUST NOT trigger another load-more request unless the user produces additional intentional scroll input that crosses the threshold relative to the new end of the list.
- **FR-004a**: The viewport restore MUST be scheduled to run inside a post-frame callback (i.e., after the new items have been laid out by the framework), not synchronously at the moment the new items are emitted/added to state.
- **FR-004b**: Between the start of a load-more fetch and the next user-initiated scroll event observed after restore, the package MUST keep the load-more trigger callback in a suppressed state and MUST NOT initiate another load-more, even if scroll position notifications fire due to layout settle, image loads, or programmatic offset corrections originating from the restore itself.
- **FR-005**: The package MUST preserve anchor behavior when an externally provided `ScrollController` is used, without taking exclusive ownership of that controller and without suppressing the consumer's own scroll listeners.
- **FR-006**: The package MUST preserve anchor behavior when no external `ScrollController` is provided, using its internal controller.
- **FR-007**: The package MUST implement anchor preservation for these view types in v1: `ListView`, `GridView`, `CustomScrollView`/sliver variants, and `StaggeredGridView`. Reverse-direction lists (`reverse: true`), `PageView`, and `ReorderableListView` are explicitly OUT OF SCOPE for v1; on those views the package MUST fall through to its prior behavior without throwing, and the README MUST list them as unsupported with that explicit fall-through note.
- **FR-008**: The package MUST handle the edge case where the captured anchor item is no longer present in the list at restore time, falling back to a documented secondary strategy (e.g., nearest stable item or viewport-offset delta) without throwing.
- **FR-009**: The package MUST NOT introduce breaking changes to the `.withProvider(...)` or `.withCubit(...)` constructors, their parameter names, defaults, or call-site contracts.
- **FR-010**: The package MUST NOT rely solely on throttling, debouncing, or hiding the load-more indicator to mitigate the chained-load-more bug; the fix MUST address scroll position directly.
- **FR-011**: The package MUST NOT require consumers to write manual scroll-correction code to obtain the new behavior; anchor preservation MUST be the default, on-by-default behavior of paginated views.
- **FR-012**: The package MUST include automated tests covering: (a) anchor preservation in a normal list, (b) anchor preservation with variable-height items where feasible, and (c) anchor preservation with custom slivers where supported.
- **FR-013**: The package's `README.md` and `CHANGELOG.md` MUST be updated to describe the new scroll anchor preservation behavior, including the per-view-type support matrix and any documented fallbacks.

### Key Entities *(include if feature involves data)*

- **Scroll Anchor**: A snapshot taken immediately before a load-more fetch that identifies a stable reference point in the visible viewport. Attributes: anchor strategy used (key/index/offset/etc.), reference value (e.g., the item key, the item index, or the pixel offset), and the viewport-relative offset of that reference at capture time.
- **Anchor Restore Outcome**: The result of attempting to restore the viewport after append. Attributes: whether the original anchor was found, which strategy was actually used (primary vs. fallback), and whether the load-more guard remains armed against chained triggers.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: When a user scrolls fast to the end of a paginated list and a page is appended, the previously visible anchor item remains within ±1 row/cell of its pre-append on-screen position in 100% of test runs across the supported view types.
- **SC-002**: After a single intentional scroll-to-end gesture, the package issues exactly one load-more request — never two or more chained automatic requests as a side effect of the append itself.
- **SC-003**: Consumers can upgrade to the version with this feature without changing any call site of `.withProvider(...)` or `.withCubit(...)`; zero source-level breaking changes are introduced.
- **SC-004**: The README contains a clear support matrix listing `ListView`, `GridView`, `CustomScrollView`/sliver variants, and `StaggeredGridView` as fully supported, and listing reverse-direction lists, `PageView`, and `ReorderableListView` as explicitly unsupported in v1 with fall-through to existing behavior. No supported or unsupported view type is left undescribed.
- **SC-005**: Automated tests exercise anchor preservation in at least the normal-list, variable-height-item, and custom-sliver scenarios, and these tests pass on every release build of the package.

## Assumptions

- The infinite-load-more bug fixed by feature `003-load-more-guard` (post-frame request guard) is in place; this feature builds on top of it rather than replacing it. The two together — guarding the request and preserving the scroll anchor — are what fully eliminate the chained-load-more behavior.
- Consumers do not currently rely on the post-append scroll position landing inside the load-more trigger zone; that prior behavior was unintentional and is being corrected.
- The package's existing scroll integration (internal and external `ScrollController` paths) exposes enough information at append time to identify a viable anchor — i.e., either item-level keys/indices via a builder pattern, or a usable viewport offset.
- For view types where Flutter does not natively offer index-stable scroll restoration (e.g., some sliver compositions or staggered grids with dynamic resolves), a viewport-offset-delta fallback is acceptable as long as it is documented and prevents chained load-more.
- Platform-specific scroll physics differences between iOS and Android are tolerated as long as the anchor item remains within the success-criteria tolerance on both platforms.
- The feature is implemented entirely within the `smart_pagination` package; no changes are required in `clubapp_core`, in the main `club_app` application, or in consumer call sites.
