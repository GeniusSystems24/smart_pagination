# Smart Pagination Examples

This document provides comprehensive examples of using the Smart Pagination library v2.4.0.

## Table of Contents

- [Smart Pagination Examples](#smart-pagination-examples)
  - [Table of Contents](#table-of-contents)
  - [Getting Started](#getting-started)
  - [Project Structure](#project-structure)
  - [Navigation with go\_router](#navigation-with-go_router)
  - [1. Basic ListView Example](#1-basic-listview-example)
  - [2. GridView with Custom Styling](#2-gridview-with-custom-styling)
  - [3. Pull-to-Refresh](#3-pull-to-refresh)
  - [4. Stream Updates (Real-time)](#4-stream-updates-real-time)
  - [5. Cursor Pagination](#5-cursor-pagination)
  - [6. Smart Search Dropdown](#6-smart-search-dropdown)
  - [7. Multi-Select Search (v2.4.0)](#7-multi-select-search-v240)
  - [8. Search Theming](#8-search-theming)
  - [9. Keyboard Navigation](#9-keyboard-navigation)
  - [10. Custom Error Handling](#10-custom-error-handling)
  - [11. Data Operations](#11-data-operations)
  - [12. Data Age \& Expiration](#12-data-age--expiration)
  - [Running the Examples](#running-the-examples)
  - [Example Categories](#example-categories)

---

## Getting Started

Add the required dependencies to your `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  smart_pagination: ^2.4.0
  go_router: ^14.6.0  # For navigation
  intl: ^0.19.0       # For date formatting
```

Import the package:

```dart
import 'package:smart_pagination/pagination.dart';
```

---

## Project Structure

The example app is organized into categories:

```
example/
├── lib/
│   ├── main.dart                    # App entry point with go_router
│   ├── router/
│   │   └── app_router.dart          # Route configuration
│   ├── screens/
│   │   ├── home_screen.dart         # Category navigation
│   │   ├── smart_pagination/        # Pagination examples
│   │   │   ├── basic_listview_screen.dart
│   │   │   ├── gridview_screen.dart
│   │   │   ├── search_dropdown_screen.dart
│   │   │   ├── multi_select_search_screen.dart
│   │   │   └── ...
│   │   └── errors/                  # Error handling examples
│   │       ├── basic_error_example.dart
│   │       └── ...
│   ├── models/
│   │   └── product.dart
│   └── services/
│       └── mock_api_service.dart
└── pubspec.yaml
```

---

## Navigation with go_router

The example app uses `go_router` for declarative routing:

```dart
// lib/router/app_router.dart
import 'package:go_router/go_router.dart';

class AppRoutes {
  static const String home = '/';
  static const String basicListView = '/basic/list-view';
  static const String searchDropdown = '/search/dropdown';
  static const String multiSelectSearch = '/search/multi-select';
  // ... more routes
}

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.home,
  routes: [
    GoRoute(
      path: AppRoutes.home,
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: AppRoutes.basicListView,
      pageBuilder: (context, state) => CustomTransitionPage(
        child: const BasicListViewScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOutCubic,
            )),
            child: child,
          );
        },
      ),
    ),
    // ... more routes
  ],
);

// lib/main.dart
class _PaginationExampleAppState extends State<PaginationExampleApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: appRouter,
      title: 'Smart Pagination Examples',
      theme: ThemeData(
        useMaterial3: true,
        extensions: [SmartSearchTheme.light()],
      ),
      darkTheme: ThemeData.dark(useMaterial3: true).copyWith(
        extensions: [SmartSearchTheme.dark()],
      ),
    );
  }
}

// Navigate using context.push()
context.push(AppRoutes.searchDropdown);
```

---

## 1. Basic ListView Example

Simple pagination with a REST API:

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
          );
        },
      ),
    );
  }
}
```

---

## 2. GridView with Custom Styling

Display items in a grid layout:

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
                  child: Text(
                    product.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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

## 3. Pull-to-Refresh

Implement refresh functionality:

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
      appBar: AppBar(title: const Text('Pull to Refresh')),
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

## 4. Stream Updates (Real-time)

Use streams for real-time updates:

```dart
class SingleStreamScreen extends StatelessWidget {
  Stream<List<Message>> streamMessages(PaginationRequest request) {
    return FirebaseFirestore.instance
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(request.pageSize ?? 20)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Message.fromFirestore(doc))
            .toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Real-time Messages')),
      body: SmartPagination.listViewWithProvider<Message>(
        request: const PaginationRequest(page: 1, pageSize: 50),
        provider: PaginationProvider.stream(streamMessages),
        itemBuilder: (context, items, index) {
          final message = items[index];
          return ListTile(
            leading: CircleAvatar(child: Text(message.author[0])),
            title: Text(message.author),
            subtitle: Text(message.content),
          );
        },
      ),
    );
  }
}
```

---

## 5. Cursor Pagination

Cursor-based pagination for real-time data:

```dart
class CursorPaginationScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cursor Pagination')),
      body: SmartPagination.listViewWithProvider<Post>(
        request: const PaginationRequest(
          page: 1,
          pageSize: 20,
          cursor: null, // Initial cursor
        ),
        provider: PaginationProvider.future((request) async {
          final response = await api.fetchPosts(
            cursor: request.cursor,
            limit: request.pageSize,
          );
          // Update cursor for next page
          request.cursor = response.nextCursor;
          return response.posts;
        }),
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

## 6. Smart Search Dropdown

Search with auto-positioning overlay:

```dart
class SearchDropdownScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search Dropdown')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SmartSearchDropdown<Product>.withProvider(
              request: const PaginationRequest(page: 1, pageSize: 10),
              provider: PaginationProvider.future(
                (request) => MockApiService.searchProducts(
                  request.searchQuery ?? '',
                  pageSize: request.pageSize ?? 10,
                ),
              ),
              searchRequestBuilder: (query) => PaginationRequest(
                page: 1,
                pageSize: 10,
                searchQuery: query,
              ),
              searchConfig: const SmartSearchConfig(
                debounceDelay: Duration(milliseconds: 300),
                minSearchLength: 0,
                searchOnEmpty: true,
              ),
              overlayConfig: const SmartSearchOverlayConfig(
                maxHeight: 300,
                borderRadius: 12,
              ),
              showSelected: true,
              itemBuilder: (context, product) => ListTile(
                leading: CircleAvatar(
                  child: Text(product.name[0].toUpperCase()),
                ),
                title: Text(product.name),
                subtitle: Text('\$${product.price.toStringAsFixed(2)}'),
              ),
              onItemSelected: (product) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Selected: ${product.name}')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## 7. Multi-Select Search (v2.4.0)

Search and select multiple items:

```dart
class MultiSelectSearchScreen extends StatefulWidget {
  @override
  State<MultiSelectSearchScreen> createState() => _MultiSelectSearchScreenState();
}

class _MultiSelectSearchScreenState extends State<MultiSelectSearchScreen> {
  List<Product> _selectedProducts = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Multi-Select Search'),
        actions: [
          if (_selectedProducts.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: () => setState(() => _selectedProducts.clear()),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Basic Multi-Select
            SmartSearchMultiDropdown<Product>.withProvider(
              request: const PaginationRequest(page: 1, pageSize: 10),
              provider: PaginationProvider.future(
                (request) => MockApiService.searchProducts(
                  request.searchQuery ?? '',
                  pageSize: request.pageSize ?? 10,
                ),
              ),
              searchRequestBuilder: (query) => PaginationRequest(
                page: 1,
                pageSize: 10,
                searchQuery: query,
              ),
              searchConfig: const SmartSearchConfig(
                debounceDelay: Duration(milliseconds: 500),
                minSearchLength: 0,
                searchOnEmpty: true,
              ),
              showSelected: true,
              itemBuilder: (context, product) => ListTile(
                leading: CircleAvatar(
                  child: Text(product.name[0].toUpperCase()),
                ),
                title: Text(product.name),
                subtitle: Text('\$${product.price.toStringAsFixed(2)}'),
              ),
              onSelectionChanged: (products) {
                setState(() => _selectedProducts = products);
              },
            ),
            const SizedBox(height: 24),

            // With Max Selections
            SmartSearchMultiDropdown<Product>.withProvider(
              request: const PaginationRequest(page: 1, pageSize: 10),
              provider: PaginationProvider.future(
                (request) => MockApiService.searchProducts(
                  request.searchQuery ?? '',
                  pageSize: request.pageSize ?? 10,
                ),
              ),
              searchRequestBuilder: (query) => PaginationRequest(
                page: 1,
                pageSize: 10,
                searchQuery: query,
              ),
              showSelected: true,
              maxSelections: 3, // Limit to 3 items
              itemBuilder: (context, product) => ListTile(
                title: Text(product.name),
                subtitle: Text('\$${product.price.toStringAsFixed(2)}'),
              ),
              onSelectionChanged: (products) {
                if (products.length == 3) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Maximum 3 items can be selected'),
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 24),

            // Custom Chip Style
            SmartSearchMultiDropdown<Product>.withProvider(
              request: const PaginationRequest(page: 1, pageSize: 10),
              provider: PaginationProvider.future(
                (request) => MockApiService.searchProducts(
                  request.searchQuery ?? '',
                  pageSize: request.pageSize ?? 10,
                ),
              ),
              searchRequestBuilder: (query) => PaginationRequest(
                page: 1,
                pageSize: 10,
                searchQuery: query,
              ),
              showSelected: true,
              selectedItemsWrap: true,
              selectedItemsSpacing: 8,
              selectedItemsRunSpacing: 8,
              itemBuilder: (context, product) => ListTile(
                title: Text(product.name),
              ),
              selectedItemBuilder: (context, product, onRemove) => Chip(
                avatar: CircleAvatar(
                  child: Text(product.name[0].toUpperCase()),
                ),
                label: Text(product.name),
                deleteIcon: const Icon(Icons.close, size: 18),
                onDeleted: onRemove,
              ),
              onSelectionChanged: (products) {},
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## 8. Search Theming

Customize search appearance:

```dart
class SearchThemingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search Theming')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Auto Theme Detection (uses system brightness)
            SmartSearchDropdown<Product>.withProvider(
              request: const PaginationRequest(page: 1, pageSize: 10),
              provider: PaginationProvider.future(fetchProducts),
              searchRequestBuilder: (query) => PaginationRequest(
                page: 1,
                pageSize: 10,
                searchQuery: query,
              ),
              itemBuilder: (context, product) => ListTile(
                title: Text(product.name),
              ),
              onItemSelected: (product) {},
            ),
            const SizedBox(height: 32),

            // Custom Purple Theme
            Theme(
              data: Theme.of(context).copyWith(
                extensions: [
                  SmartSearchTheme(
                    searchBoxBackgroundColor: const Color(0xFFF3E8FF),
                    searchBoxTextColor: const Color(0xFF581C87),
                    searchBoxHintColor: const Color(0xFF9333EA),
                    searchBoxBorderColor: const Color(0xFFD8B4FE),
                    searchBoxFocusedBorderColor: const Color(0xFF9333EA),
                    searchBoxIconColor: const Color(0xFF9333EA),
                    searchBoxCursorColor: const Color(0xFF9333EA),
                    overlayBackgroundColor: Colors.white,
                    overlayBorderColor: const Color(0xFFD8B4FE),
                    itemHoverColor: const Color(0xFFF3E8FF),
                    itemFocusedColor: const Color(0xFFE9D5FF),
                    loadingIndicatorColor: const Color(0xFF9333EA),
                  ),
                ],
              ),
              child: SmartSearchDropdown<Product>.withProvider(
                request: const PaginationRequest(page: 1, pageSize: 10),
                provider: PaginationProvider.future(fetchProducts),
                searchRequestBuilder: (query) => PaginationRequest(
                  page: 1,
                  pageSize: 10,
                  searchQuery: query,
                ),
                itemBuilder: (context, product) => ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF9333EA),
                    child: Text(
                      product.name[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(product.name),
                ),
                onItemSelected: (product) {},
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

Available theme properties:
- `searchBoxBackgroundColor`, `searchBoxTextColor`, `searchBoxHintColor`
- `searchBoxBorderColor`, `searchBoxFocusedBorderColor`, `searchBoxIconColor`
- `overlayBackgroundColor`, `overlayBorderColor`, `overlayElevation`
- `itemBackgroundColor`, `itemHoverColor`, `itemFocusedColor`, `itemSelectedColor`
- `loadingIndicatorColor`, `emptyStateIconColor`, `errorIconColor`

---

## 9. Keyboard Navigation

Navigate search results with keyboard:

```dart
class KeyboardNavigationScreen extends StatefulWidget {
  @override
  State<KeyboardNavigationScreen> createState() => _KeyboardNavigationScreenState();
}

class _KeyboardNavigationScreenState extends State<KeyboardNavigationScreen> {
  Product? _selectedProduct;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Keyboard Navigation')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Keyboard shortcuts info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Keyboard Shortcuts:', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text('↑↓ - Navigate items'),
                    Text('Enter - Select item'),
                    Text('Escape - Close dropdown'),
                    Text('Home - First item'),
                    Text('End - Last item'),
                    Text('Page Up/Down - Jump 5 items'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            SmartSearchDropdown<Product>.withProvider(
              request: const PaginationRequest(page: 1, pageSize: 10),
              provider: PaginationProvider.future(fetchProducts),
              searchRequestBuilder: (query) => PaginationRequest(
                page: 1,
                pageSize: 10,
                searchQuery: query,
              ),
              showSelected: true,
              itemBuilder: (context, product) => ListTile(
                title: Text(product.name),
                subtitle: Text(product.description),
                trailing: Text('\$${product.price.toStringAsFixed(2)}'),
              ),
              onItemSelected: (product) {
                setState(() => _selectedProduct = product);
              },
            ),

            if (_selectedProduct != null) ...[
              const SizedBox(height: 24),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.check_circle, color: Colors.green),
                  title: Text('Selected: ${_selectedProduct!.name}'),
                  subtitle: Text('\$${_selectedProduct!.price.toStringAsFixed(2)}'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

---

## 10. Custom Error Handling

Handle errors gracefully:

```dart
class CustomErrorScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Error Handling')),
      body: SmartPagination.listViewWithProvider<Product>(
        request: const PaginationRequest(page: 1, pageSize: 20),
        provider: PaginationProvider.future(fetchProducts),
        itemBuilder: (context, items, index) {
          final product = items[index];
          return ListTile(
            title: Text(product.name),
          );
        },
        onError: (exception) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 80, color: Colors.red),
                  const SizedBox(height: 24),
                  const Text(
                    'Oops! Something went wrong',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    exception.toString(),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      // Trigger retry
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try Again'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
```

---

## 11. Data Operations

Add, remove, update items programmatically:

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
    _cubit.addItem(
      Product(id: 'new', name: 'New Product', price: 99.99),
      insertFirst: true,
    );
  }

  void _removeItem(Product product) {
    _cubit.removeItem(product);
  }

  void _updateItem(Product product) {
    _cubit.updateItem(
      product,
      product.copyWith(price: product.price + 10),
    );
  }

  void _clearAll() {
    _cubit.clearItems();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Operations'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _addItem),
          IconButton(icon: const Icon(Icons.clear_all), onPressed: _clearAll),
        ],
      ),
      body: SmartPagination.withCubit(
        cubit: _cubit,
        itemBuilderType: PaginateBuilderType.listView,
        itemBuilder: (context, items, index) {
          final product = items[index];
          return Dismissible(
            key: ValueKey(product.id),
            onDismissed: (_) => _removeItem(product),
            child: ListTile(
              title: Text(product.name),
              subtitle: Text('\$${product.price.toStringAsFixed(2)}'),
              trailing: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _updateItem(product),
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

## 12. Data Age & Expiration

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
        // Callback when data expires
        onDataExpired: () {
          print('Data has expired, refreshing...');
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

## Running the Examples

1. Clone the repository
2. Navigate to the example directory:
   ```bash
   cd example
   ```
3. Install dependencies:
   ```bash
   flutter pub get
   ```
4. Run the app:
   ```bash
   flutter run
   ```

---

## Example Categories

The example app organizes examples into categories:

| Category | Description | Examples |
|----------|-------------|----------|
| **Basic** | Core pagination patterns | ListView, GridView, Column, Row, Pull-to-Refresh, Filter & Search, Retry |
| **Streams** | Real-time data updates | Single Stream, Multi Stream, Merged Streams |
| **Advanced** | Complex pagination scenarios | Cursor, Horizontal, PageView, Staggered Grid, Custom States, Scroll Control, beforeBuild Hook, hasReachedEnd, Custom Builder, Reorderable, State Separation, Preloading, Data Operations, Data Age, Sorting |
| **Search** | Smart search components | Search Dropdown, Multi-Select, Form Validation, Keyboard Navigation, Theming, Async States |
| **Errors** | Error handling patterns | Basic Errors, Network Errors, Retry Patterns, Custom Widgets, Error Recovery, Graceful Degradation, Load More Errors |

---

For more information, see the [README.md](../README.md) or visit the [GitHub repository](https://github.com/GeniusSystems24/smart_pagination).
