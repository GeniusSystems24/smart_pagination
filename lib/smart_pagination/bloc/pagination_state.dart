part of '../../pagination.dart';

@immutable
abstract class SmartPaginationState<T> implements IPaginationInitialState<T> {
  @override
  bool get hasReachedEnd => false;

  @override
  DateTime get lastUpdate => DateTime.now();

  @override
  PaginationMeta? get meta => null;
}

class SmartPaginationInitial<T> extends SmartPaginationState<T> {}

class SmartPaginationError<T> extends SmartPaginationState<T>
    implements IPaginationErrorState<T> {
  final Exception _error;
  SmartPaginationError({required Exception error}) : _error = error;

  @override
  Exception get error => _error;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SmartPaginationError<T> && other.error == error;
  }

  @override
  int get hashCode => error.hashCode;
}

/// Describes the last item-level operation that triggered a state emission.
sealed class PaginationOperation {
  const PaginationOperation();
}

/// No operation — default state.
class PaginationOperationNone extends PaginationOperation {
  const PaginationOperationNone();
}

/// An item was inserted at [index]. [count] items were inserted.
class PaginationOperationInsert extends PaginationOperation {
  final int index;
  final int count;
  const PaginationOperationInsert({required this.index, this.count = 1});
}

/// An item was removed at [index]. [count] items were removed.
/// If [index] is -1, the exact indices are unknown (e.g., removeWhere).
class PaginationOperationRemove extends PaginationOperation {
  final int index;
  final int count;
  const PaginationOperationRemove({required this.index, this.count = 1});
}

/// Items at [indices] were updated in place.
class PaginationOperationUpdate extends PaginationOperation {
  final List<int> indices;
  const PaginationOperationUpdate({required this.indices});
}

/// A single item at [index] was refreshed from the server.
class PaginationOperationRefresh extends PaginationOperation {
  final int index;
  const PaginationOperationRefresh({required this.index});
}

/// A full reload occurred (clear, setItems, fetch).
class PaginationOperationReload extends PaginationOperation {
  const PaginationOperationReload();
}

class SmartPaginationLoaded<T> extends SmartPaginationState<T>
    implements IPaginationLoadedState<T> {
  SmartPaginationLoaded({
    required this.items,
    required this.allItems,
    required this.meta,
    required this.hasReachedEnd,
    DateTime? lastUpdate,
    this.isLoadingMore = false,
    this.loadMoreError,
    this.fetchedAt,
    this.dataExpiredAt,
    this.activeOrderId,
    this.lastOperation = const PaginationOperationNone(),
    this.pageErrors = const <int, Object>{},
  }) : lastUpdate = lastUpdate ?? DateTime.now();

  final List<T> items;
  @override
  final List<T> allItems;
  @override
  final PaginationMeta meta;
  @override
  final bool hasReachedEnd;
  @override
  final DateTime lastUpdate;

  /// Whether the pagination is currently loading more items
  final bool isLoadingMore;

  /// Error that occurred while loading more items (if any)
  final Exception? loadMoreError;

  /// Timestamp when data was initially fetched (for data age tracking)
  final DateTime? fetchedAt;

  /// Timestamp when data will expire (null if no expiration configured)
  final DateTime? dataExpiredAt;

  /// The ID of the currently active sort order (null if no sorting applied)
  final String? activeOrderId;

  /// The last item-level operation that triggered this state emission.
  /// This is metadata for the UI to optimize rebuilds and trigger animations.
  /// Not included in equality checks.
  final PaginationOperation lastOperation;

  /// Per-page errors emitted by the stream provider when one page's underlying
  /// stream errors while sibling pages keep emitting.
  ///
  /// Keys are 1-based page indices; values are the error objects produced by
  /// the failing page's stream. The failing page's subscription is cancelled
  /// before this map is populated; sibling pages are unaffected. Empty when
  /// no per-page error is in flight.
  final Map<int, Object> pageErrors;

  SmartPaginationLoaded<T> copyWith({
    List<T>? items,
    List<T>? allItems,
    bool? hasReachedEnd,
    PaginationMeta? meta,
    DateTime? lastUpdate,
    bool? isLoadingMore,
    Exception? loadMoreError,
    DateTime? fetchedAt,
    DateTime? dataExpiredAt,
    String? activeOrderId,
    PaginationOperation lastOperation = const PaginationOperationNone(),
    Map<int, Object>? pageErrors,
  }) {
    final updatedAllItems = allItems ?? this.allItems;
    final updatedItems = items ?? this.items;

    return SmartPaginationLoaded<T>(
      items: updatedItems,
      allItems: updatedAllItems,
      hasReachedEnd: hasReachedEnd ?? this.hasReachedEnd,
      meta: meta ?? this.meta,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      loadMoreError: loadMoreError ?? this.loadMoreError,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      dataExpiredAt: dataExpiredAt ?? this.dataExpiredAt,
      activeOrderId: activeOrderId ?? this.activeOrderId,
      lastOperation: lastOperation,
      pageErrors: pageErrors ?? this.pageErrors,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SmartPaginationLoaded<T> &&
        other.hasReachedEnd == hasReachedEnd &&
        other.isLoadingMore == isLoadingMore &&
        other.loadMoreError == loadMoreError &&
        identical(other.lastOperation, lastOperation) &&
        listEquals(other.items, items) &&
        listEquals(other.allItems, allItems) &&
        other.meta == meta &&
        mapEquals(other.pageErrors, pageErrors);
  }

  @override
  int get hashCode => Object.hash(
    hasReachedEnd,
    isLoadingMore,
    loadMoreError,
    identityHashCode(lastOperation),
    Object.hashAll(items),
    Object.hashAll(allItems),
    meta,
    Object.hashAllUnordered(pageErrors.entries.map((e) => Object.hash(e.key, e.value))),
  );
}

// ============================================================================
// Spec 004-scroll-anchor-preservation — anchor data model.
// ============================================================================
// These private types support the scroll-anchor preservation feature: the
// cubit captures a snapshot of the visible viewport before each load-more
// fetch (`_pendingAnchor`) and restores the viewport relative to that anchor
// in a post-frame callback after the new page is appended.
//
// See specs/004-scroll-anchor-preservation/data-model.md and
// specs/004-scroll-anchor-preservation/contracts/anchor-strategy.md.
// ============================================================================

/// The strategy used to identify and restore a scroll anchor.
/// Selected at capture time based on the available inputs (per the hybrid
/// policy in spec Q1):
///   - [key] when the consumer supplies `itemKeyBuilder`,
///   - [itemIndex] for finite-item builders without `itemKeyBuilder`,
///   - [offset] as a fallback for `StaggeredGridView` and any view without
///     a `scrollview_observer` integration.
///
/// Spec 004-scroll-anchor-preservation §4 (Anchor Capture Strategy).
///
/// Note: this enum value is named [itemIndex] (not `index`) because Dart's
/// built-in `Enum.index` getter occupies that name on every enum value.
enum AnchorStrategy {
  /// Anchor identified by the consumer-supplied `itemKeyBuilder` value.
  /// Highest fidelity. Used when `itemKeyBuilder != null`.
  key,

  /// Anchor identified by item index in the items list.
  /// Used for finite-item builders (`ListView` / `GridView`) when no
  /// `itemKeyBuilder` is supplied. Safe under append-only scope (FR-001a).
  itemIndex,

  /// Anchor identified by scroll-controller pixel offset and extent delta.
  /// Used as a fallback for `StaggeredGridView` and any view without a
  /// `scrollview_observer` integration.
  offset,
}

/// View type the anchor snapshot was captured against. Not exposed publicly.
/// Out-of-scope view types (`pageView`, `reorderableListView`, `custom`)
/// cause the cubit to short-circuit anchor capture and restore as a no-op.
///
/// Spec 004-scroll-anchor-preservation §8 (View-Type Support Plan), Q5.
enum _AnchorViewType {
  listView,
  gridView,
  customScrollView,
  staggeredGridView,
  pageView, // out of scope (v1) — short-circuit
  reorderableListView, // out of scope (v1) — short-circuit
  custom, // unknown view type — short-circuit
}

/// Snapshot of the visible viewport at the moment a load-more fetch is
/// initiated. Captured by the widget layer (via the `scrollview_observer`
/// integration) and passed to the cubit via
/// [SmartPaginationCubit.captureAnchorBeforeLoadMore]. Consumed in a
/// post-frame callback after the new page is appended.
///
/// Spec 004-scroll-anchor-preservation §4.3, data-model.md §1.
class _PendingScrollAnchor {
  _PendingScrollAnchor({
    required this.strategy,
    required this.viewType,
    required this.reverse,
    required this.generation,
    this.key,
    this.index,
    this.leadingEdgeOffset,
    this.pixelsBefore,
    this.extentBefore,
  });

  /// Selected strategy for this snapshot. Determines which fields are
  /// populated and which restore mechanism is used.
  final AnchorStrategy strategy;

  /// View type the snapshot was captured against. Used to gate restore
  /// (no-op for out-of-scope view types).
  final _AnchorViewType viewType;

  /// Whether the source scrollable was `reverse: true`. v1 treats reverse
  /// lists as out of scope; restore is a no-op when this is true.
  final bool reverse;

  /// Cubit `_generation` value at capture time. The restore is discarded
  /// if the cubit's `_generation` no longer matches at restore time, which
  /// is the signal that a scope reset (refresh / filter / search)
  /// interleaved with the in-flight fetch.
  final int generation;

  /// Anchor item's identity key, computed via the consumer's
  /// `itemKeyBuilder`. Populated only when [strategy] is
  /// [AnchorStrategy.key].
  final Object? key;

  /// Anchor item's index in the items list at capture time.
  /// Populated when [strategy] is in {[AnchorStrategy.key],
  /// [AnchorStrategy.index]}.
  final int? index;

  /// Pixels from the viewport top to the anchor item's leading edge at
  /// capture time. Diagnostic / fidelity-validation field; not required
  /// for the standard restore path.
  final double? leadingEdgeOffset;

  /// `controller.position.pixels` at capture time. Required when [strategy]
  /// is [AnchorStrategy.offset]; also captured for the other strategies as
  /// a fallback for the anchor-not-found edge case (FR-008).
  final double? pixelsBefore;

  /// `controller.position.maxScrollExtent` at capture time. Diagnostic /
  /// future-use field.
  final double? extentBefore;
}
