# Quickstart — Stabilize PaginationProvider

**Branch**: `002-stabilize-provider` | **Date**: 2026-05-05

This walkthrough exercises the three flows that change behavior in this iteration. Each block is structured so the assertions at the end **fail** under the current code and **pass** after the planned changes — they double as smoke tests for the upcoming implementation tasks.

> All snippets assume `package:smart_pagination/pagination.dart` is imported.

---

## Flow 1 — Future pagination with refresh + load-more (US3)

```dart
final cubit = SmartPaginationCubit<Product, ProductRequest>(
  request: ProductRequest(page: 1, pageSize: 20),
  provider: PaginationProvider.future(
    (req) => api.fetchProducts(req),
  ),
);

// 1) Successful first page
await cubit.loadInitial();
expect(cubit.state, isA<SmartPaginationLoaded<Product>>());
expect((cubit.state as SmartPaginationLoaded<Product>).items.length, 20);

// 2) Stale-response protection: kick off a slow page-2 fetch, then refresh
final slowFetch = cubit.loadMore();          // generation = 1
await cubit.refresh();                        // bumps generation to 2
await slowFetch;                              // late page-2 response from gen 1
expect(
  (cubit.state as SmartPaginationLoaded<Product>).items.length,
  20,
  reason: 'Stale page-2 response from old generation must be discarded',
);

// 3) Disposal mid-flight
final inFlight = cubit.loadMore();
await cubit.close();                          // cubit.isClosed == true
await inFlight;                               // resolves into the void
// no exception, no state mutation after close
```

---

## Flow 2 — Stream pagination: three accumulated pages, error injection, end-of-pagination toggle (US1)

```dart
// Test infrastructure: one broadcast controller per page (sync for determinism)
final page1 = StreamController<List<Item>>.broadcast(sync: true);
final page2 = StreamController<List<Item>>.broadcast(sync: true);
final page3 = StreamController<List<Item>>.broadcast(sync: true);

final cubit = SmartPaginationCubit<Item, ItemRequest>(
  request: ItemRequest(page: 1, pageSize: 5),
  provider: PaginationProvider.stream((req) {
    switch (req.page) {
      case 1: return page1.stream;
      case 2: return page2.stream;
      case 3: return page3.stream;
      default: return const Stream.empty();
    }
  }),
);

// 1) Load page 1 and observe accumulation as we add pages 2 and 3
await cubit.loadInitial();
page1.add(List.generate(5, (i) => Item(id: 'p1-$i')));
await cubit.loadMore(); // page 2
page2.add(List.generate(5, (i) => Item(id: 'p2-$i')));
await cubit.loadMore(); // page 3
page3.add(List.generate(5, (i) => Item(id: 'p3-$i')));

final loaded = cubit.state as SmartPaginationLoaded<Item>;
expect(loaded.items.length, 15);
expect(loaded.items.first.id, 'p1-0');
expect(loaded.items.last.id,  'p3-4');

// 2) Re-emit on page 1 — only page 1 slice changes
page1.add(List.generate(5, (i) => Item(id: 'p1-mut-$i')));
final after = cubit.state as SmartPaginationLoaded<Item>;
expect(after.items.take(5).first.id, 'p1-mut-0');
expect(after.items.skip(5).first.id, 'p2-0', reason: 'Page 2 unchanged');

// 3) Per-page error: error page 2 — siblings keep emitting
page2.addError(StateError('page 2 went bad'));
final withError = cubit.state as SmartPaginationLoaded<Item>;
expect(withError.pageErrors.containsKey(2), isTrue);
expect(withError.pageErrors[2], isA<StateError>());
// page 2 subscription is cancelled — but page 1 and page 3 still emit
page3.add(List.generate(5, (i) => Item(id: 'p3-mut-$i')));
final stillLive = cubit.state as SmartPaginationLoaded<Item>;
expect(stillLive.items.last.id, 'p3-mut-4');

// 4) End-of-pagination: shrink page 3 to a partial slice
page3.add([Item(id: 'p3-partial-0'), Item(id: 'p3-partial-1')]); // count < pageSize
expect(cubit.canLoadMore, isFalse);

// 5) End-of-pagination clears when page becomes full again
page3.add(List.generate(5, (i) => Item(id: 'p3-full-$i')));
expect(cubit.canLoadMore, isTrue);

// 6) Refresh cancels every accumulated subscription
await cubit.refresh();
// Subsequent emissions on the now-cancelled streams are discarded:
page1.add([Item(id: 'late-from-old-scope')]);
final afterRefresh = cubit.state as SmartPaginationLoaded<Item>;
expect(afterRefresh.items, isNot(contains(predicate<Item>(
  (i) => i.id == 'late-from-old-scope',
))));

await cubit.close();
await page1.close();
await page2.close();
await page3.close();
```

---

## Flow 3 — Merged streams with empty/single/many shapes (US2)

```dart
// Empty case — no resources, no leaks
final empty = PaginationProvider<Product, ProductRequest>.mergeStreams((req) => []);
final emptyCubit = SmartPaginationCubit(request: req, provider: empty);
await emptyCubit.loadInitial();
expect(emptyCubit.state, isA<SmartPaginationLoaded<Product>>());
await emptyCubit.close();
// Lifecycle counters: 0 subscriptions opened, 0 controllers left open.

// Single-stream case — must cancel the underlying subscription on close
var singleCancelled = false;
final source = StreamController<List<Product>>(
  onCancel: () => singleCancelled = true,
);
final single = PaginationProvider<Product, ProductRequest>.mergeStreams(
  (req) => [source.stream],
);
final singleCubit = SmartPaginationCubit(request: req, provider: single);
await singleCubit.loadInitial();
source.add([Product(id: 's-1')]);
await singleCubit.close();
expect(singleCancelled, isTrue,
  reason: 'Single-stream branch must own a controller that cancels the source on close');

// Multi-stream case — every child cancelled, completion only when all complete
final a = StreamController<List<Product>>();
final b = StreamController<List<Product>>();
var aCancelled = false, bCancelled = false;
a.onCancel = () => aCancelled = true;
b.onCancel = () => bCancelled = true;

final multi = PaginationProvider<Product, ProductRequest>.mergeStreams(
  (req) => [a.stream, b.stream],
);
final multiCubit = SmartPaginationCubit(request: req, provider: multi);
await multiCubit.loadInitial();
a.add([Product(id: 'a-1')]);
b.add([Product(id: 'b-1')]);
await multiCubit.close();
expect(aCancelled && bCancelled, isTrue,
  reason: 'Every child subscription must be cancelled on cubit close');

await a.close();
await b.close();
```

---

## What "done" looks like for this iteration

- All three flows above run green in the package's test suite.
- No `flutter test` run leaves dangling timers, subscriptions, or controllers (verified by the package's existing `tearDown` checks plus the new instrumented counters).
- `flutter analyze` reports no new warnings beyond the existing baseline.
- README has a "Stream Accumulation" section that copy-pastes Flow 2's structure.
- CHANGELOG entry under the next version heading explains the per-page accumulation behavior, the per-page error annotation, and the dynamic end-of-pagination rule.
