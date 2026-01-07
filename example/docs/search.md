# Search Examples

Smart search components with auto-positioning overlay.

## Table of Contents

- [Search Dropdown](#search-dropdown)
- [Multi-Select Search](#multi-select-search)
- [Form Validation](#form-validation)
- [Keyboard Navigation](#keyboard-navigation)
- [Search Theming](#search-theming)
- [Async States](#async-states)

---

## Search Dropdown

Search with auto-positioning overlay:

```dart
class SearchDropdownScreen extends StatefulWidget {
  @override
  State<SearchDropdownScreen> createState() => _SearchDropdownScreenState();
}

class _SearchDropdownScreenState extends State<SearchDropdownScreen> {
  Product? _selectedProduct;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search Dropdown')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SmartSearchDropdown<Product, Product>.withProvider(
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
                maxHeight: 300,
                borderRadius: 12,
                showAboveIfNoSpace: true,
              ),
              showSelected: true,
              hintText: 'Search products...',
              itemBuilder: (context, product) => ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue[100],
                  child: Text(product.name[0].toUpperCase()),
                ),
                title: Text(product.name),
                subtitle: Text('\$${product.price.toStringAsFixed(2)}'),
              ),
              onSelected: (product, _) {
                setState(() => _selectedProduct = product);
              },
            ),

            if (_selectedProduct != null) ...[
              const SizedBox(height: 24),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.check_circle, color: Colors.green),
                  title: Text('Selected: ${_selectedProduct!.name}'),
                  subtitle: Text('\$${_selectedProduct!.price.toStringAsFixed(2)}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => setState(() => _selectedProduct = null),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

---

## Multi-Select Search

Search and select multiple items (v2.4.0):

```dart
class MultiSelectSearchScreen extends StatefulWidget {
  @override
  State<MultiSelectSearchScreen> createState() => _MultiSelectSearchScreenState();
}

class _MultiSelectSearchScreenState extends State<MultiSelectSearchScreen> {
  List<Product> _selectedProducts = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Multi-Select Search'),
        actions: [
          if (_selectedProducts.isNotEmpty)
            Chip(
              label: Text('${_selectedProducts.length} selected'),
              deleteIcon: const Icon(Icons.clear, size: 16),
              onDeleted: () => setState(() => _selectedProducts.clear()),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Basic Multi-Select
            const Text('Basic Multi-Select', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SmartSearchMultiDropdown<Product, Product>.withProvider(
              request: const PaginationRequest(page: 1, pageSize: 10),
              provider: PaginationProvider.future(searchProducts),
              searchRequestBuilder: (query) => PaginationRequest(
                page: 1,
                pageSize: 10,
                searchQuery: query,
              ),
              showSelected: true,
              itemBuilder: (context, product) => ListTile(
                leading: CircleAvatar(child: Text(product.name[0])),
                title: Text(product.name),
                subtitle: Text('\$${product.price.toStringAsFixed(2)}'),
              ),
              onSelected: (products, _) {
                setState(() => _selectedProducts = products);
              },
            ),

            const SizedBox(height: 32),

            // With Max Selections
            const Text('Max 3 Selections', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SmartSearchMultiDropdown<Product, Product>.withProvider(
              request: const PaginationRequest(page: 1, pageSize: 10),
              provider: PaginationProvider.future(searchProducts),
              searchRequestBuilder: (query) => PaginationRequest(
                page: 1,
                pageSize: 10,
                searchQuery: query,
              ),
              showSelected: true,
              maxSelections: 3,
              itemBuilder: (context, product) => ListTile(
                title: Text(product.name),
              ),
              onMaxSelectionsReached: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Maximum 3 items allowed')),
                );
              },
              onSelected: (products, _) {},
            ),

            const SizedBox(height: 32),

            // Custom Chip Builder
            const Text('Custom Chips', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SmartSearchMultiDropdown<Product, Product>.withProvider(
              request: const PaginationRequest(page: 1, pageSize: 10),
              provider: PaginationProvider.future(searchProducts),
              searchRequestBuilder: (query) => PaginationRequest(
                page: 1,
                pageSize: 10,
                searchQuery: query,
              ),
              showSelected: true,
              selectedItemsWrap: true,
              selectedItemsSpacing: 8,
              selectedItemsRunSpacing: 8,
              itemBuilder: (context, product) => ListTile(
                title: Text(product.name),
              ),
              selectedItemBuilder: (context, product, onRemove) => Chip(
                avatar: CircleAvatar(
                  backgroundColor: Colors.purple,
                  child: Text(
                    product.name[0],
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
                label: Text(product.name),
                deleteIcon: const Icon(Icons.close, size: 18),
                onDeleted: onRemove,
              ),
              onSelected: (products, _) {},
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## Form Validation

Search with validators and formatters:

```dart
class FormValidationSearchScreen extends StatefulWidget {
  @override
  State<FormValidationSearchScreen> createState() => _FormValidationSearchScreenState();
}

class _FormValidationSearchScreenState extends State<FormValidationSearchScreen> {
  final _formKey = GlobalKey<FormState>();
  Product? _selectedProduct;
  String? _errorText;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Form Validation')),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Required field
              SmartSearchDropdown<Product, Product>.withProvider(
                request: const PaginationRequest(page: 1, pageSize: 10),
                provider: PaginationProvider.future(searchProducts),
                searchRequestBuilder: (query) => PaginationRequest(
                  page: 1,
                  pageSize: 10,
                  searchQuery: query,
                ),
                showSelected: true,
                hintText: 'Select a product *',
                errorText: _errorText,
                validator: (product) {
                  if (product == null) {
                    return 'Please select a product';
                  }
                  return null;
                },
                itemBuilder: (context, product) => ListTile(
                  title: Text(product.name),
                  subtitle: Text('\$${product.price}'),
                ),
                onSelected: (product, _) {
                  setState(() {
                    _selectedProduct = product;
                    _errorText = null;
                  });
                },
              ),

              const SizedBox(height: 16),

              // With input formatter
              SmartSearchDropdown<String, String>.withProvider(
                request: const PaginationRequest(page: 1, pageSize: 10),
                provider: PaginationProvider.future(searchCountries),
                searchRequestBuilder: (query) => PaginationRequest(
                  page: 1,
                  pageSize: 10,
                  searchQuery: query,
                ),
                showSelected: true,
                hintText: 'Search country (letters only)',
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                ],
                itemBuilder: (context, country) => ListTile(
                  leading: const Icon(Icons.flag),
                  title: Text(country),
                ),
                onSelected: (country, _) {},
              ),

              const Spacer(),

              ElevatedButton(
                onPressed: () {
                  if (_selectedProduct == null) {
                    setState(() => _errorText = 'Please select a product');
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Selected: ${_selectedProduct!.name}')),
                    );
                  }
                },
                child: const Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

## Keyboard Navigation

Navigate search results with keyboard:

```dart
class KeyboardNavigationScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Keyboard Navigation')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Keyboard shortcuts info card
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.keyboard, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        Text(
                          'Keyboard Shortcuts',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                    _buildShortcutRow('↑ / ↓', 'Navigate through items'),
                    _buildShortcutRow('Enter', 'Select highlighted item'),
                    _buildShortcutRow('Escape', 'Close dropdown'),
                    _buildShortcutRow('Home', 'Jump to first item'),
                    _buildShortcutRow('End', 'Jump to last item'),
                    _buildShortcutRow('Page Up/Down', 'Jump 5 items'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Search with keyboard navigation
            SmartSearchDropdown<Product, Product>.withProvider(
              request: const PaginationRequest(page: 1, pageSize: 20),
              provider: PaginationProvider.future(searchProducts),
              searchRequestBuilder: (query) => PaginationRequest(
                page: 1,
                pageSize: 20,
                searchQuery: query,
              ),
              showSelected: true,
              hintText: 'Try keyboard navigation...',
              enableKeyboardNavigation: true,
              itemBuilder: (context, product) => ListTile(
                leading: CircleAvatar(child: Text(product.name[0])),
                title: Text(product.name),
                subtitle: Text(product.description),
                trailing: Text('\$${product.price.toStringAsFixed(2)}'),
              ),
              onSelected: (product, _) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Selected: ${product.name}')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShortcutRow(String shortcut, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Text(
              shortcut,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
          const SizedBox(width: 12),
          Text(description),
        ],
      ),
    );
  }
}
```

---

## Search Theming

Light, dark, and custom themes:

```dart
class SearchThemingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search Theming')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Auto Theme (follows system)
            const Text('Auto Theme (System)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildSearchDropdown(context),

            const SizedBox(height: 32),

            // Light Theme
            const Text('Light Theme', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Theme(
              data: Theme.of(context).copyWith(
                extensions: [SmartSearchTheme.light()],
              ),
              child: _buildSearchDropdown(context),
            ),

            const SizedBox(height: 32),

            // Dark Theme
            const Text('Dark Theme', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Theme(
              data: Theme.of(context).copyWith(
                extensions: [SmartSearchTheme.dark()],
              ),
              child: _buildSearchDropdown(context),
            ),

            const SizedBox(height: 32),

            // Custom Purple Theme
            const Text('Custom Purple Theme', style: TextStyle(fontWeight: FontWeight.bold)),
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
              child: _buildSearchDropdown(context),
            ),

            const SizedBox(height: 32),

            // Custom Green Theme
            const Text('Custom Green Theme', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Theme(
              data: Theme.of(context).copyWith(
                extensions: [
                  SmartSearchTheme(
                    searchBoxBackgroundColor: const Color(0xFFDCFCE7),
                    searchBoxTextColor: const Color(0xFF14532D),
                    searchBoxHintColor: const Color(0xFF16A34A),
                    searchBoxBorderColor: const Color(0xFF86EFAC),
                    searchBoxFocusedBorderColor: const Color(0xFF16A34A),
                    searchBoxIconColor: const Color(0xFF16A34A),
                    overlayBackgroundColor: Colors.white,
                    overlayBorderColor: const Color(0xFF86EFAC),
                    itemHoverColor: const Color(0xFFDCFCE7),
                    loadingIndicatorColor: const Color(0xFF16A34A),
                  ),
                ],
              ),
              child: _buildSearchDropdown(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchDropdown(BuildContext context) {
    return SmartSearchDropdown<Product, Product>.withProvider(
      request: const PaginationRequest(page: 1, pageSize: 10),
      provider: PaginationProvider.future(searchProducts),
      searchRequestBuilder: (query) => PaginationRequest(
        page: 1,
        pageSize: 10,
        searchQuery: query,
      ),
      hintText: 'Search products...',
      itemBuilder: (context, product) => ListTile(
        title: Text(product.name),
        subtitle: Text('\$${product.price}'),
      ),
      onSelected: (product, _) {},
    );
  }
}
```

### Available Theme Properties

| Property | Description |
|----------|-------------|
| `searchBoxBackgroundColor` | Background color of the search input |
| `searchBoxTextColor` | Text color in the search input |
| `searchBoxHintColor` | Hint text color |
| `searchBoxBorderColor` | Border color (unfocused) |
| `searchBoxFocusedBorderColor` | Border color (focused) |
| `searchBoxIconColor` | Search icon color |
| `searchBoxCursorColor` | Text cursor color |
| `overlayBackgroundColor` | Dropdown overlay background |
| `overlayBorderColor` | Dropdown overlay border |
| `overlayElevation` | Dropdown shadow elevation |
| `itemBackgroundColor` | Default item background |
| `itemHoverColor` | Item background on hover |
| `itemFocusedColor` | Item background when focused |
| `itemSelectedColor` | Selected item background |
| `loadingIndicatorColor` | Loading spinner color |
| `emptyStateIconColor` | Empty state icon color |
| `errorIconColor` | Error state icon color |

---

## Async States

Custom loading, empty, and error states:

```dart
class AsyncSearchStatesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Async States')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Custom Loading State
            const Text('Custom Loading', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SmartSearchDropdown<Product, Product>.withProvider(
              request: const PaginationRequest(page: 1, pageSize: 10),
              provider: PaginationProvider.future(searchProductsWithDelay),
              searchRequestBuilder: (query) => PaginationRequest(
                page: 1,
                pageSize: 10,
                searchQuery: query,
              ),
              hintText: 'Search (2s delay)...',
              loadingBuilder: (context) => Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const CircularProgressIndicator(strokeWidth: 2),
                    const SizedBox(height: 12),
                    Text(
                      'Searching...',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              itemBuilder: (context, product) => ListTile(
                title: Text(product.name),
              ),
              onSelected: (product, _) {},
            ),

            const SizedBox(height: 32),

            // Custom Empty State
            const Text('Custom Empty State', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SmartSearchDropdown<Product, Product>.withProvider(
              request: const PaginationRequest(page: 1, pageSize: 10),
              provider: PaginationProvider.future(
                (_) async => <Product>[], // Always returns empty
              ),
              searchRequestBuilder: (query) => PaginationRequest(
                page: 1,
                pageSize: 10,
                searchQuery: query,
              ),
              hintText: 'Search (always empty)...',
              emptyBuilder: (context) => Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 12),
                    const Text(
                      'No results found',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Try a different search term',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),
              itemBuilder: (context, product) => ListTile(
                title: Text(product.name),
              ),
              onSelected: (product, _) {},
            ),

            const SizedBox(height: 32),

            // Custom Error State
            const Text('Custom Error State', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SmartSearchDropdown<Product, Product>.withProvider(
              request: const PaginationRequest(page: 1, pageSize: 10),
              provider: PaginationProvider.future(
                (_) async => throw Exception('Network error'),
              ),
              searchRequestBuilder: (query) => PaginationRequest(
                page: 1,
                pageSize: 10,
                searchQuery: query,
              ),
              hintText: 'Search (always error)...',
              errorBuilder: (context, error, retry) => Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 12),
                    const Text(
                      'Something went wrong',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      error.toString(),
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: retry,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
              itemBuilder: (context, product) => ListTile(
                title: Text(product.name),
              ),
              onSelected: (product, _) {},
            ),
          ],
        ),
      ),
    );
  }
}
```

---

[Back to Examples](../example.md)
