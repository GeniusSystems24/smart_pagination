import 'package:flutter/material.dart';
import 'package:smart_pagination/pagination.dart';

import '../../models/product.dart';
import '../../services/mock_api_service.dart';

/// Example screen demonstrating all 13 overlay animation types
/// and the overlay value parameter feature.
class OverlayAnimationsScreen extends StatefulWidget {
  const OverlayAnimationsScreen({super.key});

  @override
  State<OverlayAnimationsScreen> createState() =>
      _OverlayAnimationsScreenState();
}

class _OverlayAnimationsScreenState extends State<OverlayAnimationsScreen> {
  OverlayAnimationType _selectedAnimation = OverlayAnimationType.fade;
  Duration _animationDuration = const Duration(milliseconds: 200);
  Curve _selectedCurve = Curves.easeOutCubic;
  String? _lastSelectedValue;

  final List<({String name, Curve curve})> _curves = [
    (name: 'easeOutCubic', curve: Curves.easeOutCubic),
    (name: 'easeInOut', curve: Curves.easeInOut),
    (name: 'easeOut', curve: Curves.easeOut),
    (name: 'bounceOut', curve: Curves.bounceOut),
    (name: 'elasticOut', curve: Curves.elasticOut),
    (name: 'easeOutBack', curve: Curves.easeOutBack),
    (name: 'fastOutSlowIn', curve: Curves.fastOutSlowIn),
    (name: 'linear', curve: Curves.linear),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Overlay Animations'),
        backgroundColor: theme.colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Animation Type Selector
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Animation Type',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: OverlayAnimationType.values.map((type) {
                        final isSelected = type == _selectedAnimation;
                        return ChoiceChip(
                          label: Text(type.name),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedAnimation = type);
                            }
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Animation Duration Slider
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Animation Duration: ${_animationDuration.inMilliseconds}ms',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Slider(
                      value: _animationDuration.inMilliseconds.toDouble(),
                      min: 50,
                      max: 1000,
                      divisions: 19,
                      label: '${_animationDuration.inMilliseconds}ms',
                      onChanged: (value) {
                        setState(() {
                          _animationDuration =
                              Duration(milliseconds: value.toInt());
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Curve Selector
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Animation Curve',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _curves.map((curveData) {
                        final isSelected = curveData.curve == _selectedCurve;
                        return ChoiceChip(
                          label: Text(curveData.name),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedCurve = curveData.curve);
                            }
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Search Dropdown with Animation
            Text(
              'Try the Search Dropdown',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Animation: ${_selectedAnimation.name}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 8),
            SmartSearchDropdown<Product, Product>.withProvider(
              key: ValueKey(
                '${_selectedAnimation.name}_${_animationDuration.inMilliseconds}_${_selectedCurve.hashCode}',
              ),
              request: PaginationRequest(page: 1, pageSize: 10),
              provider: PaginationProvider.future(
                (request) => MockApiService.fetchProducts(request),
              ),
              searchRequestBuilder: (query) => PaginationRequest(
                page: 1,
                pageSize: 10,
                searchQuery: query,
              ),
              searchConfig: const SmartSearchConfig(
                debounceDelay: Duration(milliseconds: 300),
                searchOnEmpty: true,
              ),
              overlayConfig: SmartSearchOverlayConfig(
                animationType: _selectedAnimation,
                animationDuration: _animationDuration,
                animationCurve: _selectedCurve,
                maxHeight: 250,
              ),
              itemBuilder: (context, product) => ListTile(
                leading: CircleAvatar(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(product.name[0]),
                ),
                title: Text(product.name),
                subtitle: Text('\$${product.price.toStringAsFixed(2)}'),
              ),
              onItemSelected: (product) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Selected: ${product.name}'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              decoration: InputDecoration(
                hintText: 'Search products...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Overlay Value Demo Section
            Text(
              'Overlay Value Feature',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pass a value when showing the overlay to determine content type.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),

            // Demo with overlay value
            _OverlayValueDemo(
              animationType: _selectedAnimation,
              animationDuration: _animationDuration,
              animationCurve: _selectedCurve,
              onValueSelected: (value) {
                setState(() => _lastSelectedValue = value);
              },
            ),

            if (_lastSelectedValue != null) ...[
              const SizedBox(height: 16),
              Card(
                color: theme.colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Last selected value: $_lastSelectedValue',
                          style: TextStyle(
                            color: theme.colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 32),

            // Animation Descriptions
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Animation Descriptions',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._buildAnimationDescriptions(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildAnimationDescriptions() {
    const descriptions = {
      OverlayAnimationType.fade: 'Simple opacity transition',
      OverlayAnimationType.scale: 'Scales from center point',
      OverlayAnimationType.fadeScale: 'Combined fade and scale',
      OverlayAnimationType.slideDown: 'Slides from top with fade',
      OverlayAnimationType.slideUp: 'Slides from bottom with fade',
      OverlayAnimationType.slideLeft: 'Slides from left with fade',
      OverlayAnimationType.slideRight: 'Slides from right with fade',
      OverlayAnimationType.bounceScale: 'Elastic bounce effect',
      OverlayAnimationType.elasticScale: 'Smooth overshoot scale',
      OverlayAnimationType.flipX: '3D flip on X axis',
      OverlayAnimationType.flipY: '3D flip on Y axis',
      OverlayAnimationType.zoomIn: 'Zooms from 50% to 100%',
      OverlayAnimationType.none: 'Instant show/hide',
    };

    return descriptions.entries.map((entry) {
      final isSelected = entry.key == _selectedAnimation;
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outline,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${entry.key.name}: ${entry.value}',
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color:
                      isSelected ? Theme.of(context).colorScheme.primary : null,
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}

/// Demo widget showing how to use overlay value parameter
class _OverlayValueDemo extends StatefulWidget {
  const _OverlayValueDemo({
    required this.animationType,
    required this.animationDuration,
    required this.animationCurve,
    required this.onValueSelected,
  });

  final OverlayAnimationType animationType;
  final Duration animationDuration;
  final Curve animationCurve;
  final ValueChanged<String> onValueSelected;

  @override
  State<_OverlayValueDemo> createState() => _OverlayValueDemoState();
}

class _OverlayValueDemoState extends State<_OverlayValueDemo> {
  late SmartSearchController<Product, Product> _controller;
  late SmartPaginationCubit<Product> _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = SmartPaginationCubit<Product>(
      request: PaginationRequest(page: 1, pageSize: 10),
      provider: PaginationProvider.future(
        (request) => MockApiService.fetchProducts(request),
      ),
    );
    _controller = SmartSearchController<Product, Product>(
      cubit: _cubit,
      searchRequestBuilder: (query) => PaginationRequest(
        page: 1,
        pageSize: 10,
        searchQuery: query,
      ),
      config: const SmartSearchConfig(
        debounceDelay: Duration(milliseconds: 300),
        searchOnEmpty: true,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Buttons to show overlay with different values
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ElevatedButton.icon(
              onPressed: () {
                _controller.showOverlay(value: 'electronics');
                widget.onValueSelected('electronics');
              },
              icon: const Icon(Icons.devices),
              label: const Text('Electronics'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                _controller.showOverlay(value: 'clothing');
                widget.onValueSelected('clothing');
              },
              icon: const Icon(Icons.checkroom),
              label: const Text('Clothing'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                _controller.showOverlay(value: 1);
                widget.onValueSelected('Category ID: 1');
              },
              icon: const Icon(Icons.category),
              label: const Text('Category 1'),
            ),
            OutlinedButton.icon(
              onPressed: () {
                _controller.showOverlay();
                widget.onValueSelected('(no value)');
              },
              icon: const Icon(Icons.search),
              label: const Text('No Value'),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Show current overlay value
        ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            final value = _controller.overlayValue;
            final hasValue = _controller.hasOverlayValue;

            return Card(
              color: theme.colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(
                      hasValue ? Icons.label : Icons.label_off,
                      color: hasValue
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      hasValue
                          ? 'Overlay value: $value (${value.runtimeType})'
                          : 'No overlay value set',
                      style: TextStyle(
                        fontWeight:
                            hasValue ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 8),

        // The search overlay
        SmartSearchOverlay<Product, Product>(
          controller: _controller,
          overlayConfig: SmartSearchOverlayConfig(
            animationType: widget.animationType,
            animationDuration: widget.animationDuration,
            animationCurve: widget.animationCurve,
            maxHeight: 200,
          ),
          searchBoxDecoration: InputDecoration(
            hintText: 'Search with overlay value...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          itemBuilder: (context, product) {
            // You could use _controller.overlayValue here to customize display
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: theme.colorScheme.secondaryContainer,
                child: Text(product.name[0]),
              ),
              title: Text(product.name),
              subtitle: Text('\$${product.price.toStringAsFixed(2)}'),
            );
          },
          onItemSelected: (product) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Selected: ${product.name} (value was: ${_controller.overlayValue})',
                ),
                duration: const Duration(seconds: 2),
              ),
            );
          },
        ),
      ],
    );
  }
}
