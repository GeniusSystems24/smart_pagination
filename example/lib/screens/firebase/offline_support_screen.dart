import 'dart:async';
import 'package:flutter/material.dart';
import 'package:smart_pagination/pagination.dart';

/// Mock Product for offline support example
class OfflineProduct {
  final String id;
  final String name;
  final double price;
  final String imageUrl;
  final bool isCached;

  OfflineProduct({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    this.isCached = false,
  });

  OfflineProduct copyWith({bool? isCached}) {
    return OfflineProduct(
      id: id,
      name: name,
      price: price,
      imageUrl: imageUrl,
      isCached: isCached ?? this.isCached,
    );
  }
}

/// Simulates Firestore with offline persistence and cache indicators
class OfflineSupportScreen extends StatefulWidget {
  const OfflineSupportScreen({super.key});

  @override
  State<OfflineSupportScreen> createState() => _OfflineSupportScreenState();
}

class _OfflineSupportScreenState extends State<OfflineSupportScreen> {
  bool _isOnline = true;
  bool _hasCachedData = false;
  final _streamController = StreamController<List<OfflineProduct>>.broadcast();

  // Simulated cached products
  List<OfflineProduct> _cachedProducts = [];

  // Simulated server products
  final List<OfflineProduct> _serverProducts = List.generate(
    30,
    (index) => OfflineProduct(
      id: 'product_$index',
      name: 'Product ${index + 1}',
      price: 19.99 + (index * 7.5),
      imageUrl: 'https://picsum.photos/seed/offline$index/100/100',
    ),
  );

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() async {
    if (_isOnline) {
      // Simulate fetching from server
      await Future.delayed(const Duration(milliseconds: 800));
      _cachedProducts = List.from(_serverProducts);
      _hasCachedData = true;
      _streamController.add(_serverProducts);
    } else if (_hasCachedData) {
      // Return cached data
      final cachedWithFlag =
          _cachedProducts.map((p) => p.copyWith(isCached: true)).toList();
      _streamController.add(cachedWithFlag);
    } else {
      _streamController.addError('No cached data available');
    }
  }

  void _toggleOnlineStatus() {
    setState(() {
      _isOnline = !_isOnline;
    });
    _fetchData();
  }

  Stream<List<OfflineProduct>> streamProducts(PaginationRequest request) {
    return _streamController.stream;
  }

  @override
  void dispose() {
    _streamController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Support'),
        actions: [
          // Online/Offline toggle
          Container(
            margin: const EdgeInsets.all(8),
            child: InkWell(
              onTap: _toggleOnlineStatus,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _isOnline ? Colors.green : Colors.orange,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isOnline ? Icons.cloud_done : Icons.cloud_off,
                      size: 16,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isOnline ? 'Online' : 'Offline',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Status banner
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: _isOnline ? Colors.green.shade50 : Colors.orange.shade50,
            child: Row(
              children: [
                Icon(
                  _isOnline ? Icons.wifi : Icons.wifi_off,
                  color: _isOnline
                      ? Colors.green.shade700
                      : Colors.orange.shade700,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _isOnline
                        ? 'Connected - Showing live data'
                        : 'Offline - Showing cached data',
                    style: TextStyle(
                      color: _isOnline
                          ? Colors.green.shade700
                          : Colors.orange.shade700,
                      fontSize: 13,
                    ),
                  ),
                ),
                if (!_isOnline && _hasCachedData)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${_cachedProducts.length} cached',
                      style: TextStyle(
                        color: Colors.orange.shade800,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Info card
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tap the status button to toggle',
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            'Simulates Firestore offline persistence',
                            style: TextStyle(
                              color: Colors.blue.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Products list
          Expanded(
            child: SmartPagination.listViewWithProvider<OfflineProduct>(
              request: const PaginationRequest(page: 1, pageSize: 30),
              provider: PaginationProvider.stream(streamProducts),
              itemBuilder: (context, items, index) {
                final product = items[index];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: ListTile(
                    leading: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: _isOnline
                              ? Image.network(
                                  product.imageUrl,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      _buildPlaceholder(),
                                )
                              : _buildPlaceholder(),
                        ),
                        if (product.isCached)
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Icon(
                                Icons.cached,
                                size: 12,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                    title: Text(product.name),
                    subtitle: Text(
                      '\$${product.price.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing: product.isCached
                        ? Tooltip(
                            message: 'Cached data',
                            child: Icon(
                              Icons.cached,
                              color: Colors.orange.shade400,
                              size: 20,
                            ),
                          )
                        : Icon(
                            Icons.cloud_done,
                            color: Colors.green.shade400,
                            size: 20,
                          ),
                  ),
                );
              },
              loadingWidget: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading...'),
                  ],
                ),
              ),
              onError: (error) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cloud_off, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    const Text(
                      'No cached data available',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Connect to the internet to load data',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() => _isOnline = true);
                        _fetchData();
                      },
                      icon: const Icon(Icons.wifi),
                      label: const Text('Go Online'),
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

  Widget _buildPlaceholder() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.image, color: Colors.grey.shade400),
    );
  }
}
