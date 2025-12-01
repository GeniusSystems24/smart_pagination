import 'package:flutter/material.dart';
import 'package:smart_pagination/pagination.dart';
import '../../models/product.dart';
import '../../services/mock_api_service.dart';

/// Example of beforeBuild hook for executing logic before rendering
class BeforeBuildHookScreen extends StatefulWidget {
  const BeforeBuildHookScreen({super.key});

  @override
  State<BeforeBuildHookScreen> createState() => _BeforeBuildHookScreenState();
}

class _BeforeBuildHookScreenState extends State<BeforeBuildHookScreen> {
  final List<String> _logs = [];
  final int _buildCount = 0;



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('beforeBuild Hook'),
        backgroundColor: Colors.brown,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.brown.withOpacity(0.1),
            child: const Row(
              children: [
                Icon(Icons.build, color: Colors.brown),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Execute custom logic before building the list. '
                    'Perfect for analytics, logging, or side effects.',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          // Activity Log
          Container(
            height: 180,
            color: Colors.grey[900],
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.terminal,
                      color: Colors.greenAccent,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Activity Log',
                      style: TextStyle(
                        color: Colors.greenAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Builds: $_buildCount',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const Divider(color: Colors.grey, height: 16),
                Expanded(
                  child: _logs.isEmpty
                      ? const Center(
                          child: Text(
                            'Waiting for activity...',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _logs.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.arrow_right,
                                    color: Colors.greenAccent,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      _logs[index],
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SmartPagination<Product>.withProvider(
              request: const PaginationRequest(page: 1, pageSize: 15),
              provider: PaginationProvider.future(
                (request) => MockApiService.fetchProducts(request),
              ),
              // beforeBuild hook - executes before building the list
              // beforeBuild: (context, state) {
              //   _buildCount++;
              //   if (state is SmartPaginationLoaded<Product>) {
              //     _addLog('✓ Loaded ${state.items.length} items (Page ${state.currentPage})');
              //   } else if (state is SmartPaginationLoading<Product>) {
              //     _addLog('⏳ Loading page ${state.currentPage}...');
              //   } else if (state is SmartPaginationError<Product>) {
              //     _addLog('✗ Error: ${state.error}');
              //   } else if (state is SmartPaginationInitial<Product>) {
              //     _addLog('⚡ Initialized pagination');
              //   }

              //   // Example: Track analytics
              //   // Analytics.trackEvent('pagination_view', {
              //   //   'page': state.currentPage,
              //   //   'total_items': state.items.length,
              //   // });
              // },
              itemBuilder: (context, products, index) {
                final product = products[index];
                return _buildProductCard(product, index);
              },
              separator: const Divider(height: 1),
              emptyWidget: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No products found',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
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

  Widget _buildProductCard(Product product, int index) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.brown.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            '#${index + 1}',
            style: const TextStyle(
              color: Colors.brown,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              product.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.brown.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              product.category,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.brown,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            product.description,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.build, size: 12, color: Colors.brown),
              const SizedBox(width: 4),
              Text(
                'beforeBuild hook executed',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.brown.withOpacity(0.7),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ],
      ),
      trailing: Text(
        '\$${product.price.toStringAsFixed(2)}',
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.green,
        ),
      ),
    );
  }
}
