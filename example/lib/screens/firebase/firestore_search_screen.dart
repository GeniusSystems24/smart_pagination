import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:smart_pagination/pagination.dart';

/// Model for Firestore User document
class FirestoreUser {
  final String id;
  final String name;
  final String email;
  final String avatarUrl;
  final String department;
  final bool isOnline;
  final DateTime lastActive;

  FirestoreUser({
    required this.id,
    required this.name,
    required this.email,
    required this.avatarUrl,
    required this.department,
    required this.isOnline,
    required this.lastActive,
  });

  factory FirestoreUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FirestoreUser(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      avatarUrl: data['avatarUrl'] ?? '',
      department: data['department'] ?? 'General',
      isOnline: data['isOnline'] ?? false,
      lastActive: (data['lastActive'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Searchable fields for client-side filtering
  bool matchesQuery(String query) {
    final lowerQuery = query.toLowerCase();
    return name.toLowerCase().contains(lowerQuery) ||
        email.toLowerCase().contains(lowerQuery) ||
        department.toLowerCase().contains(lowerQuery);
  }
}

/// Demonstrates Firestore search with SmartSearchDropdown
class FirestoreSearchScreen extends StatefulWidget {
  const FirestoreSearchScreen({super.key});

  @override
  State<FirestoreSearchScreen> createState() => _FirestoreSearchScreenState();
}

class _FirestoreSearchScreenState extends State<FirestoreSearchScreen> {
  bool _isFirebaseInitialized = false;
  String? _initError;
  FirestoreUser? _selectedUser;

  @override
  void initState() {
    super.initState();
    _initializeFirebase();
  }

  Future<void> _initializeFirebase() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      setState(() {
        _isFirebaseInitialized = true;
      });
    } catch (e) {
      setState(() {
        _initError = e.toString();
      });
    }
  }

  /// Searches users from Firestore
  ///
  /// Note: Firestore doesn't support native full-text search.
  /// For production apps, consider:
  /// - Algolia or Typesense integration
  /// - Firebase Extensions for search
  /// - Client-side filtering (shown here for simplicity)
  Future<List<FirestoreUser>> searchUsers(PaginationRequest request) async {
    final firestore = FirebaseFirestore.instance;
    final pageSize = request.pageSize ?? 10;
    final query = request.searchQuery?.toLowerCase() ?? '';

    // Fetch users from Firestore
    QuerySnapshot<Map<String, dynamic>> snapshot;

    if (query.isEmpty) {
      // If no search query, get users ordered by lastActive
      snapshot = await firestore
          .collection('users')
          .orderBy('lastActive', descending: true)
          .limit(pageSize * 2)
          .get();
    } else {
      // Firestore prefix search using startAt/endAt
      snapshot = await firestore
          .collection('users')
          .orderBy('name')
          .startAt([query.substring(0, 1).toUpperCase() + query.substring(1)])
          .endAt(['${query.substring(0, 1).toUpperCase() + query.substring(1)}\uf8ff'])
          .limit(pageSize * 2)
          .get();
    }

    // Convert to model and filter client-side for better matching
    var users = snapshot.docs
        .map((doc) => FirestoreUser.fromFirestore(doc))
        .toList();

    // Apply client-side filtering for better search
    if (query.isNotEmpty) {
      users = users.where((user) => user.matchesQuery(query)).toList();
    }

    // Apply pagination
    final page = request.page;
    final startIndex = (page - 1) * pageSize;
    final endIndex = (startIndex + pageSize).clamp(0, users.length);

    if (startIndex >= users.length) {
      return [];
    }

    return users.sublist(startIndex, endIndex);
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
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(context),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // Show error if Firebase initialization failed
    if (_initError != null) {
      return _buildFirebaseError();
    }

    // Show loading while initializing
    if (!_isFirebaseInitialized) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Initializing Firebase...'),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Info banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.search, color: Colors.purple.shade700, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Search users from Firestore with SmartSearchDropdown',
                    style: TextStyle(color: Colors.purple.shade700, fontSize: 13),
                  ),
                ),
              ],
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
          SmartSearchDropdown<FirestoreUser, FirestoreUser>.withProvider(
            request: const PaginationRequest(page: 1, pageSize: 10),
            provider: PaginationProvider.future(searchUsers),
            showClearButton: true,
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
            decoration: const InputDecoration(
              hintText: 'Type to search users...',
              prefixIcon: Icon(Icons.person_search),
            ),
            showSelected: true,
            itemBuilder: (context, user) => ListTile(
              leading: Stack(
                children: [
                  CircleAvatar(
                    backgroundImage: NetworkImage(user.avatarUrl),
                    onBackgroundImageError: (_, __) {},
                    child: Text(user.name.isNotEmpty ? user.name[0] : '?'),
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
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  user.department,
                  style: TextStyle(
                    color: Colors.purple.shade700,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            onSelected: (user, _) {
              setState(() => _selectedUser = user);
            },
            emptyBuilder: (context) => Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.person_off, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 8),
                  const Text('No users found'),
                  const SizedBox(height: 4),
                  Text(
                    'Add users to your "users" collection',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
            ),
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
                          backgroundImage: NetworkImage(_selectedUser!.avatarUrl),
                          onBackgroundImageError: (_, __) {},
                          child: Text(
                            _selectedUser!.name.isNotEmpty ? _selectedUser!.name[0] : '?',
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
                        color: Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _selectedUser!.department,
                        style: TextStyle(color: Colors.purple.shade700),
                      ),
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

          // Search info
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lightbulb, color: Colors.amber.shade700, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Search Implementation Note',
                      style: TextStyle(
                        color: Colors.amber.shade900,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Firestore doesn\'t support native full-text search. '
                  'This example uses prefix matching (startAt/endAt) with '
                  'client-side filtering. For production apps, consider:\n\n'
                  '• Algolia or Typesense integration\n'
                  '• Firebase Extensions for search\n'
                  '• Cloud Functions for server-side filtering',
                  style: TextStyle(color: Colors.amber.shade900, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFirebaseError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: Colors.orange.shade300),
            const SizedBox(height: 24),
            const Text(
              'Firebase Not Configured',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'To use this example, configure Firebase:\n\n'
              '1. Create a Firebase project\n'
              '2. Add your app to the project\n'
              '3. Run: flutterfire configure',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _initError ?? 'Unknown error',
                style: TextStyle(color: Colors.red.shade700, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Firestore Search'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('This example demonstrates:'),
            SizedBox(height: 12),
            Text('• SmartSearchDropdown with Firestore'),
            Text('• Prefix-based search (startAt/endAt)'),
            Text('• Client-side filtering for better matching'),
            Text('• User selection and display'),
            Text('• Online status indicators'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
