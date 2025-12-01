# Error Handling Guide

This guide covers the comprehensive error handling features in the Smart Pagination package.

## Table of Contents

- [Overview](#overview)
- [Error Builder Types](#error-builder-types)
- [CustomErrorBuilder Widget](#customerrorbuilder-widget)
- [Usage Examples](#usage-examples)
- [Best Practices](#best-practices)

## Overview

The Smart Pagination package provides robust error handling with multiple customization options:

1. **First Page Errors** - Errors that occur when initially loading data
2. **Load More Errors** - Errors that occur when loading additional pages
3. **Custom Error Widgets** - Pre-built and customizable error UI components
4. **Retry Functionality** - Built-in retry callbacks for all error states

## Error Builder Types

### firstPageErrorBuilder

Used when an error occurs during the initial data load. Provides full screen space for displaying error information.

```dart
SmartPagination.listViewWithProvider<Product>(
  request: PaginationRequest(page: 1, pageSize: 20),
  provider: PaginationProvider.future(fetchProducts),
  itemBuilder: (context, product, index) => ProductCard(product: product),
  firstPageErrorBuilder: (context, error, retry) {
    return CustomErrorBuilder.material(
      context: context,
      error: error,
      onRetry: retry,
      title: 'Failed to Load Products',
      message: 'Please check your internet connection',
    );
  },
)
```

### loadMoreErrorBuilder

Used when an error occurs while loading additional pages. Best suited for compact, inline error displays.

```dart
SmartPagination.listViewWithProvider<Product>(
  request: PaginationRequest(page: 1, pageSize: 20),
  provider: PaginationProvider.future(fetchProducts),
  itemBuilder: (context, product, index) => ProductCard(product: product),
  loadMoreErrorBuilder: (context, error, retry) {
    return CustomErrorBuilder.compact(
      context: context,
      error: error,
      onRetry: retry,
      message: 'Failed to load more items',
    );
  },
)
```

### errorBuilder (Legacy)

Backwards-compatible error builder. Now automatically maps to `firstPageErrorBuilder` with retry support.

```dart
SmartPagination.listViewWithProvider<Product>(
  request: PaginationRequest(page: 1, pageSize: 20),
  provider: PaginationProvider.future(fetchProducts),
  itemBuilder: (context, product, index) => ProductCard(product: product),
  errorBuilder: (context, error, retry) {
    // This now works with retry callback
    return ErrorDisplay(
      exception: error,
      onRetry: retry,
    );
  },
)
```

## CustomErrorBuilder Widget

The package includes a `CustomErrorBuilder` class with pre-built error widget styles.

### Material Design Style

Full-featured error display with icon, title, message, and retry button.

```dart
CustomErrorBuilder.material(
  context: context,
  error: error,
  onRetry: retry,
  title: 'Failed to Load Data',
  message: 'Please check your internet connection and try again.',
  icon: Icons.error_outline,
  iconColor: Colors.red,
  retryButtonText: 'Try Again',
)
```

**Best for:** First page errors with ample screen space

### Compact Style

Inline error display suitable for limited space.

```dart
CustomErrorBuilder.compact(
  context: context,
  error: error,
  onRetry: retry,
  message: 'Failed to load more items',
  backgroundColor: Colors.red[50],
  textColor: Colors.red[700],
)
```

**Best for:** Load more errors at the bottom of lists

### Card Style

Error displayed in a Material card with elevation and rounded corners.

```dart
CustomErrorBuilder.card(
  context: context,
  error: error,
  onRetry: retry,
  title: 'Products Unavailable',
  message: 'We could not load the products at this time.',
  elevation: 4,
)
```

**Best for:** Grid views or when you want a distinct error card

### Minimal Style

Minimalist error display with just message and retry icon.

```dart
CustomErrorBuilder.minimal(
  context: context,
  error: error,
  onRetry: retry,
  message: 'Error occurred',
)
```

**Best for:** Very limited space scenarios

### Snackbar Style

Bottom-aligned error that doesn't block content.

```dart
CustomErrorBuilder.snackbar(
  context: context,
  error: error,
  onRetry: retry,
  message: 'Failed to load',
  backgroundColor: Colors.grey[900],
)
```

**Best for:** Non-intrusive error messages

### Custom Style

Complete control over error widget design.

```dart
CustomErrorBuilder.custom(
  context: context,
  error: error,
  onRetry: retry,
  builder: (context, error, retry) {
    return YourCustomErrorWidget(
      error: error,
      onRetry: retry,
    );
  },
)
```

**Best for:** Specific branding or unique layouts

## Usage Examples

### Basic Error Handling

```dart
SmartPagination.listViewWithProvider<Product>(
  request: PaginationRequest(page: 1, pageSize: 20),
  provider: PaginationProvider.future(
    (request) => apiService.fetchProducts(request),
  ),
  itemBuilder: (context, product, index) {
    return ListTile(
      title: Text(product.name),
      subtitle: Text('\$${product.price}'),
    );
  },
  firstPageErrorBuilder: (context, error, retry) {
    return CustomErrorBuilder.material(
      context: context,
      error: error,
      onRetry: retry,
    );
  },
)
```

### Different Errors for First Page vs Load More

```dart
SmartPagination.listViewWithProvider<Product>(
  request: PaginationRequest(page: 1, pageSize: 20),
  provider: PaginationProvider.future(fetchProducts),
  itemBuilder: (context, product, index) => ProductCard(product: product),

  // Full-screen error for first page
  firstPageErrorBuilder: (context, error, retry) {
    return CustomErrorBuilder.material(
      context: context,
      error: error,
      onRetry: retry,
      title: 'Failed to Load Products',
      message: 'Please check your internet connection',
    );
  },

  // Compact error for load more
  loadMoreErrorBuilder: (context, error, retry) {
    return CustomErrorBuilder.compact(
      context: context,
      error: error,
      onRetry: retry,
    );
  },
)
```

### Grid View with Card Error

```dart
SmartPagination.gridViewWithProvider<Product>(
  request: PaginationRequest(page: 1, pageSize: 20),
  provider: PaginationProvider.future(fetchProducts),
  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2,
    childAspectRatio: 0.75,
  ),
  itemBuilder: (context, product, index) => ProductCard(product: product),

  firstPageErrorBuilder: (context, error, retry) {
    return CustomErrorBuilder.card(
      context: context,
      error: error,
      onRetry: retry,
      title: 'Products Unavailable',
      message: 'We could not load the products at this time.',
    );
  },
)
```

### Completely Custom Error Design

```dart
SmartPagination.listViewWithProvider<Product>(
  request: PaginationRequest(page: 1, pageSize: 20),
  provider: PaginationProvider.future(fetchProducts),
  itemBuilder: (context, product, index) => ProductCard(product: product),

  firstPageErrorBuilder: (context, error, retry) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Your custom icon/image
          Image.asset('assets/error_illustration.png', height: 200),
          const SizedBox(height: 24),

          // Custom title
          Text(
            'Oops! Something went wrong',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),

          // Custom message
          Text(
            'We encountered an error while loading your data.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),

          // Custom retry button
          ElevatedButton.icon(
            onPressed: retry,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 16,
              ),
            ),
          ),
        ],
      ),
    );
  },
)
```

## Best Practices

### 1. Use Appropriate Error Styles

- **First Page Errors**: Use `material` or `card` style for full details
- **Load More Errors**: Use `compact` or `minimal` style to save space
- **Grid Views**: Use `card` style for consistent design
- **Limited Space**: Use `minimal` or `snackbar` style

### 2. Provide Clear Error Messages

```dart
// Good - Clear and actionable
CustomErrorBuilder.material(
  context: context,
  error: error,
  onRetry: retry,
  title: 'Failed to Load Products',
  message: 'Please check your internet connection and try again.',
)

// Less ideal - Vague message
CustomErrorBuilder.material(
  context: context,
  error: error,
  onRetry: retry,
  title: 'Error',
  message: error.toString(),
)
```

### 3. Always Provide Retry Functionality

Users should always have the ability to retry failed operations:

```dart
firstPageErrorBuilder: (context, error, retry) {
  return CustomErrorBuilder.material(
    context: context,
    error: error,
    onRetry: retry, // Always pass the retry callback
  );
},
```

### 4. Handle Different Error Types

Consider providing different messages or UI for different error types:

```dart
firstPageErrorBuilder: (context, error, retry) {
  String title;
  String message;

  if (error is NetworkException) {
    title = 'Connection Error';
    message = 'Please check your internet connection';
  } else if (error is TimeoutException) {
    title = 'Request Timeout';
    message = 'The request took too long to complete';
  } else {
    title = 'Error Occurred';
    message = 'Something went wrong';
  }

  return CustomErrorBuilder.material(
    context: context,
    error: error,
    onRetry: retry,
    title: title,
    message: message,
  );
},
```

### 5. Consistent Design

Maintain consistent error styling throughout your app:

```dart
// Create a reusable error builder
Widget buildStandardError(
  BuildContext context,
  Exception error,
  VoidCallback retry, {
  String? title,
  String? message,
}) {
  return CustomErrorBuilder.material(
    context: context,
    error: error,
    onRetry: retry,
    title: title ?? 'Failed to Load Data',
    message: message ?? 'Please try again',
    iconColor: Theme.of(context).colorScheme.error,
  );
}

// Use it consistently
SmartPagination.listViewWithProvider<Product>(
  firstPageErrorBuilder: (context, error, retry) {
    return buildStandardError(context, error, retry);
  },
)
```

### 6. Test Error States

Always test your error handling:

```dart
// Use a test provider that throws errors
provider: PaginationProvider.future(
  (request) async {
    throw Exception('Test error');
  },
),
```

## Migration from Legacy Error Handling

If you're using the old `onError` parameter without retry support:

### Before (Legacy)
```dart
SmartPagination.listViewWithProvider<Product>(
  onError: (exception) => ErrorDisplay(exception: exception),
  // ...
)
```

### After (Recommended)
```dart
SmartPagination.listViewWithProvider<Product>(
  firstPageErrorBuilder: (context, error, retry) {
    return CustomErrorBuilder.material(
      context: context,
      error: error,
      onRetry: retry,
    );
  },
  loadMoreErrorBuilder: (context, error, retry) {
    return CustomErrorBuilder.compact(
      context: context,
      error: error,
      onRetry: retry,
    );
  },
  // ...
)
```

## Summary

The Smart Pagination package provides comprehensive error handling with:

- ✅ Separate builders for first page and load more errors
- ✅ Pre-built error widget styles (material, compact, card, minimal, snackbar)
- ✅ Built-in retry functionality
- ✅ Full customization support
- ✅ Consistent API across all pagination widgets

Choose the error style that best fits your use case and always provide clear, actionable error messages with retry options.
