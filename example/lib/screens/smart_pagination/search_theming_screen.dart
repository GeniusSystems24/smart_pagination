import 'package:flutter/material.dart';
import 'package:smart_pagination/pagination.dart';

import '../../models/product.dart';
import '../../services/mock_api_service.dart';

/// Example screen demonstrating SmartSearchTheme customization.
///
/// This screen shows how to:
/// - Use light and dark themes
/// - Auto-detect system theme
/// - Create custom themed search
/// - Customize individual theme properties
class SearchThemingScreen extends StatefulWidget {
  const SearchThemingScreen({super.key});

  @override
  State<SearchThemingScreen> createState() => _SearchThemingScreenState();
}

class _SearchThemingScreenState extends State<SearchThemingScreen> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _getThemeData(context),
      child: Builder(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Search Theming'),
            actions: [
              PopupMenuButton<ThemeMode>(
                icon: Icon(_getThemeIcon()),
                onSelected: (mode) => setState(() => _themeMode = mode),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: ThemeMode.system,
                    child: Row(
                      children: [
                        Icon(Icons.brightness_auto),
                        SizedBox(width: 8),
                        Text('System'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: ThemeMode.light,
                    child: Row(
                      children: [
                        Icon(Icons.light_mode),
                        SizedBox(width: 8),
                        Text('Light'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: ThemeMode.dark,
                    child: Row(
                      children: [
                        Icon(Icons.dark_mode),
                        SizedBox(width: 8),
                        Text('Dark'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Theme info card
                Card(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          _getThemeIcon(),
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Current Theme: ${_themeMode.name.toUpperCase()}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                ),
                              ),
                              Text(
                                'SmartSearchTheme auto-detects system theme when no explicit theme is set.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Default themed search
                Text(
                  'Auto Theme Detection',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Uses system brightness to select light/dark theme',
                  style: Theme.of(context).textTheme.bodySmall,
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
                    debounceDelay: Duration(milliseconds: 300),
                    minSearchLength: 0,
                    searchOnEmpty: true,
                  ),
                  overlayConfig: const SmartSearchOverlayConfig(
                    maxHeight: 200,
                    borderRadius: 12,
                  ),
                  itemBuilder: (context, product) => ListTile(
                    leading: CircleAvatar(
                      child: Text(product.name[0].toUpperCase()),
                    ),
                    title: Text(product.name),
                    subtitle: Text('\$${product.price.toStringAsFixed(2)}'),
                  ),
                  onItemSelected: (product) {},
                ),
                const SizedBox(height: 32),

                // Custom themed search
                Text(
                  'Custom Theme',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Purple accent with custom colors',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                Theme(
                  data: Theme.of(context).copyWith(
                    extensions: [
                      SmartSearchTheme(
                        searchBoxBackgroundColor: const Color(0xFFF3E8FF),
                        searchBoxTextColor: const Color(0xFF581C87),
                        searchBoxHintColor: const Color(0xFF9333EA),
                        searchBoxBorderColor: const Color(0xFFD8B4FE),
                        searchBoxFocusedBorderColor: const Color(0xFF9333EA),
                        searchBoxIconColor: const Color(0xFF9333EA),
                        searchBoxCursorColor: const Color(0xFF9333EA),
                        overlayBackgroundColor: Colors.white,
                        overlayBorderColor: const Color(0xFFD8B4FE),
                        itemHoverColor: const Color(0xFFF3E8FF),
                        itemFocusedColor: const Color(0xFFE9D5FF),
                        loadingIndicatorColor: const Color(0xFF9333EA),
                      ),
                    ],
                  ),
                  child: SmartSearchDropdown<Product>.withProvider(
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
                      debounceDelay: Duration(milliseconds: 300),
                      minSearchLength: 0,
                      searchOnEmpty: true,
                    ),
                    overlayConfig: const SmartSearchOverlayConfig(
                      maxHeight: 200,
                      borderRadius: 16,
                    ),
                    itemBuilder: (context, product) => ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF9333EA),
                        child: Text(
                          product.name[0].toUpperCase(),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(product.name),
                      subtitle: Text('\$${product.price.toStringAsFixed(2)}'),
                    ),
                    onItemSelected: (product) {},
                  ),
                ),
                const SizedBox(height: 32),

                // Green themed search
                Text(
                  'Green Success Theme',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Green accent for success states',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                Theme(
                  data: Theme.of(context).copyWith(
                    extensions: [
                      SmartSearchTheme(
                        searchBoxBackgroundColor: const Color(0xFFDCFCE7),
                        searchBoxTextColor: const Color(0xFF14532D),
                        searchBoxHintColor: const Color(0xFF16A34A),
                        searchBoxBorderColor: const Color(0xFFBBF7D0),
                        searchBoxFocusedBorderColor: const Color(0xFF16A34A),
                        searchBoxIconColor: const Color(0xFF16A34A),
                        searchBoxCursorColor: const Color(0xFF16A34A),
                        overlayBackgroundColor: Colors.white,
                        overlayBorderColor: const Color(0xFFBBF7D0),
                        itemHoverColor: const Color(0xFFDCFCE7),
                        itemFocusedColor: const Color(0xFFBBF7D0),
                        loadingIndicatorColor: const Color(0xFF16A34A),
                      ),
                    ],
                  ),
                  child: SmartSearchDropdown<Product>.withProvider(
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
                      debounceDelay: Duration(milliseconds: 300),
                      minSearchLength: 0,
                      searchOnEmpty: true,
                    ),
                    overlayConfig: const SmartSearchOverlayConfig(
                      maxHeight: 200,
                      borderRadius: 8,
                    ),
                    itemBuilder: (context, product) => ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF16A34A),
                        child: Text(
                          product.name[0].toUpperCase(),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(product.name),
                      subtitle: Text('\$${product.price.toStringAsFixed(2)}'),
                    ),
                    onItemSelected: (product) {},
                  ),
                ),
                const SizedBox(height: 32),

                // Theme properties info
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Available Theme Properties',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const Divider(),
                        _PropertyGroup(
                          title: 'Search Box',
                          properties: [
                            'searchBoxBackgroundColor',
                            'searchBoxTextColor',
                            'searchBoxHintColor',
                            'searchBoxBorderColor',
                            'searchBoxFocusedBorderColor',
                            'searchBoxIconColor',
                            'searchBoxCursorColor',
                          ],
                        ),
                        _PropertyGroup(
                          title: 'Overlay',
                          properties: [
                            'overlayBackgroundColor',
                            'overlayBorderColor',
                            'overlayBorderRadius',
                            'overlayElevation',
                          ],
                        ),
                        _PropertyGroup(
                          title: 'Items',
                          properties: [
                            'itemBackgroundColor',
                            'itemHoverColor',
                            'itemFocusedColor',
                            'itemSelectedColor',
                            'itemTextColor',
                          ],
                        ),
                        _PropertyGroup(
                          title: 'States',
                          properties: [
                            'loadingIndicatorColor',
                            'emptyStateIconColor',
                            'errorIconColor',
                            'errorButtonColor',
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  ThemeData _getThemeData(BuildContext context) {
    final brightness = MediaQuery.platformBrightnessOf(context);

    switch (_themeMode) {
      case ThemeMode.light:
        return ThemeData.light(useMaterial3: true);
      case ThemeMode.dark:
        return ThemeData.dark(useMaterial3: true);
      case ThemeMode.system:
        return brightness == Brightness.dark
            ? ThemeData.dark(useMaterial3: true)
            : ThemeData.light(useMaterial3: true);
    }
  }

  IconData _getThemeIcon() {
    switch (_themeMode) {
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.dark:
        return Icons.dark_mode;
      case ThemeMode.system:
        return Icons.brightness_auto;
    }
  }
}

class _PropertyGroup extends StatelessWidget {
  final String title;
  final List<String> properties;

  const _PropertyGroup({
    required this.title,
    required this.properties,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: properties.map((prop) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  prop,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
