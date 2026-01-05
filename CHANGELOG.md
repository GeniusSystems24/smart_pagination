# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.7.0] - 2026-01-05

### Added

#### Key-Based Selection for SmartSearchDropdown 🔑

New powerful key-based selection feature that allows selecting items by their unique key/ID instead of by object reference. This is especially useful when working with API data where object instances may differ but the underlying ID is the same.

**New Parameters for SmartSearchDropdown:**

| Parameter | Type | Description |
|-----------|------|-------------|
| `keyExtractor` | `K Function(T item)?` | Extracts unique key from item |
| `selectedKey` | `K?` | Currently selected key (for controlled selection) |
| `onKeySelected` | `void Function(K key, T item)?` | Called when item is selected with its key |
| `selectedKeyLabelBuilder` | `String Function(K key)?` | Builds display label from key when item not loaded |

**New Parameters for SmartSearchMultiDropdown:**

| Parameter | Type | Description |
|-----------|------|-------------|
| `keyExtractor` | `K Function(T item)?` | Extracts unique key from item |
| `selectedKeys` | `Set<K>?` | Currently selected keys (for controlled selection) |
| `onKeysChanged` | `void Function(Set<K> keys, List<T> items)?` | Called when selection changes with keys |
| `initialSelectedKeys` | `Set<K>?` | Pre-selected keys on widget load |

**Usage Example - Single Selection:**
```dart
SmartSearchDropdown<Product, int>.withProvider(
  keyExtractor: (product) => product.id,
  selectedKey: selectedProductId, // int
  onKeySelected: (id, product) {
    setState(() => selectedProductId = id);
    print('Selected product ID: $id');
  },
  // When item isn't loaded yet, show the ID
  selectedKeyLabelBuilder: (id) => 'Product #$id',
  // ... other properties
)
```

**Usage Example - Multi Selection:**
```dart
SmartSearchMultiDropdown<Product, int>.withProvider(
  keyExtractor: (product) => product.id,
  selectedKeys: selectedProductIds, // Set<int>
  onKeysChanged: (ids, products) {
    setState(() => selectedProductIds = ids);
    print('Selected ${ids.length} products');
  },
  initialSelectedKeys: {1, 2, 3}, // Pre-select by IDs
  // ... other properties
)
```

**Benefits:**
- **Pre-selection before data loads**: Select by ID even when item hasn't been fetched
- **Consistent state management**: Use primitive keys instead of object references
- **API-friendly**: Works naturally with REST APIs returning IDs
- **Form integration**: Easily bind to form fields with ID values

---

#### Initial/Pre-Selection Support 📋

Enhanced support for pre-populating search dropdowns with initial values, perfect for edit forms and default selections.

**SmartSearchDropdown:**
- `initialSelectedValue`: Set an initial item object
- `selectedKey` + `selectedKeyLabelBuilder`: Pre-select by key with placeholder label

**SmartSearchMultiDropdown:**
- `initialSelectedValues`: Set initial list of item objects
- `initialSelectedKeys`: Set initial set of keys

**Form Usage Example:**
```dart
// Edit form with pre-selected category
SmartSearchDropdown<Category, int>.withProvider(
  initialSelectedValue: existingProduct.category,
  // OR use key-based pre-selection
  selectedKey: existingProduct.categoryId,
  selectedKeyLabelBuilder: (id) => 'Category #$id (loading...)',
  showSelected: true,
  onKeySelected: (categoryId, category) {
    formData.categoryId = categoryId;
  },
)
```

---

#### New Example Screens 📱

Added two comprehensive example screens demonstrating the new features:

1. **Key-Based Selection Screen**: Shows 4 examples of key-based selection:
   - Basic key extraction and selection
   - Pre-selection by key with pending label
   - Multi-select with key sets
   - Custom key label builder display

2. **Initial Selection Screen**: Shows 4 examples of initial value handling:
   - Initial selected value for single dropdown
   - Form integration with default values
   - Multi-select with initial values list
   - Conditional initial value based on context

---

### Fixed

- Fixed type inference issues in `SmartSearchController` where `Object?` couldn't be assigned to generic type `K?`
- Fixed null check operator usage on nullable type parameters in `selectedKeyLabel` getter
- Renamed scroll mixin and typedefs for consistency:
  - `SmartPaginationScrollToItem` → `PaginationScrollToItem`
  - `SmartPaginationScrollToIndex` → `PaginationScrollToIndex`
  - `SmartPaginationScrollToItemMixin` → `PaginationScrollToItemMixin`

---

## [2.6.0] - 2026-01-02

### Added

#### Scroll Navigation Methods - Programmatic Scrolling 🎯

New scroll navigation methods in `SmartPaginationCubit` using the `scrollview_observer` package. These methods allow you to programmatically scroll to specific items in your list or grid views.

**New Methods:**

| Method | Description |
|--------|-------------|
| `animateToIndex(int index, {...})` | Smoothly animate to item at index |
| `jumpToIndex(int index, {...})` | Instantly jump to item at index |
| `animateFirstWhere(bool Function(T) test, {...})` | Animate to first item matching predicate |
| `jumpFirstWhere(bool Function(T) test, {...})` | Jump to first item matching predicate |
| `scrollToIndex(int index, {bool animate})` | Convenience method combining animate/jump |
| `scrollFirstWhere(bool Function(T) test, {bool animate})` | Convenience method combining animate/jump |

**Observer Controller Management:**

| Method | Description |
|--------|-------------|
| `attachListObserverController(ListObserverController)` | Attach controller for ListView |
| `attachGridObserverController(GridObserverController)` | Attach controller for GridView |
| `detachListObserverController()` | Detach list observer controller |
| `detachGridObserverController()` | Detach grid observer controller |
| `detachAllObserverControllers()` | Detach all observer controllers |

**Properties:**

| Property | Type | Description |
|----------|------|-------------|
| `hasListObserverController` | `bool` | Whether a list observer is attached |
| `hasGridObserverController` | `bool` | Whether a grid observer is attached |
| `hasObserverController` | `bool` | Whether any observer is attached |

**Usage Example:**
```dart
// Create the observer controller
final scrollController = ScrollController();
final observerController = ListObserverController(controller: scrollController);

// Attach to cubit
cubit.attachListObserverController(observerController);

// Navigate to specific index with animation
await cubit.animateToIndex(
  10,
  duration: Duration(milliseconds: 500),
  curve: Curves.easeOutCubic,
  alignment: 0.5, // Center in viewport
);

// Jump instantly to an index
cubit.jumpToIndex(0);

// Find and scroll to first matching item
await cubit.animateFirstWhere(
  (message) => message.id == targetId,
  alignment: 0.3,
);

// In your widget, wrap with ListViewObserver
ListViewObserver(
  controller: observerController,
  child: SmartPagination<Message>.listViewWithCubit(
    cubit: cubit,
    scrollController: scrollController,
    itemBuilder: (context, items, index) => MessageWidget(items[index]),
  ),
)
```

**Parameters:**

All navigation methods support these parameters:
- `duration` - Animation duration (default: 300ms)
- `curve` - Animation curve (default: Curves.easeInOut)
- `alignment` - Position in viewport (0.0 = top, 0.5 = center, 1.0 = bottom)
- `padding` - Additional padding for alignment
- `isFixedHeight` - Whether items have fixed height (optimization)
- `sliverContext` - Context for sliver-based scrolling

---

#### Chat Screen Example 💬

New comprehensive chat screen example demonstrating scroll navigation features:
- Animated scroll to specific messages
- Jump to unread messages
- Search and scroll to matching messages
- Message highlighting on navigation
- Real-time message insertion with auto-scroll

---

## [2.5.1] - 2026-01-02

### Fixed

#### Concurrent Request Prevention 🔒

Fixed an issue where multiple fetch requests could be executed simultaneously, causing duplicate data or race conditions.

**The Problem:**
- When `fetchPaginatedList()` was called multiple times rapidly (e.g., from multiple widget rebuilds), each call would trigger a separate network request
- This led to duplicate items, race conditions, and wasted network resources

**The Solution:**
- Added `_isFetching` flag to track ongoing fetch operations
- New requests are now queued/ignored while a fetch is in progress
- The cubit now exposes `isFetching` getter to check the current state

```dart
// Check if a fetch is in progress
if (!cubit.isFetching) {
  cubit.fetchPaginatedList();
}
```

---

#### Error Retry Strategy - Prevent Infinite Retries 🛡️

Added configurable error retry strategy to prevent infinite retry loops when server errors occur.

**The Problem:**
- When a server error occurred, widget rebuilds would trigger automatic retries endlessly
- This caused unnecessary network load and poor user experience

**The Solution:**
- New `ErrorRetryStrategy` enum with three modes:
  - `automatic`: Default behavior, retries on next fetch call
  - `manual`: Requires explicit `retryAfterError()` call
  - `none`: No automatic retry, requires `refreshPaginatedList()`

**Usage:**
```dart
SmartPaginationCubit<Product>(
  request: request,
  provider: provider,
  // Prevent automatic retries on error
  errorRetryStrategy: ErrorRetryStrategy.manual,
);

// Later, when user taps retry button:
if (cubit.hasError) {
  cubit.retryAfterError();
}
```

**New Cubit Properties:**

| Property | Type | Description |
|----------|------|-------------|
| `isFetching` | `bool` | Whether a fetch is in progress |
| `hasError` | `bool` | Whether the last fetch resulted in an error |
| `lastError` | `Exception?` | The last error that occurred |

**New Cubit Methods:**

| Method | Description |
|--------|-------------|
| `retryAfterError()` | Explicitly retry after an error (for manual strategy) |
| `clearError()` | Clear error state without retrying |

---

## [2.5.0] - 2025-12-31

### Added

#### Overlay Value Parameter - Context-Aware Content 🎯

New feature that allows passing a value when showing the overlay programmatically. This enables you to determine what content to display in the overlay based on the passed value.

**Usage Example:**
```dart
// Show overlay for user search
controller.showOverlay(value: 'user');

// Show overlay for category selection
controller.showOverlay(value: CategoryType.products);

// Show overlay with numeric identifier
controller.showOverlay(value: 1);

// In your widget, check the value:
if (controller.overlayValue == 'user') {
  return UserSearchContent();
}

// Type-safe access
final categoryId = controller.getOverlayValue<int>(); // Returns int? or null
```

**New Controller Methods:**

| Method | Description |
|--------|-------------|
| `showOverlay({Object? value})` | Show overlay with optional context value |
| `hideOverlay({bool clearValue = true})` | Hide overlay, optionally preserving the value |
| `toggleOverlay({Object? value})` | Toggle visibility with optional value |
| `setOverlayValue(Object? value)` | Set value without showing overlay |
| `clearOverlayValue()` | Clear the overlay value |
| `getOverlayValue<V>()` | Type-safe value access, returns null if type mismatch |

**New Controller Properties:**

| Property | Type | Description |
|----------|------|-------------|
| `overlayValue` | `Object?` | Current overlay value |
| `hasOverlayValue` | `bool` | Whether a value is set |

---

#### Overlay Animation Types - 13 Animation Styles 🎬

New powerful animation system for overlay show/hide transitions. Choose from 13 different animation types to match your app's design.

**Available Animation Types:**

| Animation Type | Description |
|----------------|-------------|
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

**Usage Example:**
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

**New Configuration Parameters:**

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `animationType` | `OverlayAnimationType` | `fade` | Animation style for show/hide |
| `animationCurve` | `Curve` | `Curves.easeOutCubic` | Animation curve for the transition |

---

#### Scroll-Aware Overlay Positioning 📜

The overlay now tracks the search field position in real-time when the user scrolls. This ensures the overlay stays correctly positioned relative to its target, even in scrollable content.

**Key Features:**
- Real-time position updates during scrolling
- Automatic attachment to nearest scrollable ancestor
- Screen orientation/size change handling
- Can be disabled via configuration

**Usage Example:**
```dart
SmartSearchDropdown<Product>.withProvider(
  // ... other properties
  overlayConfig: SmartSearchOverlayConfig(
    followTargetOnScroll: true, // Default: true
  ),
)
```

**New Configuration Parameter:**

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `followTargetOnScroll` | `bool` | `true` | Whether overlay follows target on scroll |

---

#### High-Accuracy Position Tracking 🎯

Enhanced position tracking system for maximum accuracy when the overlay follows the search field during scrolling.

**Technical Implementation:**
- **Ticker-based monitoring**: Continuous position checking every frame for instant updates
- **Multi-level scroll tracking**: Attaches to all ancestor `ScrollPosition` objects
- **NotificationListener wrapper**: Catches scroll events from any scrollable in the widget tree
- **Smart update scheduling**: Uses `addPostFrameCallback` for smooth, non-blocking updates
- **Optimized rebuilds**: Only triggers overlay rebuild when position actually changes

**How it works:**
```dart
// Tracks position changes every frame
Ticker _positionTicker;
Offset? _lastKnownPosition;

void _onPositionTick(Duration elapsed) {
  final currentPosition = renderBox.localToGlobal(Offset.zero);
  // Only update if position actually changed
  if (_lastKnownPosition != currentPosition) {
    _lastKnownPosition = currentPosition;
    _overlayEntry!.markNeedsBuild();
  }
}
```

**Benefits:**
- Works with nested scrollables (e.g., ListView inside PageView)
- Handles keyboard appearance/disappearance
- Responds to screen rotation and resize
- Zero lag between scroll and overlay position update

---

## [2.4.2] - 2025-12-30

### Added

#### SmartSearchMultiDropdown - Multi-Selection Search 🎯

New widget for selecting multiple items from search results with continuous search capability.

**Key Features:**
- Search and select multiple items
- Search box remains visible after selection (for continuous searching)
- Selected items displayed below the search box with individual remove buttons
- Maximum selections limit support
- Custom selected item builder for chip styling
- Configurable wrap/scroll for selected items display

**Basic Usage:**
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
  ),
  showSelected: true,
  onSelectionChanged: (products) {
    print('Selected ${products.length} items');
  },
)
```

**With Max Selections:**
```dart
SmartSearchMultiDropdown<Product>.withProvider(
  // ... other properties
  maxSelections: 5, // Limit to 5 items
  onSelectionChanged: (products) {
    // Handle selection
  },
)
```

**Custom Selected Item Builder:**
```dart
SmartSearchMultiDropdown<Product>.withProvider(
  // ... other properties
  selectedItemBuilder: (context, product, onRemove) => Chip(
    label: Text(product.name),
    onDeleted: onRemove,
    deleteIcon: Icon(Icons.close, size: 18),
  ),
)
```

**New Parameters:**

| Parameter | Type | Description |
|-----------|------|-------------|
| `onSelectionChanged` | `ValueChanged<List<T>>?` | Called when selection changes |
| `initialSelectedValues` | `List<T>?` | Pre-selected items on widget load |
| `maxSelections` | `int?` | Maximum number of selectable items |
| `selectedItemBuilder` | `Widget Function(...)` | Custom builder for selected item chips |
| `selectedItemsWrap` | `bool` | Wrap items or use horizontal scroll |
| `selectedItemsSpacing` | `double` | Horizontal spacing between chips |
| `selectedItemsRunSpacing` | `double` | Vertical spacing when wrapped |
| `selectedItemsPadding` | `EdgeInsets` | Padding around selected items container |

**Controller Methods:**

```dart
// Access controller
final controller = SmartSearchMultiController<Product>(...);

// Check selection
controller.selectedItems; // List of selected items
controller.selectionCount; // Number of selected items
controller.hasSelectedItems; // Whether any items are selected
controller.isMaxSelectionsReached; // Whether max limit reached
controller.isItemSelected(item); // Check if specific item is selected

// Modify selection
controller.addItem(item); // Add item to selection
controller.removeItem(item); // Remove item from selection
controller.removeItemAt(index); // Remove item by index
controller.toggleItemSelection(item); // Toggle selection state
controller.clearAllSelections(); // Clear all selections
controller.setSelectedItems([...]); // Set selection programmatically
```

---

## [2.3.2] - 2025-12-28

### Changed

#### Parameter Rename: initialSelectedItem → initialSelectedValue 🔄

Renamed `initialSelectedItem` to `initialSelectedValue` for consistency and clarity.

```dart
// Before (v2.3.0 - v2.3.1)
SmartSearchDropdown<Product>.withProvider(
  initialSelectedItem: preSelectedProduct,
  // ...
)

// After (v2.3.2+)
SmartSearchDropdown<Product>.withProvider(
  initialSelectedValue: preSelectedProduct,
  // ...
)
```

#### Removed: initialValue Parameter ❌

The `initialValue` parameter (added in v2.3.1) has been removed. Use `initialSelectedValue` instead to pre-select an item.

#### SmartSearchTheme Auto-Detection 🎨

`SmartSearchTheme.of(context)` now automatically detects the system theme (light/dark) when no explicit theme extension is provided.

**Before (v2.3.1):**
```dart
// Always fell back to light theme
SmartSearchTheme.of(context); // → SmartSearchTheme.light()
```

**After (v2.3.2):**
```dart
// Now respects system brightness
SmartSearchTheme.of(context);
// → SmartSearchTheme.dark() if system is in dark mode
// → SmartSearchTheme.light() if system is in light mode
```

This means SmartSearch widgets will automatically adapt to the system theme without requiring explicit `SmartSearchTheme.dark()` or `SmartSearchTheme.light()` configuration.

---

## [2.3.1] - 2025-12-28

### Added

#### Enhanced SmartSearchDropdown Form Support 📝

New form-related features for SmartSearchDropdown to enable form validation and input formatting.

**New Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| `validator` | `String? Function(String?)?` | Form validation function (enables TextFormField) |
| `textInputAction` | `TextInputAction` | Keyboard action button (default: search) |
| `inputFormatters` | `List<TextInputFormatter>?` | Input formatters for text formatting |
| `autovalidateMode` | `AutovalidateMode?` | When to validate the input |
| `onChanged` | `ValueChanged<String>?` | Called when text changes |
| `maxLength` | `int?` | Maximum input length |
| `textCapitalization` | `TextCapitalization` | Text capitalization behavior |
| `keyboardType` | `TextInputType` | Type of keyboard to display |

**Usage with Validation:**
```dart
SmartSearchDropdown<Product>.withProvider(
  // ... other properties
  validator: (value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a search term';
    }
    return null;
  },
  autovalidateMode: AutovalidateMode.onUserInteraction,
  textInputAction: TextInputAction.search,
)
```

**Usage with Input Formatters:**
```dart
SmartSearchDropdown<Product>.withProvider(
  // ... other properties
  inputFormatters: [
    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\s]')),
    LengthLimitingTextInputFormatter(50),
  ],
  maxLength: 50,
  textCapitalization: TextCapitalization.words,
)
```

---

## [2.3.0] - 2025-12-18

### Added

#### Show Selected Mode for SmartSearchDropdown 🎯

New `showSelected` feature that displays the selected item instead of the search box after selection.

**Basic Usage:**
```dart
SmartSearchDropdown<Product>.withProvider(
  // ... other properties
  showSelected: true,
  onItemSelected: (product) {
    print('Selected: ${product.name}');
  },
)
```

**Custom Selected Item Display:**
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

**With Initial Selection:**
```dart
SmartSearchDropdown<Product>.withProvider(
  // ... other properties
  showSelected: true,
  initialSelectedItem: preSelectedProduct,
)
```

**New Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| `showSelected` | `bool` | When true, shows selected item instead of search box |
| `selectedItemBuilder` | `Widget Function(context, item, onClear)?` | Custom builder for selected item display |
| `initialSelectedItem` | `T?` | Pre-selected item to display on widget load |

**New Controller Methods:**
```dart
// Get selected item
final item = controller.selectedItem;

// Check if item is selected
if (controller.hasSelectedItem) { ... }

// Set selected item programmatically
controller.setSelectedItem(product);

// Clear selection and show search box
controller.clearSelection();
controller.clearSelection(requestFocus: false); // Don't auto-focus
```

**Behavior:**
- When `showSelected: true` and an item is selected, the search box is replaced with the selected item display
- Tapping on the selected item (or the clear button) clears the selection and shows the search box again
- The selected item is automatically styled using `SmartSearchTheme` colors
- If `selectedItemBuilder` is not provided, a default display using `itemBuilder` is used

---

## [2.2.0] - 2025-12-18

### Added

#### SmartSearchTheme - ThemeExtension Support 🎨

New powerful theming system for SmartSearch widgets using Flutter's ThemeExtension pattern.

**Light & Dark Theme Support:**
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

**Comprehensive Theme Properties:**

| Category | Properties |
|----------|------------|
| **Search Box** | `searchBoxBackgroundColor`, `searchBoxTextColor`, `searchBoxHintColor`, `searchBoxBorderColor`, `searchBoxFocusedBorderColor`, `searchBoxIconColor`, `searchBoxCursorColor`, `searchBoxBorderRadius`, `searchBoxElevation`, `searchBoxShadowColor` |
| **Overlay** | `overlayBackgroundColor`, `overlayBorderColor`, `overlayBorderRadius`, `overlayElevation`, `overlayShadowColor` |
| **Items** | `itemBackgroundColor`, `itemHoverColor`, `itemFocusedColor`, `itemSelectedColor`, `itemTextColor`, `itemSubtitleColor`, `itemIconColor`, `itemDividerColor` |
| **States** | `loadingIndicatorColor`, `emptyStateIconColor`, `emptyStateTextColor`, `errorIconColor`, `errorTextColor`, `errorButtonColor` |
| **Scrollbar** | `scrollbarColor`, `scrollbarThickness`, `scrollbarRadius` |

**Factory Constructors:**
- `SmartSearchTheme.light()` - Modern light theme with Indigo accent colors
- `SmartSearchTheme.dark()` - Dark theme with purple accent colors

**Accessing Theme:**
```dart
// Get theme with fallback to light
final theme = SmartSearchTheme.of(context);

// Get theme or null
final theme = SmartSearchTheme.maybeOf(context);
```

**Custom Theme Example:**
```dart
SmartSearchTheme(
  searchBoxBackgroundColor: Colors.grey[100],
  searchBoxTextColor: Colors.black87,
  searchBoxFocusedBorderColor: Colors.blue,
  overlayBackgroundColor: Colors.white,
  itemFocusedColor: Colors.blue.withOpacity(0.1),
  itemHoverColor: Colors.grey[200],
  loadingIndicatorColor: Colors.blue,
  // ... more properties
)
```

**Theme Interpolation:**
- Full `lerp` support for smooth theme transitions
- Animated theme switching support

### Changed

- **SmartSearchBox**: Now uses `SmartSearchTheme` for default styling
- **SmartSearchOverlay**: Uses theme for overlay container, items, and state widgets
- **_FocusableItem**: Now supports hover color from theme
- **Scrollbar**: Added theme-aware scrollbar to results list
- **Example App**: Added theme toggle button in Search Dropdown screen

### Updated

- Version bumped to 2.2.0
- Package description updated to include ThemeExtension support

---

## [2.1.0] - 2025-12-18

### Added

#### Keyboard Navigation for SmartSearchDropdown ⌨️

Full keyboard navigation support for the search dropdown with focus state persistence.

**Keyboard Shortcuts:**
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

**Key Features:**
- **Focus Persistence**: Focus position is preserved when overlay is closed and reopened
- **Visual Feedback**: Focused item is highlighted with configurable decoration
- **Auto-Scroll**: List automatically scrolls to keep focused item visible
- **Mouse Hover**: Hovering over an item also updates focus
- **Smooth Animations**: Focus transitions with 100ms animation

**New Controller Methods:**
```dart
// Navigation
controller.moveToNextItem();
controller.moveToPreviousItem();
controller.moveToFirstItem();
controller.moveToLastItem();
controller.setFocusedIndex(index);
controller.clearItemFocus();

// Selection
controller.selectFocusedItem();

// Properties
controller.focusedIndex;      // Current focused index (-1 if none)
controller.focusedItem;       // Current focused item (null if none)
controller.hasItemFocus;      // Whether an item is focused
```

**Usage Example:**
```dart
SmartSearchDropdown<Product>.withProvider(
  // ... other properties
  searchConfig: SmartSearchConfig(
    clearOnClose: false, // Keep focus when closing
  ),
)
```

---

## [2.0.0] - 2025-12-18

### Added

#### SmartSearchBox - Search with Overlay Dropdown 🔍

New powerful search component that connects to SmartPaginationCubit for searching with an auto-positioning overlay dropdown.

**New Classes:**
- `SmartSearchBox<T>` - Search input widget connected to pagination cubit
- `SmartSearchOverlay<T>` - Combines search box with overlay dropdown
- `SmartSearchDropdown<T>` - Convenient all-in-one search dropdown widget
- `SmartSearchController<T>` - Controller for managing search state
- `SmartSearchConfig` - Configuration for search behavior (debounce, min length, etc.)
- `SmartSearchOverlayConfig` - Configuration for overlay appearance and positioning
- `OverlayPosition` - Enum for overlay positioning (auto, top, bottom, left, right)
- `OverlayPositioner` - Utility for calculating optimal overlay position

**Key Features:**
- **Auto-Positioning**: Overlay automatically positions itself in the best available space
- **Cubit Integration**: Directly connected to SmartPaginationCubit for data fetching
- **Debounced Search**: Configurable delay to prevent excessive API calls
- **Flexible Placement**: Position overlay top, bottom, left, right, or auto
- **Customizable**: Full control over search box and overlay appearance
- **Animations**: Smooth show/hide animations with configurable duration

**SmartSearchDropdown Constructors:**
- `.withProvider()` - Creates internal cubit with data provider
- `.withCubit()` - Uses externally managed cubit

### Usage Examples

```dart
// Simple search dropdown with provider
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
    title: Text(product.name),
    subtitle: Text('\$${product.price}'),
  ),
  onItemSelected: (product) {
    Navigator.pop(context, product);
  },
)

// With external cubit
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
  overlayConfig: SmartSearchOverlayConfig(
    position: OverlayPosition.bottom, // Force bottom position
    maxHeight: 400,
    borderRadius: 12,
    elevation: 8,
  ),
)

// Using SmartSearchBox and SmartSearchOverlay separately
final controller = SmartSearchController<Product>(
  cubit: productsCubit,
  searchRequestBuilder: (query) => PaginationRequest(
    page: 1,
    pageSize: 20,
    searchQuery: query,
  ),
  config: SmartSearchConfig(
    debounceDelay: Duration(milliseconds: 500),
    minSearchLength: 2,
  ),
);

// Place search box in app bar
AppBar(
  title: SmartSearchBox<Product>(
    controller: controller,
    decoration: InputDecoration(hintText: 'Search...'),
  ),
)

// Place overlay anywhere in your layout
SmartSearchOverlay<Product>(
  controller: controller,
  itemBuilder: (context, product) => ProductTile(product),
  onItemSelected: selectProduct,
)
```

---

## [0.1.4] - 2025-12-18

### Added

#### Sorting & Orders Feature 📊

New powerful sorting functionality that allows programmatic control over item ordering:

#### Sorted Insertion (Performance Fix) ⚡

Item insertion methods now respect the active sort order by inserting items directly at the correct sorted position using binary search. This prevents visual flickering that occurred when items were added then re-sorted.

**Improved Methods:**
- `insertEmit()` - Inserts items at correct sorted position
- `insertAllEmit()` - Uses efficient merge algorithm for batch insertions
- `addOrUpdateEmit()` - Positions new items correctly; repositions updated items if sort field changed
- `updateItemEmit()` - Repositions item if sort field changes
- `updateWhereEmit()` - Batch repositions multiple updated items efficiently

**Benefits:**
- **No Visual Flickering**: Items appear directly in their final position
- **Efficient Algorithm**: Binary search for single insertions, merge sort for batches
- **Automatic**: Works transparently when sort order is active
- **Backward Compatible**: Falls back to index-based insertion when no sorting is active

**New Classes:**
- `SortOrder<T>` - Defines how items should be sorted
- `SortOrderCollection<T>` - Manages multiple sort orders with an active selection
- `SortDirection` - Enum for ascending/descending direction

**Cubit Constructor Parameter:**
- `orders: SortOrderCollection<T>?` - Set initial sorting configuration

**New Cubit Methods:**
- `setActiveOrder(String orderId)` - Change the active sort order
- `resetOrder()` - Reset to default sort order
- `clearOrder()` - Remove sorting (show original order)
- `addSortOrder(SortOrder<T> order)` - Add a new sort order dynamically
- `removeSortOrder(String orderId)` - Remove a sort order
- `sortBy(ItemComparator<T> comparator)` - One-time sort with custom comparator
- `setOrders(SortOrderCollection<T>? orders)` - Replace entire orders collection

**New Cubit Properties:**
- `orders` - Get current sort order collection
- `activeOrder` - Get currently active sort order
- `activeOrderId` - Get ID of active sort order
- `availableOrders` - Get list of all available sort orders

**State Updates:**
- `SmartPaginationLoaded.activeOrderId` - Track current sort order in state

### Usage Examples

```dart
// Define sort orders
final orders = SortOrderCollection<Product>(
  orders: [
    SortOrder.byField(
      id: 'name',
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
    SortOrder<Product>(
      id: 'custom',
      label: 'Custom Sort',
      comparator: (a, b) => a.rating.compareTo(b.rating),
    ),
  ],
  defaultOrderId: 'name',
);

// Create cubit with orders
final cubit = SmartPaginationCubit<Product>(
  request: PaginationRequest(page: 1, pageSize: 20),
  provider: PaginationProvider.future(fetchProducts),
  orders: orders,
);

// Change sort order programmatically
cubit.setActiveOrder('price_low');  // Sort by price ascending
cubit.setActiveOrder('price_high'); // Sort by price descending
cubit.resetOrder();                 // Reset to default (name)
cubit.clearOrder();                 // Remove sorting

// Add new sort order dynamically
cubit.addSortOrder(SortOrder.byField(
  id: 'newest',
  label: 'Newest First',
  fieldSelector: (p) => p.createdAt,
  direction: SortDirection.descending,
));

// One-time custom sort
cubit.sortBy((a, b) => a.stock.compareTo(b.stock));

// Access current order in state
if (state is SmartPaginationLoaded<Product>) {
  print('Current sort: ${state.activeOrderId}');
}
```

---

## [0.1.3] - 2025-12-17

### Added

#### Specialized Widget Classes 🎯

New dedicated widget classes for each view type, providing cleaner and more intuitive API:

**New Widget Classes:**
- `SmartPaginationListView` - Paginated ListView widget
- `SmartPaginationGridView` - Paginated GridView widget
- `SmartPaginationColumn` - Paginated non-scrollable Column layout
- `SmartPaginationRow` - Paginated non-scrollable Row layout
- `SmartPaginationPageView` - Paginated PageView widget
- `SmartPaginationStaggeredGridView` - Paginated Pinterest-style masonry layout
- `SmartPaginationReorderableListView` - Paginated drag-and-drop reorderable list

**Each widget class provides:**
- `.withProvider()` constructor - Creates cubit internally with data provider
- `.withCubit()` constructor - Uses externally managed cubit

**Benefits:**
- **Clearer Intent**: Each widget class explicitly states its layout type
- **Better IDE Support**: Autocomplete shows relevant parameters for each view type
- **Reduced Confusion**: No need to specify `itemBuilderType` parameter
- **Same Functionality**: All features from `SmartPagination` are available

### Usage Examples

```dart
// Before (using SmartPagination with named constructors)
SmartPagination.listViewWithProvider(
  request: PaginationRequest(page: 1, pageSize: 20),
  provider: PaginationProvider.future(fetchProducts),
  itemBuilder: (context, items, index) => ProductTile(items[index]),
)

// After (using specialized widget class)
SmartPaginationListView.withProvider(
  request: PaginationRequest(page: 1, pageSize: 20),
  provider: PaginationProvider.future(fetchProducts),
  itemBuilder: (context, items, index) => ProductTile(items[index]),
)

// GridView example
SmartPaginationGridView.withProvider(
  request: PaginationRequest(page: 1, pageSize: 20),
  provider: PaginationProvider.future(fetchProducts),
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
  itemBuilder: (context, items, index) => ProductCard(items[index]),
)

// External cubit example
final cubit = SmartPaginationCubit<Product>(
  request: PaginationRequest(page: 1, pageSize: 20),
  provider: PaginationProvider.future(fetchProducts),
  dataAge: Duration(minutes: 5),
);

SmartPaginationListView.withCubit(
  cubit: cubit,
  itemBuilder: (context, items, index) => ProductTile(items[index]),
)
```

### Note

The original `SmartPagination` class with named constructors remains available for backward compatibility. Both approaches work identically - choose the style that best fits your preferences.

---

## [0.1.2] - 2025-12-17

### Added

#### Data Age & Automatic Expiration ⏰

New feature for automatic data invalidation and refresh when using cubit as a global variable:

**New Parameters:**
- `dataAge: Duration?` - Configure how long data remains valid after fetching

**New Properties on SmartPaginationCubit:**
- `dataAge` - Get the configured data age duration
- `lastFetchTime` - Get the timestamp of the last successful data fetch
- `isDataExpired` - Check if data has expired based on the configured dataAge
- `checkAndResetIfExpired()` - Check expiration and reset if expired (returns `true` if reset)

**New Properties on SmartPaginationLoaded State:**
- `fetchedAt: DateTime?` - Timestamp when data was initially fetched
- `dataExpiredAt: DateTime?` - Timestamp when data will expire (null if no expiration)

**Automatic Behavior:**
- When `fetchPaginatedList()` is called, it automatically checks if data has expired
- If expired, the cubit resets to initial state and triggers a fresh data load
- Perfect for global cubits that persist across screen navigations
- **Timer refreshes on any data interaction:** insert, update, remove, load more
- This ensures active users don't experience unexpected data resets

### Usage Example

```dart
// Create a global cubit with 5-minute data age
final productsCubit = SmartPaginationCubit<Product>(
  request: PaginationRequest(page: 1, pageSize: 20),
  provider: PaginationProvider.future(fetchProducts),
  dataAge: Duration(minutes: 5), // Data expires after 5 minutes
);

// When re-entering the screen, data is automatically refreshed if expired
// Or manually check expiration:
if (productsCubit.isDataExpired) {
  print('Data is stale, will refresh on next fetch');
}

// Access expiration info from state
if (state is SmartPaginationLoaded<Product>) {
  print('Data fetched at: ${state.fetchedAt}');
  print('Data expires at: ${state.dataExpiredAt}');
}
```

---

## [0.1.1] - 2025-12-17

### Added

#### Cubit Data Operations 🎛️

New programmatic data operations accessible from anywhere in your app via the cubit:

**Insert Operations:**
- `insertEmit(item, {index})` - Insert a single item at specified index (default: 0)
- `insertAllEmit(items, {index})` - Insert multiple items at specified index

**Remove Operations:**
- `removeItemEmit(item)` - Remove an item by reference, returns `true` if found
- `removeAtEmit(index)` - Remove item at index, returns the removed item or `null`
- `removeWhereEmit(test)` - Remove all items matching predicate, returns count removed

**Update Operations:**
- `updateItemEmit(matcher, updater)` - Update first matching item, returns `true` if updated
- `updateWhereEmit(matcher, updater)` - Update all matching items, returns count updated

**Other Operations:**
- `clearItems()` - Clear all items from the list
- `reload()` - Reload data from the beginning (alias for `refreshPaginatedList`)
- `setItems(items)` - Set the list to a completely new set of items
- `currentItems` - Getter to access current list of items (read-only)

#### Example App
- **Data Operations Screen** - New example demonstrating all cubit data operations:
  - Interactive buttons to test each operation
  - Long-press to remove items
  - Visual feedback for all operations

### Usage Examples

```dart
// Get the cubit reference
final cubit = SmartPaginationCubit<Product>(...);

// Insert operations
cubit.insertEmit(newProduct);
cubit.insertEmit(newProduct, index: 5);
cubit.insertAllEmit([product1, product2, product3]);

// Remove operations
cubit.removeItemEmit(productToRemove);
cubit.removeAtEmit(0); // Remove first item
cubit.removeWhereEmit((item) => item.price > 100); // Remove expensive items

// Update operations
cubit.updateItemEmit(
  (item) => item.id == '123',
  (item) => item.copyWith(price: item.price * 0.9), // Apply discount
);
cubit.updateWhereEmit(
  (item) => item.category == 'sale',
  (item) => item.copyWith(price: item.price * 0.8),
);

// Other operations
cubit.clearItems();
cubit.reload();
cubit.setItems(customProductList);

// Access current items
final items = cubit.currentItems;
print('Total items: ${items.length}');
```

---

## [0.1.0] - 2025-12-01

### Added

- **New Constructor**: `SmartPagination.column` and `SmartPagination.columnWithCubit` for non-scrollable column layouts.
- **External Cubit Support**: Added `...WithCubit` named constructors for all view types (`listViewWithCubit`, `gridViewWithCubit`, `pageViewWithCubit`, `staggeredGridViewWithCubit`, `rowWithCubit`) to easily use externally created Cubits.
- **Exposed Parameters**: Added missing parameters to all convenience constructors:
  - `scrollController`: For external scroll control.
  - `cacheExtent`: For viewport caching customization.
  - `invisibleItemsThreshold`: For configuring smart preloading.
  - **State Builders**: `firstPageLoadingBuilder`, `firstPageErrorBuilder`, `firstPageEmptyBuilder`, `loadMoreLoadingBuilder`, `loadMoreErrorBuilder`, `loadMoreNoMoreItemsBuilder`.

### Breaking Changes ⚠️

- **Constructor Renaming**:
  - `SmartPagination(...)` is now `SmartPagination.withProvider(...)`.
  - `SmartPagination.cubit(...)` is now `SmartPagination.withCubit(...)`.
  - All named constructors now have explicit suffixes:
    - `listView` -> `listViewWithProvider` / `listViewWithCubit`
    - `gridView` -> `gridViewWithProvider` / `gridViewWithCubit`
    - `pageView` -> `pageViewWithProvider` / `pageViewWithCubit`
    - `staggeredGridView` -> `staggeredGridViewWithProvider` / `staggeredGridViewWithCubit`
    - `column` -> `columnWithProvider` / `columnWithCubit`
    - `row` -> `rowWithProvider` / `rowWithCubit`
    - `reorderableListView` -> `reorderableListViewWithProvider` / `reorderableListViewWithCubit`

- **Removed Convenience Widgets**: `SmartPaginatedListView` and `SmartPaginatedGridView` have been removed. Use `SmartPagination` directly.
- **API Unification**:
  - `childBuilder` is renamed to `itemBuilder`.
  - `itemBuilder` signature changed from `(context, item, index)` to `(context, items, index)`. You must now access the item using `items[index]`.
- **Configuration**:
  - Use `itemBuilderType: PaginateBuilderType.gridView` for grid layouts.
  - Use `itemBuilderType: PaginateBuilderType.listView` (default) for list layouts.

### Changed

- Updated all example screens to use the new constructor names.
- Improved API clarity by explicitly distinguishing between `Provider` (internal Cubit creation) and `Cubit` (external Cubit injection) usage.
- Updated `SmartPagination` to be the single entry point for all pagination types.
- Updated `emptyWidget`, `loadingWidget`, and `bottomLoader` to accept `Widget` directly.
- Updated `separator` to accept `Widget` directly.

## [0.0.6] - 2025-11-30

### Added

- Documentation preparation for pub.dev publication
- Comprehensive example screens section in README (28 screens documented)
- Screenshot infrastructure with placeholder guides
- Screenshots directory structure (`basic/`, `streams/`, `advanced/`, `errors/`)

### Changed

- Enhanced README.md for pub.dev with professional presentation
  - Added "Why Smart Pagination?" section highlighting key benefits
  - Added comprehensive Table of Contents
  - Reorganized content with clear visual separators
  - Added detailed documentation for all 28 example screens
  - Added Features Comparison table vs other libraries
  - Added Use Cases section (E-commerce, Social Media, Content Apps, etc.)
  - Added Learning Resources section
  - Enhanced API Reference section
  - Added Best Practices section with code examples
  - Total: 2,100+ lines of comprehensive documentation
- Updated pubspec.yaml description for better pub.dev visibility
  - Highlights: BLoC state management, 6+ view types, advanced error handling
  - Emphasizes: Zero boilerplate, type-safe, well-tested (60+ tests)

### Documentation

- Created `screenshots/README.md` - Complete guide for capturing screenshots
- Created category-specific guides (`PLACEHOLDER.md` files)
- Added instructions for Flutter DevTools, command line, and automation
- Included image optimization guide and Git LFS setup

---

## [0.0.5] - 2025-11-02

### Added

#### Unified Provider Pattern 🔄

- **PaginationProvider Sealed Class**: Type-safe unified provider pattern
  - `PaginationProvider.future()` for REST API pagination
  - `PaginationProvider.stream()` for real-time updates
  - `PaginationProvider.mergeStreams()` for combining multiple streams
  - Single provider parameter replaces separate `dataProvider` and `streamProvider`
  - Pattern matching with switch expressions for type safety
  - Legacy typedefs maintained for backward compatibility

#### Merged Streams Support 🔀

- **MergedStreamPaginationProvider**: Merge multiple data streams
  - Combines streams into a single unified stream
  - Emits data whenever any source stream emits
  - Perfect for aggregating data from multiple sources
  - Automatic stream lifecycle management
- **Example Implementation**: Merged streams demo screen
  - Real-time updates from 3 different streams
  - Visual indicators for each stream source

#### Stream Examples 📡

- **Single Stream Example**: Real-time product list with live price updates
  - Products update every 3 seconds
  - Visual indicators for streaming data
- **Multi Stream Example**: Multiple streams with different update rates
  - Three stream sources with different intervals (3s, 4s, 5s)
  - Tab navigation between streams
  - Dynamic stream switching
  - Color-coded badges

#### Advanced Error Handling 🛡️

- **CustomErrorBuilder**: 6 pre-built error widget styles
  - `CustomErrorBuilder.material()` - Full-screen Material Design error
  - `CustomErrorBuilder.compact()` - Inline compact error
  - `CustomErrorBuilder.card()` - Elevated card-style error
  - `CustomErrorBuilder.minimal()` - Simple text-based error
  - `CustomErrorBuilder.snackbar()` - Bottom notification error
  - `CustomErrorBuilder.custom()` - Fully custom error builder
- **Error State Separation**: Different UI for first page vs load more errors
  - `firstPageErrorBuilder` - Full-screen error for initial load
  - `loadMoreErrorBuilder` - Compact error for pagination
- **Error Recovery Strategies**: 5 recovery patterns demonstrated
  - Cached data fallback
  - Partial data display
  - Alternative source switching
  - User-initiated recovery
  - Graceful degradation

#### Error Examples (7 New Screens) 🐛

- **Basic Error Handling** - Simple retry with progressive counter
- **Network Errors** - Different error types (timeout, 404, 500, 401)
- **Retry Patterns** - Manual, auto, exponential backoff, limited retries
- **Custom Error Widgets** - All 6 error widget styles demonstrated
- **Error Recovery** - 4 recovery strategies (cached, partial, alternative, user)
- **Graceful Degradation** - 3 degradation strategies (offline, placeholders, limited)
- **Load More Errors** - 3 load-more patterns (compact, inline, silent)

#### Error Images Infrastructure 🎨

- **ErrorImages Helper Class**: Easy image integration with fallback icons
  - 12 pre-configured image methods (general, network, 404, 500, timeout, etc.)
  - Automatic fallback to icons if images fail to load
  - Customizable width, height, and fallback colors
- **Documentation**: `docs/ERROR_IMAGES_SETUP.md`
  - Free illustration sources guide (unDraw, Storyset, DrawKit)
  - Download helper script
  - Image specifications and optimization
  - Troubleshooting guide

### Changed

#### API Improvements

- **SmartPagination**: Updated to unified `PaginationProvider<T>` parameter
  - Removed separate `dataProvider` and `streamProvider`
  - Single `provider` parameter accepts both Future and Stream
  - Added `retryConfig` parameter support
  - Cleaner, more intuitive API
- **Convenience Widgets**: Updated to unified provider pattern
  - `SmartPaginatedListView` uses `provider` parameter
  - `SmartPaginatedGridView` uses `provider` parameter
  - Added error builder parameters (`firstPageErrorBuilder`, `loadMoreErrorBuilder`)

#### Documentation Updates

- Updated README.md for unified provider pattern
- Added comprehensive error handling documentation
- Updated all code examples to use `PaginationProvider`
- Added error handling guide: `docs/ERROR_HANDLING.md`

### Removed

#### DualPagination (Grouped Pagination) - Complete Removal

- Removed all DualPagination functionality to simplify library focus
- Deleted `lib/dual_pagination/` directory
- Removed DualPagination tests and examples
- Updated documentation to remove DualPagination references

### Migration Guide

**From v0.0.4 (dataProvider/streamProvider) to v0.0.5 (unified provider):**

```dart
// Before (v0.0.4)
SmartPagination<Product>(
  dataProvider: (request) => apiService.fetchProducts(request),
  ...
)

// After (v0.0.5)
SmartPagination<Product>(
  provider: PaginationProvider.future(
    (request) => apiService.fetchProducts(request),
  ),
  ...
)
```

**For Stream-based pagination:**

```dart
// Before
SmartPagination<Product>(
  streamProvider: (request) => apiService.productsStream(request),
  ...
)

// After
SmartPagination<Product>(
  provider: PaginationProvider.stream(
    (request) => apiService.productsStream(request),
  ),
  ...
)
```

### Benefits

- **Type Safety**: Sealed classes ensure compile-time checking
- **Cleaner API**: Single provider instead of two parameters
- **Better Intent**: Clear distinction between Future and Stream
- **Production-Ready**: Advanced error handling out of the box
- **Well Tested**: 60+ unit tests

---

## [0.0.4] - 2025-10-31

### Added

#### Convenience Widgets 🛠️

- **SmartPaginatedListView**: Simplified ListView pagination widget
  - Cleaner API with direct `childBuilder`
  - Optional `separatorBuilder`, `emptyBuilder`, `errorBuilder`
  - Built-in retry configuration support
  - 40-60% less boilerplate code
- **SmartPaginatedGridView**: Simplified GridView pagination widget
  - Dedicated `gridDelegate` configuration
  - Direct `childBuilder` for grid items
  - Full pagination features with less code
- **DualPaginatedListView**: Simplified grouped ListView pagination
  - Easy group-based pagination
  - Simplified `groupKeyGenerator`
  - Direct `groupHeaderBuilder` and `childBuilder`

#### Example App 🎨

- **Complete Example Application** with 5 demonstration screens:
  1. Basic ListView - Simple paginated product list
  2. GridView - Product grid with pagination
  3. Retry Demo - Automatic retry on errors
  4. Filter & Search - Real-time filtering with search
  5. Grouped Messages - Messages grouped by date
- **Mock API Service**: Network delay simulation, error simulation
- **Example Models**: Product and Message with JSON serialization

### Enhanced

- **Developer Experience**: 40-60% reduction in boilerplate code
- **Example-Driven Learning**: Complete runnable examples
- **Better API Design**: More intuitive method names

---

## [0.0.3] - 2025-10-31

### Added

#### Comprehensive Test Suite 🧪

- **60+ Unit Tests** covering all core functionality
- **Data Model Tests**: PaginationMeta (12 tests), PaginationRequest (8 tests)
- **Error Handling Tests**: RetryConfig, RetryHandler, PaginationException
- **Cubit Tests**: SmartPaginationCubit (14 tests), DualPaginationCubit (12 tests)
- **Test Infrastructure**: Test models, factories, proper organization

### Testing Coverage

- ✅ PaginationMeta (100%)
- ✅ PaginationRequest (100%)
- ✅ RetryConfig (100%)
- ✅ RetryHandler (95%)
- ✅ PaginationException classes (100%)
- ✅ SmartPaginationCubit (85%)
- ✅ DualPaginationCubit (80%)

### Dependencies

- Added `bloc_test: ^9.1.5` for BLoC testing
- Added `mocktail: ^1.0.1` for mocking

---

## [0.0.2] - 2025-10-31

### Added

#### Dual Pagination (Grouped Pagination)

- **DualPaginationCubit<Key, T>**: Managing grouped state
- **Flexible Grouping**: Custom `KeyGenerator` function
- **Group Headers**: Customizable group header builder
- **Real-time Updates**: Stream support for grouped data

#### Retry Mechanism & Error Handling

- **RetryConfig**: Configurable retry behavior with exponential backoff
  - Max attempts (default: 3)
  - Initial delay (default: 1s)
  - Max delay (default: 10s)
  - Custom retry conditions
- **Timeout Handling**: Built-in timeout support (default: 30s)
- **Custom Exceptions**:
  - `PaginationTimeoutException`
  - `PaginationNetworkException`
  - `PaginationParseException`
  - `PaginationRetryExhaustedException`
- **RetryHandler Utility**: Automatic retry execution with logging

### Enhanced

- Improved error logging with retry attempt information
- Exponential backoff prevents API rate limiting

---

## [0.0.1] - 2025-10-31

### Added

#### Core Features

- Initial release of Smart Pagination library
- **SmartPagination** widget with multiple layout support:
  - ListView with separators
  - GridView with configurable delegates
  - PageView for swipeable content
  - StaggeredGridView for masonry layouts
  - Column/Row layouts

#### State Management

- **SmartPaginationCubit**: BLoC pattern implementation
- Three state types: `Initial`, `Loaded`, `Error`
- **PaginationMeta**: Metadata tracking
- **PaginationRequest**: Pagination configuration

#### Advanced Features

- Cursor-based and offset-based pagination
- Stream provider for real-time updates
- Memory management with `maxPagesInMemory`
- Filter, refresh, and order listeners
- Custom list builder for transformations
- `beforeBuild` hook for pre-render transformations

#### Controller

- **SmartPaginationController**: Scroll capabilities
- Programmatic scrolling: `scrollToIndex()`, `scrollToItem()`

#### UI Components

- `BottomLoader` - pagination loading indicator
- `InitialLoader` - initial loading state
- `EmptyDisplay` - empty state widget
- `ErrorDisplay` - error state widget

#### Developer Experience

- Type-safe generic support
- Custom error handling with callbacks
- Comprehensive in-code documentation
- Multiple named constructors

### Dependencies

- `flutter_bloc: ^9.1.1` - State management
- `flutter_staggered_grid_view: ^0.7.0` - Staggered layouts
- `logger: ^2.6.2` - Logging support
- `provider: ^6.1.5+1` - Listener management
- `scrollview_observer: ^1.26.2` - Scroll observation

### Documentation

- Comprehensive README.md with examples
- API reference and best practices
- Contributing guidelines
- Library-level documentation

---

## Future Releases

### Planned Features

- [ ] Widget and integration tests
- [ ] Code coverage reporting
- [ ] Pull-to-refresh built-in widget support
- [ ] Performance benchmarks
- [ ] Video tutorials
- [ ] CI/CD pipeline
- [ ] pub.dev publication

---

For more information, visit the [GitHub repository](https://github.com/GeniusSystems24/smart_pagination).
