# Advanced Examples

Complex pagination scenarios and advanced features.

## Table of Contents

- [Cursor Pagination](#cursor-pagination)
- [Horizontal Scroll](#horizontal-scroll)
- [PageView](#pageview)
- [Staggered Grid](#staggered-grid)
- [Custom States](#custom-states)
- [Scroll Control](#scroll-control)
- [beforeBuild Hook](#beforebuild-hook)
- [hasReachedEnd](#hasreachedend)
- [Custom View Builder](#custom-view-builder)
- [Reorderable List](#reorderable-list)
- [State Separation](#state-separation)
- [Smart Preloading](#smart-preloading)
- [Data Operations](#data-operations)
- [Data Age & Expiration](#data-age--expiration)
- [Sorting](#sorting)

---

## Cursor Pagination

Cursor-based pagination for real-time data:

```dart
class CursorPaginationScreen extends StatelessWidget {
  Future<List<Post>> fetchPosts(PaginationRequest request) async {
    final response = await api.getPosts(
      cursor: request.cursor,
      limit: request.pageSize ?? 20,
    );

    // Update cursor for next page
    request.cursor = response.nextCursor;
    request.hasMore = response.hasMore;

    return response.posts;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cursor Pagination')),
      body: SmartPagination.listViewWithProvider<Post>(
        request: PaginationRequest(
          page: 1,
          pageSize: 20,
          cursor: null,
        ),
        provider: PaginationProvider.future(fetchPosts),
        useCursorPagination: true,
        itemBuilder: (context, items, index) {
          final post = items[index];
          return ListTile(
            title: Text(post.title),
            subtitle: Text(post.content),
          );
        },
      ),
    );
  }
}
```

---

## Horizontal Scroll

Horizontal scrolling with pagination:

```dart
class HorizontalListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Horizontal Scroll')),
      body: SizedBox(
        height: 200,
        child: SmartPagination.listViewWithProvider<Movie>(
          request: const PaginationRequest(page: 1, pageSize: 10),
          provider: PaginationProvider.future(fetchMovies),
          scrollDirection: Axis.horizontal,
          itemBuilder: (context, items, index) {
            final movie = items[index];
            return Container(
              width: 140,
              margin: const EdgeInsets.all(8),
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Image.network(
                        movie.posterUrl,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        movie.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12),
                      ),
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

## PageView

Swipeable pages with auto pagination:

```dart
class PageViewScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Article Reader')),
      body: SmartPagination.pageViewWithProvider<Article>(
        request: const PaginationRequest(page: 1, pageSize: 1),
        provider: PaginationProvider.future(fetchArticles),
        onPageChanged: (index) {
          print('Reading article $index');
        },
        itemBuilder: (context, items, index) {
          final article = items[index];
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (article.imageUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      article.imageUrl!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                const SizedBox(height: 16),
                Text(
                  article.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'By ${article.author} • ${article.readTime} min read',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const Divider(height: 32),
                Text(
                  article.content,
                  style: const TextStyle(fontSize: 16, height: 1.6),
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

## Staggered Grid

Pinterest-like masonry layout:

```dart
class StaggeredGridScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Staggered Grid')),
      body: SmartPagination.staggeredGridViewWithProvider<Photo>(
        request: const PaginationRequest(page: 1, pageSize: 20),
        provider: PaginationProvider.future(fetchPhotos),
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        padding: const EdgeInsets.all(8),
        staggeredTileBuilder: (index) {
          // Varying heights for masonry effect
          return StaggeredTile.count(1, index.isEven ? 1.5 : 1.0);
        },
        itemBuilder: (context, items, index) {
          final photo = items[index];
          return Card(
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  photo.url,
                  fit: BoxFit.cover,
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Colors.black54, Colors.transparent],
                      ),
                    ),
                    child: Text(
                      photo.title,
                      style: const TextStyle(color: Colors.white),
                    ),
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

## Custom States

Custom loading, empty, and error states:

```dart
class CustomStatesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Custom States')),
      body: SmartPagination.listViewWithProvider<Product>(
        request: const PaginationRequest(page: 1, pageSize: 20),
        provider: PaginationProvider.future(fetchProducts),
        // Custom loading widget
        loadingWidget: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(strokeWidth: 2),
              SizedBox(height: 16),
              Text('Loading products...'),
            ],
          ),
        ),
        // Custom empty widget
        emptyWidget: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inbox, size: 80, color: Colors.grey[300]),
              const SizedBox(height: 16),
              const Text(
                'No products found',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Try adjusting your filters',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        // Custom error widget
        onError: (error) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cloud_off, size: 80, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Connection Error',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        // Custom load more widget
        loadMoreWidget: Container(
          padding: const EdgeInsets.all(16),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text('Loading more...'),
            ],
          ),
        ),
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

## Scroll Control

Programmatic scrolling to items:

```dart
class ScrollControlScreen extends StatefulWidget {
  @override
  State<ScrollControlScreen> createState() => _ScrollControlScreenState();
}

class _ScrollControlScreenState extends State<ScrollControlScreen> {
  final ScrollController _scrollController = ScrollController();
  late final SmartPaginationCubit<Product> _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = SmartPaginationCubit<Product>(
      request: const PaginationRequest(page: 1, pageSize: 50),
      provider: PaginationProvider.future(fetchProducts),
    );
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
    );
  }

  void _scrollToIndex(int index) {
    final itemHeight = 72.0; // Approximate item height
    _scrollController.animateTo(
      index * itemHeight,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scroll Control'),
        actions: [
          IconButton(
            icon: const Icon(Icons.vertical_align_top),
            onPressed: _scrollToTop,
            tooltip: 'Scroll to top',
          ),
        ],
      ),
      body: SmartPagination.withCubit(
        cubit: _cubit,
        scrollController: _scrollController,
        itemBuilderType: PaginateBuilderType.listView,
        itemBuilder: (context, items, index) {
          final product = items[index];
          return ListTile(
            leading: CircleAvatar(child: Text('${index + 1}')),
            title: Text(product.name),
            subtitle: Text('\$${product.price}'),
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'top',
            onPressed: _scrollToTop,
            child: const Icon(Icons.arrow_upward),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.small(
            heroTag: 'middle',
            onPressed: () => _scrollToIndex(25),
            child: const Icon(Icons.unfold_less),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.small(
            heroTag: 'bottom',
            onPressed: () => _scrollToIndex(49),
            child: const Icon(Icons.arrow_downward),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _cubit.dispose();
    super.dispose();
  }
}
```

---

## beforeBuild Hook

Execute logic before rendering:

```dart
class BeforeBuildHookScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('beforeBuild Hook')),
      body: SmartPagination.listViewWithProvider<Product>(
        request: const PaginationRequest(page: 1, pageSize: 20),
        provider: PaginationProvider.future(fetchProducts),
        beforeBuild: (items) {
          // Sort items by price before rendering
          items.sort((a, b) => a.price.compareTo(b.price));

          // Log analytics
          Analytics.logEvent('products_loaded', {'count': items.length});

          // Transform or filter items
          return items.where((p) => p.isAvailable).toList();
        },
        itemBuilder: (context, items, index) {
          final product = items[index];
          return ListTile(
            title: Text(product.name),
            subtitle: Text('\$${product.price.toStringAsFixed(2)}'),
          );
        },
      ),
    );
  }
}
```

---

## hasReachedEnd

Detect when pagination ends:

```dart
class HasReachedEndScreen extends StatefulWidget {
  @override
  State<HasReachedEndScreen> createState() => _HasReachedEndScreenState();
}

class _HasReachedEndScreenState extends State<HasReachedEndScreen> {
  bool _hasReachedEnd = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('hasReachedEnd'),
        actions: [
          if (_hasReachedEnd)
            const Chip(
              label: Text('All loaded'),
              backgroundColor: Colors.green,
            ),
        ],
      ),
      body: SmartPagination.listViewWithProvider<Product>(
        request: const PaginationRequest(page: 1, pageSize: 20),
        provider: PaginationProvider.future(fetchProducts),
        onReachedEnd: () {
          setState(() => _hasReachedEnd = true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You have reached the end!'),
              duration: Duration(seconds: 2),
            ),
          );
        },
        endOfListWidget: Container(
          padding: const EdgeInsets.all(16),
          child: const Column(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 48),
              SizedBox(height: 8),
              Text('You\'ve seen all items!'),
            ],
          ),
        ),
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

## Data Operations

Add, remove, update, clear items:

```dart
class DataOperationsScreen extends StatefulWidget {
  @override
  State<DataOperationsScreen> createState() => _DataOperationsScreenState();
}

class _DataOperationsScreenState extends State<DataOperationsScreen> {
  late final SmartPaginationCubit<Product> _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = SmartPaginationCubit<Product>(
      request: const PaginationRequest(page: 1, pageSize: 20),
      provider: PaginationProvider.future(fetchProducts),
    );
  }

  void _addItem() {
    final newProduct = Product(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: 'New Product ${DateTime.now().second}',
      price: 99.99,
    );
    _cubit.addItem(newProduct, insertFirst: true);
  }

  void _removeItem(Product product) {
    _cubit.removeItem(product);
  }

  void _updateItem(Product product) {
    final updated = product.copyWith(
      price: product.price + 10,
      name: '${product.name} (Updated)',
    );
    _cubit.updateItem(product, updated);
  }

  void _clearAll() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All?'),
        content: const Text('This will remove all items from the list.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _cubit.clearItems();
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Operations'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _addItem),
          IconButton(icon: const Icon(Icons.delete_sweep), onPressed: _clearAll),
        ],
      ),
      body: SmartPagination.withCubit(
        cubit: _cubit,
        itemBuilderType: PaginateBuilderType.listView,
        itemBuilder: (context, items, index) {
          final product = items[index];
          return Dismissible(
            key: ValueKey(product.id),
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 16),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            direction: DismissDirection.endToStart,
            onDismissed: (_) => _removeItem(product),
            child: ListTile(
              title: Text(product.name),
              subtitle: Text('\$${product.price.toStringAsFixed(2)}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _updateItem(product),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _removeItem(product),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _cubit.dispose();
    super.dispose();
  }
}
```

---

## Data Age & Expiration

Auto-refresh data after expiration:

```dart
class DataAgeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Data Age & Expiration')),
      body: SmartPagination.listViewWithProvider<Product>(
        request: const PaginationRequest(page: 1, pageSize: 20),
        provider: PaginationProvider.future(fetchProducts),
        // Data expires after 30 seconds
        dataExpirationDuration: const Duration(seconds: 30),
        // Check every 10 seconds
        dataExpirationCheckInterval: const Duration(seconds: 10),
        // Show data age in header
        headerBuilder: (context, dataAge) {
          return Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue[50],
            child: Row(
              children: [
                const Icon(Icons.access_time, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Last updated: ${formatDuration(dataAge)} ago',
                  style: TextStyle(color: Colors.blue[700]),
                ),
              ],
            ),
          );
        },
        // Callback when data expires
        onDataExpired: () {
          print('Data has expired, auto-refreshing...');
        },
        itemBuilder: (context, items, index) {
          final product = items[index];
          return ListTile(
            title: Text(product.name),
            subtitle: Text('\$${product.price.toStringAsFixed(2)}'),
          );
        },
      ),
    );
  }

  String formatDuration(Duration duration) {
    if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    }
    return '${duration.inSeconds}s';
  }
}
```

---

## Sorting

Programmatic sorting with multiple orders:

```dart
class SortingScreen extends StatefulWidget {
  @override
  State<SortingScreen> createState() => _SortingScreenState();
}

class _SortingScreenState extends State<SortingScreen> {
  final _sortListener = SmartPaginationSortChangeListener<Product>();
  String _currentSort = 'name';
  bool _ascending = true;

  void _onSortChanged(String field) {
    if (_currentSort == field) {
      _ascending = !_ascending;
    } else {
      _currentSort = field;
      _ascending = true;
    }
    setState(() {});

    _sortListener.comparator = (a, b) {
      int result;
      switch (field) {
        case 'name':
          result = a.name.compareTo(b.name);
          break;
        case 'price':
          result = a.price.compareTo(b.price);
          break;
        case 'rating':
          result = a.rating.compareTo(b.rating);
          break;
        default:
          result = 0;
      }
      return _ascending ? result : -result;
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sorting'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                _buildSortChip('name', 'Name'),
                const SizedBox(width: 8),
                _buildSortChip('price', 'Price'),
                const SizedBox(width: 8),
                _buildSortChip('rating', 'Rating'),
              ],
            ),
          ),
        ),
      ),
      body: SmartPagination.listViewWithProvider<Product>(
        request: const PaginationRequest(page: 1, pageSize: 20),
        provider: PaginationProvider.future(fetchProducts),
        sortListener: _sortListener,
        itemBuilder: (context, items, index) {
          final product = items[index];
          return ListTile(
            title: Text(product.name),
            subtitle: Row(
              children: [
                Text('\$${product.price.toStringAsFixed(2)}'),
                const SizedBox(width: 16),
                Icon(Icons.star, size: 16, color: Colors.amber),
                Text(' ${product.rating}'),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSortChip(String field, String label) {
    final isSelected = _currentSort == field;
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (isSelected)
            Icon(
              _ascending ? Icons.arrow_upward : Icons.arrow_downward,
              size: 16,
            ),
        ],
      ),
      selected: isSelected,
      onSelected: (_) => _onSortChanged(field),
    );
  }

  @override
  void dispose() {
    _sortListener.dispose();
    super.dispose();
  }
}
```

---

[Back to Examples](../example.md)
