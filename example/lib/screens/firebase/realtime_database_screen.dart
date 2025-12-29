import 'dart:async';
import 'package:flutter/material.dart';
import 'package:smart_pagination/pagination.dart';

/// Mock Post for Realtime Database example
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
}

/// Simulates Firebase Realtime Database pagination
class RealtimeDatabaseScreen extends StatefulWidget {
  const RealtimeDatabaseScreen({super.key});

  @override
  State<RealtimeDatabaseScreen> createState() => _RealtimeDatabaseScreenState();
}

class _RealtimeDatabaseScreenState extends State<RealtimeDatabaseScreen> {
  // Simulated RTDB posts
  final List<RTDBPost> _allPosts = List.generate(
    50,
    (index) => RTDBPost(
      id: 'post_$index',
      author: ['John Doe', 'Jane Smith', 'Mike Wilson', 'Sarah Connor'][
          index % 4],
      content: [
        'Just finished a great workout session! 💪',
        'Beautiful sunset today at the beach 🌅',
        'Working on some exciting new features',
        'Coffee and code - perfect morning ☕',
        'Can\'t believe how fast this week went by',
        'Learning something new every day',
        'Team meeting was super productive today',
        'Weekend plans: hiking and relaxation',
      ][index % 8],
      likes: (index * 7 + 3) % 100,
      comments: (index * 3 + 1) % 20,
      timestamp: DateTime.now().subtract(Duration(hours: index * 2)),
    ),
  );

  /// Simulates RTDB limitToLast + endBefore pagination
  Future<List<RTDBPost>> fetchPosts(PaginationRequest request) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 600));

    final pageSize = request.pageSize ?? 20;
    final page = request.page;

    // Calculate pagination (simulating limitToLast + endBefore)
    final startIndex = (page - 1) * pageSize;
    final endIndex = (startIndex + pageSize).clamp(0, _allPosts.length);

    if (startIndex >= _allPosts.length) {
      return [];
    }

    return _allPosts.sublist(startIndex, endIndex);
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
      body: Column(
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
                    'Simulated Firebase RTDB with limitToLast pagination',
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
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Author row
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.primaries[
                                  post.author.hashCode % Colors.primaries.length],
                              child: Text(
                                post.author[0],
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
                        Text(
                          post.content,
                          style: const TextStyle(fontSize: 15),
                        ),

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
                            _buildActionButton(
                              Icons.share_outlined,
                              'Share',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
              loadingWidget: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading from Realtime Database...'),
                  ],
                ),
              ),
            ),
          ),
        ],
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
