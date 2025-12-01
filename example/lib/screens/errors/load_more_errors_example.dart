import 'package:smart_pagination/pagination.dart';
import 'package:flutter/material.dart';
import '../../models/product.dart';

/// Load more errors example
///
/// Demonstrates:
/// - First page success, second page error
/// - Different UI for load more errors vs first page errors
/// - Retry load more functionality
/// - Seamless error handling during pagination
class LoadMoreErrorsExample extends StatefulWidget {
  const LoadMoreErrorsExample({super.key});

  @override
  State<LoadMoreErrorsExample> createState() => _LoadMoreErrorsExampleState();
}

class _LoadMoreErrorsExampleState extends State<LoadMoreErrorsExample>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Load More Errors'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Compact Error'),
            Tab(text: 'Inline Retry'),
            Tab(text: 'Silent Failure'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _CompactErrorTab(),
          _InlineRetryTab(),
          _SilentFailureTab(),
        ],
      ),
    );
  }
}

// ========== Compact Error Tab ==========
class _CompactErrorTab extends StatefulWidget {
  const _CompactErrorTab();

  @override
  State<_CompactErrorTab> createState() => _CompactErrorTabState();
}

class _CompactErrorTabState extends State<_CompactErrorTab> {
  Future<List<Product>> _fetchProducts(PaginationRequest request) async {
    await Future.delayed(const Duration(milliseconds: 800));

    // First page succeeds
    if (request.page == 1) {
      return List.generate(20, (index) {
        return Product(
          id: 'product_$index',
          name: 'Product #$index',
          description: 'First page loaded successfully',
          price: 19.99 + index,
          category: 'Electronics',
          imageUrl: 'https://picsum.photos/200/200?random=$index',
          createdAt: DateTime.now(),
        );
      });
    }

    // Second page and beyond fail
    throw Exception('Failed to load page ${request.page}');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.blue[50],
          child: const Text(
            'Compact Load More Error\n'
            'Shows a compact error widget at the bottom when loading more items fails.',
            style: TextStyle(fontSize: 13),
          ),
        ),
        Expanded(
          child: SmartPagination<Product>.listViewWithProvider(
            request: PaginationRequest(page: 1, pageSize: 20),
            provider: PaginationProvider.future(_fetchProducts),
            itemBuilder: (context, products, index) {
              final product = products[index];
              return ListTile(
                leading: CircleAvatar(child: Text('${index + 1}')),
                title: Text(product.name),
                subtitle: Text(product.description),
                trailing: Text('\$${product.price.toStringAsFixed(2)}'),
              );
            },
            // First page error (won't show in this example)
            firstPageErrorBuilder: (context, error, retry) {
              return CustomErrorBuilder.material(
                context: context,
                error: error,
                onRetry: retry,
              );
            },
            // Load more error - compact style
            loadMoreErrorBuilder: (context, error, retry) {
              return CustomErrorBuilder.compact(
                context: context,
                error: error,
                onRetry: retry,
                message: 'Failed to load more items. Tap to retry.',
                backgroundColor: Colors.red[50],
                textColor: Colors.red[900],
              );
            },
          ),
        ),
      ],
    );
  }
}

// ========== Inline Retry Tab ==========
class _InlineRetryTab extends StatefulWidget {
  const _InlineRetryTab();

  @override
  State<_InlineRetryTab> createState() => _InlineRetryTabState();
}

class _InlineRetryTabState extends State<_InlineRetryTab> {
  int _loadMoreAttempts = 0;

  Future<List<Product>> _fetchProducts(PaginationRequest request) async {
    await Future.delayed(const Duration(milliseconds: 800));

    // First page succeeds
    if (request.page == 1) {
      return List.generate(15, (index) {
        return Product(
          id: 'product_$index',
          name: 'Product #$index',
          description: 'Scroll down to load more',
          price: 19.99 + index,
          category: 'Electronics',
          imageUrl: 'https://picsum.photos/200/200?random=$index',
          createdAt: DateTime.now(),
        );
      });
    }

    // Second page: fail first 2 attempts, then succeed
    _loadMoreAttempts++;
    if (_loadMoreAttempts < 3) {
      throw Exception('Network error (Attempt $_loadMoreAttempts/3)');
    }

    return List.generate(15, (index) {
      final productIndex = (request.page - 1) * 15 + index;
      return Product(
        id: 'product_$productIndex',
        name: 'Product #$productIndex',
        description: 'Loaded on attempt $_loadMoreAttempts',
        price: 19.99 + productIndex,
        category: 'Electronics',
        imageUrl: 'https://picsum.photos/200/200?random=$productIndex',
        createdAt: DateTime.now(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.green[50],
          child: Text(
            'Inline Retry Pattern\n'
            'Shows retry button inline with the list. Attempts: $_loadMoreAttempts',
            style: const TextStyle(fontSize: 13),
          ),
        ),
        Expanded(
          child: SmartPagination<Product>.listViewWithProvider(
            key: ValueKey('inline_retry_$_loadMoreAttempts'),
            request: PaginationRequest(page: 1, pageSize: 15),
            provider: PaginationProvider.future(_fetchProducts),
            itemBuilder: (context, products, index) {
              final product = products[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green,
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(product.name),
                  subtitle: Text(product.description),
                ),
              );
            },
            loadMoreErrorBuilder: (context, error, retry) {
              return Container(
                margin: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Divider(),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.orange),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Failed to load more (Attempt $_loadMoreAttempts/3)',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: retry,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try Loading More'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ========== Silent Failure Tab ==========
class _SilentFailureTab extends StatefulWidget {
  const _SilentFailureTab();

  @override
  State<_SilentFailureTab> createState() => _SilentFailureTabState();
}

class _SilentFailureTabState extends State<_SilentFailureTab> {
  bool _showErrorMessage = false;

  Future<List<Product>> _fetchProducts(PaginationRequest request) async {
    await Future.delayed(const Duration(milliseconds: 800));

    // First page succeeds
    if (request.page == 1) {
      return List.generate(20, (index) {
        return Product(
          id: 'product_$index',
          name: 'Product #$index',
          description: 'Successfully loaded',
          price: 19.99 + index,
          category: 'Electronics',
          imageUrl: 'https://picsum.photos/200/200?random=$index',
          createdAt: DateTime.now(),
        );
      });
    }

    // Second page fails silently
    setState(() {
      _showErrorMessage = true;
    });

    // Auto-hide error message after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showErrorMessage = false;
        });
      }
    });

    throw Exception('Unable to load more items');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.orange[50],
          child: const Text(
            'Silent Failure Pattern\n'
            'Shows a temporary message without blocking the UI. Error auto-dismisses.',
            style: TextStyle(fontSize: 13),
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              SmartPagination<Product>.listViewWithProvider(
                request: PaginationRequest(page: 1, pageSize: 20),
                provider: PaginationProvider.future(_fetchProducts),
                itemBuilder: (context, products, index) {
                  final product = products[index];
                  return ListTile(
                    leading: CircleAvatar(child: Text('${index + 1}')),
                    title: Text(product.name),
                    subtitle: Text(product.description),
                  );
                },
                // Silent error - minimal UI
                loadMoreErrorBuilder: (context, error, retry) {
                  return CustomErrorBuilder.minimal(
                    context: context,
                    error: error,
                    onRetry: retry,
                    message: 'Failed to load more',
                  );
                },
              ),

              // Temporary error message at top
              if (_showErrorMessage)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Material(
                    elevation: 4,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      color: Colors.orange[100],
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber, color: Colors.orange),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Unable to load more items. Pull to refresh.',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            onPressed: () {
                              setState(() {
                                _showErrorMessage = false;
                              });
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
