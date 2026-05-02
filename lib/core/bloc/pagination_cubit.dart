part of '../../pagination.dart';

/// Base interface for pagination cubits that provides common functionality
/// for both SmartPagination and DualPagination cubits.
///
/// [F] is the type of the [PaginationRequest.filters] field. It defaults to
/// `dynamic` so that existing code without typed filters continues to compile.
abstract class IPaginationCubit<T, StateType extends IPaginationState<T>,
    F extends Object?> extends Cubit<StateType> {
  IPaginationCubit(super.initialState);

  /// Initial request configuration used when the pagination starts.
  PaginationRequest<F> get initialRequest;

  /// Filters the paginated list based on the provided search term.
  void filterPaginatedList(WhereChecker<T>? searchTerm);

  /// Refreshes the paginated list, starting from the beginning.
  void refreshPaginatedList({PaginationRequest<F>? requestOverride, int? limit});

  /// Fetches the next page of the paginated list.
  void fetchPaginatedList({PaginationRequest<F>? requestOverride, int? limit});

  /// Cancels any inflight work.
  void cancelOngoingRequest();

  /// Disposes the cubit and its resources.
  void dispose() {
    cancelOngoingRequest();
  }
}

/// Base interface for pagination cubits with list building capabilities.
abstract class IPaginationListCubit<T, StateType extends IPaginationState<T>,
    F extends Object?> extends IPaginationCubit<T, StateType, F> {
  IPaginationListCubit(super.initialState);

  /// Whether the cubit has fetched data at least once.
  bool get didFetch;

  /// Optional hook to transform or sort items before emitting.
  ListBuilder<T>? get listBuilder;

  /// Returns the current list of items, or empty list if not loaded.
  List<T> get currentItems;

  /// Inserts an item at the specified index.
  /// Returns true if the item was successfully inserted.
  Future<bool> insertEmit(T item, {int index = 0});

  /// Inserts multiple items at the specified index.
  /// Returns true if the items were successfully inserted.
  Future<bool> insertAllEmit(List<T> items, {int index = 0});

  /// Adds or updates an item in the list.
  /// Returns true if the operation was successful.
  Future<bool> addOrUpdateEmit(T item, {int index = 0});

  /// Removes an item from the list.
  /// Returns true if the item was found and removed.
  Future<bool> removeItemEmit(T item);

  /// Removes an item at the specified index.
  /// Returns true if the item was found and removed.
  Future<bool> removeAtEmit(int index);

  /// Removes all items that match the predicate.
  /// Returns true if any items were removed.
  Future<bool> removeWhereEmit(bool Function(T item) test);

  /// Updates an item in the list using a matcher and updater function.
  /// Returns true if an item was found and updated.
  Future<bool> updateItemEmit(
      bool Function(T item) matcher, T Function(T item) updater);

  /// Updates all items that match the predicate.
  /// Returns true if any items were updated.
  Future<bool> updateWhereEmit(
      bool Function(T item) matcher, T Function(T item) updater);

  /// Clears all items from the list.
  /// Returns true if the operation was successful.
  Future<bool> clearItems();

  /// Reloads the list from the beginning (alias for refreshPaginatedList).
  void reload();

  /// Sets the list to a completely new set of items.
  /// Returns true if the operation was successful.
  Future<bool> setItems(List<T> items);

  /// Refreshes a specific item by re-fetching it from the server.
  ///
  /// [matcher] identifies which item to refresh.
  /// [refresher] is a callback that fetches the updated item from the server.
  ///
  /// Returns true if the item was found and refreshed, false otherwise.
  Future<bool> refreshItem(
    bool Function(T item) matcher,
    Future<T> Function(T currentItem) refresher,
  );
}
