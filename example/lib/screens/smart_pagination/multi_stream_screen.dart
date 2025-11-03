import 'package:flutter/material.dart';
import 'package:custom_pagination/pagination.dart';
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
            color: _getTabColor().withOpacity(0.1),
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
    return SmartPagination<Product>(
      key: ValueKey(_selectedTabIndex), // Force rebuild when tab changes
      request: const PaginationRequest(page: 1, pageSize: 15),
      provider: PaginationProvider.stream(
        (request) => _getStreamProvider(request),
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
      onError: (exception) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Error: $exception',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
      loadingWidget: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: _getTabColor()),
            const SizedBox(height: 16),
            Text(
              'Connecting to ${_getTabLabel()} stream...',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
      bottomLoader: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: CircularProgressIndicator(color: _getTabColor()),
        ),
      ),
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
                  color: badgeColor.withOpacity(0.1),
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
              color: badgeColor.withOpacity(0.2),
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
