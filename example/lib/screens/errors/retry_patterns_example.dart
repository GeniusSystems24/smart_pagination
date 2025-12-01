import 'package:custom_pagination/pagination.dart';
import 'package:flutter/material.dart';
import '../../models/product.dart';

/// Retry patterns example
///
/// Demonstrates:
/// - Manual retry
/// - Auto-retry with countdown
/// - Exponential backoff retry
/// - Limited retry attempts
class RetryPatternsExample extends StatefulWidget {
  const RetryPatternsExample({super.key});

  @override
  State<RetryPatternsExample> createState() => _RetryPatternsExampleState();
}

class _RetryPatternsExampleState extends State<RetryPatternsExample>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Retry Patterns'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Manual Retry'),
            Tab(text: 'Auto Retry'),
            Tab(text: 'Exponential Backoff'),
            Tab(text: 'Limited Attempts'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _ManualRetryTab(),
          _AutoRetryTab(),
          _ExponentialBackoffTab(),
          _LimitedAttemptsTab(),
        ],
      ),
    );
  }
}

// ========== Manual Retry Tab ==========
class _ManualRetryTab extends StatefulWidget {
  const _ManualRetryTab();

  @override
  State<_ManualRetryTab> createState() => _ManualRetryTabState();
}

class _ManualRetryTabState extends State<_ManualRetryTab> {
  int _attemptCount = 0;

  Future<List<Product>> _fetchProducts(PaginationRequest request) async {
    await Future.delayed(const Duration(milliseconds: 800));
    _attemptCount++;
    throw Exception('Error occurred (Attempt #$_attemptCount)');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.blue[50],
          child: Text(
            'Manual Retry Pattern\n'
            'User must explicitly click retry button.\n'
            'Total attempts: $_attemptCount',
            style: const TextStyle(fontSize: 14),
          ),
        ),
        Expanded(
          child: SmartPaginatedListView<Product>(
            key: ValueKey('manual_retry_$_attemptCount'),
            request: PaginationRequest(page: 1, pageSize: 20),
            provider: PaginationProvider.future(_fetchProducts),
            childBuilder: (context, product, index) {
              return ListTile(title: Text(product.name));
            },
            firstPageErrorBuilder: (context, error, retry) {
              return CustomErrorBuilder.material(
                context: context,
                error: error,
                onRetry: retry,
                title: 'Manual Retry Required',
                message: 'Click the button below to try again.',
                retryButtonText: 'Retry Now',
              );
            },
          ),
        ),
      ],
    );
  }
}

// ========== Auto Retry Tab ==========
class _AutoRetryTab extends StatefulWidget {
  const _AutoRetryTab();

  @override
  State<_AutoRetryTab> createState() => _AutoRetryTabState();
}

class _AutoRetryTabState extends State<_AutoRetryTab> {
  int _attemptCount = 0;
  int _countdown = 5;
  VoidCallback? _pendingRetry;

  Future<List<Product>> _fetchProducts(PaginationRequest request) async {
    await Future.delayed(const Duration(milliseconds: 800));
    _attemptCount++;

    // Succeed after 3 attempts
    if (_attemptCount >= 3) {
      return List.generate(20, (index) {
        return Product(
          id: 'product_$index',
          name: 'Product #$index (Succeeded on attempt $_attemptCount)',
          description: 'Auto-retry success!',
          price: 19.99,
          category: 'Electronics',
          imageUrl: 'https://picsum.photos/200/200?random=$index',
          createdAt: DateTime.now(),
        );
      });
    }

    throw Exception('Error occurred (Attempt #$_attemptCount). Will auto-retry...');
  }

  void _startCountdown(VoidCallback retry) {
    _pendingRetry = retry;
    _countdown = 5;

    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;

      setState(() {
        _countdown--;
      });

      if (_countdown == 0) {
        _pendingRetry?.call();
        return false;
      }

      return true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.green[50],
          child: Text(
            'Auto-Retry Pattern\n'
            'Automatically retries after countdown.\n'
            'Attempts: $_attemptCount/3 (Succeeds on 3rd attempt)',
            style: const TextStyle(fontSize: 14),
          ),
        ),
        Expanded(
          child: SmartPaginatedListView<Product>(
            key: ValueKey('auto_retry_$_attemptCount'),
            request: PaginationRequest(page: 1, pageSize: 20),
            provider: PaginationProvider.future(_fetchProducts),
            childBuilder: (context, product, index) {
              return ListTile(
                title: Text(product.name),
                subtitle: Text(product.description),
              );
            },
            firstPageErrorBuilder: (context, error, retry) {
              // Start countdown on first error
              if (_pendingRetry == null) {
                Future.microtask(() => _startCountdown(retry));
              }

              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.autorenew,
                        size: 64,
                        color: Colors.orange,
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Auto-Retrying',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        error.toString(),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 24),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 80,
                            height: 80,
                            child: CircularProgressIndicator(
                              value: _countdown / 5,
                              strokeWidth: 6,
                            ),
                          ),
                          Text(
                            '$_countdown',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Retrying in $_countdown seconds...',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _countdown = 0;
                          });
                          retry();
                        },
                        child: const Text('Retry Now'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ========== Exponential Backoff Tab ==========
class _ExponentialBackoffTab extends StatefulWidget {
  const _ExponentialBackoffTab();

  @override
  State<_ExponentialBackoffTab> createState() => _ExponentialBackoffTabState();
}

class _ExponentialBackoffTabState extends State<_ExponentialBackoffTab> {
  int _attemptCount = 0;

  Future<List<Product>> _fetchProducts(PaginationRequest request) async {
    _attemptCount++;

    // Calculate exponential backoff delay: 1s, 2s, 4s, 8s
    final delaySeconds = (1 << (_attemptCount - 1)).clamp(1, 8);
    await Future.delayed(Duration(seconds: delaySeconds));

    throw Exception(
      'Error (Attempt #$_attemptCount, waited ${delaySeconds}s)'
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.orange[50],
          child: Text(
            'Exponential Backoff Pattern\n'
            'Retry delays: 1s → 2s → 4s → 8s\n'
            'Current attempt: $_attemptCount',
            style: const TextStyle(fontSize: 14),
          ),
        ),
        Expanded(
          child: SmartPaginatedListView<Product>(
            key: ValueKey('exponential_backoff_$_attemptCount'),
            request: PaginationRequest(page: 1, pageSize: 20),
            provider: PaginationProvider.future(_fetchProducts),
            retryConfig: RetryConfig(
              maxAttempts: 4,
              // retryDelays: [
              //   const Duration(seconds: 1),
              //   const Duration(seconds: 2),
              //   const Duration(seconds: 4),
              //   const Duration(seconds: 8),
              // ],
            ),
            childBuilder: (context, product, index) {
              return ListTile(title: Text(product.name));
            },
            firstPageErrorBuilder: (context, error, retry) {
              final nextDelay = _attemptCount < 4
                  ? (1 << _attemptCount)
                  : 8;

              return CustomErrorBuilder.material(
                context: context,
                error: error,
                onRetry: retry,
                title: 'Exponential Backoff',
                message: 'Next retry will wait $nextDelay seconds\n\n$error',
              );
            },
          ),
        ),
      ],
    );
  }
}

// ========== Limited Attempts Tab ==========
class _LimitedAttemptsTab extends StatefulWidget {
  const _LimitedAttemptsTab();

  @override
  State<_LimitedAttemptsTab> createState() => _LimitedAttemptsTabState();
}

class _LimitedAttemptsTabState extends State<_LimitedAttemptsTab> {
  int _attemptCount = 0;
  static const int maxAttempts = 3;

  Future<List<Product>> _fetchProducts(PaginationRequest request) async {
    await Future.delayed(const Duration(milliseconds: 800));
    _attemptCount++;
    throw Exception('Failed to load data');
  }

  @override
  Widget build(BuildContext context) {
    final attemptsRemaining = maxAttempts - _attemptCount;
    final canRetry = attemptsRemaining > 0;

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.red[50],
          child: Text(
            'Limited Retry Pattern\n'
            'Maximum $maxAttempts attempts allowed.\n'
            'Attempts used: $_attemptCount/$maxAttempts',
            style: const TextStyle(fontSize: 14),
          ),
        ),
        Expanded(
          child: SmartPaginatedListView<Product>(
            key: ValueKey('limited_attempts_$_attemptCount'),
            request: PaginationRequest(page: 1, pageSize: 20),
            provider: PaginationProvider.future(_fetchProducts),
            childBuilder: (context, product, index) {
              return ListTile(title: Text(product.name));
            },
            firstPageErrorBuilder: (context, error, retry) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        canRetry ? Icons.error_outline : Icons.block,
                        size: 64,
                        color: canRetry ? Colors.orange : Colors.red,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        canRetry ? 'Error Occurred' : 'Max Attempts Reached',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        error.toString(),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 24),
                      if (canRetry) ...[
                        Text(
                          'Attempts remaining: $attemptsRemaining',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: retry,
                          icon: const Icon(Icons.refresh),
                          label: Text('Retry ($attemptsRemaining left)'),
                        ),
                      ] else ...[
                        const Text(
                          'You have used all retry attempts.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: () {
                            setState(() {
                              _attemptCount = 0;
                            });
                          },
                          icon: const Icon(Icons.restart_alt),
                          label: const Text('Reset Example'),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
