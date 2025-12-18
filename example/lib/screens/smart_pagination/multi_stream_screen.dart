import 'package:flutter/material.dart';
import 'package:smart_pagination/pagination.dart';
import '../../models/product.dart';
import '../../services/mock_api_service.dart';

/// Multi stream example with multiple data sources
class MultiStreamScreen extends StatefulWidget {
  const MultiStreamScreen({super.key});

  @override
  State<MultiStreamScreen> createState() => _MultiStreamScreenState();
}

class _MultiStreamScreenState extends State<MultiStreamScreen> {
  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Multi Stream Example'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: _buildTab(
                    index: 0,
                    label: 'Regular',
                    icon: Icons.inventory_2,
                    color: Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildTab(
                    index: 1,
                    label: 'Featured',
                    icon: Icons.star,
                    color: Colors.amber,
                  ),
                ),
                Expanded(
                  child: _buildTab(
                    index: 2,
                    label: 'Sale',
                    icon: Icons.local_fire_department,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: _getTabColor().withValues(alpha:0.1),
            child: Row(
              children: [
                Icon(Icons.stream, color: _getTabColor()),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _getTabDescription(),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _buildStreamContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildTab({
    required int index,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _selectedTabIndex == index;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedTabIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? color : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? color : Colors.grey,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? color : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreamContent() {
    return SmartPagination<Product>.listViewWithProvider(
      key: ValueKey(_selectedTabIndex), // Force rebuild when tab changes
      request: const PaginationRequest(page: 1, pageSize: 15),
      provider: PaginationProvider.stream(
        (request) => _getStreamProvider(request),
      ),
      itemBuilder: (context, items, index) {
        final product = items[index];
        return _buildProductCard(product);
      },
      separator: const Divider(height: 1),

      // ========== FIRST PAGE STATES ==========

      firstPageLoadingBuilder: (context) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                strokeWidth: 5,
                color: _getTabColor(),
              ),
              const SizedBox(height: 24),
              Text(
                'Connecting to ${_getTabLabel()} Stream',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Streaming live updates...',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
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
                Text(
                  'Stream Connection Failed',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  error.toString(),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: retry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reconnect'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _getTabColor(),
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
                Icons.stream_outlined,
                size: 80,
                color: Colors.grey[300],
              ),
              const SizedBox(height: 24),
              Text(
                'No ${_getTabLabel()} Products',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Stream is empty',
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
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: _getTabColor(),
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
              const Expanded(
                child: Text(
                  'Failed to load more',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.red,
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
                'All items loaded',
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
    );
  }

  Stream<List<Product>> _getStreamProvider(PaginationRequest request) {
    switch (_selectedTabIndex) {
      case 0:
        return MockApiService.regularProductsStream(request);
      case 1:
        return MockApiService.featuredProductsStream(request);
      case 2:
        return MockApiService.saleProductsStream(request);
      default:
        return MockApiService.regularProductsStream(request);
    }
  }

  String _getTabLabel() {
    switch (_selectedTabIndex) {
      case 0:
        return 'Regular';
      case 1:
        return 'Featured';
      case 2:
        return 'Sale';
      default:
        return 'Regular';
    }
  }

  String _getTabDescription() {
    switch (_selectedTabIndex) {
      case 0:
        return 'Regular products update every 5 seconds. Standard inventory items.';
      case 1:
        return 'Featured products update every 4 seconds. Premium items with exclusive features.';
      case 2:
        return 'Sale products update every 3 seconds. Limited time offers!';
      default:
        return '';
    }
  }

  Color _getTabColor() {
    switch (_selectedTabIndex) {
      case 0:
        return Colors.blue;
      case 1:
        return Colors.amber;
      case 2:
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  Widget _buildProductCard(Product product) {
    final isFeatured = product.id.startsWith('featured_');
    final isSale = product.id.startsWith('sale_');

    Color badgeColor = Colors.blue;
    String badgeText = 'Regular';

    if (isFeatured) {
      badgeColor = Colors.amber;
      badgeText = 'Featured';
    } else if (isSale) {
      badgeColor = Colors.red;
      badgeText = 'Sale';
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              product.imageUrl,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 60,
                  height: 60,
                  color: Colors.grey[300],
                  child: const Icon(Icons.image_not_supported),
                );
              },
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: badgeColor,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Icon(
                Icons.stream,
                size: 12,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      title: Text(
        product.name,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 15,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            product.description,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha:0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontSize: 11,
                    color: badgeColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                product.category,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
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
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isSale ? Colors.red : Colors.green,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha:0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.update, size: 10, color: badgeColor),
                const SizedBox(width: 2),
                Text(
                  'Live',
                  style: TextStyle(
                    fontSize: 9,
                    color: badgeColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
