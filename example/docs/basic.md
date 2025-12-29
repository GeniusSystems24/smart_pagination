# Basic Examples

Core pagination patterns for common use cases.

## Table of Contents

- [Basic ListView](#basic-listview)
- [GridView](#gridview)
- [Column Layout](#column-layout)
- [Row Layout](#row-layout)
- [Pull to Refresh](#pull-to-refresh)
- [Filter & Search](#filter--search)
- [Retry Mechanism](#retry-mechanism)

---

## Basic ListView

Simple paginated ListView with products:

```dart
class BasicListViewScreen extends StatelessWidget {
  Future<List<Product>> fetchProducts(PaginationRequest request) async {
    final response = await http.get(
      Uri.parse(
        'https://api.example.com/products?page=${request.page}&limit=${request.pageSize}',
      ),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['items'] as List)
          .map((item) => Product.fromJson(item))
          .toList();
    }
    throw Exception('Failed to load products');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Products')),
      body: SmartPagination.listViewWithProvider<Product>(
        request: const PaginationRequest(page: 1, pageSize: 20),
        provider: PaginationProvider.future(fetchProducts),
        itemBuilder: (context, items, index) {
          final product = items[index];
          return ListTile(
            leading: Image.network(product.imageUrl, width: 50, height: 50),
            title: Text(product.name),
            subtitle: Text('\$${product.price.toStringAsFixed(2)}'),
            trailing: const Icon(Icons.arrow_forward_ios),
          );
        },
      ),
    );
  }
}
```

---

## GridView

Paginated GridView with product cards:

```dart
class GridViewScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Product Grid')),
      body: SmartPagination.gridViewWithProvider<Product>(
        request: const PaginationRequest(page: 1, pageSize: 20),
        provider: PaginationProvider.future(fetchProducts),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.75,
        ),
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, items, index) {
          final product = items[index];
          return Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child: Image.network(
                      product.imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '\$${product.price.toStringAsFixed(2)}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
```

---

## Column Layout

Non-scrollable column inside a scroll view:

```dart
class ColumnExampleScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Column Layout')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header section
            Container(
              height: 200,
              color: Colors.blue,
              child: const Center(
                child: Text(
                  'Header Section',
                  style: TextStyle(color: Colors.white, fontSize: 24),
                ),
              ),
            ),

            // Paginated content as Column
            SmartPagination.columnWithProvider<Product>(
              request: const PaginationRequest(page: 1, pageSize: 10),
              provider: PaginationProvider.future(fetchProducts),
              itemBuilder: (context, items, index) {
                final product = items[index];
                return ListTile(
                  title: Text(product.name),
                  subtitle: Text('\$${product.price.toStringAsFixed(2)}'),
                );
              },
            ),

            // Footer section
            Container(
              height: 100,
              color: Colors.grey[200],
              child: const Center(child: Text('Footer Section')),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## Row Layout

Non-scrollable row inside a horizontal scroll view:

```dart
class RowExampleScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Row Layout')),
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SmartPagination.rowWithProvider<Product>(
          request: const PaginationRequest(page: 1, pageSize: 10),
          provider: PaginationProvider.future(fetchProducts),
          itemBuilder: (context, items, index) {
            final product = items[index];
            return Container(
              width: 150,
              margin: const EdgeInsets.all(8),
              child: Card(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shopping_bag, size: 48, color: Colors.blue),
                    const SizedBox(height: 8),
                    Text(
                      product.name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
```

---

## Pull to Refresh

Swipe down to refresh content:

```dart
class PullToRefreshScreen extends StatefulWidget {
  @override
  State<PullToRefreshScreen> createState() => _PullToRefreshScreenState();
}

class _PullToRefreshScreenState extends State<PullToRefreshScreen> {
  final refreshListener = SmartPaginationRefreshedChangeListener();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pull to Refresh'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => refreshListener.refreshed = true,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          refreshListener.refreshed = true;
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: SmartPagination.listViewWithProvider<Product>(
          request: const PaginationRequest(page: 1, pageSize: 20),
          provider: PaginationProvider.future(fetchProducts),
          refreshListener: refreshListener,
          itemBuilder: (context, items, index) {
            final product = items[index];
            return ListTile(
              leading: CircleAvatar(child: Text('${index + 1}')),
              title: Text(product.name),
              subtitle: Text('\$${product.price.toStringAsFixed(2)}'),
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    refreshListener.dispose();
    super.dispose();
  }
}
```

---

## Filter & Search

Paginated list with filtering capabilities:

```dart
class FilterSearchScreen extends StatefulWidget {
  @override
  State<FilterSearchScreen> createState() => _FilterSearchScreenState();
}

class _FilterSearchScreenState extends State<FilterSearchScreen> {
  final filterListener = SmartPaginationFilterChangeListener<Product>();
  final searchController = TextEditingController();
  String _selectedCategory = 'All';

  void _onSearchChanged(String query) {
    if (query.isEmpty) {
      filterListener.searchTerm = null;
    } else {
      filterListener.searchTerm = (product) =>
          product.name.toLowerCase().contains(query.toLowerCase());
    }
  }

  void _onCategoryChanged(String category) {
    setState(() => _selectedCategory = category);
    if (category == 'All') {
      filterListener.filter = null;
    } else {
      filterListener.filter = (product) => product.category == category;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Filter & Search'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: 'Search products...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        searchController.clear();
                        _onSearchChanged('');
                      },
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: _onSearchChanged,
                ),
              ),
              // Category chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: ['All', 'Electronics', 'Clothing', 'Books']
                      .map((category) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(category),
                              selected: _selectedCategory == category,
                              onSelected: (_) => _onCategoryChanged(category),
                            ),
                          ))
                      .toList(),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      body: SmartPagination.listViewWithProvider<Product>(
        request: const PaginationRequest(page: 1, pageSize: 20),
        provider: PaginationProvider.future(fetchProducts),
        filterListeners: [filterListener],
        itemBuilder: (context, items, index) {
          final product = items[index];
          return ListTile(
            title: Text(product.name),
            subtitle: Text(product.category),
            trailing: Text('\$${product.price.toStringAsFixed(2)}'),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    filterListener.dispose();
    searchController.dispose();
    super.dispose();
  }
}
```

---

## Retry Mechanism

Auto-retry with exponential backoff:

```dart
class RetryDemoScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Retry Mechanism')),
      body: SmartPagination.listViewWithProvider<Product>(
        request: const PaginationRequest(page: 1, pageSize: 20),
        provider: PaginationProvider.future(fetchProducts),
        // Retry configuration
        maxRetries: 3,
        retryDelay: const Duration(seconds: 2),
        useExponentialBackoff: true,
        onRetry: (attempt, error) {
          print('Retry attempt $attempt after error: $error');
        },
        itemBuilder: (context, items, index) {
          final product = items[index];
          return ListTile(
            title: Text(product.name),
            subtitle: Text('\$${product.price.toStringAsFixed(2)}'),
          );
        },
        onError: (error) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Failed after 3 retries: $error'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // Trigger manual retry
                  },
                  child: const Text('Try Again'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
```

---

[Back to Examples](../example.md)
