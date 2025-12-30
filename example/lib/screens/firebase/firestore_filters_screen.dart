import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:smart_pagination/pagination.dart';

/// Model for Firestore Product with filters
class FilteredProduct {
  final String id;
  final String name;
  final String category;
  final double price;
  final double rating;
  final String imageUrl;
  final DateTime createdAt;

  FilteredProduct({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.rating,
    required this.imageUrl,
    required this.createdAt,
  });

  factory FilteredProduct.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FilteredProduct(
      id: doc.id,
      name: data['name'] ?? '',
      category: data['category'] ?? 'Other',
      price: (data['price'] ?? 0).toDouble(),
      rating: (data['rating'] ?? 0).toDouble(),
      imageUrl: data['imageUrl'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

/// Demonstrates Firestore with advanced filtering and composite queries
class FirestoreFiltersScreen extends StatefulWidget {
  const FirestoreFiltersScreen({super.key});

  @override
  State<FirestoreFiltersScreen> createState() => _FirestoreFiltersScreenState();
}

class _FirestoreFiltersScreenState extends State<FirestoreFiltersScreen> {
  bool _isFirebaseInitialized = false;
  String? _initError;

  String _selectedCategory = 'All';
  RangeValues _priceRange = const RangeValues(0, 500);
  String _sortBy = 'createdAt';
  bool _sortDescending = true;

  final _refreshListener = SmartPaginationRefreshedChangeListener();

  final List<String> _categories = [
    'All',
    'Electronics',
    'Clothing',
    'Books',
    'Home',
    'Sports',
  ];

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

  /// Fetches filtered products from Firestore using composite queries
  Future<List<FilteredProduct>> fetchFilteredProducts(
      PaginationRequest request) async {
    final firestore = FirebaseFirestore.instance;
    final pageSize = request.pageSize ?? 15;

    // Build base query
    Query<Map<String, dynamic>> query = firestore.collection('products');

    // Apply category filter (Firestore where clause)
    if (_selectedCategory != 'All') {
      query = query.where('category', isEqualTo: _selectedCategory);
    }

    // Apply price range filter (Firestore composite query)
    // Note: This requires a composite index in Firestore
    query = query
        .where('price', isGreaterThanOrEqualTo: _priceRange.start)
        .where('price', isLessThanOrEqualTo: _priceRange.end);

    // Apply sorting
    query = query.orderBy(_sortBy, descending: _sortDescending);

    // Apply pagination limit
    query = query.limit(pageSize);

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
        .map((doc) => FilteredProduct.fromFirestore(doc))
        .toList();
  }

  void _applyFilters() {
    _lastDocument = null; // Reset pagination when filters change
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
        // Active filters
        if (_selectedCategory != 'All' ||
            _priceRange != const RangeValues(0, 500))
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.grey.shade100,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  if (_selectedCategory != 'All')
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Chip(
                        label: Text(_selectedCategory),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () {
                          setState(() => _selectedCategory = 'All');
                          _applyFilters();
                        },
                      ),
                    ),
                  if (_priceRange != const RangeValues(0, 500))
                    Chip(
                      label: Text(
                        '\$${_priceRange.start.toInt()} - \$${_priceRange.end.toInt()}',
                      ),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () {
                        setState(() => _priceRange = const RangeValues(0, 500));
                        _applyFilters();
                      },
                    ),
                ],
              ),
            ),
          ),

        // Sort bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                'Sort by:',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: _sortBy,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: 'createdAt', child: Text('Date')),
                  DropdownMenuItem(value: 'price', child: Text('Price')),
                  DropdownMenuItem(value: 'rating', child: Text('Rating')),
                  DropdownMenuItem(value: 'name', child: Text('Name')),
                ],
                onChanged: (value) {
                  setState(() => _sortBy = value!);
                  _applyFilters();
                },
              ),
              IconButton(
                icon: Icon(
                  _sortDescending ? Icons.arrow_downward : Icons.arrow_upward,
                  size: 20,
                ),
                onPressed: () {
                  setState(() => _sortDescending = !_sortDescending);
                  _applyFilters();
                },
              ),
            ],
          ),
        ),

        // Products list
        Expanded(
          child: SmartPagination<FilteredProduct>.listViewWithProvider(
            request: const PaginationRequest(page: 1, pageSize: 15),
            provider: PaginationProvider.future(fetchFilteredProducts),
            refreshListener: _refreshListener,
            itemBuilder: (context, items, index) {
              final product = items[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      product.imageUrl,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 56,
                        height: 56,
                        color: Colors.grey.shade200,
                        child: Icon(Icons.image, color: Colors.grey.shade400),
                      ),
                    ),
                  ),
                  title: Text(product.name),
                  subtitle: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          product.category,
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.star, size: 14, color: Colors.amber.shade600),
                      Text(
                        ' ${product.rating.toStringAsFixed(1)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  trailing: Text(
                    '\$${product.price.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                ),
              );
            },
            firstPageEmptyBuilder: (context) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text(
                    'No products match your filters',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedCategory = 'All';
                        _priceRange = const RangeValues(0, 500);
                      });
                      _applyFilters();
                    },
                    child: const Text('Clear filters'),
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
                      'Query Error',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This query may require a composite index.\n'
                      'Check the Firebase console for index creation.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        error.toString(),
                        style: TextStyle(color: Colors.red.shade700, fontSize: 11),
                      ),
                    ),
                    const SizedBox(height: 16),
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

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Text(
                    'Filters',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      setSheetState(() {
                        _selectedCategory = 'All';
                        _priceRange = const RangeValues(0, 500);
                      });
                    },
                    child: const Text('Reset'),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Category
              const Text(
                'Category',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categories
                    .map((cat) => ChoiceChip(
                          label: Text(cat),
                          selected: _selectedCategory == cat,
                          onSelected: (_) {
                            setSheetState(() => _selectedCategory = cat);
                          },
                        ))
                    .toList(),
              ),
              const SizedBox(height: 24),

              // Price range
              Row(
                children: [
                  const Text(
                    'Price Range',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  Text(
                    '\$${_priceRange.start.toInt()} - \$${_priceRange.end.toInt()}',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
              RangeSlider(
                values: _priceRange,
                min: 0,
                max: 500,
                divisions: 50,
                labels: RangeLabels(
                  '\$${_priceRange.start.toInt()}',
                  '\$${_priceRange.end.toInt()}',
                ),
                onChanged: (values) {
                  setSheetState(() => _priceRange = values);
                },
              ),

              // Composite index note
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.amber.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Composite queries require Firestore indexes',
                        style: TextStyle(color: Colors.amber.shade900, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: () {
                  setState(() {});
                  _applyFilters();
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
                child: const Text('Apply Filters'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Firestore Composite Queries'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('This example demonstrates:'),
            SizedBox(height: 12),
            Text('• where() for equality filters'),
            Text('• Range queries (>=, <=)'),
            Text('• orderBy() for sorting'),
            Text('• Composite indexes for complex queries'),
            Text('• Cursor-based pagination'),
            SizedBox(height: 12),
            Text(
              'Note: Complex queries require composite indexes '
              'to be created in the Firebase console.',
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

  @override
  void dispose() {
    _refreshListener.dispose();
    super.dispose();
  }
}
