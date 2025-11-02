import 'package:flutter/material.dart';
import 'package:custom_pagination/pagination.dart';
import '../../models/product.dart';
import '../../services/mock_api_service.dart';

/// Basic ListView example with pagination
class BasicListViewScreen extends StatelessWidget {
  const BasicListViewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Basic ListView')),
      body: SinglePaginatedListView<Product>(
        request: const PaginationRequest(page: 1, pageSize: 20),
        provider: PaginationProvider.future(
          (request) => MockApiService.fetchProducts(request),
        ),
        childBuilder: (context, product, index) {
          return _buildProductCard(product);
        },
        separatorBuilder: (context, index) => const Divider(height: 1),
        emptyBuilder: (context) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No products found',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          );
        },
        errorBuilder: (context, exception, retryCallback) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Error: $exception',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: retryCallback,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          );
        },
        initialLoadingBuilder: (context) {
          return const Center(child: CircularProgressIndicator());
        },
        bottomLoadingBuilder: (context) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        },
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          product.imageUrl,
          width: 60,
          height: 60,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: 60,
              height: 60,
              color: Colors.grey[300],
              child: const Icon(Icons.image_not_supported),
            );
          },
        ),
      ),
      title: Text(
        product.name,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            product.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  product.category,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.blue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      trailing: Text(
        '\$${product.price.toStringAsFixed(2)}',
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.green,
        ),
      ),
    );
  }
}
