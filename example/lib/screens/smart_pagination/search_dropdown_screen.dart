import 'package:flutter/material.dart';
import 'package:smart_pagination/pagination.dart';

import '../../models/product.dart';
import '../../services/mock_api_service.dart';

/// Example screen demonstrating the SmartSearchDropdown feature.
///
/// This screen shows how to:
/// - Use SmartSearchDropdown with auto-positioning overlay
/// - Configure search behavior (debounce, min length, etc.)
/// - Customize overlay appearance and position
/// - Handle item selection
class SearchDropdownScreen extends StatefulWidget {
  const SearchDropdownScreen({super.key});

  @override
  State<SearchDropdownScreen> createState() => _SearchDropdownScreenState();
}

class _SearchDropdownScreenState extends State<SearchDropdownScreen> {
  Product? _selectedProduct;
  OverlayPosition _position = OverlayPosition.auto;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Search Dropdown'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Description
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Smart Search Dropdown',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'The search dropdown automatically positions itself in the best '
                      'available space. Try changing the overlay position below to see '
                      'different placement options.',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Position selector
            Text(
              'Overlay Position',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: OverlayPosition.values.map((position) {
                return ChoiceChip(
                  label: Text(position.name.toUpperCase()),
                  selected: _position == position,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _position = position);
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Search dropdown
            Text(
              'Search Products',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            SmartSearchDropdown<Product>.withProvider(
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
                debounceDelay: Duration(seconds: 1), // Wait 1 second after typing stops
                minSearchLength: 0, // Search on any input including empty
                searchOnEmpty: true, // Fetch all data when search is empty
                clearOnClose: false,
                autoFocus: false,
              ),
              overlayConfig: SmartSearchOverlayConfig(
                position: _position,
                maxHeight: 300,
                maxWidth: null, // Use search box width
                offset: 8,
                borderRadius: 12,
                elevation: 8,
                barrierDismissible: true,
                animationDuration: const Duration(milliseconds: 200),
              ),
              decoration: InputDecoration(
                hintText: 'Type to search products...',
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                ),
              ),
              itemBuilder: (context, product) => ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: Text(
                    product.name.substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                title: Text(product.name),
                subtitle: Row(
                  children: [
                    Icon(
                      Icons.star,
                      size: 14,
                      color: Colors.amber.shade700,
                    ),
                    const SizedBox(width: 4),
                    Text(product.rating.toStringAsFixed(1)),
                  ],
                ),
                trailing: Text(
                  '\$${product.price.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              onItemSelected: (product) {
                setState(() => _selectedProduct = product);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Selected: ${product.name}'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              emptyBuilder: (context) => Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.search_off,
                      size: 48,
                      color: Theme.of(context).disabledColor,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No products found',
                      style: TextStyle(color: Theme.of(context).disabledColor),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Try a different search term',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              headerBuilder: (context) => Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(context).dividerColor,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.search,
                      size: 18,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Search Results',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Selected product card
            if (_selectedProduct != null) ...[
              Text(
                'Selected Product',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor:
                                Theme.of(context).colorScheme.primaryContainer,
                            child: Text(
                              _selectedProduct!.name.substring(0, 1).toUpperCase(),
                              style: TextStyle(
                                fontSize: 20,
                                color:
                                    Theme.of(context).colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedProduct!.name,
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                Text(
                                  _selectedProduct!.description,
                                  style: Theme.of(context).textTheme.bodySmall,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildInfoChip(
                            context,
                            Icons.attach_money,
                            '\$${_selectedProduct!.price.toStringAsFixed(2)}',
                          ),
                          _buildInfoChip(
                            context,
                            Icons.star,
                            _selectedProduct!.rating.toStringAsFixed(1),
                          ),
                          _buildInfoChip(
                            context,
                            Icons.inventory,
                            'Stock: ${_selectedProduct!.stock}',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 32),

            // Features list
            Text(
              'Features',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            _buildFeatureItem(
              context,
              Icons.auto_awesome,
              'Auto-positioning',
              'Overlay finds the best position automatically',
            ),
            _buildFeatureItem(
              context,
              Icons.timer,
              'Debounced Search',
              'Waits 300ms before searching to reduce API calls',
            ),
            _buildFeatureItem(
              context,
              Icons.animation,
              'Smooth Animations',
              'Fade in/out animations for overlay',
            ),
            _buildFeatureItem(
              context,
              Icons.touch_app,
              'Tap to Dismiss',
              'Tap outside to close the overlay',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(BuildContext context, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(
    BuildContext context,
    IconData icon,
    String title,
    String description,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
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
