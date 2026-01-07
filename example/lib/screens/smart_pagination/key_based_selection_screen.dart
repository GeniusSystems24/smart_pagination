import 'package:flutter/material.dart';
import 'package:smart_pagination/pagination.dart';

import '../../models/product.dart';
import '../../services/mock_api_service.dart';

/// Example screen demonstrating key-based selection in SmartSearchDropdown.
///
/// Key-based selection allows you to:
/// - Select items by their unique key (ID, SKU, etc.) instead of object reference
/// - Pre-select items before data loads using just the key
/// - Compare items by key instead of object equality
/// - Get notified of selected keys in addition to items
class KeyBasedSelectionScreen extends StatefulWidget {
  const KeyBasedSelectionScreen({super.key});

  @override
  State<KeyBasedSelectionScreen> createState() => _KeyBasedSelectionScreenState();
}

class _KeyBasedSelectionScreenState extends State<KeyBasedSelectionScreen> {
  // Selected values for each example
  String? _selectedProductId;
  Product? _selectedProduct;

  String? _selectedMultiKey;
  List<String> _selectedMultiKeys = [];
  List<Product> _selectedMultiProducts = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Key-Based Selection'),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.key_rounded,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Key-Based Selection',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Select items using unique keys (like IDs) instead of object references. '
                      'This enables pre-selection before data loads and reliable comparison.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ============================================================
            // Example 1: Basic Key-Based Selection
            // ============================================================
            _buildSectionHeader(
              context,
              'Basic Key Selection',
              'Use product ID as the selection key',
              Icons.vpn_key_rounded,
            ),
            const SizedBox(height: 12),
            SmartSearchDropdown<Product, String>.withProvider(
              request: const PaginationRequest(page: 1, pageSize: 20),
              provider: PaginationProvider.future(
                (request) => MockApiService.searchProducts(
                  request.searchQuery ?? '',
                  pageSize: request.pageSize ?? 20,
                ),
              ),
              searchRequestBuilder: (query) => PaginationRequest(
                page: 1,
                pageSize: 20,
                searchQuery: query,
              ),
              searchConfig: const SmartSearchConfig(
                debounceDelay: Duration(milliseconds: 500),
                minSearchLength: 0,
                searchOnEmpty: true,
              ),
              overlayConfig: const SmartSearchOverlayConfig(
                maxHeight: 300,
                borderRadius: 12,
              ),
              // KEY FEATURE: Extract the key from item
              keyExtractor: (product) => product.id,
              // Show selected item
              showSelected: true,
              itemBuilder: (context, product) => ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: Text(
                    product.name[0].toUpperCase(),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                title: Text(product.name),
                subtitle: Text('ID: ${product.id}'),
                trailing: Text(
                  '\$${product.price.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              // Get notified of selection with both item and key
              onSelected: (product, key) {
                setState(() {
                  _selectedProductId = key;
                  _selectedProduct = product;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Selected Key: $key'),
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
            if (_selectedProductId != null) ...[
              const SizedBox(height: 12),
              _buildSelectionInfo(
                context,
                'Selected Key',
                _selectedProductId!,
                _selectedProduct?.name,
              ),
            ],
            const SizedBox(height: 32),

            // ============================================================
            // Example 2: Pre-selection by Key
            // ============================================================
            _buildSectionHeader(
              context,
              'Pre-Selection by Key',
              'Set initial selection using just the key',
              Icons.playlist_add_check_rounded,
            ),
            const SizedBox(height: 12),
            SmartSearchDropdown<Product, String>.withProvider(
              request: const PaginationRequest(page: 1, pageSize: 20),
              provider: PaginationProvider.future(
                (request) => MockApiService.searchProducts(
                  request.searchQuery ?? '',
                  pageSize: request.pageSize ?? 20,
                ),
              ),
              searchRequestBuilder: (query) => PaginationRequest(
                page: 1,
                pageSize: 20,
                searchQuery: query,
              ),
              searchConfig: const SmartSearchConfig(
                debounceDelay: Duration(milliseconds: 500),
                minSearchLength: 0,
                searchOnEmpty: true,
              ),
              overlayConfig: const SmartSearchOverlayConfig(
                maxHeight: 300,
                borderRadius: 12,
              ),
              keyExtractor: (product) => product.id,
              // PRE-SELECT by key before data loads!
              selectedKey: 'prod_5',
              // Custom label builder for pending key display
              selectedKeyLabelBuilder: (key) => 'Loading product: $key...',
              showSelected: true,
              itemBuilder: (context, product) => ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                  child: Text(product.name[0].toUpperCase()),
                ),
                title: Text(product.name),
                subtitle: Text('ID: ${product.id}'),
              ),
              onSelected: (product, key) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Changed to: $key'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb_outline, color: Colors.amber[700]),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'This dropdown starts with "prod_5" pre-selected. '
                        'The label shows while loading, then displays the actual product.',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // ============================================================
            // Example 3: Multi-Select with Keys
            // ============================================================
            _buildSectionHeader(
              context,
              'Multi-Select with Keys',
              'Track multiple selections by their keys',
              Icons.checklist_rounded,
            ),
            const SizedBox(height: 12),
            SmartSearchMultiDropdown<Product, String>.withProvider(
              request: const PaginationRequest(page: 1, pageSize: 20),
              provider: PaginationProvider.future(
                (request) => MockApiService.searchProducts(
                  request.searchQuery ?? '',
                  pageSize: request.pageSize ?? 20,
                ),
              ),
              searchRequestBuilder: (query) => PaginationRequest(
                page: 1,
                pageSize: 20,
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
              // KEY FEATURE: Extract keys for multi-select
              keyExtractor: (product) => product.id,
              showSelected: true,
              maxSelections: 5,
              itemBuilder: (context, product) => ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
                  child: Text(product.name[0].toUpperCase()),
                ),
                title: Text(product.name),
                subtitle: Text('ID: ${product.id}'),
              ),
              selectedItemBuilder: (context, product, onRemove) => Chip(
                avatar: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Text(
                    product.name[0],
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
                label: Text(product.id),
                deleteIcon: const Icon(Icons.close, size: 18),
                onDeleted: onRemove,
              ),
              // Get notified of selection with both items and keys
              onSelected: (products, keys) {
                setState(() {
                  _selectedMultiKeys = keys;
                  _selectedMultiProducts = products;
                });
              },
            ),
            if (_selectedMultiKeys.isNotEmpty) ...[
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selected Keys (${_selectedMultiKeys.length}):',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _selectedMultiKeys.map((key) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              key,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 32),

            // ============================================================
            // Example 4: Custom Key Builder Display
            // ============================================================
            _buildSectionHeader(
              context,
              'Custom Key Display',
              'Show custom UI while loading pre-selected key',
              Icons.style_rounded,
            ),
            const SizedBox(height: 12),
            SmartSearchDropdown<Product, String>.withProvider(
              request: const PaginationRequest(page: 1, pageSize: 20),
              provider: PaginationProvider.future(
                (request) async {
                  // Simulate slow network to show pending key state
                  await Future.delayed(const Duration(seconds: 2));
                  return MockApiService.searchProducts(
                    request.searchQuery ?? '',
                    pageSize: request.pageSize ?? 20,
                  );
                },
              ),
              searchRequestBuilder: (query) => PaginationRequest(
                page: 1,
                pageSize: 20,
                searchQuery: query,
              ),
              keyExtractor: (product) => product.id,
              selectedKey: 'prod_3',
              showSelected: true,
              // Custom widget for pending key display
              selectedKeyBuilder: (context, key, onClear) => Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primaryContainer,
                      Theme.of(context).colorScheme.secondaryContainer,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Loading Product',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'ID: $key',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: onClear,
                    ),
                  ],
                ),
              ),
              itemBuilder: (context, product) => ListTile(
                title: Text(product.name),
                subtitle: Text('ID: ${product.id}'),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.timer, color: Colors.orange[700]),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'This example has a 2-second delay to show the custom '
                        'pending key display widget.',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSelectionInfo(
    BuildContext context,
    String label,
    String key,
    String? itemName,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.green[600],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text('Key: $key'),
                  if (itemName != null) Text('Product: $itemName'),
                ],
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
        title: const Row(
          children: [
            Icon(Icons.key_rounded),
            SizedBox(width: 12),
            Text('Key-Based Selection'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Key-based selection provides several advantages:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              _FeatureItem(
                icon: Icons.vpn_key,
                title: 'Unique Identification',
                description: 'Use IDs, SKUs, or any unique key to identify items',
              ),
              _FeatureItem(
                icon: Icons.flash_on,
                title: 'Pre-Selection',
                description: 'Select items by key before data loads',
              ),
              _FeatureItem(
                icon: Icons.compare,
                title: 'Reliable Comparison',
                description: 'Compare by key instead of object equality',
              ),
              _FeatureItem(
                icon: Icons.notifications,
                title: 'Key Callbacks',
                description: 'Get notified with onKeySelected/onKeysChanged',
              ),
              _FeatureItem(
                icon: Icons.style,
                title: 'Custom Display',
                description: 'Show custom UI while loading pre-selected keys',
              ),
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

class _FeatureItem extends StatelessWidget {
  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

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
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
