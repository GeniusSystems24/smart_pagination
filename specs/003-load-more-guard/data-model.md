# Data Model: Load-More Guard

**Date**: 2026-05-05 | **Feature**: `003-load-more-guard`

---

## 1 — Unchanged Entities

These exist today and are not modified by this feature.

| Entity | File | Role |
|--------|------|------|
| `SmartPaginationCubit<T, R>` | `pagination_cubit.dart` | Single source of truth for pagination state |
| `SmartPaginationLoaded<T>` | `pagination_state.dart` | Public loaded state; holds `isLoadingMore`, `hasReachedEnd` |
| `PaginationMeta` | `core.dart` | Page metadata: `page`, `pageSize`, `hasNext`, `hasPrevious` |
| `PaginationProvider<T, R>` | `core.dart` | Union type: Future / Stream / MergedStream |
| `_PageStreamEntry<T>` | `pagination_cubit.dart` | Per-page stream subscription with generation tag |

---

## 2 — New Internal Fields (SmartPaginationCubit)

| Field | Type | Default | Cleared On |
|-------|------|---------|------------|
| `_activeLoadMoreKey` | `String?` | `null` | Completion, error, or any scope reset |
| `identityKey` (constructor param) | `Object? Function(T)?` | `null` | N/A — immutable after construction |

### `_activeLoadMoreKey` computation

```
page-based:   "${request.page}:${request.pageSize ?? 'null'}"
cursor-based: "cursor:${cursor ?? 'end'}"
```

Cleared in:
- `_fetch()` `finally` block
- `cancelOngoingRequest()`
- `_resetToInitial()`
- `refreshPaginatedList()`

---

## 3 — Modified Internal Fields (SmartPaginationCubit)

| Field | Before | After |
|-------|--------|-------|
| `_isFetching` | Set inside `_fetch()` after `fetchPaginatedList()` returns | Set inside `fetchPaginatedList()` before `emit(isLoadingMore: true)` |

---

## 4 — `_PageStreamEntry<T>` (no struct change)

The existing struct is sufficient. The new `_attachStream` guard uses
`_pageStreams.containsKey(page) && _pageStreams[page]!.generation == _generation`
without adding new fields.

---

## 5 — End-of-List Signal (logical entity, no new class)

| Signal Type | Detection |
|-------------|-----------|
| Item count | `returnedItems.length < pageSize` (existing) |
| Empty load-more page | `!reset && pageItems.isEmpty` (new early-return path) |
| Cursor null/absent | `serverHasNext = false` passed to `_computeHasNext` (new override parameter) |
| Explicit boolean | `serverHasNext = response.hasMore` passed to `_computeHasNext` |

The `serverHasNext` parameter is optional; callers that don't pass it receive
identical behaviour to the current implementation.

---

## 6 — Identity Key Deduplication (logical entity, no new class)

| Attribute | Description |
|-----------|-------------|
| `identityKey` | `Object? Function(T item)?` — extracts a unique key per item |
| Applied in | `_fetch()` before `_pages.add(pageItems)` and in `_emitMergedLoaded()` |
| Algorithm | `LinkedHashSet<Object>` seeded from existing items' keys; new page items whose key is already in the set are dropped before append |
| Absent | If `identityKey == null`, deduplication is skipped; behaviour is identical to today |

### State Transitions — Load-More Session

```
SmartPaginationInitial
        │
        ▼ fetchPaginatedList() → reset=true
  [_isFetching=true, _activeLoadMoreKey=null]
        │
        ▼ _fetch() awaits
  SmartPaginationLoaded (isLoadingMore: false, hasReachedEnd: false)
        │
        ▼ user scrolls → fetchPaginatedList() → reset=false
  [_isFetching=true, _activeLoadMoreKey="2:20"]
  SmartPaginationLoaded (isLoadingMore: true)
        │
    ┌───┴───┐
    │       │
  success  error
    │       │
    ▼       ▼
Loaded    Loaded
(isLoadingMore:false)  (isLoadingMore:false, loadMoreError: e)
(hasReachedEnd: depends) (hasReachedEnd: false ← always)
[_isFetching=false]    [_isFetching=false]
[_activeLoadMoreKey=null] [_activeLoadMoreKey=null]
```

### State Transitions — Reset

```
Any state
    │
    ▼ refreshPaginatedList() / search / filter
[_bumpGeneration()]
[cancelOngoingRequest() → _isFetching=false, _fetchToken++]
[_cancelAllPageStreams()]
[_activeLoadMoreKey=null]   ← new
[_pages.clear(), _currentMeta=null]
    │
    ▼
SmartPaginationInitial → fetchPaginatedList() (reset=true) → ...
```
