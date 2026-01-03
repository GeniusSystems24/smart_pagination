import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback, Clipboard, ClipboardData;
import 'package:intl/intl.dart' show DateFormat;
// import 'package:flutter/services.dart';
import 'package:smart_pagination/pagination.dart';
// import 'package:intl/intl.dart';
import 'package:tooltip_card/tooltip_card.dart';

import '../../models/message.dart';

/// A realistic chat screen demonstrating scroll navigation methods
/// with proper reverse ListView and modern UI design.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  late SmartPaginationCubit<Message> _cubit;
  late ScrollController _scrollController;
  late ListObserverController _observerController;
  late AnimationController _fabAnimationController;

  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _messageFocusNode = FocusNode();

  static const String _currentUser = 'أنت';
  static const String _otherUser = 'أحمد محمد';

  int? _highlightedIndex;
  bool _isSearching = false;
  bool _showScrollToBottom = false;
  bool _isTyping = false;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    _observerController = ListObserverController(controller: _scrollController);

    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _cubit = SmartPaginationCubit<Message>(
      request: const PaginationRequest(page: 1, pageSize: 30),
      provider: PaginationProvider.future(_fetchMessages),
    );

    _cubit.attachListObserverController(_observerController);

    // Simulate typing indicator
    _simulateTyping();
  }

  void _onScroll() {
    final showButton = _scrollController.hasClients &&
        _scrollController.offset > 200;

    if (showButton != _showScrollToBottom) {
      setState(() => _showScrollToBottom = showButton);
      if (showButton) {
        _fabAnimationController.forward();
      } else {
        _fabAnimationController.reverse();
      }
    }
  }

  void _simulateTyping() {
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() => _isTyping = true);
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) setState(() => _isTyping = false);
        });
      }
    });
  }

  Future<List<Message>> _fetchMessages(PaginationRequest request) async {
    await Future.delayed(const Duration(milliseconds: 800));

    final messages = <Message>[];
    final now = DateTime.now();

    // Create realistic chat messages
    final sampleConversation = _getSampleConversation();

    for (int i = 0; i < (request.pageSize ?? 20); i++) {
      final index = ((request.page - 1) * (request.pageSize ?? 20)) + i;
      if (index >= sampleConversation.length * 3) break;

      final messageData = sampleConversation[index % sampleConversation.length];
      final isCurrentUser = messageData['isMe'] as bool;

      // Create timestamps going backwards in time
      final timestamp = now.subtract(Duration(
        minutes: index * 3 + (index ~/ 5) * 30, // Add gaps for realism
      ));

      messages.add(Message(
        id: 'msg_${request.page}_$index',
        content: messageData['text'] as String,
        author: isCurrentUser ? _currentUser : _otherUser,
        timestamp: timestamp,
        isRead: index > 5, // Recent messages are unread
      ));
    }

    // Update unread count
    _unreadCount = messages.where((m) => !m.isRead).length;

    return messages;
  }

  List<Map<String, dynamic>> _getSampleConversation() {
    return [
      {'text': 'مرحباً! كيف حالك اليوم؟ 👋', 'isMe': false},
      {'text': 'أهلاً أحمد! الحمد لله بخير، وأنت؟', 'isMe': true},
      {'text': 'الحمد لله، هل انتهيت من المشروع؟', 'isMe': false},
      {'text': 'نعم، أنهيته البارحة وأرسلته للمراجعة ✅', 'isMe': true},
      {'text': 'ممتاز! عمل رائع 👏', 'isMe': false},
      {'text': 'شكراً لك! هل لديك أي ملاحظات؟', 'isMe': true},
      {'text': 'سأراجعه اليوم وأخبرك', 'isMe': false},
      {'text': 'تمام، في انتظارك', 'isMe': true},
      {'text': 'بالمناسبة، الاجتماع تأجل للساعة 3 مساءً', 'isMe': false},
      {'text': 'حسناً، سأكون جاهزاً 📅', 'isMe': true},
      {'text': 'هل تحتاج مساعدة في التحضير؟', 'isMe': false},
      {'text': 'نعم، أرسل لي العرض التقديمي من فضلك', 'isMe': true},
      {'text': 'تم الإرسال على البريد 📧', 'isMe': false},
      {'text': 'وصل، شكراً جزيلاً!', 'isMe': true},
      {'text': 'عفواً! نتواصل لاحقاً', 'isMe': false},
      {'text': 'إن شاء الله، أراك في الاجتماع', 'isMe': true},
      {'text': 'هل رأيت التحديثات الجديدة في النظام؟', 'isMe': false},
      {'text': 'لا بعد، ما الجديد؟', 'isMe': true},
      {'text': 'أضافوا ميزة البحث المتقدم 🔍', 'isMe': false},
      {'text': 'رائع! سأجربها الآن', 'isMe': true},
    ];
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _cubit.detachListObserverController();
    _cubit.close();
    _scrollController.dispose();
    _messageController.dispose();
    _searchController.dispose();
    _messageFocusNode.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final newMessage = Message(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      content: text,
      author: _currentUser,
      timestamp: DateTime.now(),
      isRead: true,
    );

    _cubit.insertEmit(newMessage, index: 0);
    _messageController.clear();

    // Haptic feedback
    HapticFeedback.lightImpact();

    // Scroll to bottom (index 0 in reverse list)
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollToNewest();
    });

    // Simulate reply
    _simulateReply();
  }

  void _simulateReply() {
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;

      setState(() => _isTyping = true);

      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;

        setState(() => _isTyping = false);

        final replies = [
          'تمام 👍',
          'حسناً، فهمت',
          'شكراً للتوضيح',
          'سأتحقق من ذلك',
          'ممتاز!',
        ];

        final reply = Message(
          id: 'msg_reply_${DateTime.now().millisecondsSinceEpoch}',
          content: replies[DateTime.now().second % replies.length],
          author: _otherUser,
          timestamp: DateTime.now(),
          isRead: false,
        );

        _cubit.insertEmit(reply, index: 0);
        setState(() => _unreadCount++);
      });
    });
  }

  Future<void> _scrollToNewest() async {
    final success = await _cubit.animateToIndex(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );

    if (success && mounted) {
      setState(() => _unreadCount = 0);
    }
  }

  Future<void> _scrollToOldest() async {
    final items = _cubit.currentItems;
    if (items.isEmpty) return;

    await _cubit.animateToIndex(
      items.length - 1,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _jumpToUnread() async {
    final success = await _cubit.animateFirstWhere(
      (message) => !message.isRead,
      duration: const Duration(milliseconds: 400),
      alignment: 0.3,
    );

    if (mounted) {
      _showSnackBar(
        success ? 'تم العثور على أول رسالة غير مقروءة' : 'لا توجد رسائل غير مقروءة',
        success ? Colors.green : Colors.orange,
      );
    }
  }

  Future<void> _searchAndScroll(String query) async {
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
      _showSnackBar(
        success
            ? 'تم العثور على الرسالة رقم ${index + 1}'
            : 'لم يتم العثور على "$query"',
        success ? Colors.green : Colors.orange,
      );
    }

    if (success) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _highlightedIndex = null);
      });
    }
  }

  void _jumpToIndex(int index) {
    final success = _cubit.jumpToIndex(index, alignment: 0.3);

    if (mounted) {
      _showSnackBar(
        success
            ? 'تم الانتقال للرسالة #${index + 1}'
            : 'لا يمكن الانتقال للرسالة #${index + 1}',
        success ? Colors.teal : Colors.red,
      );
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textAlign: TextAlign.center),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B141A) : const Color(0xFFECE5DD),
      appBar: _buildAppBar(isDark),
      body: Column(
        children: [
          // Navigation toolbar
          _buildNavigationToolbar(isDark),

          // Chat messages
          Expanded(
            child: Stack(
              children: [
                // Background pattern
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0B141A) : const Color(0xFFECE5DD),
                    ),
                  ),
                ),

                // Messages list
                ListViewObserver(
                  controller: _observerController,
                  child: SmartPagination<Message>.listViewWithCubit(
                    cubit: _cubit,
                    scrollController: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    reverse: true, // Important for chat!
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemBuilder: (context, items, index) {
                      final message = items[index];
                      final isHighlighted = _highlightedIndex == index;

                      // Show date separator
                      final showDateSeparator = _shouldShowDateSeparator(items, index);

                      return Column(
                        children: [
                          if (showDateSeparator)
                            _DateSeparator(date: message.timestamp),
                          _MessageBubble(
                            message: message,
                            isCurrentUser: message.author == _currentUser,
                            isHighlighted: isHighlighted,
                            index: index,
                            isDark: isDark,
                            onLongPress: () => _showMessageOptions(message, index),
                          ),
                        ],
                      );
                    },
                    firstPageLoadingBuilder: (context) => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            color: isDark ? Colors.teal : Colors.teal,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'جاري تحميل الرسائل...',
                            style: TextStyle(
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    firstPageErrorBuilder: (context, error, retry) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.cloud_off,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'فشل تحميل الرسائل',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'تحقق من اتصالك بالإنترنت',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 24),
                            FilledButton.icon(
                              onPressed: retry,
                              icon: const Icon(Icons.refresh),
                              label: const Text('إعادة المحاولة'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    firstPageEmptyBuilder: (context) => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'لا توجد رسائل',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'ابدأ المحادثة الآن!',
                            style: TextStyle(color: Colors.grey[500]),
                          ),
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

                // Typing indicator
                if (_isTyping)
                  Positioned(
                    bottom: 8,
                    left: 16,
                    child: _TypingIndicator(userName: _otherUser),
                  ),
              ],
            ),
          ),

          // Message input
          _buildMessageInput(isDark),
        ],
      ),
      floatingActionButton: _buildScrollToBottomFab(isDark),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark) {
    final bgColor = isDark ? const Color(0xFF1F2C34) : Colors.teal;

    return AppBar(
      backgroundColor: bgColor,
      foregroundColor: Colors.white,
      elevation: 0,
      titleSpacing: 0,
      title: _isSearching
          ? TextField(
              controller: _searchController,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'بحث في الرسائل...',
                hintStyle: TextStyle(color: Colors.white60),
                border: InputBorder.none,
              ),
              onSubmitted: (query) {
                _searchAndScroll(query);
                setState(() => _isSearching = false);
              },
            )
          : Row(
              children: [
                TooltipCard.builder(
                  beakEnabled: true,
                  placementSide: TooltipCardPlacementSide.bottom,
                  whenContentVisible: WhenContentVisible.pressButton,
                  builder: (context, close) => _buildUserProfileTooltip(close),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.white24,
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            _otherUser,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            _isTyping ? 'يكتب...' : 'متصل الآن',
                            style: TextStyle(
                              fontSize: 12,
                              color: _isTyping ? Colors.greenAccent : Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'top',
              child: Row(
                children: [
                  Icon(Icons.keyboard_double_arrow_up, size: 20),
                  SizedBox(width: 12),
                  Text('أقدم الرسائل'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'bottom',
              child: Row(
                children: [
                  Icon(Icons.keyboard_double_arrow_down, size: 20),
                  SizedBox(width: 12),
                  Text('أحدث الرسائل'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'unread',
              child: Row(
                children: [
                  Icon(Icons.mark_email_unread, size: 20),
                  SizedBox(width: 12),
                  Text('غير المقروءة'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'middle',
              child: Row(
                children: [
                  Icon(Icons.vertical_align_center, size: 20),
                  SizedBox(width: 12),
                  Text('منتصف المحادثة'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUserProfileTooltip(VoidCallback close) {
    return Container(
      padding: const EdgeInsets.all(16),
      constraints: const BoxConstraints(maxWidth: 280),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircleAvatar(
            radius: 40,
            backgroundColor: Colors.teal,
            child: Icon(Icons.person, size: 40, color: Colors.white),
          ),
          const SizedBox(height: 12),
          const Text(
            _otherUser,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '+966 50 XXX XXXX',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildProfileAction(Icons.call, 'اتصال'),
              _buildProfileAction(Icons.videocam, 'فيديو'),
              _buildProfileAction(Icons.info_outline, 'معلومات'),
            ],
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: close,
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileAction(IconData icon, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: () {},
          icon: Icon(icon, color: Colors.teal),
        ),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildNavigationToolbar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      color: isDark ? const Color(0xFF1F2C34) : Colors.teal.shade50,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _NavigationChip(
              label: 'الأولى',
              icon: Icons.looks_one,
              onTap: () => _jumpToIndex(0),
              color: Colors.teal,
            ),
            _NavigationChip(
              label: 'رقم 10',
              icon: Icons.filter_1,
              onTap: () => _jumpToIndex(9),
              color: Colors.blue,
            ),
            _NavigationChip(
              label: 'رقم 20',
              icon: Icons.filter_2,
              onTap: () => _jumpToIndex(19),
              color: Colors.purple,
            ),
            _NavigationChip(
              label: 'المشروع',
              icon: Icons.search,
              onTap: () => _searchAndScroll('المشروع'),
              color: Colors.orange,
            ),
            _NavigationChip(
              label: 'الاجتماع',
              icon: Icons.event,
              onTap: () => _searchAndScroll('الاجتماع'),
              color: Colors.pink,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput(bool isDark) {
    final bgColor = isDark ? const Color(0xFF1F2C34) : Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Emoji button
            IconButton(
              onPressed: () {},
              icon: Icon(
                Icons.emoji_emotions_outlined,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),

            // Text field
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2A3942) : Colors.grey[100],
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _messageController,
                  focusNode: _messageFocusNode,
                  textDirection: TextDirection.rtl,
                  decoration: InputDecoration(
                    hintText: 'اكتب رسالة...',
                    hintStyle: TextStyle(
                      color: isDark ? Colors.grey[500] : Colors.grey[600],
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),

            const SizedBox(width: 4),

            // Attachment button
            IconButton(
              onPressed: () {},
              icon: Icon(
                Icons.attach_file,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),

            // Send/Voice button
            TooltipCard.builder(
              beakEnabled: true,
              placementSide: TooltipCardPlacementSide.top,
              whenContentVisible: WhenContentVisible.longPressButton,
              builder: (context, close) => const Padding(
                padding: EdgeInsets.all(12),
                child: Text('اضغط للإرسال\nاضغط مطولاً للتسجيل الصوتي'),
              ),
              child: CircleAvatar(
                radius: 24,
                backgroundColor: Colors.teal,
                child: IconButton(
                  onPressed: _sendMessage,
                  icon: Icon(
                    _messageController.text.isEmpty ? Icons.mic : Icons.send,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget? _buildScrollToBottomFab(bool isDark) {
    if (!_showScrollToBottom) return null;

    return ScaleTransition(
      scale: CurvedAnimation(
        parent: _fabAnimationController,
        curve: Curves.easeOutBack,
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 70),
        child: Stack(
          children: [
            FloatingActionButton.small(
              onPressed: _scrollToNewest,
              backgroundColor: isDark ? const Color(0xFF2A3942) : Colors.white,
              child: Icon(
                Icons.keyboard_double_arrow_down,
                color: isDark ? Colors.white70 : Colors.grey[700],
              ),
            ),
            if (_unreadCount > 0)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.teal,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: Text(
                    '$_unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _handleMenuAction(String value) {
    switch (value) {
      case 'top':
        _scrollToOldest();
        break;
      case 'bottom':
        _scrollToNewest();
        break;
      case 'unread':
        _jumpToUnread();
        break;
      case 'middle':
        final items = _cubit.currentItems;
        if (items.isNotEmpty) {
          _jumpToIndex(items.length ~/ 2);
        }
        break;
    }
  }

  bool _shouldShowDateSeparator(List<Message> items, int index) {
    if (index == items.length - 1) return true;

    final currentDate = DateUtils.dateOnly(items[index].timestamp);
    final nextDate = DateUtils.dateOnly(items[index + 1].timestamp);

    return currentDate != nextDate;
  }

  void _showMessageOptions(Message message, int index) {
    HapticFeedback.mediumImpact();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Message preview
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                message.content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textDirection: TextDirection.rtl,
              ),
            ),
            const SizedBox(height: 20),

            // Actions
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MessageActionChip(
                  icon: Icons.content_copy,
                  label: 'نسخ',
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: message.content));
                    Navigator.pop(context);
                    _showSnackBar('تم النسخ', Colors.green);
                  },
                ),
                _MessageActionChip(
                  icon: Icons.reply,
                  label: 'رد',
                  onTap: () => Navigator.pop(context),
                ),
                _MessageActionChip(
                  icon: Icons.forward,
                  label: 'تحويل',
                  onTap: () => Navigator.pop(context),
                ),
                _MessageActionChip(
                  icon: Icons.star_border,
                  label: 'تمييز',
                  onTap: () => Navigator.pop(context),
                ),
                _MessageActionChip(
                  icon: Icons.center_focus_strong,
                  label: 'انتقال',
                  onTap: () {
                    Navigator.pop(context);
                    _cubit.animateToIndex(index, alignment: 0.3);
                  },
                ),
                _MessageActionChip(
                  icon: Icons.delete_outline,
                  label: 'حذف',
                  color: Colors.red,
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ============= Helper Widgets =============

class _DateSeparator extends StatelessWidget {
  const _DateSeparator({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateUtils.dateOnly(now);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateUtils.dateOnly(date);

    String dateText;
    if (messageDate == today) {
      dateText = 'اليوم';
    } else if (messageDate == yesterday) {
      dateText = 'أمس';
    } else {
      dateText = DateFormat('d MMMM yyyy', 'ar').format(date);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            dateText,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator({required this.userName});

  final String userName;

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (index) {
                  final delay = index * 0.2;
                  final value = (_controller.value - delay).clamp(0.0, 1.0);
                  final scale = 0.5 + 0.5 * (1 - (value - 0.5).abs() * 2);

                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: const BoxDecoration(
                        color: Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                }),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _NavigationChip extends StatelessWidget {
  const _NavigationChip({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.color,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: TooltipCard.builder(
        beakEnabled: true,
        placementSide: TooltipCardPlacementSide.bottom,
        whenContentVisible: WhenContentVisible.hoverButton,
        builder: (context, close) => Padding(
          padding: const EdgeInsets.all(8),
          child: Text('انتقل إلى: $label'),
        ),
        child: ActionChip(
          avatar: Icon(icon, size: 16, color: color),
          label: Text(label, style: TextStyle(fontSize: 11, color: color)),
          onPressed: onTap,
          backgroundColor: color.withValues(alpha: 0.1),
          side: BorderSide.none,
          padding: const EdgeInsets.symmetric(horizontal: 4),
        ),
      ),
    );
  }
}

class _MessageActionChip extends StatelessWidget {
  const _MessageActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? Colors.grey[700];

    return ActionChip(
      avatar: Icon(icon, size: 18, color: chipColor),
      label: Text(label, style: TextStyle(color: chipColor)),
      onPressed: onTap,
      backgroundColor: (chipColor ?? Colors.grey).withValues(alpha: 0.1),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.isCurrentUser,
    required this.isHighlighted,
    required this.index,
    required this.isDark,
    required this.onLongPress,
  });

  final Message message;
  final bool isCurrentUser;
  final bool isHighlighted;
  final int index;
  final bool isDark;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    // WhatsApp-like colors
    final bubbleColor = isCurrentUser
        ? (isDark ? const Color(0xFF005C4B) : const Color(0xFFD9FDD3))
        : (isDark ? const Color(0xFF202C33) : Colors.white);

    final textColor = isDark ? Colors.white : Colors.black87;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: EdgeInsets.only(
        left: isCurrentUser ? 64 : 8,
        right: isCurrentUser ? 8 : 64,
        top: 2,
        bottom: 2,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isHighlighted
            ? Colors.yellow.withValues(alpha: 0.4)
            : Colors.transparent,
      ),
      child: GestureDetector(
        onLongPress: onLongPress,
        child: Align(
          alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(12),
                topRight: const Radius.circular(12),
                bottomLeft: Radius.circular(isCurrentUser ? 12 : 4),
                bottomRight: Radius.circular(isCurrentUser ? 4 : 12),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.content,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 15,
                  ),
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      DateFormat('HH:mm').format(message.timestamp),
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white60 : Colors.grey[600],
                      ),
                    ),
                    if (isCurrentUser) ...[
                      const SizedBox(width: 4),
                      Icon(
                        message.isRead ? Icons.done_all : Icons.done,
                        size: 16,
                        color: message.isRead
                            ? const Color(0xFF53BDEB)
                            : (isDark ? Colors.white60 : Colors.grey[600]),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
