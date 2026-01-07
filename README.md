# Smart Pagination

[![pub package](https://img.shields.io/pub/v/smart_pagination.svg)](https://pub.dev/packages/smart_pagination)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-3.9+-02569B?logo=flutter)](https://flutter.dev)
[![Platform](https://img.shields.io/badge/Platform-All-blueviolet)](https://flutter.dev)
[![Live Demo](https://img.shields.io/badge/Live_Demo-View-success)](https://geniussystems24.github.io/smart_pagination)

**Production-ready Flutter pagination with built-in BLoC, search dropdowns, and error handling.**

```dart
SmartPaginationListView.withProvider(
  request: PaginationRequest(page: 1, pageSize: 20),
  provider: PaginationProvider.future((req) => api.getProducts(req)),
  itemBuilder: (context, items, index) => ProductTile(items[index]),
)
```

## Features

- **7 Widget Classes** - ListView, GridView, PageView, StaggeredGrid, Column, Row, ReorderableList
- **Smart Search** - Auto-positioning dropdown with key-based selection
- **Built-in BLoC** - State management included, or bring your own cubit
- **Error Handling** - 6 pre-built styles with first-page/load-more separation
- **Stream Support** - Future, Stream, and merged streams
- **Data Operations** - Insert, remove, update items programmatically
- **Auto Expiration** - Configurable data age for global cubits

## Installation

```yaml
dependencies:
  smart_pagination: ^3.0.0+1
```

```dart
import 'package:smart_pagination/pagination.dart';
```

## Quick Start

### ListView

```dart
SmartPaginationListView.withProvider(
  request: PaginationRequest(page: 1, pageSize: 20),
  provider: PaginationProvider.future((req) => fetchProducts(req)),
  itemBuilder: (context, items, index) => ListTile(
    title: Text(items[index].name),
  ),
)
```

### GridView

```dart
SmartPaginationGridView.withProvider(
  request: PaginationRequest(page: 1, pageSize: 20),
  provider: PaginationProvider.future((req) => fetchProducts(req)),
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
  itemBuilder: (context, items, index) => ProductCard(items[index]),
)
```

### With External Cubit

```dart
final cubit = SmartPaginationCubit<Product>(
  request: PaginationRequest(page: 1, pageSize: 20),
  provider: PaginationProvider.future(fetchProducts),
  dataAge: Duration(minutes: 5), // Auto-refresh stale data
);

SmartPaginationListView.withCubit(
  cubit: cubit,
  itemBuilder: (context, items, index) => ProductTile(items[index]),
)
```

---

## Widget Classes

| Widget | Layout | Use Case |
|--------|--------|----------|
| `SmartPaginationListView` | Vertical/horizontal list | Feeds, messages |
| `SmartPaginationGridView` | Multi-column grid | Catalogs, galleries |
| `SmartPaginationColumn` | Non-scrollable column | Embedded in ScrollView |
| `SmartPaginationRow` | Non-scrollable row | Chips, tags |
| `SmartPaginationPageView` | Swipeable pages | Onboarding, carousels |
| `SmartPaginationStaggeredGridView` | Masonry layout | Pinterest-style |
| `SmartPaginationReorderableListView` | Drag-and-drop | Task lists |

Each widget has two constructors:
- `.withProvider(...)` - Creates cubit internally
- `.withCubit(...)` - Uses external cubit

---

## Smart Search

Search components with auto-positioning overlay and key-based selection.

### Basic Dropdown

```dart
SmartSearchDropdown<Product, int>.withProvider(
  request: PaginationRequest(page: 1, pageSize: 20),
  provider: PaginationProvider.future((req) => api.search(req.searchQuery)),
  searchRequestBuilder: (query) => PaginationRequest(page: 1, pageSize: 20, searchQuery: query),
  itemBuilder: (context, product) => ListTile(title: Text(product.name)),
  keyExtractor: (product) => product.id,
  onSelected: (product, id) => print('Selected: ${product.name} (ID: $id)'),
)
```

### Key-Based Selection

Select by ID instead of object reference - essential for edit forms and state management.

```dart
SmartSearchDropdown<Product, int>.withProvider(
  // ... provider config
  itemBuilder: (context, product) => ListTile(title: Text(product.name)),

  // Key-based selection
  keyExtractor: (product) => product.id,
  selectedKey: selectedProductId,
  onSelected: (product, id) => setState(() => selectedProductId = id),
  selectedKeyLabelBuilder: (id) => 'Product #$id (loading...)',
  showSelected: true,
)
```

### Multi-Selection

```dart
SmartSearchMultiDropdown<Product, int>.withProvider(
  // ... provider config
  keyExtractor: (product) => product.id,
  selectedKeys: selectedIds,
  onSelected: (products, ids) => setState(() => selectedIds = ids),
  maxSelections: 5,
)
```

### Components

| Component | Description |
|-----------|-------------|
| `SmartSearchDropdown<T, K>` | Single-selection search dropdown |
| `SmartSearchMultiDropdown<T, K>` | Multi-selection with chips |
| `SmartSearchController<T, K>` | Controller for programmatic control |
| `SmartSearchBox<T, K>` | Standalone search input |
| `SmartSearchOverlay<T, K>` | Standalone results overlay |
| `SmartSearchTheme` | ThemeExtension for styling |

### Configuration

```dart
SmartSearchDropdown<Product, int>.withProvider(
  // ...
  searchConfig: SmartSearchConfig(
    debounceDelay: Duration(milliseconds: 500),
    minSearchLength: 2,
    searchOnEmpty: false,
  ),
  overlayConfig: SmartSearchOverlayConfig(
    position: OverlayPosition.auto,
    maxHeight: 400,
    animationType: OverlayAnimationType.fadeScale,
  ),
)
```

### SmartSearchDropdown Parameters

#### Core Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `request` | `PaginationRequest` | Yes* | - | Pagination config (for `.withProvider`) |
| `provider` | `PaginationProvider<T>` | Yes* | - | Data source (for `.withProvider`) |
| `cubit` | `SmartPaginationCubit<T>` | Yes* | - | External cubit (for `.withCubit`) |
| `searchRequestBuilder` | `PaginationRequest Function(String)` | Yes | - | Builds request from search query |
| `itemBuilder` | `Widget Function(BuildContext, T)` | Yes | - | Builds each result item |

#### Selection Callback

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `onSelected` | `void Function(T, K)?` | No | `null` | Called with item and key when selected |
| `onChanged` | `ValueChanged<String>?` | No | `null` | Called when text changes |

#### Key-Based Selection

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `keyExtractor` | `K Function(T)?` | No | `null` | Extracts unique key from item |
| `selectedKey` | `K?` | No | `null` | Currently selected key |
| `selectedKeyLabelBuilder` | `String Function(K)?` | No | `null` | Label for pending key |
| `selectedKeyBuilder` | `Widget Function(BuildContext, K, VoidCallback)?` | No | `null` | Custom pending key widget |

#### Show Selected Mode

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `showSelected` | `bool` | No | `false` | Show selected item instead of search box |
| `initialSelectedValue` | `T?` | No | `null` | Pre-selected item on load |
| `selectedItemBuilder` | `Widget Function(BuildContext, T, VoidCallback)?` | No | `null` | Custom selected item widget |

#### Search Box Appearance

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `decoration` | `InputDecoration?` | No | `null` | TextField decoration |
| `style` | `TextStyle?` | No | `null` | Text style |
| `prefixIcon` | `Widget?` | No | `null` | Leading icon |
| `suffixIcon` | `Widget?` | No | `null` | Trailing icon |
| `showClearButton` | `bool` | No | `true` | Show clear button |
| `borderRadius` | `BorderRadius?` | No | `null` | Border radius |

#### Input Configuration

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `textInputAction` | `TextInputAction` | No | `search` | Keyboard action button |
| `textCapitalization` | `TextCapitalization` | No | `none` | Text capitalization |
| `keyboardType` | `TextInputType` | No | `text` | Keyboard type |
| `inputFormatters` | `List<TextInputFormatter>?` | No | `null` | Input formatters |
| `maxLength` | `int?` | No | `null` | Max input length |

#### Validation

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `validator` | `String? Function(String?)?` | No | `null` | Validation function |
| `autovalidateMode` | `AutovalidateMode?` | No | `null` | When to validate |

#### Overlay State Builders

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `loadingBuilder` | `WidgetBuilder?` | No | `null` | Loading state widget |
| `emptyBuilder` | `WidgetBuilder?` | No | `null` | Empty results widget |
| `errorBuilder` | `Widget Function(BuildContext, Exception)?` | No | `null` | Error state widget |
| `headerBuilder` | `WidgetBuilder?` | No | `null` | Dropdown header |
| `footerBuilder` | `WidgetBuilder?` | No | `null` | Dropdown footer |
| `separatorBuilder` | `IndexedWidgetBuilder?` | No | `null` | Item separator |
| `overlayDecoration` | `BoxDecoration?` | No | `null` | Overlay container decoration |

#### Configuration Objects

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `searchConfig` | `SmartSearchConfig` | No | `SmartSearchConfig()` | Search behavior config |
| `overlayConfig` | `SmartSearchOverlayConfig` | No | `SmartSearchOverlayConfig()` | Overlay appearance config |

#### Cubit Options (`.withProvider` only)

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `listBuilder` | `List<T> Function(List<T>)?` | No | `null` | Transform items |
| `onInsertionCallback` | `void Function(List<T>)?` | No | `null` | Called on data load |
| `maxPagesInMemory` | `int` | No | `5` | Max cached pages |
| `retryConfig` | `RetryConfig?` | No | `null` | Retry configuration |
| `dataAge` | `Duration?` | No | `null` | Data expiration |
| `orders` | `SortOrderCollection<T>?` | No | `null` | Sort orders |
| `logger` | `Logger?` | No | `null` | Debug logger |

---

### SmartSearchMultiDropdown Parameters

#### Core Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `request` | `PaginationRequest` | Yes* | - | Pagination config (for `.withProvider`) |
| `provider` | `PaginationProvider<T>` | Yes* | - | Data source (for `.withProvider`) |
| `cubit` | `SmartPaginationCubit<T>` | Yes* | - | External cubit (for `.withCubit`) |
| `searchRequestBuilder` | `PaginationRequest Function(String)` | Yes | - | Builds request from search query |
| `itemBuilder` | `Widget Function(BuildContext, T)` | Yes | - | Builds each result item |

#### Selection Callback

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `onSelected` | `void Function(List<T>, List<K>)?` | No | `null` | Called with items and keys when selection changes |
| `onChanged` | `ValueChanged<String>?` | No | `null` | Called when text changes |
| `maxSelections` | `int?` | No | `null` | Maximum items to select |

#### Key-Based Selection

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `keyExtractor` | `K Function(T)?` | No | `null` | Extracts unique key from item |
| `selectedKeys` | `List<K>?` | No | `null` | Currently selected keys |
| `selectedKeyLabelBuilder` | `String Function(K)?` | No | `null` | Label for pending keys |
| `selectedKeyBuilder` | `Widget Function(BuildContext, K, VoidCallback)?` | No | `null` | Custom pending key chip |

#### Show Selected Mode

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `showSelected` | `bool` | No | `true` | Show selected chips below search |
| `initialSelectedValues` | `List<T>?` | No | `null` | Pre-selected items on load |
| `selectedItemBuilder` | `Widget Function(BuildContext, T, VoidCallback)?` | No | `null` | Custom selected chip |

#### Selected Items Layout

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `selectedItemsWrap` | `bool` | No | `true` | Wrap chips or scroll horizontally |
| `selectedItemsSpacing` | `double` | No | `8.0` | Horizontal spacing between chips |
| `selectedItemsRunSpacing` | `double` | No | `8.0` | Vertical spacing when wrapped |
| `selectedItemsPadding` | `EdgeInsets` | No | `EdgeInsets.only(top: 12)` | Padding around chips container |

#### Search Box Appearance

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `decoration` | `InputDecoration?` | No | `null` | TextField decoration |
| `style` | `TextStyle?` | No | `null` | Text style |
| `prefixIcon` | `Widget?` | No | `null` | Leading icon |
| `suffixIcon` | `Widget?` | No | `null` | Trailing icon |
| `showClearButton` | `bool` | No | `true` | Show clear button |
| `borderRadius` | `BorderRadius?` | No | `null` | Border radius |

#### Input Configuration

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `textInputAction` | `TextInputAction` | No | `search` | Keyboard action button |
| `textCapitalization` | `TextCapitalization` | No | `none` | Text capitalization |
| `keyboardType` | `TextInputType` | No | `text` | Keyboard type |
| `inputFormatters` | `List<TextInputFormatter>?` | No | `null` | Input formatters |
| `maxLength` | `int?` | No | `null` | Max input length |

#### Validation

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `validator` | `String? Function(String?)?` | No | `null` | Validation function |
| `autovalidateMode` | `AutovalidateMode?` | No | `null` | When to validate |

#### Overlay State Builders

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `loadingBuilder` | `WidgetBuilder?` | No | `null` | Loading state widget |
| `emptyBuilder` | `WidgetBuilder?` | No | `null` | Empty results widget |
| `errorBuilder` | `Widget Function(BuildContext, Exception)?` | No | `null` | Error state widget |
| `headerBuilder` | `WidgetBuilder?` | No | `null` | Dropdown header |
| `footerBuilder` | `WidgetBuilder?` | No | `null` | Dropdown footer |
| `separatorBuilder` | `IndexedWidgetBuilder?` | No | `null` | Item separator |
| `overlayDecoration` | `BoxDecoration?` | No | `null` | Overlay container decoration |

#### Configuration Objects

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `searchConfig` | `SmartSearchConfig` | No | `SmartSearchConfig()` | Search behavior config |
| `overlayConfig` | `SmartSearchOverlayConfig` | No | `SmartSearchOverlayConfig()` | Overlay appearance config |

#### Cubit Options (`.withProvider` only)

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `listBuilder` | `List<T> Function(List<T>)?` | No | `null` | Transform items |
| `onInsertionCallback` | `void Function(List<T>)?` | No | `null` | Called on data load |
| `maxPagesInMemory` | `int` | No | `5` | Max cached pages |
| `retryConfig` | `RetryConfig?` | No | `null` | Retry configuration |
| `dataAge` | `Duration?` | No | `null` | Data expiration |
| `orders` | `SortOrderCollection<T>?` | No | `null` | Sort orders |
| `logger` | `Logger?` | No | `null` | Debug logger |

---

## Error Handling

### Separate First-Page and Load-More Errors

```dart
SmartPaginationListView.withProvider(
  // ...
  firstPageErrorBuilder: (context, error, retry) => CustomErrorBuilder.material(
    context: context,
    error: error,
    onRetry: retry,
    title: 'Failed to load',
  ),
  loadMoreErrorBuilder: (context, error, retry) => CustomErrorBuilder.compact(
    context: context,
    error: error,
    onRetry: retry,
  ),
)
```

### Pre-Built Styles

| Style | Best For |
|-------|----------|
| `CustomErrorBuilder.material()` | First page errors |
| `CustomErrorBuilder.compact()` | Load more errors |
| `CustomErrorBuilder.card()` | Card-based UIs |
| `CustomErrorBuilder.minimal()` | Simple designs |
| `CustomErrorBuilder.snackbar()` | Non-blocking errors |
| `CustomErrorBuilder.custom()` | Custom widgets |

### Automatic Retry

```dart
SmartPaginationCubit<Product>(
  request: PaginationRequest(page: 1, pageSize: 20),
  provider: PaginationProvider.future(fetchProducts),
  retryConfig: RetryConfig(
    maxAttempts: 3,
    initialDelay: Duration(seconds: 1),
    shouldRetry: (error) => error is NetworkException,
  ),
)
```

---

## Data Operations

Programmatically manipulate items through the cubit.

```dart
// Insert
cubit.insertEmit(newProduct);
cubit.insertAllEmit([product1, product2], index: 0);

// Remove
cubit.removeItemEmit(product);
cubit.removeAtEmit(index);
cubit.removeWhereEmit((item) => item.stock == 0);

// Update
cubit.updateItemEmit(
  (item) => item.id == productId,
  (item) => item.copyWith(price: newPrice),
);

// Other
cubit.clearItems();
cubit.reload();
cubit.setItems(customList);
```

---

## Sorting

```dart
final orders = SortOrderCollection<Product>(
  orders: [
    SortOrder.byField(id: 'name', label: 'Name', fieldSelector: (p) => p.name),
    SortOrder.byField(id: 'price', label: 'Price', fieldSelector: (p) => p.price),
  ],
  defaultOrderId: 'name',
);

final cubit = SmartPaginationCubit<Product>(
  request: PaginationRequest(page: 1, pageSize: 20),
  provider: PaginationProvider.future(fetchProducts),
  orders: orders,
);

// Change sort
cubit.setActiveOrder('price');
cubit.resetOrder();
```

---

## Data Providers

### Future (REST API)

```dart
PaginationProvider.future((request) => api.fetchProducts(request))
```

### Stream (Real-time)

```dart
PaginationProvider.stream((request) => firestore.collection('products').snapshots())
```

### Merged Streams

```dart
PaginationProvider.mergeStreams((request) => [
  regularStream(request),
  featuredStream(request),
])
```

---

## Common Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `request` | `PaginationRequest` | Page number and size |
| `provider` | `PaginationProvider<T>` | Data source |
| `itemBuilder` | `Widget Function(context, items, index)` | Item widget builder |
| `invisibleItemsThreshold` | `int` | Preload trigger (default: 3) |
| `separator` | `Widget?` | Divider between items |
| `scrollController` | `ScrollController?` | Custom scroll controller |
| `shrinkWrap` | `bool` | Fit content size |
| `reverse` | `bool` | Reverse scroll direction |

### State Builders

| Parameter | Description |
|-----------|-------------|
| `firstPageLoadingBuilder` | Initial loading widget |
| `firstPageErrorBuilder` | Initial error widget |
| `firstPageEmptyBuilder` | Empty state widget |
| `loadMoreLoadingBuilder` | Bottom loading indicator |
| `loadMoreErrorBuilder` | Pagination error widget |
| `loadMoreNoMoreItemsBuilder` | End of list widget |

---

## Cubit API

```dart
final cubit = SmartPaginationCubit<T>({
  required PaginationRequest request,
  required PaginationProvider<T> provider,
  RetryConfig? retryConfig,
  Duration? dataAge,
  int? maxPagesInMemory,
  SortOrderCollection<T>? orders,
});

// Properties
cubit.currentItems;      // List<T>
cubit.isDataExpired;     // bool
cubit.lastFetchTime;     // DateTime?
cubit.activeOrder;       // SortOrder<T>?

// Methods
cubit.fetchPaginatedList();
cubit.reload();
cubit.insertEmit(item);
cubit.removeItemEmit(item);
cubit.updateItemEmit(matcher, updater);
cubit.setActiveOrder(orderId);
```

---

## Scroll Navigation

```dart
// Attach observer for precise navigation
cubit.attachListObserverController(observerController);

// Navigate
await cubit.animateToIndex(index, alignment: 0.5);
cubit.jumpToIndex(index);
await cubit.animateFirstWhere((item) => item.id == targetId);
cubit.jumpFirstWhere((item) => item.isUnread);
```

---

## Theming

### Pagination Theme

Use standard Flutter theming with custom loading/empty/error builders.

### Search Theme

```dart
MaterialApp(
  theme: ThemeData.light().copyWith(
    extensions: [SmartSearchTheme.light()],
  ),
  darkTheme: ThemeData.dark().copyWith(
    extensions: [SmartSearchTheme.dark()],
  ),
)
```

Custom theme:

```dart
SmartSearchTheme(
  searchBoxBackgroundColor: Colors.grey[100],
  searchBoxBorderRadius: BorderRadius.circular(12),
  overlayBackgroundColor: Colors.white,
  overlayElevation: 8,
  itemHoverColor: Colors.grey[100],
  itemFocusedColor: Colors.blue.withOpacity(0.1),
)
```

---

## Example App

The [example app](example/) includes 29+ demonstration screens covering all features.

```bash
cd example
flutter pub get
flutter run
```

Categories:
- Basic pagination (ListView, GridView, filters)
- Stream examples (single, multi, merged)
- Error handling (all 6 styles, recovery strategies)
- Advanced (scroll control, staggered grid, reorderable)
- Smart Search (key-based selection, multi-select)

---

## Best Practices

**1. Reuse cubits** - Create once in `initState`, dispose in `dispose`

**2. Use state separation** - Different UI for first-page vs load-more errors

**3. Configure preloading** - Adjust `invisibleItemsThreshold` for your scroll speed

**4. Set memory limits** - Use `maxPagesInMemory` for large datasets

**5. Use key-based selection** - For forms and state management in search dropdowns

---

## Resources

- [Error Handling Guide](docs/ERROR_HANDLING.md)
- [Error Images Setup](docs/ERROR_IMAGES_SETUP.md)
- [Changelog](CHANGELOG.md)
- [API Documentation](https://pub.dev/documentation/smart_pagination/latest/)

---

## License

MIT License - see [LICENSE](LICENSE)

---

<div align="center">

**Transport agnostic** - Bring your own async function

Made by [Genius Systems](https://github.com/GeniusSystems24)

</div>
