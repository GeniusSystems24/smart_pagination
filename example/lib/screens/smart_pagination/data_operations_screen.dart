import 'package:flutter/material.dart';
import 'package:smart_pagination/pagination.dart';

import '../../models/product.dart';
import '../../services/mock_api_service.dart';

/// Example demonstrating programmatic data operations on the pagination cubit.
///
/// This screen shows how to:
/// - Insert items (single and multiple)
/// - Remove items (by item, index, or condition)
/// - Update items (single and multiple)
/// - Clear all items
/// - Reload data
/// - Set items directly
/// - Access current items
class DataOperationsScreen extends StatefulWidget {
  const DataOperationsScreen({super.key});

  @override
  State<DataOperationsScreen> createState() => _DataOperationsScreenState();
}

class _DataOperationsScreenState extends State<DataOperationsScreen> {
  late SmartPaginationCubit<Product, PaginationRequest> _cubit;

  int _productCounter = 1000; // For generating unique product IDs

  @override
  void initState() {
    super.initState();
    _cubit = SmartPaginationCubit<Product, PaginationRequest>(
      request: const PaginationRequest(page: 1, pageSize: 10),
      provider: PaginationProvider.future(
        (request) => MockApiService.fetchProducts(
          PaginationRequest(
            page: request.page,
            pageSize: request.pageSize ?? 10,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  // Generate a new product for testing
  Product _generateProduct() {
    _productCounter++;
    return Product(
      id: _productCounter.toString(),
      name: 'New Product $_productCounter',
      description: 'Added programmatically',
      price: 99.99,
      imageUrl: 'https://via.placeholder.com/150',
      category: '',
      createdAt: DateTime.now(),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  // Insert single item at the beginning
  Future<void> _insertItem() async {
    final product = _generateProduct();
    final success = await _cubit.insertEmit(product, index: 0);
    _showSnackBar(success ? 'Inserted: ${product.name}' : 'Failed to insert');
  }

  // Insert multiple items
  Future<void> _insertMultiple() async {
    final products = List.generate(3, (_) => _generateProduct());
    final success = await _cubit.insertAllEmit(products, index: 0);
    _showSnackBar(
        success ? 'Inserted ${products.length} products' : 'Failed to insert');
  }

  // Remove first item
  Future<void> _removeFirst() async {
    final success = await _cubit.removeAtEmit(0);
    _showSnackBar(success ? 'Removed first item' : 'No items to remove');
  }

  // Remove item by condition (price > 50)
  Future<void> _removeExpensive() async {
    final success = await _cubit.removeWhereEmit((item) => item.price > 50);
    _showSnackBar(
        success ? 'Removed expensive products' : 'No expensive products');
  }

  // Update first item
  Future<void> _updateFirst() async {
    final success = await _cubit.updateItemEmit(
      (item) =>
          _cubit.currentItems.isNotEmpty && item == _cubit.currentItems[0],
      (item) => Product(
        id: item.id,
        name: '${item.name} (Updated)',
        description: 'Price increased!',
        price: item.price * 1.1,
        imageUrl: item.imageUrl,
        createdAt: DateTime.now(),
        category: '',
      ),
    );
    _showSnackBar(success ? 'Updated first item' : 'No items to update');
  }

  // Update all items (apply discount)
  Future<void> _applyDiscount() async {
    final success = await _cubit.updateWhereEmit(
      (item) => true, // All items
      (item) => Product(
        id: item.id,
        name: item.name,
        description: item.description,
        price: item.price * 0.9, // 10% discount
        imageUrl: item.imageUrl,
        category: '',
        createdAt: DateTime.now(),
      ),
    );
    _showSnackBar(success ? 'Applied 10% discount' : 'No items to discount');
  }

  // Refresh first item from server
  Future<void> _refreshFirst() async {
    final success = await _cubit.refreshItem(
      (item) =>
          _cubit.currentItems.isNotEmpty && item == _cubit.currentItems[0],
      (currentItem) async {
        // Simulate server refresh
        await Future.delayed(const Duration(milliseconds: 500));
        return Product(
          id: currentItem.id,
          name: '${currentItem.name} (Refreshed)',
          description: 'Refreshed from server',
          price: currentItem.price,
          imageUrl: currentItem.imageUrl,
          category: currentItem.category,
          createdAt: DateTime.now(),
        );
      },
    );
    _showSnackBar(success ? 'Refreshed first item' : 'No items to refresh');
  }

  // Clear all items
  Future<void> _clearAll() async {
    await _cubit.clearItems();
    _showSnackBar('Cleared all items');
  }

  // Reload from server
  void _reload() {
    _cubit.reload();
    _showSnackBar('Reloading...');
  }

  // Set custom items
  Future<void> _setCustomItems() async {
    final products = List.generate(
      5,
      (index) => Product(
        id: 'custom-$index',
        name: 'Custom Product ${index + 1}',
        description: 'Set via setItems()',
        price: (index + 1) * 10.0,
        imageUrl: 'https://via.placeholder.com/150',
        category: '',
        createdAt: DateTime.now(),
      ),
    );
    await _cubit.setItems(products);
    _showSnackBar('Set ${products.length} custom items');
  }

  // Show current items count
  void _showCurrentItems() {
    final items = _cubit.currentItems;
    _showSnackBar('Current items: ${items.length}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Operations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Operations buttons
          Container(
            padding: const EdgeInsets.all(8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _OperationButton(
                    label: 'Insert',
                    icon: Icons.add,
                    color: Colors.green,
                    onPressed: _insertItem,
                  ),
                  _OperationButton(
                    label: 'Insert 3',
                    icon: Icons.playlist_add,
                    color: Colors.green,
                    onPressed: _insertMultiple,
                  ),
                  _OperationButton(
                    label: 'Remove 1st',
                    icon: Icons.remove,
                    color: Colors.red,
                    onPressed: _removeFirst,
                  ),
                  _OperationButton(
                    label: 'Remove >50\$',
                    icon: Icons.delete_sweep,
                    color: Colors.red,
                    onPressed: _removeExpensive,
                  ),
                  _OperationButton(
                    label: 'Update 1st',
                    icon: Icons.edit,
                    color: Colors.blue,
                    onPressed: _updateFirst,
                  ),
                  _OperationButton(
                    label: 'Discount',
                    icon: Icons.local_offer,
                    color: Colors.orange,
                    onPressed: _applyDiscount,
                  ),
                  _OperationButton(
                    label: 'Refresh 1st',
                    icon: Icons.sync,
                    color: Colors.cyan,
                    onPressed: _refreshFirst,
                  ),
                  _OperationButton(
                    label: 'Clear',
                    icon: Icons.clear_all,
                    color: Colors.grey,
                    onPressed: _clearAll,
                  ),
                  _OperationButton(
                    label: 'Reload',
                    icon: Icons.refresh,
                    color: Colors.purple,
                    onPressed: _reload,
                  ),
                  _OperationButton(
                    label: 'Set Items',
                    icon: Icons.list,
                    color: Colors.teal,
                    onPressed: _setCustomItems,
                  ),
                  _OperationButton(
                    label: 'Count',
                    icon: Icons.numbers,
                    color: Colors.indigo,
                    onPressed: _showCurrentItems,
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          // Products list
          Expanded(
            child: SmartPagination.listViewWithCubit(
              cubit: _cubit,
              itemKeyBuilder: (item, index) => item.id,
              itemBuilder: (context, items, index) {
                final product = items[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.shade100,
                      child: Text(
                        product.id.length > 2
                            ? product.id.substring(0, 2)
                            : product.id,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    title: Text(product.name),
                    subtitle: Text(product.description),
                    trailing: Text(
                      '\$${product.price.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: product.price > 50 ? Colors.red : Colors.green,
                      ),
                    ),
                    onLongPress: () async {
                      // Remove item on long press
                      final success = await _cubit.removeItemEmit(product);
                      if (success) _showSnackBar('Removed: ${product.name}');
                    },
                  ),
                );
              },
              firstPageEmptyBuilder: (context) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.inbox, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text('No products'),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _reload,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reload'),
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

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Data Operations'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Available operations (all return Future<bool>):',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• insertEmit() - Add single item'),
              Text('• insertAllEmit() - Add multiple items'),
              Text('• removeItemEmit() - Remove by item'),
              Text('• removeAtEmit() - Remove by index'),
              Text('• removeWhereEmit() - Remove by condition'),
              Text('• updateItemEmit() - Update single item'),
              Text('• updateWhereEmit() - Update multiple items'),
              Text('• refreshItem() - Refresh item from server'),
              Text('• clearItems() - Clear all items'),
              Text('• reload() - Reload from server'),
              Text('• setItems() - Set custom items'),
              Text('• currentItems - Get current items'),
              SizedBox(height: 16),
              Text('Tip:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Long press an item to remove it!'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }
}

class _OperationButton extends StatelessWidget {
  const _OperationButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16),
        label: Text(label, style: const TextStyle(fontSize: 12)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          minimumSize: Size.zero,
        ),
      ),
    );
  }
}
