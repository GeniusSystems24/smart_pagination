import 'package:flutter/material.dart';
import 'package:smart_pagination/pagination.dart';
import '../../models/product.dart';
import '../../services/mock_api_service.dart';

/// Example demonstrating ReorderableListView with pagination
class ReorderableListScreen extends StatefulWidget {
  const ReorderableListScreen({super.key});

  @override
  State<ReorderableListScreen> createState() => _ReorderableListScreenState();
}

class _ReorderableListScreenState extends State<ReorderableListScreen> {
  List<Product> _items = [];
  bool _isInitialized = false;

  Future<void> _loadInitialData() async {
    if (_isInitialized) return;

    final request = const PaginationRequest(page: 1, pageSize: 20);
    final products = await MockApiService.fetchProducts(request);

    setState(() {
      _items = products;
      _isInitialized = true;
    });
  }

  void _handleReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _items.removeAt(oldIndex);
      _items.insert(newIndex, item);
    });

    // Show feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Moved item from position ${oldIndex + 1} to ${newIndex + 1}',
        ),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reorderable List'),
        backgroundColor: Colors.purple,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _isInitialized = false;
                _items.clear();
              });
              _loadInitialData();
            },
            tooltip: 'Reset Order',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.purple.withValues(alpha:0.1),
            child: const Row(
              children: [
                Icon(Icons.drag_indicator, color: Colors.purple),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Long press and drag items to reorder them. '
                    'Perfect for todo lists, playlists, and prioritized content.',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          // Stats Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.grey[100],
            child: Row(
              children: [
                Icon(Icons.list, size: 18, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  '${_items.length} items',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const Spacer(),
                Icon(Icons.info_outline, size: 16, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  'Long press to drag',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Reorderable List
          Expanded(
            child: FutureBuilder(
              future: _loadInitialData(),
              builder: (context, snapshot) {
                if (!_isInitialized) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.purple),
                  );
                }

                if (_items.isEmpty) {
                  return const Center(child: Text('No items to display'));
                }

                return SmartPagination<Product>.reorderableListViewWithProvider(
                  request: const PaginationRequest(page: 1, pageSize: 20),
                  provider: PaginationProvider.future(
                    (request) async => _items,
                  ),
                  itemBuilder: (context, items, index) {
                    final product = items[index];
                    return _buildProductCard(product, index);
                  },
                  onReorder: _handleReorder,
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _items.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () {
                // Show current order
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Current Order'),
                    content: SizedBox(
                      width: double.maxFinite,
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _items.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            dense: true,
                            leading: CircleAvatar(
                              radius: 14,
                              backgroundColor: Colors.purple,
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            title: Text(
                              _items[index].name,
                              style: const TextStyle(fontSize: 13),
                            ),
                          );
                        },
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                );
              },
              backgroundColor: Colors.purple,
              icon: const Icon(Icons.format_list_numbered),
              label: const Text('View Order'),
            )
          : null,
    );
  }

  Widget _buildProductCard(Product product, int index) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag Handle
            Icon(Icons.drag_handle, color: Colors.grey[400], size: 24),
            const SizedBox(width: 12),
            // Order Number
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.purple.withValues(alpha:0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Colors.purple,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                product.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.purple.withValues(alpha:0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                product.category,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.purple,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              product.description,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.attach_money, size: 14, color: Colors.green[700]),
                Text(
                  product.price.toStringAsFixed(2),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Icon(Icons.more_vert, color: Colors.grey[400]),
      ),
    );
  }
}

/// Another example with priority-based reordering
class PriorityTasksScreen extends StatefulWidget {
  const PriorityTasksScreen({super.key});

  @override
  State<PriorityTasksScreen> createState() => _PriorityTasksScreenState();
}

class _PriorityTasksScreenState extends State<PriorityTasksScreen> {
  List<Product> _tasks = [];
  bool _isInitialized = false;

  Future<void> _loadInitialData() async {
    if (_isInitialized) return;

    final request = const PaginationRequest(page: 1, pageSize: 15);
    final products = await MockApiService.fetchProducts(request);

    setState(() {
      _tasks = products;
      _isInitialized = true;
    });
  }

  void _handleReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _tasks.removeAt(oldIndex);
      _tasks.insert(newIndex, item);
    });
  }

  Color _getPriorityColor(int index) {
    if (index < 3) return Colors.red;
    if (index < 7) return Colors.orange;
    return Colors.green;
  }

  String _getPriorityLabel(int index) {
    if (index < 3) return 'HIGH';
    if (index < 7) return 'MEDIUM';
    return 'LOW';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Priority Tasks'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.deepPurple.withValues(alpha:0.1),
            child: const Row(
              children: [
                Icon(Icons.priority_high, color: Colors.deepPurple),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Reorder tasks by priority. Top items = High priority, '
                    'Bottom items = Low priority.',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          // Priority Legend
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.grey[50],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildPriorityLegend(Colors.red, 'High', 'Top 1-3'),
                _buildPriorityLegend(Colors.orange, 'Medium', '4-7'),
                _buildPriorityLegend(Colors.green, 'Low', '8+'),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: FutureBuilder(
              future: _loadInitialData(),
              builder: (context, snapshot) {
                if (!_isInitialized) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.deepPurple),
                  );
                }

                if (_tasks.isEmpty) {
                  return const Center(child: Text('No tasks'));
                }

                return SmartPagination<Product>.reorderableListViewWithProvider(
                  request: const PaginationRequest(page: 1, pageSize: 15),
                  provider: PaginationProvider.future(
                    (request) async => _tasks,
                  ),
                  itemBuilder: (context, items, index) {
                    final task = items[index];
                    final priorityColor = _getPriorityColor(index);
                    final priorityLabel = _getPriorityLabel(index);

                    return _buildTaskCard(
                      task,
                      index,
                      priorityColor,
                      priorityLabel,
                    );
                  },
                  onReorder: _handleReorder,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityLegend(Color color, String label, String range) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          '$label ($range)',
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildTaskCard(
    Product task,
    int index,
    Color priorityColor,
    String priorityLabel,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: priorityColor, width: 4)),
      ),
      child: Card(
        margin: EdgeInsets.zero,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          leading: Icon(Icons.drag_handle, color: Colors.grey[400]),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: priorityColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  priorityLabel,
                  style: const TextStyle(
                    fontSize: 9,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  task.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              task.description,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ),
          trailing: Text(
            '#${index + 1}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: priorityColor,
            ),
          ),
        ),
      ),
    );
  }
}
