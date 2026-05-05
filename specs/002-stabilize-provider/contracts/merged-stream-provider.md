# Contract: MergedStreamPaginationProvider

**Surface**: `PaginationProvider.mergeStreams(...)` factory → `MergedStreamPaginationProvider<T, R extends PaginationRequest>`.

## Preserved signature (backward-compatibility anchor)

```dart
sealed class PaginationProvider<T, R extends PaginationRequest> {
  factory PaginationProvider.mergeStreams(
    List<Stream<List<T>>> Function(R request) streamsProvider,
  ) = MergedStreamPaginationProvider<T, R>;
}
```

Removing or altering the factory's signature is **forbidden** under Constitution II. The provider's `getMergedStream(R request)` helper is internal-facing but is currently public — its signature must also be preserved.

## Inputs

- `R request` — passed verbatim to `streamsProvider`.
- The list of child `Stream<List<T>>` returned by `streamsProvider`. Length may be 0, 1, or N.

## Emissions

- The merged stream emits a `List<T>` whenever **any** child emits, surfacing that child's emission as-is.
- The merged stream errors when **any** child errors (existing behavior; not changed by this iteration).
- The merged stream completes only when **all** children have completed (FR-023).

## Lifecycle obligations (the audit target this iteration)

The current implementation has three branches; their lifecycle behavior must be uniformly leak-free:

### Empty branch (zero streams)

```dart
if (streams.isEmpty) return Stream.value([]);
```

- `Stream.value([])` owns no `StreamSubscription` and no `StreamController`. Nothing to cancel.
- Acceptable as-is (Research R5).

### Single-stream branch (one stream) — **changes this iteration**

Before:

```dart
if (streams.length == 1) return streams.first;
```

This returns the underlying stream directly, which means the merge provider has **no handle** on the subscription created when the consumer listens. If the consumer listens but never cancels, the subscription leaks.

After (target behavior):

```dart
if (streams.length == 1) {
  late StreamController<List<T>> controller;
  StreamSubscription<List<T>>? subscription;
  controller = StreamController<List<T>>(
    onListen: () {
      subscription = streams.first.listen(
        controller.add,
        onError: controller.addError,
        onDone: controller.close,
      );
    },
    onCancel: () => subscription?.cancel(),
  );
  return controller.stream;
}
```

This makes the single-stream path lifecycle-symmetric with the multi-stream path: the consumer cancels the controller's stream subscription, the controller's `onCancel` cancels the underlying subscription.

### Multi-stream branch (N ≥ 2 streams)

Existing implementation already wires `onCancel` to cancel every child subscription. Audit confirms correctness; no functional change needed, but tests must cover:

- Each child subscription's `onCancel` actually fires when the consumer cancels the merged subscription.
- Nothing leaks if **listen → never emit → cancel** (subscriptions opened but no data flowed).

## Required test scenarios (mapped to acceptance criteria)

1. **Zero streams: no subscriptions, no controllers** (FR-020 / US2 #1) — instrument lifecycle counters; assert zero allocations.
2. **Single-stream: cancels underlying subscription on cancel** (FR-021 / new) — instrument the underlying stream's `onCancel`; subscribe, then cancel the merged subscription; assert the underlying `onCancel` fires.
3. **Multi-stream: every child cancelled on cancel** (FR-021 / US2 #2) — same instrumentation across N children.
4. **Child error surfaces and does not leak siblings** (FR-022 / US2 #3) — error one child; assert merged stream surfaces the error; remaining child subscriptions are still alive.
5. **Completion only when all children complete** (FR-023 / US2 #4) — complete one child; merged stream still open; complete the rest; merged stream completes.
6. **Cubit dispose with merged-stream provider closes everything** (FR-014, FR-021 / US2 cross-applies) — close the cubit using `MergedStreamPaginationProvider`; assert no subscription remains and no controller is open.

## Failure modes the cubit must accept

- A child stream errors before any emission — cubit surfaces the error per the existing future/stream error contract.
- All children complete with no emission — cubit treats this as an empty page (existing behavior).
- The list returned by `streamsProvider` is empty — provider returns `Stream.value([])`; cubit treats it as an empty page.
