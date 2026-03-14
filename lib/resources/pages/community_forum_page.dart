import 'package:flutter/material.dart';
import 'package:nylo_framework/nylo_framework.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '/app/models/forum_post.dart';
import '/app/networking/api_service.dart';
import '/app/helpers/text_helper.dart';
import '/app/helpers/image_helper.dart';
import '/config/keys.dart';
import '/resources/pages/forum_post_detail_page.dart';

class CommunityForumPage extends NyStatefulWidget {
  static RouteView path = ("/community-forum", (_) => CommunityForumPage());

  CommunityForumPage({super.key})
      : super(child: () => _CommunityForumPageState());
}

class _CommunityForumPageState extends NyPage<CommunityForumPage> {
  String _selectedFilter = "Trending";
  String _searchQuery = "";
  List<ForumPost> _posts = [];
  TextEditingController? _searchController;
  TextEditingController? _newPostController;
  String _selectedCategoryForPost = "General";
  XFile? _selectedImageFile;

  // Color scheme - maintain from other pages
  static const Color primary = Color(0xFF3F6967);
  static const Color secondary = Color(0xFF50C1AE);
  static const Color backgroundLight = Color(0xFFFFFFFF);
  static const Color backgroundDark = Color(0xFF161C1B);
  static const Color surfaceLight = Color(0xFFF2F3F3);
  static const Color textMain = Color(0xFF131515);
  static const Color textSub = Color(0xFF6F7B7B);

  @override
  get init => () async {
        _searchController = TextEditingController();
        _newPostController = TextEditingController();
        await _loadPosts();
      };

  Future<void> _loadPosts() async {
    try {
      final api = ApiService();
      final response = await api.fetchForumPosts(
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        category: _selectedFilter != "Trending" && _selectedFilter != "Newest"
            ? _selectedFilter
            : null,
        sort: _selectedFilter == "Trending" ? "trending" : "newest",
      );
      final data = response['data'] as List<dynamic>? ?? [];
      _posts = data.map((p) => ForumPost.fromJson(p)).toList();
      _sortPosts();
      setState(() {});
    } catch (e) {
      print('Error loading posts: $e');
    }
  }

  void _sortPosts() {
    switch (_selectedFilter) {
      case "Trending":
        _posts.sort((a, b) {
          final aScore = (a.likes ?? 0) + (a.comments ?? 0) * 2;
          final bScore = (b.likes ?? 0) + (b.comments ?? 0) * 2;
          return bScore.compareTo(aScore);
        });
        break;
      case "Newest":
        _posts.sort((a, b) {
          final aTime = a.createdAt ?? DateTime(2000);
          final bTime = b.createdAt ?? DateTime(2000);
          return bTime.compareTo(aTime);
        });
        break;
      case "Soil Health":
      case "Market Trends":
        _posts = _posts.where((p) => p.category == _selectedFilter).toList();
        break;
    }
  }

  List<ForumPost> get _filteredPosts {
    var filtered = _posts;

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((post) {
        final contentMatch =
            (post.content?.toLowerCase().contains(_searchQuery.toLowerCase()) ??
                false);
        final userNameMatch = (post.userName
                ?.toLowerCase()
                .contains(_searchQuery.toLowerCase()) ??
            false);
        final categoryMatch = (post.category
                ?.toLowerCase()
                .contains(_searchQuery.toLowerCase()) ??
            false);
        return contentMatch || userNameMatch || categoryMatch;
      }).toList();
    }

    return filtered;
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

  Future<void> _toggleLike(ForumPost post) async {
    if (post.id == null) return;

    final originalLikeState = post.isLiked ?? false;
    final like = !originalLikeState;

    try {
      final api = ApiService();
      final response = await api.toggleForumPostLike(post.id!, like);
      final updatedPost = ForumPost.fromJson(response['data'] ?? response);

      setState(() {
        final index = _posts.indexWhere((p) => p.id == post.id);
        if (index != -1) {
          _posts[index] = updatedPost;
        }
      });

      // Save to storage
      try {
        final postsJson = _posts.map((p) => p.toJson()).toList();
        await Keys.forumPosts.save(postsJson);
      } catch (e) {
        print('Error saving posts: $e');
      }
    } catch (e) {
      print('Error toggling post like: $e');
      // Revert UI change on error
      setState(() {
        post.isLiked = originalLikeState;
        if (post.isLiked == true) {
          post.likes = (post.likes ?? 0) + 1;
        } else {
          post.likes = (post.likes ?? 0) - 1;
          if (post.likes! < 0) post.likes = 0;
        }
      });
    }
  }

  Future<void> _sharePost(ForumPost post) async {
    if (post.id == null) return;

    try {
      // Share using native share dialog
      try {
        await Share.share(
          stripHtmlTags(post.content ?? ''),
          subject: 'Post by ${post.userName}',
        );
      } catch (e) {
        // Handle iOS sharePositionOrigin error gracefully
        print('Share dialog error (non-critical): $e');
      }

      // Call API to increment share count
      try {
        final api = ApiService();
        final response = await api.shareForumPost(post.id!);
        final updatedPost = ForumPost.fromJson(response['data'] ?? response);

        setState(() {
          final index = _posts.indexWhere((p) => p.id == post.id);
          if (index != -1) {
            _posts[index].shares = updatedPost.shares ?? post.shares;
          }
        });

        // Save to storage
        try {
          final postsJson = _posts.map((p) => p.toJson()).toList();
          await Keys.forumPosts.save(postsJson);
        } catch (e) {
          print('Error saving posts: $e');
        }
      } catch (e) {
        print('Error updating share count: $e');
        // Still update UI locally if API fails
        setState(() {
          post.shares = (post.shares ?? 0) + 1;
        });
      }
    } catch (e) {
      print('Error sharing post: $e');
    }
  }

  Future<void> _createNewPost() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? backgroundDark : backgroundLight;
    final textColor = isDark ? Colors.white : textMain;
    final secondaryTextColor = isDark ? Colors.grey[400]! : textSub;

    _newPostController?.clear();
    _selectedCategoryForPost = "General";
    _selectedImageFile = null;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Image picker
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: () async {
                            final picker = ImagePicker();
                            final picked = await picker.pickImage(
                              source: ImageSource.gallery,
                              imageQuality: 80,
                              maxWidth: 1600,
                            );
                            if (picked != null) {
                              setState(() {
                                _selectedImageFile = picked;
                              });
                            }
                          },
                          icon: const Icon(Icons.image_outlined, size: 18),
                          label: const Text(
                            "Add image",
                            style: TextStyle(fontSize: 12),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            side: BorderSide(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.1)
                                  : Colors.grey[300]!,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        if (_selectedImageFile != null)
                          Expanded(
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    File(_selectedImageFile!.path),
                                    width: 40,
                                    height: 40,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    "Image selected",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: secondaryTextColor,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.close,
                                    size: 18,
                                    color: secondaryTextColor,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _selectedImageFile = null;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Start a discussion",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Share a question, idea, or experience with the Agrisiti community.",
                      style: TextStyle(
                        fontSize: 13,
                        color: secondaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Category",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: secondaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final category in [
                          "General",
                          "Crop Science",
                          "Livestock",
                          "Agribusiness",
                          "Soil Health",
                          "Market Trends",
                        ])
                          ChoiceChip(
                            label: Text(
                              category,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: _selectedCategoryForPost == category
                                    ? Colors.white
                                    : secondaryTextColor,
                              ),
                            ),
                            selected: _selectedCategoryForPost == category,
                            selectedColor: primary,
                            backgroundColor:
                                isDark ? Colors.white12 : surfaceLight,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _selectedCategoryForPost = category;
                                });
                              }
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _newPostController,
                      maxLines: 6,
                      minLines: 4,
                      style: TextStyle(color: textColor, fontSize: 14),
                      decoration: InputDecoration(
                        hintText:
                            "What do you want to ask or share with the community?",
                        hintStyle: TextStyle(
                          color: secondaryTextColor,
                          fontSize: 14,
                        ),
                        filled: true,
                        fillColor: isDark
                            ? Colors.white.withValues(alpha: 0.03)
                            : surfaceLight,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: Colors.grey[300]!,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: primary.withValues(alpha: 0.8),
                            width: 1.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : Colors.grey[300]!,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                            child: Text(
                              "Cancel",
                              style: TextStyle(
                                color: secondaryTextColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              final content =
                                  _newPostController?.text.trim() ?? "";
                              if (content.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        "Please write something before posting."),
                                  ),
                                );
                                return;
                              }

                              try {
                                final api = ApiService();
                                final response = await api.createForumPost(
                                  category: _selectedCategoryForPost,
                                  content: content,
                                  imagePath: _selectedImageFile?.path,
                                );
                                final created = ForumPost.fromJson(
                                    response['data'] ?? response);

                                setState(() {
                                  _posts.insert(0, created);
                                  _sortPosts();
                                });

                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Post published"),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              } catch (e) {
                                print('Error creating post: $e');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        "Failed to publish post. Please try again."),
                                    backgroundColor: Colors.redAccent,
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primary,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                            child: const Text(
                              "Post",
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController?.dispose();
    _newPostController?.dispose();
    super.dispose();
  }

  @override
  LoadingStyle get loadingStyle => LoadingStyle.normal();

  @override
  Widget view(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? backgroundDark : backgroundLight;
    final surfaceColor =
        isDark ? Colors.white.withValues(alpha: 0.05) : surfaceLight;
    final textColor = isDark ? Colors.white : textMain;
    final secondaryTextColor = isDark ? Colors.grey[400]! : textSub;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: bgColor.withValues(alpha: 0.8),
                border: Border(
                  bottom: BorderSide(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.grey[100]!,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 40,
                        height: 40,
                        child: Icon(
                          Icons.arrow_back_ios_new,
                          color: primary,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      "Community Forum",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        // TODO: Navigate to notifications
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 40,
                        height: 40,
                        child: Icon(
                          Icons.notifications_outlined,
                          color: primary,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Search Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      child: Icon(
                        Icons.search,
                        color: secondaryTextColor,
                        size: 24,
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: TextStyle(color: textColor, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: "Search discussions, topics...",
                          hintStyle: TextStyle(
                              color: secondaryTextColor, fontSize: 14),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Filter Chips
            Container(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildFilterChip("Trending", _selectedFilter == "Trending",
                      () {
                    setState(() {
                      _selectedFilter = "Trending";
                      _sortPosts();
                    });
                  }, isDark, primary, secondary),
                  const SizedBox(width: 8),
                  _buildFilterChip("Newest", _selectedFilter == "Newest", () {
                    setState(() {
                      _selectedFilter = "Newest";
                      _sortPosts();
                    });
                  }, isDark, primary, secondary),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                      "Soil Health", _selectedFilter == "Soil Health", () {
                    setState(() {
                      _selectedFilter = "Soil Health";
                      _sortPosts();
                    });
                  }, isDark, primary, secondary),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                      "Market Trends", _selectedFilter == "Market Trends", () {
                    setState(() {
                      _selectedFilter = "Market Trends";
                      _sortPosts();
                    });
                  }, isDark, primary, secondary),
                ],
              ),
            ),
            // Posts Feed
            Expanded(
              child: _filteredPosts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.forum_outlined,
                              size: 64, color: secondaryTextColor),
                          const SizedBox(height: 16),
                          Text(
                            "No posts found",
                            style: TextStyle(
                              fontSize: 16,
                              color: secondaryTextColor,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredPosts.length,
                      itemBuilder: (context, index) {
                        return _buildPostCard(
                          _filteredPosts[index],
                          textColor,
                          secondaryTextColor,
                          surfaceColor,
                          isDark,
                          primary,
                          secondary,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "forum_fab",
        onPressed: _createNewPost,
        backgroundColor: primary,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    bool isSelected,
    VoidCallback onTap,
    bool isDark,
    Color primary,
    Color secondary,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: isSelected
                ? primary
                : (isDark ? Colors.white.withValues(alpha: 0.1) : surfaceLight),
            borderRadius: BorderRadius.circular(18),
            border: isSelected
                ? null
                : Border.all(
                    color: isDark ? Colors.grey[700]! : Colors.grey[100]!,
                  ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.grey[300] : textMain),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPostCard(
    ForumPost post,
    Color textColor,
    Color secondaryTextColor,
    Color surfaceColor,
    bool isDark,
    Color primary,
    Color secondary,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          routeTo(ForumPostDetailPage.path, data: {'post': post});
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.grey[100]!,
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
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
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
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
                        ),
                        Icon(
                          Icons.more_horiz,
                          size: 20,
                          color: secondaryTextColor,
                        ),
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
                    const SizedBox(height: 8),
                    // Post Content
                    Text(
                      stripHtmlTags(post.content ?? ''),
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey[200] : textColor,
                        height: 1.5,
                      ),
                    ),
                    // Image if available
                    if (post.imageUrl != null && post.imageUrl!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        height: 160,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                isDark ? Colors.grey[800]! : Colors.grey[100]!,
                          ),
                          image: DecorationImage(
                            image: NetworkImage(getImageUrl(post.imageUrl!)),
                            fit: BoxFit.cover,
                            onError: (_, __) {},
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    // Engagement Actions
                    Row(
                      children: [
                        _buildActionButton(
                          icon: post.isLiked == true
                              ? Icons.favorite
                              : Icons.favorite_outline,
                          label: "${post.likes ?? 0}",
                          isActive: post.isLiked == true,
                          activeColor: Colors.red,
                          onTap: () => _toggleLike(post),
                          secondaryTextColor: secondaryTextColor,
                        ),
                        const SizedBox(width: 24),
                        _buildActionButton(
                          icon: Icons.chat_bubble_outline,
                          label: "${post.comments ?? 0}",
                          isActive: false,
                          activeColor: primary,
                          onTap: () {
                            routeTo(ForumPostDetailPage.path,
                                data: {'post': post});
                          },
                          secondaryTextColor: secondaryTextColor,
                        ),
                        const SizedBox(width: 24),
                        _buildActionButton(
                          icon: Icons.share_outlined,
                          label: "${post.shares ?? 0}",
                          isActive: false,
                          activeColor: secondary,
                          onTap: () => _sharePost(post),
                          secondaryTextColor: secondaryTextColor,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
