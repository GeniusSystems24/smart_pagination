// Spec 003-load-more-guard — Stream provider guard tests.
//
// Covers RC-3 (single stream factory call per page for broadcast streams)
// and §4.6 / §8.2 (duplicate page registration guard). Tests T14–T19 from
// plan §12.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_pagination/pagination.dart';

const _settle = Duration(milliseconds: 50);

void main() {
  group('Stream Guard (spec 003)', () {
    test('T14: stream factory is called exactly once per broadcast page load',
        () async {
      // For broadcast streams the cubit captures the instance once and
      // reuses it for both `.first` and the persistent subscription.
      final controllers = <int, StreamController<List<int>>>{};
      var factoryCallCount = 0;
      final cubit = SmartPaginationCubit<int, PaginationRequest>(
        request: PaginationRequest(page: 1, pageSize: 5),
        provider: PaginationProvider<int, PaginationRequest>.stream((req) {
          factoryCallCount++;
          final c = controllers.putIfAbsent(
            req.page,
            () => StreamController<List<int>>.broadcast(sync: true),
          );
          // Seed asynchronously so the cubit's `.first` listener can subscribe.
          Future<void>.microtask(() {
            c.add(List<int>.generate(5, (i) => (req.page - 1) * 5 + i));
          });
          return c.stream;
        }),
      );

      cubit.refreshPaginatedList();
      await Future<void>.delayed(_settle);

      cubit.fetchPaginatedList();
      await Future<void>.delayed(_settle);

      expect(factoryCallCount, 2,
          reason: 'one factory call per page (not 4 as before the fix)');

      for (final c in controllers.values) {
        await c.close();
      }
      await cubit.close();
    });

    test('T15: rapid page-2 triggers result in exactly one factory call',
        () async {
      // The duplicate-page registration guard is internal; we exercise it
      // by firing rapid load-more triggers and asserting only one factory
      // call lands for the target page.
      final pageFactoryCalls = <int, int>{};
      final controllers = <int, StreamController<List<int>>>{};
      final cubit = SmartPaginationCubit<int, PaginationRequest>(
        request: PaginationRequest(page: 1, pageSize: 5),
        provider: PaginationProvider<int, PaginationRequest>.stream((req) {
          pageFactoryCalls.update(req.page, (v) => v + 1, ifAbsent: () => 1);
          final c = controllers.putIfAbsent(
            req.page,
            () => StreamController<List<int>>.broadcast(sync: true),
          );
          Future<void>.microtask(() {
            c.add(List<int>.generate(5, (i) => (req.page - 1) * 5 + i));
          });
          return c.stream;
        }),
      );

      cubit.refreshPaginatedList();
      await Future<void>.delayed(_settle);

      cubit.fetchPaginatedList();
      cubit.fetchPaginatedList();
      cubit.fetchPaginatedList();
      await Future<void>.delayed(_settle);

      expect(pageFactoryCalls[2], 1);

      for (final c in controllers.values) {
        await c.close();
      }
      await cubit.close();
    });

    test('T16: stream provider stops registering pages after end-of-list',
        () async {
      final controllers = <int, StreamController<List<int>>>{};
      var pageCalls = 0;
      final cubit = SmartPaginationCubit<int, PaginationRequest>(
        request: PaginationRequest(page: 1, pageSize: 5),
        provider: PaginationProvider<int, PaginationRequest>.stream((req) {
          pageCalls++;
          final c = controllers.putIfAbsent(
            req.page,
            () => StreamController<List<int>>.broadcast(sync: true),
          );
          Future<void>.microtask(() {
            if (req.page == 1) {
              c.add([0, 1, 2, 3, 4]);
            } else {
              c.add([5, 6]); // short page → end-of-list
            }
          });
          return c.stream;
        }),
      );

      cubit.refreshPaginatedList();
      await Future<void>.delayed(_settle);
      cubit.fetchPaginatedList();
      await Future<void>.delayed(_settle);
      expect((cubit.state as SmartPaginationLoaded<int>).hasReachedEnd, isTrue);
      final callsAtEnd = pageCalls;

      for (var i = 0; i < 3; i++) {
        cubit.fetchPaginatedList();
      }
      await Future<void>.delayed(_settle);

      expect(pageCalls, callsAtEnd);

      for (final c in controllers.values) {
        await c.close();
      }
      await cubit.close();
    });

    test('T17: stale-generation stream emission is discarded', () async {
      // Two refreshes — the second creates a fresh generation. Push a value
      // on the OLD generation's controller and assert it is dropped.
      final controllerByCall = <StreamController<List<int>>>[];
      final cubit = SmartPaginationCubit<int, PaginationRequest>(
        request: PaginationRequest(page: 1, pageSize: 5),
        provider: PaginationProvider<int, PaginationRequest>.stream((req) {
          final c = StreamController<List<int>>.broadcast(sync: true);
          controllerByCall.add(c);
          Future<void>.microtask(() {
            c.add([0, 1, 2, 3, 4]);
          });
          return c.stream;
        }),
      );

      cubit.refreshPaginatedList(); // generation 1
      await Future<void>.delayed(_settle);

      cubit.refreshPaginatedList(); // generation 2
      await Future<void>.delayed(_settle);

      // Generation-1 controller pushes a stale value. The cubit's
      // generation guard should ignore it.
      controllerByCall[0].add([99, 99, 99, 99, 99]);
      await Future<void>.delayed(_settle);

      final loaded = cubit.state as SmartPaginationLoaded<int>;
      expect(loaded.items, [0, 1, 2, 3, 4],
          reason: 'stale-generation emission must not modify state');

      for (final c in controllerByCall) {
        await c.close();
      }
      await cubit.close();
    });

    test('T18: stream subscriptions are cancelled on refreshPaginatedList',
        () async {
      var cancelCount = 0;
      final cubit = SmartPaginationCubit<int, PaginationRequest>(
        request: PaginationRequest(page: 1, pageSize: 5),
        provider: PaginationProvider<int, PaginationRequest>.stream((req) {
          // Use a non-broadcast controller so onCancel fires when the last
          // subscriber goes away.
          final c = StreamController<List<int>>(
            onCancel: () => cancelCount++,
          );
          c.add(List<int>.generate(5, (i) => (req.page - 1) * 5 + i));
          return c.stream;
        }),
      );

      cubit.refreshPaginatedList();
      await Future<void>.delayed(_settle);
      cubit.fetchPaginatedList();
      await Future<void>.delayed(_settle);

      cubit.refreshPaginatedList();
      await Future<void>.delayed(_settle);

      expect(cancelCount, greaterThan(0),
          reason: 'subscriptions cancelled on refresh');

      await cubit.close();
    });

    test('T19: per-page stream error isolates only the failing page',
        () async {
      final controllers = <int, StreamController<List<int>>>{};
      final cubit = SmartPaginationCubit<int, PaginationRequest>(
        request: PaginationRequest(page: 1, pageSize: 5),
        provider: PaginationProvider<int, PaginationRequest>.stream((req) {
          final c = controllers.putIfAbsent(
            req.page,
            () => StreamController<List<int>>.broadcast(sync: true),
          );
          Future<void>.microtask(() {
            c.add(List<int>.generate(5, (i) => (req.page - 1) * 5 + i));
          });
          return c.stream;
        }),
      );

      cubit.refreshPaginatedList();
      await Future<void>.delayed(_settle);
      cubit.fetchPaginatedList();
      await Future<void>.delayed(_settle);

      controllers[2]!.addError('page-2 boom');
      await Future<void>.delayed(_settle);

      final loaded = cubit.state as SmartPaginationLoaded<int>;
      expect(loaded.pageErrors[2], 'page-2 boom');
      expect(loaded.items.length, 10,
          reason: 'siblings keep contributing their last good slice');

      controllers[1]!.add([100, 101, 102, 103, 104]);
      await Future<void>.delayed(_settle);

      expect((cubit.state as SmartPaginationLoaded<int>).items, contains(100));

      for (final c in controllers.values) {
        await c.close();
      }
      await cubit.close();
    });
  });
}
