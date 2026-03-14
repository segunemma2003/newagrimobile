import 'package:flutter/material.dart';
import 'package:nylo_framework/nylo_framework.dart';
import 'package:share_plus/share_plus.dart';
import '/app/models/forum_post.dart';
import '/app/models/forum_comment.dart';
import '/app/networking/api_service.dart';
import '/app/helpers/text_helper.dart';
import '/app/helpers/image_helper.dart';
import '/config/keys.dart';

class ForumPostDetailPage extends NyStatefulWidget {
  static RouteView path = ("/forum-post-detail", (_) => ForumPostDetailPage());

  ForumPostDetailPage({super.key})
      : super(child: () => _ForumPostDetailPageState());
}

class _ForumPostDetailPageState extends NyPage<ForumPostDetailPage> {
  ForumPost? _post;
  List<ForumComment> _comments = [];
  TextEditingController? _commentController;
  // Color scheme
  static const Color primary = Color(0xFF3F6967);
  static const Color secondary = Color(0xFF50C1AE);
  static const Color backgroundLight = Color(0xFFFFFFFF);
  static const Color backgroundDark = Color(0xFF161C1B);
  static const Color textMain = Color(0xFF131515);
  static const Color textSub = Color(0xFF6F7B7B);

  @override
  get init => () async {
        final data = widget.data<Map<String, dynamic>>();
        if (data != null && data['post'] != null) {
          _post = data['post'] as ForumPost;
        }
        _commentController = TextEditingController();
        await _loadCurrentUser();
        await _loadComments();
      };

  Future<void> _loadCurrentUser() async {
    // Current implementation of comments API does not require explicit user fields
    // since the backend uses the authenticated user. This is kept for future use.
  }

  Future<void> _loadComments() async {
    if (_post?.id == null) return;

    try {
      final api = ApiService();
      final response = await api.get('/forum/posts/${_post!.id}/comments');
      final commentsJson = response['data'] as List<dynamic>? ?? [];
      _comments = commentsJson
          .map((c) => ForumComment.fromJson(c))
          .where((c) => c.parentId == null)
          .toList();
      _comments.sort((a, b) {
        final aTime = a.createdAt ?? DateTime(2000);
        final bTime = b.createdAt ?? DateTime(2000);
        return bTime.compareTo(aTime);
      });
      setState(() {});
    } catch (e) {
      print('Error loading comments: $e');
    }
  }

  Future<void> _postComment() async {
    if (_post == null ||
        _post!.id == null ||
        (_commentController?.text.trim().isEmpty ?? true)) {
      return;
    }

    final api = ApiService();
    try {
      final response = await api.addForumComment(
        _post!.id!,
        _commentController!.text.trim(),
      );
      final newComment = ForumComment.fromJson(response['data'] ?? response);

      setState(() {
        _comments.insert(0, newComment);
        _post!.comments = (_post!.comments ?? 0) + 1;
        _commentController!.clear();
      });
    } catch (e) {
      print('Error saving comment: $e');
    }
  }

  Future<void> _toggleLikeComment(ForumComment comment) async {
    setState(() {
      comment.isLiked = !(comment.isLiked ?? false);
      if (comment.isLiked == true) {
        comment.likes = (comment.likes ?? 0) + 1;
      } else {
        comment.likes = (comment.likes ?? 0) - 1;
        if (comment.likes! < 0) comment.likes = 0;
      }
    });

    // Optionally sync likes with backend later
  }

  Future<void> _toggleLikePost() async {
    if (_post == null) return;

    try {
      final api = ApiService();
      final like = !(_post!.isLiked ?? false);
      final response = await api.toggleForumPostLike(_post!.id!, like);
      final updatedPost = ForumPost.fromJson(response['data'] ?? response);

      setState(() {
        _post = updatedPost;
        _post!.isLiked = like;
      });
    } catch (e) {
      print('Error toggling post like: $e');
    }
  }

  Future<void> _sharePost() async {
    if (_post == null) return;

    try {
      await Share.share(
        '${_post!.content}\n\nShared from Agrisiti Community Forum',
        subject: 'Post by ${_post!.userName}',
      );
      setState(() {
        _post!.shares = (_post!.shares ?? 0) + 1;
      });

      // Save to storage
      final postsJson = await Keys.forumPosts.read<List>() ?? [];
      final postIndex = postsJson.indexWhere((p) => p['id'] == _post!.id);
      if (postIndex != -1) {
        postsJson[postIndex] = _post!.toJson();
        await Keys.forumPosts.save(postsJson);
      }
    } catch (e) {
      print('Error sharing post: $e');
    }
  }

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return '';

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  @override
  void dispose() {
    _commentController?.dispose();
    super.dispose();
  }

  @override
  LoadingStyle get loadingStyle => LoadingStyle.normal();

  @override
  Widget view(BuildContext context) {
    if (_post == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Post")),
        body: const Center(child: Text("Post not found")),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? backgroundDark : backgroundLight;
    final textColor = isDark ? Colors.white : textMain;
    final secondaryTextColor = isDark ? Colors.grey[400]! : textSub;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          "Post",
          style: TextStyle(color: textColor, fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Post Content
                  _buildPostHeader(_post!, textColor, secondaryTextColor,
                      isDark, primary, secondary),
                  if (_post!.imageUrl != null &&
                      _post!.imageUrl!.isNotEmpty) ...[
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: NetworkImage(getImageUrl(_post!.imageUrl!)),
                          fit: BoxFit.cover,
                          onError: (_, __) {},
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  // Post Actions
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        _buildActionButton(
                          icon: _post!.isLiked == true
                              ? Icons.favorite
                              : Icons.favorite_outline,
                          label: "${_post!.likes ?? 0}",
                          isActive: _post!.isLiked == true,
                          activeColor: Colors.red,
                          onTap: _toggleLikePost,
                          secondaryTextColor: secondaryTextColor,
                        ),
                        const SizedBox(width: 24),
                        _buildActionButton(
                          icon: Icons.chat_bubble_outline,
                          label: "${_post!.comments ?? 0}",
                          isActive: false,
                          activeColor: primary,
                          onTap: () {},
                          secondaryTextColor: secondaryTextColor,
                        ),
                        const SizedBox(width: 24),
                        _buildActionButton(
                          icon: Icons.share_outlined,
                          label: "${_post!.shares ?? 0}",
                          isActive: false,
                          activeColor: secondary,
                          onTap: _sharePost,
                          secondaryTextColor: secondaryTextColor,
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  // Comments Section
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      "Comments (${_comments.length})",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                  ),
                  // Comments List
                  ..._comments.map((comment) => _buildCommentItem(
                        comment,
                        textColor,
                        secondaryTextColor,
                        isDark,
                        primary,
                        secondary,
                      )),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
          // Comment Input
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: 12 + MediaQuery.of(context).padding.bottom,
            ),
            decoration: BoxDecoration(
              color: bgColor,
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.grey[200]!,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      hintText: "Write a comment...",
                      hintStyle: TextStyle(color: secondaryTextColor),
                      filled: true,
                      fillColor: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: primary,
                  borderRadius: BorderRadius.circular(24),
                  child: InkWell(
                    onTap: _postComment,
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      width: 48,
                      height: 48,
                      child:
                          const Icon(Icons.send, color: Colors.white, size: 20),
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

  Widget _buildPostHeader(
    ForumPost post,
    Color textColor,
    Color secondaryTextColor,
    bool isDark,
    Color primary,
    Color secondary,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: (post.isVerified == true ? secondary : primary)
                    .withValues(alpha: 0.2),
                width: 2,
              ),
              image: post.userAvatar != null && post.userAvatar!.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(getImageUrl(post.userAvatar!)),
                      fit: BoxFit.cover,
                      onError: (_, __) {},
                    )
                  : null,
              color: post.userAvatar == null || post.userAvatar!.isEmpty
                  ? primary.withValues(alpha: 0.1)
                  : null,
            ),
            child: post.userAvatar == null || post.userAvatar!.isEmpty
                ? Center(
                    child: Text(
                      (post.userName ?? 'U')[0].toUpperCase(),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: primary,
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      post.userName ?? 'Unknown',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    if (post.isVerified == true) ...[
                      const SizedBox(width: 4),
                      Icon(
                        Icons.verified,
                        size: 14,
                        color: secondary,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  "${_formatTime(post.createdAt)} • ${post.category ?? 'General'}",
                  style: TextStyle(
                    fontSize: 11,
                    color: secondaryTextColor,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  stripHtmlTags(post.content ?? ''),
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey[200] : textColor,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentItem(
    ForumComment comment,
    Color textColor,
    Color secondaryTextColor,
    bool isDark,
    Color primary,
    Color secondary,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image:
                  comment.userAvatar != null && comment.userAvatar!.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(getImageUrl(comment.userAvatar!)),
                          fit: BoxFit.cover,
                          onError: (_, __) {},
                        )
                      : null,
              color: comment.userAvatar == null || comment.userAvatar!.isEmpty
                  ? primary.withValues(alpha: 0.1)
                  : null,
            ),
            child: comment.userAvatar == null || comment.userAvatar!.isEmpty
                ? Center(
                    child: Text(
                      (comment.userName ?? 'U')[0].toUpperCase(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: primary,
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.userName ?? 'Unknown',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    if (comment.isVerified == true) ...[
                      const SizedBox(width: 4),
                      Icon(
                        Icons.verified,
                        size: 12,
                        color: secondary,
                      ),
                    ],
                    const SizedBox(width: 8),
                    Text(
                      _formatTime(comment.createdAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: secondaryTextColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  stripHtmlTags(comment.content ?? ''),
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey[300] : textColor,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _toggleLikeComment(comment),
                        borderRadius: BorderRadius.circular(8),
                        child: Row(
                          children: [
                            Icon(
                              comment.isLiked == true
                                  ? Icons.favorite
                                  : Icons.favorite_outline,
                              size: 16,
                              color: comment.isLiked == true
                                  ? Colors.red
                                  : secondaryTextColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "${comment.likes ?? 0}",
                              style: TextStyle(
                                fontSize: 11,
                                color: secondaryTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required Color activeColor,
    required VoidCallback onTap,
    required Color secondaryTextColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isActive ? activeColor : secondaryTextColor,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: secondaryTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
