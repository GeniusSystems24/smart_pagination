import 'package:flutter/material.dart';
import 'package:smart_pagination/pagination.dart';
import '../../models/product.dart';
import '../../services/mock_api_service.dart';

/// Demonstrates per-page stream accumulation (v3.3.0).
///
/// Each page-load registers an independent live subscription. Scrolling to
/// page 2 does NOT cancel page 1 — both pages update simultaneously via their
/// own stream subscriptions. The page badge ("P1", "P2") and live timestamps
/// in the item subtitles make this visible at a glance.
class StreamAccumulationScreen extends StatefulWidget {
  const StreamAccumulationScreen({super.key});

  @override
  State<StreamAccumulationScreen> createState() =>
      _StreamAccumulationScreenState();
}

class _StreamAccumulationScreenState extends State<StreamAccumulationScreen> {
  late final SmartPaginationCubit<Product, PaginationRequest> _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = SmartPaginationCubit<Product, PaginationRequest>(
      request: const PaginationRequest(page: 1, pageSize: 8),
      provider: PaginationProvider.stream(
        MockApiService.accumulatingProductsStream,
      ),
    );
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stream Accumulation'),
        backgroundColor: const Color(0xFF0D9488),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildInfoBanner(),
          _buildStatusBar(),
          Expanded(
            child: SmartPagination<Product, PaginationRequest>.withCubit(
              cubit: _cubit,
              itemBuilderType: PaginateBuilderType.listView,
              itemBuilder: (context, items, index) => _buildItem(items[index]),
              separator: const Divider(height: 1),
              firstPageLoadingBuilder: (context) => const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF0D9488)),
                    SizedBox(height: 16),
                    Text('Attaching page 1 subscription…'),
                  ],
                ),
              ),
              firstPageErrorBuilder: (context, error, retry) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 12),
                    Text(error.toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13)),
                    const SizedBox(height: 16),
                    ElevatedButton(onPressed: retry, child: const Text('Retry')),
                  ],
                ),
              ),
              loadMoreLoadingBuilder: (context) => Container(
                padding: const EdgeInsets.all(16),
                alignment: Alignment.center,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Color(0xFF0D9488)),
                    ),
                    SizedBox(width: 10),
                    Text('Attaching new page subscription…',
                        style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
              loadMoreNoMoreItemsBuilder: (context) => Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.done_all, size: 16, color: Colors.green.shade600),
                    const SizedBox(width: 8),
                    Text(
                      'All page subscriptions active',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
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
      color: const Color(0xFF0D9488).withValues(alpha: 0.08),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.layers_rounded, color: Color(0xFF0D9488), size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Each page gets its own independent live subscription. Scroll to load '
              'page 2 — watch page 1 items keep updating (timestamps change) while '
              'page 2 items are also live. No page replaces another.',
              style: TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBar() {
    return StreamBuilder<SmartPaginationState<Product>>(
      stream: _cubit.stream,
      initialData: _cubit.state,
      builder: (context, snapshot) {
        final state = snapshot.requireData;
        final itemCount =
            state is SmartPaginationLoaded<Product> ? state.allItems.length : 0;
        final page = state is SmartPaginationLoaded<Product>
            ? (state.meta.page ?? 0)
            : 0;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              _buildStatChip(
                icon: Icons.subscriptions_rounded,
                label: 'Active Pages',
                value: '$page',
                color: const Color(0xFF0D9488),
              ),
              const SizedBox(width: 12),
              _buildStatChip(
                icon: Icons.list_alt_rounded,
                label: 'Total Items',
                value: '$itemCount',
                color: const Color(0xFF6366F1),
              ),
              const Spacer(),
              if (state is SmartPaginationLoaded<Product>)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, size: 8, color: Colors.green),
                      SizedBox(width: 6),
                      Text(
                        'LIVE',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style:
                    TextStyle(fontSize: 10, color: color.withValues(alpha: 0.7)),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Colours for pages 1–5+ so each page's items are visually distinct.
  static const _pageColors = [
    Color(0xFF0D9488), // teal   – page 1
    Color(0xFF6366F1), // indigo – page 2
    Color(0xFFF59E0B), // amber  – page 3
    Color(0xFFEF4444), // red    – page 4
    Color(0xFF8B5CF6), // violet – page 5
  ];

  Widget _buildItem(Product product) {
    // id format: product_pN_M  →  extract N as page number
    final match = RegExp(r'_p(\d+)_').firstMatch(product.id);
    final page = match != null ? (int.tryParse(match.group(1)!) ?? 1) : 1;
    final color = _pageColors[(page - 1) % _pageColors.length];

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Center(
          child: Text(
            'P$page',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ),
      title: Text(
        product.name,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Text(
          product.description,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '\$${product.price.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Page $page',
              style: TextStyle(
                  fontSize: 10, color: color, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
