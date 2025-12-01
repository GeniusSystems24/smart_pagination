import 'dart:math';
import 'dart:async';
import 'package:smart_pagination/pagination.dart';
import '../models/product.dart';
import '../models/message.dart';

/// Mock API service to simulate backend calls
class MockApiService {
  static final _random = Random();

  // Simulate network delay
  static const _networkDelay = Duration(milliseconds: 800);

  // Categories for products
  static const _categories = [
    'Electronics',
    'Books',
    'Clothing',
    'Home & Garden',
    'Sports',
    'Toys',
  ];

  // Sample product names
  static const _productNames = [
    'Wireless Headphones',
    'Smart Watch',
    'Laptop',
    'Running Shoes',
    'Coffee Maker',
    'Desk Lamp',
    'Backpack',
    'Water Bottle',
    'Yoga Mat',
    'Gaming Mouse',
  ];

  /// Fetch products with guaranteed error (for testing error handling)
  Future<List<Product>> fetchProductsWithError(
    PaginationRequest request,
  ) async {
    await Future.delayed(_networkDelay);
    throw Exception('Network error: Unable to connect to server');
  }

  /// Fetch products with pagination
  static Future<List<Product>> fetchProducts(
    PaginationRequest request, {
    bool simulateError = false,
  }) async {
    await Future.delayed(_networkDelay);

    if (simulateError && _random.nextDouble() < 0.3) {
      throw Exception('Network error: Failed to fetch products');
    }

    final pageSize = request.pageSize ?? 20;
    final startIndex = (request.page - 1) * pageSize;

    // Generate products
    final products = List.generate(
      pageSize,
      (index) {
        final productIndex = startIndex + index;
        return Product(
          id: 'product_$productIndex',
          name: '${_productNames[productIndex % _productNames.length]} #$productIndex',
          description: 'High quality product with amazing features. Perfect for your needs.',
          price: 19.99 + (productIndex % 100) * 5.0,
          category: _categories[productIndex % _categories.length],
          imageUrl: 'https://picsum.photos/200/200?random=$productIndex',
          createdAt: DateTime.now().subtract(Duration(days: productIndex)),
        );
      },
    );

    // Apply filters if provided
    if (request.filters != null) {
      final category = request.filters!['category'] as String?;
      if (category != null) {
        return products.where((p) => p.category == category).toList();
      }
    }

    return products;
  }

  /// Fetch messages with pagination
  static Future<List<Message>> fetchMessages(
    PaginationRequest request,
  ) async {
    await Future.delayed(_networkDelay);

    final pageSize = request.pageSize ?? 50;
    final startIndex = (request.page - 1) * pageSize;

    // Generate messages
    final messages = List.generate(
      pageSize,
      (index) {
        final messageIndex = startIndex + index;
        final daysAgo = messageIndex ~/ 10; // 10 messages per day
        final timestamp = DateTime.now().subtract(Duration(
          days: daysAgo,
          hours: messageIndex % 24,
        ));

        return Message(
          id: 'message_$messageIndex',
          content: 'Message content #$messageIndex. This is a sample message with some text.',
          author: 'User ${messageIndex % 5}',
          timestamp: timestamp,
          isRead: _random.nextBool(),
        );
      },
    );

    return messages;
  }

  /// Fetch limited products (for demonstrating end of list)
  static Future<List<Product>> fetchLimitedProducts(
    PaginationRequest request,
  ) async {
    await Future.delayed(_networkDelay);

    final pageSize = request.pageSize ?? 20;
    final startIndex = (request.page - 1) * pageSize;
    const totalProducts = 47; // Odd number to demonstrate end

    if (startIndex >= totalProducts) {
      return []; // No more products
    }

    final remainingProducts = totalProducts - startIndex;
    final itemsToReturn = remainingProducts < pageSize ? remainingProducts : pageSize;

    return List.generate(
      itemsToReturn,
      (index) {
        final productIndex = startIndex + index;
        return Product(
          id: 'product_$productIndex',
          name: 'Limited Product #$productIndex',
          description: 'This is from a limited collection.',
          price: 29.99 + productIndex * 2.0,
          category: _categories[productIndex % _categories.length],
          imageUrl: 'https://picsum.photos/200/200?random=$productIndex',
          createdAt: DateTime.now().subtract(Duration(days: productIndex)),
        );
      },
    );
  }

  /// Search products by name
  static Future<List<Product>> searchProducts(
    String query,
    PaginationRequest request,
  ) async {
    await Future.delayed(Duration(milliseconds: 500));

    final allProducts = await fetchProducts(request);

    if (query.isEmpty) {
      return allProducts;
    }

    return allProducts
        .where((p) => p.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  // ============= STREAM EXAMPLES =============

  /// Single stream: Products with real-time updates
  /// Simulates a backend that pushes updates every 3 seconds
  static Stream<List<Product>> productsStream(PaginationRequest request) async* {
    // Initial data
    yield await fetchProducts(request);

    // Simulate real-time updates every 3 seconds
    await for (final _ in Stream.periodic(const Duration(seconds: 3))) {
      // Generate updated products with random price changes
      final pageSize = request.pageSize ?? 20;
      final startIndex = (request.page - 1) * pageSize;

      final updatedProducts = List.generate(
        pageSize,
        (index) {
          final productIndex = startIndex + index;
          final priceVariation = (_random.nextDouble() - 0.5) * 10; // ±5

          return Product(
            id: 'product_$productIndex',
            name: '${_productNames[productIndex % _productNames.length]} #$productIndex',
            description: 'Updated at ${DateTime.now().toIso8601String().substring(11, 19)}',
            price: (19.99 + (productIndex % 100) * 5.0 + priceVariation).clamp(10.0, 999.0),
            category: _categories[productIndex % _categories.length],
            imageUrl: 'https://picsum.photos/200/200?random=$productIndex',
            createdAt: DateTime.now().subtract(Duration(days: productIndex)),
          );
        },
      );

      yield updatedProducts;
    }
  }

  /// Multiple streams: Products from different sources
  /// Stream 1: Regular products
  static Stream<List<Product>> regularProductsStream(PaginationRequest request) async* {
    final pageSize = request.pageSize ?? 10;
    final startIndex = (request.page - 1) * pageSize;

    await Future.delayed(const Duration(milliseconds: 500));

    yield List.generate(
      pageSize,
      (index) {
        final productIndex = startIndex + index;
        return Product(
          id: 'regular_$productIndex',
          name: 'Regular ${_productNames[productIndex % _productNames.length]} #$productIndex',
          description: 'Standard product from main inventory',
          price: 19.99 + (productIndex % 50) * 3.0,
          category: _categories[productIndex % _categories.length],
          imageUrl: 'https://picsum.photos/200/200?random=${productIndex + 1000}',
          createdAt: DateTime.now().subtract(Duration(days: productIndex)),
        );
      },
    );

    // Periodic updates every 5 seconds
    await for (final _ in Stream.periodic(const Duration(seconds: 5))) {
      yield List.generate(
        pageSize,
        (index) {
          final productIndex = startIndex + index;
          final priceChange = (_random.nextDouble() - 0.5) * 5;

          return Product(
            id: 'regular_$productIndex',
            name: 'Regular ${_productNames[productIndex % _productNames.length]} #$productIndex',
            description: 'Updated: ${DateTime.now().toIso8601String().substring(11, 19)}',
            price: (19.99 + (productIndex % 50) * 3.0 + priceChange).clamp(10.0, 500.0),
            category: _categories[productIndex % _categories.length],
            imageUrl: 'https://picsum.photos/200/200?random=${productIndex + 1000}',
            createdAt: DateTime.now().subtract(Duration(days: productIndex)),
          );
        },
      );
    }
  }

  /// Stream 2: Featured/premium products
  static Stream<List<Product>> featuredProductsStream(PaginationRequest request) async* {
    final pageSize = request.pageSize ?? 10;
    final startIndex = (request.page - 1) * pageSize;

    await Future.delayed(const Duration(milliseconds: 700));

    yield List.generate(
      pageSize,
      (index) {
        final productIndex = startIndex + index;
        return Product(
          id: 'featured_$productIndex',
          name: '⭐ Featured ${_productNames[productIndex % _productNames.length]} #$productIndex',
          description: 'Premium product with exclusive features',
          price: 49.99 + (productIndex % 30) * 10.0,
          category: _categories[productIndex % _categories.length],
          imageUrl: 'https://picsum.photos/200/200?random=${productIndex + 2000}',
          createdAt: DateTime.now().subtract(Duration(days: productIndex)),
        );
      },
    );

    // Periodic updates every 4 seconds
    await for (final _ in Stream.periodic(const Duration(seconds: 4))) {
      yield List.generate(
        pageSize,
        (index) {
          final productIndex = startIndex + index;
          final priceChange = (_random.nextDouble() - 0.5) * 8;

          return Product(
            id: 'featured_$productIndex',
            name: '⭐ Featured ${_productNames[productIndex % _productNames.length]} #$productIndex',
            description: 'Updated: ${DateTime.now().toIso8601String().substring(11, 19)}',
            price: (49.99 + (productIndex % 30) * 10.0 + priceChange).clamp(30.0, 999.0),
            category: _categories[productIndex % _categories.length],
            imageUrl: 'https://picsum.photos/200/200?random=${productIndex + 2000}',
            createdAt: DateTime.now().subtract(Duration(days: productIndex)),
          );
        },
      );
    }
  }

  /// Stream 3: Sale/discounted products
  static Stream<List<Product>> saleProductsStream(PaginationRequest request) async* {
    final pageSize = request.pageSize ?? 10;
    final startIndex = (request.page - 1) * pageSize;

    await Future.delayed(const Duration(milliseconds: 600));

    yield List.generate(
      pageSize,
      (index) {
        final productIndex = startIndex + index;
        return Product(
          id: 'sale_$productIndex',
          name: '🔥 Sale ${_productNames[productIndex % _productNames.length]} #$productIndex',
          description: 'Limited time offer - Huge discount!',
          price: 9.99 + (productIndex % 20) * 2.0,
          category: _categories[productIndex % _categories.length],
          imageUrl: 'https://picsum.photos/200/200?random=${productIndex + 3000}',
          createdAt: DateTime.now().subtract(Duration(days: productIndex)),
        );
      },
    );

    // Periodic updates every 3 seconds (sales change frequently)
    await for (final _ in Stream.periodic(const Duration(seconds: 3))) {
      yield List.generate(
        pageSize,
        (index) {
          final productIndex = startIndex + index;
          final priceChange = (_random.nextDouble() - 0.5) * 3;

          return Product(
            id: 'sale_$productIndex',
            name: '🔥 Sale ${_productNames[productIndex % _productNames.length]} #$productIndex',
            description: 'Updated: ${DateTime.now().toIso8601String().substring(11, 19)}',
            price: (9.99 + (productIndex % 20) * 2.0 + priceChange).clamp(5.0, 100.0),
            category: _categories[productIndex % _categories.length],
            imageUrl: 'https://picsum.photos/200/200?random=${productIndex + 3000}',
            createdAt: DateTime.now().subtract(Duration(days: productIndex)),
          );
        },
      );
    }
  }
}
