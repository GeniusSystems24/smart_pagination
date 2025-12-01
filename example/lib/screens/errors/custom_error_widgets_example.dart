import 'package:smart_pagination/pagination.dart';
import 'package:flutter/material.dart';
import '../../models/product.dart';

/// Custom error widgets example
///
/// Demonstrates all pre-built error widget styles:
/// - Material Design
/// - Compact
/// - Card
/// - Minimal
/// - Snackbar
/// - Completely Custom
class CustomErrorWidgetsExample extends StatelessWidget {
  const CustomErrorWidgetsExample({super.key});

  Future<List<Product>> _fetchProductsWithError(PaginationRequest request) async {
    await Future.delayed(const Duration(milliseconds: 800));
    throw Exception('Network error: Unable to connect to server');
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 6,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Custom Error Widgets'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Material'),
              Tab(text: 'Compact'),
              Tab(text: 'Card'),
              Tab(text: 'Minimal'),
              Tab(text: 'Snackbar'),
              Tab(text: 'Custom'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildMaterialExample(),
            _buildCompactExample(),
            _buildCardExample(),
            _buildMinimalExample(),
            _buildSnackbarExample(),
            _buildCustomExample(),
          ],
        ),
      ),
    );
  }

  // ========== Material Design Example ==========
  Widget _buildMaterialExample() {
    return Column(
      children: [
        _buildInfoBanner(
          'Material Design Style',
          'Full-featured error display with icon, title, message, and action button.\n'
          'Best for: First page errors with ample screen space.',
          Colors.blue,
        ),
        Expanded(
            child: SmartPagination<Product>.listViewWithProvider(
              key: const Key('material_error'),
              request: PaginationRequest(page: 1, pageSize: 20),
              provider: PaginationProvider.future(_fetchProductsWithError),
              itemBuilder: (context, products, index) {
                final product = products[index];
                return ListTile(title: Text(product.name));
              },
            firstPageErrorBuilder: (context, error, retry) {
              return CustomErrorBuilder.material(
                context: context,
                error: error,
                onRetry: retry,
                title: 'Failed to Load Products',
                message: 'Please check your internet connection and try again.',
                icon: Icons.cloud_off,
                iconColor: Colors.blue,
                retryButtonText: 'Try Again',
              );
            },
          ),
        ),
      ],
    );
  }

  // ========== Compact Example ==========
  Widget _buildCompactExample() {
    return Column(
      children: [
        _buildInfoBanner(
          'Compact Style',
          'Space-efficient inline error widget with horizontal layout.\n'
          'Best for: Load more errors with limited vertical space.',
          Colors.orange,
        ),
        Expanded(
            child: SmartPagination<Product>.listViewWithProvider(
              key: const Key('compact_error'),
              request: PaginationRequest(page: 1, pageSize: 20),
              provider: PaginationProvider.future(_fetchProductsWithError),
              itemBuilder: (context, products, index) {
                final product = products[index];
                return ListTile(title: Text(product.name));
              },
            firstPageErrorBuilder: (context, error, retry) {
              return Center(
                child: CustomErrorBuilder.compact(
                  context: context,
                  error: error,
                  onRetry: retry,
                  message: 'Unable to load products. Please try again.',
                  backgroundColor: Colors.orange[50],
                  textColor: Colors.orange[900],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ========== Card Example ==========
  Widget _buildCardExample() {
    return Column(
      children: [
        _buildInfoBanner(
          'Card Style',
          'Error displayed in a Material card with elevation and rounded corners.\n'
          'Best for: Grid views or when you want a distinct error card.',
          Colors.green,
        ),
        Expanded(
            child: SmartPagination<Product>.listViewWithProvider(
              key: const Key('card_error'),
              request: PaginationRequest(page: 1, pageSize: 20),
              provider: PaginationProvider.future(_fetchProductsWithError),
              itemBuilder: (context, products, index) {
                final product = products[index];
                return ListTile(title: Text(product.name));
              },
            firstPageErrorBuilder: (context, error, retry) {
              return CustomErrorBuilder.card(
                context: context,
                error: error,
                onRetry: retry,
                title: 'Products Unavailable',
                message: 'We couldn\'t load the products at this time. Please check your connection.',
                elevation: 8,
              );
            },
          ),
        ),
      ],
    );
  }

  // ========== Minimal Example ==========
  Widget _buildMinimalExample() {
    return Column(
      children: [
        _buildInfoBanner(
          'Minimal Style',
          'Minimalist error display with just message and retry icon button.\n'
          'Best for: Very limited space scenarios.',
          Colors.purple,
        ),
        Expanded(
            child: SmartPagination<Product>.listViewWithProvider(
              key: const Key('minimal_error'),
              request: PaginationRequest(page: 1, pageSize: 20),
              provider: PaginationProvider.future(_fetchProductsWithError),
              itemBuilder: (context, products, index) {
                final product = products[index];
                return ListTile(title: Text(product.name));
              },
            firstPageErrorBuilder: (context, error, retry) {
              return Center(
                child: CustomErrorBuilder.minimal(
                  context: context,
                  error: error,
                  onRetry: retry,
                  message: 'Failed to load products',
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ========== Snackbar Example ==========
  Widget _buildSnackbarExample() {
    return Column(
      children: [
        _buildInfoBanner(
          'Snackbar Style',
          'Bottom-aligned error that doesn\'t block content.\n'
          'Best for: Non-intrusive error messages.',
          Colors.indigo,
        ),
        Expanded(
            child: SmartPagination<Product>.listViewWithProvider(
              key: const Key('snackbar_error'),
              request: PaginationRequest(page: 1, pageSize: 20),
              provider: PaginationProvider.future(_fetchProductsWithError),
              itemBuilder: (context, products, index) {
                final product = products[index];
                return ListTile(title: Text(product.name));
              },
            firstPageErrorBuilder: (context, error, retry) {
              return Stack(
                children: [
                  // Dimmed background
                  Container(
                    color: Colors.black12,
                    child: const Center(
                      child: Text(
                        'Content would appear here',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  // Snackbar-style error
                  CustomErrorBuilder.snackbar(
                    context: context,
                    error: error,
                    onRetry: retry,
                    message: 'Failed to load products',
                    backgroundColor: Colors.grey[900],
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  // ========== Custom Example ==========
  Widget _buildCustomExample() {
    return Column(
      children: [
        _buildInfoBanner(
          'Completely Custom',
          'Build your own error widget from scratch with complete control.\n'
          'Best for: Specific branding or unique design requirements.',
          Colors.red,
        ),
        Expanded(
            child: SmartPagination<Product>.listViewWithProvider(
              key: const Key('custom_error'),
              request: PaginationRequest(page: 1, pageSize: 20),
              provider: PaginationProvider.future(_fetchProductsWithError),
              itemBuilder: (context, products, index) {
                final product = products[index];
                return ListTile(title: Text(product.name));
              },
            firstPageErrorBuilder: (context, error, retry) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.purple[100]!,
                      Colors.pink[100]!,
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Animated error icon
                      TweenAnimationBuilder(
                        tween: Tween<double>(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 500),
                        builder: (context, double value, child) {
                          return Transform.scale(
                            scale: value,
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.purple.withOpacity(0.3),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.sentiment_dissatisfied,
                                size: 64,
                                color: Colors.purple,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 32),

                      // Custom title
                      const Text(
                        'Oops!',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Custom message
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 48),
                        child: Text(
                          'Something unexpected happened',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Custom retry button
                      Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.purple, Colors.pink],
                          ),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.purple.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: retry,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 48,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.refresh, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                'TRY AGAIN',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildInfoBanner(String title, String description, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(color: color.withOpacity(0.3)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
