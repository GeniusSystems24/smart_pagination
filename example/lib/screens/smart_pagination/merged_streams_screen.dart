import 'package:flutter/material.dart';
import 'package:smart_pagination/pagination.dart';
import '../../models/product.dart';
import '../../services/mock_api_service.dart';

/// Example of merging multiple streams into one unified stream
class MergedStreamsScreen extends StatelessWidget {
  const MergedStreamsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Merged Streams'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.deepPurple.withOpacity(0.1),
            child: const Row(
              children: [
                Icon(Icons.merge_type, color: Colors.deepPurple),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'This example merges 3 different streams (Regular, Featured, Sale) '
                    'into one unified stream. Products update in real-time from all sources.',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          _buildStreamBadges(),
          Expanded(
            child: SmartPagination<Product>.listViewWithProvider(
              request: const PaginationRequest(page: 1, pageSize: 15),
              provider: PaginationProvider.mergeStreams(
                (request) => [
                  MockApiService.regularProductsStream(request),
                  MockApiService.featuredProductsStream(request),
                  MockApiService.saleProductsStream(request),
                ],
              ),
              itemBuilder: (context, items, index) {
                final product = items[index];
                return _buildProductCard(product);
              },
              separator: const Divider(height: 1),

              // ========== FIRST PAGE STATES ==========

              firstPageLoadingBuilder: (context) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        strokeWidth: 5,
                        color: Colors.deepPurple,
                      ),
                      SizedBox(height: 24),
                      Text(
                        'Merging Streams',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Combining multiple data sources...',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                );
              },

              firstPageErrorBuilder: (context, error, retry) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 72,
                          color: Colors.red.shade400,
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Merge Failed',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          error.toString(),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton.icon(
                          onPressed: retry,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry Merge'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },

              firstPageEmptyBuilder: (context) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.merge_type,
                        size: 80,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'No Merged Products',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'All streams are empty',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                );
              },

              // ========== LOAD MORE STATES ==========

              loadMoreLoadingBuilder: (context) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  alignment: Alignment.center,
                  child: const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: Colors.deepPurple,
                    ),
                  ),
                );
              },

              loadMoreErrorBuilder: (context, error, retry) {
                return Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber, color: Colors.red.shade700, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Failed to load more',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.red.shade900,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: retry,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              },

              loadMoreNoMoreItemsBuilder: (context) {
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, size: 18, color: Colors.green.shade600),
                      const SizedBox(width: 8),
                      Text(
                        'All streams loaded',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              },

              // Smart preloading: Load when 3 items from the end
              invisibleItemsThreshold: 3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreamBadges() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildBadge('Regular', Colors.blue, '5s'),
          _buildBadge('Featured', Colors.orange, '4s'),
          _buildBadge('Sale', Colors.red, '3s'),
        ],
      ),
    );
  }

  Widget _buildBadge(String label, Color color, String interval) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color, width: 2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.stream, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Updates: $interval',
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildProductCard(Product product) {
    // Determine product type based on category
    Color categoryColor;
    IconData categoryIcon;
    String streamSource;

    if (product.category.toLowerCase().contains('electronics')) {
      categoryColor = Colors.blue;
      categoryIcon = Icons.devices;
      streamSource = 'Regular';
    } else if (product.category.toLowerCase().contains('featured')) {
      categoryColor = Colors.orange;
      categoryIcon = Icons.star;
      streamSource = 'Featured';
    } else if (product.category.toLowerCase().contains('sale')) {
      categoryColor = Colors.red;
      categoryIcon = Icons.local_offer;
      streamSource = 'Sale';
    } else {
      categoryColor = Colors.blue;
      categoryIcon = Icons.shopping_bag;
      streamSource = 'Regular';
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: categoryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(categoryIcon, color: categoryColor, size: 28),
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
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: categoryColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              streamSource,
              style: TextStyle(
                fontSize: 10,
                color: categoryColor,
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
              Icon(Icons.update, size: 12, color: categoryColor),
              const SizedBox(width: 4),
              Text(
                'Real-time updates',
                style: TextStyle(
                  fontSize: 11,
                  color: categoryColor,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '\$${product.price.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 2),
          Icon(
            Icons.trending_up,
            size: 16,
            color: Colors.green.withOpacity(0.6),
          ),
        ],
      ),
    );
  }
}
