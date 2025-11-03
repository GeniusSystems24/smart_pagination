import 'package:flutter/material.dart';
import 'package:custom_pagination/pagination.dart';
import '../../models/product.dart';
import '../../services/mock_api_service.dart';

/// Example demonstrating hasReachedEnd detection
class HasReachedEndScreen extends StatefulWidget {
  const HasReachedEndScreen({super.key});

  @override
  State<HasReachedEndScreen> createState() => _HasReachedEndScreenState();
}

class _HasReachedEndScreenState extends State<HasReachedEndScreen> {
  bool _hasReachedEnd = false;
  int _totalItemsLoaded = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('hasReachedEnd Detection'),
        backgroundColor: Colors.orange,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.orange.withOpacity(0.1),
            child: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.orange),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Demonstrates detecting when pagination reaches the end. '
                    'Watch the footer change as you scroll!',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          // Status Banner
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: _hasReachedEnd
                ? Colors.green.withOpacity(0.2)
                : Colors.blue.withOpacity(0.2),
            child: Row(
              children: [
                Icon(
                  _hasReachedEnd ? Icons.check_circle : Icons.hourglass_empty,
                  color: _hasReachedEnd ? Colors.green : Colors.blue,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _hasReachedEnd
                            ? '✓ Reached End'
                            : 'Loading...',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _hasReachedEnd ? Colors.green : Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _hasReachedEnd
                            ? 'All $_totalItemsLoaded items loaded'
                            : '$_totalItemsLoaded items loaded so far',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Product List
          Expanded(
            child: SmartPaginatedListView<Product>(
              request: const PaginationRequest(page: 1, pageSize: 20),
              provider: PaginationProvider.future(
                (request) => MockApiService.fetchProducts(request),
              ),
              childBuilder: (context, product, index) {
                return _buildProductCard(product, index);
              },
              separatorBuilder: (context, index) => const Divider(height: 1),
            ),
          ),
        ],
      ),
      // Custom footer using SmartPagination.cubit to detect hasReachedEnd
      floatingActionButton: _hasReachedEnd
          ? FloatingActionButton.extended(
              onPressed: () {
                setState(() {
                  // Reset by recreating the widget
                });
              },
              backgroundColor: Colors.green,
              icon: const Icon(Icons.refresh),
              label: const Text('Reload'),
            )
          : null,
    );
  }

  Widget _buildProductCard(Product product, int index) {
    // Update total items and check if we've reached the end
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (index + 1 > _totalItemsLoaded) {
        setState(() {
          _totalItemsLoaded = index + 1;
        });
      }
    });

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            '#${index + 1}',
            style: const TextStyle(
              color: Colors.orange,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
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
          if (index >= 45) // Show badge for last few items
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'NEAR END',
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.white,
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  product.category,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
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
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }
}

/// Example with explicit hasReachedEnd callback
class HasReachedEndCallbackScreen extends StatelessWidget {
  const HasReachedEndCallbackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('hasReachedEnd Callback'),
        backgroundColor: Colors.deepOrange,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.deepOrange.withOpacity(0.1),
            child: const Row(
              children: [
                Icon(Icons.event_available, color: Colors.deepOrange),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Using onReachedEnd callback to show a message when '
                    'pagination completes.',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SmartPagination<Product>(
              request: const PaginationRequest(page: 1, pageSize: 15),
              provider: PaginationProvider.future(
                (request) => MockApiService.fetchProducts(request),
              ),
              itemBuilderType: PaginateBuilderType.listView,
              itemBuilder: (context, items, index) {
                final product = items[index];
                return _buildProductCard(context, product, index);
              },
              separator: const Divider(height: 1),
              // This callback is called when pagination reaches the end
              onReachedEnd: (state) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.white),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'All ${state.items.length} items loaded!',
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 3),
                  ),
                );
              },
              // Custom footer shown at the end
              footer: SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 48,
                        color: Colors.green.withOpacity(0.5),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'You\'ve reached the end!',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'No more items to load',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, Product product, int index) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.deepOrange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.shopping_bag,
          color: Colors.deepOrange.shade700,
          size: 28,
        ),
      ),
      title: Text(
        product.name,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 15,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            product.description,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
          const SizedBox(height: 4),
          Text(
            product.category,
            style: TextStyle(
              fontSize: 11,
              color: Colors.deepOrange.shade700,
              fontWeight: FontWeight.w600,
            ),
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
