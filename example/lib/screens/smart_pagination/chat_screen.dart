import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show HapticFeedback, Clipboard, ClipboardData;
import 'package:intl/intl.dart' show DateFormat;
// import 'package:flutter/services.dart';
import 'package:smart_pagination/pagination.dart';
// import 'package:intl/intl.dart';
import 'package:tooltip_card/tooltip_card.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/message.dart';

/// A realistic chat screen demonstrating scroll navigation methods
/// with proper reverse ListView and modern UI design.
class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) => const _ChatControllerScope();
}

class _ChatControllerScope extends StatefulWidget {
  const _ChatControllerScope();

  @override
  State<_ChatControllerScope> createState() => _ChatControllerScopeState();
}

class _ChatControllerScopeState extends State<_ChatControllerScope> {
  late final _ChatScreenController _controller;

  @override
  void initState() {
    super.initState();
    _controller = _ChatScreenController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _ChatScreenView(controller: _controller);
  }
}

const Object _notSet = Object();

class _ChatUiState {
  const _ChatUiState({
    this.highlightedIndex,
    this.isSearching = false,
    this.showScrollToBottom = false,
    this.isTyping = false,
    this.unreadCount = 0,
  });

  final int? highlightedIndex;
  final bool isSearching;
  final bool showScrollToBottom;
  final bool isTyping;
  final int unreadCount;

  _ChatUiState copyWith({
    Object? highlightedIndex = _notSet,
    bool? isSearching,
    bool? showScrollToBottom,
    bool? isTyping,
    int? unreadCount,
  }) {
    return _ChatUiState(
      highlightedIndex: identical(highlightedIndex, _notSet)
          ? this.highlightedIndex
          : highlightedIndex as int?,
      isSearching: isSearching ?? this.isSearching,
      showScrollToBottom: showScrollToBottom ?? this.showScrollToBottom,
      isTyping: isTyping ?? this.isTyping,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}

class _ChatScreenController {
  _ChatScreenController() {
    scrollController.addListener(_onScroll);

    // Observer is now built-in! No need to create ListObserverController manually.
    // SmartPagination will automatically attach it to the cubit.
    cubit = SmartPaginationCubit<Message>(
      request: const PaginationRequest(page: 1, pageSize: 30),
      provider: PaginationProvider.future(_fetchMessages),
    );

    // Simulate typing indicator
    _simulateTyping();
  }

  late final SmartPaginationCubit<Message> cubit;
  final ScrollController scrollController = ScrollController();

  final TextEditingController messageController = TextEditingController();
  final TextEditingController searchController = TextEditingController();
  final FocusNode messageFocusNode = FocusNode();
  final ValueNotifier<_ChatUiState> uiState =
      ValueNotifier<_ChatUiState>(const _ChatUiState());

  static const String _currentUser = 'أنت';
  static const String _otherUser = 'أحمد محمد';

  final Map<String, _MessageAttachment> messageAttachments =
      <String, _MessageAttachment>{};

  bool _disposed = false;

  void _updateUiState(_ChatUiState Function(_ChatUiState current) update) {
    if (_disposed) return;
    uiState.value = update(uiState.value);
  }

  void _onScroll() {
    final showButton =
        scrollController.hasClients && scrollController.offset > 200;

    if (showButton != uiState.value.showScrollToBottom) {
      _updateUiState(
        (current) => current.copyWith(showScrollToBottom: showButton),
      );
    }
  }

  void _simulateTyping() {
    Future.delayed(const Duration(seconds: 5), () {
      if (_disposed) return;
      _updateUiState((current) => current.copyWith(isTyping: true));
      Future.delayed(const Duration(seconds: 2), () {
        if (_disposed) return;
        _updateUiState((current) => current.copyWith(isTyping: false));
      });
    });
  }

  Future<List<Message>> _fetchMessages(PaginationRequest request) async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (_disposed) return <Message>[];

    final messages = <Message>[];
    final now = DateTime.now();

    // Create realistic chat messages
    final sampleConversation = _getSampleConversation();

    for (int i = 0; i < (request.pageSize ?? 20); i++) {
      final index = ((request.page - 1) * (request.pageSize ?? 20)) + i;
      if (index >= sampleConversation.length * 3) break;

      final messageData = sampleConversation[index % sampleConversation.length];
      final isCurrentUser = messageData.isMe;
      final messageId = 'msg_${request.page}_$index';

      if (messageData.attachment != null) {
        messageAttachments[messageId] = messageData.attachment!;
      } else {
        messageAttachments.remove(messageId);
      }

      // Create timestamps going backwards in time
      final timestamp = now.subtract(Duration(
        minutes: index * 3 + (index ~/ 5) * 30, // Add gaps for realism
      ));

      messages.add(Message(
        id: messageId,
        content: messageData.text,
        author: isCurrentUser ? _currentUser : _otherUser,
        timestamp: timestamp,
        isRead: index > 5, // Recent messages are unread
      ));
    }

    // Update unread count
    _updateUiState(
      (current) => current.copyWith(
        unreadCount: messages.where((m) => !m.isRead).length,
      ),
    );

    return messages;
  }

  List<_SampleConversationMessage> _getSampleConversation() {
    return const [
      _SampleConversationMessage(
        text: 'مرحباً! كيف حالك اليوم؟ 👋',
        isMe: false,
      ),
      _SampleConversationMessage(
        text: 'أهلاً أحمد! الحمد لله بخير، وأنت؟',
        isMe: true,
      ),
      _SampleConversationMessage(
        text: 'media image: أرسلت لك صورة حقيقية للمعاينة',
        isMe: false,
        attachment: _MessageAttachment(
          type: _MessageAttachmentType.image,
          title: 'صورة حقيقية',
          subtitle: 'JPEG • 18 KB',
          caption: 'هذه رسالة media تحتوي صورة حقيقية.',
          mediaUrl:
              'https://interactive-examples.mdn.mozilla.net/media/cc0-images/grapefruit-slice-332-332.jpg',
          icon: Icons.image,
          color: Color(0xFF0B8F8A),
        ),
      ),
      _SampleConversationMessage(
        text: 'media video: هذا فيديو حقيقي قابل للتشغيل',
        isMe: true,
        attachment: _MessageAttachment(
          type: _MessageAttachmentType.video,
          title: 'فيديو الزهرة',
          subtitle: 'MP4 • 1.1 MB',
          caption: 'هذه رسالة media تحتوي ملف فيديو حقيقي.',
          mediaUrl:
              'https://interactive-examples.mdn.mozilla.net/media/cc0-videos/flower.mp4',
          icon: Icons.play_arrow_rounded,
          color: Color(0xFF3A86FF),
          actionLabel: 'تشغيل الفيديو',
          duration: '0:05',
        ),
      ),
      _SampleConversationMessage(
        text: 'media audio: هذا مقطع صوتي حقيقي',
        isMe: false,
        attachment: _MessageAttachment(
          type: _MessageAttachmentType.audio,
          title: 'مقطع صوتي',
          subtitle: 'MP3 • 39 KB',
          caption: 'هذه رسالة media تحتوي ملف صوت حقيقي.',
          mediaUrl:
              'https://interactive-examples.mdn.mozilla.net/media/cc0-audio/t-rex-roar.mp3',
          icon: Icons.graphic_eq,
          color: Color(0xFF118AB2),
          actionLabel: 'تشغيل الصوت',
          duration: '0:01',
        ),
      ),
      _SampleConversationMessage(
        text: 'الحمد لله، هل انتهيت من المشروع؟',
        isMe: false,
      ),
      _SampleConversationMessage(
        text: 'نعم، أنهيته البارحة وأرسلته للمراجعة ✅',
        isMe: true,
      ),
      _SampleConversationMessage(
        text: 'location: هذا موقع الاجتماع الرئيسي',
        isMe: true,
        attachment: _MessageAttachment(
          type: _MessageAttachmentType.location,
          title: 'موقع الاجتماع',
          subtitle: 'الرياض - حي الملقا',
          caption: '24.7743, 46.7386',
          icon: Icons.location_on,
          color: Color(0xFFE76F51),
          actionLabel: 'عرض الموقع',
        ),
      ),
      _SampleConversationMessage(
        text: 'ممتاز! عمل رائع 👏',
        isMe: false,
      ),
      _SampleConversationMessage(
        text: 'contact: أرسل لك جهة اتصال خالد من فريق الدعم',
        isMe: false,
        attachment: _MessageAttachment(
          type: _MessageAttachmentType.contact,
          title: 'خالد الدعم الفني',
          subtitle: '+966 55 123 4567',
          caption: 'فريق تجربة العملاء',
          icon: Icons.person,
          color: Color(0xFF2A9D8F),
        ),
      ),
      _SampleConversationMessage(
        text: 'شكراً لك! هل لديك أي ملاحظات؟',
        isMe: true,
      ),
      _SampleConversationMessage(
        text: 'سأراجعه اليوم وأخبرك',
        isMe: false,
      ),
      _SampleConversationMessage(
        text: 'تمام، في انتظارك',
        isMe: true,
      ),
      _SampleConversationMessage(
        text: 'poll: ما الوقت الأنسب للاجتماع القادم؟',
        isMe: false,
        attachment: _MessageAttachment(
          type: _MessageAttachmentType.poll,
          title: 'ما الوقت الأنسب للاجتماع القادم؟',
          subtitle: '12 صوتاً',
          caption: 'استطلاع تجريبي لرسائل poll.',
          icon: Icons.poll,
          color: Color(0xFF6A4C93),
          pollOptions: [
            _PollOption(label: '10:00 صباحاً', votes: 5),
            _PollOption(label: '1:00 ظهراً', votes: 3),
            _PollOption(label: '3:00 مساءً', votes: 4),
          ],
        ),
      ),
      _SampleConversationMessage(
        text: 'بالمناسبة، الاجتماع تأجل للساعة 3 مساءً',
        isMe: false,
      ),
      _SampleConversationMessage(
        text: 'حسناً، سأكون جاهزاً 📅',
        isMe: true,
      ),
      _SampleConversationMessage(
        text: 'هل تحتاج مساعدة في التحضير؟',
        isMe: false,
      ),
      _SampleConversationMessage(
        text: 'نعم، أرسل لي العرض التقديمي من فضلك',
        isMe: true,
      ),
      _SampleConversationMessage(
        text: 'تم الإرسال على البريد 📧',
        isMe: false,
      ),
      _SampleConversationMessage(
        text: 'وصل، شكراً جزيلاً!',
        isMe: true,
      ),
      _SampleConversationMessage(
        text: 'عفواً! نتواصل لاحقاً',
        isMe: false,
      ),
      _SampleConversationMessage(
        text: 'إن شاء الله، أراك في الاجتماع',
        isMe: true,
      ),
      _SampleConversationMessage(
        text: 'هل رأيت التحديثات الجديدة في النظام؟',
        isMe: false,
      ),
      _SampleConversationMessage(
        text: 'لا بعد، ما الجديد؟',
        isMe: true,
      ),
      _SampleConversationMessage(
        text: 'أضافوا ميزة البحث المتقدم 🔍',
        isMe: false,
      ),
      _SampleConversationMessage(
        text: 'رائع! سأجربها الآن',
        isMe: true,
      ),
    ];
  }

  void dispose() {
    _disposed = true;
    scrollController.removeListener(_onScroll);
    // No need to detach observer - it's handled automatically by SmartPagination
    cubit.close();
    scrollController.dispose();
    messageController.dispose();
    searchController.dispose();
    messageFocusNode.dispose();
    uiState.dispose();
  }

  void sendMessage() {
    final text = messageController.text.trim();
    if (text.isEmpty) {
      messageFocusNode.requestFocus();
      return;
    }

    final newMessage = Message(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      content: text,
      author: _currentUser,
      timestamp: DateTime.now(),
      isRead: true,
    );

    cubit.insertEmit(newMessage, index: 0);
    messageController.clear();
    messageFocusNode.requestFocus();

    // Haptic feedback
    HapticFeedback.lightImpact();

    // Scroll to bottom (index 0 in reverse list)
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_disposed) return;
      scrollToNewest();
      messageFocusNode.requestFocus();
    });

    // Simulate reply
    _simulateReply();
  }

  void _simulateReply() {
    Future.delayed(const Duration(seconds: 2), () {
      if (_disposed) return;

      _updateUiState((current) => current.copyWith(isTyping: true));

      Future.delayed(const Duration(seconds: 2), () {
        if (_disposed) return;

        _updateUiState((current) => current.copyWith(isTyping: false));

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

        cubit.insertEmit(reply, index: 0);
        _updateUiState(
          (current) => current.copyWith(unreadCount: current.unreadCount + 1),
        );
      });
    });
  }

  void scrollToNewest() {
    final success = cubit.jumpToIndex(0);

    if (success) {
      _updateUiState((current) => current.copyWith(unreadCount: 0));
    }
  }

  void scrollToOldest() {
    final items = cubit.currentItems;
    if (items.isEmpty) return;

    cubit.jumpToIndex(items.length - 1);
  }

  void jumpToUnread(BuildContext context) {
    final success = cubit.jumpFirstWhere(
      (message) => !message.isRead,
      alignment: 0.3,
    );

    if (!_disposed) {
      showSnackBar(
        context,
        success
            ? 'تم العثور على أول رسالة غير مقروءة'
            : 'لا توجد رسائل غير مقروءة',
        success ? Colors.green : Colors.orange,
      );
    }
  }

  void searchAndScroll(BuildContext context, String query) {
    if (query.isEmpty) return;

    final success = cubit.jumpFirstWhere(
      (message) => message.content.toLowerCase().contains(query.toLowerCase()),
      alignment: 0.3,
    );

    final items = cubit.currentItems;
    final index = items.indexWhere(
      (m) => m.content.toLowerCase().contains(query.toLowerCase()),
    );

    _updateUiState(
      (current) => current.copyWith(highlightedIndex: success ? index : null),
    );

    if (!_disposed) {
      showSnackBar(
        context,
        success
            ? 'تم العثور على الرسالة رقم ${index + 1}'
            : 'لم يتم العثور على "$query"',
        success ? Colors.green : Colors.orange,
      );
    }

    if (success) {
      Future.delayed(const Duration(seconds: 3), () {
        if (_disposed) return;
        _updateUiState(
          (current) => current.copyWith(highlightedIndex: null),
        );
      });
    }
  }

  void jumpToIndex(BuildContext context, int index) {
    final success = cubit.jumpToIndex(index, alignment: 0.3);

    if (!_disposed) {
      showSnackBar(
        context,
        success
            ? 'تم الانتقال للرسالة #${index + 1}'
            : 'لا يمكن الانتقال للرسالة #${index + 1}',
        success ? Colors.teal : Colors.red,
      );
    }
  }

  void setSearching(bool isSearching) {
    if (!isSearching) {
      searchController.clear();
    }

    _updateUiState(
      (current) => current.copyWith(
        isSearching: isSearching,
        highlightedIndex: isSearching ? current.highlightedIndex : null,
      ),
    );
  }

  void toggleSearch() {
    setSearching(!uiState.value.isSearching);
  }

  void handleMenuAction(BuildContext context, String value) {
    switch (value) {
      case 'top':
        scrollToOldest();
        break;
      case 'bottom':
        scrollToNewest();
        break;
      case 'unread':
        jumpToUnread(context);
        break;
      case 'middle':
        final items = cubit.currentItems;
        if (items.isNotEmpty) {
          jumpToIndex(context, items.length ~/ 2);
        }
        break;
    }
  }

  void showSnackBar(BuildContext context, String message, Color color) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
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
}

class _ChatScreenView extends StatelessWidget {
  const _ChatScreenView({required this.controller});

  final _ChatScreenController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ValueListenableBuilder<_ChatUiState>(
      valueListenable: controller.uiState,
      builder: (context, uiState, _) {
        return Scaffold(
          backgroundColor:
              isDark ? const Color(0xFF0B141A) : const Color(0xFFECE5DD),
          appBar: _buildAppBar(context, isDark, uiState),
          body: Column(
            children: [
              // Navigation toolbar
              _buildNavigationToolbar(context, isDark),

              // Chat messages
              Expanded(
                child: Stack(
                  children: [
                    // Background pattern
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF0B141A)
                              : const Color(0xFFECE5DD),
                        ),
                      ),
                    ),

                    // Messages list - ListViewObserver is now built-in!
                    SmartPagination<Message>.listViewWithCubit(
                      cubit: controller.cubit,
                      scrollController: controller.scrollController,
                      physics: const BouncingScrollPhysics(),
                      reverse: true, // Important for chat!
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemBuilder: (context, items, index) {
                        final message = items[index];
                        final isHighlighted = uiState.highlightedIndex == index;

                        // Show date separator
                        final showDateSeparator =
                            _shouldShowDateSeparator(items, index);

                        return Column(
                          children: [
                            if (showDateSeparator)
                              _DateSeparator(date: message.timestamp),
                            _MessageBubble(
                              message: message,
                              attachment:
                                  controller.messageAttachments[message.id],
                              isCurrentUser: message.author ==
                                  _ChatScreenController._currentUser,
                              isHighlighted: isHighlighted,
                              index: index,
                              isDark: isDark,
                              onLongPress: () =>
                                  _showMessageOptions(context, message, index),
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

                    // Typing indicator
                    if (uiState.isTyping)
                      Positioned(
                        bottom: 8,
                        left: 16,
                        child: const _TypingIndicator(),
                      ),
                  ],
                ),
              ),

              // Message input
              _buildMessageInput(isDark),
            ],
          ),
          floatingActionButton: _buildScrollToBottomFab(isDark, uiState),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    bool isDark,
    _ChatUiState uiState,
  ) {
    final bgColor = isDark ? const Color(0xFF1F2C34) : Colors.teal;

    return AppBar(
      backgroundColor: bgColor,
      foregroundColor: Colors.white,
      elevation: 0,
      titleSpacing: 0,
      title: uiState.isSearching
          ? TextField(
              controller: controller.searchController,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'بحث في الرسائل...',
                hintStyle: TextStyle(color: Colors.white60),
                border: InputBorder.none,
              ),
              onSubmitted: (query) {
                controller.searchAndScroll(context, query);
                controller.setSearching(false);
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
                            _ChatScreenController._otherUser,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            uiState.isTyping ? 'يكتب...' : 'متصل الآن',
                            style: TextStyle(
                              fontSize: 12,
                              color: uiState.isTyping
                                  ? Colors.greenAccent
                                  : Colors.white70,
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
          icon: Icon(uiState.isSearching ? Icons.close : Icons.search),
          onPressed: controller.toggleSearch,
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) => controller.handleMenuAction(context, value),
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
            _ChatScreenController._otherUser,
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

  Widget _buildNavigationToolbar(BuildContext context, bool isDark) {
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
              onTap: () => controller.jumpToIndex(context, 0),
              color: Colors.teal,
            ),
            _NavigationChip(
              label: 'رقم 10',
              icon: Icons.filter_1,
              onTap: () => controller.jumpToIndex(context, 9),
              color: Colors.blue,
            ),
            _NavigationChip(
              label: 'رقم 20',
              icon: Icons.filter_2,
              onTap: () => controller.jumpToIndex(context, 19),
              color: Colors.purple,
            ),
            _NavigationChip(
              label: 'المشروع',
              icon: Icons.search,
              onTap: () => controller.searchAndScroll(context, 'المشروع'),
              color: Colors.orange,
            ),
            _NavigationChip(
              label: 'الاجتماع',
              icon: Icons.event,
              onTap: () => controller.searchAndScroll(context, 'الاجتماع'),
              color: Colors.pink,
            ),
            _NavigationChip(
              label: 'وسائط',
              icon: Icons.perm_media,
              onTap: () => controller.searchAndScroll(context, 'media'),
              color: Colors.indigo,
            ),
            _NavigationChip(
              label: 'موقع',
              icon: Icons.location_on,
              onTap: () => controller.searchAndScroll(context, 'location'),
              color: Colors.deepOrange,
            ),
            _NavigationChip(
              label: 'جهة اتصال',
              icon: Icons.person_add_alt,
              onTap: () => controller.searchAndScroll(context, 'contact'),
              color: Colors.green,
            ),
            _NavigationChip(
              label: 'استطلاع',
              icon: Icons.poll,
              onTap: () => controller.searchAndScroll(context, 'poll'),
              color: Colors.deepPurple,
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
                  controller: controller.messageController,
                  focusNode: controller.messageFocusNode,
                  textInputAction: TextInputAction.send,
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
                  onEditingComplete: () {},
                  onSubmitted: (_) => controller.sendMessage(),
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
                  onPressed: controller.sendMessage,
                  icon: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: controller.messageController,
                    builder: (context, value, _) {
                      return Icon(
                        value.text.trim().isEmpty ? Icons.mic : Icons.send,
                        color: Colors.white,
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget? _buildScrollToBottomFab(bool isDark, _ChatUiState uiState) {
    if (!uiState.showScrollToBottom) return null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 70),
      child: Stack(
        children: [
          FloatingActionButton.small(
            onPressed: controller.scrollToNewest,
            backgroundColor: isDark ? const Color(0xFF2A3942) : Colors.white,
            child: Icon(
              Icons.keyboard_double_arrow_down,
              color: isDark ? Colors.white70 : Colors.grey[700],
            ),
          ),
          if (uiState.unreadCount > 0)
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
                  '${uiState.unreadCount}',
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
    );
  }

  bool _shouldShowDateSeparator(List<Message> items, int index) {
    if (index == items.length - 1) return true;

    final currentDate = DateUtils.dateOnly(items[index].timestamp);
    final nextDate = DateUtils.dateOnly(items[index + 1].timestamp);

    return currentDate != nextDate;
  }

  void _showMessageOptions(BuildContext context, Message message, int index) {
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
                    controller.showSnackBar(context, 'تم النسخ', Colors.green);
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
                    controller.cubit.jumpToIndex(index, alignment: 0.3);
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

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

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
        children: List.generate(
          3,
          (index) => Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: const BoxDecoration(
              color: Colors.grey,
              shape: BoxShape.circle,
            ),
          ),
        ),
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

Future<void> _launchAttachmentUrl(BuildContext context, String? url) async {
  final uri = url == null ? null : Uri.tryParse(url);
  final messenger = ScaffoldMessenger.maybeOf(context);

  if (uri == null) {
    messenger?.showSnackBar(
      const SnackBar(content: Text('رابط الوسائط غير صالح')),
    );
    return;
  }

  final didLaunch = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!didLaunch) {
    messenger?.showSnackBar(
      const SnackBar(content: Text('تعذر فتح ملف الوسائط')),
    );
  }
}

class _SampleConversationMessage {
  const _SampleConversationMessage({
    required this.text,
    required this.isMe,
    this.attachment,
  });

  final String text;
  final bool isMe;
  final _MessageAttachment? attachment;
}

enum _MessageAttachmentType { image, video, audio, location, contact, poll }

class _MessageAttachment {
  const _MessageAttachment({
    required this.type,
    required this.title,
    this.subtitle,
    this.caption,
    this.mediaUrl,
    this.icon = Icons.insert_drive_file,
    this.color = Colors.teal,
    this.actionLabel,
    this.duration,
    this.pollOptions = const [],
  });

  final _MessageAttachmentType type;
  final String title;
  final String? subtitle;
  final String? caption;
  final String? mediaUrl;
  final IconData icon;
  final Color color;
  final String? actionLabel;
  final String? duration;
  final List<_PollOption> pollOptions;
}

class _PollOption {
  const _PollOption({
    required this.label,
    required this.votes,
  });

  final String label;
  final int votes;
}

class _MessageAttachmentView extends StatelessWidget {
  const _MessageAttachmentView({
    required this.attachment,
    required this.textColor,
    required this.isDark,
  });

  final _MessageAttachment attachment;
  final Color textColor;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width * 0.75;
        final width = maxWidth < 180
            ? maxWidth
            : maxWidth > 260
                ? 260.0
                : maxWidth;

        return SizedBox(
          width: width,
          child: switch (attachment.type) {
            _MessageAttachmentType.image => _buildImageContent(),
            _MessageAttachmentType.video => _buildVideoContent(context),
            _MessageAttachmentType.audio => _buildAudioContent(context),
            _MessageAttachmentType.location => _buildLocationContent(context),
            _MessageAttachmentType.contact => _buildContactContent(context),
            _MessageAttachmentType.poll => _buildPollContent(),
          },
        );
      },
    );
  }

  Widget _buildImageContent() {
    final mutedColor = isDark ? Colors.white70 : Colors.black54;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            children: [
              Image.network(
                attachment.mediaUrl!,
                height: 170,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildMediaFallback(
                    height: 170,
                    icon: Icons.broken_image_outlined,
                    label: 'تعذر تحميل الصورة',
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;

                  return _buildMediaFallback(
                    height: 170,
                    icon: Icons.image_outlined,
                    label: 'جاري تحميل الصورة',
                    showProgress: true,
                  );
                },
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0),
                        Colors.black.withValues(alpha: 0.48),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: _AttachmentBadge(
                  icon: Icons.image_outlined,
                  label: attachment.subtitle ?? 'image',
                  isDark: isDark,
                ),
              ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Text(
                  attachment.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                  textDirection: TextDirection.rtl,
                ),
              ),
            ],
          ),
        ),
        if (attachment.caption != null) ...[
          const SizedBox(height: 8),
          Text(
            attachment.caption!,
            style: TextStyle(color: mutedColor, fontSize: 13),
            textDirection: TextDirection.rtl,
          ),
        ],
      ],
    );
  }

  Widget _buildVideoContent(BuildContext context) {
    final mutedColor = isDark ? Colors.white70 : Colors.black54;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => _launchAttachmentUrl(context, attachment.mediaUrl),
          child: Container(
            height: 150,
            decoration: BoxDecoration(
              color: attachment.color.withValues(alpha: isDark ? 0.24 : 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(
                        4,
                        (index) => Row(
                          children: List.generate(
                            5,
                            (dotIndex) => Expanded(
                              child: Container(
                                height: 18,
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 2),
                                decoration: BoxDecoration(
                                  color: attachment.color.withValues(
                                    alpha: index.isEven ? 0.18 : 0.11,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Center(
                  child: CircleAvatar(
                    radius: 30,
                    backgroundColor: attachment.color,
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 38,
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: _AttachmentBadge(
                    icon: Icons.videocam_outlined,
                    label: attachment.duration ?? 'video',
                    isDark: isDark,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          attachment.title,
          style: TextStyle(
            color: textColor,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
          textDirection: TextDirection.rtl,
        ),
        if (attachment.subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            attachment.subtitle!,
            style: TextStyle(color: mutedColor, fontSize: 12),
            textDirection: TextDirection.rtl,
          ),
        ],
        if (attachment.caption != null) ...[
          const SizedBox(height: 6),
          Text(
            attachment.caption!,
            style: TextStyle(color: mutedColor, fontSize: 12),
            textDirection: TextDirection.rtl,
          ),
        ],
        if (attachment.actionLabel != null) ...[
          const SizedBox(height: 8),
          _InlineAction(
            icon: Icons.open_in_new,
            label: attachment.actionLabel!,
            color: attachment.color,
            onTap: () => _launchAttachmentUrl(context, attachment.mediaUrl),
          ),
        ],
      ],
    );
  }

  Widget _buildAudioContent(BuildContext context) {
    final mutedColor = isDark ? Colors.white70 : Colors.black54;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: isDark ? 0.16 : 0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => _launchAttachmentUrl(context, attachment.mediaUrl),
                child: CircleAvatar(
                  radius: 22,
                  backgroundColor: attachment.color,
                  child: const Icon(Icons.play_arrow, color: Colors.white),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      attachment.title,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w700,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                    const SizedBox(height: 6),
                    _AudioWaveform(color: attachment.color, isDark: isDark),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                attachment.duration ?? '0:00',
                style: TextStyle(color: mutedColor, fontSize: 11),
              ),
            ],
          ),
          if (attachment.subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              attachment.subtitle!,
              style: TextStyle(color: mutedColor, fontSize: 12),
              textDirection: TextDirection.rtl,
            ),
          ],
          if (attachment.caption != null) ...[
            const SizedBox(height: 4),
            Text(
              attachment.caption!,
              style: TextStyle(color: mutedColor, fontSize: 12),
              textDirection: TextDirection.rtl,
            ),
          ],
          if (attachment.actionLabel != null) ...[
            const SizedBox(height: 8),
            _InlineAction(
              icon: Icons.open_in_new,
              label: attachment.actionLabel!,
              color: attachment.color,
              onTap: () => _launchAttachmentUrl(context, attachment.mediaUrl),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMediaFallback({
    required double height,
    required IconData icon,
    required String label,
    bool showProgress = false,
  }) {
    return Container(
      height: height,
      width: double.infinity,
      color: attachment.color.withValues(alpha: isDark ? 0.28 : 0.16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: attachment.color, size: 42),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(color: textColor, fontSize: 12),
            textDirection: TextDirection.rtl,
          ),
          if (showProgress) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: 80,
              child: LinearProgressIndicator(
                minHeight: 3,
                color: attachment.color,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLocationContent(BuildContext context) {
    final mutedColor = isDark ? Colors.white70 : Colors.black54;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 120,
          decoration: BoxDecoration(
            color: attachment.color.withValues(alpha: isDark ? 0.24 : 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: attachment.color.withValues(alpha: 0.28),
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(
                      4,
                      (index) => Container(
                        height: 2,
                        decoration: BoxDecoration(
                          color: attachment.color.withValues(alpha: 0.24),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Center(
                child: CircleAvatar(
                  radius: 26,
                  backgroundColor: attachment.color,
                  child: const Icon(Icons.location_on, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          attachment.title,
          style: TextStyle(
            color: textColor,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
          textDirection: TextDirection.rtl,
        ),
        if (attachment.subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            attachment.subtitle!,
            style: TextStyle(color: mutedColor, fontSize: 12),
            textDirection: TextDirection.rtl,
          ),
        ],
        if (attachment.caption != null) ...[
          const SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.my_location, size: 14, color: mutedColor),
              const SizedBox(width: 4),
              Text(
                attachment.caption!,
                style: TextStyle(color: mutedColor, fontSize: 11),
              ),
            ],
          ),
        ],
        if (attachment.actionLabel != null) ...[
          const SizedBox(height: 8),
          _InlineAction(
            icon: Icons.map_outlined,
            label: attachment.actionLabel!,
            color: attachment.color,
            onTap: attachment.mediaUrl == null
                ? null
                : () => _launchAttachmentUrl(context, attachment.mediaUrl),
          ),
        ],
      ],
    );
  }

  Widget _buildContactContent(BuildContext context) {
    final mutedColor = isDark ? Colors.white70 : Colors.black54;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: isDark ? 0.16 : 0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: attachment.color,
                child: Icon(attachment.icon, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      attachment.title,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w700,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                    if (attachment.subtitle != null)
                      Text(
                        attachment.subtitle!,
                        style: TextStyle(color: mutedColor, fontSize: 12),
                      ),
                    if (attachment.caption != null)
                      Text(
                        attachment.caption!,
                        style: TextStyle(color: mutedColor, fontSize: 11),
                        textDirection: TextDirection.rtl,
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _InlineAction(
                  icon: Icons.chat_bubble_outline,
                  label: 'رسالة',
                  color: attachment.color,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _InlineAction(
                  icon: Icons.call,
                  label: 'اتصال',
                  color: attachment.color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPollContent() {
    final totalVotes = attachment.pollOptions.fold<int>(
      0,
      (total, option) => total + option.votes,
    );
    final mutedColor = isDark ? Colors.white70 : Colors.black54;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(attachment.icon, color: attachment.color, size: 20),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                attachment.title,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                ),
                textDirection: TextDirection.rtl,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...attachment.pollOptions.map(
          (option) => _PollOptionTile(
            option: option,
            totalVotes: totalVotes,
            color: attachment.color,
            textColor: textColor,
            mutedColor: mutedColor,
            isDark: isDark,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          attachment.subtitle ?? '$totalVotes صوتاً',
          style: TextStyle(color: mutedColor, fontSize: 11),
          textDirection: TextDirection.rtl,
        ),
        if (attachment.caption != null) ...[
          const SizedBox(height: 2),
          Text(
            attachment.caption!,
            style: TextStyle(color: mutedColor, fontSize: 11),
            textDirection: TextDirection.rtl,
          ),
        ],
      ],
    );
  }
}

class _AttachmentBadge extends StatelessWidget {
  const _AttachmentBadge({
    required this.icon,
    required this.label,
    required this.isDark,
  });

  final IconData icon;
  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.black.withValues(alpha: 0.34)
            : Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: isDark ? Colors.white : Colors.black54),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.white : Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineAction extends StatelessWidget {
  const _InlineAction({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AudioWaveform extends StatelessWidget {
  const _AudioWaveform({
    required this.color,
    required this.isDark,
  });

  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    const heights = <double>[10, 18, 14, 24, 16, 28, 12, 22, 15, 20, 11, 17];

    return Row(
      children: [
        for (final height in heights)
          Expanded(
            child: Align(
              alignment: Alignment.center,
              child: Container(
                height: height,
                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: isDark ? 0.72 : 0.82),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _PollOptionTile extends StatelessWidget {
  const _PollOptionTile({
    required this.option,
    required this.totalVotes,
    required this.color,
    required this.textColor,
    required this.mutedColor,
    required this.isDark,
  });

  final _PollOption option;
  final int totalVotes;
  final Color color;
  final Color textColor;
  final Color mutedColor;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final percentage = totalVotes == 0 ? 0.0 : option.votes / totalVotes;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  option.label,
                  style: TextStyle(color: textColor, fontSize: 13),
                  textDirection: TextDirection.rtl,
                ),
              ),
              Text(
                '${(percentage * 100).round()}%',
                style: TextStyle(
                  color: mutedColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: percentage,
              minHeight: 7,
              backgroundColor: Colors.black.withValues(
                alpha: isDark ? 0.24 : 0.08,
              ),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.attachment,
    required this.isCurrentUser,
    required this.isHighlighted,
    required this.index,
    required this.isDark,
    required this.onLongPress,
  });

  final Message message;
  final _MessageAttachment? attachment;
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

    return Container(
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
          alignment:
              isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
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
                if (attachment == null)
                  Text(
                    message.content,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 15,
                    ),
                    textDirection: TextDirection.rtl,
                  )
                else
                  _MessageAttachmentView(
                    attachment: attachment!,
                    textColor: textColor,
                    isDark: isDark,
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
