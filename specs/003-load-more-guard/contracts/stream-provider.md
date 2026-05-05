# Contract: Stream Provider — Load-More Guard

**Provider type**: `PaginationProvider.stream(...)`
**Changed behaviour**: single factory call per page; duplicate registration guard.

---

## Factory Call Contract

```
GIVEN  a StreamPaginationProvider is active
WHEN   _fetch() processes a page load
THEN   streamProvider(request) is called exactly once
AND    the returned stream instance is used for both .first (snapshot) and
       _attachStream (persistent subscription)
```

The old behaviour (two separate factory calls per page) is eliminated.

## Registration Guard Contract

```
GIVEN  _pageStreams already contains an entry for page P with generation G
WHEN   _attachStream(stream, request{page: P}) is called with the same generation G
THEN   the call is a no-op; the existing subscription is kept
AND    no duplicate subscription is registered
```

Duplicate registration can occur if fast scrolling causes `fetchPaginatedList()` to
complete and call `_attachStream` twice before the widget rebuilds. The guard prevents
the second call from replacing or doubling the subscription.

## Stale Scope Contract

```
GIVEN  a stream subscription was registered under generation G
WHEN   a scope reset bumps _generation to G+1
AND    the old stream emits a value
THEN   the emission is discarded (entry.generation != _generation)
AND    current list state is not modified
```

## End-of-List Contract (Stream Path)

```
GIVEN  _emitMergedLoaded is called
WHEN   ALL of the following:
       - pageSize is non-null
       - the highest-page entry's latestValue.length < pageSize
       - the entry has received at least one full emission (isComplete flag)
THEN   hasReachedEnd = true is emitted
AND    no further page stream registrations occur
```

The `isComplete` flag on `_PageStreamEntry` prevents premature end-of-list
detection during stream warm-up when the first emission hasn't yet settled.

## Accumulation Contract (Unchanged)

Stream accumulation semantics are preserved from spec 002-stabilize-provider:

- Loading page N adds a subscription to `_pageStreams[N]` without cancelling
  pages 1..N-1
- All active page subscriptions remain live until scope reset
- Merged view is the concatenation of all pages' `latestValue` in ascending order
