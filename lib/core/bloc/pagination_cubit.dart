part of '../../pagination.dart';

/// Base interface for pagination cubits that provides common functionality
/// for both SmartPagination and DualPagination cubits.
abstract class IPaginationCubit<T, StateType extends IPaginationState<T>>
    extends Cubit<StateType> {
  IPaginationCubit(super.initialState);

  /// Initial request configuration used when the pagination starts.
  PaginationRequest get initialRequest;

  /// Filters the paginated list based on the provided search term.
  void filterPaginatedList(WhereChecker<T>? searchTerm);

  /// Refreshes the paginated list, starting from the beginning.
  void refreshPaginatedList({PaginationRequest? requestOverride, int? limit});

  /// Fetches the next page of the paginated list.
  void fetchPaginatedList({PaginationRequest? requestOverride, int? limit});

  /// Cancels any inflight work.
  void cancelOngoingRequest();

  /// Disposes the cubit and its resources.
  void dispose() {
    cancelOngoingRequest();
  }
}

/// Base interface for pagination cubits with list building capabilities.
abstract class IPaginationListCubit<T, StateType extends IPaginationState<T>>
    extends IPaginationCubit<T, StateType> {
  IPaginationListCubit(super.initialState);

  /// Whether the cubit has fetched data at least once.
  bool get didFetch;

  /// Optional hook to transform or sort items before emitting.
  ListBuilder<T>? get listBuilder;

  /// Returns the current list of items, or empty list if not loaded.
  List<T> get currentItems;

  /// Inserts an item at the specified index.
  void insertEmit(T item, {int index = 0});

  /// Inserts multiple items at the specified index.
  void insertAllEmit(List<T> items, {int index = 0});

  /// Adds or updates an item in the list.
  void addOrUpdateEmit(T item, {int index = 0});

  /// Removes an item from the list.
  /// Returns true if the item was found and removed.
  bool removeItemEmit(T item);

  /// Removes an item at the specified index.
  /// Returns the removed item, or null if index is out of bounds.
  T? removeAtEmit(int index);

  /// Removes all items that match the predicate.
  /// Returns the number of items removed.
  int removeWhereEmit(bool Function(T item) test);

  /// Updates an item in the list using a matcher and updater function.
  /// Returns true if an item was found and updated.
  bool updateItemEmit(bool Function(T item) matcher, T Function(T item) updater);

  /// Updates all items that match the predicate.
  /// Returns the number of items updated.
  int updateWhereEmit(
      bool Function(T item) matcher, T Function(T item) updater);

  /// Clears all items from the list.
  void clearItems();

  /// Reloads the list from the beginning (alias for refreshPaginatedList).
  void reload();

  /// Sets the list to a completely new set of items.
  void setItems(List<T> items);
}
