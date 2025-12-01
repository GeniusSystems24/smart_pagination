import 'package:smart_pagination/pagination.dart';
import 'package:flutter/material.dart';
import '../../models/product.dart';

/// Graceful degradation example
///
/// Demonstrates:
/// - Showing limited functionality instead of complete failure
/// - Offline mode with reduced features
/// - Placeholder content when data unavailable
/// - Progressive enhancement strategies
class GracefulDegradationExample extends StatefulWidget {
  const GracefulDegradationExample({super.key});

  @override
  State<GracefulDegradationExample> createState() =>
      _GracefulDegradationExampleState();
}

class _GracefulDegradationExampleState
    extends State<GracefulDegradationExample>
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
        title: const Text('Graceful Degradation'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Offline Mode'),
            Tab(text: 'Placeholder Content'),
            Tab(text: 'Limited Features'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _OfflineModeTab(),
          _PlaceholderContentTab(),
          _LimitedFeaturesTab(),
        ],
      ),
    );
  }
}

// ========== Offline Mode Tab ==========
class _OfflineModeTab extends StatefulWidget {
  const _OfflineModeTab();

  @override
  State<_OfflineModeTab> createState() => _OfflineModeTabState();
}

class _OfflineModeTabState extends State<_OfflineModeTab> {
  bool _isOffline = true;

  // Offline data (previously synced)
  final List<Product> _offlineProducts = List.generate(8, (index) {
    return Product(
      id: 'offline_$index',
      name: 'Product #$index',
      description: 'Last synced 2 hours ago',
      price: 19.99 + index,
      category: 'Electronics',
      imageUrl: 'https://picsum.photos/200/200?random=$index',
      createdAt: DateTime.now().subtract(Duration(hours: 2)),
    );
  });

  Future<List<Product>> _fetchProducts(PaginationRequest request) async {
    await Future.delayed(const Duration(milliseconds: 800));

    if (_isOffline) {
      throw Exception('No internet connection');
    }

    return List.generate(20, (index) {
      return Product(
        id: 'online_$index',
        name: 'Fresh Product #$index',
        description: 'Latest from server',
        price: 29.99 + index,
        category: 'Electronics',
        imageUrl: 'https://picsum.photos/200/200?random=${index + 100}',
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
          color: _isOffline ? Colors.orange[100] : Colors.green[100],
          child: Row(
            children: [
              Icon(
                _isOffline ? Icons.cloud_off : Icons.cloud_done,
                color: _isOffline ? Colors.orange : Colors.green,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isOffline ? 'Offline Mode' : 'Online Mode',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      _isOffline
                          ? 'Showing cached content. Some features limited.'
                          : 'Connected. All features available.',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              Switch(
                value: !_isOffline,
                onChanged: (value) {
                  setState(() {
                    _isOffline = !value;
                  });
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: _isOffline
              ? _buildOfflineView()
              : _buildOnlineView(),
        ),
      ],
    );
  }

  Widget _buildOfflineView() {
    return ListView.builder(
      itemCount: _offlineProducts.length + 1,
      itemBuilder: (context, index) {
        if (index == _offlineProducts.length) {
          return Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
                const SizedBox(height: 8),
                const Text(
                  'End of Offline Content',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Connect to internet to load more',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          );
        }

        final product = _offlineProducts[index];
        return ListTile(
          leading: Stack(
            children: [
              const CircleAvatar(
                child: Icon(Icons.shopping_bag),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.offline_pin,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          title: Text(product.name),
          subtitle: Text(product.description),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${product.price.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text(
                'Cached',
                style: TextStyle(fontSize: 10, color: Colors.orange),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOnlineView() {
    return SmartPagination<Product>.listViewWithProvider(
      key: const Key('online_mode'),
      request: PaginationRequest(page: 1, pageSize: 20),
      provider: PaginationProvider.future(_fetchProducts),
      itemBuilder: (context, products, index) {
        final product = products[index];
        return ListTile(
          leading: const CircleAvatar(
            backgroundColor: Colors.green,
            child: Icon(Icons.cloud_done, color: Colors.white),
          ),
          title: Text(product.name),
          subtitle: Text(product.description),
          trailing: Text(
            '\$${product.price.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        );
      },
    );
  }
}

// ========== Placeholder Content Tab ==========
class _PlaceholderContentTab extends StatelessWidget {
  const _PlaceholderContentTab();

  Future<List<Product>> _fetchProducts(PaginationRequest request) async {
    await Future.delayed(const Duration(milliseconds: 800));
    throw Exception('Unable to load product data');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.purple[50],
          child: const Text(
            'Placeholder Content Strategy\n'
            'Show skeleton/placeholder UI instead of blank error screen.',
            style: TextStyle(fontSize: 13),
          ),
        ),
        Expanded(
          child: SmartPagination<Product>.listViewWithProvider(
            request: PaginationRequest(page: 1, pageSize: 20),
            provider: PaginationProvider.future(_fetchProducts),
            itemBuilder: (context, products, index) {
              final product = products[index];
              return ListTile(title: Text(product.name));
            },
            firstPageErrorBuilder: (context, error, retry) {
              return ListView.builder(
                itemCount: 10,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    // Error banner at top
                    return Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.orange),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Unable to load real data. Showing placeholders.',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.refresh),
                            onPressed: retry,
                          ),
                        ],
                      ),
                    );
                  }

                  // Placeholder items with shimmer effect
                  return ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        shape: BoxShape.circle,
                      ),
                    ),
                    title: Container(
                      height: 16,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    subtitle: Container(
                      height: 12,
                      width: 200,
                      margin: const EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    trailing: Container(
                      width: 60,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// ========== Limited Features Tab ==========
class _LimitedFeaturesTab extends StatefulWidget {
  const _LimitedFeaturesTab();

  @override
  State<_LimitedFeaturesTab> createState() => _LimitedFeaturesTabState();
}

class _LimitedFeaturesTabState extends State<_LimitedFeaturesTab> {
  bool _hasError = true;

  // Basic product list available even during errors
  final List<Product> _basicProducts = List.generate(12, (index) {
    return Product(
      id: 'basic_$index',
      name: 'Product #$index',
      description: 'Basic info available',
      price: 19.99 + index,
      category: 'Electronics',
      imageUrl: '',  // No images during error
      createdAt: DateTime.now(),
    );
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.amber[50],
          child: Row(
            children: [
              Icon(
                _hasError ? Icons.warning_amber : Icons.check_circle,
                color: _hasError ? Colors.amber : Colors.green,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _hasError
                      ? 'Limited Mode: Basic features only'
                      : 'Full Mode: All features enabled',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Switch(
                value: !_hasError,
                onChanged: (value) {
                  setState(() {
                    _hasError = !value;
                  });
                },
              ),
            ],
          ),
        ),
        if (_hasError)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.amber[100],
            child: Row(
              children: const [
                Icon(Icons.info_outline, size: 16, color: Colors.amber),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Some features disabled: Images, Reviews, Add to Cart',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: ListView.builder(
            itemCount: _basicProducts.length,
            itemBuilder: (context, index) {
              final product = _basicProducts[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      // Product image (disabled during error)
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: _hasError ? Colors.grey[300] : Colors.blue[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _hasError ? Icons.image_not_supported : Icons.image,
                          color: _hasError ? Colors.grey : Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Product info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '\$${product.price.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (_hasError)
                              const Padding(
                                padding: EdgeInsets.only(top: 4),
                                child: Text(
                                  'Reviews unavailable',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      // Action button (disabled during error)
                      ElevatedButton.icon(
                        onPressed: _hasError ? null : () {},
                        icon: Icon(_hasError ? Icons.block : Icons.shopping_cart),
                        label: Text(_hasError ? 'Unavailable' : 'Add'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _hasError ? Colors.grey : null,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
