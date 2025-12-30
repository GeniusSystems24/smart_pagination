import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:smart_pagination/pagination.dart';

/// Model for RTDB Post
class RTDBPost {
  final String id;
  final String author;
  final String content;
  final int likes;
  final int comments;
  final DateTime timestamp;

  RTDBPost({
    required this.id,
    required this.author,
    required this.content,
    required this.likes,
    required this.comments,
    required this.timestamp,
  });

  factory RTDBPost.fromRTDB(String key, Map<dynamic, dynamic> data) {
    return RTDBPost(
      id: key,
      author: data['author'] ?? 'Unknown',
      content: data['content'] ?? '',
      likes: data['likes'] ?? 0,
      comments: data['comments'] ?? 0,
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        data['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  Map<String, dynamic> toRTDB() {
    return {
      'author': author,
      'content': content,
      'likes': likes,
      'comments': comments,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }
}

/// Demonstrates Firebase Realtime Database pagination
class RealtimeDatabaseScreen extends StatefulWidget {
  const RealtimeDatabaseScreen({super.key});

  @override
  State<RealtimeDatabaseScreen> createState() => _RealtimeDatabaseScreenState();
}

class _RealtimeDatabaseScreenState extends State<RealtimeDatabaseScreen> {
  bool _isFirebaseInitialized = false;
  String? _initError;

  // Store last key for cursor-based pagination
  int? _lastTimestamp;

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

  /// Fetches posts from Firebase Realtime Database
  Future<List<RTDBPost>> fetchPosts(PaginationRequest request) async {
    final database = FirebaseDatabase.instance;
    final pageSize = request.pageSize ?? 10;

    // Build query with ordering
    Query query = database
        .ref('posts')
        .orderByChild('timestamp')
        .limitToLast(pageSize + 1); // Fetch one extra to check hasMore

    // Apply cursor if not first page
    if (request.page > 1 && _lastTimestamp != null) {
      query = database
          .ref('posts')
          .orderByChild('timestamp')
          .endBefore(_lastTimestamp)
          .limitToLast(pageSize + 1);
    }

    // Execute query
    final snapshot = await query.get();

    if (!snapshot.exists || snapshot.value == null) {
      return [];
    }

    // Parse data
    final data = Map<String, dynamic>.from(snapshot.value as Map);
    final posts = <RTDBPost>[];

    data.forEach((key, value) {
      posts.add(RTDBPost.fromRTDB(key, Map<dynamic, dynamic>.from(value)));
    });

    // Sort by timestamp descending (newest first)
    posts.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    // Store last item for next page cursor
    if (posts.length > pageSize) {
      final lastPost = posts.last;
      _lastTimestamp = lastPost.timestamp.millisecondsSinceEpoch;
      posts.removeLast(); // Remove the extra item
    }

    return posts;
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Realtime Database'),
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

    return Column(
      children: [
        // Info banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          color: Colors.amber.shade50,
          child: Row(
            children: [
              Icon(Icons.data_object, color: Colors.amber.shade700, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Firebase Realtime Database with limitToLast pagination',
                  style: TextStyle(color: Colors.amber.shade700, fontSize: 13),
                ),
              ),
            ],
          ),
        ),

        // Posts list
        Expanded(
          child: SmartPagination<RTDBPost>.listViewWithProvider(
            request: const PaginationRequest(page: 1, pageSize: 10),
            provider: PaginationProvider.future(fetchPosts),
            itemBuilder: (context, items, index) {
              final post = items[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Author row
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor:
                                Colors.primaries[post.author.hashCode %
                                    Colors.primaries.length],
                            child: Text(
                              post.author.isNotEmpty ? post.author[0] : '?',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  post.author,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  _timeAgo(post.timestamp),
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.more_horiz),
                            onPressed: () {},
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Content
                      Text(post.content, style: const TextStyle(fontSize: 15)),

                      const SizedBox(height: 12),

                      // Actions row
                      Row(
                        children: [
                          _buildActionButton(
                            Icons.thumb_up_outlined,
                            '${post.likes}',
                          ),
                          const SizedBox(width: 24),
                          _buildActionButton(
                            Icons.comment_outlined,
                            '${post.comments}',
                          ),
                          const SizedBox(width: 24),
                          _buildActionButton(Icons.share_outlined, 'Share'),
                        ],
                      ),
                    ],
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
                  Text('Loading from Realtime Database...'),
                ],
              ),
            ),
            firstPageEmptyBuilder: (context) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.article_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  const Text('No posts yet'),
                  const SizedBox(height: 8),
                  Text(
                    'Add posts to your "posts" node',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
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
              '2. Enable Realtime Database\n'
              '3. Add your app to the project\n'
              '4. Run: flutterfire configure',
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

  Widget _buildActionButton(IconData icon, String label) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Colors.grey.shade600),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
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
        title: const Text('Realtime Database'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('This example demonstrates:'),
            SizedBox(height: 12),
            Text('• Firebase Realtime Database integration'),
            Text('• limitToLast() for reverse pagination'),
            Text('• endBefore() for cursor navigation'),
            Text('• orderByChild() sorting'),
            Text('• Efficient nested data handling'),
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
