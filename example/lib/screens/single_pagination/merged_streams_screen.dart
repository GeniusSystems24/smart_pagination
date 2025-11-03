import 'package:flutter/material.dart';
import 'package:custom_pagination/pagination.dart';
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
            child: SinglePagination<Product>(
              request: const PaginationRequest(page: 1, pageSize: 15),
              provider: PaginationProvider.mergeStreams(
                (request) => [
                  MockApiService.regularProductsStream(request),
                  MockApiService.featuredProductsStream(request),
                  MockApiService.saleProductsStream(request),
                ],
              ),
              itemBuilderType: PaginateBuilderType.listView,
              itemBuilder: (context, items, index) {
                final product = items[index];
                return _buildProductCard(product);
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
              loadingWidget: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Merging streams...',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
              bottomLoader: const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
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
