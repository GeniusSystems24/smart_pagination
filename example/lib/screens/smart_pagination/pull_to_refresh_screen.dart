import 'package:flutter/material.dart';
import 'package:custom_pagination/pagination.dart';
import '../../models/product.dart';
import '../../services/mock_api_service.dart';

/// Example of pull-to-refresh functionality
class PullToRefreshScreen extends StatelessWidget {
  const PullToRefreshScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pull to Refresh'),
        backgroundColor: Colors.amber,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.amber.withOpacity(0.2),
            child: const Row(
              children: [
                Icon(Icons.refresh, color: Colors.amber),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Pull down from the top to refresh the list. '
                    'This will reload the data from the beginning.',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                // This will be handled by the cubit's refresh method
                // For now, we'll show the pull-to-refresh UI
                await Future.delayed(const Duration(milliseconds: 500));
              },
              child: SmartPaginatedListView<Product>(
                request: const PaginationRequest(page: 1, pageSize: 15),
                provider: PaginationProvider.future(
                  (request) => MockApiService.fetchProducts(request),
                ),
                childBuilder: (context, product, index) {
                  return _buildProductCard(product, index);
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
                      SizedBox(height: 8),
                      Text(
                        'Pull down to refresh',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                );
              },
              bottomLoadingBuilder: (context) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Colors.amber),
                      SizedBox(height: 16),
                      Text(
                        'Loading products...',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                );
              },
            ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Product product, int index) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.amber.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          children: [
            Center(
              child: Icon(
                Icons.shopping_bag,
                color: Colors.amber.shade700,
                size: 28,
              ),
            ),
            if (index < 3)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Text(
                    'NEW',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 6,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              product.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              product.category,
              style: TextStyle(
                fontSize: 11,
                color: Colors.amber.shade900,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
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
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.refresh, size: 12, color: Colors.amber.shade700),
              const SizedBox(width: 4),
              Text(
                'Pull to refresh anytime',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.amber.shade700,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '\$${product.price.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 4),
          Icon(
            Icons.add_shopping_cart,
            size: 16,
            color: Colors.grey[400],
          ),
        ],
      ),
    );
  }
}
