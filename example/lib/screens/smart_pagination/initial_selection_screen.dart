import 'package:flutter/material.dart';
import 'package:smart_pagination/pagination.dart';

import '../../models/product.dart';
import '../../services/mock_api_service.dart';

/// Example screen demonstrating initial/pre-selection in SmartSearchDropdown.
///
/// This screen shows how to:
/// - Set initial selected value using initialSelectedValue
/// - Pre-select by key before data loads
/// - Handle showSelected mode properly
/// - Customize selected item display
class InitialSelectionScreen extends StatefulWidget {
  const InitialSelectionScreen({super.key});

  @override
  State<InitialSelectionScreen> createState() => _InitialSelectionScreenState();
}

class _InitialSelectionScreenState extends State<InitialSelectionScreen> {
  // Simulated initial product (e.g., from user preferences or previous selection)
  final Product _initialProduct = Product(
    id: 'prod_1',
    name: 'Premium Headphones',
    description: 'High-quality wireless headphones',
    price: 199.99,
    rating: 4.8,
    stock: 50,
    imageUrl: '',
    category: 'Electronics',
    createdAt: DateTime.now(),
  );

  Product? _selectedProduct;
  List<Product> _selectedProducts = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Initial Selection'),
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
              color: Theme.of(context).colorScheme.secondaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.playlist_add_check_rounded,
                          color: Theme.of(context)
                              .colorScheme
                              .onSecondaryContainer,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Initial Selection',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSecondaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Pre-populate dropdowns with previously selected values, '
                      'user preferences, or default selections.',
                      style: TextStyle(
                        color:
                            Theme.of(context).colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ============================================================
            // Example 1: Initial Selected Value (Object)
            // ============================================================
            _buildSectionHeader(
              context,
              'Initial Selected Value',
              'Start with a pre-selected product object',
              Icons.check_circle_rounded,
            ),
            const SizedBox(height: 12),
            SmartSearchDropdown<Product, Product>.withProvider(
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
              // Set initial selected value
              initialSelectedValue: _initialProduct,
              showSelected: true,
              itemBuilder: (context, product) => ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                  child: Text(
                    product.name[0].toUpperCase(),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                title: Text(product.name),
                subtitle: Text(product.description),
                trailing: Text(
                  '\$${product.price.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              // Custom selected item display
              selectedItemBuilder: (context, product, onClear) => Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: Text(
                        product.name[0],
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '\$${product.price.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: onClear,
                      tooltip: 'Change selection',
                    ),
                  ],
                ),
              ),
              onSelected: (product, _) {
                setState(() => _selectedProduct = product);
              },
            ),
            const SizedBox(height: 32),

            // ============================================================
            // Example 2: Form with Default Value
            // ============================================================
            _buildSectionHeader(
              context,
              'Form with Default Value',
              'Use in forms with pre-filled values',
              Icons.edit_note_rounded,
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Edit Product Details',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: 'Order #12345',
                      decoration: const InputDecoration(
                        labelText: 'Order ID',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.receipt),
                      ),
                      readOnly: true,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Selected Product',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 8),
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
                        maxHeight: 250,
                        borderRadius: 8,
                      ),
                      keyExtractor: (product) => product.id,
                      // Pre-select by key (e.g., from database)
                      selectedKey: 'prod_2',
                      selectedKeyLabelBuilder: (key) => 'Product: $key',
                      showSelected: true,
                      decoration: InputDecoration(
                        hintText: 'Search products...',
                        prefixIcon: const Icon(Icons.inventory_2),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      itemBuilder: (context, product) => ListTile(
                        leading: const Icon(Icons.inventory_2),
                        title: Text(product.name),
                        subtitle: Text('ID: ${product.id}'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: '2',
                      decoration: const InputDecoration(
                        labelText: 'Quantity',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.numbers),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Form submitted!'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        icon: const Icon(Icons.save),
                        label: const Text('Save Changes'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // ============================================================
            // Example 3: Multi-Select with Initial Values
            // ============================================================
            _buildSectionHeader(
              context,
              'Multi-Select with Initial Values',
              'Start with pre-selected items list',
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
              keyExtractor: (product) => product.id,
              // Pre-select multiple items by keys
              selectedKeys: ['prod_1', 'prod_3', 'prod_5'],
              showSelected: true,
              selectedItemsWrap: true,
              selectedItemsSpacing: 8,
              selectedItemsRunSpacing: 8,
              itemBuilder: (context, product) => ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      Theme.of(context).colorScheme.tertiaryContainer,
                  child: Text(product.name[0].toUpperCase()),
                ),
                title: Text(product.name),
                subtitle: Text('ID: ${product.id}'),
                trailing: Text('\$${product.price.toStringAsFixed(2)}'),
              ),
              selectedItemBuilder: (context, product, onRemove) => Chip(
                avatar: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Text(
                    product.name[0],
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
                label: Text(product.name),
                deleteIcon: const Icon(Icons.close, size: 18),
                onDeleted: onRemove,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              ),
              onSelected: (products, _) {
                setState(() => _selectedProducts = products);
              },
            ),
            if (_selectedProducts.isNotEmpty) ...[
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selected Products (${_selectedProducts.length}):',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ...(_selectedProducts.map((p) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                const Icon(Icons.check,
                                    size: 16, color: Colors.green),
                                const SizedBox(width: 8),
                                Text(
                                    '${p.name} (\$${p.price.toStringAsFixed(2)})'),
                              ],
                            ),
                          ))),
                      const Divider(),
                      Text(
                        'Total: \$${_selectedProducts.fold<double>(0, (sum, p) => sum + p.price).toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 32),

            // ============================================================
            // Example 4: Conditional Initial Value
            // ============================================================
            _buildSectionHeader(
              context,
              'Conditional Initial Value',
              'Set initial value based on conditions',
              Icons.rule_rounded,
            ),
            const SizedBox(height: 12),
            _ConditionalDropdown(),
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
            color: Theme.of(context).colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.onSecondaryContainer,
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

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.playlist_add_check_rounded),
            SizedBox(width: 12),
            Text('Initial Selection'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ways to set initial selection:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              _FeatureItem(
                icon: Icons.data_object,
                title: 'initialSelectedValue',
                description: 'Pass the full object for immediate display',
              ),
              _FeatureItem(
                icon: Icons.key,
                title: 'selectedKey',
                description: 'Pass just the key, item loads when data arrives',
              ),
              _FeatureItem(
                icon: Icons.list,
                title: 'selectedKeys (Multi)',
                description: 'Pass multiple keys for multi-select',
              ),
              _FeatureItem(
                icon: Icons.inventory,
                title: 'initialSelectedValues (Multi)',
                description: 'Pass multiple objects for multi-select',
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

/// Widget demonstrating conditional initial value based on user preference
class _ConditionalDropdown extends StatefulWidget {
  @override
  State<_ConditionalDropdown> createState() => _ConditionalDropdownState();
}

class _ConditionalDropdownState extends State<_ConditionalDropdown> {
  bool _rememberSelection = true;
  String? _savedProductId = 'prod_4'; // Simulated saved preference

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Remember my selection',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                Switch(
                  value: _rememberSelection,
                  onChanged: (value) {
                    setState(() {
                      _rememberSelection = value;
                      if (!value) _savedProductId = null;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            SmartSearchDropdown<Product, String>.withProvider(
              // Use a unique key to rebuild when preference changes
              key: ValueKey('dropdown_$_rememberSelection'),
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
                borderRadius: 8,
              ),
              keyExtractor: (product) => product.id,
              // Conditionally set initial selection
              selectedKey: _rememberSelection ? _savedProductId : null,
              selectedKeyLabelBuilder: (key) => 'Loading: $key',
              showSelected: true,
              itemBuilder: (context, product) => ListTile(
                title: Text(product.name),
                subtitle: Text('ID: ${product.id}'),
              ),
              onSelected: (product, key) {
                if (_rememberSelection) {
                  setState(() => _savedProductId = key);
                }
              },
            ),
            const SizedBox(height: 8),
            Text(
              _rememberSelection
                  ? 'Selection will be saved for next time'
                  : 'Selection will not be remembered',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
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
