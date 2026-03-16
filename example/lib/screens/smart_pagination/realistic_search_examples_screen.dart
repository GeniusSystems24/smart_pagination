import 'dart:math';
import 'package:flutter/material.dart';
import 'package:smart_pagination/pagination.dart';

import '../../models/product.dart';
import '../../models/user.dart';

/// Realistic search examples with professional, modern UI designs.
///
/// This screen demonstrates:
/// - E-commerce product search with filters
/// - Team member/Contact selector
/// - Country/Location picker
/// - Tag/Category multi-selector
/// - Employee directory search
class RealisticSearchExamplesScreen extends StatefulWidget {
  const RealisticSearchExamplesScreen({super.key});

  @override
  State<RealisticSearchExamplesScreen> createState() =>
      _RealisticSearchExamplesScreenState();
}

class _RealisticSearchExamplesScreenState
    extends State<RealisticSearchExamplesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
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
        title: const Text('Realistic Examples'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.shopping_bag), text: 'E-Commerce'),
            Tab(icon: Icon(Icons.people), text: 'Team'),
            Tab(icon: Icon(Icons.public), text: 'Countries'),
            Tab(icon: Icon(Icons.label), text: 'Tags'),
            Tab(icon: Icon(Icons.business), text: 'Directory'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _ECommerceSearchExample(),
          _TeamMemberSearchExample(),
          _CountryPickerExample(),
          _TagSelectorExample(),
          _EmployeeDirectoryExample(),
        ],
      ),
    );
  }
}

// ============================================================================
// 1. E-Commerce Product Search
// ============================================================================
class _ECommerceSearchExample extends StatefulWidget {
  const _ECommerceSearchExample();

  @override
  State<_ECommerceSearchExample> createState() =>
      _ECommerceSearchExampleState();
}

class _ECommerceSearchExampleState extends State<_ECommerceSearchExample> {
  Product? _selectedProduct;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.primary.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.shopping_bag,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Product Search',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Find products in your store',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Search Dropdown
          Text(
            'Quick Search',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          SmartSearchDropdown<Product, String>.withProvider(
            request: const PaginationRequest(page: 1, pageSize: 10),
            provider: PaginationProvider.future(_searchProducts),
            searchRequestBuilder: (query) => PaginationRequest(
              page: 1,
              pageSize: 10,
              searchQuery: query,
            ),
            keyExtractor: (p) => p.id,
            searchConfig: const SmartSearchConfig(
              debounceDelay: Duration(milliseconds: 300),
              fetchOnInit: true,
              skipDebounceOnEmpty: true,
            ),
            overlayConfig: const SmartSearchOverlayConfig(
              maxHeight: 350,
              borderRadius: 16,
              elevation: 12,
              animationType: OverlayAnimationType.fadeScale,
            ),
            showSelected: true,
            decoration: InputDecoration(
              hintText: 'Search for products...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: theme.colorScheme.primary,
                  width: 2,
                ),
              ),
            ),
            itemBuilder: (context, product) => _ProductListTile(product: product),
            selectedItemBuilder: (context, product, onClear) =>
                _SelectedProductCard(product: product, onClear: onClear),
            onSelected: (product, _) {
              setState(() => _selectedProduct = product);
            },
            headerBuilder: (context) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                border: Border(
                  bottom: BorderSide(color: theme.dividerColor),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.inventory_2,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Available Products',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            emptyBuilder: (context) => Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.search_off,
                    size: 48,
                    color: theme.disabledColor,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No products found',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.disabledColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Try a different search term',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.disabledColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Selected Product Details
          if (_selectedProduct != null) ...[
            Text(
              'Selected Product',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _ProductDetailCard(product: _selectedProduct!),
          ],
        ],
      ),
    );
  }

  static Future<List<Product>> _searchProducts(PaginationRequest request) async {
    await Future.delayed(const Duration(milliseconds: 400));

    final products = List.generate(
      50,
      (i) => Product(
        id: 'prod_$i',
        name: _productNames[i % _productNames.length],
        description: _productDescriptions[i % _productDescriptions.length],
        price: 29.99 + (i * 10.5),
        category: _categories[i % _categories.length],
        imageUrl: '',
        createdAt: DateTime.now().subtract(Duration(days: i)),
        rating: 3.5 + (Random().nextDouble() * 1.5),
        stock: Random().nextInt(100),
      ),
    );

    final query = request.searchQuery?.toLowerCase() ?? '';
    if (query.isEmpty) return products.take(10).toList();

    return products
        .where((p) =>
            p.name.toLowerCase().contains(query) ||
            p.category.toLowerCase().contains(query))
        .take(10)
        .toList();
  }

  static const _productNames = [
    'MacBook Pro 16"',
    'iPhone 15 Pro Max',
    'AirPods Pro 2',
    'iPad Air M2',
    'Apple Watch Ultra',
    'Sony WH-1000XM5',
    'Samsung Galaxy S24',
    'Dell XPS 15',
    'Logitech MX Master 3',
    'Kindle Paperwhite',
  ];

  static const _productDescriptions = [
    'Premium quality with exceptional performance',
    'Latest technology for modern lifestyle',
    'Best-in-class features and design',
    'Professional grade equipment',
    'Award-winning innovation',
  ];

  static const _categories = [
    'Electronics',
    'Computers',
    'Audio',
    'Mobile',
    'Accessories',
  ];
}

class _ProductListTile extends StatelessWidget {
  final Product product;

  const _ProductListTile({required this.product});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.inventory_2,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        product.category,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.star,
                      size: 14,
                      color: Colors.amber[700],
                    ),
                    const SizedBox(width: 2),
                    Text(
                      product.rating.toStringAsFixed(1),
                      style: theme.textTheme.labelSmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            '\$${product.price.toStringAsFixed(2)}',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectedProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onClear;

  const _SelectedProductCard({
    required this.product,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.check,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '\$${product.price.toStringAsFixed(2)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onClear,
            icon: const Icon(Icons.close),
            style: IconButton.styleFrom(
              backgroundColor: theme.colorScheme.surface,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductDetailCard extends StatelessWidget {
  final Product product;

  const _ProductDetailCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.secondary,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.inventory_2,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          product.category,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSecondaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              product.description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _InfoChip(
                  icon: Icons.attach_money,
                  label: product.price.toStringAsFixed(2),
                  color: Colors.green,
                ),
                const SizedBox(width: 12),
                _InfoChip(
                  icon: Icons.star,
                  label: product.rating.toStringAsFixed(1),
                  color: Colors.amber[700]!,
                ),
                const SizedBox(width: 12),
                _InfoChip(
                  icon: Icons.inventory,
                  label: '${product.stock} in stock',
                  color: theme.colorScheme.primary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 2. Team Member Search
// ============================================================================
class _TeamMemberSearchExample extends StatefulWidget {
  const _TeamMemberSearchExample();

  @override
  State<_TeamMemberSearchExample> createState() =>
      _TeamMemberSearchExampleState();
}

class _TeamMemberSearchExampleState extends State<_TeamMemberSearchExample> {
  List<User> _selectedMembers = [];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: theme.colorScheme.secondary,
                  child: const Icon(
                    Icons.group_add,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add Team Members',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Search and select team members for your project',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Multi-select search
          SmartSearchMultiDropdown<User, String>.withProvider(
            request: const PaginationRequest(page: 1, pageSize: 15),
            provider: PaginationProvider.future(_searchUsers),
            searchRequestBuilder: (query) => PaginationRequest(
              page: 1,
              pageSize: 15,
              searchQuery: query,
            ),
            keyExtractor: (u) => u.id,
            displayMode: SearchDisplayMode.bottomSheet,
            searchConfig: const SmartSearchConfig(
              debounceDelay: Duration(milliseconds: 300),
              fetchOnInit: true,
            ),
            bottomSheetConfig: SmartSearchBottomSheetConfig(
              titleBuilder: (count) => Row(
                children: [
                  const Icon(Icons.people),
                  const SizedBox(width: 12),
                  Text(
                    count > 0 ? 'Selected ($count)' : 'Select Team Members',
                    style: theme.textTheme.titleLarge,
                  ),
                ],
              ),
              confirmText: 'Add Members',
              showSelectedCount: true,
              heightFactor: 0.85,
            ),
            showSelected: true,
            hintText: 'Tap to add team members...',
            maxSelections: 5,
            onMaxSelectionsReached: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Maximum 5 members allowed'),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: theme.colorScheme.error,
                ),
              );
            },
            itemBuilder: (context, user) => _UserListTile(user: user),
            selectedItemBuilder: (context, user, onRemove) =>
                _UserChip(user: user, onRemove: onRemove),
            selectedItemsWrap: true,
            selectedItemsSpacing: 8,
            selectedItemsRunSpacing: 8,
            onSelected: (users, _) {
              setState(() => _selectedMembers = users);
            },
          ),
          const SizedBox(height: 24),

          // Selected Members Summary
          if (_selectedMembers.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Team Composition',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => setState(() => _selectedMembers.clear()),
                  icon: const Icon(Icons.clear_all, size: 18),
                  label: const Text('Clear All'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...List.generate(_selectedMembers.length, (index) {
              final user = _selectedMembers[index];
              return _TeamMemberCard(
                user: user,
                onRemove: () {
                  setState(() => _selectedMembers.removeAt(index));
                },
              );
            }),
          ],
        ],
      ),
    );
  }

  static Future<List<User>> _searchUsers(PaginationRequest request) async {
    await Future.delayed(const Duration(milliseconds: 400));

    final users = List.generate(
      30,
      (i) => User(
        id: 'user_$i',
        name: _names[i % _names.length],
        email: '${_names[i % _names.length].toLowerCase().replaceAll(' ', '.')}@company.com',
        avatar: '',
        department: _departments[i % _departments.length],
        role: _roles[i % _roles.length],
        isOnline: Random().nextBool(),
        lastSeen: DateTime.now().subtract(Duration(minutes: Random().nextInt(120))),
      ),
    );

    final query = request.searchQuery?.toLowerCase() ?? '';
    if (query.isEmpty) return users;

    return users
        .where((u) =>
            u.name.toLowerCase().contains(query) ||
            u.email.toLowerCase().contains(query) ||
            u.department.toLowerCase().contains(query))
        .toList();
  }

  static const _names = [
    'Alex Johnson',
    'Sarah Williams',
    'Michael Brown',
    'Emily Davis',
    'James Wilson',
    'Emma Taylor',
    'David Anderson',
    'Olivia Martinez',
    'Robert Garcia',
    'Sophia Lee',
  ];

  static const _departments = [
    'Engineering',
    'Design',
    'Marketing',
    'Sales',
    'Product',
  ];

  static const _roles = [
    'Senior Developer',
    'UI/UX Designer',
    'Project Manager',
    'Team Lead',
    'Analyst',
  ];
}

class _UserListTile extends StatelessWidget {
  final User user;

  const _UserListTile({required this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initials = user.name.split(' ').map((n) => n[0]).take(2).join();

    return ListTile(
      leading: Stack(
        children: [
          CircleAvatar(
            backgroundColor: _getAvatarColor(user.name),
            child: Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (user.isOnline)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: theme.scaffoldBackgroundColor, width: 2),
                ),
              ),
            ),
        ],
      ),
      title: Text(
        user.name,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Row(
        children: [
          Icon(Icons.business, size: 14, color: theme.disabledColor),
          const SizedBox(width: 4),
          Text(user.department),
          const SizedBox(width: 8),
          Text('• ${user.role}', style: TextStyle(color: theme.disabledColor)),
        ],
      ),
      trailing: user.isOnline
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Online',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          : null,
    );
  }

  Color _getAvatarColor(String name) {
    final colors = [
      Colors.blue,
      Colors.purple,
      Colors.teal,
      Colors.orange,
      Colors.pink,
      Colors.indigo,
    ];
    return colors[name.hashCode % colors.length];
  }
}

class _UserChip extends StatelessWidget {
  final User user;
  final VoidCallback onRemove;

  const _UserChip({required this.user, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final initials = user.name.split(' ').map((n) => n[0]).take(2).join();

    return Chip(
      avatar: CircleAvatar(
        backgroundColor: _getAvatarColor(user.name),
        child: Text(
          initials,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      label: Text(user.name.split(' ').first),
      deleteIcon: const Icon(Icons.close, size: 16),
      onDeleted: onRemove,
    );
  }

  Color _getAvatarColor(String name) {
    final colors = [
      Colors.blue,
      Colors.purple,
      Colors.teal,
      Colors.orange,
      Colors.pink,
      Colors.indigo,
    ];
    return colors[name.hashCode % colors.length];
  }
}

class _TeamMemberCard extends StatelessWidget {
  final User user;
  final VoidCallback onRemove;

  const _TeamMemberCard({required this.user, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initials = user.name.split(' ').map((n) => n[0]).take(2).join();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: _getAvatarColor(user.name),
              child: Text(
                initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${user.role} • ${user.department}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.remove_circle_outline),
              color: theme.colorScheme.error,
            ),
          ],
        ),
      ),
    );
  }

  Color _getAvatarColor(String name) {
    final colors = [
      Colors.blue,
      Colors.purple,
      Colors.teal,
      Colors.orange,
      Colors.pink,
      Colors.indigo,
    ];
    return colors[name.hashCode % colors.length];
  }
}

// ============================================================================
// 3. Country Picker
// ============================================================================
class _CountryPickerExample extends StatefulWidget {
  const _CountryPickerExample();

  @override
  State<_CountryPickerExample> createState() => _CountryPickerExampleState();
}

class _CountryPickerExampleState extends State<_CountryPickerExample> {
  Country? _selectedCountry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Form Card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: theme.dividerColor),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.person_add,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Shipping Information',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please select your country for delivery',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Country Selector
                  Text(
                    'Country / Region',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SmartSearchDropdown<Country, String>.withProvider(
                    request: const PaginationRequest(page: 1, pageSize: 20),
                    provider: PaginationProvider.future(_searchCountries),
                    searchRequestBuilder: (query) => PaginationRequest(
                      page: 1,
                      pageSize: 20,
                      searchQuery: query,
                    ),
                    keyExtractor: (c) => c.code,
                    searchConfig: const SmartSearchConfig(
                      debounceDelay: Duration(milliseconds: 200),
                      fetchOnInit: true,
                    ),
                    overlayConfig: const SmartSearchOverlayConfig(
                      maxHeight: 300,
                      borderRadius: 12,
                    ),
                    showSelected: true,
                    decoration: InputDecoration(
                      hintText: 'Select country...',
                      prefixIcon: const Icon(Icons.public),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    itemBuilder: (context, country) =>
                        _CountryListTile(country: country),
                    selectedItemBuilder: (context, country, onClear) =>
                        _SelectedCountryTile(country: country, onClear: onClear),
                    onSelected: (country, _) {
                      setState(() => _selectedCountry = country);
                    },
                  ),
                  const SizedBox(height: 24),

                  // Other form fields (placeholder)
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Address',
                      prefixIcon: const Icon(Icons.home_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            labelText: 'City',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            labelText: 'Postal Code',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_selectedCountry != null) ...[
                    const SizedBox(height: 16),
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Phone',
                        prefixIcon: const Icon(Icons.phone_outlined),
                        prefixText: '${_selectedCountry!.dialCode} ',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _selectedCountry != null ? () {} : null,
                      icon: const Icon(Icons.check),
                      label: const Text('Continue to Payment'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Future<List<Country>> _searchCountries(
      PaginationRequest request) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final query = request.searchQuery?.toLowerCase() ?? '';
    if (query.isEmpty) return _countries;

    return _countries
        .where((c) =>
            c.name.toLowerCase().contains(query) ||
            c.code.toLowerCase().contains(query))
        .toList();
  }

  static const _countries = [
    Country(code: 'US', name: 'United States', flag: '🇺🇸', dialCode: '+1', continent: 'North America'),
    Country(code: 'GB', name: 'United Kingdom', flag: '🇬🇧', dialCode: '+44', continent: 'Europe'),
    Country(code: 'CA', name: 'Canada', flag: '🇨🇦', dialCode: '+1', continent: 'North America'),
    Country(code: 'AU', name: 'Australia', flag: '🇦🇺', dialCode: '+61', continent: 'Oceania'),
    Country(code: 'DE', name: 'Germany', flag: '🇩🇪', dialCode: '+49', continent: 'Europe'),
    Country(code: 'FR', name: 'France', flag: '🇫🇷', dialCode: '+33', continent: 'Europe'),
    Country(code: 'JP', name: 'Japan', flag: '🇯🇵', dialCode: '+81', continent: 'Asia'),
    Country(code: 'KR', name: 'South Korea', flag: '🇰🇷', dialCode: '+82', continent: 'Asia'),
    Country(code: 'CN', name: 'China', flag: '🇨🇳', dialCode: '+86', continent: 'Asia'),
    Country(code: 'IN', name: 'India', flag: '🇮🇳', dialCode: '+91', continent: 'Asia'),
    Country(code: 'BR', name: 'Brazil', flag: '🇧🇷', dialCode: '+55', continent: 'South America'),
    Country(code: 'MX', name: 'Mexico', flag: '🇲🇽', dialCode: '+52', continent: 'North America'),
    Country(code: 'IT', name: 'Italy', flag: '🇮🇹', dialCode: '+39', continent: 'Europe'),
    Country(code: 'ES', name: 'Spain', flag: '🇪🇸', dialCode: '+34', continent: 'Europe'),
    Country(code: 'NL', name: 'Netherlands', flag: '🇳🇱', dialCode: '+31', continent: 'Europe'),
    Country(code: 'SA', name: 'Saudi Arabia', flag: '🇸🇦', dialCode: '+966', continent: 'Asia'),
    Country(code: 'AE', name: 'UAE', flag: '🇦🇪', dialCode: '+971', continent: 'Asia'),
    Country(code: 'SG', name: 'Singapore', flag: '🇸🇬', dialCode: '+65', continent: 'Asia'),
    Country(code: 'EG', name: 'Egypt', flag: '🇪🇬', dialCode: '+20', continent: 'Africa'),
    Country(code: 'ZA', name: 'South Africa', flag: '🇿🇦', dialCode: '+27', continent: 'Africa'),
  ];
}

class _CountryListTile extends StatelessWidget {
  final Country country;

  const _CountryListTile({required this.country});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Text(
        country.flag,
        style: const TextStyle(fontSize: 28),
      ),
      title: Text(
        country.name,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(country.continent),
      trailing: Text(
        country.dialCode,
        style: TextStyle(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _SelectedCountryTile extends StatelessWidget {
  final Country country;
  final VoidCallback onClear;

  const _SelectedCountryTile({required this.country, required this.onClear});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.primary),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(country.flag, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  country.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  '${country.dialCode} • ${country.continent}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onClear,
            icon: const Icon(Icons.close),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 4. Tag Selector
// ============================================================================
class _TagSelectorExample extends StatefulWidget {
  const _TagSelectorExample();

  @override
  State<_TagSelectorExample> createState() => _TagSelectorExampleState();
}

class _TagSelectorExampleState extends State<_TagSelectorExample> {
  List<Tag> _selectedTags = [];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.purple.shade400,
                  Colors.purple.shade700,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.edit_note,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'New Blog Post',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Add tags to help readers find your content',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Tag Selector
          Text(
            'Tags',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          SmartSearchMultiDropdown<Tag, String>.withProvider(
            request: const PaginationRequest(page: 1, pageSize: 20),
            provider: PaginationProvider.future(_searchTags),
            searchRequestBuilder: (query) => PaginationRequest(
              page: 1,
              pageSize: 20,
              searchQuery: query,
            ),
            keyExtractor: (t) => t.id,
            searchConfig: const SmartSearchConfig(
              debounceDelay: Duration(milliseconds: 200),
              fetchOnInit: true,
            ),
            overlayConfig: const SmartSearchOverlayConfig(
              maxHeight: 280,
              borderRadius: 12,
              animationType: OverlayAnimationType.slideDown,
            ),
            showSelected: true,
            maxSelections: 5,
            decoration: InputDecoration(
              hintText: 'Search tags...',
              prefixIcon: const Icon(Icons.tag),
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            itemBuilder: (context, tag) => _TagListTile(tag: tag),
            selectedItemBuilder: (context, tag, onRemove) =>
                _TagChip(tag: tag, onRemove: onRemove),
            selectedItemsWrap: true,
            selectedItemsSpacing: 8,
            selectedItemsRunSpacing: 8,
            onSelected: (tags, _) {
              setState(() => _selectedTags = tags);
            },
          ),
          const SizedBox(height: 8),
          Text(
            'Select up to 5 tags • ${_selectedTags.length}/5 selected',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.disabledColor,
            ),
          ),
          const SizedBox(height: 24),

          // Popular Tags
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Popular Tags',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text('See all'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _popularTags.map((tag) {
              final isSelected = _selectedTags.any((t) => t.id == tag.id);
              return ActionChip(
                avatar: Icon(
                  Icons.tag,
                  size: 16,
                  color: isSelected ? Colors.white : Color(tag.color),
                ),
                label: Text(tag.name),
                backgroundColor:
                    isSelected ? Color(tag.color) : Color(tag.color).withOpacity(0.1),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Color(tag.color),
                  fontWeight: FontWeight.w500,
                ),
                onPressed: () {
                  setState(() {
                    if (isSelected) {
                      _selectedTags.removeWhere((t) => t.id == tag.id);
                    } else if (_selectedTags.length < 5) {
                      _selectedTags.add(tag);
                    }
                  });
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  static Future<List<Tag>> _searchTags(PaginationRequest request) async {
    await Future.delayed(const Duration(milliseconds: 200));

    final query = request.searchQuery?.toLowerCase() ?? '';
    if (query.isEmpty) return _allTags;

    return _allTags.where((t) => t.name.toLowerCase().contains(query)).toList();
  }

  static final _allTags = [
    const Tag(id: 'flutter', name: 'Flutter', color: 0xFF0175C2, usageCount: 1250),
    const Tag(id: 'dart', name: 'Dart', color: 0xFF00B4AB, usageCount: 980),
    const Tag(id: 'mobile', name: 'Mobile Development', color: 0xFFE91E63, usageCount: 850),
    const Tag(id: 'ui', name: 'UI/UX Design', color: 0xFF9C27B0, usageCount: 720),
    const Tag(id: 'web', name: 'Web Development', color: 0xFFFF9800, usageCount: 650),
    const Tag(id: 'api', name: 'API', color: 0xFF4CAF50, usageCount: 540),
    const Tag(id: 'tutorial', name: 'Tutorial', color: 0xFF2196F3, usageCount: 480),
    const Tag(id: 'tips', name: 'Tips & Tricks', color: 0xFFFF5722, usageCount: 420),
    const Tag(id: 'performance', name: 'Performance', color: 0xFF795548, usageCount: 380),
    const Tag(id: 'testing', name: 'Testing', color: 0xFF607D8B, usageCount: 320),
    const Tag(id: 'animation', name: 'Animation', color: 0xFFE040FB, usageCount: 290),
    const Tag(id: 'state', name: 'State Management', color: 0xFF00BCD4, usageCount: 260),
  ];

  static final _popularTags = _allTags.take(6).toList();
}

class _TagListTile extends StatelessWidget {
  final Tag tag;

  const _TagListTile({required this.tag});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Color(tag.color).withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.tag,
          color: Color(tag.color),
          size: 20,
        ),
      ),
      title: Text(
        tag.name,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '${tag.usageCount}',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final Tag tag;
  final VoidCallback onRemove;

  const _TagChip({required this.tag, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(
        Icons.tag,
        size: 16,
        color: Color(tag.color),
      ),
      label: Text(tag.name),
      backgroundColor: Color(tag.color).withOpacity(0.1),
      labelStyle: TextStyle(
        color: Color(tag.color),
        fontWeight: FontWeight.w500,
      ),
      deleteIcon: Icon(Icons.close, size: 16, color: Color(tag.color)),
      onDeleted: onRemove,
    );
  }
}

// ============================================================================
// 5. Employee Directory
// ============================================================================
class _EmployeeDirectoryExample extends StatefulWidget {
  const _EmployeeDirectoryExample();

  @override
  State<_EmployeeDirectoryExample> createState() =>
      _EmployeeDirectoryExampleState();
}

class _EmployeeDirectoryExampleState extends State<_EmployeeDirectoryExample> {
  User? _selectedEmployee;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.badge,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Employee Directory',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${_employees.length} employees',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.disabledColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Search
                SmartSearchDropdown<User, String>.withProvider(
                  request: const PaginationRequest(page: 1, pageSize: 15),
                  provider: PaginationProvider.future(_searchEmployees),
                  searchRequestBuilder: (query) => PaginationRequest(
                    page: 1,
                    pageSize: 15,
                    searchQuery: query,
                  ),
                  keyExtractor: (u) => u.id,
                  searchConfig: const SmartSearchConfig(
                    debounceDelay: Duration(milliseconds: 300),
                    fetchOnInit: true,
                  ),
                  overlayConfig: const SmartSearchOverlayConfig(
                    maxHeight: 350,
                    borderRadius: 16,
                    elevation: 8,
                  ),
                  showSelected: true,
                  decoration: InputDecoration(
                    hintText: 'Search by name, email, or department...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.filter_list),
                      onPressed: () {},
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  itemBuilder: (context, user) =>
                      _EmployeeListTile(user: user),
                  selectedItemBuilder: (context, user, onClear) =>
                      _SelectedEmployeeTile(user: user, onClear: onClear),
                  onSelected: (user, _) {
                    setState(() => _selectedEmployee = user);
                  },
                  headerBuilder: (context) => Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(
                          Icons.history,
                          size: 18,
                          color: theme.disabledColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Search Results',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.disabledColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Employee Profile Card
          if (_selectedEmployee != null) ...[
            _EmployeeProfileCard(employee: _selectedEmployee!),
          ] else ...[
            // Quick Access Section
            Text(
              'Quick Access',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                _QuickAccessCard(
                  icon: Icons.engineering,
                  title: 'Engineering',
                  count: 45,
                  color: Colors.blue,
                ),
                _QuickAccessCard(
                  icon: Icons.palette,
                  title: 'Design',
                  count: 12,
                  color: Colors.purple,
                ),
                _QuickAccessCard(
                  icon: Icons.campaign,
                  title: 'Marketing',
                  count: 18,
                  color: Colors.orange,
                ),
                _QuickAccessCard(
                  icon: Icons.support_agent,
                  title: 'Support',
                  count: 25,
                  color: Colors.green,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static Future<List<User>> _searchEmployees(PaginationRequest request) async {
    await Future.delayed(const Duration(milliseconds: 400));

    final query = request.searchQuery?.toLowerCase() ?? '';
    if (query.isEmpty) return _employees;

    return _employees
        .where((u) =>
            u.name.toLowerCase().contains(query) ||
            u.email.toLowerCase().contains(query) ||
            u.department.toLowerCase().contains(query) ||
            u.role.toLowerCase().contains(query))
        .toList();
  }

  static final _employees = List.generate(
    20,
    (i) => User(
      id: 'emp_$i',
      name: _names[i % _names.length],
      email: '${_names[i % _names.length].toLowerCase().replaceAll(' ', '.')}@company.com',
      avatar: '',
      department: _departments[i % _departments.length],
      role: _roles[i % _roles.length],
      isOnline: Random().nextBool(),
      lastSeen: DateTime.now().subtract(Duration(minutes: Random().nextInt(120))),
    ),
  );

  static const _names = [
    'John Smith',
    'Sarah Johnson',
    'Michael Chen',
    'Emily Williams',
    'David Brown',
    'Jessica Davis',
    'Christopher Wilson',
    'Amanda Taylor',
    'Matthew Anderson',
    'Ashley Martinez',
  ];

  static const _departments = [
    'Engineering',
    'Design',
    'Marketing',
    'Sales',
    'Product',
    'HR',
    'Finance',
    'Support',
  ];

  static const _roles = [
    'Software Engineer',
    'Senior Developer',
    'UI/UX Designer',
    'Product Manager',
    'Team Lead',
    'Analyst',
    'Coordinator',
    'Specialist',
  ];
}

class _EmployeeListTile extends StatelessWidget {
  final User user;

  const _EmployeeListTile({required this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initials = user.name.split(' ').map((n) => n[0]).take(2).join();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: _getColor(user.department),
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (user.isOnline)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.scaffoldBackgroundColor,
                        width: 2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user.role,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.disabledColor,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _getColor(user.department).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              user.department,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: _getColor(user.department),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getColor(String department) {
    switch (department) {
      case 'Engineering':
        return Colors.blue;
      case 'Design':
        return Colors.purple;
      case 'Marketing':
        return Colors.orange;
      case 'Sales':
        return Colors.green;
      case 'Product':
        return Colors.teal;
      case 'HR':
        return Colors.pink;
      case 'Finance':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }
}

class _SelectedEmployeeTile extends StatelessWidget {
  final User user;
  final VoidCallback onClear;

  const _SelectedEmployeeTile({required this.user, required this.onClear});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initials = user.name.split(' ').map((n) => n[0]).take(2).join();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: theme.colorScheme.primary,
            child: Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  user.name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${user.role} • ${user.department}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onClear,
            icon: const Icon(Icons.close),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _EmployeeProfileCard extends StatelessWidget {
  final User employee;

  const _EmployeeProfileCard({required this.employee});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initials = employee.name.split(' ').map((n) => n[0]).take(2).join();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.dividerColor),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _getColor(employee.department),
                  _getColor(employee.department).withOpacity(0.7),
                ],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: Colors.white,
                  child: Text(
                    initials,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _getColor(employee.department),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        employee.name,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        employee.role,
                        style: const TextStyle(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                if (employee.isOnline)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.circle,
                          size: 8,
                          color: Colors.white,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Online',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _ProfileInfoRow(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  value: employee.email,
                ),
                const SizedBox(height: 12),
                _ProfileInfoRow(
                  icon: Icons.business_outlined,
                  label: 'Department',
                  value: employee.department,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.email),
                        label: const Text('Email'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.chat),
                        label: const Text('Message'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getColor(String department) {
    switch (department) {
      case 'Engineering':
        return Colors.blue;
      case 'Design':
        return Colors.purple;
      case 'Marketing':
        return Colors.orange;
      case 'Sales':
        return Colors.green;
      case 'Product':
        return Colors.teal;
      case 'HR':
        return Colors.pink;
      case 'Finance':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }
}

class _ProfileInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: theme.disabledColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.disabledColor,
                ),
              ),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuickAccessCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final int count;
  final Color color;

  const _QuickAccessCard({
    required this.icon,
    required this.title,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor),
      ),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const Spacer(),
                  Text(
                    '$count',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
