import 'package:flutter/material.dart';
import 'package:smart_pagination/pagination.dart';
import '../../models/product.dart';
import '../../services/mock_api_service.dart';
import '../../widgets/product_card.dart';

class ColumnExampleScreen extends StatefulWidget {
  const ColumnExampleScreen({super.key});

  @override
  State<ColumnExampleScreen> createState() => _ColumnExampleScreenState();
}

class _ColumnExampleScreenState extends State<ColumnExampleScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Column Layout (Non-scrollable)')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader('Featured Products'),
              const SizedBox(height: 8),
              const Text(
                'This section is a standard Column widget containing a SmartPagination.column. '
                'It is not scrollable by itself but sits inside the parent SingleChildScrollView.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              
              // SmartPagination.column example
              SmartPagination<Product>.columnWithProvider(
                request: const PaginationRequest(page: 1, pageSize: 3),
                provider: PaginationProvider.future(
                  (request) => MockApiService.fetchProducts(
                    request,
                  ),
                ),
                itemBuilder: (context, items, index) {
                  return ProductCard(product: items[index]);
                },
                separator: const SizedBox(height: 12),
                // Custom loading builder for the column
                firstPageLoadingBuilder: (context) => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),

              const SizedBox(height: 24),
              _buildHeader('More Content Below'),
              const SizedBox(height: 8),
              Container(
                height: 100,
                color: Colors.blue.withValues(alpha: 0.1),
                alignment: Alignment.center,
                child: const Text('Other widgets in the same scroll view'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
