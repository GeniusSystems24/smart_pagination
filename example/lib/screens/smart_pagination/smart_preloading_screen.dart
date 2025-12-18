import 'package:flutter/material.dart';
import 'package:smart_pagination/pagination.dart';
import '../../models/product.dart';
import '../../services/mock_api_service.dart';

/// Example demonstrating smart preloading with invisibleItemsThreshold
class SmartPreloadingScreen extends StatefulWidget {
  const SmartPreloadingScreen({super.key});

  @override
  State<SmartPreloadingScreen> createState() => _SmartPreloadingScreenState();
}

class _SmartPreloadingScreenState extends State<SmartPreloadingScreen> {
  int _threshold = 3;
  int _loadMoreTriggers = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Preloading'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.deepPurple.withValues(alpha:0.1),
            child: const Row(
              children: [
                Icon(Icons.speed, color: Colors.deepPurple),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Items load before you reach the end! '
                    'Adjust threshold to control when preloading starts.',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),

          // Controls Panel
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.tune, size: 18, color: Colors.grey[700]),
                    const SizedBox(width: 8),
                    Text(
                      'Preload Threshold',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$_threshold items',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Slider(
                        value: _threshold.toDouble(),
                        min: 1,
                        max: 10,
                        divisions: 9,
                        activeColor: Colors.deepPurple,
                        label: '$_threshold items before end',
                        onChanged: (value) {
                          setState(() {
                            _threshold = value.toInt();
                            _loadMoreTriggers = 0; // Reset counter
                          });
                        },
                      ),
                    ),
                  ],
                ),
                Text(
                  'Loads more when $_threshold items away from the end',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 8),
                const Divider(height: 1),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      'Load triggers: $_loadMoreTriggers',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Product List
          Expanded(
            child: SmartPagination<Product>.listViewWithProvider(
              key: ValueKey(_threshold), // Rebuild when threshold changes
              request: const PaginationRequest(page: 1, pageSize: 15),
              provider: PaginationProvider.future(
                (request) => MockApiService.fetchProducts(request),
              ),
              itemBuilder: (context, items, index) {
                final product = items[index];
                final itemsFromEnd = items.length - index;
                final willTrigger = itemsFromEnd <= _threshold;

                return _buildProductCard(
                  product,
                  index,
                  items.length,
                  willTrigger,
                );
              },
              separator: const Divider(height: 1),

              // Set the threshold
              invisibleItemsThreshold: _threshold,

              // Custom load more indicator with debug info
              loadMoreLoadingBuilder: (context) {
                // Increment counter when loading starts
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    setState(() {
                      _loadMoreTriggers++;
                    });
                  }
                });

                return Container(
                  padding: const EdgeInsets.all(20),
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.deepPurple.withValues(alpha:0.3),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: Colors.deepPurple,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Preloading more items...',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Triggered $_threshold items before the end',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                );
              },

              // Custom end indicator
              loadMoreNoMoreItemsBuilder: (context) {
                return Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.green.withValues(alpha:0.3),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 48,
                        color: Colors.green.shade600,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'All items loaded!',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Total load triggers: $_loadMoreTriggers',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
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
    );
  }

  Widget _buildProductCard(
    Product product,
    int index,
    int totalItems,
    bool willTrigger,
  ) {
    final itemsFromEnd = totalItems - index;

    return Container(
      decoration: willTrigger
          ? BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: Colors.deepPurple,
                  width: 4,
                ),
              ),
            )
          : null,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        leading: Stack(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: willTrigger
                    ? Colors.deepPurple.withValues(alpha:0.2)
                    : Colors.grey.withValues(alpha:0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '#${index + 1}',
                  style: TextStyle(
                    color: willTrigger ? Colors.deepPurple : Colors.grey[700],
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            if (willTrigger)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.deepPurple,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.bolt,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
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
            if (willTrigger)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.deepPurple,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'PRELOAD',
                  style: const TextStyle(
                    fontSize: 9,
                    color: Colors.white,
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
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  Icons.arrow_upward,
                  size: 12,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 4),
                Text(
                  '$itemsFromEnd from end',
                  style: TextStyle(
                    fontSize: 11,
                    color: willTrigger ? Colors.deepPurple : Colors.grey[500],
                    fontWeight: willTrigger ? FontWeight.bold : FontWeight.normal,
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
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
