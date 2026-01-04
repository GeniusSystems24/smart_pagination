import 'package:flutter/material.dart';
import 'package:smart_pagination/pagination.dart';

import '../../models/product.dart';
import '../../services/mock_api_service.dart';

/// Example screen demonstrating keyboard navigation in SmartSearchDropdown.
///
/// This screen shows how to:
/// - Navigate search results with arrow keys
/// - Select items with Enter key
/// - Close overlay with Escape key
/// - Use Home/End/PageUp/PageDown for quick navigation
class KeyboardNavigationSearchScreen extends StatefulWidget {
  const KeyboardNavigationSearchScreen({super.key});

  @override
  State<KeyboardNavigationSearchScreen> createState() =>
      _KeyboardNavigationSearchScreenState();
}

class _KeyboardNavigationSearchScreenState
    extends State<KeyboardNavigationSearchScreen> {
  Product? _selectedProduct;
  final List<String> _navigationLog = [];

  void _addLog(String message) {
    setState(() {
      _navigationLog.insert(0, '${DateTime.now().toString().substring(11, 19)} - $message');
      if (_navigationLog.length > 10) {
        _navigationLog.removeLast();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Keyboard Navigation'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showShortcutsDialog,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Keyboard shortcuts card
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
                          Icons.keyboard,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Keyboard Shortcuts',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _ShortcutRow(icon: Icons.arrow_downward, keys: '↓', description: 'Next item'),
                    _ShortcutRow(icon: Icons.arrow_upward, keys: '↑', description: 'Previous item'),
                    _ShortcutRow(icon: Icons.keyboard_return, keys: 'Enter', description: 'Select item'),
                    _ShortcutRow(icon: Icons.close, keys: 'Esc', description: 'Close dropdown'),
                    _ShortcutRow(icon: Icons.first_page, keys: 'Home', description: 'First item'),
                    _ShortcutRow(icon: Icons.last_page, keys: 'End', description: 'Last item'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Search dropdown
            Text(
              'Try Keyboard Navigation',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            SmartSearchDropdown<Product, Product>.withProvider(
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
                debounceDelay: Duration(milliseconds: 300),
                minSearchLength: 0,
                searchOnEmpty: true,
              ),
              overlayConfig: const SmartSearchOverlayConfig(
                maxHeight: 300,
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
              onItemSelected: (product) {
                setState(() => _selectedProduct = product);
                _addLog('Selected: ${product.name}');
              },
            ),
            const SizedBox(height: 24),

            // Selected product display
            if (_selectedProduct != null) ...[
              Text(
                'Selected Product',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Text(
                      _selectedProduct!.name[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(_selectedProduct!.name),
                  subtitle: Text(_selectedProduct!.description),
                  trailing: Text(
                    '\$${_selectedProduct!.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),

            // Navigation log
            Text(
              'Navigation Log',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Card(
                child: _navigationLog.isEmpty
                    ? const Center(
                        child: Text(
                          'Navigate using keyboard to see logs',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: _navigationLog.length,
                        itemBuilder: (context, index) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            _navigationLog[index],
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                              color: index == 0
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                            ),
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showShortcutsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.keyboard),
            SizedBox(width: 8),
            Text('Keyboard Shortcuts'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DialogShortcut(keys: '↑ / ↓', description: 'Navigate items'),
            _DialogShortcut(keys: 'Enter', description: 'Select focused item'),
            _DialogShortcut(keys: 'Escape', description: 'Close dropdown'),
            _DialogShortcut(keys: 'Home', description: 'Go to first item'),
            _DialogShortcut(keys: 'End', description: 'Go to last item'),
            _DialogShortcut(keys: 'Page Up', description: 'Jump 5 items up'),
            _DialogShortcut(keys: 'Page Down', description: 'Jump 5 items down'),
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

class _ShortcutRow extends StatelessWidget {
  final IconData icon;
  final String keys;
  final String description;

  const _ShortcutRow({
    required this.icon,
    required this.keys,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Theme.of(context).colorScheme.onPrimaryContainer),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              keys,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            description,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _DialogShortcut extends StatelessWidget {
  final String keys;
  final String description;

  const _DialogShortcut({
    required this.keys,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 100,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              keys,
              style: const TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 12),
          Text(description),
        ],
      ),
    );
  }
}
