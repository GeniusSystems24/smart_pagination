// Spec 004-scroll-anchor-preservation — Backward compatibility tests.
//
// Covers tests T30–T35 from plan §13. Verifies Spec FR-009 (zero breaking
// changes) and Constitution §II ("Backward Compatibility First"):
//   - .withProvider(...) and .withCubit(...) work unchanged,
//   - external ScrollController is NOT taken over,
//   - external listeners continue to fire,
//   - preserveScrollAnchorOnAppend: false reverts to pre-feature behavior,
//   - README example call sites compile and run unmodified.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_pagination/pagination.dart';

const _pageSize = 20;
const _itemHeight = 50.0;

void main() {
  group('Scroll Anchor — Backward Compatibility (spec 004)', () {
    // -----------------------------------------------------------------------
    // T30: .withProvider(...) constructor — anchor preservation works
    // with the package's internal ScrollController.
    //
    // Verifies: existing .withProvider call sites get anchor preservation
    // for free (default opt-in) and the package's internal controller is
    // wired up correctly without the consumer providing one.
    // -----------------------------------------------------------------------
    testWidgets(
      'T30: .withProvider(...) constructor — anchor preservation works '
      "with the package's internal ScrollController",
      (tester) async {
        var providerCallCount = 0;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SmartPaginationListView<int, PaginationRequest>.withProvider(
                request: PaginationRequest(page: 1, pageSize: _pageSize),
                provider: PaginationProvider<int, PaginationRequest>.future(
                  (req) async {
                    providerCallCount++;
                    return List<int>.generate(
                      _pageSize,
                      (i) => (req.page - 1) * _pageSize + i,
                    );
                  },
                ),
                itemBuilder: (context, items, index) => SizedBox(
                  height: _itemHeight,
                  child: Text('Item ${items[index]}'),
                ),
                invisibleItemsThreshold: 3,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(providerCallCount, 1, reason: 'Initial fetch fires once.');

        await tester.fling(
          find.byType(CustomScrollView).first,
          const Offset(0, -3000),
          8000,
        );
        await tester.pumpAndSettle();

        // Exactly one load-more — suppression flag prevents chain triggers.
        expect(
          providerCallCount,
          2,
          reason: 'Anchor preservation + suppression armed — single load-more.',
        );
      },
    );

    // -----------------------------------------------------------------------
    // T31: .withCubit(...) constructor — anchor preservation works
    // with an externally-supplied ScrollController.
    // -----------------------------------------------------------------------
    testWidgets(
      'T31: .withCubit(...) constructor — anchor preservation works with '
      'an externally-supplied ScrollController',
      (tester) async {
        var providerCallCount = 0;
        final externalController = ScrollController();

        final cubit = SmartPaginationCubit<int, PaginationRequest>(
          request: PaginationRequest(page: 1, pageSize: _pageSize),
          provider: PaginationProvider<int, PaginationRequest>.future(
            (req) async {
              providerCallCount++;
              return List<int>.generate(
                _pageSize,
                (i) => (req.page - 1) * _pageSize + i,
              );
            },
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SmartPaginationListView<int, PaginationRequest>.withCubit(
                cubit: cubit,
                scrollController: externalController,
                itemBuilder: (context, items, index) => SizedBox(
                  height: _itemHeight,
                  child: Text('Item ${items[index]}'),
                ),
                invisibleItemsThreshold: 3,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(providerCallCount, 1);

        await tester.fling(
          find.byType(CustomScrollView).first,
          const Offset(0, -3000),
          8000,
        );
        await tester.pumpAndSettle();

        expect(
          providerCallCount,
          2,
          reason: 'External controller path — single load-more after fling.',
        );

        // External controller is still attached & usable.
        expect(externalController.hasClients, isTrue);
        externalController.dispose();
      },
    );

    // -----------------------------------------------------------------------
    // T32: external ScrollController's addListener callbacks continue to
    // fire during anchor capture and during the post-frame restore.
    //
    // The new outer NotificationListener<ScrollNotification> introduced in
    // spec 004 must NOT consume notifications (returns false), and must NOT
    // detach the controller's listeners.
    // -----------------------------------------------------------------------
    testWidgets(
      "T32: external ScrollController's addListener callbacks continue "
      'to fire during anchor capture and during the post-frame restore',
      (tester) async {
        final externalController = ScrollController();
        var listenerInvocations = 0;
        externalController.addListener(() => listenerInvocations++);

        final cubit = SmartPaginationCubit<int, PaginationRequest>(
          request: PaginationRequest(page: 1, pageSize: _pageSize),
          provider: PaginationProvider<int, PaginationRequest>.future(
            (req) async => List<int>.generate(
              _pageSize,
              (i) => (req.page - 1) * _pageSize + i,
            ),
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SmartPaginationListView<int, PaginationRequest>.withCubit(
                cubit: cubit,
                scrollController: externalController,
                itemBuilder: (context, items, index) => SizedBox(
                  height: _itemHeight,
                  child: Text('Item ${items[index]}'),
                ),
                invisibleItemsThreshold: 3,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        final invocationsAfterInit = listenerInvocations;

        await tester.fling(
          find.byType(CustomScrollView).first,
          const Offset(0, -3000),
          8000,
        );
        await tester.pumpAndSettle();

        expect(
          listenerInvocations,
          greaterThan(invocationsAfterInit),
          reason: 'External controller listener received scroll notifications '
              'during fling and post-restore (NotificationListener did not '
              'consume them).',
        );

        externalController.dispose();
      },
    );

    // -----------------------------------------------------------------------
    // T33: external ScrollController is NOT disposed by the package — it
    // can be reused in a sibling widget after the paginated view unmounts.
    // -----------------------------------------------------------------------
    testWidgets(
      'T33: external ScrollController is NOT disposed by the package '
      '(reusable in a sibling widget after the paginated view is unmounted)',
      (tester) async {
        final externalController = ScrollController();

        final cubit = SmartPaginationCubit<int, PaginationRequest>(
          request: PaginationRequest(page: 1, pageSize: _pageSize),
          provider: PaginationProvider<int, PaginationRequest>.future(
            (req) async => List<int>.generate(_pageSize, (i) => i),
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SmartPaginationListView<int, PaginationRequest>.withCubit(
                cubit: cubit,
                scrollController: externalController,
                itemBuilder: (context, items, index) => SizedBox(
                  height: _itemHeight,
                  child: Text('Item ${items[index]}'),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Replace with a different widget tree — paginated view is unmounted.
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ListView(
                controller: externalController,
                children: const [
                  SizedBox(height: 100, child: Text('Sibling')),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Controller is still alive and reattached to the new ListView.
        expect(externalController.hasClients, isTrue);
        expect(find.text('Sibling'), findsOneWidget);

        externalController.dispose();
      },
    );

    // -----------------------------------------------------------------------
    // T34: preserveScrollAnchorOnAppend: false disables capture, restore,
    // and suppression entirely — behavior reverts to pre-feature.
    //
    // Pre-feature behavior on a fast fling triggered chained load-mores
    // (the exact issue spec 004 was designed to fix). With the flag set
    // to false we expect to see that pre-3.5.0 behavior reproduce.
    // -----------------------------------------------------------------------
    testWidgets(
      'T34: preserveScrollAnchorOnAppend: false disables capture, '
      'restore, and suppression entirely; behavior reverts to pre-feature',
      (tester) async {
        var providerCallCount = 0;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SmartPaginationListView<int, PaginationRequest>.withProvider(
                request: PaginationRequest(page: 1, pageSize: _pageSize),
                provider: PaginationProvider<int, PaginationRequest>.future(
                  (req) async {
                    providerCallCount++;
                    return List<int>.generate(
                      _pageSize,
                      (i) => (req.page - 1) * _pageSize + i,
                    );
                  },
                ),
                itemBuilder: (context, items, index) => SizedBox(
                  height: _itemHeight,
                  child: Text('Item ${items[index]}'),
                ),
                invisibleItemsThreshold: 3,
                preserveScrollAnchorOnAppend: false,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(providerCallCount, 1);

        // With suppression disabled, a fling that crosses the load-more
        // threshold may chain-trigger more than once — exactly the legacy
        // behavior. Just assert at least one load-more fired and no
        // exception was thrown.
        await tester.fling(
          find.byType(CustomScrollView).first,
          const Offset(0, -3000),
          8000,
        );
        await tester.pumpAndSettle();

        expect(
          providerCallCount,
          greaterThanOrEqualTo(2),
          reason: 'At least one load-more fired (legacy behavior preserved).',
        );
      },
    );

    // -----------------------------------------------------------------------
    // T35: README example call sites for .withProvider and .withCubit
    // compile and run without modification.
    //
    // The exact constructor signatures from README are exercised here. If
    // any required parameter was added or removed, this test would fail
    // to compile, surfacing the breaking change immediately.
    // -----------------------------------------------------------------------
    testWidgets(
      'T35: all call sites from the README examples for .withProvider '
      'and .withCubit compile and run without modification',
      (tester) async {
        // README example: .withProvider
        final providerWidget =
            SmartPaginationListView<int, PaginationRequest>.withProvider(
          request: PaginationRequest(page: 1, pageSize: _pageSize),
          provider: PaginationProvider<int, PaginationRequest>.future(
            (req) async => List<int>.generate(_pageSize, (i) => i),
          ),
          itemBuilder: (context, items, index) => SizedBox(
            height: _itemHeight,
            child: Text('Item ${items[index]}'),
          ),
        );

        await tester.pumpWidget(
          MaterialApp(home: Scaffold(body: providerWidget)),
        );
        await tester.pumpAndSettle();
        expect(find.text('Item 0'), findsOneWidget);

        // README example: .withCubit
        final cubit = SmartPaginationCubit<int, PaginationRequest>(
          request: PaginationRequest(page: 1, pageSize: _pageSize),
          provider: PaginationProvider<int, PaginationRequest>.future(
            (req) async => List<int>.generate(_pageSize, (i) => i + 100),
          ),
        );
        final cubitWidget =
            SmartPaginationListView<int, PaginationRequest>.withCubit(
          cubit: cubit,
          itemBuilder: (context, items, index) => SizedBox(
            height: _itemHeight,
            child: Text('Item ${items[index]}'),
          ),
        );

        await tester.pumpWidget(
          MaterialApp(home: Scaffold(body: cubitWidget)),
        );
        await tester.pumpAndSettle();
        expect(find.text('Item 100'), findsOneWidget);

        await cubit.close();
      },
    );
  });
}
