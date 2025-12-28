# Claude Development Guide for Smart Pagination

This document provides development standards and guidelines for Claude AI agents working on the Smart Pagination library.

## Project Overview

**Smart Pagination** is a powerful Flutter pagination library with built-in BLoC state management, multiple view types, advanced error handling, and smart search capabilities.

### Key Technologies
- **Flutter** (Dart) - Main framework
- **flutter_bloc** - State management (BLoC/Cubit pattern)
- **provider** - Dependency injection
- **flutter_staggered_grid_view** - Staggered grid layouts

## Project Structure

```
lib/
├── pagination.dart              # Main entry point (exports all public APIs)
├── pagination/                  # Core pagination functionality
│   ├── cubit/                   # SmartPaginationCubit & states
│   ├── models/                  # PaginationRequest, PaginationResponse
│   ├── widgets/                 # SmartPagination widgets
│   └── utils/                   # Helpers, builders, extensions
├── smart_search/                # Smart Search feature
│   ├── controller/              # SmartSearchController
│   ├── widgets/                 # SmartSearchBox, SmartSearchDropdown, SmartSearchOverlay
│   ├── models/                  # SmartSearchConfig, SmartSearchOverlayConfig
│   └── theme/                   # SmartSearchTheme (ThemeExtension)
└── error_handling/              # Error handling widgets

example/lib/
├── main.dart                    # Example app entry point
├── screens/
│   ├── home_screen.dart         # Main navigation screen
│   ├── smart_pagination/        # Pagination examples
│   └── errors/                  # Error handling examples
├── models/                      # Example data models
├── services/                    # Mock API services
└── widgets/                     # Reusable example widgets
```

## Code Style Guidelines

### 1. File Organization
- Use `part of` directive for files within the same feature
- Main export file is `lib/pagination.dart`
- Each feature has its own directory with subdirectories for different concerns

### 2. Widget Patterns

#### Constructor Naming
Use named constructors for different initialization patterns:
```dart
// With provider (creates internal cubit)
SmartSearchDropdown<T>.withProvider({...})

// With existing cubit
SmartSearchDropdown<T>.withCubit({...})
```

#### Required Parameters
Always use named parameters with `required` keyword for essential parameters:
```dart
const SmartSearchDropdown({
  required this.request,
  required this.provider,
  required this.itemBuilder,
  // Optional parameters with defaults
  this.showSelected = false,
  this.validator,
});
```

### 3. Documentation Standards

#### Class Documentation
```dart
/// A widget that combines search input with dropdown results.
///
/// This widget shows how to:
/// - Use auto-positioning overlay
/// - Configure search behavior
/// - Handle item selection
///
/// Example:
/// ```dart
/// SmartSearchDropdown<Product>.withProvider(
///   request: PaginationRequest(page: 1),
///   // ...
/// )
/// ```
class SmartSearchDropdown<T> extends StatefulWidget {
```

#### Parameter Documentation
```dart
/// Whether to show the selected item instead of search box.
///
/// When true, after selecting an item, the search box is replaced
/// with a widget showing the selected item.
final bool showSelected;
```

### 4. State Management

#### Using ChangeNotifier
```dart
class SmartSearchController<T> extends ChangeNotifier {
  void _updateState() {
    // Always call notifyListeners after state changes
    notifyListeners();
  }
}
```

#### Using BLoC/Cubit
```dart
class SmartPaginationCubit<T> extends Cubit<SmartPaginationState<T>> {
  void loadItems() {
    emit(SmartPaginationLoading());
    // ...
    emit(SmartPaginationLoaded(items: items));
  }
}
```

### 5. Generic Types
Always use meaningful generic type names:
```dart
class SmartSearchDropdown<T> extends StatefulWidget {
  // T represents the item type
  final Widget Function(BuildContext context, T item) itemBuilder;
}
```

## Version Numbering

Follow Semantic Versioning (SemVer):
- **MAJOR.MINOR.PATCH** (e.g., 2.3.1)
- **MAJOR**: Breaking API changes
- **MINOR**: New features (backward compatible)
- **PATCH**: Bug fixes

## Adding New Features

### Step-by-Step Process

1. **Plan the feature**
   - Define new parameters/methods
   - Consider backward compatibility
   - Plan documentation

2. **Implement in order**
   - Controller/Model changes first
   - Widget implementation
   - Pass parameters through widget hierarchy

3. **Update documentation**
   - Add to CHANGELOG.md
   - Update README.md
   - Update version in pubspec.yaml

4. **Add examples**
   - Create example screen in `example/lib/screens/`
   - Add to `home_screen.dart` categories
   - Include comprehensive usage demos

### Example: Adding a New Parameter

1. **Add to widget constructor:**
```dart
const SmartSearchDropdown({
  // existing params...
  this.newParameter,
});

final String? newParameter;
```

2. **Pass through hierarchy:**
```dart
// In SmartSearchDropdown.build()
return SmartSearchOverlay<T>(
  // existing params...
  newParameter: widget.newParameter,
);
```

3. **Use in child widget:**
```dart
// In SmartSearchBox or SmartSearchOverlay
if (widget.newParameter != null) {
  // Apply the parameter
}
```

## Common Patterns

### 1. Conditional Widget Rendering
```dart
Widget build(BuildContext context) {
  return validator != null
      ? TextFormField(
          validator: validator,
          // ... other props
        )
      : TextField(
          // ... other props
        );
}
```

### 2. Controller Pattern
```dart
void _initializeController() {
  _controller = SmartSearchController<T>(
    cubit: _cubit,
    config: widget.searchConfig,
    initialValue: widget.initialValue,
  );
}

@override
void dispose() {
  if (_ownsController) {
    _controller.dispose();
  }
  super.dispose();
}
```

### 3. Theme Extension Pattern
```dart
// Access theme
final theme = SmartSearchTheme.of(context);

// Use with fallback
final color = theme.primaryColor ?? Theme.of(context).primaryColor;
```

### 4. Overlay Positioning
```dart
final positionData = OverlayPositioner.calculatePosition(
  targetRect: searchBoxRect,
  overlaySize: Size(maxWidth, maxHeight),
  screenSize: MediaQuery.of(context).size,
  config: overlayConfig,
);
```

## Testing Guidelines

### Unit Tests
- Test cubit state changes
- Test controller methods
- Test utility functions

### Widget Tests
- Test widget rendering
- Test user interactions
- Test state updates

### Example Test Pattern
```dart
testWidgets('shows loading indicator', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: SmartPagination<Product>.withProvider(
        // ... setup
      ),
    ),
  );

  expect(find.byType(CircularProgressIndicator), findsOneWidget);
});
```

## Changelog Format

Follow Keep a Changelog format:

```markdown
## [2.3.1] - 2025-12-28

### Added
- Feature description with emoji for visual identification

### Fixed
- Bug fix description

### Changed
- Change description
```

## Commit Message Format

Use conventional commits:
```
feat: add form validation support to SmartSearchDropdown

- Add validator parameter for form validation
- Add inputFormatters for text formatting
- Add textInputAction for keyboard action
```

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation
- `refactor`: Code refactoring
- `test`: Tests
- `chore`: Maintenance

## Key Files for Reference

When implementing new features, reference these files:

1. **Widget structure**: `lib/smart_search/widgets/smart_search_dropdown.dart`
2. **Controller pattern**: `lib/smart_search/controller/smart_search_controller.dart`
3. **Theme extension**: `lib/smart_search/theme/smart_search_theme.dart`
4. **State management**: `lib/pagination/cubit/smart_pagination_cubit.dart`
5. **Example patterns**: `example/lib/screens/smart_pagination/search_dropdown_screen.dart`

## Important Notes

1. **Backward Compatibility**: Never break existing APIs without major version bump
2. **Default Values**: Always provide sensible defaults for optional parameters
3. **Documentation**: Every public API must have dartdoc comments
4. **Examples**: Every feature should have a working example
5. **Type Safety**: Use generics consistently throughout the codebase
6. **Null Safety**: Follow Dart null safety best practices

## Quick Reference

### Adding a new parameter to SmartSearchDropdown:

1. Add to `SmartSearchDropdown` constructor and field
2. Add to `SmartSearchOverlay` constructor and field (if needed)
3. Add to `SmartSearchBox` constructor and field (if needed)
4. Update `_initializeController()` if controller needs it
5. Update `build()` to pass parameter down the widget tree
6. Add documentation comments
7. Update CHANGELOG.md
8. Update README.md
9. Add example usage
10. Update version in pubspec.yaml
