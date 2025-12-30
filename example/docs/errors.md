# Error Handling Examples

Error handling patterns and best practices.

## Table of Contents

- [Basic Error Handling](#basic-error-handling)
- [Network Errors](#network-errors)
- [Retry Patterns](#retry-patterns)
- [Custom Error Widgets](#custom-error-widgets)
- [Error Recovery](#error-recovery)
- [Graceful Degradation](#graceful-degradation)
- [Load More Errors](#load-more-errors)

---

## Basic Error Handling

Simple error display with retry:

```dart
class BasicErrorExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Basic Error Handling')),
      body: SmartPagination.listViewWithProvider<Product>(
        request: const PaginationRequest(page: 1, pageSize: 20),
        provider: PaginationProvider.future(fetchProducts),
        onError: (error) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red[300],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Oops! Something went wrong',
                    style: TextStyle(
                      fontSize: 18,
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
                      // Trigger refresh
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try Again'),
                  ),
                ],
              ),
            ),
          );
        },
        itemBuilder: (context, items, index) {
          final product = items[index];
          return ListTile(
            title: Text(product.name),
            subtitle: Text('\$${product.price}'),
          );
        },
      ),
    );
  }
}
```

---

## Network Errors

Handle different types of network errors:

```dart
class NetworkErrorsExample extends StatelessWidget {
  Future<List<Product>> fetchWithErrorHandling(PaginationRequest request) async {
    try {
      final response = await http.get(
        Uri.parse('https://api.example.com/products?page=${request.page}'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['items'] as List)
            .map((item) => Product.fromJson(item))
            .toList();
      } else if (response.statusCode == 404) {
        throw NotFoundException('Products not found');
      } else if (response.statusCode == 500) {
        throw ServerException('Server error. Please try again later.');
      } else if (response.statusCode == 401) {
        throw AuthException('Please login to continue');
      } else {
        throw HttpException('HTTP ${response.statusCode}');
      }
    } on SocketException {
      throw NetworkException('No internet connection');
    } on TimeoutException {
      throw NetworkException('Connection timed out');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Network Errors')),
      body: SmartPagination.listViewWithProvider<Product>(
        request: const PaginationRequest(page: 1, pageSize: 20),
        provider: PaginationProvider.future(fetchWithErrorHandling),
        onError: (error) {
          IconData icon;
          String title;
          String message;
          Color color;

          if (error is NetworkException) {
            icon = Icons.wifi_off;
            title = 'No Connection';
            message = error.message;
            color = Colors.orange;
          } else if (error is NotFoundException) {
            icon = Icons.search_off;
            title = 'Not Found';
            message = error.message;
            color = Colors.blue;
          } else if (error is ServerException) {
            icon = Icons.cloud_off;
            title = 'Server Error';
            message = error.message;
            color = Colors.red;
          } else if (error is AuthException) {
            icon = Icons.lock;
            title = 'Authentication Required';
            message = error.message;
            color = Colors.purple;
          } else {
            icon = Icons.error_outline;
            title = 'Error';
            message = error.toString();
            color = Colors.grey;
          }

          return _buildErrorWidget(
            icon: icon,
            title: title,
            message: message,
            color: color,
          );
        },
        itemBuilder: (context, items, index) {
          final product = items[index];
          return ListTile(
            title: Text(product.name),
          );
        },
      ),
    );
  }

  Widget _buildErrorWidget({
    required IconData icon,
    required String title,
    required String message,
    required Color color,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 48, color: color),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
```

---

## Retry Patterns

Auto, exponential, and limited retries:

```dart
class RetryPatternsExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Retry Patterns'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Auto'),
              Tab(text: 'Exponential'),
              Tab(text: 'Limited'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Auto Retry (immediate)
            SmartPagination.listViewWithProvider<Product>(
              request: const PaginationRequest(page: 1, pageSize: 20),
              provider: PaginationProvider.future(fetchProducts),
              maxRetries: 3,
              retryDelay: const Duration(seconds: 1),
              onRetry: (attempt, error) {
                print('Auto retry #$attempt');
              },
              itemBuilder: (context, items, index) {
                return ListTile(title: Text(items[index].name));
              },
            ),

            // Exponential Backoff
            SmartPagination.listViewWithProvider<Product>(
              request: const PaginationRequest(page: 1, pageSize: 20),
              provider: PaginationProvider.future(fetchProducts),
              maxRetries: 5,
              retryDelay: const Duration(seconds: 1),
              useExponentialBackoff: true, // 1s, 2s, 4s, 8s, 16s
              onRetry: (attempt, error) {
                final delay = Duration(seconds: math.pow(2, attempt - 1).toInt());
                print('Exponential retry #$attempt after $delay');
              },
              itemBuilder: (context, items, index) {
                return ListTile(title: Text(items[index].name));
              },
            ),

            // Limited with UI feedback
            _LimitedRetryExample(),
          ],
        ),
      ),
    );
  }
}

class _LimitedRetryExample extends StatefulWidget {
  @override
  State<_LimitedRetryExample> createState() => _LimitedRetryExampleState();
}

class _LimitedRetryExampleState extends State<_LimitedRetryExample> {
  int _retryCount = 0;
  final int _maxRetries = 3;

  @override
  Widget build(BuildContext context) {
    return SmartPagination.listViewWithProvider<Product>(
      request: const PaginationRequest(page: 1, pageSize: 20),
      provider: PaginationProvider.future(fetchProducts),
      maxRetries: _maxRetries,
      retryDelay: const Duration(seconds: 2),
      onRetry: (attempt, error) {
        setState(() => _retryCount = attempt);
      },
      headerBuilder: (context, _) {
        if (_retryCount > 0) {
          return Container(
            padding: const EdgeInsets.all(8),
            color: Colors.amber[100],
            child: Row(
              children: [
                const Icon(Icons.autorenew, size: 16),
                const SizedBox(width: 8),
                Text('Retry attempt $_retryCount/$_maxRetries'),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
      onError: (error) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Failed after $_maxRetries retries'),
              const SizedBox(height: 8),
              Text(error.toString()),
            ],
          ),
        );
      },
      itemBuilder: (context, items, index) {
        return ListTile(title: Text(items[index].name));
      },
    );
  }
}
```

---

## Custom Error Widgets

Pre-built error widget styles:

```dart
class CustomErrorWidgetsExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Error Widget Styles')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Minimal Style
          const Text('Minimal', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Card(
            child: SizedBox(
              height: 150,
              child: Center(
                child: TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.refresh),
                  label: const Text('Failed to load. Tap to retry'),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Card Style
          const Text('Card Style', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.error, color: Colors.red[400], size: 32),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Unable to load content',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Please check your connection',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {},
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Banner Style
          const Text('Banner Style', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red[50],
              border: Border.all(color: Colors.red[200]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.red[700]),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Error loading data',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red[700],
                        ),
                      ),
                      Text(
                        'Network connection failed',
                        style: TextStyle(color: Colors.red[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('RETRY'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Full Page Style
          const Text('Full Page Style', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            height: 300,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/error_illustration.png', height: 120),
                const SizedBox(height: 24),
                const Text(
                  'Something went wrong',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'We\'re working on fixing this. Please try again.',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton(
                      onPressed: () {},
                      child: const Text('Go Back'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {},
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## Error Recovery

Cached data and fallback strategies:

```dart
class ErrorRecoveryExample extends StatefulWidget {
  @override
  State<ErrorRecoveryExample> createState() => _ErrorRecoveryExampleState();
}

class _ErrorRecoveryExampleState extends State<ErrorRecoveryExample> {
  List<Product>? _cachedProducts;
  bool _isOffline = false;

  Future<List<Product>> fetchWithFallback(PaginationRequest request) async {
    try {
      final products = await fetchFromApi(request);
      // Cache successful response
      _cachedProducts = products;
      await saveToCache(products);
      setState(() => _isOffline = false);
      return products;
    } catch (e) {
      setState(() => _isOffline = true);

      // Try memory cache
      if (_cachedProducts != null) {
        return _cachedProducts!;
      }

      // Try disk cache
      final diskCache = await loadFromCache();
      if (diskCache != null) {
        return diskCache;
      }

      // No fallback available
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Error Recovery'),
        actions: [
          if (_isOffline)
            Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud_off, size: 16, color: Colors.white),
                  SizedBox(width: 4),
                  Text('Offline', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          if (_isOffline)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.orange[100],
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange[800]),
                  const SizedBox(width: 8),
                  Text(
                    'Showing cached data. Pull to refresh.',
                    style: TextStyle(color: Colors.orange[800]),
                  ),
                ],
              ),
            ),
          Expanded(
            child: SmartPagination.listViewWithProvider<Product>(
              request: const PaginationRequest(page: 1, pageSize: 20),
              provider: PaginationProvider.future(fetchWithFallback),
              itemBuilder: (context, items, index) {
                final product = items[index];
                return ListTile(
                  title: Text(product.name),
                  subtitle: Text('\$${product.price}'),
                  trailing: _isOffline
                      ? Icon(Icons.cached, color: Colors.grey[400])
                      : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## Graceful Degradation

Offline mode and placeholders:

```dart
class GracefulDegradationExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Graceful Degradation')),
      body: SmartPagination.listViewWithProvider<Product>(
        request: const PaginationRequest(page: 1, pageSize: 20),
        provider: PaginationProvider.future(fetchProducts),
        // Show skeleton while loading
        loadingWidget: _buildSkeletonList(),
        // Partial data with error banner
        partialErrorBuilder: (context, items, error, retry) {
          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                color: Colors.amber[100],
                child: Row(
                  children: [
                    const Icon(Icons.warning, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('Some items failed to load'),
                    ),
                    TextButton(
                      onPressed: retry,
                      child: const Text('RETRY'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(items[index].name),
                    );
                  },
                ),
              ),
            ],
          );
        },
        itemBuilder: (context, items, index) {
          final product = items[index];
          return ListTile(
            title: Text(product.name),
            subtitle: Text('\$${product.price}'),
          );
        },
      ),
    );
  }

  Widget _buildSkeletonList() {
    return ListView.builder(
      itemCount: 10,
      itemBuilder: (context, index) {
        return ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(20),
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
            width: 100,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      },
    );
  }
}
```

---

## Load More Errors

Handle errors when loading more pages:

```dart
class LoadMoreErrorsExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Load More Errors')),
      body: SmartPagination.listViewWithProvider<Product>(
        request: const PaginationRequest(page: 1, pageSize: 20),
        provider: PaginationProvider.future(fetchProducts),
        // Custom load more error widget
        loadMoreErrorWidget: (error, retry) {
          return Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, color: Colors.red[400], size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Failed to load more',
                      style: TextStyle(color: Colors.red[400]),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: retry,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Retry'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red[400],
                    side: BorderSide(color: Colors.red[400]!),
                  ),
                ),
              ],
            ),
          );
        },
        // Max retries for load more
        loadMoreMaxRetries: 2,
        onLoadMoreError: (error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error loading more: $error'),
              action: SnackBarAction(
                label: 'Retry',
                onPressed: () {},
              ),
            ),
          );
        },
        itemBuilder: (context, items, index) {
          final product = items[index];
          return ListTile(
            leading: CircleAvatar(child: Text('${index + 1}')),
            title: Text(product.name),
            subtitle: Text('\$${product.price}'),
          );
        },
      ),
    );
  }
}
```

---

[Back to Examples](../example.md)
