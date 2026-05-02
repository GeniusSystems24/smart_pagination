part of '../pagination.dart';

typedef WhereChecker<T> = bool Function(T item);
typedef CompareBy<T> = int Function(T a, T b);
typedef OnInsertionCallback<T> = void Function(List<T> items);

/// Unified pagination data provider that can be either Future-based or Stream-based.
///
/// The second type parameter [F] is the type of the [PaginationRequest.filters]
/// field. It defaults to `dynamic` so that existing code using untyped filters
/// continues to work without modification.
///
/// Use [PaginationProvider.future] for standard REST API pagination.
/// Use [PaginationProvider.stream] for real-time updates.
///
/// Example with Future (untyped – backward-compatible):
/// ```dart
/// final provider = PaginationProvider<Product>.future(
///   (request) => apiService.fetchProducts(request),
/// );
/// ```
///
/// Example with typed filters:
/// ```dart
/// final provider = PaginationProvider<Product, ProductFilters>.future(
///   (request) => apiService.fetchProducts(request.filters!),
/// );
/// ```
///
/// Example with Stream:
/// ```dart
/// final provider = PaginationProvider<Product, ProductFilters>.stream(
///   (request) => apiService.productsStream(request),
/// );
/// ```
sealed class PaginationProvider<T, F extends Object?> {
  const PaginationProvider();

  /// Creates a Future-based pagination provider for standard REST APIs.
  const factory PaginationProvider.future(
    Future<List<T>> Function(PaginationRequest<F> request) dataProvider,
  ) = FuturePaginationProvider<T, F>;

  /// Creates a Stream-based pagination provider for real-time updates.
  const factory PaginationProvider.stream(
    Stream<List<T>> Function(PaginationRequest<F> request) streamProvider,
  ) = StreamPaginationProvider<T, F>;

  /// Creates a provider that merges multiple streams into a single stream.
  ///
  /// When you have multiple data sources (streams) and want to combine them
  /// into one unified stream, use this provider.
  ///
  /// Example:
  /// ```dart
  /// final provider = PaginationProvider<Product, ProductFilters>.mergeStreams(
  ///   (request) => [
  ///     apiService.regularProductsStream(request),
  ///     apiService.featuredProductsStream(request),
  ///   ],
  /// );
  /// ```
  factory PaginationProvider.mergeStreams(
    List<Stream<List<T>>> Function(PaginationRequest<F> request) streamsProvider,
  ) = MergedStreamPaginationProvider<T, F>;
}

/// Future-based pagination provider for standard REST APIs.
final class FuturePaginationProvider<T, F extends Object?>
    extends PaginationProvider<T, F> {
  const FuturePaginationProvider(this.dataProvider);

  /// Function that fetches a page of data from your API.
  final Future<List<T>> Function(PaginationRequest<F> request) dataProvider;
}

/// Stream-based pagination provider for real-time updates.
final class StreamPaginationProvider<T, F extends Object?>
    extends PaginationProvider<T, F> {
  const StreamPaginationProvider(this.streamProvider);

  /// Function that provides a stream of data updates.
  final Stream<List<T>> Function(PaginationRequest<F> request) streamProvider;
}

/// Merged streams pagination provider that combines multiple streams into one.
///
/// This provider takes multiple data streams and merges them into a single
/// stream, emitting data whenever any of the source streams emit.
final class MergedStreamPaginationProvider<T, F extends Object?>
    extends PaginationProvider<T, F> {
  MergedStreamPaginationProvider(this.streamsProvider);

  /// Function that provides a list of streams to be merged.
  final List<Stream<List<T>>> Function(PaginationRequest<F> request)
      streamsProvider;

  /// Gets a merged stream that combines all source streams.
  Stream<List<T>> getMergedStream(PaginationRequest<F> request) {
    final streams = streamsProvider(request);

    if (streams.isEmpty) {
      return Stream.value([]);
    }

    if (streams.length == 1) {
      return streams.first;
    }

    // Create a stream controller to merge all streams
    late StreamController<List<T>> controller;
    final subscriptions = <StreamSubscription<List<T>>>[];

    controller = StreamController<List<T>>(
      onListen: () {
        for (final stream in streams) {
          final subscription = stream.listen(
            (data) => controller.add(data),
            onError: (error) => controller.addError(error),
          );
          subscriptions.add(subscription);
        }
      },
      onCancel: () async {
        for (final subscription in subscriptions) {
          await subscription.cancel();
        }
      },
    );

    return controller.stream;
  }
}

/// Legacy typedef for backward compatibility (will be deprecated).
typedef PaginationDataProvider<T> =
    Future<List<T>> Function(PaginationRequest request);

/// Legacy typedef for backward compatibility (will be deprecated).
typedef PaginationStreamProvider<T> =
    Stream<List<T>> Function(PaginationRequest request);

/// Signature for a function that builds a list from fetched items.
typedef ListBuilder<T> = List<T> Function(List<T> list);

/// Signature for a callback function that is called when items are inserted.
typedef InsertAllCallback<T> =
    void Function(List<T> currentItems, Iterable<T> newItems);
