# Smart Pagination

<p align="center">
  <a href="https://pub.dev/packages/smart_pagination"><img src="https://img.shields.io/pub/v/smart_pagination.svg?label=pub&color=blue" alt="Pub Version"></a>
  <a href="https://github.com/GeniusSystems24/smart_pagination/blob/main/LICENSE"><img src="https://img.shields.io/badge/license-MIT-green.svg" alt="License"></a>
  <a href="https://flutter.dev"><img src="https://img.shields.io/badge/flutter-3.9.0+-02569B?logo=flutter" alt="Flutter"></a>
  <a href="https://github.com/GeniusSystems24/smart_pagination/actions"><img src="https://img.shields.io/badge/tests-60%2B%20passed-brightgreen" alt="Tests"></a>
  <a href="https://flutter.dev"><img src="https://img.shields.io/badge/Platform-All-blueviolet?style=for-the-badge" alt="Platform"></a>
  <a href="https://geniussystems24.github.io/smart_pagination"><img src="https://img.shields.io/badge/🚀_Live_Demo-View_Online-success?style=for-the-badge" alt="Live Demo"></a>
  <a href="https://flutter.dev"><img src="https://img.shields.io/badge/Platform-All-blueviolet?style=for-the-badge" alt="Platform"></a>
  <a href="https://geniussystems24.github.io/smart_pagination"><img src="https://img.shields.io/badge/🚀_Live_Demo-View_Online-success?style=for-the-badge" alt="Live Demo"></a>
</p>

<p align="center">
  <b>A powerful, flexible, and production-ready Flutter pagination library</b><br>
  Built-in BLoC state management | Advanced error handling | Beautiful UI components
</p>

<p align="center">
  <a href="#-installation">Installation</a> •
  <a href="#-quick-start">Quick Start</a> •
  <a href="#-widget-classes">Widget Classes</a> •
  <a href="#-features">Features</a> •
  <a href="#-example-app">Examples</a>
</p>

---

> **Transport agnostic**: Bring your own async function and enjoy consistent, production-ready pagination UI.

## ✨ Why Smart Pagination?

| Feature | Description |
|---------|-------------|
| 🚀 **Zero Boilerplate** | Get paginated lists running in minutes with minimal code |
| 🎯 **7 Widget Classes** | `SmartPaginationListView`, `GridView`, `Column`, `Row`, `PageView`, `StaggeredGrid`, `ReorderableList` |
| 🎨 **6+ View Types** | ListView, GridView, PageView, StaggeredGrid, Column, Row, Custom |
| 🛡️ **Error Handling** | 6 pre-built error widget styles with state separation |
| ⚡ **Smart Preloading** | Automatically loads data before users reach the end |
| 🔄 **Real-time Support** | Works seamlessly with Streams, Futures, and merged streams |
| 📱 **State Separation** | Different UI for first page vs load more states |
| 🎛️ **Data Operations** | Programmatic add, remove, update, clear via cubit |
| ⏰ **Data Age** | Automatic data expiration and refresh for global cubits |
| 📊 **Sorting & Orders** | Programmatic sorting with multiple configurable orders |
| 🔍 **Smart Search** | Search box with auto-positioning overlay dropdown |
| 🎨 **Theme Support** | ThemeExtension with light/dark mode and full customization |
| 🧩 **Customizable** | Every aspect can be customized to match your design |
| 🎯 **Type-safe** | Full generic type support throughout the library |
| 🧪 **Well Tested** | 60+ unit tests ensuring reliability |

---

## 📚 Table of Contents

- [Installation](#-installation)
- [Quick Start](#-quick-start)
- [Widget Classes](#-widget-classes)
- [Features](#-features)
- [Smart Search](#-smart-search)
- [Data Operations](#-data-operations)
- [Data Age & Expiration](#-data-age--expiration)
- [Sorting & Orders](#-sorting--orders)
- [Error Handling](#-error-handling)
- [View Types](#-view-types)
- [Advanced Usage](#-advanced-usage)
- [Example App](#-example-app)
- [API Reference](#-api-reference)
- [Contributing](#-contributing)

---

## 📦 Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  smart_pagination: ^2.5.0
```

Install it:

```bash
flutter pub get
```

Import it:

```dart
import 'package:smart_pagination/pagination.dart';
```

---

## 🚀 Quick Start

### 1. Basic ListView Pagination

The simplest way to add pagination to your app:

```dart
import 'package:smart_pagination/pagination.dart';
import 'package:flutter/material.dart';

class ProductsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Products')),
      body: SmartPagination<Product>.withProvider(
        request: PaginationRequest(page: 1, pageSize: 20),
        provider: PaginationProvider.future(
          (request) => apiService.fetchProducts(request),
        ),
        itemBuilder: (context, items, index) {
          final product = items[index];
          return ListTile(
            leading: Image.network(product.imageUrl),
            title: Text(product.name),
            subtitle: Text('\$${product.price}'),
          );
        },
      ),
    );
  }
}
```

That's it! You now have a fully functional paginated list with:

- ✅ Automatic loading of next pages
- ✅ Loading indicators
- ✅ Error handling with retry
- ✅ Empty state handling
- ✅ Pull-to-refresh support

### 2. GridView Pagination

Switch to a grid layout by changing one line:

```dart
SmartPagination<Product>.withProvider(
  request: PaginationRequest(page: 1, pageSize: 20),
  provider: PaginationProvider.future(
    (request) => apiService.fetchProducts(request),
  ),
  itemBuilderType: PaginateBuilderType.gridView,
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2,
    childAspectRatio: 0.75,
    crossAxisSpacing: 10,
    mainAxisSpacing: 10,
  ),
  itemBuilder: (context, items, index) {
    final product = items[index];
    return ProductCard(product: product);
  },
)
```

### 3. With Custom Error Handling

Add beautiful error states:

```dart
SmartPagination<Product>.withProvider(
  request: PaginationRequest(page: 1, pageSize: 20),
  provider: PaginationProvider.future(fetchProducts),
  itemBuilder: (context, items, index) => ProductCard(items[index]),

  // Beautiful Material Design error for first page
  firstPageErrorBuilder: (context, error, retry) {
    return CustomErrorBuilder.material(
      context: context,
      error: error,
      onRetry: retry,
      title: 'Oops! Something went wrong',
      message: 'Unable to load products. Please try again.',
    );
  },

  // Compact inline error for load more
  loadMoreErrorBuilder: (context, error, retry) {
    return CustomErrorBuilder.compact(
      context: context,
      error: error,
      onRetry: retry,
    );
  },
)
```

---

## 🎯 Widget Classes

<table>
<tr>
<td><b>Widget Class</b></td>
<td><b>Layout</b></td>
<td><b>Use Case</b></td>
</tr>
<tr>
<td><code>SmartPaginationListView</code></td>
<td>Vertical/horizontal list</td>
<td>Standard lists, feeds, messages</td>
</tr>
<tr>
<td><code>SmartPaginationGridView</code></td>
<td>Multi-column grid</td>
<td>Product catalogs, image galleries</td>
</tr>
<tr>
<td><code>SmartPaginationColumn</code></td>
<td>Non-scrollable column</td>
<td>Embedded in scroll views</td>
</tr>
<tr>
<td><code>SmartPaginationRow</code></td>
<td>Non-scrollable row</td>
<td>Tags, chips, horizontal items</td>
</tr>
<tr>
<td><code>SmartPaginationPageView</code></td>
<td>Swipeable pages</td>
<td>Onboarding, image carousels</td>
</tr>
<tr>
<td><code>SmartPaginationStaggeredGridView</code></td>
<td>Masonry layout</td>
<td>Pinterest-style, mixed sizes</td>
</tr>
<tr>
<td><code>SmartPaginationReorderableListView</code></td>
<td>Drag-and-drop list</td>
<td>Task lists, priorities</td>
</tr>
</table>

### Constructor Pattern

Each widget class provides **two constructors**:

```dart
// With Provider (creates cubit internally)
SmartPaginationListView.withProvider(
  request: PaginationRequest(page: 1, pageSize: 20),
  provider: PaginationProvider.future(fetchProducts),
  itemBuilder: (context, items, index) => ProductTile(items[index]),
)

// With Cubit (uses external cubit)
SmartPaginationListView.withCubit(
  cubit: productsCubit,
  itemBuilder: (context, items, index) => ProductTile(items[index]),
)
```

### GridView Example

```dart
SmartPaginationGridView.withProvider(
  request: PaginationRequest(page: 1, pageSize: 20),
  provider: PaginationProvider.future(fetchProducts),
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
  itemBuilder: (context, items, index) => ProductCard(items[index]),
)
```

### Column Example (Non-scrollable)

```dart
SingleChildScrollView(
  child: Column(
    children: [
      Header(),
      SmartPaginationColumn.withProvider(
        request: PaginationRequest(page: 1, pageSize: 10),
        provider: PaginationProvider.future(fetchProducts),
        itemBuilder: (context, items, index) => ProductTile(items[index]),
      ),
      Footer(),
    ],
  ),
)
```

### With External Cubit (Global State)

```dart
// Create cubit with data age for automatic expiration
final productsCubit = SmartPaginationCubit<Product>(
  request: PaginationRequest(page: 1, pageSize: 20),
  provider: PaginationProvider.future(fetchProducts),
  dataAge: Duration(minutes: 5),
);

// Use anywhere in your app
SmartPaginationListView.withCubit(
  cubit: productsCubit,
  itemBuilder: (context, items, index) => ProductTile(items[index]),
)
```

> **Note**: The original `SmartPagination` class with named constructors (e.g., `SmartPagination.listViewWithProvider`) remains available for backward compatibility.

---

## ✨ Features

### 🎨 Layout Support

| Layout Type | Description | Use Case |
|------------|-------------|----------|
| **ListView** | Vertical/horizontal scrollable lists | Standard lists, feeds, messages |
| **GridView** | Multi-column grids | Product catalogs, image galleries |
| **PageView** | Swipeable pages | Onboarding, image carousels |
| **StaggeredGridView** | Pinterest-style masonry layouts | Dynamic content, mixed sizes |
| **ReorderableListView** | Drag-and-drop reordering | Task lists, priority management |
| **Custom View Builder** | Complete layout control | Unique layouts, complex UIs |

### 🛡️ Advanced Error Handling

#### 6 Pre-Built Error Widget Styles

1. **Material Design** - Full-screen error with icon, title, and message
2. **Compact** - Inline error for load more scenarios
3. **Card** - Elevated card-style error display
4. **Minimal** - Simple text-based error
5. **Snackbar** - Bottom notification-style error
6. **Custom** - Bring your own error widget

#### Error State Separation

Different error UIs for different scenarios:

- **First Page Error** - Full-screen, detailed error when initial load fails
- **Load More Error** - Compact, inline error when pagination fails

```dart
SmartPagination<Product>.withProvider(
  // ... other properties

  // Full-screen error for initial load
  firstPageErrorBuilder: (context, error, retry) {
    return CustomErrorBuilder.material(
      context: context,
      error: error,
      onRetry: retry,
    );
  },

  // Compact error for pagination
  loadMoreErrorBuilder: (context, error, retry) {
    return CustomErrorBuilder.compact(
      context: context,
      error: error,
      onRetry: retry,
    );
  },
)
```

### 🔄 Pagination Strategies

- **Offset Pagination** - Traditional page-based (`?page=2&pageSize=20`)
- **Cursor Pagination** - Efficient cursor-based (`?cursor=abc123&limit=20`)
- **Lazy Loading** - Automatic loading as user scrolls
- **Smart Preloading** - Load items 3 items before reaching the end (configurable)
- **Memory Management** - Keep only N pages in memory to optimize performance

### 📡 Data Sources

#### Future Provider (REST APIs)

```dart
PaginationProvider.future(
  (request) => apiService.fetchProducts(request),
)
```

#### Stream Provider (Real-time)

```dart
PaginationProvider.stream(
  (request) => firestore.collection('products').snapshots(),
)
```

#### Merged Streams

```dart
PaginationProvider.mergeStreams(
  (request) => [
    regularProductsStream(request),
    featuredProductsStream(request),
  ],
)
```

### 🔁 Retry Mechanisms

#### 1. Manual Retry

User clicks a button to retry:

```dart
firstPageErrorBuilder: (context, error, retry) {
  return ElevatedButton(
    onPressed: retry,
    child: Text('Try Again'),
  );
}
```

#### 2. Automatic Retry with Exponential Backoff

```dart
SmartPagination.listViewWithProvider<Product>(
  request: PaginationRequest(page: 1, pageSize: 20),
  provider: PaginationProvider.future(fetchProducts),
  retryConfig: RetryConfig(
    maxAttempts: 3,
    initialDelay: Duration(seconds: 1),
    maxDelay: Duration(seconds: 10),
    shouldRetry: (error) => error is NetworkException,
  ),
  itemBuilder: (context, items, index) => ProductCard(items[index]),
)
```

#### 3. Auto Retry with Countdown

Show a countdown timer before auto-retry

#### 4. Limited Attempts

Maximum retry attempts with exhaustion handling

See [example app](example/) for complete implementations.

### 🎯 Smart Preloading

Load data before users reach the end:

```dart
SmartPagination.listViewWithProvider<Product>(
  // ... other properties

  // Load when user is 3 items away from the end (default: 3)
  invisibleItemsThreshold: 3,
)
```

Adjust based on your needs:

- `invisibleItemsThreshold: 5` - More aggressive preloading
- `invisibleItemsThreshold: 1` - Load just before reaching end
- `invisibleItemsThreshold: 0` - Load only when reaching end

### 🔍 Filtering & Search

#### Server-Side Filtering

```dart
SmartPagination.listViewWithProvider<Product>(
  request: PaginationRequest(
    page: 1,
    pageSize: 20,
    filters: {
      'category': 'electronics',
      'minPrice': 100,
      'maxPrice': 1000,
      'search': searchQuery,
    },
  ),
  provider: PaginationProvider.future(fetchProducts),
  itemBuilder: (context, items, index) => ProductCard(items[index]),
)
```

#### Client-Side Filtering

```dart
final filterListener = SmartPaginationFilterChangeListener<Product>();

SmartPagination.withCubit(
  cubit: cubit,
  filterListeners: [filterListener],
  itemBuilder: (context, items, index) => ProductCard(items[index]),
)

// Apply filter
filterListener.searchTerm = (product) =>
  product.name.toLowerCase().contains(searchQuery.toLowerCase());
```

### ⚡ Performance Features

- **Lazy Building** - Items built only when visible
- **Smart Preloading** - Configurable preload threshold
- **Memory Optimization** - Page-based caching (`maxPagesInMemory`)
- **Efficient Rendering** - Optimized for large lists
- **Cache Extent Control** - Customize viewport caching

### 🎨 UI Customization

Every aspect of the UI can be customized:

```dart
SmartPagination.listViewWithProvider<Product>(
  request: PaginationRequest(page: 1, pageSize: 20),
  provider: PaginationProvider.future(fetchProducts),
  itemBuilder: (context, items, index) => ProductCard(items[index]),

  // Loading states
  firstPageLoadingBuilder: (context) => CustomLoader(),
  loadMoreLoadingBuilder: (context) => BottomLoader(),

  // Empty state
  firstPageEmptyBuilder: (context) => EmptyState(),

  // Error states
  firstPageErrorBuilder: (context, error, retry) => ErrorWidget(),
  loadMoreErrorBuilder: (context, error, retry) => InlineError(),

  // No more items
  loadMoreNoMoreItemsBuilder: (context) => EndOfList(),

  // Separators
  separator: Divider(),

  // Scroll behavior
  physics: BouncingScrollPhysics(),
  padding: EdgeInsets.all(16),
  shrinkWrap: true,
  reverse: false,
)
```

---

## 🔍 Smart Search

Smart Search provides a search input with an auto-positioning overlay dropdown that connects to `SmartPaginationCubit` for real-time search results.

### SmartSearchDropdown (All-in-One)

The easiest way to add search with dropdown results:

```dart
SmartSearchDropdown<Product>.withProvider(
  request: PaginationRequest(page: 1, pageSize: 20),
  provider: PaginationProvider.future((request) async {
    return await api.searchProducts(request.searchQuery ?? '');
  }),
  searchRequestBuilder: (query) => PaginationRequest(
    page: 1,
    pageSize: 20,
    searchQuery: query,
  ),
  itemBuilder: (context, product) => ListTile(
    leading: CircleAvatar(child: Text(product.name[0])),
    title: Text(product.name),
    subtitle: Text('\$${product.price}'),
  ),
  onItemSelected: (product) {
    Navigator.pop(context, product);
  },
)
```

### With External Cubit

```dart
final searchCubit = SmartPaginationCubit<Product>(
  request: PaginationRequest(page: 1, pageSize: 20),
  provider: PaginationProvider.future(searchProducts),
);

SmartSearchDropdown<Product>.withCubit(
  cubit: searchCubit,
  searchRequestBuilder: (query) => PaginationRequest(
    page: 1,
    pageSize: 20,
    searchQuery: query,
  ),
  itemBuilder: (context, product) => ListTile(
    title: Text(product.name),
  ),
  onItemSelected: (product) => print('Selected: ${product.name}'),
)
```

### Overlay Position

The dropdown automatically positions itself in the best available space. You can also force a specific position:

```dart
SmartSearchDropdown<Product>.withProvider(
  // ... other properties
  overlayConfig: SmartSearchOverlayConfig(
    position: OverlayPosition.bottom, // Force bottom position
    // position: OverlayPosition.auto, // Auto (default)
    // position: OverlayPosition.top,
    // position: OverlayPosition.left,
    // position: OverlayPosition.right,
    maxHeight: 400,
    borderRadius: 12,
    elevation: 8,
  ),
)
```

### Search Configuration

Control search behavior with `SmartSearchConfig`:

```dart
SmartSearchDropdown<Product>.withProvider(
  // ... other properties
  searchConfig: SmartSearchConfig(
    debounceDelay: Duration(milliseconds: 500), // Wait before searching
    minSearchLength: 2, // Minimum characters to trigger search
    searchOnEmpty: false, // Don't search when input is empty
    clearOnClose: true, // Clear text when overlay closes
    autoFocus: false, // Don't auto-focus on mount
  ),
)
```

### Overlay Animation Types

Choose from 13 different animation styles for the overlay show/hide transitions:

```dart
SmartSearchDropdown<Product>.withProvider(
  // ... other properties
  overlayConfig: SmartSearchOverlayConfig(
    animationType: OverlayAnimationType.bounceScale,
    animationDuration: Duration(milliseconds: 300),
    animationCurve: Curves.easeOutBack,
  ),
)
```

**Available Animation Types:**

| Animation | Description |
|-----------|-------------|
| `fade` | Simple fade in/out (default) |
| `scale` | Scale animation from center |
| `fadeScale` | Combined scale with fade |
| `slideDown` | Slide from top with fade |
| `slideUp` | Slide from bottom with fade |
| `slideLeft` | Slide from left with fade |
| `slideRight` | Slide from right with fade |
| `bounceScale` | Elastic bounce scale effect |
| `elasticScale` | Smooth elastic scale with overshoot |
| `flipX` | 3D flip on X axis |
| `flipY` | 3D flip on Y axis |
| `zoomIn` | Zoom from 50% to 100% |
| `none` | Instant show/hide, no animation |

### Overlay Value Parameter

Pass a context value when showing the overlay to determine what content to display:

```dart
// Show overlay with different values
controller.showOverlay(value: 'users');     // Search users
controller.showOverlay(value: 'products');  // Search products
controller.showOverlay(value: 1);           // Category ID

// In your widget, check the value
if (controller.overlayValue == 'users') {
  return UserSearchResults();
}

// Type-safe access
final categoryId = controller.getOverlayValue<int>(); // Returns int? or null
```

**Controller Methods:**

| Method | Description |
|--------|-------------|
| `showOverlay({Object? value})` | Show overlay with optional context value |
| `hideOverlay({bool clearValue})` | Hide overlay, optionally preserving value |
| `toggleOverlay({Object? value})` | Toggle visibility with optional value |
| `setOverlayValue(Object? value)` | Set value without showing overlay |
| `clearOverlayValue()` | Clear the overlay value |
| `getOverlayValue<V>()` | Type-safe value access |

**Properties:**

| Property | Type | Description |
|----------|------|-------------|
| `overlayValue` | `Object?` | Current overlay value |
| `hasOverlayValue` | `bool` | Whether a value is set |

### Scroll-Aware Positioning

The overlay automatically tracks the search field position during scrolling:

```dart
SmartSearchDropdown<Product>.withProvider(
  // ... other properties
  overlayConfig: SmartSearchOverlayConfig(
    followTargetOnScroll: true, // Default: true
  ),
)
```

**Features:**
- Real-time position updates during scrolling
- Automatic attachment to nearest scrollable ancestor
- Screen orientation/size change handling
- Can be disabled via `followTargetOnScroll: false`

### Separate Search Box & Overlay

For more control, use `SmartSearchBox` and `SmartSearchOverlay` separately:

```dart
// Create controller
final controller = SmartSearchController<Product>(
  cubit: productsCubit,
  searchRequestBuilder: (query) => PaginationRequest(
    page: 1,
    pageSize: 20,
    searchQuery: query,
  ),
  config: SmartSearchConfig(
    debounceDelay: Duration(milliseconds: 300),
  ),
);

// Place search box anywhere (e.g., in AppBar)
AppBar(
  title: SmartSearchBox<Product>(
    controller: controller,
    decoration: InputDecoration(
      hintText: 'Search products...',
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  ),
)

// Place overlay in your body
Scaffold(
  body: Stack(
    children: [
      YourMainContent(),
      SmartSearchOverlay<Product>(
        controller: controller,
        itemBuilder: (context, product) => ProductTile(product),
        onItemSelected: (product) {
          Navigator.push(context, ProductDetailsPage(product));
        },
      ),
    ],
  ),
)
```

### Keyboard Navigation

The search dropdown supports full keyboard navigation:

| Key | Action |
|-----|--------|
| `↓` Arrow Down | Move focus to next item / Open overlay |
| `↑` Arrow Up | Move focus to previous item / Open overlay |
| `Enter` | Select the focused item |
| `Escape` | Close the overlay |
| `Home` | Move focus to first item |
| `End` | Move focus to last item |
| `Page Down` | Move focus 5 items down |
| `Page Up` | Move focus 5 items up |

**Focus Persistence**: The focused item position is remembered when the overlay closes and restored when it reopens.

```dart
// Programmatic navigation
controller.moveToNextItem();
controller.moveToPreviousItem();
controller.setFocusedIndex(3);
controller.selectFocusedItem();

// Check focus state
if (controller.hasItemFocus) {
  print('Focused: ${controller.focusedItem}');
}
```

### Customizing Overlay Appearance

```dart
SmartSearchDropdown<Product>.withProvider(
  // ... other properties

  // Custom states
  loadingBuilder: (context) => Center(child: CircularProgressIndicator()),
  emptyBuilder: (context) => Center(child: Text('No results found')),
  errorBuilder: (context, error) => Center(child: Text('Error: $error')),

  // Header and footer
  headerBuilder: (context) => Padding(
    padding: EdgeInsets.all(8),
    child: Text('Search Results', style: TextStyle(fontWeight: FontWeight.bold)),
  ),
  footerBuilder: (context) => TextButton(
    onPressed: () {},
    child: Text('View all results'),
  ),

  // Overlay decoration
  overlayDecoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: Colors.black26,
        blurRadius: 10,
        offset: Offset(0, 4),
      ),
    ],
  ),
)
```

### Show Selected Mode

Display the selected item instead of the search box after selection:

```dart
SmartSearchDropdown<Product>.withProvider(
  // ... other properties
  showSelected: true,
  selectedItemBuilder: (context, product, onClear) => Container(
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.primaryContainer,
      borderRadius: BorderRadius.circular(12),
    ),
    child: ListTile(
      leading: CircleAvatar(child: Text(product.name[0])),
      title: Text(product.name),
      subtitle: Text('\$${product.price}'),
      trailing: IconButton(
        icon: Icon(Icons.close),
        onPressed: onClear, // Clears selection and shows search box
      ),
    ),
  ),
)
```

**Parameters:**

| Parameter | Description |
|-----------|-------------|
| `showSelected` | When true, shows selected item instead of search box |
| `selectedItemBuilder` | Custom builder for the selected item display |
| `initialSelectedValue` | Pre-selected item to display on widget load |

**Controller Methods:**

```dart
// Access selected item
final item = controller.selectedItem;
if (controller.hasSelectedItem) { ... }

// Programmatic control
controller.setSelectedItem(product);
controller.clearSelection(); // Shows search box again
```

### Form Validation & Input Formatting

SmartSearchDropdown supports form validation and input formatting for integration with Flutter forms:

```dart
SmartSearchDropdown<Product>.withProvider(
  // ... other properties

  // Pre-select an item
  initialSelectedValue: preSelectedProduct,

  // Form validation
  validator: (value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a search term';
    }
    if (value.length < 3) {
      return 'Search term must be at least 3 characters';
    }
    return null;
  },
  autovalidateMode: AutovalidateMode.onUserInteraction,

  // Input formatting
  inputFormatters: [
    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\s]')),
    LengthLimitingTextInputFormatter(50),
  ],
  maxLength: 50,

  // Keyboard options
  textInputAction: TextInputAction.search,
  textCapitalization: TextCapitalization.words,
  keyboardType: TextInputType.text,

  // Text change callback
  onChanged: (value) {
    print('Search text: $value');
  },
)
```

**Parameters:**

| Parameter | Type | Description |
|-----------|------|-------------|
| `initialSelectedValue` | `T?` | Pre-selected item to display on widget load |
| `validator` | `String? Function(String?)?` | Form validation function (uses TextFormField) |
| `autovalidateMode` | `AutovalidateMode?` | When to validate the input |
| `inputFormatters` | `List<TextInputFormatter>?` | Input formatters for text formatting |
| `maxLength` | `int?` | Maximum input length |
| `textInputAction` | `TextInputAction` | Keyboard action button (default: search) |
| `textCapitalization` | `TextCapitalization` | Text capitalization behavior |
| `keyboardType` | `TextInputType` | Type of keyboard to display |
| `onChanged` | `ValueChanged<String>?` | Called when text changes |

**Usage in Forms:**

```dart
final _formKey = GlobalKey<FormState>();

Form(
  key: _formKey,
  child: Column(
    children: [
      SmartSearchDropdown<Product>.withProvider(
        // ... properties
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Required field';
          }
          return null;
        },
      ),
      ElevatedButton(
        onPressed: () {
          if (_formKey.currentState!.validate()) {
            // Form is valid
          }
        },
        child: Text('Submit'),
      ),
    ],
  ),
)
```

### SmartSearchMultiDropdown

Multi-selection search dropdown that allows selecting multiple items from search results:

```dart
SmartSearchMultiDropdown<Product>.withProvider(
  request: PaginationRequest(page: 1, pageSize: 20),
  provider: PaginationProvider.future(fetchProducts),
  searchRequestBuilder: (query) => PaginationRequest(
    page: 1,
    pageSize: 20,
    searchQuery: query,
  ),
  itemBuilder: (context, product) => ListTile(
    title: Text(product.name),
    subtitle: Text('\$${product.price}'),
  ),
  showSelected: true, // Show selected items below search box
  maxSelections: 5, // Optional: limit selections
  onSelectionChanged: (products) {
    print('Selected ${products.length} items');
  },
)
```

**Custom Selected Item Display:**

```dart
SmartSearchMultiDropdown<Product>.withProvider(
  // ... other properties
  selectedItemBuilder: (context, product, onRemove) => Chip(
    avatar: CircleAvatar(child: Text(product.name[0])),
    label: Text(product.name),
    onDeleted: onRemove,
  ),
  selectedItemsWrap: true, // Wrap items or horizontal scroll
  selectedItemsSpacing: 8.0,
  selectedItemsRunSpacing: 8.0,
)
```

**Parameters:**

| Parameter | Type | Description |
|-----------|------|-------------|
| `onSelectionChanged` | `ValueChanged<List<T>>?` | Called when selection changes |
| `initialSelectedValues` | `List<T>?` | Pre-selected items |
| `maxSelections` | `int?` | Maximum selectable items |
| `showSelected` | `bool` | Show selected items below search |
| `selectedItemBuilder` | `Widget Function(...)` | Custom chip builder |
| `selectedItemsWrap` | `bool` | Wrap items (true) or scroll (false) |

**Controller Methods:**

```dart
// Selection state
controller.selectedItems; // Get all selected items
controller.selectionCount; // Number of selections
controller.isItemSelected(item); // Check if item is selected
controller.isMaxSelectionsReached; // Check if limit reached

// Modify selection
controller.addItem(item);
controller.removeItem(item);
controller.toggleItemSelection(item);
controller.clearAllSelections();
```

### SmartSearchTheme (Light & Dark Mode)

SmartSearch widgets support theming via Flutter's `ThemeExtension` pattern:

```dart
// Add to your MaterialApp
MaterialApp(
  theme: ThemeData.light().copyWith(
    extensions: [SmartSearchTheme.light()],
  ),
  darkTheme: ThemeData.dark().copyWith(
    extensions: [SmartSearchTheme.dark()],
  ),
)
```

**Custom Theme:**

```dart
SmartSearchTheme(
  // Search Box
  searchBoxBackgroundColor: Colors.grey[100],
  searchBoxTextColor: Colors.black87,
  searchBoxHintColor: Colors.grey[500],
  searchBoxBorderColor: Colors.grey[300],
  searchBoxFocusedBorderColor: Colors.blue,
  searchBoxIconColor: Colors.grey[600],

  // Overlay
  overlayBackgroundColor: Colors.white,
  overlayBorderRadius: BorderRadius.circular(12),
  overlayElevation: 8,

  // Items
  itemHoverColor: Colors.grey[100],
  itemFocusedColor: Colors.blue.withOpacity(0.1),
  itemDividerColor: Colors.grey[200],

  // States
  loadingIndicatorColor: Colors.blue,
  emptyStateIconColor: Colors.grey[400],
  errorIconColor: Colors.red,

  // Scrollbar
  scrollbarColor: Colors.grey[400],
  scrollbarThickness: 6,
)
```

**Access Theme in Widgets:**

```dart
// Get theme with fallback to light theme
final theme = SmartSearchTheme.of(context);

// Get theme or null if not set
final theme = SmartSearchTheme.maybeOf(context);
```

**Theme Properties:**

| Category | Properties |
|----------|------------|
| **Search Box** | `searchBoxBackgroundColor`, `searchBoxTextColor`, `searchBoxHintColor`, `searchBoxBorderColor`, `searchBoxFocusedBorderColor`, `searchBoxIconColor`, `searchBoxCursorColor`, `searchBoxBorderRadius` |
| **Overlay** | `overlayBackgroundColor`, `overlayBorderColor`, `overlayBorderRadius`, `overlayElevation`, `overlayShadowColor` |
| **Items** | `itemBackgroundColor`, `itemHoverColor`, `itemFocusedColor`, `itemSelectedColor`, `itemTextColor`, `itemSubtitleColor`, `itemIconColor`, `itemDividerColor` |
| **States** | `loadingIndicatorColor`, `emptyStateIconColor`, `emptyStateTextColor`, `errorIconColor`, `errorTextColor`, `errorButtonColor` |
| **Scrollbar** | `scrollbarColor`, `scrollbarThickness`, `scrollbarRadius` |

---

## 🎛️ Data Operations

The `SmartPaginationCubit` provides powerful data manipulation methods that can be called from anywhere in your app. These operations automatically update the UI.

### Accessing the Cubit

```dart
// Create and store the cubit reference
late SmartPaginationCubit<Product> cubit;

@override
void initState() {
  super.initState();
  cubit = SmartPaginationCubit<Product>(
    request: PaginationRequest(page: 1, pageSize: 20),
    provider: PaginationProvider.future(fetchProducts),
  );
}

// Use in your widget
SmartPagination.listViewWithCubit<Product>(
  cubit: cubit,
  itemBuilder: (context, items, index) => ProductCard(items[index]),
)
```

### Insert Operations

#### Insert Single Item

```dart
// Insert at the beginning (default)
cubit.insertEmit(newProduct);

// Insert at specific index
cubit.insertEmit(newProduct, index: 5);
```

#### Insert Multiple Items

```dart
cubit.insertAllEmit([product1, product2, product3]);
cubit.insertAllEmit(newProducts, index: 10);
```

### Remove Operations

#### Remove by Item

```dart
final wasRemoved = cubit.removeItemEmit(productToRemove);
if (wasRemoved) {
  print('Product removed successfully');
}
```

#### Remove by Index

```dart
final removedItem = cubit.removeAtEmit(0);
if (removedItem != null) {
  print('Removed: ${removedItem.name}');
}
```

#### Remove by Condition

```dart
// Remove all products with price > 100
final count = cubit.removeWhereEmit((item) => item.price > 100);
print('Removed $count expensive products');

// Remove out-of-stock items
cubit.removeWhereEmit((item) => item.stock == 0);
```

### Update Operations

#### Update Single Item

```dart
final wasUpdated = cubit.updateItemEmit(
  (item) => item.id == '123',  // Find item
  (item) => item.copyWith(     // Update it
    price: item.price * 0.9,   // 10% discount
  ),
);
```

#### Update Multiple Items

```dart
// Apply discount to all sale items
final count = cubit.updateWhereEmit(
  (item) => item.category == 'sale',
  (item) => item.copyWith(price: item.price * 0.8),
);
print('Updated $count items');

// Mark all as featured
cubit.updateWhereEmit(
  (item) => true,
  (item) => item.copyWith(isFeatured: true),
);
```

### Other Operations

#### Clear All Items

```dart
cubit.clearItems();
```

#### Reload from Server

```dart
cubit.reload();
```

#### Set Custom Items

```dart
// Replace all items with a new list
cubit.setItems(customProductList);
```

#### Access Current Items

```dart
final items = cubit.currentItems;
print('Total items: ${items.length}');

// Find specific item
final featured = items.where((item) => item.isFeatured).toList();
```

### Real-World Examples

#### Shopping Cart - Add to Cart

```dart
void addToCart(Product product) {
  cartCubit.addOrUpdateEmit(
    CartItem(product: product, quantity: 1),
  );
}
```

#### Todo App - Toggle Complete

```dart
void toggleTodo(String todoId) {
  todoCubit.updateItemEmit(
    (item) => item.id == todoId,
    (item) => item.copyWith(isCompleted: !item.isCompleted),
  );
}
```

#### Chat App - Delete Message

```dart
void deleteMessage(Message message) {
  chatCubit.removeItemEmit(message);
}
```

#### Inventory - Update Stock

```dart
void updateStock(String productId, int newStock) {
  inventoryCubit.updateItemEmit(
    (item) => item.id == productId,
    (item) => item.copyWith(stock: newStock),
  );
}
```

#### Bulk Operations

```dart
// Remove all completed tasks
taskCubit.removeWhereEmit((task) => task.isCompleted);

// Apply bulk discount
productCubit.updateWhereEmit(
  (product) => product.category == 'clearance',
  (product) => product.copyWith(price: product.price * 0.5),
);
```

---

## ⏰ Data Age & Expiration

The `dataAge` feature allows automatic data invalidation and refresh when using the cubit as a global variable. This is perfect for scenarios where you want to keep the cubit alive across screen navigations but ensure data freshness.

### Basic Usage

```dart
// Create a global cubit with data expiration
final productsCubit = SmartPaginationCubit<Product>(
  request: PaginationRequest(page: 1, pageSize: 20),
  provider: PaginationProvider.future(fetchProducts),
  dataAge: Duration(minutes: 5), // Data expires after 5 minutes
);
```

### How It Works

1. When data is successfully fetched, the `lastFetchTime` is recorded
2. When `fetchPaginatedList()` is called (e.g., when re-entering a screen), it checks if data has expired
3. If `dataAge` duration has passed since `lastFetchTime`, the cubit automatically:
   - Clears all cached data
   - Resets to initial state
   - Triggers a fresh data load

**Timer Auto-Refresh:** The timer resets on any data interaction (insert, update, remove, load more). This ensures active users don't experience unexpected data resets while using the list.

### Available Properties

```dart
// Check if data has expired
if (cubit.isDataExpired) {
  print('Data is stale');
}

// Get the last fetch timestamp
final lastFetch = cubit.lastFetchTime;

// Get the configured data age
final age = cubit.dataAge;

// Manually check and reset if expired (returns true if reset occurred)
final wasReset = cubit.checkAndResetIfExpired();
```

### Accessing Expiration Info from State

```dart
BlocBuilder<SmartPaginationCubit<Product>, SmartPaginationState<Product>>(
  builder: (context, state) {
    if (state is SmartPaginationLoaded<Product>) {
      // When the data was fetched
      final fetchedAt = state.fetchedAt;

      // When the data will expire (null if no dataAge configured)
      final expiresAt = state.dataExpiredAt;

      if (expiresAt != null) {
        final remaining = expiresAt.difference(DateTime.now());
        print('Data expires in ${remaining.inMinutes} minutes');
      }
    }
    return YourWidget();
  },
)
```

### Use Case: Global Cubit with Auto-Refresh

```dart
// In your dependency injection or global state
class AppState {
  static final productsCubit = SmartPaginationCubit<Product>(
    request: PaginationRequest(page: 1, pageSize: 20),
    provider: PaginationProvider.future(ApiService.fetchProducts),
    dataAge: Duration(minutes: 10), // Refresh data every 10 minutes
  );
}

// In your screen
class ProductsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SmartPagination.listViewWithCubit(
      cubit: AppState.productsCubit,
      itemBuilder: (context, items, index) => ProductCard(items[index]),
    );
  }
}

// When user navigates to ProductsScreen after 10+ minutes,
// data will automatically refresh!
```

### Configuration Options

| Duration | Use Case |
|----------|----------|
| `Duration(seconds: 30)` | Real-time dashboards |
| `Duration(minutes: 5)` | Frequently updated content |
| `Duration(minutes: 30)` | Standard content lists |
| `Duration(hours: 1)` | Relatively static content |
| `null` (default) | Never expires automatically |

---

## 📊 Sorting & Orders

The `orders` feature provides powerful programmatic control over item sorting. Configure sort orders at initialization or modify them dynamically at runtime.

### Basic Usage

```dart
// Define sort orders
final orders = SortOrderCollection<Product>(
  orders: [
    SortOrder.byField(
      id: 'name_asc',
      label: 'Name (A-Z)',
      fieldSelector: (p) => p.name,
      direction: SortDirection.ascending,
    ),
    SortOrder.byField(
      id: 'price_low',
      label: 'Price: Low to High',
      fieldSelector: (p) => p.price,
      direction: SortDirection.ascending,
    ),
    SortOrder.byField(
      id: 'price_high',
      label: 'Price: High to Low',
      fieldSelector: (p) => p.price,
      direction: SortDirection.descending,
    ),
  ],
  defaultOrderId: 'name_asc',
);

// Create cubit with orders
final cubit = SmartPaginationCubit<Product>(
  request: PaginationRequest(page: 1, pageSize: 20),
  provider: PaginationProvider.future(fetchProducts),
  orders: orders,
);
```

### Changing Sort Order

```dart
// Change sort order programmatically
cubit.setActiveOrder('price_low');  // Sort by price (low to high)
cubit.setActiveOrder('price_high'); // Sort by price (high to low)

// Reset to default order
cubit.resetOrder();

// Clear sorting (original server order)
cubit.clearOrder();
```

### Custom Comparator

```dart
// Using custom comparator for complex sorting
final customOrder = SortOrder<Product>(
  id: 'rating_stock',
  label: 'Rating & Stock',
  comparator: (a, b) {
    // Sort by rating first, then by stock
    final ratingCompare = b.rating.compareTo(a.rating);
    if (ratingCompare != 0) return ratingCompare;
    return b.stock.compareTo(a.stock);
  },
);

cubit.addSortOrder(customOrder);
cubit.setActiveOrder('rating_stock');
```

### Dynamic Sort Orders

```dart
// Add sort order at runtime
cubit.addSortOrder(SortOrder.byField(
  id: 'newest',
  label: 'Newest First',
  fieldSelector: (p) => p.createdAt,
  direction: SortDirection.descending,
));

// Remove sort order
cubit.removeSortOrder('newest');

// Replace entire orders collection
cubit.setOrders(newOrdersCollection);
```

### One-Time Sort

```dart
// Sort without changing active order
cubit.sortBy((a, b) => a.stock.compareTo(b.stock));
```

### Accessing Sort State

```dart
// Get current active order
final activeOrder = cubit.activeOrder;
final activeOrderId = cubit.activeOrderId;

// Get all available orders
final allOrders = cubit.availableOrders;

// Access from state
BlocBuilder<SmartPaginationCubit<Product>, SmartPaginationState<Product>>(
  builder: (context, state) {
    if (state is SmartPaginationLoaded<Product>) {
      print('Current sort: ${state.activeOrderId}');
    }
    return YourWidget();
  },
)
```

### Sort Order Dropdown Example

```dart
DropdownButton<String>(
  value: cubit.activeOrderId,
  items: cubit.availableOrders.map((order) {
    return DropdownMenuItem(
      value: order.id,
      child: Text(order.label),
    );
  }).toList(),
  onChanged: (orderId) {
    if (orderId != null) {
      cubit.setActiveOrder(orderId);
    }
  },
)
```

### Available Properties

| Property | Type | Description |
|----------|------|-------------|
| `orders` | `SortOrderCollection<T>?` | Current sort order collection |
| `activeOrder` | `SortOrder<T>?` | Currently active sort order |
| `activeOrderId` | `String?` | ID of active sort order |
| `availableOrders` | `List<SortOrder<T>>` | All available sort orders |

### Available Methods

| Method | Description |
|--------|-------------|
| `setActiveOrder(String id)` | Set active sort by ID |
| `resetOrder()` | Reset to default order |
| `clearOrder()` | Remove sorting |
| `addSortOrder(SortOrder order)` | Add new sort order |
| `removeSortOrder(String id)` | Remove sort order |
| `sortBy(comparator)` | One-time custom sort |
| `setOrders(collection)` | Replace orders collection |

---

## 🛡️ Error Handling

### 6 Error Widget Styles

#### 1. Material Design (Recommended for First Page Errors)

<details>
<summary>View example</summary>

```dart
CustomErrorBuilder.material(
  context: context,
  error: error,
  onRetry: retry,
  title: 'Failed to Load Products',
  message: 'Please check your internet connection and try again.',
  icon: Icons.cloud_off,
  iconColor: Colors.blue,
  retryButtonText: 'Retry',
)
```

**Best for**: First page errors, initial load failures
**Style**: Full-screen with large icon, title, message, and prominent retry button
</details>

#### 2. Compact (Recommended for Load More Errors)

<details>
<summary>View example</summary>

```dart
CustomErrorBuilder.compact(
  context: context,
  error: error,
  onRetry: retry,
  message: 'Failed to load more items',
  backgroundColor: Colors.red[50],
  textColor: Colors.red[900],
)
```

**Best for**: Load more errors, inline errors
**Style**: Compact inline widget with message and small retry button
</details>

#### 3. Card Style

<details>
<summary>View example</summary>

```dart
CustomErrorBuilder.card(
  context: context,
  error: error,
  onRetry: retry,
  title: 'Products Unavailable',
  message: 'We couldn\'t fetch the products at this time.',
  elevation: 4,
)
```

**Best for**: Mixed content layouts, card-based UIs
**Style**: Elevated card with shadow, title, message, and retry button
</details>

#### 4. Minimal

<details>
<summary>View example</summary>

```dart
CustomErrorBuilder.minimal(
  context: context,
  error: error,
  onRetry: retry,
  message: 'Something went wrong',
)
```

**Best for**: Simple UIs, minimal designs
**Style**: Text message with small retry link
</details>

#### 5. Snackbar

<details>
<summary>View example</summary>

```dart
CustomErrorBuilder.snackbar(
  context: context,
  error: error,
  onRetry: retry,
  message: 'Failed to load data',
  backgroundColor: Colors.red,
)
```

**Best for**: Non-blocking errors, temporary notifications
**Style**: Bottom notification bar with message and action
</details>

#### 6. Custom

<details>
<summary>View example</summary>

```dart
CustomErrorBuilder.custom(
  context: context,
  error: error,
  onRetry: retry,
  builder: (context, error, retry) {
    return MyCustomErrorWidget(
      error: error,
      onRetry: retry,
    );
  },
)
```

**Best for**: Unique designs, branded error pages
**Style**: Completely custom - you control everything
</details>

### Error Recovery Strategies

The library supports multiple error recovery strategies:

#### 1. Cached Data Fallback

Show offline/cached data when fresh data fails to load

#### 2. Partial Data Display

Display whatever data loaded successfully before the error occurred

#### 3. Alternative Source

Switch to a backup data source (e.g., backup server, CDN)

#### 4. User-Initiated Recovery

Require user action to resolve (e.g., login, grant permissions)

#### 5. Graceful Degradation

Continue with limited functionality in offline/error mode

See [docs/ERROR_HANDLING.md](docs/ERROR_HANDLING.md) and the [example app](example/lib/screens/errors/) for complete implementations.

### Custom Exception Types

Define your own exception types for better error handling:

```dart
class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);

  @override
  String toString() => 'NetworkException: $message';
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);

  @override
  String toString() => 'TimeoutException: $message';
}

class ServerException implements Exception {
  final int statusCode;
  final String message;
  ServerException(this.statusCode, this.message);

  @override
  String toString() => 'ServerException($statusCode): $message';
}

// Use in error builders
firstPageErrorBuilder: (context, error, retry) {
  if (error is NetworkException) {
    return NetworkErrorWidget(onRetry: retry);
  } else if (error is TimeoutException) {
    return TimeoutErrorWidget(onRetry: retry);
  } else if (error is ServerException) {
    return ServerErrorWidget(statusCode: error.statusCode, onRetry: retry);
  }
  return CustomErrorBuilder.material(context: context, error: error, onRetry: retry);
}
```

### Error Illustrations

The library includes an `ErrorImages` helper for beautiful error illustrations:

```dart
CustomErrorBuilder.material(
  context: context,
  error: error,
  onRetry: retry,
  title: 'No Internet Connection',
  message: 'Please check your connection and try again',
  // Add custom image above the error
  customChild: ErrorImages.network(
    width: 200,
    height: 200,
    fallbackColor: Colors.orange,
  ),
)
```

**Available images**:

- `ErrorImages.general()` - General error
- `ErrorImages.network()` - Network/connectivity error
- `ErrorImages.notFound()` - 404 not found
- `ErrorImages.serverError()` - 500 server error
- `ErrorImages.timeout()` - Request timeout
- `ErrorImages.auth()` - Authentication error
- `ErrorImages.offline()` - Offline mode
- `ErrorImages.empty()` - Empty state
- `ErrorImages.retry()` - Retry icon
- `ErrorImages.recovery()` - Recovery icon
- `ErrorImages.loadingError()` - Load more error
- `ErrorImages.custom()` - Custom error

**Features**:

- Automatic fallback to icons if images fail to load
- Customizable width, height, and fallback colors
- Free illustration sources guide included

See [docs/ERROR_IMAGES_SETUP.md](docs/ERROR_IMAGES_SETUP.md) for setup instructions.

---

## 🎨 View Types

### 1. ListView

Standard vertical or horizontal scrolling list.

```dart
SmartPagination.listViewWithProvider<Product>(
  request: PaginationRequest(page: 1, pageSize: 20),
  provider: PaginationProvider.future(fetchProducts),
  itemBuilder: (context, items, index) {
    final product = items[index];
    return ListTile(
      leading: Image.network(product.imageUrl),
      title: Text(product.name),
      subtitle: Text('\$${product.price}'),
      trailing: Icon(Icons.arrow_forward_ios),
    );
  },
  separator: Divider(),
)
```

**Properties**:

- `scrollDirection`: `Axis.vertical` (default) or `Axis.horizontal`
- `shrinkWrap`: `true` to fit content
- `reverse`: `true` for bottom-to-top scrolling
- `separatorBuilder`: Add dividers between items

### 2. GridView

Multi-column grid layout.

```dart
SmartPagination.gridViewWithProvider<Product>(
  request: PaginationRequest(page: 1, pageSize: 20),
  provider: PaginationProvider.future(fetchProducts),
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2,
    childAspectRatio: 0.75,
    crossAxisSpacing: 10,
    mainAxisSpacing: 10,
  ),
  itemBuilder: (context, items, index) {
    final product = items[index];
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Image.network(
              product.imageUrl,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: TextStyle(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),
                Text('\$${product.price}'),
              ],
            ),
          ),
        ],
      ),
    );
  },
)
```

### 3. Column (Non-scrollable)

A non-scrollable column layout, useful when you want to embed the list inside another scroll view (e.g., `SingleChildScrollView`).

```dart
SingleChildScrollView(
  child: Column(
    children: [
      HeaderWidget(),
      SmartPagination.columnWithProvider<Product>(
        request: PaginationRequest(page: 1, pageSize: 5),
        provider: PaginationProvider.future(fetchProducts),
        itemBuilder: (context, items, index) => ProductTile(items[index]),
        separator: Divider(),
      ),
      FooterWidget(),
    ],
  ),
)
```

### 4. PageView

Swipeable full-screen pages.

```dart
SmartPagination.pageViewWithCubit(
  cubit: cubit,
  itemBuilder: (context, items, index) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: ProductDetailView(product: items[index]),
    );
  },
  scrollDirection: Axis.horizontal,
)
```

**Use cases**:

- Image carousels
- Onboarding flows
- Full-screen product views
- Story-style content

### 4. StaggeredGridView

Pinterest-style masonry layout with varying item sizes.

```dart
SmartPagination.staggeredGridViewWithCubit(
  cubit: cubit,
  crossAxisCount: 2,
  itemBuilder: (context, items, index) {
    final product = items[index];
    return StaggeredGridTile.fit(
      crossAxisCellCount: 1,
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(
              product.imageUrl,
              fit: BoxFit.cover,
            ),
            Padding(
              padding: EdgeInsets.all(8),
              child: Text(product.name),
            ),
          ],
        ),
      ),
    );
  },
)
```

**Use cases**:

- Pinterest-style galleries
- Mixed-size content
- Dynamic height items
- Photo galleries

### 5. ReorderableListView

Drag-and-drop list reordering.

```dart
SmartPagination.reorderableListViewWithCubit(
  cubit: cubit,
  itemBuilder: (context, items, index) {
    return ListTile(
      key: ValueKey(items[index].id),
      leading: Icon(Icons.drag_handle),
      title: Text(items[index].name),
      subtitle: Text('Priority: ${index + 1}'),
    );
  },
  onReorder: (oldIndex, newIndex) {
    // Handle reordering logic
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final item = items.removeAt(oldIndex);
    items.insert(newIndex, item);
  },
)
```

**Use cases**:

- Task lists
- Priority management
- Playlist organization
- Custom ordering

### 6. Custom View Builder

Complete control over the layout.

```dart
SmartPagination.withCubit(
  cubit: cubit,
  itemBuilderType: PaginateBuilderType.custom,
  customViewBuilder: (context, items, hasReachedEnd, fetchMore) {
    return Column(
      children: [
        // Your custom header
        Container(
          padding: EdgeInsets.all(16),
          child: Text('Found ${items.length} items'),
        ),

        // Your custom layout
        Expanded(
          child: YourCustomLayout(
            items: items,
            onLoadMore: fetchMore,
            isLastPage: hasReachedEnd,
          ),
        ),

        // Your custom footer
        if (!hasReachedEnd)
          TextButton(
            onPressed: fetchMore,
            child: Text('Load More'),
          ),
      ],
    );
  },
)
```

**Use cases**:

- Unique layouts
- Complex UIs
- Mixed view types
- Custom interactions

---

## 🚀 Advanced Usage

### Stream Support

#### Real-time Updates (Single Stream)

```dart
SmartPagination.listViewWithProvider<Message>(
  request: PaginationRequest(page: 1, pageSize: 50),
  provider: PaginationProvider.stream(
    (request) => firestore
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(request.pageSize)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Message.fromDoc(doc)).toList()),
  ),
  itemBuilder: (context, items, index) {
    return MessageBubble(message: items[index]);
  },
)
```

#### Multiple Streams

Switch between different data streams:

```dart
class ProductsPage extends StatefulWidget {
  @override
  _ProductsPageState createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  String selectedStream = 'all';

  Stream<List<Product>> getStream(PaginationRequest request) {
    switch (selectedStream) {
      case 'featured':
        return apiService.featuredProductsStream(request);
      case 'sale':
        return apiService.saleProductsStream(request);
      default:
        return apiService.allProductsStream(request);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Products'),
        actions: [
          DropdownButton<String>(
            value: selectedStream,
            items: [
              DropdownMenuItem(value: 'all', child: Text('All')),
              DropdownMenuItem(value: 'featured', child: Text('Featured')),
              DropdownMenuItem(value: 'sale', child: Text('On Sale')),
            ],
            onChanged: (value) => setState(() => selectedStream = value!),
          ),
        ],
      ),
      body: SmartPagination.listViewWithProvider<Product>(
        key: ValueKey(selectedStream), // Force rebuild on stream change
        request: PaginationRequest(page: 1, pageSize: 20),
        provider: PaginationProvider.stream(getStream),
        itemBuilder: (context, items, index) => ProductCard(items[index]),
      ),
    );
  }
}
```

#### Merged Streams

Combine multiple streams into one:

```dart
SmartPagination.listViewWithProvider<Product>(
  request: PaginationRequest(page: 1, pageSize: 20),
  provider: PaginationProvider.mergeStreams(
    (request) => [
      apiService.regularProductsStream(request),
      apiService.featuredProductsStream(request),
      apiService.saleProductsStream(request),
    ],
  ),
  itemBuilder: (context, items, index) => ProductCard(items[index]),
)
```

### External Cubit & State Management

If you need to manage the `SmartPaginationCubit` externally (e.g., for dependency injection or sharing state), use the `...WithCubit` named constructors:

- `SmartPagination.listViewWithCubit`
- `SmartPagination.gridViewWithCubit`
- `SmartPagination.columnWithCubit`
- `SmartPagination.pageViewWithCubit`
- `SmartPagination.staggeredGridViewWithCubit`
- `SmartPagination.rowWithCubit`
- `SmartPagination.reorderableListViewWithCubit`

```dart
class MyPage extends StatefulWidget {
  @override
  _MyPageState createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  late SmartPaginationCubit<Product> _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = SmartPaginationCubit<Product>(
      request: PaginationRequest(page: 1, pageSize: 20),
      provider: PaginationProvider.future(fetchProducts),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SmartPagination.listViewWithCubit<Product>(
      cubit: _cubit,
      itemBuilder: (context, items, index) => ProductCard(items[index]),
    );
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }
}
```

### Scroll Control

Programmatic scrolling to specific items or indices:

```dart
final controller = SmartPaginationController<Product>();

class ProductsPage extends StatefulWidget {
  @override
  _ProductsPageState createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  late SmartPaginationCubit<Product> cubit;

  @override
  void initState() {
    super.initState();
    cubit = SmartPaginationCubit<Product>(
      request: PaginationRequest(page: 1, pageSize: 20),
      provider: PaginationProvider.future(fetchProducts),
    )..controller = controller;
  }

  void scrollToProduct(Product product) {
    controller.scrollToItem(
      product,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void scrollToIndex(int index) {
    controller.scrollToIndex(
      index,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Products'),
        actions: [
          IconButton(
            icon: Icon(Icons.arrow_upward),
            onPressed: () => scrollToIndex(0), // Scroll to top
          ),
        ],
      ),
      body: SmartPagination.withCubit(
        cubit: cubit,
        itemBuilder: (context, items, index) => ProductCard(items[index]),
      ),
    );
  }

  @override
  void dispose() {
    cubit.close();
    super.dispose();
  }
}
```

### Before Build Hook

Transform state before rendering:

```dart
SmartPagination.listViewWithProvider<Product>(
  request: PaginationRequest(page: 1, pageSize: 20),
  provider: PaginationProvider.future(fetchProducts),
  itemBuilder: (context, items, index) => ProductCard(items[index]),

  // Sort items before rendering
  beforeBuild: (state) {
    if (state is SmartPaginationLoaded<Product>) {
      final sortedItems = state.items.toList()
        ..sort((a, b) => a.price.compareTo(b.price));
      return state.copyWith(items: sortedItems);
    }
    return state;
  },
)
```

### List Builder

Transform items in the cubit before emission:

```dart
SmartPaginationCubit<Product>(
  request: PaginationRequest(page: 1, pageSize: 20),
  provider: PaginationProvider.future(fetchProducts),

  // Remove duplicates
  listBuilder: (items) {
    return items.toSet().toList();
  },
)
```

### Callbacks

React to pagination events:

```dart
SmartPaginationCubit<Product>(
  request: PaginationRequest(page: 1, pageSize: 20),
  provider: PaginationProvider.future(fetchProducts),

  onInsertionCallback: (items) {
    print('Loaded ${items.length} new items');
    analytics.logEvent('items_loaded', {'count': items.length});
  },

  onReachedEnd: () {
    print('Reached end of pagination');
    showSnackBar('No more items to load');
  },

  onClear: () {
    print('Pagination list cleared');
  },
)
```

### Pull to Refresh

Add swipe-down-to-refresh functionality:

```dart
final refreshListener = SmartPaginationRefreshedChangeListener();

class ProductsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        refreshListener.refreshed = true;
        await Future.delayed(Duration(seconds: 1));
      },
      child: SmartPagination.listViewWithProvider<Product>(
        request: PaginationRequest(page: 1, pageSize: 20),
        provider: PaginationProvider.future(fetchProducts),
        refreshListener: refreshListener,
        itemBuilder: (context, items, index) => ProductCard(items[index]),
      ),
    );
  }
}
```

### Memory Management

Optimize memory usage for large datasets:

```dart
SmartPaginationCubit<Product>(
  request: PaginationRequest(page: 1, pageSize: 20),
  provider: PaginationProvider.future(fetchProducts),

  // Keep only 5 pages in memory (100 items with pageSize=20)
  // Older pages are automatically removed
  maxPagesInMemory: 5,
)
```

### Custom Loading States

Customize loading indicators for different states:

```dart
SmartPagination.listViewWithProvider<Product>(
  request: PaginationRequest(page: 1, pageSize: 20),
  provider: PaginationProvider.future(fetchProducts),
  itemBuilder: (context, items, index) => ProductCard(items[index]),

  // Full-screen loading for first page
  firstPageLoadingBuilder: (context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading products...'),
        ],
      ),
    );
  },

  // Bottom loading for pagination
  loadMoreLoadingBuilder: (context) {
    return Container(
      padding: EdgeInsets.all(16),
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 12),
          Text('Loading more...'),
        ],
      ),
    );
  },
)
```

### Custom Empty States

Show custom UI when no data is available:

```dart
SmartPagination.listViewWithProvider<Product>(
  request: PaginationRequest(page: 1, pageSize: 20),
  provider: PaginationProvider.future(fetchProducts),
  itemBuilder: (context, items, index) => ProductCard(items[index]),

  firstPageEmptyBuilder: (context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_basket_outlined,
            size: 100,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'No Products Found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Try adjusting your filters',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  },
)
```

### Cursor-Based Pagination

Efficient pagination for large datasets:

```dart
// Your API response model
class PaginatedResponse<T> {
  final List<T> items;
  final String? nextCursor;
  final bool hasMore;

  PaginatedResponse({
    required this.items,
    this.nextCursor,
    required this.hasMore,
  });
}

// Use cursor in pagination
class ProductsPage extends StatefulWidget {
  @override
  _ProductsPageState createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  String? nextCursor;

  Future<List<Product>> fetchProducts(PaginationRequest request) async {
    final response = await apiService.fetchProductsCursor(
      cursor: nextCursor,
      limit: request.pageSize,
    );

    nextCursor = response.nextCursor;
    return response.items;
  }

  @override
  Widget build(BuildContext context) {
    return SmartPagination.listViewWithProvider<Product>(
      request: PaginationRequest(page: 1, pageSize: 20),
      provider: PaginationProvider.future(fetchProducts),
      itemBuilder: (context, items, index) => ProductCard(items[index]),
    );
  }
}
```

---

## 🎨 Example App

The library includes a comprehensive example app with **29 demonstration screens** covering every feature.

### Running the Example

```bash
cd example
flutter pub get
flutter run
```

### 📱 All Example Screens with Screenshots

<div align="center">

> 💡 **Tip**: Click on any example below to see the implementation in the repository

</div>

---

### 🎯 Basic Pagination Examples

#### 1. Basic ListView

Simple paginated product list with automatic loading.

<div align="center">
  <img src="screenshots/basic/01_basic_listview.png" alt="Basic ListView" width="250"/>
</div>

**Features**: Automatic pagination, loading indicators, scroll-to-load

**Code**: [basic_listview_screen.dart](example/lib/screens/smart_pagination/basic_listview_screen.dart)

---

#### 2. GridView Pagination

Product grid with 2 columns and pagination.

<div align="center">
  <img src="screenshots/basic/02_gridview.png" alt="GridView" width="250"/>
</div>

**Features**: GridView layout, configurable columns, responsive grid

**Code**: [gridview_screen.dart](example/lib/screens/smart_pagination/gridview_screen.dart)

---

#### 3. Retry Mechanism

Automatic retry with exponential backoff.

<div align="center">
  <img src="screenshots/basic/03_retry_mechanism.png" alt="Retry Mechanism" width="250"/>
</div>

**Features**: Auto-retry, exponential backoff, configurable attempts

**Code**: [retry_demo_screen.dart](example/lib/screens/smart_pagination/retry_demo_screen.dart)

---

#### 4. Filter & Search

Real-time search and filtering with pagination.

<div align="center">
  <img src="screenshots/basic/04_filter_search.png" alt="Filter & Search" width="250"/>
</div>

**Features**: Server-side filtering, search as you type, filter persistence

**Code**: [filter_search_screen.dart](example/lib/screens/smart_pagination/filter_search_screen.dart)

---

#### 5. Pull to Refresh

Swipe down to refresh functionality.

<div align="center">
  <img src="screenshots/basic/05_pull_to_refresh.png" alt="Pull to Refresh" width="250"/>
</div>

**Features**: Pull-to-refresh, refresh indicators, state reset

**Code**: [pull_to_refresh_screen.dart](example/lib/screens/smart_pagination/pull_to_refresh_screen.dart)

---

### 📡 Stream Examples

#### 6. Single Stream

Real-time updates from a single data stream.

<div align="center">
  <img src="screenshots/streams/06_single_stream.png" alt="Single Stream" width="250"/>
</div>

**Features**: Real-time updates, WebSocket/Firestore integration, auto-sync

**Code**: [single_stream_screen.dart](example/lib/screens/smart_pagination/single_stream_screen.dart)

---

#### 7. Multi Stream

Switch between different data streams dynamically.

<div align="center">
  <img src="screenshots/streams/07_multi_stream.png" alt="Multi Stream" width="250"/>
</div>

**Features**: Stream switching, multiple data sources, smooth transitions

**Code**: [multi_stream_screen.dart](example/lib/screens/smart_pagination/multi_stream_screen.dart)

---

#### 8. Merged Streams

Combine multiple streams into one unified list.

<div align="center">
  <img src="screenshots/streams/08_merged_streams.png" alt="Merged Streams" width="250"/>
</div>

**Features**: Stream merging, unified data, concurrent updates

**Code**: [merged_streams_screen.dart](example/lib/screens/smart_pagination/merged_streams_screen.dart)

---

### ⚙️ Advanced Examples

#### 9. Cursor Pagination

Efficient cursor-based pagination for large datasets.

<div align="center">
  <img src="screenshots/advanced/09_cursor_pagination.png" alt="Cursor Pagination" width="250"/>
</div>

**Features**: Cursor-based pagination, efficient queries, no page skipping

**Code**: [cursor_pagination_screen.dart](example/lib/screens/smart_pagination/cursor_pagination_screen.dart)

---

#### 10. Horizontal Scroll

Horizontal scrolling paginated list.

<div align="center">
  <img src="screenshots/advanced/10_horizontal_scroll.png" alt="Horizontal Scroll" width="250"/>
</div>

**Features**: Horizontal orientation, swipe navigation, carousel-style

**Code**: [horizontal_list_screen.dart](example/lib/screens/smart_pagination/horizontal_list_screen.dart)

---

#### 11. PageView

Swipeable full-screen pages with pagination.

<div align="center">
  <img src="screenshots/advanced/11_page_view.png" alt="PageView" width="250"/>
</div>

**Features**: Full-screen pages, swipe gestures, page indicators

**Code**: [page_view_screen.dart](example/lib/screens/smart_pagination/page_view_screen.dart)

---

#### 12. Staggered Grid

Pinterest-style masonry layout.

<div align="center">
  <img src="screenshots/advanced/12_staggered_grid.png" alt="Staggered Grid" width="250"/>
</div>

**Features**: Masonry layout, variable heights, dynamic positioning

**Code**: [staggered_grid_screen.dart](example/lib/screens/smart_pagination/staggered_grid_screen.dart)

---

#### 13. Custom States

Custom loading, empty, and error states.

<div align="center">
  <img src="screenshots/advanced/13_custom_states.png" alt="Custom States" width="250"/>
</div>

**Features**: Custom UI for all states, branded loading, custom animations

**Code**: [custom_states_screen.dart](example/lib/screens/smart_pagination/custom_states_screen.dart)

---

#### 14. Scroll Control

Programmatic scrolling to specific items or indices.

<div align="center">
  <img src="screenshots/advanced/14_scroll_control.png" alt="Scroll Control" width="250"/>
</div>

**Features**: Scroll to item, scroll to index, smooth animations

**Code**: [scroll_control_screen.dart](example/lib/screens/smart_pagination/scroll_control_screen.dart)

---

#### 15. beforeBuild Hook

Transform state before rendering.

<div align="center">
  <img src="screenshots/advanced/15_before_build_hook.png" alt="beforeBuild Hook" width="250"/>
</div>

**Features**: State transformation, sorting, filtering before render

**Code**: [before_build_hook_screen.dart](example/lib/screens/smart_pagination/before_build_hook_screen.dart)

---

#### 16. hasReachedEnd

Detect when pagination reaches the end.

<div align="center">
  <img src="screenshots/advanced/16_has_reached_end.png" alt="hasReachedEnd" width="250"/>
</div>

**Features**: End detection, custom end message, callbacks

**Code**: [has_reached_end_screen.dart](example/lib/screens/smart_pagination/has_reached_end_screen.dart)

---

#### 17. Custom View Builder

Complete control over the layout.

<div align="center">
  <img src="screenshots/advanced/17_custom_view_builder.png" alt="Custom View Builder" width="250"/>
</div>

**Features**: Fully custom layouts, mixed views, complex UIs

**Code**: [custom_view_builder_screen.dart](example/lib/screens/smart_pagination/custom_view_builder_screen.dart)

---

#### 18. Reorderable List

Drag and drop to reorder items.

<div align="center">
  <img src="screenshots/advanced/18_reorderable_list.png" alt="Reorderable List" width="250"/>
</div>

**Features**: Drag-and-drop, reorder callbacks, visual feedback

**Code**: [reorderable_list_screen.dart](example/lib/screens/smart_pagination/reorderable_list_screen.dart)

---

#### 19. State Separation

Different UI for first page vs load more states.

<div align="center">
  <img src="screenshots/advanced/19_state_separation.png" alt="State Separation" width="250"/>
</div>

**Features**: Separate first page/load more UI, different error handling

**Code**: [state_separation_screen.dart](example/lib/screens/smart_pagination/state_separation_screen.dart)

---

#### 20. Smart Preloading

Configurable preload threshold.

<div align="center">
  <img src="screenshots/advanced/20_smart_preloading.png" alt="Smart Preloading" width="250"/>
</div>

**Features**: Preload before end, configurable threshold, smooth experience

**Code**: [smart_preloading_screen.dart](example/lib/screens/smart_pagination/smart_preloading_screen.dart)

---

#### 21. Custom Error Handling

All error widget styles demonstration.

<div align="center">
  <img src="screenshots/advanced/21_custom_error_handling.png" alt="Custom Error Handling" width="250"/>
</div>

**Features**: All 6 error styles, custom error types, retry mechanisms

**Code**: [custom_error_handling_screen.dart](example/lib/screens/smart_pagination/custom_error_handling_screen.dart)

---

#### 22. Data Operations

Programmatic data manipulation (add, remove, update, clear).

<div align="center">
  <img src="screenshots/advanced/22_data_operations.png" alt="Data Operations" width="250"/>
</div>

**Features**: Insert items, remove items, update items, clear all, reload, set items

**Code**: [data_operations_screen.dart](example/lib/screens/smart_pagination/data_operations_screen.dart)

---

### 🛡️ Error Handling Examples

#### 23. Basic Error Handling

Simple error display with retry button.

<div align="center">
  <img src="screenshots/errors/23_basic_error.png" alt="Basic Error" width="250"/>
</div>

**Features**: Simple retry, error counter, success after N attempts

**Code**: [basic_error_example.dart](example/lib/screens/errors/basic_error_example.dart)

---

#### 24. Network Errors

Different network error types (timeout, 404, 500, etc.).

<div align="center">
  <img src="screenshots/errors/24_network_errors.png" alt="Network Errors" width="250"/>
</div>

**Features**: Custom exceptions, context-aware errors, appropriate icons

**Code**: [network_errors_example.dart](example/lib/screens/errors/network_errors_example.dart)

---

#### 25. Retry Patterns

Manual, auto, exponential backoff, limited retries.

<div align="center">
  <img src="screenshots/errors/25_retry_patterns.png" alt="Retry Patterns" width="250"/>
</div>

**Features**: 4 retry strategies, countdown timers, retry limits

**Code**: [retry_patterns_example.dart](example/lib/screens/errors/retry_patterns_example.dart)

---

#### 26. Custom Error Widgets

All 6 pre-built error widget styles.

<div align="center">
  <img src="screenshots/errors/26_custom_error_widgets.png" alt="Custom Error Widgets" width="250"/>
</div>

**Features**: Material, Compact, Card, Minimal, Snackbar, Custom styles

**Code**: [custom_error_widgets_example.dart](example/lib/screens/errors/custom_error_widgets_example.dart)

---

#### 27. Error Recovery

Cached data, partial data, fallback strategies.

<div align="center">
  <img src="screenshots/errors/27_error_recovery.png" alt="Error Recovery" width="250"/>
</div>

**Features**: 4 recovery strategies, offline mode, data persistence

**Code**: [error_recovery_example.dart](example/lib/screens/errors/error_recovery_example.dart)

---

#### 28. Graceful Degradation

Offline mode, placeholders, limited features.

<div align="center">
  <img src="screenshots/errors/28_graceful_degradation.png" alt="Graceful Degradation" width="250"/>
</div>

**Features**: 3 degradation strategies, offline UI, skeleton screens

**Code**: [graceful_degradation_example.dart](example/lib/screens/errors/graceful_degradation_example.dart)

---

#### 29. Load More Errors

Handle errors while loading additional pages.

<div align="center">
  <img src="screenshots/errors/29_load_more_errors.png" alt="Load More Errors" width="250"/>
</div>

**Features**: 3 load-more patterns, inline errors, dismissible banners

**Code**: [load_more_errors_example.dart](example/lib/screens/errors/load_more_errors_example.dart)

---

### 📸 Adding Screenshots

To capture screenshots for the examples:

1. Run the example app
2. Navigate to each screen
3. Take screenshots (recommended: 1080x2400px)
4. Save to `screenshots/` directory following naming convention

See [screenshots/README.md](screenshots/README.md) for detailed instructions.

---

## 📚 API Reference

### SmartPagination.withProvider<T>

Low-level widget for complete control.

```dart
SmartPagination.withProvider<T>({
  // Data source
  required PaginationRequest request,
  required PaginationProvider<T> provider,
  required Widget Function(BuildContext, List<T>, int) itemBuilder,

  // View type
  PaginateBuilderType itemBuilderType = PaginateBuilderType.listView,

  // Custom view builder
  Widget Function(
    BuildContext context,
    List<T> items,
    bool hasReachedEnd,
    VoidCallback fetchMore,
  )? customViewBuilder,

  // All other parameters same as SmartPagination.listView
})
```

### SmartPagination.withCubit<T>

Use with your own cubit instance for full control.

```dart
SmartPagination.withCubit<T>({
  required SmartPaginationCubit<T> cubit,
  required Widget Function(BuildContext, List<T>, int) itemBuilder,
  required PaginateBuilderType itemBuilderType,
  // ... other parameters
})
```

### SmartPagination.columnWithProvider<T>

Creates a pagination widget as a Column layout (non-scrollable).

```dart
SmartPagination.columnWithProvider<T>({
  required PaginationRequest request,
  required PaginationProvider<T> provider,
  required Widget Function(BuildContext, List<T>, int) itemBuilder,
  // ... other parameters
})
```

### SmartPagination.columnWithCubit<T>

Creates a pagination widget as a Column layout (non-scrollable) with an external Cubit.

```dart
SmartPagination.columnWithCubit<T>({
  required SmartPaginationCubit<T> cubit,
  required Widget Function(BuildContext, List<T>, int) itemBuilder,
  // ... other parameters
})
```

### SmartPagination.gridViewWithProvider<T>

Grid layout with pagination.

```dart
SmartPagination.gridViewWithProvider<T>({
  required PaginationRequest request,
  required PaginationProvider<T> provider,
  required Widget Function(BuildContext, List<T>, int) itemBuilder,
  required SliverGridDelegate gridDelegate,
  // ... other parameters
})
```

### SmartPagination.gridViewWithCubit<T>

Grid layout with pagination with an external Cubit.

```dart
SmartPagination.gridViewWithCubit<T>({
  required SmartPaginationCubit<T> cubit,
  required Widget Function(BuildContext, List<T>, int) itemBuilder,
  required SliverGridDelegate gridDelegate,
  // ... other parameters
})
```

### SmartPagination.listViewWithProvider<T>

The easiest way to create a paginated list.

```dart
SmartPagination.listViewWithProvider<T>({
  required PaginationRequest request,
  required PaginationProvider<T> provider,
  required Widget Function(BuildContext, List<T>, int) itemBuilder,
  // ... other parameters
})
```

### SmartPagination.listViewWithCubit<T>

ListView layout with pagination with an external Cubit.

```dart
SmartPagination.listViewWithCubit<T>({
  required SmartPaginationCubit<T> cubit,
  required Widget Function(BuildContext, List<T>, int) itemBuilder,
  // ... other parameters
})
```

### SmartPagination.reorderableListViewWithProvider<T>

Reorderable list layout with pagination.

```dart
SmartPagination.reorderableListViewWithProvider<T>({
  required PaginationRequest request,
  required PaginationProvider<T> provider,
  required Widget Function(BuildContext, List<T>, int) itemBuilder,
  required void Function(int oldIndex, int newIndex) onReorder,
  // ... other parameters
})
```

### SmartPagination.reorderableListViewWithCubit<T>

Reorderable list layout with pagination with an external Cubit.

```dart
SmartPagination.reorderableListViewWithCubit<T>({
  required SmartPaginationCubit<T> cubit,
  required Widget Function(BuildContext, List<T>, int) itemBuilder,
  required void Function(int oldIndex, int newIndex) onReorder,
  // ... other parameters
})
```

### SmartPagination.pageViewWithProvider<T>

PageView layout with pagination.

```dart
SmartPagination.pageViewWithProvider<T>({
  required PaginationRequest request,
  required PaginationProvider<T> provider,
  required Widget Function(BuildContext, List<T>, int) itemBuilder,
  // ... other parameters
})
```

### SmartPagination.pageViewWithCubit<T>

PageView layout with pagination with an external Cubit.

```dart
SmartPagination.pageViewWithCubit<T>({
  required SmartPaginationCubit<T> cubit,
  required Widget Function(BuildContext, List<T>, int) itemBuilder,
  // ... other parameters
})
```

### SmartPagination.staggeredGridViewWithProvider<T>

StaggeredGridView layout with pagination.

```dart
SmartPagination.staggeredGridViewWithProvider<T>({
  required PaginationRequest request,
  required PaginationProvider<T> provider,
  required StaggeredGridTile Function(BuildContext, List<T>, int) itemBuilder,
  required int crossAxisCount,
  // ... other parameters
})
```

### SmartPagination.staggeredGridViewWithCubit<T>

StaggeredGridView layout with pagination with an external Cubit.

```dart
SmartPagination.staggeredGridViewWithCubit<T>({
  required SmartPaginationCubit<T> cubit,
  required StaggeredGridTile Function(BuildContext, List<T>, int) itemBuilder,
  required int crossAxisCount,
  // ... other parameters
})
```

### SmartPagination.rowWithProvider<T>

Row layout (horizontal non-scrollable) with pagination.

```dart
SmartPagination.rowWithProvider<T>({
  required PaginationRequest request,
  required PaginationProvider<T> provider,
  required Widget Function(BuildContext, List<T>, int) itemBuilder,
  // ... other parameters
})
```

### SmartPagination.rowWithCubit<T>

Row layout (horizontal non-scrollable) with pagination with an external Cubit.

```dart
SmartPagination.rowWithCubit<T>({
  required SmartPaginationCubit<T> cubit,
  required Widget Function(BuildContext, List<T>, int) itemBuilder,
  // ... other parameters
})
```

### Configuration Fields

| Field | Type | Description | Default |
|-------|------|-------------|---------|
| `request` | `PaginationRequest` | Configuration for pagination (page size, initial page). Required for `withProvider`. | - |
| `provider` | `PaginationProvider<T>` | Data source definition (Future or Stream). Required for `withProvider`. | - |
| `cubit` | `SmartPaginationCubit<T>` | External BLoC instance. Required for `withCubit`. | - |
| `itemBuilder` | `ItemBuilder<T>` | Builder function for each item in the list. | - |
| `itemBuilderType` | `PaginateBuilderType` | The type of layout to render (listView, gridView, etc.). | `listView` |
| `gridDelegate` | `SliverGridDelegate` | Grid configuration. Required for `gridView` type. | `SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2)` |
| `scrollDirection` | `Axis` | The axis along which the scroll view scrolls. | `Axis.vertical` |
| `shrinkWrap` | `bool` | Whether the extent of the scroll view should be determined by the contents. | `false` |
| `reverse` | `bool` | Whether the scroll view scrolls in the reading direction. | `false` |
| `physics` | `ScrollPhysics?` | How the scroll view should respond to user input. | `null` |
| `padding` | `EdgeInsetsGeometry` | The amount of space by which to inset the children. | `EdgeInsets.all(0)` |
| `scrollController` | `ScrollController?` | An object that can be used to control the position to which this scroll view is scrolled. | `null` |
| `pageController` | `PageController?` | Controller for `pageView` type. | `null` |
| `onPageChanged` | `ValueChanged<int>?` | Callback when page changes in `pageView`. | `null` |
| `header` | `Widget?` | Widget to display at the top of the list. | `null` |
| `footer` | `Widget?` | Widget to display at the bottom of the list. | `null` |
| `separator` | `Widget?` | Widget to display between items (ListView/Column/Row). | `EmptySeparator` / `SizedBox` |
| `emptyWidget` | `Widget` | Widget to display when the list is empty. | `EmptyDisplay()` |
| `loadingWidget` | `Widget` | Widget to display while loading the first page. | `InitialLoader()` |
| `bottomLoader` | `Widget` | Widget to display at the bottom while loading more items. | `BottomLoader()` |
| `heightOfInitialLoadingAndEmptyWidget` | `double?` | Height constraint for initial loading/empty states. | `MediaQuery.size.height` |
| `customViewBuilder` | `CustomViewBuilder?` | Builder for `PaginateBuilderType.custom`. | `null` |
| `onReorder` | `ReorderCallback?` | Callback for `reorderableListView`. | `null` |
| `firstPageLoadingBuilder` | `WidgetBuilder?` | Custom builder for first page loading state. | `null` |
| `firstPageErrorBuilder` | `ErrorBuilder?` | Custom builder for first page error state. | `null` |
| `firstPageEmptyBuilder` | `WidgetBuilder?` | Custom builder for first page empty state. | `null` |
| `loadMoreLoadingBuilder` | `WidgetBuilder?` | Custom builder for load more loading indicator. | `null` |
| `loadMoreErrorBuilder` | `ErrorBuilder?` | Custom builder for load more error state. | `null` |
| `loadMoreNoMoreItemsBuilder` | `WidgetBuilder?` | Custom builder for "no more items" state. | `null` |
| `invisibleItemsThreshold` | `int` | Number of invisible items that triggers loading more. | `3` |
| `retryConfig` | `RetryConfig?` | Configuration for automatic retries. | `null` |
| `refreshListener` | `SmartPaginationRefreshedChangeListener?` | Listener for pull-to-refresh events. | `null` |
| `filterListeners` | `List<SmartPaginationFilterChangeListener>?` | Listeners for search/filter events. | `null` |
| `onReachedEnd` | `VoidCallback?` | Callback when the end of the list is reached. | `null` |
| `onLoaded` | `Function(SmartPaginationLoaded)?` | Callback when data is successfully loaded. | `null` |
| `beforeBuild` | `StateTransformer?` | Hook to transform state before building. | `null` |
| `listBuilder` | `ListBuilder?` | Hook to transform list items in Cubit. | `null` |
| `cacheExtent` | `double?` | The viewport distance that items are cached. | `null` |
| `allowImplicitScrolling` | `bool` | Whether to allow implicit scrolling. | `false` |
| `keyboardDismissBehavior` | `ScrollViewKeyboardDismissBehavior` | How the keyboard should be dismissed. | `manual` |
| `maxPagesInMemory` | `int` | Maximum number of pages to keep in memory. | `5` |

### PaginationProvider<T>

Defines how data is fetched.

```dart
// Future-based (REST APIs)
PaginationProvider.future(
  Future<List<T>> Function(PaginationRequest request) provider,
)

// Stream-based (Real-time)
PaginationProvider.stream(
  Stream<List<T>> Function(PaginationRequest request) provider,
)

// Merged streams
PaginationProvider.mergeStreams(
  List<Stream<List<T>>> Function(PaginationRequest request) providers,
)
```

### PaginationRequest

Request configuration.

```dart
const PaginationRequest({
  required int page,              // Current page number (1-indexed)
  required int pageSize,          // Number of items per page
  Map<String, dynamic>? filters,  // Optional filters for server-side filtering
})
```

### RetryConfig

Configure automatic retry behavior.

```dart
RetryConfig({
  int maxAttempts = 3,                        // Max retry attempts
  Duration initialDelay = Duration(seconds: 1), // Initial retry delay
  Duration maxDelay = Duration(seconds: 10),    // Maximum retry delay
  Duration? timeoutDuration,                    // Request timeout
  List<Duration>? retryDelays,                  // Custom delays per attempt
  bool Function(Exception)? shouldRetry,        // Custom retry condition
})
```

### CustomErrorBuilder

Pre-built error widget styles.

```dart
// Material Design
CustomErrorBuilder.material({
  required BuildContext context,
  required Exception error,
  required VoidCallback onRetry,
  String? title,
  String? message,
  IconData? icon,
  Color? iconColor,
  String? retryButtonText,
})

// Compact inline
CustomErrorBuilder.compact({
  required BuildContext context,
  required Exception error,
  required VoidCallback onRetry,
  String? message,
  Color? backgroundColor,
  Color? textColor,
})

// Card style
CustomErrorBuilder.card({
  required BuildContext context,
  required Exception error,
  required VoidCallback onRetry,
  String? title,
  String? message,
  double? elevation,
})

// Minimal
CustomErrorBuilder.minimal({
  required BuildContext context,
  required Exception error,
  required VoidCallback onRetry,
  String? message,
})

// Snackbar
CustomErrorBuilder.snackbar({
  required BuildContext context,
  required Exception error,
  required VoidCallback onRetry,
  String? message,
  Color? backgroundColor,
})

// Custom
CustomErrorBuilder.custom({
  required BuildContext context,
  required Exception error,
  required VoidCallback onRetry,
  required Widget Function(BuildContext, Exception, VoidCallback) builder,
})
```

### ErrorImages

Helper for error illustrations with automatic icon fallback.

```dart
ErrorImages.general({double width, double height, Color? fallbackColor})
ErrorImages.network({double width, double height, Color? fallbackColor})
ErrorImages.notFound({double width, double height, Color? fallbackColor})
ErrorImages.server({double width, double height, Color? fallbackColor})
ErrorImages.timeout({double width, double height, Color? fallbackColor})
ErrorImages.auth({double width, double height, Color? fallbackColor})
ErrorImages.offline({double width, double height, Color? fallbackColor})
ErrorImages.empty({double width, double height, Color? fallbackColor})
ErrorImages.retry({double width, double height, Color? fallbackColor})
ErrorImages.recovery({double width, double height, Color? fallbackColor})
ErrorImages.loading({double width, double height, Color? fallbackColor})
ErrorImages.custom({double width, double height, Color? fallbackColor})
```

### SmartPaginationCubit<T>

Low-level BLoC for advanced use cases.

```dart
class SmartPaginationCubit<T> extends Cubit<SmartPaginationState<T>> {
  SmartPaginationCubit({
    required PaginationRequest request,
    required PaginationProvider<T> provider,
    RetryConfig? retryConfig,
    int? maxPagesInMemory,
    List<T> Function(List<T>)? listBuilder,
    void Function(List<T>)? onInsertionCallback,
    VoidCallback? onClear,
    VoidCallback? onReachedEnd,
    Logger? logger,
    Duration? dataAge,                // NEW: Auto-expire data after this duration
  });

  // Properties
  List<T> get currentItems;           // Get current items (read-only)
  bool get didFetch;                  // Whether data has been fetched
  Duration? get dataAge;              // Get configured data age duration
  DateTime? get lastFetchTime;        // Get timestamp of last successful fetch
  bool get isDataExpired;             // Check if data has expired

  // Pagination Methods
  void fetchPaginatedList();          // Fetch next page (auto-checks expiration)
  void refreshPaginatedList();        // Refresh from beginning
  void reload();                      // Alias for refreshPaginatedList
  bool checkAndResetIfExpired();      // Check and reset if data expired

  // Insert Operations
  void insertEmit(T item, {int index = 0});           // Insert single item
  void insertAllEmit(List<T> items, {int index = 0}); // Insert multiple items
  void addOrUpdateEmit(T item, {int index = 0});      // Add or update item

  // Remove Operations
  bool removeItemEmit(T item);                        // Remove by item
  T? removeAtEmit(int index);                         // Remove by index
  int removeWhereEmit(bool Function(T) test);         // Remove by condition

  // Update Operations
  bool updateItemEmit(
    bool Function(T) matcher,
    T Function(T) updater,
  );                                                   // Update single item
  int updateWhereEmit(
    bool Function(T) matcher,
    T Function(T) updater,
  );                                                   // Update multiple items

  // Other Operations
  void clearItems();                                   // Clear all items
  void setItems(List<T> items);                        // Set custom items
  void filterPaginatedList(bool Function(T)? filter); // Filter items
}
```

### SmartPaginationState<T>

BLoC states.

```dart
// Initial state
class SmartPaginationInitial<T> extends SmartPaginationState<T>

// Loading first page
class SmartPaginationLoading<T> extends SmartPaginationState<T>

// Data loaded
class SmartPaginationLoaded<T> extends SmartPaginationState<T> {
  final List<T> items;
  final bool hasReachedEnd;
  final bool isLoadingMore;
  final Exception? loadMoreError;
  final DateTime? fetchedAt;        // When data was fetched
  final DateTime? dataExpiredAt;    // When data will expire
}

// First page error
class SmartPaginationError<T> extends SmartPaginationState<T> {
  final Exception exception;
}

// Empty state
class SmartPaginationEmpty<T> extends SmartPaginationState<T>
```

---

## 🎯 Best Practices

### 1. Reuse Cubits for Performance

Create the cubit once and reuse it:

```dart
// ❌ Bad - Creates new cubit on every build
Widget build(BuildContext context) {
  return SmartPagination.listViewWithProvider<Product>(
    request: PaginationRequest(page: 1, pageSize: 20),
    provider: PaginationProvider.future(fetchProducts),
    itemBuilder: (context, items, index) => ProductCard(items[index]),
  );
}

// ✅ Good - Reuse cubit instance
class ProductsPage extends StatefulWidget {
  @override
  _ProductsPageState createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  late SmartPaginationCubit<Product> cubit;

  @override
  void initState() {
    super.initState();
    cubit = SmartPaginationCubit<Product>(
      request: PaginationRequest(page: 1, pageSize: 20),
      provider: PaginationProvider.future(fetchProducts),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SmartPagination.withCubit(
      cubit: cubit,
      itemBuilder: (context, items, index) => ProductCard(items[index]),
    );
  }

  @override
  void dispose() {
    cubit.close();
    super.dispose();
  }
}
```

### 2. Optimize Memory Usage

Set `maxPagesInMemory` based on your item size:

```dart
SmartPaginationCubit<Product>(
  request: PaginationRequest(page: 1, pageSize: 20),
  provider: PaginationProvider.future(fetchProducts),
  maxPagesInMemory: 5, // Keeps ~100 items in memory
)
```

### 3. Always Provide Error Builders

Better user experience with custom error handling:

```dart
SmartPagination.listView<Product>(
  // ... other properties

  firstPageErrorBuilder: (context, error, retry) {
    return CustomErrorBuilder.material(
      context: context,
      error: error,
      onRetry: retry,
      title: 'Oops!',
      message: 'Something went wrong. Please try again.',
    );
  },

  loadMoreErrorBuilder: (context, error, retry) {
    return CustomErrorBuilder.compact(
      context: context,
      error: error,
      onRetry: retry,
    );
  },
)
```

### 4. Use State Separation

Different UI for first page vs load more:

```dart
// Different loading indicators
firstPageLoadingBuilder: (context) => FullScreenLoader(),
loadMoreLoadingBuilder: (context) => BottomLoader(),

// Different error widgets
firstPageErrorBuilder: (context, error, retry) => FullScreenError(),
loadMoreErrorBuilder: (context, error, retry) => InlineError(),
```

### 5. Smart Preloading Configuration

Adjust based on your use case:

```dart
// Fast scrolling content (e.g., chat)
invisibleItemsThreshold: 5,

// Slow scrolling content (e.g., product catalog)
invisibleItemsThreshold: 2,

// On-demand loading only
invisibleItemsThreshold: 0,
```

### 6. Use listBuilder for Transformations

Prefer `listBuilder` over `beforeBuild` for performance:

```dart
// ✅ Good - Transforms in cubit before emission
SmartPaginationCubit<Product>(
  request: PaginationRequest(page: 1, pageSize: 20),
  provider: PaginationProvider.future(fetchProducts),
  listBuilder: (items) => items.toSet().toList(), // Remove duplicates
)

// ⚠️ Less efficient - Transforms on every build
SmartPagination.listView<Product>(
  request: PaginationRequest(page: 1, pageSize: 20),
  provider: PaginationProvider.future(fetchProducts),
  beforeBuild: (state) {
    // Runs on every build
  },
  itemBuilder: (context, items, index) => ProductCard(items[index]),
)
```

### 7. Error Images with Fallback

Always use fallback to ensure content displays:

```dart
ErrorImages.network(
  width: 200,
  height: 200,
  fallbackColor: Colors.orange, // Shows icon if image fails
)
```

### 8. Testing with Mock Data

Create mock providers for predictable tests:

```dart
// Mock provider for testing
final mockProvider = PaginationProvider.future(
  (request) async {
    await Future.delayed(Duration(milliseconds: 500));
    return List.generate(
      request.pageSize,
      (i) => Product(
        id: '${request.page}-$i',
        name: 'Product ${request.page}-$i',
      ),
    );
  },
);

// Use in tests
testWidgets('displays products', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: SmartPagination.listView<Product>(
        request: PaginationRequest(page: 1, pageSize: 20),
        provider: mockProvider,
        itemBuilder: (context, items, index) {
          return Text(items[index].name);
        },
      ),
    ),
  );

  await tester.pumpAndSettle();
  expect(find.text('Product 1-0'), findsOneWidget);
});
```

---

## 📖 Documentation

- **Error Handling Guide**: [docs/ERROR_HANDLING.md](docs/ERROR_HANDLING.md)
- **Error Images Setup**: [docs/ERROR_IMAGES_SETUP.md](docs/ERROR_IMAGES_SETUP.md)
- **Changelog**: [CHANGELOG.md](CHANGELOG.md)
- **License**: [LICENSE](LICENSE)

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

```
MIT License

Copyright (c) 2024 Genius Systems

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

## 🙏 Acknowledgments

- **flutter_bloc** - State management ([pub.dev/packages/flutter_bloc](https://pub.dev/packages/flutter_bloc))
- **scrollview_observer** - Scroll control ([pub.dev/packages/scrollview_observer](https://pub.dev/packages/scrollview_observer))
- **flutter_staggered_grid_view** - Staggered layouts ([pub.dev/packages/flutter_staggered_grid_view](https://pub.dev/packages/flutter_staggered_grid_view))
- Inspired by Flutter pagination best practices

---

## 🌟 Features Comparison

| Feature | Smart Pagination | infinite_scroll_pagination | flutter_pagewise | pagination_view |
|---------|------------------|---------------------------|------------------|-----------------|
| BLoC Pattern | ✅ Built-in | ❌ Manual | ❌ Manual | ❌ Manual |
| Multiple View Types | ✅ 6+ types | ⚠️ Limited | ⚠️ Limited | ⚠️ Limited |
| Error State Separation | ✅ Yes | ❌ No | ❌ No | ❌ No |
| Pre-built Error Widgets | ✅ 6 styles | ❌ No | ❌ No | ❌ No |
| Stream Support | ✅ Full | ⚠️ Limited | ❌ No | ❌ No |
| Smart Preloading | ✅ Configurable | ⚠️ Fixed | ⚠️ Fixed | ❌ No |
| Memory Management | ✅ Yes | ❌ No | ❌ No | ❌ No |
| Retry Mechanism | ✅ Advanced | ⚠️ Basic | ⚠️ Basic | ❌ No |
| Data Operations | ✅ Full CRUD | ❌ No | ❌ No | ❌ No |
| Type Safety | ✅ Full generics | ✅ Yes | ✅ Yes | ⚠️ Limited |
| Testing | ✅ 60+ tests | ⚠️ Partial | ⚠️ Partial | ❌ No |
| Documentation | ✅ Comprehensive | ⚠️ Basic | ⚠️ Basic | ⚠️ Basic |
| Example App | ✅ 29+ screens | ⚠️ Few | ⚠️ Few | ⚠️ Few |

---

## 💡 Use Cases

### E-Commerce Apps

- Product catalogs with grid/list views
- Search and filter products
- Categorized product listings
- Order history pagination

### Social Media

- News feeds with real-time updates
- User profiles and followers lists
- Comments and replies threading
- Media galleries (photos, videos)

### Content Apps

- Article listings
- Video streaming libraries
- Podcast episodes
- News aggregators

### Business Apps

- Transaction histories
- Customer lists
- Invoice management
- Report listings

### Chat Apps

- Message history pagination
- Contact lists
- Channel/group listings
- File/media sharing logs

---

## Example Code

- [Basic Examples](example/lib/screens/basic/)
- [Stream Examples](example/lib/screens/streams/)
- [Error Examples](example/lib/screens/errors/)
- [Advanced Examples](example/lib/screens/advanced/)

---

<div align="center">

**Transport agnostic**: Bring your own async function and enjoy consistent pagination UI.

Made with ❤️ by [Genius Systems](https://github.com/GeniusSystems24)

[⬆ Back to Top](#smart-pagination)

</div>
