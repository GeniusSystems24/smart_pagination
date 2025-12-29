import 'dart:async';
import 'package:flutter/material.dart';
import 'package:smart_pagination/pagination.dart';

/// Mock Product for Firestore filters example
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
}

/// Simulates Firestore with advanced filtering and composite queries
class FirestoreFiltersScreen extends StatefulWidget {
  const FirestoreFiltersScreen({super.key});

  @override
  State<FirestoreFiltersScreen> createState() => _FirestoreFiltersScreenState();
}

class _FirestoreFiltersScreenState extends State<FirestoreFiltersScreen> {
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

  // Simulated Firestore products
  final List<FilteredProduct> _allProducts = List.generate(
    80,
    (index) => FilteredProduct(
      id: 'product_$index',
      name: '${['Smart', 'Premium', 'Basic', 'Pro', 'Ultra'][index % 5]} '
          '${['Watch', 'Phone', 'Laptop', 'Camera', 'Speaker', 'Headphones'][index % 6]}',
      category: ['Electronics', 'Clothing', 'Books', 'Home', 'Sports'][index % 5],
      price: 20.0 + (index * 12.5) % 480,
      rating: 3.0 + (index % 20) / 10,
      imageUrl: 'https://picsum.photos/seed/product$index/100/100',
      createdAt: DateTime.now().subtract(Duration(days: index)),
    ),
  );

  /// Simulates Firestore composite query with filters
  Future<List<FilteredProduct>> fetchFilteredProducts(
      PaginationRequest request) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 700));

    // Start with all products
    var filtered = List<FilteredProduct>.from(_allProducts);

    // Apply category filter
    if (_selectedCategory != 'All') {
      filtered = filtered.where((p) => p.category == _selectedCategory).toList();
    }

    // Apply price range filter
    filtered = filtered
        .where((p) =>
            p.price >= _priceRange.start && p.price <= _priceRange.end)
        .toList();

    // Apply sorting
    filtered.sort((a, b) {
      int result;
      switch (_sortBy) {
        case 'price':
          result = a.price.compareTo(b.price);
          break;
        case 'rating':
          result = a.rating.compareTo(b.rating);
          break;
        case 'name':
          result = a.name.compareTo(b.name);
          break;
        default:
          result = a.createdAt.compareTo(b.createdAt);
      }
      return _sortDescending ? -result : result;
    });

    // Apply pagination
    final pageSize = request.pageSize ?? 20;
    final page = request.page;
    final startIndex = (page - 1) * pageSize;
    final endIndex = (startIndex + pageSize).clamp(0, filtered.length);

    if (startIndex >= filtered.length) {
      return [];
    }

    return filtered.sublist(startIndex, endIndex);
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
                          setState(
                              () => _priceRange = const RangeValues(0, 500));
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
                    _sortDescending
                        ? Icons.arrow_downward
                        : Icons.arrow_upward,
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
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
              emptyWidget: Center(
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
            ),
          ),
        ],
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

  @override
  void dispose() {
    _refreshListener.dispose();
    super.dispose();
  }
}
