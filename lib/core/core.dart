part of '../pagination.dart';

typedef WhereChecker<T> = bool Function(T item);
typedef CompareBy<T> = int Function(T a, T b);
typedef OnInsertionCallback<T> = void Function(List<T> items);

/// Unified pagination data provider that can be either Future-based or Stream-based.
///
/// The second type parameter [R] is the concrete [PaginationRequest] type
/// (or subclass) that the provider callback will receive. This enables
/// compile-time type safety when passing custom request objects.
///
/// Use [PaginationProvider.future] for standard REST API pagination.
/// Use [PaginationProvider.stream] for real-time updates.
///
/// Example with the base request type (no custom fields):
/// ```dart
/// final provider = PaginationProvider<Product, PaginationRequest>.future(
///   (request) => apiService.fetchProducts(request),
/// );
/// // Shorthand – PaginationRequest is the default bound:
/// final provider = PaginationProvider<Product>.future(
///   (request) => apiService.fetchProducts(request),
/// );
/// ```
///
/// Example with a custom typed request:
/// ```dart
/// final provider = PaginationProvider<Product, ProductRequest>.future(
///   (req) => apiService.fetchProducts(req.category, maxPrice: req.maxPrice),
/// );
/// ```
///
/// Example with Stream:
/// ```dart
/// final provider = PaginationProvider<Product, ProductRequest>.stream(
///   (req) => apiService.productsStream(req.category),
/// );
/// ```
sealed class PaginationProvider<T, R extends PaginationRequest> {
  const PaginationProvider();

  /// Creates a Future-based pagination provider for standard REST APIs.
  const factory PaginationProvider.future(
    Future<List<T>> Function(R request) dataProvider,
  ) = FuturePaginationProvider<T, R>;

  /// Creates a Stream-based pagination provider for real-time updates.
  const factory PaginationProvider.stream(
    Stream<List<T>> Function(R request) streamProvider,
  ) = StreamPaginationProvider<T, R>;

  /// Creates a provider that merges multiple streams into a single stream.
  ///
  /// When you have multiple data sources (streams) and want to combine them
  /// into one unified stream, use this provider.
  ///
  /// Example:
  /// ```dart
  /// final provider = PaginationProvider<Product, ProductRequest>.mergeStreams(
  ///   (req) => [
  ///     apiService.regularProductsStream(req),
  ///     apiService.featuredProductsStream(req),
  ///   ],
  /// );
  /// ```
  factory PaginationProvider.mergeStreams(
    List<Stream<List<T>>> Function(R request) streamsProvider,
  ) = MergedStreamPaginationProvider<T, R>;
}

/// Future-based pagination provider for standard REST APIs.
final class FuturePaginationProvider<T, R extends PaginationRequest>
    extends PaginationProvider<T, R> {
  const FuturePaginationProvider(this.dataProvider);

  /// Function that fetches a page of data from your API.
  final Future<List<T>> Function(R request) dataProvider;
}

/// Stream-based pagination provider for real-time updates.
final class StreamPaginationProvider<T, R extends PaginationRequest>
    extends PaginationProvider<T, R> {
  const StreamPaginationProvider(this.streamProvider);

  /// Function that provides a stream of data updates.
  final Stream<List<T>> Function(R request) streamProvider;
}

/// Merged streams pagination provider that combines multiple streams into one.
///
/// This provider takes multiple data streams and merges them into a single
/// stream, emitting data whenever any of the source streams emit.
final class MergedStreamPaginationProvider<T, R extends PaginationRequest>
    extends PaginationProvider<T, R> {
  MergedStreamPaginationProvider(this.streamsProvider);

  /// Function that provides a list of streams to be merged.
  final List<Stream<List<T>>> Function(R request) streamsProvider;

  /// Gets a merged stream that combines all source streams.
  Stream<List<T>> getMergedStream(R request) {
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
