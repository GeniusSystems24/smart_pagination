import 'dart:math';
import 'package:custom_pagination/pagination.dart';
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
}
