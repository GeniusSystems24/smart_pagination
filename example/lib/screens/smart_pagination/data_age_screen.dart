import 'package:flutter/material.dart';
import 'package:smart_pagination/pagination.dart';

import '../../models/product.dart';
import '../../services/mock_api_service.dart';

/// Example demonstrating the dataAge feature for automatic data expiration.
///
/// This screen shows how to:
/// - Configure dataAge for automatic data invalidation
/// - Check if data has expired
/// - View expiration timestamps
/// - Use cubit as a global variable with auto-refresh
///
/// Perfect for scenarios where you keep the cubit alive across screen navigations
/// but want data to automatically refresh after a certain period.
class DataAgeScreen extends StatefulWidget {
  const DataAgeScreen({super.key});

  @override
  State<DataAgeScreen> createState() => _DataAgeScreenState();
}

class _DataAgeScreenState extends State<DataAgeScreen> {
  // Cubit with 30 second data age for demo purposes
  // In real apps, you might use Duration(minutes: 5) or longer
  late SmartPaginationCubit<Product> _cubit;

  // Track selected data age
  Duration _selectedDataAge = const Duration(seconds: 30);

  @override
  void initState() {
    super.initState();
    _createCubit();
  }

  void _createCubit() {
    _cubit = SmartPaginationCubit<Product>(
      request: const PaginationRequest(page: 1, pageSize: 10),
      provider: PaginationProvider.future(
        (request) => MockApiService.fetchProducts(
          PaginationRequest(
            page: request.page,
            pageSize: request.pageSize ?? 10,
          ),
        ),
      ),
      dataAge: _selectedDataAge,
    );
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  // Check if data is expired
  void _checkExpiration() {
    final isExpired = _cubit.isDataExpired;
    final lastFetch = _cubit.lastFetchTime;

    if (lastFetch == null) {
      _showSnackBar('No data fetched yet');
    } else if (isExpired) {
      _showSnackBar('Data has EXPIRED! Will refresh on next fetch.');
    } else {
      final remaining =
          _cubit.dataAge!.inSeconds -
          DateTime.now().difference(lastFetch).inSeconds;
      _showSnackBar('Data valid for $remaining more seconds');
    }
  }

  // Manually trigger expiration check and reset
  void _checkAndReset() {
    final wasReset = _cubit.checkAndResetIfExpired();
    if (wasReset) {
      _showSnackBar('Data was expired and has been reset!');
    } else {
      _showSnackBar('Data is still valid, no reset needed');
    }
  }

  // Change data age and recreate cubit
  void _changeDataAge(Duration newAge) {
    setState(() {
      _selectedDataAge = newAge;
      _cubit.close();
      _createCubit();
    });
    _showSnackBar('Data age changed to ${newAge.inSeconds} seconds');
  }

  // Simulate user interaction - adds an item and refreshes the timer
  int _counter = 1000;
  void _addItem() {
    _counter++;
    final product = Product(
      id: _counter.toString(),
      name: 'New Item $_counter',
      description: 'Timer refreshed!',
      price: 99.99,
      imageUrl: '',
      category: '',
      createdAt: DateTime.now(),
    );
    _cubit.insertEmit(product, index: 0);
    _showSnackBar('Item added - Timer REFRESHED!');
    setState(() {}); // Update UI to show new timer
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Age & Expiration'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Data Age Info Card
          _buildDataAgeInfoCard(),

          // Action buttons
          _buildActionButtons(),

          const Divider(height: 1),

          // Products list
          Expanded(
            child: SmartPagination.listViewWithCubit(
              cubit: _cubit,
              itemBuilder: (context, items, index) {
                final product = items[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.shade100,
                      child: Text(
                        product.id.length > 2
                            ? product.id.substring(0, 2)
                            : product.id,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    title: Text(product.name),
                    subtitle: Text(product.description),
                    trailing: Text(
                      '\$${product.price.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              },
              firstPageLoadingBuilder: (context) => const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading products...'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataAgeInfoCard() {
    return StreamBuilder<SmartPaginationState<Product>>(
      stream: _cubit.stream,
      initialData: _cubit.state,
      builder: (context, snapshot) {
        final state = snapshot.data;
        final lastFetch = _cubit.lastFetchTime;
        final isExpired = _cubit.isDataExpired;

        String statusText;
        Color statusColor;
        IconData statusIcon;

        if (lastFetch == null) {
          statusText = 'No data loaded yet';
          statusColor = Colors.grey;
          statusIcon = Icons.hourglass_empty;
        } else if (isExpired) {
          statusText = 'Data EXPIRED';
          statusColor = Colors.red;
          statusIcon = Icons.warning;
        } else {
          statusText = 'Data valid';
          statusColor = Colors.green;
          statusIcon = Icons.check_circle;
        }

        DateTime? fetchedAt;
        DateTime? expiredAt;

        if (state is SmartPaginationLoaded<Product>) {
          fetchedAt = state.fetchedAt;
          expiredAt = state.dataExpiredAt;
        }

        return Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(statusIcon, color: statusColor, size: 28),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Data Age: ${_selectedDataAge.inSeconds} seconds',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          statusText,
                          style: TextStyle(color: statusColor),
                        ),
                      ],
                    ),
                    const Spacer(),
                    if (!isExpired && lastFetch != null)
                      _ExpirationCountdown(
                        expiresAt: lastFetch.add(_selectedDataAge),
                        onExpired: () => setState(() {}),
                      ),
                  ],
                ),
                if (fetchedAt != null) ...[
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    'Fetched at:',
                    _formatTime(fetchedAt),
                    Icons.download,
                  ),
                  const SizedBox(height: 4),
                  if (expiredAt != null)
                    _buildInfoRow(
                      'Expires at:',
                      _formatTime(expiredAt),
                      Icons.timer_off,
                    ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: Colors.grey)),
        const SizedBox(width: 8),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
      ],
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}:'
        '${time.second.toString().padLeft(2, '0')}';
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // Data Age selector
          Row(
            children: [
              const Text('Data Age: '),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('15s'),
                selected: _selectedDataAge.inSeconds == 15,
                onSelected: (_) => _changeDataAge(const Duration(seconds: 15)),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('30s'),
                selected: _selectedDataAge.inSeconds == 30,
                onSelected: (_) => _changeDataAge(const Duration(seconds: 30)),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('60s'),
                selected: _selectedDataAge.inSeconds == 60,
                onSelected: (_) => _changeDataAge(const Duration(seconds: 60)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Action buttons
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _checkExpiration,
                  icon: const Icon(Icons.timer, size: 18),
                  label: const Text('Check Status'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _checkAndReset,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Check & Reset'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    _cubit.reload();
                    _showSnackBar('Reloading data...');
                  },
                  icon: const Icon(Icons.sync, size: 18),
                  label: const Text('Force Reload'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _addItem,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Item'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Data Age Feature'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'What is Data Age?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Data Age defines how long fetched data remains valid. '
                'After this duration, data is considered "expired" and '
                'will be automatically refreshed on the next fetch.',
              ),
              SizedBox(height: 16),
              Text(
                'Use Cases:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Global cubits that persist across screens'),
              Text('• Cached data that needs periodic refresh'),
              Text('• Real-time dashboards with stale data protection'),
              SizedBox(height: 16),
              Text(
                'Timer Auto-Refresh:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'The timer resets on any data interaction:\n'
                '• Insert/Add items\n'
                '• Update items\n'
                '• Remove items\n'
                '• Load more pages\n\n'
                'This ensures active users don\'t experience '
                'unexpected data resets.',
              ),
              SizedBox(height: 16),
              Text(
                'Available Properties:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• dataAge - Configured duration'),
              Text('• lastFetchTime - When data was fetched'),
              Text('• isDataExpired - Check if expired'),
              Text('• checkAndResetIfExpired() - Auto-reset if expired'),
              SizedBox(height: 16),
              Text(
                'State Properties:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• fetchedAt - Timestamp of data fetch'),
              Text('• dataExpiredAt - When data will expire'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }
}

/// Widget that shows countdown to expiration
class _ExpirationCountdown extends StatefulWidget {
  const _ExpirationCountdown({
    required this.expiresAt,
    required this.onExpired,
  });

  final DateTime expiresAt;
  final VoidCallback onExpired;

  @override
  State<_ExpirationCountdown> createState() => _ExpirationCountdownState();
}

class _ExpirationCountdownState extends State<_ExpirationCountdown> {
  late Stream<int> _countdownStream;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void didUpdateWidget(_ExpirationCountdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expiresAt != widget.expiresAt) {
      _startCountdown();
    }
  }

  void _startCountdown() {
    _countdownStream = Stream.periodic(
      const Duration(seconds: 1),
      (count) {
        final remaining = widget.expiresAt.difference(DateTime.now()).inSeconds;
        if (remaining <= 0) {
          widget.onExpired();
        }
        return remaining;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: _countdownStream,
      builder: (context, snapshot) {
        final remaining = snapshot.data ??
            widget.expiresAt.difference(DateTime.now()).inSeconds;

        if (remaining <= 0) {
          return const SizedBox.shrink();
        }

        final color = remaining <= 10 ? Colors.red : Colors.green;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.timer, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                '${remaining}s',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
