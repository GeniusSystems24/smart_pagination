import 'package:flutter/material.dart';
import 'package:smart_pagination/pagination.dart';

import '../../models/product.dart';
import '../../services/mock_api_service.dart';

/// Example screen demonstrating SmartSearchMultiDropdown.
///
/// This screen shows how to:
/// - Select multiple items from search results
/// - Display selected items below the search box
/// - Remove individual items from selection
/// - Configure max selections limit
/// - Use custom selected item builders
class MultiSelectSearchScreen extends StatefulWidget {
  const MultiSelectSearchScreen({super.key});

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
              tooltip: 'Clear all',
            ),
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
                        'Search and select multiple products. '
                        'Selected items appear below the search box.',
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

            // Section 1: Basic Multi-Select
            Text(
              'Basic Multi-Select',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
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
              overlayConfig: const SmartSearchOverlayConfig(
                maxHeight: 250,
                borderRadius: 12,
              ),
              showSelected: true,
              itemBuilder: (context, product) => ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: Text(product.name[0].toUpperCase()),
                ),
                title: Text(product.name),
                subtitle: Text(product.description),
                trailing: Text(
                  '\$${product.price.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              onSelectionChanged: (products) {
                setState(() => _selectedProducts = products);
              },
            ),
            const SizedBox(height: 32),

            // Section 2: With Max Selections
            Text(
              'With Max Selections (3)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
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
              overlayConfig: const SmartSearchOverlayConfig(
                maxHeight: 250,
                borderRadius: 12,
              ),
              showSelected: true,
              maxSelections: 3,
              itemBuilder: (context, product) => ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                  child: Text(product.name[0].toUpperCase()),
                ),
                title: Text(product.name),
                subtitle: Text('\$${product.price.toStringAsFixed(2)}'),
              ),
              onSelectionChanged: (products) {
                if (products.length == 3) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Maximum 3 items can be selected'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 32),

            // Section 3: Custom Selected Item Builder
            Text(
              'Custom Chip Style',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
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
              overlayConfig: const SmartSearchOverlayConfig(
                maxHeight: 250,
                borderRadius: 12,
              ),
              showSelected: true,
              selectedItemsWrap: true,
              selectedItemsSpacing: 8,
              selectedItemsRunSpacing: 8,
              itemBuilder: (context, product) => ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
                  child: Text(product.name[0].toUpperCase()),
                ),
                title: Text(product.name),
                subtitle: Text(product.description),
              ),
              selectedItemBuilder: (context, product, onRemove) => Chip(
                avatar: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Text(
                    product.name[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
                label: Text(product.name),
                deleteIcon: const Icon(Icons.close, size: 18),
                onDeleted: onRemove,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              ),
              onSelectionChanged: (products) {
                // Handle selection change
              },
            ),
            const SizedBox(height: 32),

            // Selected Products Summary
            if (_selectedProducts.isNotEmpty) ...[
              Text(
                'Selected Products Summary',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total: ${_selectedProducts.length} items',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Divider(),
                      ...List.generate(_selectedProducts.length, (index) {
                        final product = _selectedProducts[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(product.name),
                              Text(
                                '\$${product.price.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Price:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '\$${_selectedProducts.fold<double>(0, (sum, p) => sum + p.price).toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
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

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info_outline),
            SizedBox(width: 8),
            Text('v2.4.0 Features'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _FeatureItem(
                icon: Icons.checklist,
                title: 'Multi-Select',
                description: 'Select multiple items from search results',
              ),
              _FeatureItem(
                icon: Icons.search,
                title: 'Continuous Search',
                description: 'Search box stays visible after selection',
              ),
              _FeatureItem(
                icon: Icons.view_list,
                title: 'Selected Items Display',
                description: 'Shows all selected items below search box',
              ),
              _FeatureItem(
                icon: Icons.delete_outline,
                title: 'Individual Remove',
                description: 'Remove button on each selected item',
              ),
              _FeatureItem(
                icon: Icons.format_list_numbered,
                title: 'Max Selections',
                description: 'Limit the number of selectable items',
              ),
              _FeatureItem(
                icon: Icons.style,
                title: 'Custom Chip Builder',
                description: 'Customize selected item appearance',
              ),
            ],
          ),
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

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
