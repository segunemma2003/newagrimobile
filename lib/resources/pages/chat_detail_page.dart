import 'package:flutter/material.dart';
import 'package:nylo_framework/nylo_framework.dart';
import '/app/models/message.dart';
import '/app/models/chat_message.dart';
import '/app/networking/api_service.dart';
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
  String? _courseId;
  String? _recipientId;
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = true;

  // Color scheme
  static const Color primary = Color(0xFF3F6967);
  static const Color secondary = Color(0xFF50C1AE);
  static const Color backgroundDark = Color(0xFF161C1B);
  static const Color sentMessageColor = Color(0xFFDCF8C6);
  static const Color receivedMessageColor = Color(0xFFFFFFFF);

  @override
  get init => () async {
        final data = widget.data<Map<String, dynamic>>();
        if (data != null) {
          if (data['conversation'] != null) {
            _conversation = data['conversation'] as Message;
            // Extract course ID and recipient ID from conversation
            final convId = _conversation!.conversationId ?? _conversation!.id;
            if (convId != null && convId.contains('-')) {
              final parts = convId.split('-');
              if (parts.length >= 2) {
                _courseId = parts[0];
                _recipientId = parts[1];
              }
            }
          }
          // Also check if course_id and recipient_id are passed directly
          if (data['course_id'] != null) _courseId = data['course_id']?.toString();
          if (data['recipient_id'] != null) _recipientId = data['recipient_id']?.toString();
        }
        _messageController = TextEditingController();
        await _loadCurrentUser();
        await _loadMessages();
        _scrollToBottom();
      };

  Future<void> _loadCurrentUser() async {
    try {
      final userData = await Keys.auth.read<Map<String, dynamic>>();
      _currentUserId = userData?['id']?.toString();
      _currentUserName = userData?['name']?.toString() ?? 'You';
      _currentUserAvatar = userData?['avatar']?.toString();
    } catch (e) {
      print('Error loading current user: $e');
    }
  }

  Future<void> _loadMessages() async {
    if (_courseId == null || _currentUserId == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Fetch course messages from API
      final response = await api<ApiService>(
        (request) => request.fetchCourseMessages(_courseId!),
      );

      if (response != null) {
        final messagesData = response is List ? response : (response['data'] ?? []);
        _messages = [];

        for (var msgData in messagesData) {
          final senderId = msgData['sender_id']?.toString();
          final recipientId = msgData['recipient_id']?.toString();
          
          // Only include messages in this conversation
          if ((senderId == _currentUserId && recipientId == _recipientId) ||
              (senderId == _recipientId && recipientId == _currentUserId)) {
            final isSent = senderId == _currentUserId;
            final sender = msgData['sender'];
            final recipient = msgData['recipient'];
            final otherUser = isSent ? recipient : sender;

            final chatMsg = ChatMessage()
              ..id = msgData['id']?.toString()
              ..conversationId = _conversation?.id ?? '${_courseId}-$_recipientId'
              ..senderId = senderId
              ..senderName = otherUser?['name'] ?? (isSent ? _currentUserName : 'Unknown')
              ..senderAvatar = otherUser?['avatar']
              ..content = msgData['message'] ?? msgData['subject'] ?? ''
              ..timestamp = msgData['created_at'] != null
                  ? DateTime.tryParse(msgData['created_at'].toString())
                  : null
              ..isSent = isSent
              ..isRead = msgData['is_read'] ?? false
              ..type = 'text';

            _messages.add(chatMsg);

            // Mark as read if user is recipient
            if (!isSent && msgData['is_read'] == false) {
              try {
                await api<ApiService>(
                  (request) => request.markMessageAsRead(msgData['id']?.toString() ?? ''),
                );
              } catch (e) {
                print('Error marking message as read: $e');
              }
            }
          }
        }

        // Sort by timestamp
        _messages.sort((a, b) {
          final aTime = a.timestamp ?? DateTime(2000);
          final bTime = b.timestamp ?? DateTime(2000);
          return aTime.compareTo(bTime);
        });

        setState(() {
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading messages: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _sendMessage() async {
    if (_courseId == null || _recipientId == null || _messageController == null || 
        _messageController!.text.trim().isEmpty || _currentUserId == null) {
      return;
    }

    final messageText = _messageController!.text.trim();
    _messageController!.clear();

    // Optimistically add message to UI
    final tempMessage = ChatMessage()
      ..id = DateTime.now().millisecondsSinceEpoch.toString()
      ..conversationId = _conversation?.id ?? '${_courseId}-$_recipientId'
      ..senderId = _currentUserId
      ..senderName = _currentUserName
      ..senderAvatar = _currentUserAvatar
      ..content = messageText
      ..timestamp = DateTime.now()
      ..isSent = true
      ..isRead = false
      ..type = 'text';

    setState(() {
      _messages.add(tempMessage);
    });

    _scrollToBottom();

    // Send to API
    try {
      final response = await api<ApiService>(
        (request) => request.sendMessage({
          'course_id': _courseId,
          'recipient_id': _recipientId,
          'message': messageText,
          'subject': null, // Optional subject
        }),
      );

      if (response != null) {
        // Update message with real ID from server
        final msgData = response is Map ? response : response['data'];
        if (msgData != null && msgData['id'] != null) {
          tempMessage.id = msgData['id']?.toString();
          tempMessage.timestamp = msgData['created_at'] != null
              ? DateTime.tryParse(msgData['created_at'].toString())
              : DateTime.now();
        }
        setState(() {});
      }
    } catch (e) {
      print('Error sending message: $e');
      // Show error to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send message. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? backgroundDark : const Color(0xFFECE5DD);
    final textColor = isDark ? Colors.white : const Color(0xFF131515);
    final secondaryTextColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: isDark ? backgroundDark : primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            if (_conversation?.senderAvatar != null)
              Container(
                width: 40,
                height: 40,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: NetworkImage(_conversation!.senderAvatar!),
                    fit: BoxFit.cover,
                    onError: (_, __) {},
                  ),
                ),
              ),
            Expanded(
              child: Text(
                _conversation?.senderName ?? "Chat",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
      body: _conversation == null && _courseId == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 80,
                    color: secondaryTextColor.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "Conversation not found",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Messages List
                Expanded(
                  child: _isLoading
                      ? Center(child: CircularProgressIndicator(color: secondary))
                      : ListView.builder(
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
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey[200],
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
      // Commented out - messaging functionality
      /*
      if (_conversation == null) {
        return Scaffold(
          appBar: AppBar(title: const Text("Chat")),
          body: const Center(child: Text("Conversation not found")),
        );
      }

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
                      ? Colors.white.withValues(alpha: 0.2)
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
                    color: Colors.black.withValues(alpha: 0.05),
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
                        color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey[200],
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
      */
    );
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
                    ? primary.withValues(alpha: 0.2)
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
                    ? (isDark ? secondary.withValues(alpha: 0.3) : sentMessageColor)
                    : (isDark ? Colors.white.withValues(alpha: 0.1) : receivedMessageColor),
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
