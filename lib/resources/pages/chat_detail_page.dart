import 'package:flutter/material.dart';
import 'package:nylo_framework/nylo_framework.dart';
import '/app/models/message.dart';
import '/app/models/chat_message.dart';
import '/config/keys.dart';

class ChatDetailPage extends NyStatefulWidget {
  static RouteView path = ("/chat-detail", (_) => ChatDetailPage());

  ChatDetailPage({super.key}) : super(child: () => _ChatDetailPageState());
}

class _ChatDetailPageState extends NyPage<ChatDetailPage> {
  Message? _conversation;
  List<ChatMessage> _messages = [];
  TextEditingController? _messageController;
  String? _currentUserId;
  String? _currentUserName;
  String? _currentUserAvatar;
  final ScrollController _scrollController = ScrollController();

  // Color scheme
  static const Color primary = Color(0xFF3F6967);
  static const Color secondary = Color(0xFF50C1AE);
  static const Color backgroundDark = Color(0xFF161C1B);
  static const Color sentMessageColor = Color(0xFFDCF8C6);
  static const Color receivedMessageColor = Color(0xFFFFFFFF);

  @override
  get init => () async {
        final data = widget.data<Map<String, dynamic>>();
        if (data != null && data['conversation'] != null) {
          _conversation = data['conversation'] as Message;
        }
        _messageController = TextEditingController();
        await _loadCurrentUser();
        await _loadMessages();
        _scrollToBottom();
      };

  Future<void> _loadCurrentUser() async {
    try {
      final userData = await Keys.auth.read<Map<String, dynamic>>();
      _currentUserId = userData?['id']?.toString() ?? 'user_1';
      _currentUserName = userData?['name']?.toString() ?? 'You';
      _currentUserAvatar = userData?['avatar']?.toString();
    } catch (e) {
      _currentUserId = 'user_1';
      _currentUserName = 'You';
    }
  }

  Future<void> _loadMessages() async {
    if (_conversation?.id == null) return;
    
    try {
      final messagesJson = await Keys.chatMessages.read<List>();
      if (messagesJson != null) {
        _messages = messagesJson
            .map((m) => ChatMessage.fromJson(m))
            .where((m) => m.conversationId == _conversation!.id)
            .toList();
        _messages.sort((a, b) {
          final aTime = a.timestamp ?? DateTime(2000);
          final bTime = b.timestamp ?? DateTime(2000);
          return aTime.compareTo(bTime);
        });
        setState(() {});
      } else {
        _loadDummyMessages();
      }
    } catch (e) {
      print('Error loading messages: $e');
      _loadDummyMessages();
    }
  }

  void _loadDummyMessages() {
    if (_conversation == null) return;
    
    _messages = [
      ChatMessage()
        ..id = "1"
        ..conversationId = _conversation!.id
        ..senderId = _conversation!.senderId
        ..senderName = _conversation!.senderName
        ..senderAvatar = _conversation!.senderAvatar
        ..content = "Hello! How can I help you today?"
        ..timestamp = DateTime.now().subtract(const Duration(hours: 2))
        ..isSent = false
        ..isRead = true,
      ChatMessage()
        ..id = "2"
        ..conversationId = _conversation!.id
        ..senderId = _currentUserId
        ..senderName = _currentUserName
        ..content = "Hi! I need help with my course assignment."
        ..timestamp = DateTime.now().subtract(const Duration(hours: 1, minutes: 45))
        ..isSent = true
        ..isRead = true,
      ChatMessage()
        ..id = "3"
        ..conversationId = _conversation!.id
        ..senderId = _conversation!.senderId
        ..senderName = _conversation!.senderName
        ..content = "Sure, I'd be happy to help. Which course are you working on?"
        ..timestamp = DateTime.now().subtract(const Duration(hours: 1, minutes: 30))
        ..isSent = false
        ..isRead = true,
      ChatMessage()
        ..id = "4"
        ..conversationId = _conversation!.id
        ..senderId = _currentUserId
        ..senderName = _currentUserName
        ..content = "It's the Sustainable Farming course, Module 3."
        ..timestamp = DateTime.now().subtract(const Duration(minutes: 30))
        ..isSent = true
        ..isRead = true,
    ];
    setState(() {});
  }

  Future<void> _sendMessage() async {
    if (_conversation == null || _messageController == null || _messageController!.text.trim().isEmpty) {
      return;
    }

    final newMessage = ChatMessage()
      ..id = DateTime.now().millisecondsSinceEpoch.toString()
      ..conversationId = _conversation!.id
      ..senderId = _currentUserId
      ..senderName = _currentUserName
      ..senderAvatar = _currentUserAvatar
      ..content = _messageController!.text.trim()
      ..timestamp = DateTime.now()
      ..isSent = true
      ..isRead = false
      ..type = 'text';

    setState(() {
      _messages.add(newMessage);
      _messageController!.clear();
    });

    _scrollToBottom();

    // Save to storage
    try {
      final allMessagesJson = await Keys.chatMessages.read<List>() ?? [];
      allMessagesJson.add(newMessage.toJson());
      await Keys.chatMessages.save(allMessagesJson);
      
      // Update conversation
      final conversationsJson = await Keys.messages.read<List>() ?? [];
      final convIndex = conversationsJson.indexWhere((c) => c['id'] == _conversation!.id);
      if (convIndex != -1) {
        conversationsJson[convIndex]['last_message_preview'] = newMessage.content;
        conversationsJson[convIndex]['last_message_time'] = newMessage.timestamp?.toIso8601String();
        await Keys.messages.save(conversationsJson);
      }
    } catch (e) {
      print('Error saving message: $e');
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    
    if (messageDate == today) {
      // Today - show time only
      final hour = dateTime.hour;
      final minute = dateTime.minute.toString().padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '$displayHour:$minute $period';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      // Yesterday
      final hour = dateTime.hour;
      final minute = dateTime.minute.toString().padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return 'Yesterday $displayHour:$minute $period';
    } else {
      // Older - show date and time
      final month = dateTime.month;
      final day = dateTime.day;
      final hour = dateTime.hour;
      final minute = dateTime.minute.toString().padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '$month/$day $displayHour:$minute $period';
    }
  }

  @override
  void dispose() {
    _messageController?.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  LoadingStyle get loadingStyle => LoadingStyle.normal();

  @override
  Widget view(BuildContext context) {
    if (_conversation == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Chat")),
        body: const Center(child: Text("Conversation not found")),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF131515);
    final secondaryTextColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;

    return Scaffold(
      backgroundColor: isDark ? backgroundDark : const Color(0xFFECE5DD),
      appBar: AppBar(
        backgroundColor: isDark ? backgroundDark : primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: _conversation!.senderAvatar != null && _conversation!.senderAvatar!.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(_conversation!.senderAvatar!),
                        fit: BoxFit.cover,
                        onError: (_, __) {},
                      )
                    : null,
                color: _conversation!.senderAvatar == null || _conversation!.senderAvatar!.isEmpty
                    ? Colors.white.withOpacity(0.2)
                    : null,
              ),
              child: _conversation!.senderAvatar == null || _conversation!.senderAvatar!.isEmpty
                  ? Center(
                      child: Text(
                        (_conversation!.senderName ?? 'U')[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _conversation!.senderName ?? 'Unknown',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (_conversation!.senderType == 'instructor' || _conversation!.senderType == 'student')
                    const Text(
                      "online",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.videocam, color: Colors.white),
            onPressed: () {
              // TODO: Start video call
            },
          ),
          IconButton(
            icon: const Icon(Icons.phone, color: Colors.white),
            onPressed: () {
              // TODO: Start voice call
            },
          ),
          PopupMenuButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'view_profile',
                child: Text('View Profile'),
              ),
              const PopupMenuItem(
                value: 'media',
                child: Text('Media, Links & Docs'),
              ),
              const PopupMenuItem(
                value: 'search',
                child: Text('Search'),
              ),
              const PopupMenuItem(
                value: 'mute',
                child: Text('Mute Notifications'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final showDateDivider = index == 0 ||
                    (_messages[index - 1].timestamp != null &&
                        message.timestamp != null &&
                        DateTime(
                              _messages[index - 1].timestamp!.year,
                              _messages[index - 1].timestamp!.month,
                              _messages[index - 1].timestamp!.day,
                            ) !=
                            DateTime(
                              message.timestamp!.year,
                              message.timestamp!.month,
                              message.timestamp!.day,
                            ));
                
                return Column(
                  children: [
                    if (showDateDivider)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          _formatDate(message.timestamp),
                          style: TextStyle(
                            fontSize: 12,
                            color: secondaryTextColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    _buildMessageBubble(
                      message,
                      textColor,
                      secondaryTextColor,
                      isDark,
                    ),
                  ],
                );
              },
            ),
          ),
          // Input Area
          Container(
            padding: EdgeInsets.only(
              left: 8,
              right: 8,
              top: 8,
              bottom: 8 + MediaQuery.of(context).padding.bottom,
            ),
            decoration: BoxDecoration(
              color: isDark ? backgroundDark : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.emoji_emotions_outlined, color: secondaryTextColor),
                  onPressed: () {
                    // TODO: Open emoji picker
                  },
                ),
                IconButton(
                  icon: Icon(Icons.attach_file, color: secondaryTextColor),
                  onPressed: () {
                    // TODO: Open attachment options
                  },
                ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[200],
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _messageController,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        hintText: "Type a message",
                        hintStyle: TextStyle(color: secondaryTextColor),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: secondary,
                  borderRadius: BorderRadius.circular(24),
                  child: InkWell(
                    onTap: _sendMessage,
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      width: 48,
                      height: 48,
                      child: const Icon(Icons.send, color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? dateTime) {
    if (dateTime == null) return '';
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    
    if (messageDate == today) {
      return 'Today';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year}';
    }
  }

  Widget _buildMessageBubble(
    ChatMessage message,
    Color textColor,
    Color secondaryTextColor,
    bool isDark,
  ) {
    final isSent = message.isSent == true;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Row(
        mainAxisAlignment: isSent ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isSent) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: message.senderAvatar != null && message.senderAvatar!.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(message.senderAvatar!),
                        fit: BoxFit.cover,
                        onError: (_, __) {},
                      )
                    : null,
                color: message.senderAvatar == null || message.senderAvatar!.isEmpty
                    ? primary.withOpacity(0.2)
                    : null,
              ),
              child: message.senderAvatar == null || message.senderAvatar!.isEmpty
                  ? Center(
                      child: Text(
                        (message.senderName ?? 'U')[0].toUpperCase(),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: primary,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSent
                    ? (isDark ? secondary.withOpacity(0.3) : sentMessageColor)
                    : (isDark ? Colors.white.withOpacity(0.1) : receivedMessageColor),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(8),
                  topRight: const Radius.circular(8),
                  bottomLeft: Radius.circular(isSent ? 8 : 0),
                  bottomRight: Radius.circular(isSent ? 0 : 8),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isSent)
                    Text(
                      message.senderName ?? 'Unknown',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? secondary : primary,
                      ),
                    ),
                  if (!isSent) const SizedBox(height: 2),
                  Text(
                    message.content ?? '',
                    style: TextStyle(
                      fontSize: 14,
                      color: isSent
                          ? (isDark ? Colors.white : const Color(0xFF111B21))
                          : textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(message.timestamp),
                        style: TextStyle(
                          fontSize: 11,
                          color: secondaryTextColor,
                        ),
                      ),
                      if (isSent) ...[
                        const SizedBox(width: 4),
                        Icon(
                          message.isRead == true ? Icons.done_all : Icons.done,
                          size: 14,
                          color: message.isRead == true
                              ? (isDark ? secondary : Colors.blue)
                              : secondaryTextColor,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isSent) const SizedBox(width: 36),
        ],
      ),
    );
  }
}
