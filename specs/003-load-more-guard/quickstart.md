# Quickstart: Load-More Guard

**Date**: 2026-05-05 | **Feature**: `003-load-more-guard`

This document describes the expected behaviour for three flows after the guard
is implemented. Each flow ends with an assertion that distinguishes the new
behaviour from the old.

---

## Flow 1 — Future Provider: Fast Scroll Guard

### Setup

```dart
var providerCallCount = 0;

final cubit = SmartPaginationCubit<Item, PaginationRequest>(
  request: PaginationRequest(page: 1, pageSize: 10),
  provider: PaginationProvider.future((request) async {
    providerCallCount++;
    return List.generate(10, (i) => Item(id: (request.page - 1) * 10 + i));
  }),
);
```

### Old behaviour (before fix)

Calling `fetchPaginatedList()` 10 times synchronously could result in
`providerCallCount >= 2` because the `_isFetching` flag was not set before the
second call entered.

### New behaviour (after fix)

```dart
// Initial load
await cubit.fetchPaginatedList();
providerCallCount = 0; // reset counter after initial load

// Simulate 10 rapid scroll triggers
for (var i = 0; i < 10; i++) {
  cubit.fetchPaginatedList();
}
await Future.delayed(Duration.zero); // let async complete

assert(providerCallCount == 1);  // exactly one provider call
assert(cubit.state is SmartPaginationLoaded);
final loaded = cubit.state as SmartPaginationLoaded<Item>;
assert(loaded.items.length == 20); // page 1 + page 2
assert(!loaded.isLoadingMore);
```

**Key assertion**: `providerCallCount == 1` — the guard stopped 9 of the 10 calls.

---

## Flow 2 — Future Provider: End-of-List and Stale Response

### Setup

```dart
var page2Completer = Completer<List<Item>>();

final cubit = SmartPaginationCubit<Item, PaginationRequest>(
  request: PaginationRequest(page: 1, pageSize: 10),
  provider: PaginationProvider.future((request) async {
    if (request.page == 1) return List.generate(10, (i) => Item(id: i));
    if (request.page == 2) return await page2Completer.future;
    return [];
  }),
);
```

### Scenario A — Empty last page does not append

```dart
// Load page 1
await cubit.fetchPaginatedList();

// Trigger load-more (page 2)
cubit.fetchPaginatedList();

// Refresh before page 2 completes (bumps generation)
cubit.refreshPaginatedList();

// Now complete page 2 — stale response
page2Completer.complete([]);
await Future.delayed(Duration.zero);

final loaded = cubit.state as SmartPaginationLoaded<Item>;
assert(loaded.items.length == 10);     // only page 1 items (refresh cleared page 2)
assert(!loaded.hasReachedEnd);         // fresh session; end not set by stale response
```

### Scenario B — Truly empty page sets end-of-list

```dart
final cubit2 = SmartPaginationCubit<Item, PaginationRequest>(
  request: PaginationRequest(page: 1, pageSize: 10),
  provider: PaginationProvider.future((request) async {
    if (request.page == 1) return List.generate(10, (i) => Item(id: i));
    return []; // page 2 is empty
  }),
);

await cubit2.fetchPaginatedList(); // load page 1
cubit2.fetchPaginatedList();       // trigger load-more
await Future.delayed(Duration.zero);

final state2 = cubit2.state as SmartPaginationLoaded<Item>;
assert(state2.hasReachedEnd);          // empty page → end of list
assert(state2.items.length == 10);     // empty page NOT appended
```

---

## Flow 3 — Stream Provider: No Duplicate Factory Calls

### Setup

```dart
var factoryCallCount = 0;

Stream<List<Item>> streamFactory(PaginationRequest request) {
  factoryCallCount++;
  return Stream.value(
    List.generate(10, (i) => Item(id: (request.page - 1) * 10 + i)),
  );
}

final cubit = SmartPaginationCubit<Item, PaginationRequest>(
  request: PaginationRequest(page: 1, pageSize: 10),
  provider: PaginationProvider.stream(streamFactory),
);
```

### Old behaviour (before fix)

For each page load, `streamFactory` was called twice: once for `.first` and once
for `_attachStream`. Loading pages 1 and 2 resulted in `factoryCallCount == 4`.

### New behaviour (after fix)

```dart
// Load page 1
await cubit.fetchPaginatedList();

// Load page 2
cubit.fetchPaginatedList();
await Future.delayed(Duration.zero);

assert(factoryCallCount == 2);  // exactly one factory call per page (not two)

final loaded = cubit.state as SmartPaginationLoaded<Item>;
assert(loaded.items.length == 20);
assert(!loaded.isLoadingMore);
```

**Key assertion**: `factoryCallCount == 2` (one per page) — not 4 as before.

---

## Flow 4 — Identity-Key Deduplication

### Setup

```dart
final cubit = SmartPaginationCubit<Item, PaginationRequest>(
  request: PaginationRequest(page: 1, pageSize: 5),
  provider: PaginationProvider.future((request) async {
    // Pages overlap: page 1 ends with id=4, page 2 starts with id=4
    if (request.page == 1) return [Item(id: 0), Item(id: 1), Item(id: 2), Item(id: 3), Item(id: 4)];
    if (request.page == 2) return [Item(id: 4), Item(id: 5), Item(id: 6), Item(id: 7), Item(id: 8)];
    return [];
  }),
  identityKey: (item) => item.id,  // ← new optional parameter
);
```

### Without identityKey (old / default)

Items 0–4 from page 1 + items 4–8 from page 2 = 10 items including duplicate id=4.

### With identityKey (new)

```dart
await cubit.fetchPaginatedList(); // page 1
cubit.fetchPaginatedList();       // page 2
await Future.delayed(Duration.zero);

final loaded = cubit.state as SmartPaginationLoaded<Item>;
assert(loaded.items.length == 9);  // id=4 appears once, not twice
assert(loaded.items.map((i) => i.id).toSet().length == 9); // all unique
```

**Key assertion**: `items.length == 9` — the duplicate id=4 from page 2 was dropped.
