# Contract: Merged Stream Provider — Load-More Guard

**Provider type**: `PaginationProvider.mergeStreams(...)`
**Changed behaviour**: single factory call per page; duplicate subscription guard.

---

## Factory Call Contract

```
GIVEN  a MergedStreamPaginationProvider is active
WHEN   _fetch() processes a page load
THEN   getMergedStream(request) is called exactly once
AND    the returned stream instance is used for both .first and _attachStream
```

## Duplicate Subscription Guard Contract

```
GIVEN  a subscription for page P already exists in _pageStreams for generation G
WHEN   _attachStream is called again for the same page P and generation G
THEN   the call is silently skipped
AND    the existing subscription is not cancelled or replaced
AND    no second subscription is opened on the merged stream
```

This is identical to the stream provider contract — the `_attachStream` guard is
shared across both stream provider types.

## Cancellation Contract

```
GIVEN  a MergedStreamPaginationProvider has active subscriptions for pages 1..N
WHEN   refreshPaginatedList() is called
THEN   _cancelAllPageStreams() cancels ALL N subscriptions
AND    _pageStreams is cleared
AND    _generation is bumped before cancellation (so late emissions are discarded)
```

## Fast-Scroll Repeated Registration Contract

```
GIVEN  the user scrolls rapidly near the bottom of a merged-stream list
WHEN   fetchPaginatedList() is called K times before the widget rebuilds
THEN   exactly one load-more request is started (_isFetching + _activeLoadMoreKey)
AND    exactly one subscription is registered in _pageStreams
AND    getMergedStream(request) is called exactly once
```

## End-of-List Contract

Same as stream provider: end is detected via item-count heuristic or serverHasNext
override. Once `hasReachedEnd = true`, no further `fetchPaginatedList()` calls reach
the provider and no new subscriptions are registered.
