import 'package:smart_pagination/pagination.dart';
import 'package:flutter/material.dart';
import '../../models/product.dart';

/// Error recovery strategies example
///
/// Demonstrates:
/// - Fallback to cached data
/// - Partial data display on error
/// - Alternative data sources
/// - User-initiated recovery
class ErrorRecoveryExample extends StatefulWidget {
  const ErrorRecoveryExample({super.key});

  @override
  State<ErrorRecoveryExample> createState() => _ErrorRecoveryExampleState();
}

class _ErrorRecoveryExampleState extends State<ErrorRecoveryExample>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
        title: const Text('Error Recovery Strategies'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Cached Data'),
            Tab(text: 'Partial Data'),
            Tab(text: 'Alternative Source'),
            Tab(text: 'User Recovery'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _CachedDataTab(),
          _PartialDataTab(),
          _AlternativeSourceTab(),
          _UserRecoveryTab(),
        ],
      ),
    );
  }
}

// ========== Cached Data Recovery ==========
class _CachedDataTab extends StatefulWidget {
  const _CachedDataTab();

  @override
  State<_CachedDataTab> createState() => _CachedDataTabState();
}

class _CachedDataTabState extends State<_CachedDataTab> {
  // Simulated cache
  List<Product> _cachedProducts = [];
  bool _hasCache = false;
  bool _shouldFail = true;

  @override
  void initState() {
    super.initState();
    // Pre-populate cache
    _cachedProducts = List.generate(10, (index) {
      return Product(
        id: 'cached_$index',
        name: 'Cached Product #$index',
        description: 'Loaded from local cache',
        price: 19.99 + index,
        category: 'Electronics',
        imageUrl: 'https://picsum.photos/200/200?random=$index',
        createdAt: DateTime.now().subtract(Duration(hours: index)),
      );
    });
    _hasCache = true;
  }

  Future<List<Product>> _fetchProducts(PaginationRequest request) async {
    await Future.delayed(const Duration(milliseconds: 800));

    if (_shouldFail) {
      throw Exception('Network error: Unable to fetch fresh data');
    }

    return List.generate(20, (index) {
      return Product(
        id: 'fresh_$index',
        name: 'Fresh Product #$index',
        description: 'Loaded from server',
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
          color: Colors.blue[50],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Cached Data Fallback',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'When fresh data fails to load, fall back to cached data.\n'
                'Cache status: ${_hasCache ? "✅ Available" : "❌ Empty"}\n'
                'Cached items: ${_cachedProducts.length}',
                style: const TextStyle(fontSize: 13),
              ),
            ],
          ),
        ),
        Expanded(
          child: _shouldFail && _hasCache
              ? _buildCachedDataView()
              : _buildNormalView(),
        ),
      ],
    );
  }

  Widget _buildCachedDataView() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          color: Colors.orange[100],
          child: Row(
            children: [
              const Icon(Icons.cached, color: Colors.orange, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Showing cached data from previous session',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _shouldFail = false;
                  });
                },
                child: const Text('Refresh'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _cachedProducts.length,
            itemBuilder: (context, index) {
              final product = _cachedProducts[index];
              return ListTile(
                leading: const Icon(Icons.storage, color: Colors.orange),
                title: Text(product.name),
                subtitle: Text(product.description),
                trailing: Text('\$${product.price.toStringAsFixed(2)}'),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNormalView() {
    return SmartPaginatedListView<Product>(
      key: ValueKey('cached_data_$_shouldFail'),
      request: PaginationRequest(page: 1, pageSize: 20),
      provider: PaginationProvider.future(_fetchProducts),
      childBuilder: (context, product, index) {
        return ListTile(
          leading: const Icon(Icons.cloud_done, color: Colors.green),
          title: Text(product.name),
          subtitle: Text(product.description),
          trailing: Text('\$${product.price.toStringAsFixed(2)}'),
        );
      },
      firstPageErrorBuilder: (context, error, retry) {
        // This shouldn't show since we handle errors with cache
        return const SizedBox.shrink();
      },
    );
  }
}

// ========== Partial Data Recovery ==========
class _PartialDataTab extends StatefulWidget {
  const _PartialDataTab();

  @override
  State<_PartialDataTab> createState() => _PartialDataTabState();
}

class _PartialDataTabState extends State<_PartialDataTab> {
  List<Product> _partialProducts = [];
  bool _hasPartialData = false;
  String? _errorMessage;

  Future<List<Product>> _fetchProducts(PaginationRequest request) async {
    await Future.delayed(const Duration(milliseconds: 800));

    // Simulate partial success: some data loaded before error
    _partialProducts = List.generate(5, (index) {
      return Product(
        id: 'partial_$index',
        name: 'Product #$index (Partial)',
        description: 'Loaded before connection failed',
        price: 19.99 + index,
        category: 'Electronics',
        imageUrl: 'https://picsum.photos/200/200?random=$index',
        createdAt: DateTime.now(),
      );
    });
    _hasPartialData = true;
    _errorMessage = 'Connection lost after loading 5 items';

    throw Exception(_errorMessage);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.green[50],
          child: const Text(
            'Partial Data Display\n'
            'Show whatever data was loaded before the error occurred.',
            style: TextStyle(fontSize: 13),
          ),
        ),
        Expanded(
          child: _hasPartialData
              ? _buildPartialDataView()
              : _buildLoadingView(),
        ),
      ],
    );
  }

  Widget _buildPartialDataView() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          color: Colors.orange[100],
          child: Row(
            children: [
              const Icon(Icons.warning_amber, color: Colors.orange, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Partial data: ${_partialProducts.length} items loaded\n$_errorMessage',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _partialProducts.length + 1,
            itemBuilder: (context, index) {
              if (index < _partialProducts.length) {
                final product = _partialProducts[index];
                return ListTile(
                  leading: const Icon(Icons.check_circle, color: Colors.green),
                  title: Text(product.name),
                  subtitle: Text(product.description),
                  trailing: Text('\$${product.price.toStringAsFixed(2)}'),
                );
              } else {
                // Show error at the end
                return CustomErrorBuilder.compact(
                  context: context,
                  error: Exception(_errorMessage),
                  onRetry: () {
                    setState(() {
                      _hasPartialData = false;
                      _errorMessage = null;
                    });
                  },
                  message: 'Failed to load more items',
                );
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingView() {
    return SmartPaginatedListView<Product>(
      key: const Key('partial_data_loading'),
      request: PaginationRequest(page: 1, pageSize: 20),
      provider: PaginationProvider.future(_fetchProducts),
      childBuilder: (context, product, index) {
        return ListTile(title: Text(product.name));
      },
    );
  }
}

// ========== Alternative Source Recovery ==========
class _AlternativeSourceTab extends StatefulWidget {
  const _AlternativeSourceTab();

  @override
  State<_AlternativeSourceTab> createState() => _AlternativeSourceTabState();
}

class _AlternativeSourceTabState extends State<_AlternativeSourceTab> {
  bool _usePrimarySource = true;

  Future<List<Product>> _fetchFromPrimary(PaginationRequest request) async {
    await Future.delayed(const Duration(milliseconds: 800));
    throw Exception('Primary server is unavailable');
  }

  Future<List<Product>> _fetchFromBackup(PaginationRequest request) async {
    await Future.delayed(const Duration(milliseconds: 1000));

    return List.generate(15, (index) {
      return Product(
        id: 'backup_$index',
        name: 'Product #$index (Backup Server)',
        description: 'Loaded from backup server',
        price: 19.99 + index,
        category: 'Electronics',
        imageUrl: 'https://picsum.photos/200/200?random=${index + 200}',
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
          color: Colors.purple[50],
          child: Text(
            'Alternative Data Source\n'
            'Switch to backup server when primary fails.\n'
            'Current source: ${_usePrimarySource ? "Primary (Will Fail)" : "Backup (Working)"}',
            style: const TextStyle(fontSize: 13),
          ),
        ),
        Expanded(
          child: SmartPaginatedListView<Product>(
            key: ValueKey('alt_source_$_usePrimarySource'),
            request: PaginationRequest(page: 1, pageSize: 20),
            provider: PaginationProvider.future(
              _usePrimarySource ? _fetchFromPrimary : _fetchFromBackup,
            ),
            childBuilder: (context, product, index) {
              return ListTile(
                leading: Icon(
                  _usePrimarySource ? Icons.cloud : Icons.backup,
                  color: _usePrimarySource ? Colors.blue : Colors.orange,
                ),
                title: Text(product.name),
                subtitle: Text(product.description),
                trailing: Text('\$${product.price.toStringAsFixed(2)}'),
              );
            },
            firstPageErrorBuilder: (context, error, retry) {
              return CustomErrorBuilder.material(
                context: context,
                error: error,
                onRetry: () {
                  setState(() {
                    _usePrimarySource = false;
                  });
                },
                title: 'Primary Server Unavailable',
                message: 'The main server is not responding. Switch to backup server?',
                retryButtonText: 'Use Backup Server',
                icon: Icons.swap_horiz,
                iconColor: Colors.orange,
              );
            },
          ),
        ),
      ],
    );
  }
}

// ========== User-Initiated Recovery ==========
class _UserRecoveryTab extends StatefulWidget {
  const _UserRecoveryTab();

  @override
  State<_UserRecoveryTab> createState() => _UserRecoveryTabState();
}

class _UserRecoveryTabState extends State<_UserRecoveryTab> {
  bool _requiresLogin = true;

  Future<List<Product>> _fetchProducts(PaginationRequest request) async {
    await Future.delayed(const Duration(milliseconds: 800));

    if (_requiresLogin) {
      throw Exception('Authentication required. Please log in to continue.');
    }

    return List.generate(20, (index) {
      return Product(
        id: 'product_$index',
        name: 'Secure Product #$index',
        description: 'Requires authentication',
        price: 49.99 + index,
        category: 'Premium',
        imageUrl: 'https://picsum.photos/200/200?random=$index',
        createdAt: DateTime.now(),
      );
    });
  }

  Future<void> _handleLogin() async {
    // Simulate login process
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Login'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            TextField(decoration: InputDecoration(labelText: 'Email')),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _requiresLogin = false;
              });
              Navigator.pop(context);
            },
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.red[50],
          child: Text(
            'User-Initiated Recovery\n'
            'Require user action to resolve error (e.g., login, permissions).\n'
            'Status: ${_requiresLogin ? "❌ Not Logged In" : "✅ Logged In"}',
            style: const TextStyle(fontSize: 13),
          ),
        ),
        Expanded(
          child: SmartPaginatedListView<Product>(
            key: ValueKey('user_recovery_$_requiresLogin'),
            request: PaginationRequest(page: 1, pageSize: 20),
            provider: PaginationProvider.future(_fetchProducts),
            childBuilder: (context, product, index) {
              return ListTile(
                leading: const Icon(Icons.lock_open, color: Colors.green),
                title: Text(product.name),
                subtitle: Text(product.description),
                trailing: Text('\$${product.price.toStringAsFixed(2)}'),
              );
            },
            firstPageErrorBuilder: (context, error, retry) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.lock_outline,
                        size: 64,
                        color: Colors.orange,
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Authentication Required',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        error.toString(),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () async {
                          await _handleLogin();
                          if (!_requiresLogin) {
                            retry();
                          }
                        },
                        icon: const Icon(Icons.login),
                        label: const Text('Login'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
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
