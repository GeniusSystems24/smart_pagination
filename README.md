# Custom Pagination

[![Pub Version](https://img.shields.io/badge/pub-v0.0.5-blue)](https://pub.dev/packages/smart_pagination)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)
[![Flutter](https://img.shields.io/badge/flutter-3.9.0+-02569B?logo=flutter)](https://flutter.dev)

A powerful, flexible, and easy-to-use Flutter pagination library with built-in **BLoC state management**, **advanced error handling**, and **beautiful UI components**. Perfect for REST APIs, real-time streams, and complex data requirements.

> **Transport agnostic**: Bring your own async function and enjoy consistent, production-ready pagination UI.

## ✨ Why Custom Pagination?

- 🚀 **Zero boilerplate** - Get paginated lists running in minutes with minimal code
- 🎨 **6+ view types** - ListView, GridView, PageView, StaggeredGrid, and more
- 🛡️ **Production-ready error handling** - 6 beautiful error widget styles included
- ⚡ **Smart preloading** - Automatically loads data before users reach the end
- 🔄 **Real-time support** - Works seamlessly with Streams and Futures
- 📱 **State separation** - Different UI for first page vs load more states
- 🧩 **Highly customizable** - Every aspect can be customized to match your design
- 🎯 **Type-safe** - Full generic type support throughout the library
- 🧪 **Well tested** - 60+ unit tests ensuring reliability

---

## 📚 Table of Contents

- [Installation](#-installation)
- [Quick Start](#-quick-start)
- [Features](#-features)
- [Error Handling](#-error-handling)
- [View Types](#-view-types)
- [Advanced Usage](#-advanced-usage)
- [Example App](#-example-app)
- [API Reference](#-api-reference)
- [Contributing](#-contributing)

---

## 📦 Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  smart_pagination: ^0.0.5
```

Install it:

```bash
flutter pub get
```

Import it:

```dart
import 'package:smart_pagination/smart_pagination.dart';
```

---

## 🚀 Quick Start

### 1. Basic ListView Pagination

The simplest way to add pagination to your app:

```dart
import 'package:smart_pagination/smart_pagination.dart';
import 'package:flutter/material.dart';

class ProductsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Products')),
      body: SmartPaginatedListView<Product>(
        request: PaginationRequest(page: 1, pageSize: 20),
        provider: PaginationProvider.future(
          (request) => apiService.fetchProducts(request),
        ),
        childBuilder: (context, product, index) {
          return ListTile(
            leading: Image.network(product.imageUrl),
            title: Text(product.name),
            subtitle: Text('\$${product.price}'),
          );
        },
      ),
    );
  }
}
```

That's it! You now have a fully functional paginated list with:

- ✅ Automatic loading of next pages
- ✅ Loading indicators
- ✅ Error handling with retry
- ✅ Empty state handling
- ✅ Pull-to-refresh support

### 2. GridView Pagination

Switch to a grid layout by changing one line:

```dart
SmartPaginatedGridView<Product>(
  request: PaginationRequest(page: 1, pageSize: 20),
  provider: PaginationProvider.future(
    (request) => apiService.fetchProducts(request),
  ),
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2,
    childAspectRatio: 0.75,
    crossAxisSpacing: 10,
    mainAxisSpacing: 10,
  ),
  childBuilder: (context, product, index) {
    return ProductCard(product: product);
  },
)
```

### 3. With Custom Error Handling

Add beautiful error states:

```dart
SmartPaginatedListView<Product>(
  request: PaginationRequest(page: 1, pageSize: 20),
  provider: PaginationProvider.future(fetchProducts),
  childBuilder: (context, product, index) => ProductCard(product),

  // Beautiful Material Design error for first page
  firstPageErrorBuilder: (context, error, retry) {
    return CustomErrorBuilder.material(
      context: context,
      error: error,
      onRetry: retry,
      title: 'Oops! Something went wrong',
      message: 'Unable to load products. Please try again.',
    );
  },

  // Compact inline error for load more
  loadMoreErrorBuilder: (context, error, retry) {
    return CustomErrorBuilder.compact(
      context: context,
      error: error,
      onRetry: retry,
    );
  },
)
```

---

## ✨ Features

### 🎨 Layout Support

| Layout Type | Description | Use Case |
|------------|-------------|----------|
| **ListView** | Vertical/horizontal scrollable lists | Standard lists, feeds, messages |
| **GridView** | Multi-column grids | Product catalogs, image galleries |
| **PageView** | Swipeable pages | Onboarding, image carousels |
| **StaggeredGridView** | Pinterest-style masonry layouts | Dynamic content, mixed sizes |
| **ReorderableListView** | Drag-and-drop reordering | Task lists, priority management |
| **Custom View Builder** | Complete layout control | Unique layouts, complex UIs |

### 🛡️ Advanced Error Handling

#### 6 Pre-Built Error Widget Styles

1. **Material Design** - Full-screen error with icon, title, and message
2. **Compact** - Inline error for load more scenarios
3. **Card** - Elevated card-style error display
4. **Minimal** - Simple text-based error
5. **Snackbar** - Bottom notification-style error
6. **Custom** - Bring your own error widget

#### Error State Separation

Different error UIs for different scenarios:

- **First Page Error** - Full-screen, detailed error when initial load fails
- **Load More Error** - Compact, inline error when pagination fails

```dart
SmartPaginatedListView<Product>(
  // ... other properties

  // Full-screen error for initial load
  firstPageErrorBuilder: (context, error, retry) {
    return CustomErrorBuilder.material(
      context: context,
      error: error,
      onRetry: retry,
    );
  },

  // Compact error for pagination
  loadMoreErrorBuilder: (context, error, retry) {
    return CustomErrorBuilder.compact(
      context: context,
      error: error,
      onRetry: retry,
    );
  },
)
```

### 🔄 Pagination Strategies

- **Offset Pagination** - Traditional page-based (`?page=2&pageSize=20`)
- **Cursor Pagination** - Efficient cursor-based (`?cursor=abc123&limit=20`)
- **Lazy Loading** - Automatic loading as user scrolls
- **Smart Preloading** - Load items 3 items before reaching the end (configurable)
- **Memory Management** - Keep only N pages in memory to optimize performance

### 📡 Data Sources

#### Future Provider (REST APIs)

```dart
PaginationProvider.future(
  (request) => apiService.fetchProducts(request),
)
```

#### Stream Provider (Real-time)

```dart
PaginationProvider.stream(
  (request) => firestore.collection('products').snapshots(),
)
```

#### Merged Streams

```dart
PaginationProvider.mergeStreams(
  (request) => [
    regularProductsStream(request),
    featuredProductsStream(request),
  ],
)
```

### 🔁 Retry Mechanisms

#### 1. Manual Retry

User clicks a button to retry:

```dart
firstPageErrorBuilder: (context, error, retry) {
  return ElevatedButton(
    onPressed: retry,
    child: Text('Try Again'),
  );
}
```

#### 2. Automatic Retry with Exponential Backoff

```dart
SmartPaginatedListView<Product>(
  request: PaginationRequest(page: 1, pageSize: 20),
  provider: PaginationProvider.future(fetchProducts),
  retryConfig: RetryConfig(
    maxAttempts: 3,
    initialDelay: Duration(seconds: 1),
    maxDelay: Duration(seconds: 10),
    shouldRetry: (error) => error is NetworkException,
  ),
  childBuilder: (context, product, index) => ProductCard(product),
)
```

#### 3. Auto Retry with Countdown

Show a countdown timer before auto-retry

#### 4. Limited Attempts

Maximum retry attempts with exhaustion handling

See [example app](example/) for complete implementations.

### 🎯 Smart Preloading

Load data before users reach the end:

```dart
SmartPaginatedListView<Product>(
  // ... other properties

  // Load when user is 3 items away from the end (default: 3)
  invisibleItemsThreshold: 3,
)
```

Adjust based on your needs:

- `invisibleItemsThreshold: 5` - More aggressive preloading
- `invisibleItemsThreshold: 1` - Load just before reaching end
- `invisibleItemsThreshold: 0` - Load only when reaching end

### 🔍 Filtering & Search

#### Server-Side Filtering

```dart
SmartPaginatedListView<Product>(
  request: PaginationRequest(
    page: 1,
    pageSize: 20,
    filters: {
      'category': 'electronics',
      'minPrice': 100,
      'maxPrice': 1000,
      'search': searchQuery,
    },
  ),
  provider: PaginationProvider.future(fetchProducts),
  childBuilder: (context, product, index) => ProductCard(product),
)
```

#### Client-Side Filtering

```dart
final filterListener = SmartPaginationFilterChangeListener<Product>();

SmartPagination(
  cubit: cubit,
  filterListeners: [filterListener],
  itemBuilder: (context, items, index) => ProductCard(items[index]),
)

// Apply filter
filterListener.searchTerm = (product) =>
  product.name.toLowerCase().contains(searchQuery.toLowerCase());
```

### ⚡ Performance Features

- **Lazy Building** - Items built only when visible
- **Smart Preloading** - Configurable preload threshold
- **Memory Optimization** - Page-based caching (`maxPagesInMemory`)
- **Efficient Rendering** - Optimized for large lists
- **Cache Extent Control** - Customize viewport caching

### 🎨 UI Customization

Every aspect of the UI can be customized:

```dart
SmartPaginatedListView<Product>(
  request: PaginationRequest(page: 1, pageSize: 20),
  provider: PaginationProvider.future(fetchProducts),
  childBuilder: (context, product, index) => ProductCard(product),

  // Loading states
  firstPageLoadingBuilder: (context) => CustomLoader(),
  loadMoreLoadingBuilder: (context) => BottomLoader(),

  // Empty state
  firstPageEmptyBuilder: (context) => EmptyState(),

  // Error states
  firstPageErrorBuilder: (context, error, retry) => ErrorWidget(),
  loadMoreErrorBuilder: (context, error, retry) => InlineError(),

  // No more items
  loadMoreNoMoreItemsBuilder: (context) => EndOfList(),

  // Separators
  separatorBuilder: (context, index) => Divider(),

  // Scroll behavior
  physics: BouncingScrollPhysics(),
  padding: EdgeInsets.all(16),
  shrinkWrap: true,
  reverse: false,
)
```

---

## 🛡️ Error Handling

### 6 Error Widget Styles

#### 1. Material Design (Recommended for First Page Errors)

<details>
<summary>View example</summary>

```dart
CustomErrorBuilder.material(
  context: context,
  error: error,
  onRetry: retry,
  title: 'Failed to Load Products',
  message: 'Please check your internet connection and try again.',
  icon: Icons.cloud_off,
  iconColor: Colors.blue,
  retryButtonText: 'Retry',
)
```

**Best for**: First page errors, initial load failures
**Style**: Full-screen with large icon, title, message, and prominent retry button
</details>

#### 2. Compact (Recommended for Load More Errors)

<details>
<summary>View example</summary>

```dart
CustomErrorBuilder.compact(
  context: context,
  error: error,
  onRetry: retry,
  message: 'Failed to load more items',
  backgroundColor: Colors.red[50],
  textColor: Colors.red[900],
)
```

**Best for**: Load more errors, inline errors
**Style**: Compact inline widget with message and small retry button
</details>

#### 3. Card Style

<details>
<summary>View example</summary>

```dart
CustomErrorBuilder.card(
  context: context,
  error: error,
  onRetry: retry,
  title: 'Products Unavailable',
  message: 'We couldn\'t fetch the products at this time.',
  elevation: 4,
)
```

**Best for**: Mixed content layouts, card-based UIs
**Style**: Elevated card with shadow, title, message, and retry button
</details>

#### 4. Minimal

<details>
<summary>View example</summary>

```dart
CustomErrorBuilder.minimal(
  context: context,
  error: error,
  onRetry: retry,
  message: 'Something went wrong',
)
```

**Best for**: Simple UIs, minimal designs
**Style**: Text message with small retry link
</details>

#### 5. Snackbar

<details>
<summary>View example</summary>

```dart
CustomErrorBuilder.snackbar(
  context: context,
  error: error,
  onRetry: retry,
  message: 'Failed to load data',
  backgroundColor: Colors.red,
)
```

**Best for**: Non-blocking errors, temporary notifications
**Style**: Bottom notification bar with message and action
</details>

#### 6. Custom

<details>
<summary>View example</summary>

```dart
CustomErrorBuilder.custom(
  context: context,
  error: error,
  onRetry: retry,
  builder: (context, error, retry) {
    return MyCustomErrorWidget(
      error: error,
      onRetry: retry,
    );
  },
)
```

**Best for**: Unique designs, branded error pages
**Style**: Completely custom - you control everything
</details>

### Error Recovery Strategies

The library supports multiple error recovery strategies:

#### 1. Cached Data Fallback

Show offline/cached data when fresh data fails to load

#### 2. Partial Data Display

Display whatever data loaded successfully before the error occurred

#### 3. Alternative Source

Switch to a backup data source (e.g., backup server, CDN)

#### 4. User-Initiated Recovery

Require user action to resolve (e.g., login, grant permissions)

#### 5. Graceful Degradation

Continue with limited functionality in offline/error mode

See [docs/ERROR_HANDLING.md](docs/ERROR_HANDLING.md) and the [example app](example/lib/screens/errors/) for complete implementations.

### Custom Exception Types

Define your own exception types for better error handling:

```dart
class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);

  @override
  String toString() => 'NetworkException: $message';
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);

  @override
  String toString() => 'TimeoutException: $message';
}

class ServerException implements Exception {
  final int statusCode;
  final String message;
  ServerException(this.statusCode, this.message);

  @override
  String toString() => 'ServerException($statusCode): $message';
}

// Use in error builders
firstPageErrorBuilder: (context, error, retry) {
  if (error is NetworkException) {
    return NetworkErrorWidget(onRetry: retry);
  } else if (error is TimeoutException) {
    return TimeoutErrorWidget(onRetry: retry);
  } else if (error is ServerException) {
    return ServerErrorWidget(statusCode: error.statusCode, onRetry: retry);
  }
  return CustomErrorBuilder.material(context: context, error: error, onRetry: retry);
}
```

### Error Illustrations

The library includes an `ErrorImages` helper for beautiful error illustrations:

```dart
CustomErrorBuilder.material(
  context: context,
  error: error,
  onRetry: retry,
  title: 'No Internet Connection',
  message: 'Please check your connection and try again',
  // Add custom image above the error
  customChild: ErrorImages.network(
    width: 200,
    height: 200,
    fallbackColor: Colors.orange,
  ),
)
```

**Available images**:

- `ErrorImages.general()` - General error
- `ErrorImages.network()` - Network/connectivity error
- `ErrorImages.notFound()` - 404 not found
- `ErrorImages.serverError()` - 500 server error
- `ErrorImages.timeout()` - Request timeout
- `ErrorImages.auth()` - Authentication error
- `ErrorImages.offline()` - Offline mode
- `ErrorImages.empty()` - Empty state
- `ErrorImages.retry()` - Retry icon
- `ErrorImages.recovery()` - Recovery icon
- `ErrorImages.loadingError()` - Load more error
- `ErrorImages.custom()` - Custom error

**Features**:

- Automatic fallback to icons if images fail to load
- Customizable width, height, and fallback colors
- Free illustration sources guide included

See [docs/ERROR_IMAGES_SETUP.md](docs/ERROR_IMAGES_SETUP.md) for setup instructions.

---

## 🎨 View Types

### 1. ListView

Standard vertical or horizontal scrolling list.

```dart
SmartPaginatedListView<Product>(
  request: PaginationRequest(page: 1, pageSize: 20),
  provider: PaginationProvider.future(fetchProducts),
  childBuilder: (context, product, index) {
    return ListTile(
      leading: Image.network(product.imageUrl),
      title: Text(product.name),
      subtitle: Text('\$${product.price}'),
      trailing: Icon(Icons.arrow_forward_ios),
    );
  },
  separatorBuilder: (context, index) => Divider(),
)
```

**Properties**:

- `scrollDirection`: `Axis.vertical` (default) or `Axis.horizontal`
- `shrinkWrap`: `true` to fit content
- `reverse`: `true` for bottom-to-top scrolling
- `separatorBuilder`: Add dividers between items

### 2. GridView

Multi-column grid layout.

```dart
SmartPaginatedGridView<Product>(
  request: PaginationRequest(page: 1, pageSize: 20),
  provider: PaginationProvider.future(fetchProducts),
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2,
    childAspectRatio: 0.75,
    crossAxisSpacing: 10,
    mainAxisSpacing: 10,
  ),
  childBuilder: (context, product, index) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Image.network(
              product.imageUrl,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: TextStyle(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),
                Text('\$${product.price}'),
              ],
            ),
          ),
        ],
      ),
    );
  },
)
```

**Grid Delegates**:

- `SliverGridDelegateWithFixedCrossAxisCount` - Fixed number of columns
- `SliverGridDelegateWithMaxCrossAxisExtent` - Max width per item

### 3. PageView

Swipeable full-screen pages.

```dart
SmartPagination.pageView(
  cubit: cubit,
  itemBuilder: (context, items, index) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: ProductDetailView(product: items[index]),
    );
  },
  pageSnapping: true,
  scrollDirection: Axis.horizontal,
)
```

**Use cases**:

- Image carousels
- Onboarding flows
- Full-screen product views
- Story-style content

### 4. StaggeredGridView

Pinterest-style masonry layout with varying item sizes.

```dart
SmartPagination.staggeredGridView(
  cubit: cubit,
  crossAxisCount: 2,
  itemBuilder: (context, items, index) {
    final product = items[index];
    return StaggeredGridTile.fit(
      crossAxisCellCount: 1,
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(
              product.imageUrl,
              fit: BoxFit.cover,
            ),
            Padding(
              padding: EdgeInsets.all(8),
              child: Text(product.name),
            ),
          ],
        ),
      ),
    );
  },
)
```

**Use cases**:

- Pinterest-style galleries
- Mixed-size content
- Dynamic height items
- Photo galleries

### 5. ReorderableListView

Drag-and-drop list reordering.

```dart
SmartPagination(
  cubit: cubit,
  itemBuilderType: PaginateBuilderType.reorderableListView,
  itemBuilder: (context, items, index) {
    return ListTile(
      key: ValueKey(items[index].id),
      leading: Icon(Icons.drag_handle),
      title: Text(items[index].name),
      subtitle: Text('Priority: ${index + 1}'),
    );
  },
  onReorder: (oldIndex, newIndex) {
    // Handle reordering logic
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final item = items.removeAt(oldIndex);
    items.insert(newIndex, item);
  },
)
```

**Use cases**:

- Task lists
- Priority management
- Playlist organization
- Custom ordering

### 6. Custom View Builder

Complete control over the layout.

```dart
SmartPagination(
  cubit: cubit,
  itemBuilderType: PaginateBuilderType.custom,
  customViewBuilder: (context, items, hasReachedEnd, fetchMore) {
    return Column(
      children: [
        // Your custom header
        Container(
          padding: EdgeInsets.all(16),
          child: Text('Found ${items.length} items'),
        ),

        // Your custom layout
        Expanded(
          child: YourCustomLayout(
            items: items,
            onLoadMore: fetchMore,
            isLastPage: hasReachedEnd,
          ),
        ),

        // Your custom footer
        if (!hasReachedEnd)
          TextButton(
            onPressed: fetchMore,
            child: Text('Load More'),
          ),
      ],
    );
  },
)
```

**Use cases**:

- Unique layouts
- Complex UIs
- Mixed view types
- Custom interactions

---

## 🚀 Advanced Usage

### Stream Support

#### Real-time Updates (Single Stream)

```dart
SmartPaginatedListView<Message>(
  request: PaginationRequest(page: 1, pageSize: 50),
  provider: PaginationProvider.stream(
    (request) => firestore
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(request.pageSize)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Message.fromDoc(doc)).toList()),
  ),
  childBuilder: (context, message, index) {
    return MessageBubble(message: message);
  },
)
```

#### Multiple Streams

Switch between different data streams:

```dart
class ProductsPage extends StatefulWidget {
  @override
  _ProductsPageState createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  String selectedStream = 'all';

  Stream<List<Product>> getStream(PaginationRequest request) {
    switch (selectedStream) {
      case 'featured':
        return apiService.featuredProductsStream(request);
      case 'sale':
        return apiService.saleProductsStream(request);
      default:
        return apiService.allProductsStream(request);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Products'),
        actions: [
          DropdownButton<String>(
            value: selectedStream,
            items: [
              DropdownMenuItem(value: 'all', child: Text('All')),
              DropdownMenuItem(value: 'featured', child: Text('Featured')),
              DropdownMenuItem(value: 'sale', child: Text('On Sale')),
            ],
            onChanged: (value) => setState(() => selectedStream = value!),
          ),
        ],
      ),
      body: SmartPaginatedListView<Product>(
        key: ValueKey(selectedStream), // Force rebuild on stream change
        request: PaginationRequest(page: 1, pageSize: 20),
        provider: PaginationProvider.stream(getStream),
        childBuilder: (context, product, index) => ProductCard(product),
      ),
    );
  }
}
```

#### Merged Streams

Combine multiple streams into one:

```dart
SmartPaginatedListView<Product>(
  request: PaginationRequest(page: 1, pageSize: 20),
  provider: PaginationProvider.mergeStreams(
    (request) => [
      apiService.regularProductsStream(request),
      apiService.featuredProductsStream(request),
      apiService.saleProductsStream(request),
    ],
  ),
  childBuilder: (context, product, index) => ProductCard(product),
)
```

### Scroll Control

Programmatic scrolling to specific items or indices:

```dart
final controller = SmartPaginationController<Product>();

class ProductsPage extends StatefulWidget {
  @override
  _ProductsPageState createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  late SmartPaginationCubit<Product> cubit;

  @override
  void initState() {
    super.initState();
    cubit = SmartPaginationCubit<Product>(
      request: PaginationRequest(page: 1, pageSize: 20),
      provider: PaginationProvider.future(fetchProducts),
    )..controller = controller;
  }

  void scrollToProduct(Product product) {
    controller.scrollToItem(
      product,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void scrollToIndex(int index) {
    controller.scrollToIndex(
      index,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Products'),
        actions: [
          IconButton(
            icon: Icon(Icons.arrow_upward),
            onPressed: () => scrollToIndex(0), // Scroll to top
          ),
        ],
      ),
      body: SmartPagination.cubit(
        cubit: cubit,
        itemBuilder: (context, items, index) => ProductCard(items[index]),
      ),
    );
  }

  @override
  void dispose() {
    cubit.close();
    super.dispose();
  }
}
```

### Before Build Hook

Transform state before rendering:

```dart
SmartPaginatedListView<Product>(
  request: PaginationRequest(page: 1, pageSize: 20),
  provider: PaginationProvider.future(fetchProducts),
  childBuilder: (context, product, index) => ProductCard(product),

  // Sort items before rendering
  beforeBuild: (state) {
    if (state is SmartPaginationLoaded<Product>) {
      final sortedItems = state.items.toList()
        ..sort((a, b) => a.price.compareTo(b.price));
      return state.copyWith(items: sortedItems);
    }
    return state;
  },
)
```

### List Builder

Transform items in the cubit before emission:

```dart
SmartPaginationCubit<Product>(
  request: PaginationRequest(page: 1, pageSize: 20),
  provider: PaginationProvider.future(fetchProducts),

  // Remove duplicates
  listBuilder: (items) {
    return items.toSet().toList();
  },
)
```

### Callbacks

React to pagination events:

```dart
SmartPaginationCubit<Product>(
  request: PaginationRequest(page: 1, pageSize: 20),
  provider: PaginationProvider.future(fetchProducts),

  onInsertionCallback: (items) {
    print('Loaded ${items.length} new items');
    analytics.logEvent('items_loaded', {'count': items.length});
  },

  onReachedEnd: () {
    print('Reached end of pagination');
    showSnackBar('No more items to load');
  },

  onClear: () {
    print('Pagination list cleared');
  },
)
```

### Pull to Refresh

Add swipe-down-to-refresh functionality:

```dart
final refreshListener = SmartPaginationRefreshedChangeListener();

class ProductsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        refreshListener.refreshed = true;
        await Future.delayed(Duration(seconds: 1));
      },
      child: SmartPaginatedListView<Product>(
        request: PaginationRequest(page: 1, pageSize: 20),
        provider: PaginationProvider.future(fetchProducts),
        refreshListener: refreshListener,
        childBuilder: (context, product, index) => ProductCard(product),
      ),
    );
  }
}
```

### Memory Management

Optimize memory usage for large datasets:

```dart
SmartPaginationCubit<Product>(
  request: PaginationRequest(page: 1, pageSize: 20),
  provider: PaginationProvider.future(fetchProducts),

  // Keep only 5 pages in memory (100 items with pageSize=20)
  // Older pages are automatically removed
  maxPagesInMemory: 5,
)
```

### Custom Loading States

Customize loading indicators for different states:

```dart
SmartPaginatedListView<Product>(
  request: PaginationRequest(page: 1, pageSize: 20),
  provider: PaginationProvider.future(fetchProducts),
  childBuilder: (context, product, index) => ProductCard(product),

  // Full-screen loading for first page
  firstPageLoadingBuilder: (context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading products...'),
        ],
      ),
    );
  },

  // Bottom loading for pagination
  loadMoreLoadingBuilder: (context) {
    return Container(
      padding: EdgeInsets.all(16),
      alignment: Alignment.center,
      child: Row(
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
    );
  },
)
```

### Custom Empty States

Show custom UI when no data is available:

```dart
SmartPaginatedListView<Product>(
  request: PaginationRequest(page: 1, pageSize: 20),
  provider: PaginationProvider.future(fetchProducts),
  childBuilder: (context, product, index) => ProductCard(product),

  firstPageEmptyBuilder: (context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_basket_outlined,
            size: 100,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'No Products Found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Try adjusting your filters',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  },
)
```

### Cursor-Based Pagination

Efficient pagination for large datasets:

```dart
// Your API response model
class PaginatedResponse<T> {
  final List<T> items;
  final String? nextCursor;
  final bool hasMore;

  PaginatedResponse({
    required this.items,
    this.nextCursor,
    required this.hasMore,
  });
}

// Use cursor in pagination
class ProductsPage extends StatefulWidget {
  @override
  _ProductsPageState createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  String? nextCursor;

  Future<List<Product>> fetchProducts(PaginationRequest request) async {
    final response = await apiService.fetchProductsCursor(
      cursor: nextCursor,
      limit: request.pageSize,
    );

    nextCursor = response.nextCursor;
    return response.items;
  }

  @override
  Widget build(BuildContext context) {
    return SmartPaginatedListView<Product>(
      request: PaginationRequest(page: 1, pageSize: 20),
      provider: PaginationProvider.future(fetchProducts),
      childBuilder: (context, product, index) => ProductCard(product),
    );
  }
}
```

---

## 🎨 Example App

The library includes a comprehensive example app with **28 demonstration screens** covering every feature.

### Running the Example

```bash
cd example
flutter pub get
flutter run
```

### 📱 All Example Screens with Screenshots

<div align="center">

> 💡 **Tip**: Click on any example below to see the implementation in the repository

</div>

---

### 🎯 Basic Pagination Examples

#### 1. Basic ListView

Simple paginated product list with automatic loading.

<div align="center">
  <img src="screenshots/basic/01_basic_listview.png" alt="Basic ListView" width="250"/>
</div>

**Features**: Automatic pagination, loading indicators, scroll-to-load

**Code**: [basic_listview_screen.dart](example/lib/screens/smart_pagination/basic_listview_screen.dart)

---

#### 2. GridView Pagination

Product grid with 2 columns and pagination.

<div align="center">
  <img src="screenshots/basic/02_gridview.png" alt="GridView" width="250"/>
</div>

**Features**: GridView layout, configurable columns, responsive grid

**Code**: [gridview_screen.dart](example/lib/screens/smart_pagination/gridview_screen.dart)

---

#### 3. Retry Mechanism

Automatic retry with exponential backoff.

<div align="center">
  <img src="screenshots/basic/03_retry_mechanism.png" alt="Retry Mechanism" width="250"/>
</div>

**Features**: Auto-retry, exponential backoff, configurable attempts

**Code**: [retry_demo_screen.dart](example/lib/screens/smart_pagination/retry_demo_screen.dart)

---

#### 4. Filter & Search

Real-time search and filtering with pagination.

<div align="center">
  <img src="screenshots/basic/04_filter_search.png" alt="Filter & Search" width="250"/>
</div>

**Features**: Server-side filtering, search as you type, filter persistence

**Code**: [filter_search_screen.dart](example/lib/screens/smart_pagination/filter_search_screen.dart)

---

#### 5. Pull to Refresh

Swipe down to refresh functionality.

<div align="center">
  <img src="screenshots/basic/05_pull_to_refresh.png" alt="Pull to Refresh" width="250"/>
</div>

**Features**: Pull-to-refresh, refresh indicators, state reset

**Code**: [pull_to_refresh_screen.dart](example/lib/screens/smart_pagination/pull_to_refresh_screen.dart)

---

### 📡 Stream Examples

#### 6. Single Stream

Real-time updates from a single data stream.

<div align="center">
  <img src="screenshots/streams/06_single_stream.png" alt="Single Stream" width="250"/>
</div>

**Features**: Real-time updates, WebSocket/Firestore integration, auto-sync

**Code**: [single_stream_screen.dart](example/lib/screens/smart_pagination/single_stream_screen.dart)

---

#### 7. Multi Stream

Switch between different data streams dynamically.

<div align="center">
  <img src="screenshots/streams/07_multi_stream.png" alt="Multi Stream" width="250"/>
</div>

**Features**: Stream switching, multiple data sources, smooth transitions

**Code**: [multi_stream_screen.dart](example/lib/screens/smart_pagination/multi_stream_screen.dart)

---

#### 8. Merged Streams

Combine multiple streams into one unified list.

<div align="center">
  <img src="screenshots/streams/08_merged_streams.png" alt="Merged Streams" width="250"/>
</div>

**Features**: Stream merging, unified data, concurrent updates

**Code**: [merged_streams_screen.dart](example/lib/screens/smart_pagination/merged_streams_screen.dart)

---

### ⚙️ Advanced Examples

#### 9. Cursor Pagination

Efficient cursor-based pagination for large datasets.

<div align="center">
  <img src="screenshots/advanced/09_cursor_pagination.png" alt="Cursor Pagination" width="250"/>
</div>

**Features**: Cursor-based pagination, efficient queries, no page skipping

**Code**: [cursor_pagination_screen.dart](example/lib/screens/smart_pagination/cursor_pagination_screen.dart)

---

#### 10. Horizontal Scroll

Horizontal scrolling paginated list.

<div align="center">
  <img src="screenshots/advanced/10_horizontal_scroll.png" alt="Horizontal Scroll" width="250"/>
</div>

**Features**: Horizontal orientation, swipe navigation, carousel-style

**Code**: [horizontal_list_screen.dart](example/lib/screens/smart_pagination/horizontal_list_screen.dart)

---

#### 11. PageView

Swipeable full-screen pages with pagination.

<div align="center">
  <img src="screenshots/advanced/11_page_view.png" alt="PageView" width="250"/>
</div>

**Features**: Full-screen pages, swipe gestures, page indicators

**Code**: [page_view_screen.dart](example/lib/screens/smart_pagination/page_view_screen.dart)

---

#### 12. Staggered Grid

Pinterest-style masonry layout.

<div align="center">
  <img src="screenshots/advanced/12_staggered_grid.png" alt="Staggered Grid" width="250"/>
</div>

**Features**: Masonry layout, variable heights, dynamic positioning

**Code**: [staggered_grid_screen.dart](example/lib/screens/smart_pagination/staggered_grid_screen.dart)

---

#### 13. Custom States

Custom loading, empty, and error states.

<div align="center">
  <img src="screenshots/advanced/13_custom_states.png" alt="Custom States" width="250"/>
</div>

**Features**: Custom UI for all states, branded loading, custom animations

**Code**: [custom_states_screen.dart](example/lib/screens/smart_pagination/custom_states_screen.dart)

---

#### 14. Scroll Control

Programmatic scrolling to specific items or indices.

<div align="center">
  <img src="screenshots/advanced/14_scroll_control.png" alt="Scroll Control" width="250"/>
</div>

**Features**: Scroll to item, scroll to index, smooth animations

**Code**: [scroll_control_screen.dart](example/lib/screens/smart_pagination/scroll_control_screen.dart)

---

#### 15. beforeBuild Hook

Transform state before rendering.

<div align="center">
  <img src="screenshots/advanced/15_before_build_hook.png" alt="beforeBuild Hook" width="250"/>
</div>

**Features**: State transformation, sorting, filtering before render

**Code**: [before_build_hook_screen.dart](example/lib/screens/smart_pagination/before_build_hook_screen.dart)

---

#### 16. hasReachedEnd

Detect when pagination reaches the end.

<div align="center">
  <img src="screenshots/advanced/16_has_reached_end.png" alt="hasReachedEnd" width="250"/>
</div>

**Features**: End detection, custom end message, callbacks

**Code**: [has_reached_end_screen.dart](example/lib/screens/smart_pagination/has_reached_end_screen.dart)

---

#### 17. Custom View Builder

Complete control over the layout.

<div align="center">
  <img src="screenshots/advanced/17_custom_view_builder.png" alt="Custom View Builder" width="250"/>
</div>

**Features**: Fully custom layouts, mixed views, complex UIs

**Code**: [custom_view_builder_screen.dart](example/lib/screens/smart_pagination/custom_view_builder_screen.dart)

---

#### 18. Reorderable List

Drag and drop to reorder items.

<div align="center">
  <img src="screenshots/advanced/18_reorderable_list.png" alt="Reorderable List" width="250"/>
</div>

**Features**: Drag-and-drop, reorder callbacks, visual feedback

**Code**: [reorderable_list_screen.dart](example/lib/screens/smart_pagination/reorderable_list_screen.dart)

---

#### 19. State Separation

Different UI for first page vs load more states.

<div align="center">
  <img src="screenshots/advanced/19_state_separation.png" alt="State Separation" width="250"/>
</div>

**Features**: Separate first page/load more UI, different error handling

**Code**: [state_separation_screen.dart](example/lib/screens/smart_pagination/state_separation_screen.dart)

---

#### 20. Smart Preloading

Configurable preload threshold.

<div align="center">
  <img src="screenshots/advanced/20_smart_preloading.png" alt="Smart Preloading" width="250"/>
</div>

**Features**: Preload before end, configurable threshold, smooth experience

**Code**: [smart_preloading_screen.dart](example/lib/screens/smart_pagination/smart_preloading_screen.dart)

---

#### 21. Custom Error Handling

All error widget styles demonstration.

<div align="center">
  <img src="screenshots/advanced/21_custom_error_handling.png" alt="Custom Error Handling" width="250"/>
</div>

**Features**: All 6 error styles, custom error types, retry mechanisms

**Code**: [custom_error_handling_screen.dart](example/lib/screens/smart_pagination/custom_error_handling_screen.dart)

---

### 🛡️ Error Handling Examples

#### 22. Basic Error Handling

Simple error display with retry button.

<div align="center">
  <img src="screenshots/errors/22_basic_error.png" alt="Basic Error" width="250"/>
</div>

**Features**: Simple retry, error counter, success after N attempts

**Code**: [basic_error_example.dart](example/lib/screens/errors/basic_error_example.dart)

---

#### 23. Network Errors

Different network error types (timeout, 404, 500, etc.).

<div align="center">
  <img src="screenshots/errors/23_network_errors.png" alt="Network Errors" width="250"/>
</div>

**Features**: Custom exceptions, context-aware errors, appropriate icons

**Code**: [network_errors_example.dart](example/lib/screens/errors/network_errors_example.dart)

---

#### 24. Retry Patterns

Manual, auto, exponential backoff, limited retries.

<div align="center">
  <img src="screenshots/errors/24_retry_patterns.png" alt="Retry Patterns" width="250"/>
</div>

**Features**: 4 retry strategies, countdown timers, retry limits

**Code**: [retry_patterns_example.dart](example/lib/screens/errors/retry_patterns_example.dart)

---

#### 25. Custom Error Widgets

All 6 pre-built error widget styles.

<div align="center">
  <img src="screenshots/errors/25_custom_error_widgets.png" alt="Custom Error Widgets" width="250"/>
</div>

**Features**: Material, Compact, Card, Minimal, Snackbar, Custom styles

**Code**: [custom_error_widgets_example.dart](example/lib/screens/errors/custom_error_widgets_example.dart)

---

#### 26. Error Recovery

Cached data, partial data, fallback strategies.

<div align="center">
  <img src="screenshots/errors/26_error_recovery.png" alt="Error Recovery" width="250"/>
</div>

**Features**: 4 recovery strategies, offline mode, data persistence

**Code**: [error_recovery_example.dart](example/lib/screens/errors/error_recovery_example.dart)

---

#### 27. Graceful Degradation

Offline mode, placeholders, limited features.

<div align="center">
  <img src="screenshots/errors/27_graceful_degradation.png" alt="Graceful Degradation" width="250"/>
</div>

**Features**: 3 degradation strategies, offline UI, skeleton screens

**Code**: [graceful_degradation_example.dart](example/lib/screens/errors/graceful_degradation_example.dart)

---

#### 28. Load More Errors

Handle errors while loading additional pages.

<div align="center">
  <img src="screenshots/errors/28_load_more_errors.png" alt="Load More Errors" width="250"/>
</div>

**Features**: 3 load-more patterns, inline errors, dismissible banners

**Code**: [load_more_errors_example.dart](example/lib/screens/errors/load_more_errors_example.dart)

---

### 📸 Adding Screenshots

To capture screenshots for the examples:

1. Run the example app
2. Navigate to each screen
3. Take screenshots (recommended: 1080x2400px)
4. Save to `screenshots/` directory following naming convention

See [screenshots/README.md](screenshots/README.md) for detailed instructions.

---

## 📚 API Reference

### SmartPaginatedListView<T>

The easiest way to create a paginated list.

```dart
SmartPaginatedListView<T>({
  // Required
  required PaginationRequest request,
  required PaginationProvider<T> provider,
  required Widget Function(BuildContext, T, int) childBuilder,

  // Optional builders
  Widget Function(BuildContext, int)? separatorBuilder,

  // First page builders
  Widget Function(BuildContext)? firstPageLoadingBuilder,
  Widget Function(BuildContext, Exception, VoidCallback)? firstPageErrorBuilder,
  Widget Function(BuildContext)? firstPageEmptyBuilder,

  // Load more builders
  Widget Function(BuildContext)? loadMoreLoadingBuilder,
  Widget Function(BuildContext, Exception, VoidCallback)? loadMoreErrorBuilder,
  Widget Function(BuildContext)? loadMoreNoMoreItemsBuilder,

  // Configuration
  RetryConfig? retryConfig,
  bool shrinkWrap = false,
  bool reverse = false,
  Axis scrollDirection = Axis.vertical,
  EdgeInsetsGeometry? padding,
  ScrollPhysics? physics,
  ScrollController? scrollController,
  int invisibleItemsThreshold = 3,
  VoidCallback? onReachedEnd,

  // Advanced
  SmartPaginationState<T> Function(SmartPaginationState<T>)? beforeBuild,
  SmartPaginationRefreshedChangeListener? refreshListener,
  List<SmartPaginationFilterChangeListener<T>>? filterListeners,
})
```

### SmartPaginatedGridView<T>

Grid layout with pagination.

```dart
SmartPaginatedGridView<T>({
  // All SmartPaginatedListView parameters, plus:
  required SliverGridDelegate gridDelegate,
})
```

### SmartPagination<T>

Low-level widget for complete control.

```dart
SmartPagination<T>({
  // Data source
  required PaginationRequest request,
  required PaginationProvider<T> provider,
  required Widget Function(BuildContext, List<T>, int) itemBuilder,

  // View type
  PaginateBuilderType itemBuilderType = PaginateBuilderType.listView,

  // Custom view builder
  Widget Function(
    BuildContext context,
    List<T> items,
    bool hasReachedEnd,
    VoidCallback fetchMore,
  )? customViewBuilder,

  // All other parameters same as SmartPaginatedListView
})
```

### SmartPagination.cubit()

Use with your own cubit instance for full control.

```dart
SmartPagination.cubit<T>({
  required SmartPaginationCubit<T> cubit,
  required Widget Function(BuildContext, List<T>, int) itemBuilder,
  // ... other parameters
})
```

### PaginationProvider<T>

Defines how data is fetched.

```dart
// Future-based (REST APIs)
PaginationProvider.future(
  Future<List<T>> Function(PaginationRequest request) provider,
)

// Stream-based (Real-time)
PaginationProvider.stream(
  Stream<List<T>> Function(PaginationRequest request) provider,
)

// Merged streams
PaginationProvider.mergeStreams(
  List<Stream<List<T>>> Function(PaginationRequest request) providers,
)
```

### PaginationRequest

Request configuration.

```dart
const PaginationRequest({
  required int page,              // Current page number (1-indexed)
  required int pageSize,          // Number of items per page
  Map<String, dynamic>? filters,  // Optional filters for server-side filtering
})
```

### RetryConfig

Configure automatic retry behavior.

```dart
RetryConfig({
  int maxAttempts = 3,                        // Max retry attempts
  Duration initialDelay = Duration(seconds: 1), // Initial retry delay
  Duration maxDelay = Duration(seconds: 10),    // Maximum retry delay
  Duration? timeoutDuration,                    // Request timeout
  List<Duration>? retryDelays,                  // Custom delays per attempt
  bool Function(Exception)? shouldRetry,        // Custom retry condition
})
```

### CustomErrorBuilder

Pre-built error widget styles.

```dart
// Material Design
CustomErrorBuilder.material({
  required BuildContext context,
  required Exception error,
  required VoidCallback onRetry,
  String? title,
  String? message,
  IconData? icon,
  Color? iconColor,
  String? retryButtonText,
})

// Compact inline
CustomErrorBuilder.compact({
  required BuildContext context,
  required Exception error,
  required VoidCallback onRetry,
  String? message,
  Color? backgroundColor,
  Color? textColor,
})

// Card style
CustomErrorBuilder.card({
  required BuildContext context,
  required Exception error,
  required VoidCallback onRetry,
  String? title,
  String? message,
  double? elevation,
})

// Minimal
CustomErrorBuilder.minimal({
  required BuildContext context,
  required Exception error,
  required VoidCallback onRetry,
  String? message,
})

// Snackbar
CustomErrorBuilder.snackbar({
  required BuildContext context,
  required Exception error,
  required VoidCallback onRetry,
  String? message,
  Color? backgroundColor,
})

// Custom
CustomErrorBuilder.custom({
  required BuildContext context,
  required Exception error,
  required VoidCallback onRetry,
  required Widget Function(BuildContext, Exception, VoidCallback) builder,
})
```

### ErrorImages

Helper for error illustrations with automatic icon fallback.

```dart
ErrorImages.general({double width, double height, Color? fallbackColor})
ErrorImages.network({double width, double height, Color? fallbackColor})
ErrorImages.notFound({double width, double height, Color? fallbackColor})
ErrorImages.serverError({double width, double height, Color? fallbackColor})
ErrorImages.timeout({double width, double height, Color? fallbackColor})
ErrorImages.auth({double width, double height, Color? fallbackColor})
ErrorImages.offline({double width, double height, Color? fallbackColor})
ErrorImages.empty({double width, double height, Color? fallbackColor})
ErrorImages.retry({double width, double height, Color? fallbackColor})
ErrorImages.recovery({double width, double height, Color? fallbackColor})
ErrorImages.loadingError({double width, double height, Color? fallbackColor})
ErrorImages.custom({double width, double height, Color? fallbackColor})
```

### SmartPaginationCubit<T>

Low-level BLoC for advanced use cases.

```dart
class SmartPaginationCubit<T> extends Cubit<SmartPaginationState<T>> {
  SmartPaginationCubit({
    required PaginationRequest request,
    required PaginationProvider<T> provider,
    RetryConfig? retryConfig,
    int? maxPagesInMemory,
    List<T> Function(List<T>)? listBuilder,
    void Function(List<T>)? onInsertionCallback,
    VoidCallback? onClear,
    VoidCallback? onReachedEnd,
    Logger? logger,
  });

  // Methods
  Future<void> fetchPaginatedList();
  Future<void> loadMore();
  void refresh();
  void clear();
  void addItems(List<T> items);
  void removeItem(T item);
  void updateItem(T oldItem, T newItem);
}
```

### SmartPaginationState<T>

BLoC states.

```dart
// Initial state
class SmartPaginationInitial<T> extends SmartPaginationState<T>

// Loading first page
class SmartPaginationLoading<T> extends SmartPaginationState<T>

// Data loaded
class SmartPaginationLoaded<T> extends SmartPaginationState<T> {
  final List<T> items;
  final bool hasReachedEnd;
  final bool isLoadingMore;
  final Exception? loadMoreError;
}

// First page error
class SmartPaginationError<T> extends SmartPaginationState<T> {
  final Exception exception;
}

// Empty state
class SmartPaginationEmpty<T> extends SmartPaginationState<T>
```

---

## 🎯 Best Practices

### 1. Reuse Cubits for Performance

Create the cubit once and reuse it:

```dart
// ❌ Bad - Creates new cubit on every build
Widget build(BuildContext context) {
  return SmartPaginatedListView<Product>(
    request: PaginationRequest(page: 1, pageSize: 20),
    provider: PaginationProvider.future(fetchProducts),
    childBuilder: (context, product, index) => ProductCard(product),
  );
}

// ✅ Good - Reuse cubit instance
class ProductsPage extends StatefulWidget {
  @override
  _ProductsPageState createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  late SmartPaginationCubit<Product> cubit;

  @override
  void initState() {
    super.initState();
    cubit = SmartPaginationCubit<Product>(
      request: PaginationRequest(page: 1, pageSize: 20),
      provider: PaginationProvider.future(fetchProducts),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SmartPagination.cubit(
      cubit: cubit,
      itemBuilder: (context, items, index) => ProductCard(items[index]),
    );
  }

  @override
  void dispose() {
    cubit.close();
    super.dispose();
  }
}
```

### 2. Optimize Memory Usage

Set `maxPagesInMemory` based on your item size:

```dart
SmartPaginationCubit<Product>(
  request: PaginationRequest(page: 1, pageSize: 20),
  provider: PaginationProvider.future(fetchProducts),
  maxPagesInMemory: 5, // Keeps ~100 items in memory
)
```

### 3. Always Provide Error Builders

Better user experience with custom error handling:

```dart
SmartPaginatedListView<Product>(
  // ... other properties

  firstPageErrorBuilder: (context, error, retry) {
    return CustomErrorBuilder.material(
      context: context,
      error: error,
      onRetry: retry,
      title: 'Oops!',
      message: 'Something went wrong. Please try again.',
    );
  },

  loadMoreErrorBuilder: (context, error, retry) {
    return CustomErrorBuilder.compact(
      context: context,
      error: error,
      onRetry: retry,
    );
  },
)
```

### 4. Use State Separation

Different UI for first page vs load more:

```dart
// Different loading indicators
firstPageLoadingBuilder: (context) => FullScreenLoader(),
loadMoreLoadingBuilder: (context) => BottomLoader(),

// Different error widgets
firstPageErrorBuilder: (context, error, retry) => FullScreenError(),
loadMoreErrorBuilder: (context, error, retry) => InlineError(),
```

### 5. Smart Preloading Configuration

Adjust based on your use case:

```dart
// Fast scrolling content (e.g., chat)
invisibleItemsThreshold: 5,

// Slow scrolling content (e.g., product catalog)
invisibleItemsThreshold: 2,

// On-demand loading only
invisibleItemsThreshold: 0,
```

### 6. Use listBuilder for Transformations

Prefer `listBuilder` over `beforeBuild` for performance:

```dart
// ✅ Good - Transforms in cubit before emission
SmartPaginationCubit<Product>(
  request: PaginationRequest(page: 1, pageSize: 20),
  provider: PaginationProvider.future(fetchProducts),
  listBuilder: (items) => items.toSet().toList(), // Remove duplicates
)

// ⚠️ Less efficient - Transforms on every build
SmartPaginatedListView<Product>(
  request: PaginationRequest(page: 1, pageSize: 20),
  provider: PaginationProvider.future(fetchProducts),
  beforeBuild: (state) {
    // Runs on every build
  },
  childBuilder: (context, product, index) => ProductCard(product),
)
```

### 7. Error Images with Fallback

Always use fallback to ensure content displays:

```dart
ErrorImages.network(
  width: 200,
  height: 200,
  fallbackColor: Colors.orange, // Shows icon if image fails
)
```

### 8. Testing with Mock Data

Create mock providers for predictable tests:

```dart
// Mock provider for testing
final mockProvider = PaginationProvider.future(
  (request) async {
    await Future.delayed(Duration(milliseconds: 500));
    return List.generate(
      request.pageSize,
      (i) => Product(
        id: '${request.page}-$i',
        name: 'Product ${request.page}-$i',
      ),
    );
  },
);

// Use in tests
testWidgets('displays products', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: SmartPaginatedListView<Product>(
        request: PaginationRequest(page: 1, pageSize: 20),
        provider: mockProvider,
        childBuilder: (context, product, index) {
          return Text(product.name);
        },
      ),
    ),
  );

  await tester.pumpAndSettle();
  expect(find.text('Product 1-0'), findsOneWidget);
});
```

---

## 🏗️ Architecture

```
lib/
├── core/                          # Core interfaces and shared widgets
│   ├── bloc/                      # Abstract interfaces
│   │   ├── ipagination_cubit.dart
│   │   ├── ipagination_state.dart
│   │   └── ipagination_listeners.dart
│   ├── controller/                # Controller interfaces
│   │   └── ipagination_controller.dart
│   └── widget/                    # Shared UI components
│       ├── error_display.dart
│       ├── custom_error_builder.dart    # 6 error styles
│       ├── initial_loader.dart
│       ├── bottom_loader.dart
│       └── empty_display.dart
│
├── data/                          # Data models
│   └── models/
│       ├── pagination_request.dart
│       ├── pagination_meta.dart
│       └── pagination_provider.dart
│
└── smart_pagination/              # Main implementation
    ├── bloc/                      # State management
    │   ├── smart_pagination_cubit.dart
    │   ├── smart_pagination_state.dart
    │   └── smart_pagination_listeners.dart
    ├── controller/                # Scroll control
    │   └── smart_pagination_controller.dart
    └── widgets/                   # UI widgets
        ├── paginate_api_view.dart              # Low-level widget
        ├── smart_paginated_list_view.dart      # Convenience widget
        ├── smart_paginated_grid_view.dart      # Convenience widget
        └── smart_paginated_staggered_grid.dart # Staggered grid
```

### Design Principles

1. **Separation of Concerns** - Core interfaces separate from implementation
2. **Flexibility** - Multiple abstraction levels for different use cases
3. **Type Safety** - Generic types throughout for compile-time safety
4. **Testability** - Mock-friendly interfaces and dependency injection
5. **Extensibility** - Easy to extend with custom implementations

---

## 📖 Documentation

- **Error Handling Guide**: [docs/ERROR_HANDLING.md](docs/ERROR_HANDLING.md)
- **Error Images Setup**: [docs/ERROR_IMAGES_SETUP.md](docs/ERROR_IMAGES_SETUP.md)
- **Changelog**: [CHANGELOG.md](CHANGELOG.md)
- **License**: [LICENSE](LICENSE)

---

## 🧪 Testing

The library includes 60+ unit tests ensuring reliability.

### Run Tests

```bash
flutter test
```

### Example Tests

```dart
// Cubit test
blocTest<SmartPaginationCubit<Product>, SmartPaginationState<Product>>(
  'emits loaded state when fetch succeeds',
  build: () => SmartPaginationCubit<Product>(
    request: PaginationRequest(page: 1, pageSize: 20),
    provider: PaginationProvider.future(mockFetchProducts),
  ),
  act: (cubit) => cubit.fetchPaginatedList(),
  expect: () => [
    isA<SmartPaginationLoaded<Product>>()
      .having((s) => s.items.length, 'items length', 20),
  ],
);

// Widget test
testWidgets('shows loading indicator initially', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: SmartPaginatedListView<Product>(
        request: PaginationRequest(page: 1, pageSize: 20),
        provider: PaginationProvider.future(mockFetchProducts),
        childBuilder: (context, product, index) => Text(product.name),
      ),
    ),
  );

  expect(find.byType(CircularProgressIndicator), findsOneWidget);
});
```

---

## 🗺️ Roadmap

- [x] Single pagination implementation
- [x] BLoC state management
- [x] ListView, GridView, PageView support
- [x] Retry mechanism with exponential backoff
- [x] 60+ unit tests
- [x] Convenience widgets
- [x] Example app with 28+ demos
- [x] Advanced error handling (6 styles)
- [x] Error state separation
- [x] Error illustrations infrastructure
- [x] Smart preloading
- [x] Stream support
- [x] Merged streams
- [x] Custom view builder
- [x] Reorderable list support
- [x] StaggeredGridView support
- [ ] Widget and integration tests
- [ ] Performance benchmarks
- [ ] Video tutorials
- [ ] CI/CD pipeline
- [ ] pub.dev publication
- [ ] Infinite scroll mode
- [ ] Bi-directional pagination
- [ ] GraphQL support

---

## 🤝 Contributing

We welcome contributions! Here's how you can help:

### Ways to Contribute

1. 🐛 **Report bugs** - [Open an issue](https://github.com/GeniusSystems24/smart_pagination/issues)
2. 💡 **Suggest features** - [Start a discussion](https://github.com/GeniusSystems24/smart_pagination/discussions)
3. 📖 **Improve docs** - Fix typos, add examples
4. 🔧 **Submit PRs** - Add features, fix bugs

### Development Setup

```bash
# Clone the repository
git clone https://github.com/GeniusSystems24/smart_pagination.git
cd smart_pagination

# Install dependencies
flutter pub get

# Run tests
flutter test

# Run example app
cd example
flutter pub get
flutter run
```

### Pull Request Process

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Add/update tests
5. Ensure tests pass (`flutter test`)
6. Format code (`flutter format .`)
7. Update documentation
8. Commit changes (`git commit -m 'Add amazing feature'`)
9. Push to branch (`git push origin feature/amazing-feature`)
10. Open a Pull Request

### Guidelines

- ✅ All tests must pass
- ✅ Code must be formatted (`flutter format .`)
- ✅ Update documentation for new features
- ✅ Add examples for new features
- ✅ Follow existing code style
- ✅ Write clear commit messages

---

## 📝 Changelog

See [CHANGELOG.md](CHANGELOG.md) for detailed version history.

### Latest Version (0.0.5)

- ✅ Advanced error handling with 6 pre-built error styles
- ✅ Error state separation (first page vs load more)
- ✅ Error illustrations infrastructure
- ✅ Smart preloading configuration
- ✅ Custom view builder support
- ✅ Stream support (single, multiple, merged)
- ✅ 28+ example screens
- ✅ Comprehensive documentation

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

```
MIT License

Copyright (c) 2024 Genius Systems 24

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

## 🙏 Acknowledgments

- **flutter_bloc** - State management ([pub.dev/packages/flutter_bloc](https://pub.dev/packages/flutter_bloc))
- **scrollview_observer** - Scroll control ([pub.dev/packages/scrollview_observer](https://pub.dev/packages/scrollview_observer))
- **flutter_staggered_grid_view** - Staggered layouts ([pub.dev/packages/flutter_staggered_grid_view](https://pub.dev/packages/flutter_staggered_grid_view))
- Inspired by Flutter pagination best practices

---

## 📧 Support

Need help? We're here for you!

- 📫 [Open an issue](https://github.com/GeniusSystems24/smart_pagination/issues)
- 💬 [Start a discussion](https://github.com/GeniusSystems24/smart_pagination/discussions)
- 📚 [Read the docs](https://github.com/GeniusSystems24/smart_pagination#readme)
- ⭐ Star the repo if you find it useful!

---

## 🌟 Features Comparison

| Feature | Custom Pagination | infinite_scroll_pagination | flutter_pagewise | pagination_view |
|---------|------------------|---------------------------|------------------|-----------------|
| BLoC Pattern | ✅ Built-in | ❌ Manual | ❌ Manual | ❌ Manual |
| Multiple View Types | ✅ 6+ types | ⚠️ Limited | ⚠️ Limited | ⚠️ Limited |
| Error State Separation | ✅ Yes | ❌ No | ❌ No | ❌ No |
| Pre-built Error Widgets | ✅ 6 styles | ❌ No | ❌ No | ❌ No |
| Stream Support | ✅ Full | ⚠️ Limited | ❌ No | ❌ No |
| Smart Preloading | ✅ Configurable | ⚠️ Fixed | ⚠️ Fixed | ❌ No |
| Memory Management | ✅ Yes | ❌ No | ❌ No | ❌ No |
| Retry Mechanism | ✅ Advanced | ⚠️ Basic | ⚠️ Basic | ❌ No |
| Type Safety | ✅ Full generics | ✅ Yes | ✅ Yes | ⚠️ Limited |
| Testing | ✅ 60+ tests | ⚠️ Partial | ⚠️ Partial | ❌ No |
| Documentation | ✅ Comprehensive | ⚠️ Basic | ⚠️ Basic | ⚠️ Basic |
| Example App | ✅ 28+ screens | ⚠️ Few | ⚠️ Few | ⚠️ Few |

---

## 💡 Use Cases

### E-Commerce Apps

- Product catalogs with grid/list views
- Search and filter products
- Categorized product listings
- Order history pagination

### Social Media

- News feeds with real-time updates
- User profiles and followers lists
- Comments and replies threading
- Media galleries (photos, videos)

### Content Apps

- Article listings
- Video streaming libraries
- Podcast episodes
- News aggregators

### Business Apps

- Transaction histories
- Customer lists
- Invoice management
- Report listings

### Chat Apps

- Message history pagination
- Contact lists
- Channel/group listings
- File/media sharing logs

---

## 🎓 Learning Resources

### Tutorials

- [Getting Started Guide](https://github.com/GeniusSystems24/smart_pagination/wiki/Getting-Started)
- [Error Handling Deep Dive](docs/ERROR_HANDLING.md)
- [Advanced Patterns](https://github.com/GeniusSystems24/smart_pagination/wiki/Advanced-Patterns)

### Example Code

- [Basic Examples](example/lib/screens/basic/)
- [Stream Examples](example/lib/screens/streams/)
- [Error Examples](example/lib/screens/errors/)
- [Advanced Examples](example/lib/screens/advanced/)

### Video Tutorials

- Coming soon!

---

<div align="center">

**Transport agnostic**: Bring your own async function and enjoy consistent pagination UI.

Made with ❤️ by [Genius Systems 24](https://github.com/GeniusSystems24)

[⬆ Back to Top](#custom-pagination)

</div>
