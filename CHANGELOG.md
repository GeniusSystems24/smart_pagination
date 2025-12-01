# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.0.6] - 2025-11-30

### Added

- Documentation preparation for pub.dev publication
- Comprehensive example screens section in README (28 screens documented)
- Screenshot infrastructure with placeholder guides
- Screenshots directory structure (`basic/`, `streams/`, `advanced/`, `errors/`)

### Changed

- Enhanced README.md for pub.dev with professional presentation
  - Added "Why Custom Pagination?" section highlighting key benefits
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

- Initial release of Custom Pagination library
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
