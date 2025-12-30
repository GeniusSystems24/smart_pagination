import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:smart_pagination/pagination.dart';

/// Model for Firestore Message document
class RealtimeMessage {
  final String id;
  final String userName;
  final String content;
  final String avatarUrl;
  final DateTime timestamp;

  RealtimeMessage({
    required this.id,
    required this.userName,
    required this.content,
    required this.avatarUrl,
    required this.timestamp,
  });

  factory RealtimeMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RealtimeMessage(
      id: doc.id,
      userName: data['userName'] ?? 'Unknown',
      content: data['content'] ?? '',
      avatarUrl: data['avatarUrl'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userName': userName,
      'content': content,
      'avatarUrl': avatarUrl,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}

/// Demonstrates Firestore real-time updates with snapshots
class FirestoreRealtimeScreen extends StatefulWidget {
  const FirestoreRealtimeScreen({super.key});

  @override
  State<FirestoreRealtimeScreen> createState() =>
      _FirestoreRealtimeScreenState();
}

class _FirestoreRealtimeScreenState extends State<FirestoreRealtimeScreen> {
  bool _isFirebaseInitialized = false;
  String? _initError;

  final List<String> _sampleUsers = [
    'Alice',
    'Bob',
    'Charlie',
    'Diana',
    'Eve',
    'Frank',
  ];

  final List<String> _sampleMessages = [
    'Hello everyone! 👋',
    'How is the project going?',
    'Just pushed the latest changes',
    'Can someone review my PR?',
    'Great work on the new feature!',
  ];

  int _messageIndex = 0;

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

  /// Streams messages from Firestore in real-time
  Stream<List<RealtimeMessage>> streamMessages(PaginationRequest request) {
    final firestore = FirebaseFirestore.instance;
    final pageSize = request.pageSize ?? 50;

    return firestore
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(pageSize)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RealtimeMessage.fromFirestore(doc))
            .toList());
  }

  /// Adds a new message to Firestore
  Future<void> _addNewMessage() async {
    if (!_isFirebaseInitialized) return;

    final user = _sampleUsers[_messageIndex % _sampleUsers.length];
    final content = _sampleMessages[_messageIndex % _sampleMessages.length];
    _messageIndex++;

    final message = RealtimeMessage(
      id: '',
      userName: user,
      content: content,
      avatarUrl: 'https://i.pravatar.cc/150?u=$user',
      timestamp: DateTime.now(),
    );

    try {
      await FirebaseFirestore.instance
          .collection('messages')
          .add(message.toFirestore());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding message: $e')),
        );
      }
    }
  }

  String _formatTime(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firestore Real-time'),
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _isFirebaseInitialized ? Colors.green : Colors.grey,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.circle,
                  size: 8,
                  color: _isFirebaseInitialized ? Colors.white : Colors.grey.shade300,
                ),
                const SizedBox(width: 4),
                Text(
                  _isFirebaseInitialized ? 'LIVE' : 'OFFLINE',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: _isFirebaseInitialized
          ? FloatingActionButton(
              onPressed: _addNewMessage,
              tooltip: 'Add message',
              child: const Icon(Icons.add),
            )
          : null,
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
          color: Colors.green.shade50,
          child: Row(
            children: [
              Icon(Icons.sync, color: Colors.green.shade700, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Real-time Firestore snapshots - changes appear instantly',
                  style: TextStyle(color: Colors.green.shade700, fontSize: 13),
                ),
              ),
            ],
          ),
        ),

        // Messages list
        Expanded(
          child: SmartPagination<RealtimeMessage>.listViewWithProvider(
            request: const PaginationRequest(page: 1, pageSize: 50),
            provider: PaginationProvider.stream(streamMessages),
            itemBuilder: (context, items, index) {
              final message = items[index];
              final isNew = index == 0 &&
                  DateTime.now().difference(message.timestamp).inSeconds < 5;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                color: isNew ? Colors.green.shade50 : Colors.transparent,
                child: Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(message.avatarUrl),
                      onBackgroundImageError: (_, __) {},
                      child: Text(message.userName[0]),
                    ),
                    title: Row(
                      children: [
                        Text(
                          message.userName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatTime(message.timestamp),
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        ),
                        if (isNew) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'NEW',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(message.content),
                    ),
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
                  Text('Connecting to Firestore...'),
                ],
              ),
            ),
            firstPageEmptyBuilder: (context) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text('No messages yet'),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to add a message',
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
}
