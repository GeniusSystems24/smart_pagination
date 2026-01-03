import 'package:flutter/material.dart';
import 'package:smart_pagination/pagination.dart';
import 'package:intl/intl.dart';
import 'package:tooltip_card/tooltip_card.dart';

import '../../models/message.dart';

/// Example screen demonstrating scroll navigation methods
/// (animateToIndex, animateFirstWhere, jumpToIndex, jumpFirstWhere)
/// with a chat-like UI using scrollview_observer.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late SmartPaginationCubit<Message> _cubit;
  late ScrollController _scrollController;
  late ListObserverController _observerController;
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  String _currentUser = 'You';
  int? _highlightedIndex;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _observerController = ListObserverController(controller: _scrollController);

    _cubit = SmartPaginationCubit<Message>(
      request: const PaginationRequest(page: 1, pageSize: 50),
      provider: PaginationProvider.future(_fetchMessages),
    );

    // Attach the observer controller to the cubit for scroll navigation
    _cubit.attachListObserverController(_observerController);
  }

  Future<List<Message>> _fetchMessages(PaginationRequest request) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final messages = <Message>[];
    final baseTime = DateTime.now().subtract(const Duration(days: 1));

    for (int i = 0; i < (request.pageSize ?? 20); i++) {
      final index = ((request.page - 1) * (request.pageSize ?? 20)) + i;
      final isCurrentUser = index % 3 == 0;
      final author = isCurrentUser ? 'You' : 'John Doe';

      messages.add(Message(
        id: 'msg_$index',
        content: _getSampleMessage(index),
        author: author,
        timestamp: baseTime.add(Duration(minutes: index * 5)),
        isRead: index < 10,
      ));
    }

    return messages;
  }

  String _getSampleMessage(int index) {
    final samples = [
      'Hey! How are you doing today?',
      'I just finished the project we discussed.',
      'Can you review my pull request when you get a chance?',
      'The meeting has been rescheduled to 3 PM.',
      'Thanks for your help with the bug fix!',
      'Did you see the latest updates?',
      'Let me know if you need any assistance.',
      'Great work on the presentation!',
      'I\'ll send you the documents shortly.',
      'Looking forward to our collaboration!',
      'The deployment was successful.',
      'Please check the error logs.',
      'New feature request from the client.',
      'Sprint review is tomorrow at 10 AM.',
      'Code review completed with comments.',
    ];
    return samples[index % samples.length];
  }

  @override
  void dispose() {
    _cubit.detachListObserverController();
    _cubit.close();
    _scrollController.dispose();
    _messageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    final newMessage = Message(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      content: _messageController.text.trim(),
      author: _currentUser,
      timestamp: DateTime.now(),
      isRead: true,
    );

    _cubit.insertEmit(newMessage, index: 0);
    _messageController.clear();

    // Scroll to the new message
    Future.delayed(const Duration(milliseconds: 100), () {
      _cubit.animateToIndex(0, alignment: 0.0);
    });
  }

  void _scrollToBottom() async {
    final items = _cubit.currentItems;
    if (items.isEmpty) return;

    await _cubit.animateToIndex(
      items.length - 1,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Scrolled to oldest message'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  void _scrollToTop() async {
    await _cubit.animateToIndex(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Scrolled to newest message'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  void _jumpToUnreadMessage() async {
    final success = await _cubit.animateFirstWhere(
      (message) => !message.isRead,
      duration: const Duration(milliseconds: 400),
      alignment: 0.3,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Found first unread message'
                : 'No unread messages found',
          ),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  void _searchAndScrollToMessage(String query) async {
    if (query.isEmpty) return;

    final success = await _cubit.animateFirstWhere(
      (message) => message.content.toLowerCase().contains(query.toLowerCase()),
      duration: const Duration(milliseconds: 400),
      alignment: 0.3,
    );

    final items = _cubit.currentItems;
    final index = items.indexWhere(
      (m) => m.content.toLowerCase().contains(query.toLowerCase()),
    );

    setState(() {
      _highlightedIndex = success ? index : null;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Found message at position ${index + 1}'
                : 'No matching message found',
          ),
          backgroundColor: success ? Colors.green : Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
    }

    // Clear highlight after 3 seconds
    if (success) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() => _highlightedIndex = null);
        }
      });
    }
  }

  void _jumpToIndex(int index) {
    final success = _cubit.jumpToIndex(index, alignment: 0.3);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Jumped to message #${index + 1}'
                : 'Could not jump to message #${index + 1}',
          ),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Search messages...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
                onSubmitted: _searchAndScrollToMessage,
              )
            : const Text('Chat Example'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _highlightedIndex = null;
                }
              });
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'top':
                  _scrollToTop();
                  break;
                case 'bottom':
                  _scrollToBottom();
                  break;
                case 'unread':
                  _jumpToUnreadMessage();
                  break;
                case 'middle':
                  final items = _cubit.currentItems;
                  if (items.isNotEmpty) {
                    _jumpToIndex(items.length ~/ 2);
                  }
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'top',
                child: ListTile(
                  leading: Icon(Icons.vertical_align_top),
                  title: Text('Scroll to Top'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'bottom',
                child: ListTile(
                  leading: Icon(Icons.vertical_align_bottom),
                  title: Text('Scroll to Bottom'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'unread',
                child: ListTile(
                  leading: Icon(Icons.mark_email_unread),
                  title: Text('Find Unread'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'middle',
                child: ListTile(
                  leading: Icon(Icons.vertical_align_center),
                  title: Text('Jump to Middle'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Feature description
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.indigo.withValues(alpha: 0.1),
            child: Row(
              children: [
                TooltipCard.builder(
                  beakEnabled: true,
                  placementSide: TooltipCardPlacementSide.bottom,
                  whenContentVisible: WhenContentVisible.onTap,
                  builder: (context, close) => Container(
                    padding: const EdgeInsets.all(12),
                    constraints: const BoxConstraints(maxWidth: 250),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'الدوال المستخدمة:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        _buildMethodInfo('animateToIndex', 'تحريك سلس للعنصر'),
                        _buildMethodInfo('jumpToIndex', 'انتقال مباشر للعنصر'),
                        _buildMethodInfo('animateFirstWhere', 'بحث وتحريك سلس'),
                        _buildMethodInfo('jumpFirstWhere', 'بحث وانتقال مباشر'),
                        _buildMethodInfo('scrollToIndex', 'تمرير مع خيار الحركة'),
                        _buildMethodInfo('scrollFirstWhere', 'بحث وتمرير مع خيار الحركة'),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: close,
                          child: const Text('إغلاق'),
                        ),
                      ],
                    ),
                  ),
                  child: const Icon(Icons.info_outline, color: Colors.indigo, size: 20),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'يوضح هذا المثال دوال التمرير مع tooltip_card و scrollview_observer. '
                    'اضغط مطولاً على أي رسالة لرؤية التفاصيل.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          // Quick jump buttons
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _QuickJumpChip(
                    label: 'Jump to #1',
                    icon: Icons.looks_one,
                    onPressed: () => _jumpToIndex(0),
                    tooltipMessage: 'انتقل مباشرة إلى أول رسالة باستخدام jumpToIndex',
                  ),
                  const SizedBox(width: 8),
                  _QuickJumpChip(
                    label: 'Jump to #10',
                    icon: Icons.looks_two,
                    onPressed: () => _jumpToIndex(9),
                    tooltipMessage: 'انتقل مباشرة إلى الرسالة رقم 10 باستخدام jumpToIndex',
                  ),
                  const SizedBox(width: 8),
                  _QuickJumpChip(
                    label: 'Jump to #25',
                    icon: Icons.format_list_numbered,
                    onPressed: () => _jumpToIndex(24),
                    tooltipMessage: 'انتقل مباشرة إلى الرسالة رقم 25 باستخدام jumpToIndex',
                  ),
                  const SizedBox(width: 8),
                  _QuickJumpChip(
                    label: 'Find "bug"',
                    icon: Icons.search,
                    onPressed: () => _searchAndScrollToMessage('bug'),
                    tooltipMessage: 'ابحث عن كلمة "bug" باستخدام animateFirstWhere',
                  ),
                  const SizedBox(width: 8),
                  _QuickJumpChip(
                    label: 'Find "meeting"',
                    icon: Icons.event,
                    onPressed: () => _searchAndScrollToMessage('meeting'),
                    tooltipMessage: 'ابحث عن كلمة "meeting" باستخدام animateFirstWhere',
                  ),
                ],
              ),
            ),
          ),

          const Divider(height: 1),

          // Messages list with ListViewObserver
          Expanded(
            child: ListViewObserver(
              controller: _observerController,
              child: SmartPagination<Message>.listViewWithCubit(
                cubit: _cubit,
                scrollController: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                reverse: false,
                itemBuilder: (context, items, index) {
                  final message = items[index];
                  final isHighlighted = _highlightedIndex == index;
                  return _MessageBubble(
                    message: message,
                    isCurrentUser: message.author == _currentUser,
                    isHighlighted: isHighlighted,
                    index: index,
                    onTap: () => _showMessageDetails(message, index),
                  );
                },
                firstPageLoadingBuilder: (context) => const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Colors.indigo),
                      SizedBox(height: 16),
                      Text('Loading messages...'),
                    ],
                  ),
                ),
                firstPageErrorBuilder: (context, error, retry) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      const Text('Failed to load messages'),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: retry,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
                firstPageEmptyBuilder: (context) => const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No messages yet'),
                      Text('Start a conversation!', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
                loadMoreLoadingBuilder: (context) => const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Message input
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FloatingActionButton(
                    onPressed: _sendMessage,
                    mini: true,
                    backgroundColor: Colors.indigo,
                    child: const Icon(Icons.send, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: TooltipCard.builder(
        beakEnabled: true,
        placementSide: TooltipCardPlacementSide.start,
        whenContentVisible: WhenContentVisible.onHover,
        builder: (context, close) => const Padding(
          padding: EdgeInsets.all(8),
          child: Text(
            'انتقل لأعلى (animateToIndex)',
            style: TextStyle(fontSize: 12),
          ),
        ),
        child: FloatingActionButton.small(
          onPressed: _scrollToTop,
          backgroundColor: Colors.indigo,
          child: const Icon(Icons.arrow_upward, color: Colors.white),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.miniEndFloat,
    );
  }

  Widget _buildMethodInfo(String method, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.indigo.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              method,
              style: const TextStyle(
                fontSize: 10,
                fontFamily: 'monospace',
                color: Colors.indigo,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              description,
              style: const TextStyle(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  void _showMessageDetails(Message message, int index) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: message.author == _currentUser
                      ? Colors.indigo
                      : Colors.grey,
                  child: Text(
                    message.author[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.author,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      DateFormat('MMM d, yyyy HH:mm').format(message.timestamp),
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(message.content),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Message #${index + 1}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                Row(
                  children: [
                    Icon(
                      message.isRead ? Icons.done_all : Icons.done,
                      size: 16,
                      color: message.isRead ? Colors.blue : Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      message.isRead ? 'Read' : 'Unread',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _cubit.animateToIndex(index, alignment: 0.3);
                  },
                  icon: const Icon(Icons.center_focus_strong),
                  label: const Text('Scroll to this'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickJumpChip extends StatelessWidget {
  const _QuickJumpChip({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.tooltipMessage,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltipMessage;

  @override
  Widget build(BuildContext context) {
    return TooltipCard.builder(
      beakEnabled: true,
      placementSide: TooltipCardPlacementSide.bottom,
      whenContentVisible: WhenContentVisible.onHover,
      builder: (context, close) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: const BoxConstraints(maxWidth: 200),
        child: Text(
          tooltipMessage ?? 'اضغط للانتقال إلى $label',
          style: const TextStyle(fontSize: 12),
        ),
      ),
      child: ActionChip(
        avatar: Icon(icon, size: 16),
        label: Text(label, style: const TextStyle(fontSize: 12)),
        onPressed: onPressed,
        backgroundColor: Colors.indigo.withValues(alpha: 0.1),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.isCurrentUser,
    required this.isHighlighted,
    required this.index,
    required this.onTap,
  });

  final Message message;
  final bool isCurrentUser;
  final bool isHighlighted;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bubbleContent = Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.7,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isCurrentUser ? Colors.indigo : Colors.grey[200],
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(isCurrentUser ? 16 : 4),
          bottomRight: Radius.circular(isCurrentUser ? 4 : 16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isCurrentUser)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                message.author,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
              ),
            ),
          Text(
            message.content,
            style: TextStyle(
              color: isCurrentUser ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                DateFormat('HH:mm').format(message.timestamp),
                style: TextStyle(
                  fontSize: 10,
                  color: isCurrentUser ? Colors.white70 : Colors.grey[600],
                ),
              ),
              if (isCurrentUser) ...[
                const SizedBox(width: 4),
                Icon(
                  message.isRead ? Icons.done_all : Icons.done,
                  size: 14,
                  color: message.isRead ? Colors.lightBlueAccent : Colors.white70,
                ),
              ],
            ],
          ),
        ],
      ),
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isHighlighted
            ? Colors.yellow.withValues(alpha: 0.3)
            : Colors.transparent,
      ),
      child: Row(
        mainAxisAlignment:
            isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isCurrentUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey[300],
              child: Text(
                message.author[0].toUpperCase(),
                style: const TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: TooltipCard.builder(
              beakEnabled: true,
              placementSide: isCurrentUser
                  ? TooltipCardPlacementSide.start
                  : TooltipCardPlacementSide.end,
              whenContentVisible: WhenContentVisible.onLongPress,
              modalBarrierEnabled: true,
              builder: (context, close) => _MessageTooltipContent(
                message: message,
                index: index,
                onClose: close,
                onScrollTo: onTap,
              ),
              child: GestureDetector(
                onTap: onTap,
                child: bubbleContent,
              ),
            ),
          ),
          if (isCurrentUser) const SizedBox(width: 8),
        ],
      ),
    );
  }
}

/// Tooltip content widget for message details
class _MessageTooltipContent extends StatelessWidget {
  const _MessageTooltipContent({
    required this.message,
    required this.index,
    required this.onClose,
    required this.onScrollTo,
  });

  final Message message;
  final int index;
  final VoidCallback onClose;
  final VoidCallback onScrollTo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      constraints: const BoxConstraints(maxWidth: 280),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.indigo.withValues(alpha: 0.2),
                child: Text(
                  message.author[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.indigo,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.author,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      DateFormat('MMM d, yyyy • HH:mm').format(message.timestamp),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Message preview
          Text(
            message.content,
            style: const TextStyle(fontSize: 13),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),

          // Status row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'رسالة #${index + 1}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[700],
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    message.isRead ? Icons.done_all : Icons.done,
                    size: 16,
                    color: message.isRead ? Colors.blue : Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    message.isRead ? 'مقروءة' : 'غير مقروءة',
                    style: TextStyle(
                      fontSize: 11,
                      color: message.isRead ? Colors.blue : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: onClose,
                child: const Text('إغلاق'),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: () {
                  onClose();
                  onScrollTo();
                },
                icon: const Icon(Icons.center_focus_strong, size: 18),
                label: const Text('انتقال'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
