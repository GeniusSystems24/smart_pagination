import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:smart_pagination/pagination.dart';

/// Model for Firestore Product document
class FirestoreProduct {
  final String id;
  final String name;
  final double price;
  final String imageUrl;
  final DateTime createdAt;

  FirestoreProduct({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.createdAt,
  });

  factory FirestoreProduct.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FirestoreProduct(
      id: doc.id,
      name: data['name'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      imageUrl: data['imageUrl'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
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

/// Demonstrates Firestore cursor-based pagination with SmartPagination
class FirestorePaginationScreen extends StatefulWidget {
  const FirestorePaginationScreen({super.key});

  @override
  State<FirestorePaginationScreen> createState() =>
      _FirestorePaginationScreenState();
}

class _FirestorePaginationScreenState extends State<FirestorePaginationScreen> {
  bool _isFirebaseInitialized = false;
  String? _initError;

  // Store last document for cursor-based pagination
  DocumentSnapshot? _lastDocument;

  @override
  void initState() {
    super.initState();
    _initializeFirebase();
  }

  Future<void> _initializeFirebase() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      setState(() {
        _isFirebaseInitialized = true;
      });
    } catch (e) {
      setState(() {
        _initError = e.toString();
      });
    }
  }

  /// Fetches products from Firestore using cursor-based pagination
  Future<List<FirestoreProduct>> fetchProducts(PaginationRequest request) async {
    final firestore = FirebaseFirestore.instance;
    final pageSize = request.pageSize ?? 20;

    // Build query with ordering (required for cursor pagination)
    Query<Map<String, dynamic>> query = firestore
        .collection('products')
        .orderBy('createdAt', descending: true)
        .limit(pageSize);

    // Apply cursor if not first page
    if (request.page > 1 && _lastDocument != null) {
      query = query.startAfterDocument(_lastDocument!);
    }

    // Execute query
    final snapshot = await query.get();

    // Store last document for next page
    if (snapshot.docs.isNotEmpty) {
      _lastDocument = snapshot.docs.last;
    }

    // Convert to model objects
    return snapshot.docs
        .map((doc) => FirestoreProduct.fromFirestore(doc))
        .toList();
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firestore Pagination'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(context),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // Show error if Firebase initialization failed
    if (_initError != null) {
      return _buildFirebaseError();
    }

    // Show loading while initializing
    if (!_isFirebaseInitialized) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Initializing Firebase...'),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Info banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          color: Colors.blue.shade50,
          child: Row(
            children: [
              Icon(Icons.cloud, color: Colors.blue.shade700, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Cloud Firestore with cursor-based pagination (startAfterDocument)',
                  style: TextStyle(color: Colors.blue.shade700, fontSize: 13),
                ),
              ),
            ],
          ),
        ),

        // Product list
        Expanded(
          child: SmartPagination<FirestoreProduct>.listViewWithProvider(
            request: const PaginationRequest(page: 1, pageSize: 20),
            provider: PaginationProvider.future(fetchProducts),
            itemBuilder: (context, items, index) {
              final product = items[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      product.imageUrl,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 50,
                        height: 50,
                        color: Colors.grey.shade200,
                        child: Icon(Icons.image, color: Colors.grey.shade400),
                      ),
                    ),
                  ),
                  title: Text(product.name),
                  subtitle: Text(
                    '\$${product.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  trailing: Text(
                    _timeAgo(product.createdAt),
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ),
              );
            },
            firstPageLoadingBuilder: (context) => const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading from Firestore...'),
                ],
              ),
            ),
            firstPageEmptyBuilder: (context) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text('No products found'),
                  const SizedBox(height: 8),
                  Text(
                    'Add products to your "products" collection',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            firstPageErrorBuilder: (context, error, retry) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load products',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: retry,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFirebaseError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: Colors.orange.shade300),
            const SizedBox(height: 24),
            const Text(
              'Firebase Not Configured',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'To use this example, configure Firebase:\n\n'
              '1. Create a Firebase project\n'
              '2. Add your app to the project\n'
              '3. Download google-services.json (Android)\n'
              '   or GoogleService-Info.plist (iOS)\n'
              '4. Run: flutterfire configure',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _initError ?? 'Unknown error',
                style: TextStyle(color: Colors.red.shade700, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Firestore Pagination'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('This example demonstrates:'),
            SizedBox(height: 12),
            Text('• Cloud Firestore integration'),
            Text('• Cursor-based pagination with startAfterDocument()'),
            Text('• Ordered queries (by createdAt)'),
            Text('• Document to model conversion'),
            Text('• Error handling for Firebase'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
