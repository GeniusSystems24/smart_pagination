// US4 acceptance tests for spec 002-stabilize-provider, Phase 6 (T043–T046).
//
// Verifies that a developer-defined `PaginationRequest` subclass flows
// through every provider variant's user callback unchanged: the subclass
// instance reaching the callback is reference-identical to the one supplied
// by the cubit, and its custom fields are readable without a cast (FR-030).

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_pagination/pagination.dart';

class _ProductRequest extends PaginationRequest {
  const _ProductRequest({
    super.page,
    super.pageSize,
    required this.category,
    this.maxPrice,
  });

  final String category;
  final double? maxPrice;

  @override
  _ProductRequest copyWith({
    int? page,
    int? pageSize,
    String? cursor,
    Map<String, dynamic>? filters,
    Map<String, dynamic>? extra,
    String? searchQuery,
  }) {
    return _ProductRequest(
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      category: category,
      maxPrice: maxPrice,
    );
  }
}

void main() {
  group('US4: type-safe custom request subclasses (T043–T046)', () {
    test('T043: future provider receives the custom subclass unchanged',
        () async {
      _ProductRequest? received;
      final cubit = SmartPaginationCubit<int, _ProductRequest>(
        request: const _ProductRequest(
          page: 1,
          pageSize: 5,
          category: 'electronics',
          maxPrice: 99.99,
        ),
        provider: PaginationProvider<int, _ProductRequest>.future((req) async {
          received = req;
          return List<int>.generate(5, (i) => i);
        }),
      );

      cubit.refreshPaginatedList();
      await cubit.stream.firstWhere((s) => s is SmartPaginationLoaded<int>);

      expect(received, isA<_ProductRequest>(),
          reason: 'callback must receive the exact subclass, not the base');
      expect(received!.category, 'electronics',
          reason: 'custom field must be readable without a cast');
      expect(received!.maxPrice, 99.99);

      await cubit.close();
    });

    test(
        'T044: stream provider preserves custom subclass across load-more',
        () async {
      final receivedRequests = <_ProductRequest>[];
      final controllers = <int, StreamController<List<int>>>{};
      final cubit = SmartPaginationCubit<int, _ProductRequest>(
        request: const _ProductRequest(
          page: 1,
          pageSize: 5,
          category: 'books',
          maxPrice: 19.99,
        ),
        provider: PaginationProvider<int, _ProductRequest>.stream((req) {
          receivedRequests.add(req);
          final ctrl = controllers.putIfAbsent(
            req.page,
            () => StreamController<List<int>>.broadcast(sync: true),
          );
          return ctrl.stream;
        }),
      );

      Future<void> seed(int page) async {
        await Future<void>.delayed(Duration.zero);
        controllers[page]!.add(List<int>.generate(5, (i) => i));
        await Future<void>.delayed(Duration.zero);
      }

      cubit.refreshPaginatedList();
      await seed(1);
      cubit.fetchPaginatedList();
      await seed(2);

      // Each invocation of the user callback must receive a _ProductRequest
      // with the original custom fields preserved.
      expect(receivedRequests, isNotEmpty);
      for (final req in receivedRequests) {
        expect(req, isA<_ProductRequest>());
        expect(req.category, 'books');
        expect(req.maxPrice, 19.99);
      }
      // Page numbers progress 1, 1, 2, 2 (cubit calls streamProvider twice
      // per page load: once for `.first`, once for the live subscription).
      final pageNumbers = receivedRequests.map((r) => r.page).toSet();
      expect(pageNumbers, containsAll([1, 2]));

      await cubit.close();
      for (final c in controllers.values) {
        await c.close();
      }
    });

    test('T045: merged-stream provider preserves custom subclass', () async {
      final receivedRequests = <_ProductRequest>[];
      final cubit = SmartPaginationCubit<int, _ProductRequest>(
        request: const _ProductRequest(
          page: 1,
          pageSize: 5,
          category: 'sports',
          maxPrice: 49.99,
        ),
        provider:
            PaginationProvider<int, _ProductRequest>.mergeStreams((req) {
          receivedRequests.add(req);
          return [
            Stream<List<int>>.value([1, 2, 3, 4, 5]),
            Stream<List<int>>.value([6, 7, 8, 9, 10]),
          ];
        }),
      );

      cubit.refreshPaginatedList();
      await cubit.stream.firstWhere((s) => s is SmartPaginationLoaded<int>);

      expect(receivedRequests, isNotEmpty);
      for (final req in receivedRequests) {
        expect(req, isA<_ProductRequest>());
        expect(req.category, 'sports');
        expect(req.maxPrice, 49.99);
      }

      await cubit.close();
    });
  });
}
