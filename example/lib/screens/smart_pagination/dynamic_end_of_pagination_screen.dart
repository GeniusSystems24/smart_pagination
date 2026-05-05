import 'dart:async';
import 'package:flutter/material.dart';
import 'package:smart_pagination/pagination.dart';
import '../../models/product.dart';

/// Demonstrates dynamic end-of-pagination detection (v3.3.0).
///
/// `hasReachedEnd` is re-evaluated on every stream emission:
/// - Page emits fewer items than `pageSize` → `hasReachedEnd = true`.
/// - Page emits a full page again → `hasReachedEnd = false`, scroll resumes.
///
/// Use the control panel to fill/drain page 1 and observe the live change.
class DynamicEndOfPaginationScreen extends StatefulWidget {
  const DynamicEndOfPaginationScreen({super.key});

  @override
  State<DynamicEndOfPaginationScreen> createState() =>
      _DynamicEndOfPaginationScreenState();
}

class _DynamicEndOfPaginationScreenState
    extends State<DynamicEndOfPaginationScreen> {
  static const int _pageSize = 10;

  static const _names = [
    'Wireless Headphones',
    'Smart Watch',
    'Laptop',
    'Running Shoes',
    'Coffee Maker',
    'Desk Lamp',
    'Backpack',
    'Water Bottle',
    'Yoga Mat',
    'Gaming Mouse',
  ];

  late final StreamController<List<Product>> _page1Controller;
  late SmartPaginationCubit<Product, PaginationRequest> _cubit;
  int _emittedCount = 5;

  @override
  void initState() {
    super.initState();
    _page1Controller = StreamController<List<Product>>.broadcast();
    _cubit = SmartPaginationCubit<Product, PaginationRequest>(
      request: const PaginationRequest(page: 1, pageSize: _pageSize),
      provider: PaginationProvider.stream(_buildProvider),
    );
    // Emit the initial partial page after subscriptions are set up.
    Future.microtask(() => _emitPage(5));
  }

  Stream<List<Product>> _buildProvider(PaginationRequest request) {
    if (request.page == 1) return _page1Controller.stream;
    return _staticPageStream(request);
  }

  Stream<List<Product>> _staticPageStream(PaginationRequest request) async* {
    final ps = request.pageSize ?? _pageSize;
    final start = (request.page - 1) * ps;
    yield _makeStaticItems(request.page, ps, start, 'loaded');
    var tick = 1;
    await for (final _ in Stream.periodic(const Duration(seconds: 6))) {
      yield _makeStaticItems(
          request.page, ps, start, 'update #$tick • ${_now()}');
      tick++;
    }
  }

  List<Product> _makeStaticItems(
      int page, int ps, int start, String label) {
    return List.generate(ps, (i) {
      final idx = start + i;
      return Product(
        id: 'static_${page}_$idx',
        name: '${_names[idx % _names.length]} #$idx',
        description: 'Page $page • $label',
        price: 19.99 + idx * 3.0,
        category: 'Static',
        imageUrl: 'https://picsum.photos/200/200?random=$idx',
        createdAt: DateTime.now().subtract(Duration(days: idx)),
      );
    });
  }

  void _emitPage(int count) {
    if (!_page1Controller.hasListener) return;
    final isPartial = count < _pageSize;
    _page1Controller.add(
      List.generate(count, (i) => Product(
            id: 'dynamic_1_$i',
            name: '${_names[i % _names.length]} #$i',
            description: isPartial
                ? '⚠ Partial: $count/$_pageSize → end detected'
                : '✓ Full: $count/$_pageSize → pagination resumes',
            price: 29.99 + i * 2.0,
            category: 'Dynamic',
            imageUrl: 'https://picsum.photos/200/200?random=$i',
            createdAt: DateTime.now(),
          )),
    );
    setState(() => _emittedCount = count);
  }

  void _fillPage() => _emitPage(_pageSize);
  void _drainPage() => _emitPage(5);

  static String _now() =>
      DateTime.now().toIso8601String().substring(11, 19);

  @override
  void dispose() {
    _cubit.close();
    _page1Controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dynamic End-of-Pagination'),
        backgroundColor: const Color(0xFFF59E0B),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildInfoBanner(),
          _buildControlPanel(),
          Expanded(
            child: SmartPagination<Product, PaginationRequest>.withCubit(
              key: ValueKey(_cubit),
              cubit: _cubit,
              itemBuilderType: PaginateBuilderType.listView,
              itemBuilder: (context, items, index) => _buildItem(items[index]),
              separator: const Divider(height: 1),
              firstPageLoadingBuilder: (context) => const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Color(0xFFF59E0B)),
                    SizedBox(height: 16),
                    Text('Waiting for first emission…'),
                  ],
                ),
              ),
              loadMoreLoadingBuilder: (context) => Container(
                padding: const EdgeInsets.all(16),
                alignment: Alignment.center,
                child: const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Color(0xFFF59E0B)),
                ),
              ),
              loadMoreNoMoreItemsBuilder: (context) => _buildEndIndicator(),
              invisibleItemsThreshold: 3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.science_rounded, color: Color(0xFFF59E0B), size: 18),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Rule: items.length < pageSize → hasReachedEnd = true. '
              'When the stream later emits a full page, end clears and scrolling '
              'resumes. Tap the buttons below to trigger both transitions live.',
              style: TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlPanel() {
    return StreamBuilder<SmartPaginationState<Product>>(
      stream: _cubit.stream,
      initialData: _cubit.state,
      builder: (context, snapshot) {
        final state = snapshot.requireData;
        final hasReachedEnd = state is SmartPaginationLoaded<Product>
            ? state.hasReachedEnd
            : false;
        final isFull = _emittedCount >= _pageSize;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildIndicator(
                      label: 'Page 1 items',
                      value: '$_emittedCount / $_pageSize',
                      color: isFull ? Colors.green : const Color(0xFFF59E0B),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildIndicator(
                      label: 'hasReachedEnd',
                      value: hasReachedEnd ? 'true' : 'false',
                      color: hasReachedEnd
                          ? const Color(0xFFEF4444)
                          : Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: isFull ? null : _fillPage,
                      icon: const Icon(Icons.expand_rounded, size: 16),
                      label: Text('Fill ($_pageSize items)'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.green,
                        side: const BorderSide(color: Colors.green),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: isFull ? _drainPage : null,
                      icon: const Icon(Icons.compress_rounded, size: 16),
                      label: const Text('Drain (5 items)'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFF59E0B),
                        side:
                            const BorderSide(color: Color(0xFFF59E0B)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildIndicator({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
                fontSize: 10, color: color.withValues(alpha: 0.7)),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(Product product) {
    final isDynamic = product.id.startsWith('dynamic_');
    final isPartial = isDynamic && _emittedCount < _pageSize;

    Color color;
    IconData icon;
    if (!isDynamic) {
      color = Colors.blue;
      icon = Icons.list_alt_rounded;
    } else if (isPartial) {
      color = const Color(0xFFF59E0B);
      icon = Icons.hourglass_top_rounded;
    } else {
      color = Colors.green;
      icon = Icons.check_circle_rounded;
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        product.name,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        product.description,
        style: TextStyle(
          fontSize: 12,
          color: (isDynamic && isPartial) ? color : Colors.grey[600],
        ),
      ),
      trailing: Text(
        '\$${product.price.toStringAsFixed(2)}',
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
    );
  }

  Widget _buildEndIndicator() {
    final isPartial = _emittedCount < _pageSize;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(
            isPartial
                ? Icons.stop_circle_outlined
                : Icons.done_all_rounded,
            color: isPartial ? const Color(0xFFF59E0B) : Colors.green,
            size: 22,
          ),
          const SizedBox(height: 6),
          Text(
            isPartial
                ? 'End detected: $_emittedCount/$_pageSize items on page 1'
                : 'All pages loaded',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isPartial ? const Color(0xFFF59E0B) : Colors.green,
            ),
          ),
          if (isPartial)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Tap "Fill" to resume scrolling →',
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
            ),
        ],
      ),
    );
  }
}
