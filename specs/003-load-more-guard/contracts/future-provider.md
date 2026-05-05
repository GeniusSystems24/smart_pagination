# Contract: Future Provider — Load-More Guard

**Provider type**: `PaginationProvider.future(...)`
**Changed behaviour**: guard strengthening only; public API unchanged.

---

## Guard Contract

```
GIVEN  a FuturePaginationProvider is active
WHEN   fetchPaginatedList() is called N times in the same event-loop turn
THEN   the consumer's dataProvider function is called exactly once
AND    all N-1 extra calls are dropped by _isFetching or _activeLoadMoreKey
```

## In-Flight Key

For future providers, the load-more key is:

```
key = "${request.page}:${request.pageSize ?? 'null'}"
```

If `fetchPaginatedList()` is called while `_activeLoadMoreKey == key`, the call
returns immediately without reaching the provider.

## Stale Response Contract

```
GIVEN  a fetch for generation G is in flight
WHEN   refreshPaginatedList() is called (bumps _generation, increments _fetchToken)
AND    the old future resolves with token T_old
THEN   T_old != _fetchToken → response is discarded
AND    no items are appended
AND    hasReachedEnd is not changed
```

## End-of-List Contract

| Condition | Result |
|-----------|--------|
| `response.isEmpty && !reset` | `hasReachedEnd = true`; no page appended |
| `response.length < pageSize` | `hasReachedEnd = true`; page appended normally |
| `response.length == pageSize` | `hasReachedEnd = false`; one more fetch may follow |
| `serverHasNext == false` (optional) | `hasReachedEnd = true` regardless of count |
| Error | `hasReachedEnd = false`; `loadMoreError` set |

## Backward Compatibility

Existing callers passing only `dataProvider` function are unaffected.
The `serverHasNext` mechanism requires no code change on the consumer side;
it is applied only if the consumer's provider returns a `PaginationResponse`
(future enhancement, not part of this feature).
