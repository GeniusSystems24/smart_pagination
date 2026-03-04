import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_pagination/pagination.dart';

const _viewportKey = ValueKey<String>('viewport');

SmartPaginationLoaded<int> _loadedState(List<int> items) {
  final snapshot = List<int>.from(items);
  return SmartPaginationLoaded<int>(
    items: snapshot,
    allItems: snapshot,
    meta: PaginationMeta(
      page: 1,
      pageSize: snapshot.length,
      hasNext: false,
      hasPrevious: false,
    ),
    hasReachedEnd: true,
  );
}

Finder _itemFinder(int value) => find.byKey(ValueKey<String>('item-$value'));

Widget _buildHost({
  required ValueNotifier<List<int>> itemsNotifier,
  required PaginateBuilderType type,
  required bool preserveCenteredItemOnInsert,
  ScrollController? scrollController,
  PageController? pageController,
  SliverGridDelegate? gridDelegate,
  Axis scrollDirection = Axis.vertical,
  Widget Function(BuildContext, List<int>, bool, VoidCallback?)?
  customViewBuilder,
}) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox(
          key: _viewportKey,
          width: 360,
          height: 420,
          child: ValueListenableBuilder<List<int>>(
            valueListenable: itemsNotifier,
            builder: (context, items, _) {
              return PaginateApiView<int>(
                loadedState: _loadedState(items),
                itemBuilderType: type,
                itemBuilder: (context, docs, index) {
                  final value = docs[index];
                  return SizedBox(
                    key: ValueKey<String>('item-$value'),
                    height: 80,
                    child: ColoredBox(
                      color: index.isEven
                          ? const Color(0xFFE8F0FE)
                          : const Color(0xFFE3F2FD),
                      child: Center(child: Text('item $value')),
                    ),
                  );
                },
                separator: const SizedBox.shrink(),
                scrollController: scrollController,
                pageController: pageController,
                preserveCenteredItemOnInsert: preserveCenteredItemOnInsert,
                gridDelegate:
                    gridDelegate ??
                    const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 0,
                      crossAxisSpacing: 0,
                      mainAxisExtent: 80,
                    ),
                customViewBuilder: customViewBuilder,
                scrollDirection: scrollDirection,
              );
            },
          ),
        ),
      ),
    ),
  );
}

Future<void> _centerListLikeItem(
  WidgetTester tester,
  ScrollController controller,
  int index,
) async {
  const itemExtent = 80.0;
  const viewportExtent = 420.0;
  final targetOffset =
      (index * itemExtent) - ((viewportExtent / 2) - (itemExtent / 2));
  controller.jumpTo(targetOffset.clamp(0, controller.position.maxScrollExtent));
  await tester.pumpAndSettle();
}

int _findClosestVisibleItemToViewportCenter(
  WidgetTester tester,
  List<int> candidates,
) {
  final viewportCenter = tester.getCenter(find.byKey(_viewportKey)).dy;
  int? centeredItem;
  var minDistance = double.infinity;

  for (final item in candidates) {
    final finder = _itemFinder(item);
    if (finder.evaluate().isEmpty) {
      continue;
    }

    final itemCenter = tester.getCenter(finder).dy;
    final distance = (itemCenter - viewportCenter).abs();
    if (distance < minDistance) {
      minDistance = distance;
      centeredItem = item;
    }
  }

  expect(centeredItem, isNotNull);
  return centeredItem!;
}

void main() {
  testWidgets('ListView keeps centered item anchored when prepending items', (
    tester,
  ) async {
    final items = ValueNotifier<List<int>>(List<int>.generate(60, (i) => i));
    final scrollController = ScrollController();

    await tester.pumpWidget(
      _buildHost(
        itemsNotifier: items,
        type: PaginateBuilderType.listView,
        preserveCenteredItemOnInsert: true,
        scrollController: scrollController,
      ),
    );
    await _centerListLikeItem(tester, scrollController, 10);

    final centeredItemBefore = _findClosestVisibleItemToViewportCenter(
      tester,
      items.value,
    );
    final beforeCenter = tester.getCenter(_itemFinder(centeredItemBefore)).dy;

    items.value = <int>[-3, -2, -1, ...items.value];
    await tester.pump();
    await tester.pumpAndSettle();

    expect(_itemFinder(centeredItemBefore), findsOneWidget);
    final afterCenter = tester.getCenter(_itemFinder(centeredItemBefore)).dy;
    expect((afterCenter - beforeCenter).abs(), lessThan(12.0));
  });

  testWidgets('ListView keeps centered item stable when appending items', (
    tester,
  ) async {
    final items = ValueNotifier<List<int>>(List<int>.generate(60, (i) => i));
    final scrollController = ScrollController();

    await tester.pumpWidget(
      _buildHost(
        itemsNotifier: items,
        type: PaginateBuilderType.listView,
        preserveCenteredItemOnInsert: true,
        scrollController: scrollController,
      ),
    );
    await _centerListLikeItem(tester, scrollController, 10);

    final centeredItemBefore = _findClosestVisibleItemToViewportCenter(
      tester,
      items.value,
    );
    final beforeCenter = tester.getCenter(_itemFinder(centeredItemBefore)).dy;

    items.value = <int>[...items.value, 1000, 1001, 1002];
    await tester.pump();
    await tester.pumpAndSettle();

    expect(_itemFinder(centeredItemBefore), findsOneWidget);
    final afterCenter = tester.getCenter(_itemFinder(centeredItemBefore)).dy;
    expect((afterCenter - beforeCenter).abs(), lessThan(12.0));
  });

  testWidgets('GridView keeps centered item anchored on prepend and append', (
    tester,
  ) async {
    final items = ValueNotifier<List<int>>(List<int>.generate(80, (i) => i));
    final scrollController = ScrollController();

    await tester.pumpWidget(
      _buildHost(
        itemsNotifier: items,
        type: PaginateBuilderType.gridView,
        preserveCenteredItemOnInsert: true,
        scrollController: scrollController,
      ),
    );
    await _centerListLikeItem(tester, scrollController, 10);

    final centeredItemBefore = _findClosestVisibleItemToViewportCenter(
      tester,
      items.value,
    );
    final beforePrepend = tester.getCenter(_itemFinder(centeredItemBefore)).dy;

    items.value = <int>[-4, -3, -2, -1, ...items.value];
    await tester.pump();
    await tester.pumpAndSettle();

    expect(_itemFinder(centeredItemBefore), findsOneWidget);
    final afterPrepend = tester.getCenter(_itemFinder(centeredItemBefore)).dy;
    expect((afterPrepend - beforePrepend).abs(), lessThan(12.0));

    items.value = <int>[...items.value, 2000, 2001, 2002, 2003];
    await tester.pump();
    await tester.pumpAndSettle();

    expect(_itemFinder(centeredItemBefore), findsOneWidget);
    final afterAppend = tester.getCenter(_itemFinder(centeredItemBefore)).dy;
    expect((afterAppend - afterPrepend).abs(), lessThan(12.0));
  });

  testWidgets(
    'PageView preserves the currently centered page item after prepend',
    (tester) async {
      final items = ValueNotifier<List<int>>(List<int>.generate(12, (i) => i));
      final pageController = PageController(initialPage: 5);

      await tester.pumpWidget(
        _buildHost(
          itemsNotifier: items,
          type: PaginateBuilderType.pageView,
          preserveCenteredItemOnInsert: true,
          pageController: pageController,
          scrollDirection: Axis.horizontal,
        ),
      );
      await tester.pumpAndSettle();

      expect(_itemFinder(5), findsOneWidget);

      items.value = <int>[-1, ...items.value];
      await tester.pump();
      await tester.pumpAndSettle();

      expect(_itemFinder(5), findsOneWidget);
      expect((pageController.page! - 6).abs(), lessThan(0.01));
    },
  );

  testWidgets('staggeredGridView and custom modes are no-op without throwing', (
    tester,
  ) async {
    final staggeredItems = ValueNotifier<List<int>>(
      List<int>.generate(20, (i) => i),
    );

    await tester.pumpWidget(
      _buildHost(
        itemsNotifier: staggeredItems,
        type: PaginateBuilderType.staggeredGridView,
        preserveCenteredItemOnInsert: true,
      ),
    );
    await tester.pumpAndSettle();

    staggeredItems.value = <int>[-2, -1, ...staggeredItems.value];
    await tester.pump();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    final customItems = ValueNotifier<List<int>>(
      List<int>.generate(8, (i) => i),
    );
    await tester.pumpWidget(
      _buildHost(
        itemsNotifier: customItems,
        type: PaginateBuilderType.custom,
        preserveCenteredItemOnInsert: true,
        customViewBuilder: (context, docs, _, __) {
          return ListView(
            children: [
              for (final item in docs)
                SizedBox(height: 60, child: Center(child: Text('item $item'))),
            ],
          );
        },
      ),
    );
    await tester.pumpAndSettle();

    customItems.value = <int>[-1, ...customItems.value];
    await tester.pump();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'preserveCenteredItemOnInsert=false keeps old shifting behavior',
    (tester) async {
      final items = ValueNotifier<List<int>>(List<int>.generate(60, (i) => i));
      final scrollController = ScrollController();

      await tester.pumpWidget(
        _buildHost(
          itemsNotifier: items,
          type: PaginateBuilderType.listView,
          preserveCenteredItemOnInsert: false,
          scrollController: scrollController,
        ),
      );
      await _centerListLikeItem(tester, scrollController, 10);

      final centeredItemBefore = _findClosestVisibleItemToViewportCenter(
        tester,
        items.value,
      );
      final beforeCenter = tester.getCenter(_itemFinder(centeredItemBefore)).dy;

      items.value = <int>[-3, -2, -1, ...items.value];
      await tester.pump();
      await tester.pumpAndSettle();

      expect(_itemFinder(centeredItemBefore), findsOneWidget);
      final afterCenter = tester.getCenter(_itemFinder(centeredItemBefore)).dy;
      expect((afterCenter - beforeCenter).abs(), greaterThan(80.0));
    },
  );
}
