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
  return MaterialApp(home: Scaffold(body: child));
}

Future<void> _pumpPagination(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(_buildHost(child));
  await tester.pumpAndSettle();
}

void main() {
  group('SmartPagination pull-to-refresh', () {
    testWidgets('does not render RefreshIndicator when canRefresh is false', (
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

    testWidgets('default onRefresh calls cubit.reload()', (tester) async {
      final cubit = _TrackingPaginationCubit<int>(
        request: const PaginationRequest(page: 1, pageSize: 20),
        provider: PaginationProvider.future((request) async => <int>[]),
      );

      await _pumpPagination(
        tester,
        SmartPaginationListView<int>.withCubit(
          cubit: cubit,
          canRefresh: true,
          itemBuilder: (context, items, index) => Text('Item ${items[index]}'),
        ),
      );

      final indicator = tester.widget<RefreshIndicator>(
        find.byType(RefreshIndicator),
      );
      await indicator.onRefresh();

      expect(cubit.reloadCalls, 1);
    });

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

    testWidgets(
      'does not render RefreshIndicator in unsupported horizontal row layout',
      (tester) async {
        await _pumpPagination(
          tester,
          SmartPaginationRow<int>.withProvider(
            request: const PaginationRequest(page: 1, pageSize: 20),
            provider: PaginationProvider.future((request) async => [1, 2]),
            canRefresh: true,
            itemBuilder: (context, items, index) =>
                Text('Item ${items[index]}'),
          ),
        );

        expect(find.byType(RefreshIndicator), findsNothing);
      },
    );
  });
}
