import 'dart:async';
import 'package:flutter/material.dart';
import 'package:smart_pagination/pagination.dart';

/// Mock User for Firestore search example
class FirestoreUser {
  final String id;
  final String name;
  final String email;
  final String avatarUrl;
  final bool isOnline;
  final DateTime lastActive;

  FirestoreUser({
    required this.id,
    required this.name,
    required this.email,
    required this.avatarUrl,
    required this.isOnline,
    required this.lastActive,
  });

  /// Generate search keywords for Firestore array-contains queries
  List<String> get searchKeywords {
    final keywords = <String>[];
    final nameLower = name.toLowerCase();
    for (int i = 1; i <= nameLower.length; i++) {
      keywords.add(nameLower.substring(0, i));
    }
    return keywords;
  }
}

/// Simulates Firestore search with SmartSearchDropdown
class FirestoreSearchScreen extends StatefulWidget {
  const FirestoreSearchScreen({super.key});

  @override
  State<FirestoreSearchScreen> createState() => _FirestoreSearchScreenState();
}

class _FirestoreSearchScreenState extends State<FirestoreSearchScreen> {
  FirestoreUser? _selectedUser;

  // Simulated Firestore users collection
  final List<FirestoreUser> _allUsers = [
    FirestoreUser(
      id: '1',
      name: 'Alice Johnson',
      email: 'alice@example.com',
      avatarUrl: 'https://i.pravatar.cc/150?u=alice',
      isOnline: true,
      lastActive: DateTime.now(),
    ),
    FirestoreUser(
      id: '2',
      name: 'Bob Smith',
      email: 'bob@example.com',
      avatarUrl: 'https://i.pravatar.cc/150?u=bob',
      isOnline: false,
      lastActive: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    FirestoreUser(
      id: '3',
      name: 'Charlie Brown',
      email: 'charlie@example.com',
      avatarUrl: 'https://i.pravatar.cc/150?u=charlie',
      isOnline: true,
      lastActive: DateTime.now(),
    ),
    FirestoreUser(
      id: '4',
      name: 'Diana Prince',
      email: 'diana@example.com',
      avatarUrl: 'https://i.pravatar.cc/150?u=diana',
      isOnline: false,
      lastActive: DateTime.now().subtract(const Duration(days: 1)),
    ),
    FirestoreUser(
      id: '5',
      name: 'Edward Norton',
      email: 'edward@example.com',
      avatarUrl: 'https://i.pravatar.cc/150?u=edward',
      isOnline: true,
      lastActive: DateTime.now(),
    ),
    FirestoreUser(
      id: '6',
      name: 'Fiona Apple',
      email: 'fiona@example.com',
      avatarUrl: 'https://i.pravatar.cc/150?u=fiona',
      isOnline: false,
      lastActive: DateTime.now().subtract(const Duration(hours: 5)),
    ),
    FirestoreUser(
      id: '7',
      name: 'George Lucas',
      email: 'george@example.com',
      avatarUrl: 'https://i.pravatar.cc/150?u=george',
      isOnline: true,
      lastActive: DateTime.now(),
    ),
    FirestoreUser(
      id: '8',
      name: 'Hannah Montana',
      email: 'hannah@example.com',
      avatarUrl: 'https://i.pravatar.cc/150?u=hannah',
      isOnline: false,
      lastActive: DateTime.now().subtract(const Duration(hours: 12)),
    ),
  ];

  /// Simulates Firestore search with array-contains
  Future<List<FirestoreUser>> searchUsers(PaginationRequest request) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    final query = request.searchQuery?.toLowerCase() ?? '';

    if (query.isEmpty) {
      // Return recent users when no search query
      final sorted = List<FirestoreUser>.from(_allUsers)
        ..sort((a, b) => b.lastActive.compareTo(a.lastActive));
      return sorted.take(request.pageSize ?? 10).toList();
    }

    // Simulate array-contains search
    return _allUsers
        .where((user) => user.searchKeywords.any((kw) => kw.startsWith(query)))
        .take(request.pageSize ?? 10)
        .toList();
  }

  String _formatLastActive(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Active now';
    if (diff.inHours < 1) return 'Active ${diff.inMinutes}m ago';
    if (diff.inDays < 1) return 'Active ${diff.inHours}h ago';
    return 'Active ${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firestore Search'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info card
            Card(
              color: Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Simulates Firestore array-contains query for prefix search',
                        style: TextStyle(color: Colors.orange.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Search label
            const Text(
              'Search Users',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Search dropdown
            SmartSearchDropdown<FirestoreUser>.withProvider(
              request: const PaginationRequest(page: 1, pageSize: 10),
              provider: PaginationProvider.future(searchUsers),
              searchRequestBuilder: (query) => PaginationRequest(
                page: 1,
                pageSize: 10,
                searchQuery: query,
              ),
              searchConfig: const SmartSearchConfig(
                debounceDelay: Duration(milliseconds: 300),
                minSearchLength: 0,
                searchOnEmpty: true,
              ),
              overlayConfig: const SmartSearchOverlayConfig(
                maxHeight: 300,
              ),
              hintText: 'Type to search users...',
              showSelected: true,
              itemBuilder: (context, user) => ListTile(
                leading: Stack(
                  children: [
                    CircleAvatar(
                      backgroundImage: NetworkImage(user.avatarUrl),
                      onBackgroundImageError: (_, __) {},
                      child: Text(user.name[0]),
                    ),
                    if (user.isOnline)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                title: Text(user.name),
                subtitle: Text(user.email),
                trailing: user.isOnline
                    ? null
                    : Text(
                        _formatLastActive(user.lastActive),
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 11,
                        ),
                      ),
              ),
              onItemSelected: (user) {
                setState(() => _selectedUser = user);
              },
            ),

            // Selected user card
            if (_selectedUser != null) ...[
              const SizedBox(height: 32),
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 48,
                            backgroundImage:
                                NetworkImage(_selectedUser!.avatarUrl),
                            onBackgroundImageError: (_, __) {},
                            child: Text(
                              _selectedUser!.name[0],
                              style: const TextStyle(fontSize: 32),
                            ),
                          ),
                          if (_selectedUser!.isOnline)
                            Positioned(
                              right: 4,
                              bottom: 4,
                              child: Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 3,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _selectedUser!.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _selectedUser!.email,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _selectedUser!.isOnline
                              ? Colors.green.shade100
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _selectedUser!.isOnline
                              ? 'Online'
                              : _formatLastActive(_selectedUser!.lastActive),
                          style: TextStyle(
                            color: _selectedUser!.isOnline
                                ? Colors.green.shade700
                                : Colors.grey.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.message),
                            label: const Text('Message'),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.person),
                            label: const Text('Profile'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
