import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_pagination/pagination.dart';

class _TrackingPaginationCubit<T> extends SmartPaginationCubit<T> {
  _TrackingPaginationCubit({required super.request, required super.provider});

  int reloadCalls = 0;

  @override
  void reload() {
    reloadCalls++;
    super.reload();
  }
}

Widget _buildHost(Widget child) {
  return MaterialApp(
    home: Scaffold(body: SizedBox.expand(child: child)),
  );
}

Future<void> _pumpPagination(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(_buildHost(child));
  await tester.pumpAndSettle();
}

Widget _buildHorizontalItem(String label) {
  return SizedBox(width: 140, height: 120, child: Center(child: Text(label)));
}

Future<void> _dragHorizontalRefresh(WidgetTester tester) async {
  await tester.drag(find.byType(Scrollable).first, const Offset(240, 0));
  await tester.pump();
  await tester.pumpAndSettle();
}

void main() {
  group('SmartPagination pull-to-refresh', () {
    testWidgets('does not render refresh UI when canRefresh is false', (
      tester,
    ) async {
      await _pumpPagination(
        tester,
        SmartPaginationListView<int>.withProvider(
          request: const PaginationRequest(page: 1, pageSize: 20),
          provider: PaginationProvider.future((request) async => [1, 2]),
          itemBuilder: (context, items, index) => Text('Item ${items[index]}'),
        ),
      );

      expect(find.byType(RefreshIndicator), findsNothing);
      expect(find.byType(RefreshProgressIndicator), findsNothing);
    });

    testWidgets(
      'renders RefreshIndicator when canRefresh is true and list is empty',
      (tester) async {
        await _pumpPagination(
          tester,
          SmartPaginationListView<int>.withProvider(
            request: const PaginationRequest(page: 1, pageSize: 20),
            provider: PaginationProvider.future((request) async => <int>[]),
            canRefresh: true,
            itemBuilder: (context, items, index) =>
                Text('Item ${items[index]}'),
          ),
        );

        expect(find.byType(RefreshIndicator), findsOneWidget);
      },
    );

    testWidgets(
      'renders RefreshIndicator for vertical page view when canRefresh is true',
      (tester) async {
        await _pumpPagination(
          tester,
          SmartPaginationPageView<int>.withProvider(
            request: const PaginationRequest(page: 1, pageSize: 20),
            provider: PaginationProvider.future((request) async => [1, 2]),
            canRefresh: true,
            scrollDirection: Axis.vertical,
            itemBuilder: (context, items, index) =>
                Center(child: Text('Item ${items[index]}')),
          ),
        );

        expect(find.byType(RefreshIndicator), findsOneWidget);
      },
    );

    testWidgets(
      'renders RefreshIndicator for vertical custom builder when canRefresh is true',
      (tester) async {
        await _pumpPagination(
          tester,
          SmartPagination<int>.withProvider(
            request: const PaginationRequest(page: 1, pageSize: 20),
            provider: PaginationProvider.future((request) async => [1, 2]),
            itemBuilderType: PaginateBuilderType.custom,
            canRefresh: true,
            itemBuilder: (context, items, index) => const SizedBox.shrink(),
            customViewBuilder: (context, items, hasReachedEnd, fetchMore) {
              return ListView(
                children: [
                  for (final item in items) ListTile(title: Text('Item $item')),
                ],
              );
            },
          ),
        );

        expect(find.byType(RefreshIndicator), findsOneWidget);
      },
    );

    testWidgets(
      'default onRefresh calls cubit.reload() and waits for fetch completion',
      (tester) async {
        final refreshCompleter = Completer<List<int>>();
        final responses = Queue<Future<List<int>>>()
          ..add(Future<List<int>>.value([1]))
          ..add(refreshCompleter.future);

        final cubit = _TrackingPaginationCubit<int>(
          request: const PaginationRequest(page: 1, pageSize: 20),
          provider: PaginationProvider.future(
            (request) => responses.removeFirst(),
          ),
        );

        await _pumpPagination(
          tester,
          SmartPaginationListView<int>.withCubit(
            cubit: cubit,
            canRefresh: true,
            itemBuilder: (context, items, index) =>
                Text('Item ${items[index]}'),
          ),
        );

        final indicator = tester.widget<RefreshIndicator>(
          find.byType(RefreshIndicator),
        );

        var refreshCompleted = false;
        final refreshFuture = indicator.onRefresh().then((_) {
          refreshCompleted = true;
        });

        await tester.pump(const Duration(milliseconds: 20));

        expect(cubit.reloadCalls, 1);
        expect(refreshCompleted, isFalse);

        refreshCompleter.complete([1]);
        await tester.pump(const Duration(milliseconds: 50));
        await refreshFuture;

        expect(refreshCompleted, isTrue);
      },
    );

    testWidgets('custom onRefresh is called with current cubit', (
      tester,
    ) async {
      final cubit = _TrackingPaginationCubit<int>(
        request: const PaginationRequest(page: 1, pageSize: 20),
        provider: PaginationProvider.future((request) async => <int>[]),
      );

      SmartPaginationCubit<int>? receivedCubit;
      var refreshCalls = 0;

      await _pumpPagination(
        tester,
        SmartPaginationListView<int>.withCubit(
          cubit: cubit,
          canRefresh: true,
          onRefresh: (passedCubit) async {
            refreshCalls++;
            receivedCubit = passedCubit;
          },
          itemBuilder: (context, items, index) => Text('Item ${items[index]}'),
        ),
      );

      final indicator = tester.widget<RefreshIndicator>(
        find.byType(RefreshIndicator),
      );
      await indicator.onRefresh();

      expect(refreshCalls, 1);
      expect(identical(receivedCubit, cubit), isTrue);
      expect(cubit.reloadCalls, 0);
    });

    testWidgets('horizontal list view drag triggers refresh callback', (
      tester,
    ) async {
      var refreshCalls = 0;

      await _pumpPagination(
        tester,
        SmartPaginationListView<int>.withProvider(
          request: const PaginationRequest(page: 1, pageSize: 20),
          provider: PaginationProvider.future((request) async => [1]),
          canRefresh: true,
          scrollDirection: Axis.horizontal,
          onRefresh: (cubit) async {
            refreshCalls++;
          },
          itemBuilder: (context, items, index) =>
              _buildHorizontalItem('Item ${items[index]}'),
        ),
      );

      await _dragHorizontalRefresh(tester);

      expect(refreshCalls, 1);
    });

    testWidgets('horizontal row drag triggers refresh callback', (
      tester,
    ) async {
      var refreshCalls = 0;

      await _pumpPagination(
        tester,
        SmartPaginationRow<int>.withProvider(
          request: const PaginationRequest(page: 1, pageSize: 20),
          provider: PaginationProvider.future((request) async => [1]),
          canRefresh: true,
          onRefresh: (cubit) async {
            refreshCalls++;
          },
          itemBuilder: (context, items, index) =>
              _buildHorizontalItem('Item ${items[index]}'),
        ),
      );

      await _dragHorizontalRefresh(tester);

      expect(refreshCalls, 1);
    });

    testWidgets('horizontal page view drag triggers refresh callback', (
      tester,
    ) async {
      var refreshCalls = 0;

      await _pumpPagination(
        tester,
        SmartPaginationPageView<int>.withProvider(
          request: const PaginationRequest(page: 1, pageSize: 1),
          provider: PaginationProvider.future((request) async => [1]),
          canRefresh: true,
          scrollDirection: Axis.horizontal,
          onRefresh: (cubit) async {
            refreshCalls++;
          },
          itemBuilder: (context, items, index) =>
              _buildHorizontalItem('Item ${items[index]}'),
        ),
      );

      await _dragHorizontalRefresh(tester);

      expect(refreshCalls, 1);
    });
  });
}
