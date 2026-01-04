# Firebase Examples

Real-time pagination with Firebase Firestore and Firebase Realtime Database.

## Table of Contents

- [Setup](#setup)
- [Firestore Pagination](#firestore-pagination)
- [Firestore Real-time](#firestore-real-time)
- [Firestore Search](#firestore-search)
- [Realtime Database](#realtime-database)
- [Firestore with Filters](#firestore-with-filters)
- [Offline Support](#offline-support)

---

## Setup

Add Firebase dependencies to your `pubspec.yaml`:

```yaml
dependencies:
  firebase_core: ^2.24.0
  cloud_firestore: ^4.14.0
  firebase_database: ^10.4.0
```

Initialize Firebase in your `main.dart`:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}
```

---

## Firestore Pagination

Basic paginated Firestore queries:

```dart
class FirestorePaginationScreen extends StatelessWidget {
  Future<List<Product>> fetchProducts(PaginationRequest request) async {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('products')
        .orderBy('createdAt', descending: true)
        .limit(request.pageSize ?? 20);

    // Use cursor for pagination
    if (request.cursor != null) {
      query = query.startAfterDocument(request.cursor as DocumentSnapshot);
    }

    final snapshot = await query.get();

    // Store last document as cursor for next page
    if (snapshot.docs.isNotEmpty) {
      request.cursor = snapshot.docs.last;
      request.hasMore = snapshot.docs.length == (request.pageSize ?? 20);
    } else {
      request.hasMore = false;
    }

    return snapshot.docs
        .map((doc) => Product.fromFirestore(doc))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Firestore Pagination')),
      body: SmartPagination.listViewWithProvider<Product>(
        request: PaginationRequest(page: 1, pageSize: 20),
        provider: PaginationProvider.future(fetchProducts),
        useCursorPagination: true,
        itemBuilder: (context, items, index) {
          final product = items[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundImage: NetworkImage(product.imageUrl),
            ),
            title: Text(product.name),
            subtitle: Text('\$${product.price.toStringAsFixed(2)}'),
            trailing: Text(
              timeAgo(product.createdAt),
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          );
        },
      ),
    );
  }
}

// Product model with Firestore support
class Product {
  final String id;
  final String name;
  final double price;
  final String imageUrl;
  final DateTime createdAt;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.createdAt,
  });

  factory Product.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Product(
      id: doc.id,
      name: data['name'] as String,
      price: (data['price'] as num).toDouble(),
      imageUrl: data['imageUrl'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'price': price,
      'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
```

---

## Firestore Real-time

Listen to real-time updates from Firestore:

```dart
class FirestoreRealtimeScreen extends StatelessWidget {
  Stream<List<Message>> streamMessages(PaginationRequest request) {
    return FirebaseFirestore.instance
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(request.pageSize ?? 50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Message.fromFirestore(doc))
            .toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Real-time Messages'),
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, size: 8, color: Colors.white),
                SizedBox(width: 4),
                Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
      body: SmartPagination.listViewWithProvider<Message>(
        request: const PaginationRequest(page: 1, pageSize: 50),
        provider: PaginationProvider.stream(streamMessages),
        itemBuilder: (context, items, index) {
          final message = items[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ListTile(
              leading: CircleAvatar(
                backgroundImage: NetworkImage(message.avatarUrl),
              ),
              title: Row(
                children: [
                  Text(
                    message.userName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    formatTime(message.timestamp),
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ),
              subtitle: Text(message.content),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddMessageDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddMessageDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Message'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Enter message...'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              FirebaseFirestore.instance.collection('messages').add({
                'content': controller.text,
                'userName': 'User',
                'avatarUrl': 'https://i.pravatar.cc/150',
                'timestamp': FieldValue.serverTimestamp(),
              });
              Navigator.pop(context);
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }
}
```

---

## Firestore Search

Search Firestore with SmartSearchDropdown:

```dart
class FirestoreSearchScreen extends StatefulWidget {
  @override
  State<FirestoreSearchScreen> createState() => _FirestoreSearchScreenState();
}

class _FirestoreSearchScreenState extends State<FirestoreSearchScreen> {
  User? _selectedUser;

  Future<List<User>> searchUsers(PaginationRequest request) async {
    final query = request.searchQuery?.toLowerCase() ?? '';

    if (query.isEmpty) {
      // Return recent users when no search query
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .orderBy('lastActive', descending: true)
          .limit(request.pageSize ?? 10)
          .get();

      return snapshot.docs.map((doc) => User.fromFirestore(doc)).toList();
    }

    // Search by name (requires composite index)
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('searchKeywords', arrayContains: query)
        .limit(request.pageSize ?? 10)
        .get();

    return snapshot.docs.map((doc) => User.fromFirestore(doc)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search Users')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SmartSearchDropdown<User, User>.withProvider(
              request: const PaginationRequest(page: 1, pageSize: 10),
              provider: PaginationProvider.future(searchUsers),
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
              hintText: 'Search users...',
              showSelected: true,
              itemBuilder: (context, user) => ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(user.avatarUrl),
                ),
                title: Text(user.name),
                subtitle: Text(user.email),
                trailing: user.isOnline
                    ? const Icon(Icons.circle, color: Colors.green, size: 12)
                    : null,
              ),
              onItemSelected: (user) {
                setState(() => _selectedUser = user);
              },
            ),

            if (_selectedUser != null) ...[
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundImage: NetworkImage(_selectedUser!.avatarUrl),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _selectedUser!.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _selectedUser!.email,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {},
                        child: const Text('View Profile'),
                      ),
                    ],
                  ),
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

## Realtime Database

Pagination with Firebase Realtime Database:

```dart
class RealtimeDatabaseScreen extends StatelessWidget {
  Future<List<Post>> fetchPosts(PaginationRequest request) async {
    final ref = FirebaseDatabase.instance.ref('posts');

    Query query = ref.orderByChild('timestamp').limitToLast(request.pageSize ?? 20);

    if (request.cursor != null) {
      query = query.endBefore(request.cursor);
    }

    final snapshot = await query.get();

    if (!snapshot.exists) {
      request.hasMore = false;
      return [];
    }

    final posts = <Post>[];
    for (final child in snapshot.children) {
      posts.add(Post.fromRTDB(child));
    }

    // Reverse to get correct order (newest first)
    posts.reversed.toList();

    if (posts.isNotEmpty) {
      request.cursor = posts.last.timestamp;
      request.hasMore = posts.length == (request.pageSize ?? 20);
    }

    return posts;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Realtime Database')),
      body: SmartPagination.listViewWithProvider<Post>(
        request: PaginationRequest(page: 1, pageSize: 20),
        provider: PaginationProvider.future(fetchPosts),
        useCursorPagination: true,
        itemBuilder: (context, items, index) {
          final post = items[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(child: Text(post.author[0])),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post.author,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            timeAgo(post.timestamp),
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(post.content),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.thumb_up_outlined, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text('${post.likes}', style: TextStyle(color: Colors.grey[600])),
                      const SizedBox(width: 16),
                      Icon(Icons.comment_outlined, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text('${post.comments}', style: TextStyle(color: Colors.grey[600])),
                    ],
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

## Firestore with Filters

Advanced filtering with Firestore:

```dart
class FirestoreFiltersScreen extends StatefulWidget {
  @override
  State<FirestoreFiltersScreen> createState() => _FirestoreFiltersScreenState();
}

class _FirestoreFiltersScreenState extends State<FirestoreFiltersScreen> {
  String _selectedCategory = 'All';
  RangeValues _priceRange = const RangeValues(0, 1000);
  String _sortBy = 'createdAt';
  bool _sortDescending = true;

  final _refreshListener = SmartPaginationRefreshedChangeListener();

  Future<List<Product>> fetchFilteredProducts(PaginationRequest request) async {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('products');

    // Apply category filter
    if (_selectedCategory != 'All') {
      query = query.where('category', isEqualTo: _selectedCategory);
    }

    // Apply price range filter
    query = query
        .where('price', isGreaterThanOrEqualTo: _priceRange.start)
        .where('price', isLessThanOrEqualTo: _priceRange.end);

    // Apply sorting
    query = query.orderBy(_sortBy, descending: _sortDescending);

    // Apply pagination
    query = query.limit(request.pageSize ?? 20);

    if (request.cursor != null) {
      query = query.startAfterDocument(request.cursor as DocumentSnapshot);
    }

    final snapshot = await query.get();

    if (snapshot.docs.isNotEmpty) {
      request.cursor = snapshot.docs.last;
      request.hasMore = snapshot.docs.length == (request.pageSize ?? 20);
    } else {
      request.hasMore = false;
    }

    return snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList();
  }

  void _applyFilters() {
    _refreshListener.refreshed = true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firestore Filters'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterSheet(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Active filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                if (_selectedCategory != 'All')
                  Chip(
                    label: Text(_selectedCategory),
                    onDeleted: () {
                      setState(() => _selectedCategory = 'All');
                      _applyFilters();
                    },
                  ),
                if (_priceRange != const RangeValues(0, 1000))
                  Chip(
                    label: Text('\$${_priceRange.start.toInt()} - \$${_priceRange.end.toInt()}'),
                    onDeleted: () {
                      setState(() => _priceRange = const RangeValues(0, 1000));
                      _applyFilters();
                    },
                  ),
              ],
            ),
          ),

          Expanded(
            child: SmartPagination.listViewWithProvider<Product>(
              request: PaginationRequest(page: 1, pageSize: 20),
              provider: PaginationProvider.future(fetchFilteredProducts),
              refreshListener: _refreshListener,
              useCursorPagination: true,
              itemBuilder: (context, items, index) {
                final product = items[index];
                return ListTile(
                  leading: Image.network(product.imageUrl, width: 50, height: 50),
                  title: Text(product.name),
                  subtitle: Text(product.category),
                  trailing: Text('\$${product.price.toStringAsFixed(2)}'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Category', style: TextStyle(fontWeight: FontWeight.bold)),
              Wrap(
                spacing: 8,
                children: ['All', 'Electronics', 'Clothing', 'Books', 'Home']
                    .map((cat) => ChoiceChip(
                          label: Text(cat),
                          selected: _selectedCategory == cat,
                          onSelected: (_) {
                            setSheetState(() => _selectedCategory = cat);
                          },
                        ))
                    .toList(),
              ),
              const SizedBox(height: 16),
              Text('Price Range: \$${_priceRange.start.toInt()} - \$${_priceRange.end.toInt()}'),
              RangeSlider(
                values: _priceRange,
                min: 0,
                max: 1000,
                divisions: 20,
                onChanged: (values) {
                  setSheetState(() => _priceRange = values);
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {});
                  _applyFilters();
                  Navigator.pop(context);
                },
                child: const Text('Apply Filters'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _refreshListener.dispose();
    super.dispose();
  }
}
```

---

## Offline Support

Firestore with offline persistence:

```dart
class OfflineSupportScreen extends StatefulWidget {
  @override
  State<OfflineSupportScreen> createState() => _OfflineSupportScreenState();
}

class _OfflineSupportScreenState extends State<OfflineSupportScreen> {
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    // Monitor connectivity
    Connectivity().onConnectivityChanged.listen((result) {
      setState(() => _isOnline = result != ConnectivityResult.none);
    });
  }

  Stream<List<Product>> streamProducts(PaginationRequest request) {
    return FirebaseFirestore.instance
        .collection('products')
        .orderBy('createdAt', descending: true)
        .limit(request.pageSize ?? 20)
        .snapshots(includeMetadataChanges: true)
        .map((snapshot) {
      // Check if data is from cache
      final isFromCache = snapshot.metadata.isFromCache;

      if (isFromCache && mounted) {
        // Show indicator that data is cached
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() {});
        });
      }

      return snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Support'),
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _isOnline ? Colors.green : Colors.orange,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isOnline ? Icons.cloud_done : Icons.cloud_off,
                  size: 16,
                  color: Colors.white,
                ),
                const SizedBox(width: 4),
                Text(
                  _isOnline ? 'Online' : 'Offline',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (!_isOnline)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.orange[100],
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange[800]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You\'re offline. Showing cached data.',
                      style: TextStyle(color: Colors.orange[800]),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: SmartPagination.listViewWithProvider<Product>(
              request: const PaginationRequest(page: 1, pageSize: 20),
              provider: PaginationProvider.stream(streamProducts),
              itemBuilder: (context, items, index) {
                final product = items[index];
                return ListTile(
                  leading: Image.network(
                    product.imageUrl,
                    width: 50,
                    height: 50,
                    errorBuilder: (_, __, ___) => Container(
                      width: 50,
                      height: 50,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image_not_supported),
                    ),
                  ),
                  title: Text(product.name),
                  subtitle: Text('\$${product.price.toStringAsFixed(2)}'),
                  trailing: !_isOnline
                      ? Icon(Icons.cached, color: Colors.grey[400], size: 16)
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

[Back to Examples](../example.md)
