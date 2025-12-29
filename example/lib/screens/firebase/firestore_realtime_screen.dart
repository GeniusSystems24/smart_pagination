import 'dart:async';
import 'package:flutter/material.dart';
import 'package:smart_pagination/pagination.dart';

/// Mock Message for real-time example
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
}

/// Simulates Firestore real-time updates with snapshots
class FirestoreRealtimeScreen extends StatefulWidget {
  const FirestoreRealtimeScreen({super.key});

  @override
  State<FirestoreRealtimeScreen> createState() =>
      _FirestoreRealtimeScreenState();
}

class _FirestoreRealtimeScreenState extends State<FirestoreRealtimeScreen> {
  final List<RealtimeMessage> _messages = [];
  final _streamController = StreamController<List<RealtimeMessage>>.broadcast();
  Timer? _simulationTimer;
  int _messageCount = 0;

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
    'Let\'s schedule a meeting',
    'Documentation is updated',
    'Tests are passing now ✅',
    'Found a bug, working on fix',
    'Deploy is complete 🚀',
  ];

  @override
  void initState() {
    super.initState();
    _initializeMessages();
    _startRealtimeSimulation();
  }

  void _initializeMessages() {
    // Create initial messages
    for (int i = 0; i < 10; i++) {
      _messages.add(_generateMessage());
    }
    _streamController.add(List.from(_messages));
  }

  void _startRealtimeSimulation() {
    // Simulate new messages arriving every 3-5 seconds
    _simulationTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted) {
        _addNewMessage();
      }
    });
  }

  void _addNewMessage() {
    final newMessage = _generateMessage();
    _messages.insert(0, newMessage);
    _streamController.add(List.from(_messages));
  }

  RealtimeMessage _generateMessage() {
    final user = _sampleUsers[_messageCount % _sampleUsers.length];
    final content = _sampleMessages[_messageCount % _sampleMessages.length];
    _messageCount++;

    return RealtimeMessage(
      id: 'msg_$_messageCount',
      userName: user,
      content: content,
      avatarUrl: 'https://i.pravatar.cc/150?u=$user',
      timestamp: DateTime.now(),
    );
  }

  Stream<List<RealtimeMessage>> streamMessages(PaginationRequest request) {
    return _streamController.stream;
  }

  String _formatTime(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }

  @override
  void dispose() {
    _simulationTimer?.cancel();
    _streamController.close();
    super.dispose();
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
              color: Colors.green,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, size: 8, color: Colors.white),
                SizedBox(width: 4),
                Text(
                  'LIVE',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
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
                    'New messages appear automatically every ~4 seconds',
                    style:
                        TextStyle(color: Colors.green.shade700, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),

          // Messages list
          Expanded(
            child: SmartPagination.listViewWithProvider<RealtimeMessage>(
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
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewMessage,
        tooltip: 'Add message',
        child: const Icon(Icons.add),
      ),
    );
  }
}
