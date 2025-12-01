import 'package:smart_pagination/pagination.dart';
import 'package:flutter/material.dart';
import '../../models/product.dart';

/// Custom exception types for network errors
class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);

  @override
  String toString() => message;
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);

  @override
  String toString() => message;
}

class ServerException implements Exception {
  final int statusCode;
  final String message;
  ServerException(this.statusCode, this.message);

  @override
  String toString() => '$message (Status: $statusCode)';
}

/// Network errors example
///
/// Demonstrates:
/// - Different network error types
/// - Custom error messages per error type
/// - Appropriate UI for each error
class NetworkErrorsExample extends StatefulWidget {
  const NetworkErrorsExample({super.key});

  @override
  State<NetworkErrorsExample> createState() => _NetworkErrorsExampleState();
}

class _NetworkErrorsExampleState extends State<NetworkErrorsExample> {
  String _selectedErrorType = 'network';

  Future<List<Product>> _fetchProducts(PaginationRequest request) async {
    await Future.delayed(const Duration(milliseconds: 800));

    // Throw different error types based on selection
    switch (_selectedErrorType) {
      case 'network':
        throw NetworkException('Unable to connect to server. Please check your internet connection.');
      case 'timeout':
        await Future.delayed(const Duration(milliseconds: 500));
        throw TimeoutException('Request timed out. The server took too long to respond.');
      case 'server':
        throw ServerException(500, 'Internal server error. Our team has been notified.');
      case 'notfound':
        throw ServerException(404, 'The requested resource was not found.');
      case 'unauthorized':
        throw ServerException(401, 'Unauthorized. Please log in again.');
      default:
        throw Exception('Unknown error occurred');
    }
  }

  Widget _buildErrorWidget(
    BuildContext context,
    Exception error,
    VoidCallback retry,
  ) {
    IconData icon;
    Color color;
    String title;
    String message;
    String actionText;

    // Customize UI based on error type
    if (error is NetworkException) {
      icon = Icons.wifi_off;
      color = Colors.orange;
      title = 'No Internet Connection';
      message = error.message;
      actionText = 'Retry';
    } else if (error is TimeoutException) {
      icon = Icons.access_time;
      color = Colors.amber;
      title = 'Request Timed Out';
      message = error.message;
      actionText = 'Try Again';
    } else if (error is ServerException) {
      if (error.statusCode == 401) {
        icon = Icons.lock;
        color = Colors.red;
        title = 'Authentication Required';
        message = error.message;
        actionText = 'Log In';
      } else if (error.statusCode == 404) {
        icon = Icons.search_off;
        color = Colors.grey;
        title = 'Not Found';
        message = error.message;
        actionText = 'Go Back';
      } else {
        icon = Icons.error_outline;
        color = Colors.red;
        title = 'Server Error';
        message = error.message;
        actionText = 'Retry';
      }
    } else {
      icon = Icons.error;
      color = Colors.red;
      title = 'Error';
      message = error.toString();
      actionText = 'Retry';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 64,
                color: color,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: retry,
              icon: const Icon(Icons.refresh),
              label: Text(actionText),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Network Errors'),
      ),
      body: Column(
        children: [
          // Error type selector
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Error Type:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildErrorTypeChip('network', 'No Connection', Icons.wifi_off),
                    _buildErrorTypeChip('timeout', 'Timeout', Icons.access_time),
                    _buildErrorTypeChip('server', '500 Error', Icons.error_outline),
                    _buildErrorTypeChip('notfound', '404 Error', Icons.search_off),
                    _buildErrorTypeChip('unauthorized', '401 Error', Icons.lock),
                  ],
                ),
              ],
            ),
          ),

          // Paginated list
          Expanded(
            child: SmartPagination<Product>.listViewWithProvider(
              key: ValueKey('network_error_$_selectedErrorType'),
              request: PaginationRequest(page: 1, pageSize: 20),
              provider: PaginationProvider.future(_fetchProducts),
              itemBuilder: (context, products, index) {
                final product = products[index];
                return ListTile(
                  title: Text(product.name),
                  subtitle: Text('\$${product.price.toStringAsFixed(2)}'),
                );
              },
              firstPageErrorBuilder: _buildErrorWidget,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorTypeChip(String type, String label, IconData icon) {
    final isSelected = _selectedErrorType == type;
    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedErrorType = type;
          });
        }
      },
    );
  }
}
