import 'package:flutter/material.dart';
import 'package:custom_pagination/pagination.dart';
import '../../models/product.dart';
import '../../services/mock_api_service.dart';

/// Example of staggered grid view (Pinterest-like layout)
class StaggeredGridScreen extends StatelessWidget {
  const StaggeredGridScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Staggered Grid'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.deepPurple.withOpacity(0.1),
            child: const Row(
              children: [
                Icon(Icons.view_quilt, color: Colors.deepPurple),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Pinterest-like layout with varying card heights. '
                    'Perfect for image galleries and masonry layouts.',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SmartPagination<Product>(
              request: const PaginationRequest(page: 1, pageSize: 20),
              provider: PaginationProvider.future(
                (request) => MockApiService.fetchProducts(request),
              ),
              itemBuilderType: PaginateBuilderType.staggeredGridView,

              // crossAxisCount: 2,
              // mainAxisSpacing: 12,
              // crossAxisSpacing: 12,
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, items, index) {
                final product = items[index];
                return _buildProductCard(product, index);
              },
              emptyWidget: const Center(child: Text('No products')),
              loadingWidget: const Center(child: CircularProgressIndicator()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Product product, int index) {
    // Vary the height based on index for staggered effect
    final heights = [180.0, 220.0, 200.0, 240.0, 190.0, 210.0];
    final imageHeight = heights[index % heights.length];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image section with varying height
          Container(
            height: imageHeight,
            decoration: BoxDecoration(
              color: Colors.primaries[index % Colors.primaries.length]
                  .withOpacity(0.2),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(
                    Icons.shopping_bag_outlined,
                    size: 60,
                    color: Colors.primaries[index % Colors.primaries.length]
                        .withOpacity(0.5),
                  ),
                ),
                // Category badge
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      product.category,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color:
                            Colors.primaries[index % Colors.primaries.length],
                      ),
                    ),
                  ),
                ),
                // Favorite button
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.favorite_border, size: 18),
                      color: Colors.red,
                      onPressed: () {},
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Product info
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  product.description,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '\$${product.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.add_shopping_cart,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
