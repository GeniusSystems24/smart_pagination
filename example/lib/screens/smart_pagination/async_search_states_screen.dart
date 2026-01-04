import 'package:flutter/material.dart';
import 'package:smart_pagination/pagination.dart';

import '../../models/product.dart';
import '../../services/mock_api_service.dart';

/// Example screen demonstrating async search states.
///
/// This screen shows how to:
/// - Handle loading states during search
/// - Display empty states when no results
/// - Handle error states with retry
/// - Configure debounce delay
/// - Use custom state builders
class AsyncSearchStatesScreen extends StatefulWidget {
  const AsyncSearchStatesScreen({super.key});

  @override
  State<AsyncSearchStatesScreen> createState() => _AsyncSearchStatesScreenState();
}

class _AsyncSearchStatesScreenState extends State<AsyncSearchStatesScreen> {
  bool _simulateError = false;
  bool _simulateEmpty = false;
  int _debounceMs = 500;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Async Search States'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Controls card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Simulation Controls',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: const Text('Simulate Error'),
                      subtitle: const Text('API returns error'),
                      value: _simulateError,
                      onChanged: (value) {
                        setState(() {
                          _simulateError = value;
                          if (value) _simulateEmpty = false;
                        });
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Simulate Empty'),
                      subtitle: const Text('API returns no results'),
                      value: _simulateEmpty,
                      onChanged: (value) {
                        setState(() {
                          _simulateEmpty = value;
                          if (value) _simulateError = false;
                        });
                      },
                    ),
                    const Divider(),
                    ListTile(
                      title: const Text('Debounce Delay'),
                      subtitle: Text('$_debounceMs ms'),
                      trailing: SizedBox(
                        width: 200,
                        child: Slider(
                          value: _debounceMs.toDouble(),
                          min: 100,
                          max: 2000,
                          divisions: 19,
                          label: '$_debounceMs ms',
                          onChanged: (value) {
                            setState(() => _debounceMs = value.round());
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Default states
            Text(
              'Default State Builders',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            SmartSearchDropdown<Product, Product>.withProvider(
              key: ValueKey('default-$_simulateError-$_simulateEmpty-$_debounceMs'),
              request: const PaginationRequest(page: 1, pageSize: 10),
              provider: PaginationProvider.future(
                (request) => _fetchProducts(request),
              ),
              searchRequestBuilder: (query) => PaginationRequest(
                page: 1,
                pageSize: 10,
                searchQuery: query,
              ),
              searchConfig: SmartSearchConfig(
                debounceDelay: Duration(milliseconds: _debounceMs),
                minSearchLength: 0,
                searchOnEmpty: true,
              ),
              overlayConfig: const SmartSearchOverlayConfig(
                maxHeight: 250,
                borderRadius: 12,
              ),
              itemBuilder: (context, product) => ListTile(
                leading: CircleAvatar(
                  child: Text(product.name[0].toUpperCase()),
                ),
                title: Text(product.name),
                subtitle: Text('\$${product.price.toStringAsFixed(2)}'),
              ),
              onItemSelected: (product) {},
            ),
            const SizedBox(height: 32),

            // Custom states
            Text(
              'Custom State Builders',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            SmartSearchDropdown<Product, Product>.withProvider(
              key: ValueKey('custom-$_simulateError-$_simulateEmpty-$_debounceMs'),
              request: const PaginationRequest(page: 1, pageSize: 10),
              provider: PaginationProvider.future(
                (request) => _fetchProducts(request),
              ),
              searchRequestBuilder: (query) => PaginationRequest(
                page: 1,
                pageSize: 10,
                searchQuery: query,
              ),
              searchConfig: SmartSearchConfig(
                debounceDelay: Duration(milliseconds: _debounceMs),
                minSearchLength: 0,
                searchOnEmpty: true,
              ),
              overlayConfig: const SmartSearchOverlayConfig(
                maxHeight: 250,
                borderRadius: 12,
              ),
              // Custom loading builder
              loadingBuilder: (context) => Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator.adaptive(),
                    const SizedBox(height: 16),
                    Text(
                      'Searching...',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Please wait while we find products',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              // Custom empty builder
              emptyBuilder: (context) => Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.inventory_2_outlined,
                        size: 48,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No Products Found',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Try a different search term',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              // Custom error builder
              errorBuilder: (context, error) => Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.errorContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.cloud_off,
                        size: 32,
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Connection Error',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      error.toString(),
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () {
                        // Trigger retry by rebuilding
                        setState(() {});
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              itemBuilder: (context, product) => ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: Text(product.name[0].toUpperCase()),
                ),
                title: Text(product.name),
                subtitle: Text(product.description),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '\$${product.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
              onItemSelected: (product) {},
            ),
            const SizedBox(height: 32),

            // States info
            Card(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Available State Builders',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    _StateInfo(
                      icon: Icons.hourglass_empty,
                      title: 'loadingBuilder',
                      description: 'Shown while fetching data from API',
                    ),
                    _StateInfo(
                      icon: Icons.inbox_outlined,
                      title: 'emptyBuilder',
                      description: 'Shown when search returns no results',
                    ),
                    _StateInfo(
                      icon: Icons.error_outline,
                      title: 'errorBuilder',
                      description: 'Shown when API request fails',
                    ),
                    _StateInfo(
                      icon: Icons.view_list,
                      title: 'headerBuilder',
                      description: 'Widget shown above results list',
                    ),
                    _StateInfo(
                      icon: Icons.view_list_outlined,
                      title: 'footerBuilder',
                      description: 'Widget shown below results list',
                    ),
                    _StateInfo(
                      icon: Icons.horizontal_rule,
                      title: 'separatorBuilder',
                      description: 'Separator between list items',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<List<Product>> _fetchProducts(PaginationRequest request) async {
    // Add artificial delay to show loading state
    await Future.delayed(const Duration(milliseconds: 800));

    if (_simulateError) {
      throw Exception('Network error: Unable to connect to server');
    }

    if (_simulateEmpty) {
      return [];
    }

    return MockApiService.searchProducts(
      request.searchQuery ?? '',
      pageSize: request.pageSize ?? 10,
    );
  }
}

class _StateInfo extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _StateInfo({
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
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                  ),
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
