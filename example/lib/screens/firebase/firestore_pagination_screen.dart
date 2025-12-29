import 'dart:async';
import 'package:flutter/material.dart';
import 'package:smart_pagination/pagination.dart';

/// Mock Product for Firestore example
class FirestoreProduct {
  final String id;
  final String name;
  final double price;
  final String imageUrl;
  final DateTime createdAt;

  FirestoreProduct({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.createdAt,
  });
}

/// Simulates Firestore pagination with cursor-based queries
class FirestorePaginationScreen extends StatefulWidget {
  const FirestorePaginationScreen({super.key});

  @override
  State<FirestorePaginationScreen> createState() =>
      _FirestorePaginationScreenState();
}

class _FirestorePaginationScreenState extends State<FirestorePaginationScreen> {
  // Simulated Firestore data
  final List<FirestoreProduct> _allProducts = List.generate(
    100,
    (index) => FirestoreProduct(
      id: 'product_$index',
      name: 'Product ${index + 1}',
      price: 10.0 + (index * 5.99),
      imageUrl: 'https://picsum.photos/seed/$index/100/100',
      createdAt: DateTime.now().subtract(Duration(hours: index)),
    ),
  );

  /// Simulates Firestore cursor-based pagination
  Future<List<FirestoreProduct>> fetchProducts(
      PaginationRequest request) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    final pageSize = request.pageSize ?? 20;
    final page = request.page;

    // Calculate pagination indices (simulating startAfterDocument)
    final startIndex = (page - 1) * pageSize;
    final endIndex = (startIndex + pageSize).clamp(0, _allProducts.length);

    if (startIndex >= _allProducts.length) {
      return [];
    }

    return _allProducts.sublist(startIndex, endIndex);
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firestore Pagination'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Info banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Colors.blue.shade50,
            child: Row(
              children: [
                Icon(Icons.cloud, color: Colors.blue.shade700, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Simulated Firestore with cursor-based pagination',
                    style: TextStyle(color: Colors.blue.shade700, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),

          // Product list
          Expanded(
            child: SmartPagination<FirestoreProduct>.listViewWithProvider(
              request: const PaginationRequest(page: 1, pageSize: 20),
              provider: PaginationProvider.future(fetchProducts),
              itemBuilder: (context, items, index) {
                final product = items[index];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        product.imageUrl,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 50,
                          height: 50,
                          color: Colors.grey.shade200,
                          child: Icon(Icons.image, color: Colors.grey.shade400),
                        ),
                      ),
                    ),
                    title: Text(product.name),
                    subtitle: Text(
                      '\$${product.price.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing: Text(
                      _timeAgo(product.createdAt),
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                  ),
                );
              },
              loadingWidget: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading from Firestore...'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Firestore Pagination'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('This example demonstrates:'),
            SizedBox(height: 12),
            Text('• Cursor-based pagination'),
            Text('• startAfterDocument() simulation'),
            Text('• Efficient large dataset handling'),
            Text('• Real-time ready architecture'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
