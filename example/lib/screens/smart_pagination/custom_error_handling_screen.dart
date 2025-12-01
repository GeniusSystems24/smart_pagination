import 'package:smart_pagination/pagination.dart';
import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../services/mock_api_service.dart';

/// Demonstrates custom error handling with various error widget styles
///
/// This example shows:
/// - Material design error widget for first page errors
/// - Compact error widget for load more errors
/// - Card-style error widget
/// - Minimal error widget
/// - Custom error widget with complete control
class CustomErrorHandlingScreen extends StatefulWidget {
  const CustomErrorHandlingScreen({super.key});

  @override
  State<CustomErrorHandlingScreen> createState() =>
      _CustomErrorHandlingScreenState();
}

class _CustomErrorHandlingScreenState extends State<CustomErrorHandlingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _apiService = MockApiService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Custom Error Handling'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Material'),
            Tab(text: 'Compact'),
            Tab(text: 'Card'),
            Tab(text: 'Minimal'),
            Tab(text: 'Custom'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMaterialErrorExample(),
          _buildCompactErrorExample(),
          _buildCardErrorExample(),
          _buildMinimalErrorExample(),
          _buildCustomErrorExample(),
        ],
      ),
    );
  }

  /// Example 1: Material Design Error Widget
  Widget _buildMaterialErrorExample() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.blue[50],
          child: const Text(
            'Material Design style with full details.\n'
            'Best for first page errors with full screen space.',
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          child: SmartPagination<Product>.withProvider(
            key: const Key('material_error'),
            request: PaginationRequest(page: 1, pageSize: 10),
            provider: PaginationProvider.future(
              (request) => _apiService.fetchProductsWithError(request),
            ),
            itemBuilder: (context, products, index) {
              final product = products[index];
              return ListTile(
                title: Text(product.name),
                subtitle: Text('\$${product.price.toStringAsFixed(2)}'),
              );
            },
            // Material design error for first page
            firstPageErrorBuilder: (context, error, retry) {
              return CustomErrorBuilder.material(
                context: context,
                error: error,
                onRetry: retry,
                title: 'Failed to Load Products',
                message: 'Please check your internet connection and try again.',
              );
            },
            // Compact error for load more
            loadMoreErrorBuilder: (context, error, retry) {
              return CustomErrorBuilder.compact(
                context: context,
                error: error,
                onRetry: retry,
                message: 'Failed to load more products',
              );
            },
          ),
        ),
      ],
    );
  }

  /// Example 2: Compact Error Widget
  Widget _buildCompactErrorExample() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.orange[50],
          child: const Text(
            'Compact style for inline errors.\n'
            'Best for load more errors with limited space.',
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          child: SmartPagination<Product>.withProvider(
            key: const Key('compact_error'),
            request: PaginationRequest(page: 1, pageSize: 10),
            provider: PaginationProvider.future(
              (request) => _apiService.fetchProductsWithError(request),
            ),
            itemBuilder: (context, products, index) {
              final product = products[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(product.name),
                  subtitle: Text('\$${product.price.toStringAsFixed(2)}'),
                ),
              );
            },
            firstPageErrorBuilder: (context, error, retry) {
              return CustomErrorBuilder.compact(
                context: context,
                error: error,
                onRetry: retry,
                message: 'Unable to load products. Please try again.',
              );
            },
            loadMoreErrorBuilder: (context, error, retry) {
              return CustomErrorBuilder.compact(
                context: context,
                error: error,
                onRetry: retry,
              );
            },
          ),
        ),
      ],
    );
  }

  /// Example 3: Card Style Error Widget
  Widget _buildCardErrorExample() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.green[50],
          child: const Text(
            'Card style with shadow and rounded corners.\n'
            'Good for grid views or distinct error cards.',
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          child: SmartPagination<Product>.withProvider(
            itemBuilderType: PaginateBuilderType.gridView,
            key: const Key('card_error'),
            request: PaginationRequest(page: 1, pageSize: 10),
            provider: PaginationProvider.future(
              (request) => _apiService.fetchProductsWithError(request),
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            padding: const EdgeInsets.all(8),
            itemBuilder: (context, products, index) {
              final product = products[index];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.shopping_bag, size: 48),
                      const SizedBox(height: 8),
                      Text(
                        product.name,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Text(
                        '\$${product.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            firstPageErrorBuilder: (context, error, retry) {
              return CustomErrorBuilder.card(
                context: context,
                error: error,
                onRetry: retry,
                title: 'Products Unavailable',
                message:
                    'We could not load the products at this time. Please try again.',
              );
            },
          ),
        ),
      ],
    );
  }

  /// Example 4: Minimal Error Widget
  Widget _buildMinimalErrorExample() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.purple[50],
          child: const Text(
            'Minimal style with just message and retry button.\n'
            'Best for very limited space scenarios.',
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          child: SmartPagination<Product>.withProvider(
            key: const Key('minimal_error'),
            request: PaginationRequest(page: 1, pageSize: 10),
            provider: PaginationProvider.future(
              (request) => _apiService.fetchProductsWithError(request),
            ),
            itemBuilder: (context, products, index) {
              final product = products[index];
              return ListTile(
                dense: true,
                title: Text(product.name),
                trailing: Text(
                  '\$${product.price.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              );
            },
            loadMoreErrorBuilder: (context, error, retry) {
              return CustomErrorBuilder.minimal(
                context: context,
                error: error,
                onRetry: retry,
              );
            },
            firstPageErrorBuilder: (context, error, retry) {
              return Center(
                child: CustomErrorBuilder.minimal(
                  context: context,
                  error: error,
                  onRetry: retry,
                  message: 'Failed to load',
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Example 5: Custom Error Widget with Complete Control
  Widget _buildCustomErrorExample() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.red[50],
          child: const Text(
            'Completely custom error widget.\n'
            'Use when you need specific layout or branding.',
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          child: SmartPagination<Product>.withProvider(
            key: const Key('custom_error'),
            request: PaginationRequest(page: 1, pageSize: 10),
            provider: PaginationProvider.future(
              (request) => _apiService.fetchProductsWithError(request),
            ),
            itemBuilder: (context, products, index) {
              final product = products[index];
              return ListTile(
                title: Text(product.name),
                subtitle: Text('\$${product.price.toStringAsFixed(2)}'),
              );
            },
            firstPageErrorBuilder: (context, error, retry) {
              // Completely custom error design
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.red[100]!, Colors.white],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.cloud_off,
                          size: 64,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'Oops!',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Something went wrong',
                        style: TextStyle(fontSize: 18, color: Colors.black87),
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: retry,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 48,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          'TRY AGAIN',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            loadMoreErrorBuilder: (context, error, retry) {
              return CustomErrorBuilder.snackbar(
                context: context,
                error: error,
                onRetry: retry,
              );
            },
          ),
        ),
      ],
    );
  }
}
