import 'package:flutter/material.dart';
import 'package:smart_pagination/pagination.dart';
import '../../models/product.dart';
import '../../services/mock_api_service.dart';

/// Demonstrates per-page error annotation via [SmartPaginationLoaded.pageErrors]
/// (v3.3.0).
///
/// Page 2's stream deliberately emits an error ~3 s after loading. The cubit
/// isolates the failure: page 2's subscription is cancelled, `pageErrors[2]`
/// is populated, and sibling pages keep updating normally. An animated banner
/// surfaces the error without replacing the list.
class PerPageErrorScreen extends StatefulWidget {
  const PerPageErrorScreen({super.key});

  @override
  State<PerPageErrorScreen> createState() => _PerPageErrorScreenState();
}

class _PerPageErrorScreenState extends State<PerPageErrorScreen> {
  late SmartPaginationCubit<Product, PaginationRequest> _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = _buildCubit();
  }

  SmartPaginationCubit<Product, PaginationRequest> _buildCubit() =>
      SmartPaginationCubit<Product, PaginationRequest>(
        request: const PaginationRequest(page: 1, pageSize: 8),
        provider:
            PaginationProvider.stream(MockApiService.unreliablePageStream),
      );

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  void _reload() {
    final old = _cubit;
    setState(() => _cubit = _buildCubit());
    old.close();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Per-Page Error Annotation'),
        backgroundColor: const Color(0xFFEF4444),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Reload demo',
            onPressed: _reload,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildInfoBanner(),
          // Error banner — only visible when pageErrors is non-empty.
          StreamBuilder<SmartPaginationState<Product>>(
            stream: _cubit.stream,
            initialData: _cubit.state,
            builder: (context, snapshot) {
              final state = snapshot.requireData;
              if (state is SmartPaginationLoaded<Product> &&
                  state.pageErrors.isNotEmpty) {
                return _buildPageErrorBanner(state.pageErrors);
              }
              return const SizedBox.shrink();
            },
          ),
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
                    CircularProgressIndicator(color: Color(0xFFEF4444)),
                    SizedBox(height: 16),
                    Text('Loading pages…'),
                  ],
                ),
              ),
              firstPageErrorBuilder: (context, error, retry) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: Colors.red),
                    const SizedBox(height: 12),
                    Text(error.toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                        onPressed: retry, child: const Text('Retry')),
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
                      strokeWidth: 2, color: Color(0xFFEF4444)),
                ),
              ),
              loadMoreNoMoreItemsBuilder: (context) => Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.done_all,
                        size: 16, color: Colors.green.shade600),
                    const SizedBox(width: 8),
                    Text('All pages loaded',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                  ],
                ),
              ),
              invisibleItemsThreshold: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFFEF4444).withValues(alpha: 0.06),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded,
                  color: Color(0xFFEF4444), size: 18),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Scroll to load page 2. After ~3 s, page 2\'s stream emits an error. '
                  'Watch the banner appear — page 1 and page 3+ keep live-updating.',
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: [
              _buildChip('Page 1', Colors.green, 'Healthy'),
              _buildChip('Page 2', const Color(0xFFEF4444), 'Errors ~3 s'),
              _buildChip('Page 3+', Colors.green, 'Healthy'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, Color color, String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 7, color: color),
          const SizedBox(width: 5),
          Text(
            '$label: $status',
            style: TextStyle(
                fontSize: 11, color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildPageErrorBanner(Map<int, Object> pageErrors) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    color: Colors.red.shade700, size: 16),
                const SizedBox(width: 8),
                Text(
                  'state.pageErrors',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade800,
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red.shade200,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${pageErrors.length} page(s) affected',
                    style: TextStyle(
                        fontSize: 10,
                        color: Colors.red.shade900,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          // One row per errored page
          ...pageErrors.entries.map((entry) => Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${entry.key}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Page ${entry.key}',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.red.shade800,
                                fontSize: 12),
                          ),
                          Text(
                            entry.value.toString(),
                            style: TextStyle(
                                fontSize: 11, color: Colors.red.shade600),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.cancel_outlined,
                        color: Colors.red.shade400, size: 16),
                  ],
                ),
              )),
          // Footer note
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: Text(
              'Subscription cancelled for errored page — sibling pages unaffected.',
              style: TextStyle(
                  fontSize: 11,
                  color: Colors.red.shade400,
                  fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(Product product) {
    // id format: unreliable_N_M  →  N is page number
    final parts = product.id.split('_');
    final page = parts.length >= 2 ? (int.tryParse(parts[1]) ?? 1) : 1;
    final isRiskyPage = page == 2;
    final color = isRiskyPage ? const Color(0xFFEF4444) : Colors.green;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          isRiskyPage ? Icons.warning_amber_rounded : Icons.check_circle_rounded,
          color: color,
          size: 22,
        ),
      ),
      title: Text(
        product.name,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        product.description,
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '\$${product.price.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 3),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'P$page',
              style: TextStyle(
                  fontSize: 10, color: color, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
