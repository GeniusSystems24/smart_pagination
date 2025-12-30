import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:smart_pagination/pagination.dart';

/// Model for Firestore Product with cache status
class OfflineProduct {
  final String id;
  final String name;
  final double price;
  final String imageUrl;
  final bool isFromCache;

  OfflineProduct({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    this.isFromCache = false,
  });

  factory OfflineProduct.fromFirestore(
    DocumentSnapshot doc, {
    bool isFromCache = false,
  }) {
    final data = doc.data() as Map<String, dynamic>;
    return OfflineProduct(
      id: doc.id,
      name: data['name'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      imageUrl: data['imageUrl'] ?? '',
      isFromCache: isFromCache,
    );
  }
}

/// Demonstrates Firestore with offline persistence and cache indicators
class OfflineSupportScreen extends StatefulWidget {
  const OfflineSupportScreen({super.key});

  @override
  State<OfflineSupportScreen> createState() => _OfflineSupportScreenState();
}

class _OfflineSupportScreenState extends State<OfflineSupportScreen> {
  bool _isFirebaseInitialized = false;
  String? _initError;

  // Stream controller for products
  StreamController<List<OfflineProduct>>? _streamController;
  StreamSubscription<QuerySnapshot>? _firestoreSubscription;

  // Connection status
  bool _isOnline = true;
  int _cachedCount = 0;

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

      // Enable offline persistence (enabled by default on mobile)
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );

      setState(() {
        _isFirebaseInitialized = true;
      });

      _setupProductStream();
    } catch (e) {
      setState(() {
        _initError = e.toString();
      });
    }
  }

  void _setupProductStream() {
    _streamController = StreamController<List<OfflineProduct>>.broadcast();

    // Listen to Firestore snapshots
    _firestoreSubscription = FirebaseFirestore.instance
        .collection('products')
        .orderBy('name')
        .limit(30)
        .snapshots(includeMetadataChanges: true)
        .listen((snapshot) {
      // Check if data is from cache
      final isFromCache = snapshot.metadata.isFromCache;
      final hasPendingWrites = snapshot.metadata.hasPendingWrites;

      setState(() {
        _isOnline = !isFromCache;
        _cachedCount = isFromCache ? snapshot.docs.length : 0;
      });

      // Convert to model objects
      final products = snapshot.docs
          .map((doc) => OfflineProduct.fromFirestore(
                doc,
                isFromCache: isFromCache || hasPendingWrites,
              ))
          .toList();

      _streamController?.add(products);
    }, onError: (error) {
      _streamController?.addError(error);
    });
  }

  Stream<List<OfflineProduct>> streamProducts(PaginationRequest request) {
    return _streamController?.stream ?? const Stream.empty();
  }

  @override
  void dispose() {
    _firestoreSubscription?.cancel();
    _streamController?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Support'),
        actions: [
          // Connection status indicator
          Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _isOnline ? Colors.green : Colors.orange,
              borderRadius: BorderRadius.circular(16),
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
                  _isOnline ? 'Online' : 'Cached',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
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
        // Status banner
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          color: _isOnline ? Colors.green.shade50 : Colors.orange.shade50,
          child: Row(
            children: [
              Icon(
                _isOnline ? Icons.wifi : Icons.wifi_off,
                color: _isOnline ? Colors.green.shade700 : Colors.orange.shade700,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _isOnline
                      ? 'Connected - Showing live data from Firestore'
                      : 'Offline - Showing cached data',
                  style: TextStyle(
                    color: _isOnline
                        ? Colors.green.shade700
                        : Colors.orange.shade700,
                    fontSize: 13,
                  ),
                ),
              ),
              if (!_isOnline && _cachedCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$_cachedCount cached',
                    style: TextStyle(
                      color: Colors.orange.shade800,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Info card
        Padding(
          padding: const EdgeInsets.all(16),
          child: Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Firestore Offline Persistence',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'Data is automatically cached for offline access',
                          style: TextStyle(
                            color: Colors.blue.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Products list
        Expanded(
          child: SmartPagination<OfflineProduct>.listViewWithProvider(
            request: const PaginationRequest(page: 1, pageSize: 30),
            provider: PaginationProvider.stream(streamProducts),
            itemBuilder: (context, items, index) {
              final product = items[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  leading: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          product.imageUrl,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildPlaceholder(),
                        ),
                      ),
                      if (product.isFromCache)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(
                              Icons.cached,
                              size: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                  title: Text(product.name),
                  subtitle: Text(
                    '\$${product.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  trailing: product.isFromCache
                      ? Tooltip(
                          message: 'From local cache',
                          child: Icon(
                            Icons.cached,
                            color: Colors.orange.shade400,
                            size: 20,
                          ),
                        )
                      : Tooltip(
                          message: 'From server',
                          child: Icon(
                            Icons.cloud_done,
                            color: Colors.green.shade400,
                            size: 20,
                          ),
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
                  Text('Loading products...'),
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_off, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text(
                    'No cached data available',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Connect to the internet to load data',
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
              '3. Run: flutterfire configure',
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

  Widget _buildPlaceholder() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.image, color: Colors.grey.shade400),
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Firestore Offline Support'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('This example demonstrates:'),
            SizedBox(height: 12),
            Text('• Firestore offline persistence'),
            Text('• Automatic data caching'),
            Text('• Cache vs server indicators'),
            Text('• Metadata change detection'),
            Text('• Seamless offline/online transitions'),
            SizedBox(height: 12),
            Text(
              'Firestore automatically caches data and syncs '
              'when connection is restored.',
              style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
            ),
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
