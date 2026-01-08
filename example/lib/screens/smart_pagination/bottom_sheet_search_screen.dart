import 'package:flutter/material.dart';
import 'package:smart_pagination/pagination.dart';

import '../../models/product.dart';
import '../../services/mock_api_service.dart';

/// Example screen demonstrating SmartSearchMultiDropdown with bottomSheet display mode.
///
/// This screen shows how to:
/// - Use bottomSheet mode instead of overlay dropdown
/// - Configure the bottom sheet appearance
/// - Handle selection in fullscreen modal
/// - Compare overlay vs bottomSheet modes
class BottomSheetSearchScreen extends StatefulWidget {
  const BottomSheetSearchScreen({super.key});

  @override
  State<BottomSheetSearchScreen> createState() => _BottomSheetSearchScreenState();
}

class _BottomSheetSearchScreenState extends State<BottomSheetSearchScreen> {
  List<Product> _selectedProducts = [];
  List<Product> _bottomSheetSelectedProducts = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bottom Sheet Search'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showInfoDialog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info Card
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Compare the two display modes: Overlay dropdown vs Bottom sheet. '
                        'Bottom sheet is better for mobile devices.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Section 1: Overlay Mode (Default)
            Text(
              '1. Overlay Mode (Default)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Results appear in a dropdown overlay',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            SmartSearchMultiDropdown<Product, Product>.withProvider(
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
              displayMode: SearchDisplayMode.overlay, // Default
              searchConfig: const SmartSearchConfig(
                debounceDelay: Duration(milliseconds: 500),
              ),
              overlayConfig: const SmartSearchOverlayConfig(
                maxHeight: 250,
              ),
              showSelected: true,
              hintText: 'Search products (overlay)...',
              itemBuilder: (context, product) => ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                  child: Text(product.name[0]),
                ),
                title: Text(product.name),
                subtitle: Text('\$${product.price.toStringAsFixed(2)}'),
              ),
              onSelected: (products, _) {
                setState(() => _selectedProducts = products);
              },
            ),
            const SizedBox(height: 32),

            // Section 2: Bottom Sheet Mode
            Text(
              '2. Bottom Sheet Mode',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Opens a fullscreen bottom sheet for selection',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            SmartSearchMultiDropdown<Product, Product>.withProvider(
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
              displayMode: SearchDisplayMode.bottomSheet, // Bottom sheet mode
              searchConfig: const SmartSearchConfig(
                debounceDelay: Duration(milliseconds: 500),
              ),
              bottomSheetConfig: const SmartSearchBottomSheetConfig(
                title: 'Select Products',
                confirmText: 'Done',
                showSelectedCount: true,
                showClearAllButton: true,
                heightFactor: 0.85,
              ),
              showSelected: true,
              hintText: 'Tap to search products...',
              itemBuilder: (context, product) => ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                  child: Text(product.name[0]),
                ),
                title: Text(product.name),
                subtitle: Text('\$${product.price.toStringAsFixed(2)}'),
              ),
              onSelected: (products, _) {
                setState(() => _bottomSheetSelectedProducts = products);
              },
            ),
            const SizedBox(height: 32),

            // Section 3: Custom Bottom Sheet
            Text(
              '3. Custom Bottom Sheet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'With custom title builder and max selections',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            SmartSearchMultiDropdown<Product, Product>.withProvider(
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
              displayMode: SearchDisplayMode.bottomSheet,
              maxSelections: 3,
              onMaxSelectionsReached: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Maximum 3 products allowed!'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              bottomSheetConfig: SmartSearchBottomSheetConfig(
                titleBuilder: (count) => Row(
                  children: [
                    const Icon(Icons.shopping_cart),
                    const SizedBox(width: 8),
                    Text(
                      count > 0 ? 'Cart ($count/3)' : 'Add to Cart',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
                confirmText: 'Add to Cart',
                clearAllText: 'Remove All',
                heightFactor: 0.75,
                showDragHandle: true,
              ),
              showSelected: true,
              hintText: 'Add products to cart...',
              selectedItemBuilder: (context, product, onRemove) => Chip(
                avatar: CircleAvatar(
                  backgroundColor: Colors.green,
                  child: Text(
                    product.name[0],
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
                label: Text(product.name),
                deleteIcon: const Icon(Icons.close, size: 18),
                onDeleted: onRemove,
              ),
              itemBuilder: (context, product) => ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.green[100],
                  child: Text(product.name[0]),
                ),
                title: Text(product.name),
                subtitle: Text('\$${product.price.toStringAsFixed(2)}'),
                trailing: Text(
                  'In Stock: ${product.stock}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ),
              onSelected: (products, _) {},
            ),
            const SizedBox(height: 32),

            // Summary Card
            if (_selectedProducts.isNotEmpty || _bottomSheetSelectedProducts.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selection Summary',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const Divider(),
                      if (_selectedProducts.isNotEmpty) ...[
                        Text('Overlay Mode: ${_selectedProducts.length} items'),
                        Text(
                          _selectedProducts.map((p) => p.name).join(', '),
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (_bottomSheetSelectedProducts.isNotEmpty) ...[
                        Text('Bottom Sheet Mode: ${_bottomSheetSelectedProducts.length} items'),
                        Text(
                          _bottomSheetSelectedProducts.map((p) => p.name).join(', '),
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Display Modes'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'SearchDisplayMode.overlay',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('• Shows results in a dropdown overlay'),
              Text('• Good for desktop and quick selections'),
              Text('• Default mode'),
              SizedBox(height: 16),
              Text(
                'SearchDisplayMode.bottomSheet',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('• Opens a fullscreen bottom sheet'),
              Text('• Better for mobile devices'),
              Text('• More space for search and results'),
              Text('• Includes confirm/cancel buttons'),
              SizedBox(height: 16),
              Text(
                'SmartSearchBottomSheetConfig',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('• title: Bottom sheet title'),
              Text('• titleBuilder: Custom title widget'),
              Text('• confirmText: Confirm button text'),
              Text('• showSelectedCount: Show count in title'),
              Text('• showClearAllButton: Show clear button'),
              Text('• heightFactor: Height (0.0 to 1.0)'),
              Text('• showDragHandle: Show drag indicator'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
