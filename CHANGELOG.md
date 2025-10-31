# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.0.1] - 2025-10-31

### Added

#### Core Features
- Initial release of Custom Pagination library
- `SinglePagination` widget with multiple layout support:
  - ListView with separators
  - GridView with configurable delegates
  - PageView for swipeable content
  - StaggeredGridView for masonry layouts
  - Column layout (non-scrollable)
  - Row layout (non-scrollable horizontal)

#### State Management
- `SinglePaginationCubit` implementing BLoC pattern
- Three state types: `Initial`, `Loaded`, `Error`
- `PaginationMeta` for pagination metadata tracking
- `PaginationRequest` for pagination configuration

#### Advanced Features
- Cursor-based and offset-based pagination support
- Stream provider for real-time updates
- Memory management with configurable `maxPagesInMemory`
- Filter listeners (`SinglePaginationFilterChangeListener`)
- Refresh listeners (`SinglePaginationRefreshedChangeListener`)
- Order listeners (`SinglePaginationOrderChangeListener`)
- Custom list builder for item transformation
- `beforeBuild` hook for pre-render transformations

#### Controller
- `SinglePaginationController` with scroll capabilities
- Programmatic scrolling to index: `scrollToIndex()`
- Programmatic scrolling to item: `scrollToItem()`
- Controller factory: `SinglePaginationController.of()`
- Public/private controller modes

#### UI Components
- `BottomLoader` - loading indicator for pagination
- `InitialLoader` - initial loading state widget
- `EmptyDisplay` - empty state widget
- `ErrorDisplay` - error state widget
- `EmptySeparator` - zero-size separator widget

#### Developer Experience
- Type-safe generic support for any data model
- Custom error handling with `onError` callback
- Callbacks: `onLoaded`, `onReachedEnd`, `onInsertionCallback`, `onClear`
- Custom logger integration
- Comprehensive documentation in code
- Multiple named constructors for different use cases

### Fixed
- Fixed spelling error in `ErrorDisplay`: "occured" → "occurred"
- Fixed entry point (`lib/pagination.dart`) - removed unrelated Calculator class

### Documentation
- Comprehensive README.md with:
  - Feature overview
  - Installation instructions
  - Quick start guide
  - 10+ usage examples
  - Architecture documentation
  - API reference
  - Best practices
  - Contributing guidelines
- Added library-level documentation in `lib/pagination.dart`
- Updated `pubspec.yaml` with proper package description
- Added CHANGELOG.md for version tracking

### Dependencies
- `flutter_bloc: ^9.1.1` - State management
- `flutter_staggered_grid_view: ^0.7.0` - Staggered layouts
- `logger: ^2.6.2` - Logging support
- `provider: ^6.1.5+1` - Listener management
- `scrollview_observer: ^1.26.2` - Scroll observation

### Known Limitations
- Dual pagination not yet implemented (interfaces exist)
- No built-in retry mechanism for network failures
- Limited test coverage (tests to be added in future releases)

## [Unreleased]

### Planned Features
- Dual pagination implementation with grouping support
- Comprehensive unit and integration tests
- Network retry mechanism with exponential backoff
- Pull-to-refresh indicator integration
- Performance benchmarks and optimizations
- Example app with various use cases
- Video tutorials and documentation
- CI/CD pipeline setup
- Publication to pub.dev

---

For more information about this release, visit the [GitHub repository](https://github.com/GeniusSystems24/custom_pagination).
