import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_pagination/pagination.dart';

typedef _EmptyCaseBuilder =
    Widget Function({
      required PaginationProvider<int> provider,
      required Widget emptyWidget,
      Widget Function(BuildContext context)? firstPageEmptyBuilder,
    });

class _EmptyCase {
  const _EmptyCase(this.name, this.builder);

  final String name;
  final _EmptyCaseBuilder builder;
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

const _request = PaginationRequest(page: 1, pageSize: 20);

final List<_EmptyCase> _emptyCases = [
  _EmptyCase(
    'list view',
    ({required provider, required emptyWidget, firstPageEmptyBuilder}) =>
        SmartPaginationListView<int>.withProvider(
          request: _request,
          provider: provider,
          emptyWidget: emptyWidget,
          firstPageEmptyBuilder: firstPageEmptyBuilder,
          itemBuilder: (context, items, index) => Text('Item ${items[index]}'),
        ),
  ),
  _EmptyCase(
    'grid view',
    ({required provider, required emptyWidget, firstPageEmptyBuilder}) =>
        SmartPaginationGridView<int>.withProvider(
          request: _request,
          provider: provider,
          emptyWidget: emptyWidget,
          firstPageEmptyBuilder: firstPageEmptyBuilder,
          itemBuilder: (context, items, index) => Text('Item ${items[index]}'),
        ),
  ),
  _EmptyCase(
    'page view',
    ({required provider, required emptyWidget, firstPageEmptyBuilder}) =>
        SmartPaginationPageView<int>.withProvider(
          request: _request,
          provider: provider,
          emptyWidget: emptyWidget,
          firstPageEmptyBuilder: firstPageEmptyBuilder,
          itemBuilder: (context, items, index) => Text('Item ${items[index]}'),
        ),
  ),
  _EmptyCase(
    'staggered grid view',
    ({required provider, required emptyWidget, firstPageEmptyBuilder}) =>
        SmartPaginationStaggeredGridView<int>.withProvider(
          request: _request,
          provider: provider,
          crossAxisCount: 2,
          emptyWidget: emptyWidget,
          firstPageEmptyBuilder: firstPageEmptyBuilder,
          itemBuilder: (context, items, index) => StaggeredGridTile.fit(
            crossAxisCellCount: 1,
            child: Text('Item ${items[index]}'),
          ),
        ),
  ),
  _EmptyCase(
    'reorderable list view',
    ({required provider, required emptyWidget, firstPageEmptyBuilder}) =>
        SmartPaginationReorderableListView<int>.withProvider(
          request: _request,
          provider: provider,
          emptyWidget: emptyWidget,
          firstPageEmptyBuilder: firstPageEmptyBuilder,
          onReorder: (oldIndex, newIndex) {},
          itemBuilder: (context, items, index) => ListTile(
            key: ValueKey(items[index]),
            title: Text('Item ${items[index]}'),
          ),
        ),
  ),
  _EmptyCase(
    'column',
    ({required provider, required emptyWidget, firstPageEmptyBuilder}) =>
        SmartPaginationColumn<int>.withProvider(
          request: _request,
          provider: provider,
          emptyWidget: emptyWidget,
          firstPageEmptyBuilder: firstPageEmptyBuilder,
          itemBuilder: (context, items, index) => Text('Item ${items[index]}'),
        ),
  ),
  _EmptyCase(
    'row',
    ({required provider, required emptyWidget, firstPageEmptyBuilder}) =>
        SmartPaginationRow<int>.withProvider(
          request: _request,
          provider: provider,
          emptyWidget: emptyWidget,
          firstPageEmptyBuilder: firstPageEmptyBuilder,
          itemBuilder: (context, items, index) => Text('Item ${items[index]}'),
        ),
  ),
  _EmptyCase(
    'custom',
    ({required provider, required emptyWidget, firstPageEmptyBuilder}) =>
        SmartPagination<int>.withProvider(
          request: _request,
          provider: provider,
          itemBuilderType: PaginateBuilderType.custom,
          emptyWidget: emptyWidget,
          firstPageEmptyBuilder: firstPageEmptyBuilder,
          itemBuilder: (context, items, index) => const SizedBox.shrink(),
          customViewBuilder: (context, items, hasReachedEnd, fetchMore) {
            return ListView(
              children: [
                for (final item in items) ListTile(title: Text('Item $item')),
              ],
            );
          },
        ),
  ),
];

void main() {
  group('SmartPagination empty state', () {
    for (final testCase in _emptyCases) {
      testWidgets(
        '${testCase.name} prefers firstPageEmptyBuilder over emptyWidget',
        (tester) async {
          final emptyWidgetText = 'fallback empty ${testCase.name}';
          final builderText = 'builder empty ${testCase.name}';

          await _pumpPagination(
            tester,
            testCase.builder(
              provider: PaginationProvider.future((request) async => <int>[]),
              emptyWidget: Center(child: Text(emptyWidgetText)),
              firstPageEmptyBuilder: (context) =>
                  Center(child: Text(builderText)),
            ),
          );

          expect(find.text(builderText), findsOneWidget);
          expect(find.text(emptyWidgetText), findsNothing);
        },
      );

      testWidgets(
        '${testCase.name} falls back to emptyWidget when builder is missing',
        (tester) async {
          final emptyWidgetText = 'fallback empty ${testCase.name}';

          await _pumpPagination(
            tester,
            testCase.builder(
              provider: PaginationProvider.future((request) async => <int>[]),
              emptyWidget: Center(child: Text(emptyWidgetText)),
            ),
          );

          expect(find.text(emptyWidgetText), findsOneWidget);
        },
      );
    }
  });
}
