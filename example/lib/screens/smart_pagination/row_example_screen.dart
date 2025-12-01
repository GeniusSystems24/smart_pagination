import 'package:flutter/material.dart';
import 'package:smart_pagination/pagination.dart';
import '../../models/product.dart';
import '../../services/mock_api_service.dart';
import '../../widgets/product_card.dart';

class RowExampleScreen extends StatefulWidget {
  const RowExampleScreen({super.key});

  @override
  State<RowExampleScreen> createState() => _RowExampleScreenState();
}

class _RowExampleScreenState extends State<RowExampleScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Row Layout (Non-scrollable)')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader('Featured Products Row'),
                  const SizedBox(height: 8),
                  const Text(
                    'This section uses SmartPagination.row inside a horizontal SingleChildScrollView. '
                    'SmartPagination.row itself is not scrollable.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),

            // Horizontal Scroll View containing SmartPagination.row
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SmartPagination<Product>.rowWithProvider(
                request: const PaginationRequest(page: 1, pageSize: 5),
                provider: PaginationProvider.future(
                  (request) => MockApiService.fetchProducts(request),
                ),
                itemBuilder: (context, items, index) {
                  return SizedBox(
                    width: 200,
                    child: ProductCard(product: items[index]),
                  );
                },
                separator: const SizedBox(width: 12),
                // Custom loading builder
                firstPageLoadingBuilder: (context) => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildHeader('More Content Below'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    );
  }
}
