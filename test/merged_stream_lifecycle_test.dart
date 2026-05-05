// US2 acceptance tests for spec 002-stabilize-provider, Phase 4 (T027–T032).
//
// Each test names the task ID and the contract scenario it verifies (see
// specs/002-stabilize-provider/contracts/merged-stream-provider.md).
//
// Most tests exercise `getMergedStream` directly on the provider so we can
// instrument `StreamController.onCancel`/`onListen` counters without going
// through the cubit. T032 wires it through the cubit to verify dispose
// integration.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_pagination/pagination.dart';

class _LifecycleCounter {
  int listens = 0;
  int cancels = 0;
}

StreamController<List<int>> _controller(_LifecycleCounter counter) {
  late StreamController<List<int>> ctrl;
  ctrl = StreamController<List<int>>(
    onListen: () => counter.listens++,
    onCancel: () => counter.cancels++,
  );
  return ctrl;
}

void main() {
  group('US2: merged-stream lifecycle (T027–T032)', () {
    test('T027: zero streams emits empty page and holds no resources', () async {
      final provider = MergedStreamPaginationProvider<int, PaginationRequest>(
        (req) => const <Stream<List<int>>>[],
      );

      final emissions = <List<int>>[];
      final sub = provider.getMergedStream(PaginationRequest(page: 1)).listen(
        emissions.add,
      );
      // Stream.value([]) emits one event then completes synchronously on
      // microtask; let it flush.
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();
      expect(emissions, equals([<int>[]]));
    });

    test('T028: single-stream branch cancels underlying subscription on cancel',
        () async {
      final c = _LifecycleCounter();
      final source = _controller(c);

      final provider = MergedStreamPaginationProvider<int, PaginationRequest>(
        (req) => [source.stream],
      );

      final merged = provider.getMergedStream(PaginationRequest(page: 1));
      final sub = merged.listen((_) {});
      // The merge controller's onListen subscribes to source.
      await Future<void>.delayed(Duration.zero);
      expect(c.listens, 1, reason: 'merge wrapper must subscribe to source');

      await sub.cancel();
      expect(c.cancels, 1,
          reason: 'cancelling the merged subscription must cancel the source');

      await source.close();
    });

    test('T029: multi-stream branch cancels every child on cancel', () async {
      final cA = _LifecycleCounter();
      final cB = _LifecycleCounter();
      final cC = _LifecycleCounter();
      final a = _controller(cA);
      final b = _controller(cB);
      final c = _controller(cC);

      final provider = MergedStreamPaginationProvider<int, PaginationRequest>(
        (req) => [a.stream, b.stream, c.stream],
      );

      final sub = provider
          .getMergedStream(PaginationRequest(page: 1))
          .listen((_) {});
      await Future<void>.delayed(Duration.zero);
      expect(cA.listens, 1);
      expect(cB.listens, 1);
      expect(cC.listens, 1);

      await sub.cancel();
      expect(cA.cancels, 1);
      expect(cB.cancels, 1);
      expect(cC.cancels, 1);

      await a.close();
      await b.close();
      await c.close();
    });

    test('T030: child error surfaces and does not cancel siblings', () async {
      final cA = _LifecycleCounter();
      final cB = _LifecycleCounter();
      final a = _controller(cA);
      final b = _controller(cB);

      final provider = MergedStreamPaginationProvider<int, PaginationRequest>(
        (req) => [a.stream, b.stream],
      );

      final emissions = <List<int>>[];
      final errors = <Object>[];
      final sub = provider.getMergedStream(PaginationRequest(page: 1)).listen(
        emissions.add,
        onError: errors.add,
      );

      await Future<void>.delayed(Duration.zero);
      a.add([1]);
      a.addError('a-failed');
      b.add([2]);
      await Future<void>.delayed(Duration.zero);

      expect(errors, contains('a-failed'));
      // Note: emissions is a List<List<int>>; `contains([1])` would compare
      // by identity since List.== is identity-based. Use anyElement+equals.
      expect(emissions, anyElement(equals([1])));
      expect(emissions, anyElement(equals([2])),
          reason: 'sibling B must keep delivering after A errors');
      expect(cB.cancels, 0,
          reason: 'B subscription must remain alive after A errors');

      await sub.cancel();
      await a.close();
      await b.close();
    });

    test('T031: merged stream completes only when every child completes',
        () async {
      final a = StreamController<List<int>>();
      final b = StreamController<List<int>>();

      final provider = MergedStreamPaginationProvider<int, PaginationRequest>(
        (req) => [a.stream, b.stream],
      );

      var done = false;
      final sub = provider.getMergedStream(PaginationRequest(page: 1)).listen(
        (_) {},
        onDone: () => done = true,
      );

      await Future<void>.delayed(Duration.zero);
      await a.close();
      await Future<void>.delayed(Duration.zero);
      expect(done, isFalse,
          reason: 'merged stream must stay open until every child completes');

      await b.close();
      await Future<void>.delayed(Duration.zero);
      expect(done, isTrue,
          reason: 'merged stream completes when the last child completes');

      await sub.cancel();
    });

    test('T032: cubit dispose with merged-stream provider closes cleanly',
        () async {
      // Use broadcast controllers so the cubit can call streamsProvider(req)
      // twice (once for `.first`, once for the live subscription) without
      // exhausting a single-subscription stream.
      final cA = _LifecycleCounter();
      final cB = _LifecycleCounter();
      final a = StreamController<List<int>>.broadcast(
        onListen: () => cA.listens++,
        onCancel: () => cA.cancels++,
      );
      final b = StreamController<List<int>>.broadcast(
        onListen: () => cB.listens++,
        onCancel: () => cB.cancels++,
      );

      final cubit = SmartPaginationCubit<int, PaginationRequest>(
        request: PaginationRequest(page: 1, pageSize: 5),
        provider:
            PaginationProvider<int, PaginationRequest>.mergeStreams(
          (req) => [a.stream, b.stream],
        ),
      );
      cubit.refreshPaginatedList();
      // Let the cubit subscribe via `.first`, then push the seed emission.
      await Future<void>.delayed(Duration.zero);
      a.add([1, 2, 3, 4, 5]);
      await Future<void>.delayed(Duration.zero);

      await cubit.close();
      expect(cubit.isClosed, isTrue);

      // Pushing on the controllers after close must not throw.
      a.add([99]);
      b.add([99]);
      await Future<void>.delayed(Duration.zero);

      await a.close();
      await b.close();
    });
  });
}
