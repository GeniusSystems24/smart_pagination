# Smart Pagination Examples

This document provides practical examples of using the Smart Pagination library.

## Table of Contents

- [Smart Pagination Examples](#smart-pagination-examples)
  - [Table of Contents](#table-of-contents)
  - [1. Basic ListView Example](#1-basic-listview-example)
  - [2. GridView with Custom Styling](#2-gridview-with-custom-styling)
  - [3. PageView for Swipeable Content](#3-pageview-for-swipeable-content)
  - [4. Filter and Search](#4-filter-and-search)
  - [5. Pull-to-Refresh](#5-pull-to-refresh)
  - [6. Custom Error Handling](#6-custom-error-handling)
  - [7. Stream Updates (Real-time)](#7-stream-updates-real-time)
  - [8. Programmatic Scrolling](#8-programmatic-scrolling)
  - [9. Memory Management](#9-memory-management)
  - [10. REST API Integration](#10-rest-api-integration)
  - [Running the Examples](#running-the-examples)

---

## 1. Basic ListView Example

Simple pagination with a REST API:

```dart
import 'package:flutter/material.dart';
import 'package:smart_pagination/pagination.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Model
class Product {
  final String id;
  final String name;
  final double price;
  final String imageUrl;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'].toString(),
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      imageUrl: json['image'] as String,
    );
  }
}

class ProductListPage extends StatelessWidget {
  // Data provider function
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
    } else {
      throw Exception('Failed to load products');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Products')),
      body: SinglePagination<Product>(
        request: PaginationRequest(page: 1, pageSize: 20),
        dataProvider: fetchProducts,
        itemBuilder: (context, items, index) {
          final product = items[index];
          return ListTile(
            leading: Image.network(product.imageUrl, width: 50, height: 50),
            title: Text(product.name),
            subtitle: Text('\$${product.price.toStringAsFixed(2)}'),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () {
              // Navigate to product details
            },
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
class PhotoGalleryPage extends StatelessWidget {
  Future<List<Photo>> fetchPhotos(PaginationRequest request) async {
    // Fetch photos from API
    final response = await http.get(
      Uri.parse('https://api.example.com/photos?page=${request.page}'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['photos'] as List)
          .map((item) => Photo.fromJson(item))
          .toList();
    }
    throw Exception('Failed to load photos');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Photo Gallery')),
      body: SinglePagination.gridView(
        cubit: SinglePaginationCubit<Photo>(
          request: PaginationRequest(page: 1, pageSize: 20),
          dataProvider: fetchPhotos,
        ),
        itemBuilder: (context, items, index) {
          final photo = items[index];
          return Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                    child: Image.network(
                      photo.url,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(8),
                  child: Text(
                    photo.title,
                    style: TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        },
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.75,
        ),
        padding: EdgeInsets.all(16),
      ),
    );
  }
}
```

---

## 3. PageView for Swipeable Content

Create a swipeable carousel:

```dart
class ArticleViewerPage extends StatelessWidget {
  Future<List<Article>> fetchArticles(PaginationRequest request) async {
    // Fetch articles
    final response = await http.get(
      Uri.parse('https://api.example.com/articles?page=${request.page}'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['articles'] as List)
          .map((item) => Article.fromJson(item))
          .toList();
    }
    throw Exception('Failed to load articles');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Articles')),
      body: SinglePagination.pageView(
        cubit: SinglePaginationCubit<Article>(
          request: PaginationRequest(page: 1, pageSize: 1), // One article at a time
          dataProvider: fetchArticles,
        ),
        itemBuilder: (context, items, index) {
          final article = items[index];
          return Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (article.imageUrl != null)
                  Image.network(
                    article.imageUrl!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                SizedBox(height: 16),
                Text(
                  article.title,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  article.author,
                  style: TextStyle(color: Colors.grey),
                ),
                SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: Text(article.content),
                  ),
                ),
              ],
            ),
          );
        },
        onPageChanged: (index) {
          print('Viewing article at index: $index');
        },
      ),
    );
  }
}
```

---

## 4. Filter and Search

Add search and filter functionality:

```dart
class SearchableProductsPage extends StatefulWidget {
  @override
  State<SearchableProductsPage> createState() => _SearchableProductsPageState();
}

class _SearchableProductsPageState extends State<SearchableProductsPage> {
  final filterListener = SinglePaginationFilterChangeListener<Product>();
  final searchController = TextEditingController();

  Future<List<Product>> fetchProducts(PaginationRequest request) async {
    final response = await http.get(
      Uri.parse('https://api.example.com/products?page=${request.page}&limit=${request.pageSize}'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['items'] as List)
          .map((item) => Product.fromJson(item))
          .toList();
    }
    throw Exception('Failed to load products');
  }

  void _onSearchChanged(String query) {
    if (query.isEmpty) {
      filterListener.searchTerm = null;
    } else {
      filterListener.searchTerm = (product) =>
          product.name.toLowerCase().contains(query.toLowerCase());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Search Products'),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(60),
          child: Padding(
            padding: EdgeInsets.all(8),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: () {
                    searchController.clear();
                    _onSearchChanged('');
                  },
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: _onSearchChanged,
            ),
          ),
        ),
      ),
      body: SinglePagination<Product>(
        request: PaginationRequest(page: 1, pageSize: 20),
        dataProvider: fetchProducts,
        filterListeners: [filterListener],
        itemBuilder: (context, items, index) {
          final product = items[index];
          return Card(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: Text(product.name),
              subtitle: Text('\$${product.price.toStringAsFixed(2)}'),
              trailing: Icon(Icons.arrow_forward_ios),
            ),
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

## 5. Pull-to-Refresh

Implement refresh functionality:

```dart
class RefreshableListPage extends StatefulWidget {
  @override
  State<RefreshableListPage> createState() => _RefreshableListPageState();
}

class _RefreshableListPageState extends State<RefreshableListPage> {
  final refreshListener = SinglePaginationRefreshedChangeListener();
  late final SinglePaginationCubit<Product> cubit;

  @override
  void initState() {
    super.initState();
    cubit = SinglePaginationCubit<Product>(
      request: PaginationRequest(page: 1, pageSize: 20),
      dataProvider: fetchProducts,
    );
  }

  Future<List<Product>> fetchProducts(PaginationRequest request) async {
    // Fetch products from API
    final response = await http.get(
      Uri.parse('https://api.example.com/products?page=${request.page}'),
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
      appBar: AppBar(
        title: Text('Pull to Refresh'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              refreshListener.refreshed = true;
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          refreshListener.refreshed = true;
          // Wait a bit for the refresh to complete
          await Future.delayed(Duration(milliseconds: 500));
        },
        child: SinglePagination.cubit(
          cubit: cubit,
          itemBuilderType: PaginateBuilderType.listView,
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
    cubit.dispose();
    super.dispose();
  }
}
```

---

## 6. Custom Error Handling

Handle errors gracefully:

```dart
class ErrorHandlingPage extends StatelessWidget {
  Future<List<Product>> fetchProducts(PaginationRequest request) async {
    try {
      final response = await http.get(
        Uri.parse('https://api.example.com/products?page=${request.page}'),
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['items'] as List)
            .map((item) => Product.fromJson(item))
            .toList();
      } else if (response.statusCode == 404) {
        throw Exception('Products not found');
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } on TimeoutException {
      throw Exception('Request timed out. Please check your internet connection.');
    } catch (e) {
      throw Exception('Failed to load products: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Error Handling')),
      body: SinglePagination<Product>(
        request: PaginationRequest(page: 1, pageSize: 20),
        dataProvider: fetchProducts,
        itemBuilder: (context, items, index) {
          final product = items[index];
          return ListTile(
            title: Text(product.name),
            subtitle: Text('\$${product.price.toStringAsFixed(2)}'),
          );
        },
        onError: (exception) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 80, color: Colors.red),
                  SizedBox(height: 24),
                  Text(
                    'Oops! Something went wrong',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  Text(
                    exception.toString(),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      // Trigger a refresh
                    },
                    icon: Icon(Icons.refresh),
                    label: Text('Try Again'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
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

## 7. Stream Updates (Real-time)

Use streams for real-time updates (e.g., Firebase):

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

class RealtimeMessagesPage extends StatelessWidget {
  Future<List<Message>> fetchMessages(PaginationRequest request) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(request.pageSize ?? 20)
        .get();

    return snapshot.docs
        .map((doc) => Message.fromFirestore(doc))
        .toList();
  }

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
      appBar: AppBar(title: Text('Real-time Messages')),
      body: SinglePagination<Message>(
        request: PaginationRequest(page: 1, pageSize: 50),
        dataProvider: fetchMessages,
        streamProvider: streamMessages, // Real-time updates
        itemBuilder: (context, items, index) {
          final message = items[index];
          return Card(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: CircleAvatar(
                child: Text(message.author[0]),
              ),
              title: Text(message.author),
              subtitle: Text(message.content),
              trailing: Text(
                _formatTime(message.timestamp),
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes}m ago';
    if (difference.inDays < 1) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
  }
}
```

---

## 8. Programmatic Scrolling

Scroll to specific items programmatically:

```dart
class ScrollControlPage extends StatefulWidget {
  @override
  State<ScrollControlPage> createState() => _ScrollControlPageState();
}

class _ScrollControlPageState extends State<ScrollControlPage> {
  late final SinglePaginationController<Product> controller;

  @override
  void initState() {
    super.initState();
    controller = SinglePaginationController.of(
      request: PaginationRequest(page: 1, pageSize: 50),
      dataProvider: fetchProducts,
    );
  }

  Future<List<Product>> fetchProducts(PaginationRequest request) async {
    // Fetch products
    final response = await http.get(
      Uri.parse('https://api.example.com/products?page=${request.page}'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['items'] as List)
          .map((item) => Product.fromJson(item))
          .toList();
    }
    throw Exception('Failed to load products');
  }

  void _scrollToTop() {
    controller.scrollToIndex(0);
  }

  void _scrollToMiddle() {
    controller.scrollToIndex(25);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Scroll Control'),
        actions: [
          IconButton(
            icon: Icon(Icons.arrow_upward),
            onPressed: _scrollToTop,
            tooltip: 'Scroll to top',
          ),
        ],
      ),
      body: SinglePagination.cubit(
        cubit: controller.cubit,
        itemBuilderType: PaginateBuilderType.listView,
        itemBuilder: (context, items, index) {
          final product = items[index];
          return Card(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: Text('#${index + 1}'),
              title: Text(product.name),
              subtitle: Text('\$${product.price.toStringAsFixed(2)}'),
            ),
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'top',
            child: Icon(Icons.arrow_upward),
            onPressed: _scrollToTop,
            tooltip: 'Scroll to top',
          ),
          SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'middle',
            child: Icon(Icons.remove),
            onPressed: _scrollToMiddle,
            tooltip: 'Scroll to middle',
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
```

---

## 9. Memory Management

Optimize memory usage for large lists:

```dart
class MemoryOptimizedPage extends StatelessWidget {
  Future<List<LargeItem>> fetchItems(PaginationRequest request) async {
    // Fetch large items with images
    final response = await http.get(
      Uri.parse('https://api.example.com/large-items?page=${request.page}'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['items'] as List)
          .map((item) => LargeItem.fromJson(item))
          .toList();
    }
    throw Exception('Failed to load items');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Memory Optimized')),
      body: SinglePagination.listView(
        cubit: SinglePaginationCubit<LargeItem>(
          request: PaginationRequest(page: 1, pageSize: 20),
          dataProvider: fetchItems,
          maxPagesInMemory: 3, // Keep only 3 pages in memory (60 items)
          onClear: () {
            print('Cleared old pages from memory');
          },
          onInsertionCallback: (items) {
            print('Loaded ${items.length} items');
          },
        ),
        itemBuilder: (context, items, index) {
          final item = items[index];
          return Card(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                Image.network(
                  item.imageUrl,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  cacheHeight: 400, // Optimize image memory
                ),
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(item.title),
                ),
              ],
            ),
          );
        },
        cacheExtent: 500, // Pre-render items 500 pixels off-screen
      ),
    );
  }
}
```

---

## 10. REST API Integration

Complete example with a real REST API:

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

// API Service
class ApiService {
  static const String baseUrl = 'https://jsonplaceholder.typicode.com';

  Future<List<Post>> fetchPosts(PaginationRequest request) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/posts?_page=${request.page}&_limit=${request.pageSize}',
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Post.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load posts: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}

// Model
class Post {
  final int id;
  final int userId;
  final String title;
  final String body;

  Post({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] as int,
      userId: json['userId'] as int,
      title: json['title'] as String,
      body: json['body'] as String,
    );
  }
}

// Page
class PostsPage extends StatelessWidget {
  final apiService = ApiService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Posts'),
        centerTitle: true,
      ),
      body: SinglePagination<Post>(
        request: PaginationRequest(page: 1, pageSize: 10),
        dataProvider: apiService.fetchPosts,
        itemBuilder: (context, items, index) {
          final post = items[index];
          return Card(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: InkWell(
              onTap: () {
                // Navigate to post details
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PostDetailPage(post: post),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          child: Text('${post.userId}'),
                          backgroundColor: Colors.blue[100],
                          foregroundColor: Colors.blue[900],
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            post.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text(
                      post.body,
                      style: TextStyle(color: Colors.grey[700]),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        loadingWidget: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading posts...'),
            ],
          ),
        ),
        emptyWidget: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inbox, size: 80, color: Colors.grey),
              SizedBox(height: 16),
              Text('No posts available'),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

## Running the Examples

To run these examples:

1. Add the required dependencies to your `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  smart_pagination: ^0.0.1
  http: ^1.1.0
  cloud_firestore: ^4.13.0  # For real-time example
```

2. Import the package:

```dart
import 'package:smart_pagination/pagination.dart';
```

3. Copy any example code and customize it for your needs!

---

For more information, see the [README.md](../README.md) or visit the [GitHub repository](https://github.com/GeniusSystems24/smart_pagination).
