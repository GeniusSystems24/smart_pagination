import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smart_pagination/pagination.dart';

import '../../models/product.dart';
import '../../services/mock_api_service.dart';

/// Example screen demonstrating Form Validation with SmartSearchDropdown.
///
/// This screen shows how to:
/// - Use SmartSearchDropdown inside a Form with validation
/// - Use initialSelectedValue for pre-selected items
/// - Use inputFormatters for input restrictions
/// - Handle form submission with validation
/// - Configure keyboard options (textInputAction, textCapitalization)
class FormValidationSearchScreen extends StatefulWidget {
  const FormValidationSearchScreen({super.key});

  @override
  State<FormValidationSearchScreen> createState() =>
      _FormValidationSearchScreenState();
}

class _FormValidationSearchScreenState
    extends State<FormValidationSearchScreen> {
  final _formKey = GlobalKey<FormState>();
  Product? _selectedProduct;
  int _quantity = 1;
  String _notes = '';
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Form Validation'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showInfoDialog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info Card
              Card(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'This example demonstrates form validation, '
                          'input formatters, and initial values with SmartSearchDropdown.',
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Section: Product Search with Validation
              Text(
                'Product Search *',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              SmartSearchDropdown<Product>.withProvider(
                request: const PaginationRequest(page: 1, pageSize: 10),
                provider: PaginationProvider.future(
                  (request) => MockApiService.searchProducts(
                    request.searchQuery ?? '',
                    pageSize: request.pageSize ?? 10,
                  ),
                ),
                searchRequestBuilder: (query) => PaginationRequest(
                  page: 1,
                  pageSize: 10,
                  searchQuery: query,
                ),
                searchConfig: const SmartSearchConfig(
                  debounceDelay: Duration(milliseconds: 500),
                  minSearchLength: 0,
                  searchOnEmpty: true,
                ),
                overlayConfig: const SmartSearchOverlayConfig(
                  maxHeight: 250,
                  borderRadius: 12,
                ),
                // Form Validation (v2.3.1)
                validator: (value) {
                  if (_selectedProduct == null) {
                    return 'Please select a product';
                  }
                  return null;
                },
                autovalidateMode: AutovalidateMode.onUserInteraction,
                // Input Options
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                // Input Formatters - only allow letters, numbers, spaces
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\s]')),
                  LengthLimitingTextInputFormatter(50),
                ],
                maxLength: 50,
                // Show selected mode
                showSelected: true,
                selectedItemBuilder: (context, product, onClear) => Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: Text(
                          product.name[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              product.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '\$${product.price.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          onClear();
                          setState(() => _selectedProduct = null);
                        },
                        tooltip: 'Clear selection',
                      ),
                    ],
                  ),
                ),
                itemBuilder: (context, product) => ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    child: Text(product.name[0].toUpperCase()),
                  ),
                  title: Text(product.name),
                  subtitle: Text(product.description),
                  trailing: Text(
                    '\$${product.price.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                onItemSelected: (product) {
                  setState(() => _selectedProduct = product);
                },
              ),
              const SizedBox(height: 24),

              // Section: Quantity with Input Formatter
              Text(
                'Quantity *',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: '1',
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(3),
                ],
                decoration: InputDecoration(
                  hintText: 'Enter quantity',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.numbers),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter quantity';
                  }
                  final qty = int.tryParse(value);
                  if (qty == null || qty < 1) {
                    return 'Quantity must be at least 1';
                  }
                  if (qty > 100) {
                    return 'Maximum quantity is 100';
                  }
                  return null;
                },
                onSaved: (value) {
                  _quantity = int.tryParse(value ?? '1') ?? 1;
                },
              ),
              const SizedBox(height: 24),

              // Section: Notes
              Text(
                'Notes (Optional)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                maxLines: 3,
                maxLength: 200,
                textInputAction: TextInputAction.done,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Add any special instructions...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 48),
                    child: Icon(Icons.note_alt_outlined),
                  ),
                ),
                onSaved: (value) {
                  _notes = value ?? '';
                },
              ),
              const SizedBox(height: 32),

              // Submit Button
              FilledButton.icon(
                onPressed: _isSubmitting ? null : _submitForm,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check),
                label: Text(_isSubmitting ? 'Submitting...' : 'Submit Order'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Reset Button
              OutlinedButton.icon(
                onPressed: _resetForm,
                icon: const Icon(Icons.refresh),
                label: const Text('Reset Form'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      setState(() => _isSubmitting = true);

      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      setState(() => _isSubmitting = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Order submitted: ${_selectedProduct?.name} x $_quantity',
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _resetForm() {
    _formKey.currentState!.reset();
    setState(() {
      _selectedProduct = null;
      _quantity = 1;
      _notes = '';
    });
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info_outline),
            SizedBox(width: 8),
            Text('v2.3.2 Features'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _FeatureItem(
                icon: Icons.select_all,
                title: 'initialSelectedValue',
                description: 'Pre-select an item when widget loads',
              ),
              _FeatureItem(
                icon: Icons.check_circle_outline,
                title: 'validator',
                description: 'Form validation with TextFormField',
              ),
              _FeatureItem(
                icon: Icons.keyboard,
                title: 'textInputAction',
                description: 'Keyboard action button (next, done, search)',
              ),
              _FeatureItem(
                icon: Icons.format_list_numbered,
                title: 'inputFormatters',
                description: 'Restrict or format input text',
              ),
              _FeatureItem(
                icon: Icons.dark_mode,
                title: 'Auto Theme',
                description: 'Automatic dark/light theme based on system',
              ),
              _FeatureItem(
                icon: Icons.straighten,
                title: 'maxLength',
                description: 'Limit input character count',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodySmall?.color,
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
