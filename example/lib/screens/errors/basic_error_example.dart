import 'package:smart_pagination/pagination.dart';
import 'package:flutter/material.dart';
import '../../models/product.dart';

/// Basic error handling example
///
/// Demonstrates:
/// - Default error display
/// - Simple retry functionality
/// - First page vs load more errors
class BasicErrorExample extends StatefulWidget {
  const BasicErrorExample({super.key});

  @override
  State<BasicErrorExample> createState() => _BasicErrorExampleState();
}

class _BasicErrorExampleState extends State<BasicErrorExample> {
  bool _shouldFail = true;
  int _retryCount = 0;

  Future<List<Product>> _fetchProducts(PaginationRequest request) async {
    await Future.delayed(const Duration(milliseconds: 800));

    if (_shouldFail) {
      throw Exception('Failed to fetch products. Please try again.');
    }

    // Return products if not failing
    final pageSize = request.pageSize ?? 20;
    final startIndex = (request.page - 1) * pageSize;

    return List.generate(
      pageSize,
      (index) {
        final productIndex = startIndex + index;
        return Product(
          id: 'product_$productIndex',
          name: 'Product #$productIndex',
          description: 'A great product',
          price: 19.99 + productIndex * 2.0,
          category: 'Electronics',
          imageUrl: 'https://picsum.photos/200/200?random=$productIndex',
          createdAt: DateTime.now(),
        );
      },
    );
  }

  void _handleRetry() {
    setState(() {
      _retryCount++;
      // Succeed after 2 retries
      if (_retryCount >= 2) {
        _shouldFail = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Basic Error Handling'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset Example',
            onPressed: () {
              setState(() {
                _shouldFail = true;
                _retryCount = 0;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Info banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.blue[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Basic Error Handling',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This example will fail on first load. Retry $_retryCount/2 times to succeed.',
                  style: TextStyle(color: Colors.grey[700]),
                ),
                const SizedBox(height: 4),
                Text(
                  'Status: ${_shouldFail ? "❌ Will Fail" : "✅ Will Succeed"}',
                  style: TextStyle(
                    color: _shouldFail ? Colors.red : Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Paginated list
          Expanded(
            child: SmartPagination<Product>.listViewWithProvider(
              key: ValueKey('basic_error_$_retryCount'),
              request: PaginationRequest(page: 1, pageSize: 20),
              provider: PaginationProvider.future(_fetchProducts),
              itemBuilder: (context, products, index) {
                final product = products[index];
                return ListTile(
                  leading: CircleAvatar(
                    child: Text('${index + 1}'),
                  ),
                  title: Text(product.name),
                  subtitle: Text('\$${product.price.toStringAsFixed(2)}'),
                  trailing: const Icon(Icons.chevron_right),
                );
              },

              // Use default error display with retry
              firstPageErrorBuilder: (context, error, retry) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Error Loading Products',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          error.toString(),
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () {
                            _handleRetry();
                            retry();
                          },
                          icon: const Icon(Icons.refresh),
                          label: Text('Retry ($_retryCount/2)'),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _shouldFail = false;
                              _retryCount = 2;
                            });
                          },
                          child: const Text('Skip to Success'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
