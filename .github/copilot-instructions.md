# GitHub Copilot Instructions for Smart Pagination

This repository contains the `smart_pagination` Flutter package and its example application.

## 🏗 Project Architecture

- **Core Pattern**: BLoC (Business Logic Component) using `flutter_bloc`.
- **State Management**: `SmartPaginationCubit` manages the pagination state (`SmartPaginationState`).
- **Entry Point**: `SmartPagination<T>` is the main widget, offering factory constructors for various layouts (`listView`, `gridView`, `pageView`, `staggeredGridView`).
- **Data Abstraction**: `PaginationProvider<T>` abstracts data fetching, supporting both `Future` (REST) and `Stream` (Real-time) sources.

## 📂 Code Organization

- **Library Structure**: The main library file is `lib/pagination.dart`. It exports all public API components.
- **Part Directives**: The project extensively uses `part` and `part of` directives.
  - **Rule**: When creating new files in `lib/`, ensure they are properly linked via `part` in `lib/pagination.dart` (or relevant parent) and use `part of` in the new file.
- **Core vs Implementation**:
  - `lib/core/`: Contains base interfaces, shared widgets, and error handling logic.
  - `lib/smart_pagination/`: Contains the concrete implementation of the smart pagination logic (Cubit, Widgets, Controller).
- **Example App**: Located in `example/`. It is a complete Flutter app demonstrating all features.

## 🧩 Key Components & Patterns

### 1. Widget Usage
Prefer using the factory constructors of `SmartPagination` for type-safe and convenient instantiation:

```dart
SmartPagination.listView<MyModel>(
  request: PaginationRequest(page: 1, pageSize: 20),
  provider: PaginationProvider.future(fetchData),
  itemBuilder: (context, items, index) => MyItemWidget(items[index]),
  // ... options
)
```

### 2. Data Fetching
Use `PaginationProvider` to define data sources:
- **Future**: `PaginationProvider.future((request) => ...)`
- **Stream**: `PaginationProvider.stream((request) => ...)`
- **Merged**: `PaginationProvider.mergeStreams((request) => ...)`

### 3. Request Model
`PaginationRequest` is immutable and handles both offset and cursor pagination:
- `page`: 1-based index.
- `pageSize`: Items per page.
- `cursor`: For cursor-based APIs.
- `filters`: Map for server-side filtering.

### 4. Error Handling
- **Configuration**: Use `RetryConfig` to define retry behavior (attempts, delays, exponential backoff).
- **UI**: Use `CustomErrorBuilder` factory methods (`.material`, `.compact`, `.card`, etc.) within `firstPageErrorBuilder` and `loadMoreErrorBuilder`.
- **Exceptions**: Throw `PaginationException` subclasses (`PaginationNetworkException`, etc.) for precise error handling.

### 5. State Handling
The `SmartPaginationCubit` emits `SmartPaginationState<T>`:
- `SmartPaginationInitial`: Before first fetch.
- `SmartPaginationLoading`: Loading first page.
- `SmartPaginationLoaded`: Data available. Check `isLoadingMore` and `loadMoreError` for pagination status.
- `SmartPaginationError`: First page load failed.
- `SmartPaginationEmpty`: No data found.

## 🛠 Development Workflow

- **Running Example**:
  ```bash
  cd example
  flutter run
  ```
- **Testing**:
  - Run tests from the root: `flutter test`
- **Linting**:
  - Follow `analysis_options.yaml` rules.
- **Documentation**:
  - Update `CHANGELOG.md` and `README.md` when making any modifications.
- **Examples**:
  - Update the example app in `example/` if the changes affect public API or add new features.

## ⚠️ Important Conventions

- **Generics**: The library is generic `<T>`. Always specify the type parameter when using `SmartPagination` or `SmartPaginationCubit`.
- **Immutability**: `PaginationRequest` and `SmartPaginationState` are immutable. Use `copyWith` for modifications.
- **Memory Management**: `SmartPaginationCubit` has a `maxPagesInMemory` property to control memory usage for large lists.
