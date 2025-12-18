import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_pagination/pagination.dart';

import '../../models/product.dart';
import '../../services/mock_api_service.dart';

/// Example screen demonstrating the Sorting & Orders feature.
///
/// This screen shows how to:
/// - Configure sort orders at initialization
/// - Change sort order programmatically
/// - Add/remove sort orders dynamically
/// - Use a dropdown to let users choose sort order
class SortingScreen extends StatefulWidget {
  const SortingScreen({super.key});

  @override
  State<SortingScreen> createState() => _SortingScreenState();
}

class _SortingScreenState extends State<SortingScreen> {
  late final SmartPaginationCubit<Product> _cubit;

  @override
  void initState() {
    super.initState();

    // Define available sort orders
    final orders = SortOrderCollection<Product>(
      orders: [
        SortOrder.byField(
          id: 'name_asc',
          label: 'Name (A-Z)',
          fieldSelector: (p) => p.name,
          direction: SortDirection.ascending,
        ),
        SortOrder.byField(
          id: 'name_desc',
          label: 'Name (Z-A)',
          fieldSelector: (p) => p.name,
          direction: SortDirection.descending,
        ),
        SortOrder.byField(
          id: 'price_low',
          label: 'Price: Low to High',
          fieldSelector: (p) => p.price,
          direction: SortDirection.ascending,
        ),
        SortOrder.byField(
          id: 'price_high',
          label: 'Price: High to Low',
          fieldSelector: (p) => p.price,
          direction: SortDirection.descending,
        ),
        SortOrder<Product>(
          id: 'custom',
          label: 'Custom (Rating then Price)',
          comparator: (a, b) {
            // Sort by rating descending, then price ascending
            final ratingCompare = b.rating.compareTo(a.rating);
            if (ratingCompare != 0) return ratingCompare;
            return a.price.compareTo(b.price);
          },
        ),
      ],
      defaultOrderId: 'name_asc',
    );

    // Create cubit with orders
    _cubit = SmartPaginationCubit<Product>(
      request: const PaginationRequest(page: 1, pageSize: 15),
      provider: PaginationProvider.future(
        (request) => MockApiService.fetchProducts(
          PaginationRequest(
            page: request.page,
            pageSize: request.pageSize ?? 15,
          ),
        ),
      ),
      orders: orders,
    );
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sorting & Orders'),
        actions: [
          // Reset order button
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset to Default',
            onPressed: () {
              _cubit.resetOrder();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sort order reset to default')),
              );
            },
          ),
          // Clear order button
          IconButton(
            icon: const Icon(Icons.clear_all),
            tooltip: 'Clear Sorting',
            onPressed: () {
              _cubit.clearOrder();
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Sorting cleared')));
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Sort order selector
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Row(
              children: [
                const Icon(Icons.sort),
                const SizedBox(width: 12),
                const Text('Sort by: '),
                const SizedBox(width: 8),
                Expanded(
                  child:
                      BlocBuilder<
                        SmartPaginationCubit<Product>,
                        SmartPaginationState<Product>
                      >(
                        bloc: _cubit,
                        builder: (context, state) {
                          return DropdownButton<String>(
                            value: _cubit.activeOrderId,
                            isExpanded: true,
                            hint: const Text('Select sort order'),
                            items: [
                              const DropdownMenuItem(
                                value: null,
                                child: Text('None (Original Order)'),
                              ),
                              ..._cubit.availableOrders.map((order) {
                                return DropdownMenuItem(
                                  value: order.id,
                                  child: Text(order.label),
                                );
                              }),
                            ],
                            onChanged: (orderId) {
                              if (orderId == null) {
                                _cubit.clearOrder();
                              } else {
                                _cubit.setActiveOrder(orderId);
                              }
                            },
                          );
                        },
                      ),
                ),
              ],
            ),
          ),

          // Current order indicator
          BlocBuilder<
            SmartPaginationCubit<Product>,
            SmartPaginationState<Product>
          >(
            bloc: _cubit,
            builder: (context, state) {
              if (state is SmartPaginationLoaded<Product>) {
                final activeOrder = _cubit.activeOrder;
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: Text(
                    activeOrder != null
                        ? 'Sorted by: ${activeOrder.label}'
                        : 'No sorting applied',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),

          // Products list
          Expanded(
            child: SmartPaginationListView.withCubit(
              cubit: _cubit,
              itemBuilder: (context, items, index) {
                final product = items[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: Text(
                        product.name.substring(0, 1).toUpperCase(),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ),
                    title: Text(product.name),
                    subtitle: Row(
                      children: [
                        Icon(
                          Icons.star,
                          size: 16,
                          color: Colors.amber.shade700,
                        ),
                        const SizedBox(width: 4),
                        Text(product.rating.toStringAsFixed(1)),
                        const SizedBox(width: 16),
                        Text(
                          'Stock: ${product.stock}',
                          style: TextStyle(
                            color: product.stock > 10
                                ? Colors.green
                                : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    trailing: Text(
                      '\$${product.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                );
              },
              emptyWidget: const Center(child: Text('No products found')),
              loadingWidget: const Center(child: CircularProgressIndicator()),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddOrderDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Order'),
      ),
    );
  }

  void _showAddOrderDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Sort Order'),
        content: const Text(
          'This demonstrates adding a new sort order dynamically.\n\n'
          'Adding "Newest First" order (by ID descending).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              _cubit.addSortOrder(
                SortOrder.byField(
                  id: 'id_desc',
                  label: 'Newest First (by ID)',
                  fieldSelector: (p) => p.id,
                  direction: SortDirection.descending,
                ),
              );
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('New sort order added!')),
              );
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
