import 'package:flutter/material.dart';
import 'package:nylo_framework/nylo_framework.dart';
import 'package:share_plus/share_plus.dart';
import '/app/models/forum_post.dart';
import '/config/keys.dart';
import '/resources/pages/forum_post_detail_page.dart';

class CommunityForumPage extends NyStatefulWidget {
  static RouteView path = ("/community-forum", (_) => CommunityForumPage());

  CommunityForumPage({super.key}) : super(child: () => _CommunityForumPageState());
}

class _CommunityForumPageState extends NyPage<CommunityForumPage> {
  String _selectedFilter = "Trending";
  String _searchQuery = "";
  List<ForumPost> _posts = [];
  TextEditingController? _searchController;

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
        await _loadPosts();
      };

  Future<void> _loadPosts() async {
    try {
      final postsJson = await Keys.forumPosts.read<List>();
      if (postsJson != null) {
        _posts = postsJson.map((p) => ForumPost.fromJson(p)).toList();
        _sortPosts();
        setState(() {});
      } else {
        _loadDummyPosts();
      }
    } catch (e) {
      print('Error loading posts: $e');
      _loadDummyPosts();
    }
  }

  void _loadDummyPosts() {
    _posts = [
      ForumPost()
        ..id = "1"
        ..userName = "Amaka Okafor"
        ..userAvatar = "https://lh3.googleusercontent.com/aida-public/AB6AXuAJT8HrhyljJMy7ytV5cQY0SZ9Bekg79iONEpmJU72GdNFZ74cjM1tdJmezPd6_X7md4mDMNMlcI70afm_fmNvGLprPdC6h5_c_gYhgCyEOtQ5NCUOcT4UnPL4Kp3Jpn2cOgDleZr1hxOCQHiB5s2eJk1Cjh8D3ELqYmFhmycjNzn6IV6f2ekmsjZuKjRHUW1h70upOIqr4Q5BL0ttTKEdOr3kpCejSrYySJMYYOLJyXM1djeokhAHAO-t1nkYmM5blIr6tv75UDow"
        ..isVerified = true
        ..category = "Crop Science"
        ..content = "What are the best organic pest control methods for tomato farming in Southern Nigeria during the rainy season? My leaves are spotting."
        ..createdAt = DateTime.now().subtract(const Duration(hours: 2))
        ..likes = 24
        ..comments = 12
        ..shares = 5
        ..isLiked = false,
      ForumPost()
        ..id = "2"
        ..userName = "Chidi Eze"
        ..userAvatar = "https://lh3.googleusercontent.com/aida-public/AB6AXuD4lbtsaY4k85t6TL_u4mMlWQJJXa_wOZX5bLOVIzah--Hup81cKmGIQRTs772nrD7ZgZexuVyv7zvpufR6A0oemcS0KCDyH2MNR_JvyOpvXS2YQ8yh3gJTeafAt-XMTjjk6R_ZOjDK2VJOWtyYFzBQWdxV-_-E9HfwHTMKJAAbRTUe-6-l4tSMoD8NSXT1rvZddngyK5oJe_MHRbRwBeCeGKVhijLZKYwKaw_ikp8KOaMYwUyB3cjHp7T4e-9jxouJAuXYXaasQIk"
        ..isVerified = false
        ..category = "Agribusiness"
        ..content = "Just finished the \"Supply Chain 101\" module. It's fascinating how much waste can be reduced through better cold storage logistics! Anyone else working on solar cooling?"
        ..imageUrl = "https://lh3.googleusercontent.com/aida-public/AB6AXuCj-i7d8rRUwqJQHBd5z3osr5aqawB1LjihGcOYmIIt2OHdfcAg-7bqGputt1GImeRKWKENwObFzK1HR_R1iq9Cc18WSRRkreB1V3PGtA0vn0MNtmkobZa48tZkW6a8mGg7z-GQ3wIC3RWdL_M-B8BSx_RL_LN8BfmBWSxdGddY8GFGs8saiDAypVyb5dYuwv4cpjxlmTCmOGvs72uS2IZTUgqXoYVMchanlxhIxwCnBNLvx0CHIjIK4D_PE7D8EZZhRTYaAaRkdC4"
        ..createdAt = DateTime.now().subtract(const Duration(hours: 5))
        ..likes = 89
        ..comments = 31
        ..shares = 14
        ..isLiked = true,
      ForumPost()
        ..id = "3"
        ..userName = "Grace Adeniyi"
        ..userAvatar = "https://lh3.googleusercontent.com/aida-public/AB6AXuDTP0jqZ8rFOAsvhg8z62_08xKGlKE2Atcrh7wMEGaaTXdOq6qaWhPjyeQ651HgbhMyZ1thYfEKvUEceNITQs5ZndTPXHjdoceqFqcUluQGy0CFGxogMGaxS_pa6FPZNH2dVZREliZxq04-1BbWI5f6Y_41bDZiTbiPXNPa2oCxEvIJsvhZVwwSNxUT0J2KqoWvIlm2iJ9aJnL2s6_D6mKtThs5LWXM65kaZzpTWQebePKadbBgO_1Gp2z1b7cHStcfG75A41EK1_w"
        ..isVerified = false
        ..category = "General"
        ..content = "Is there a government subsidy currently available for smallholder irrigation kits in Lagos state?"
        ..createdAt = DateTime.now().subtract(const Duration(hours: 8))
        ..likes = 15
        ..comments = 8
        ..shares = 2
        ..isLiked = false,
    ];
    _sortPosts();
    setState(() {});
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
        final contentMatch = (post.content?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
        final userNameMatch = (post.userName?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
        final categoryMatch = (post.category?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
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
    setState(() {
      post.isLiked = !(post.isLiked ?? false);
      if (post.isLiked == true) {
        post.likes = (post.likes ?? 0) + 1;
      } else {
        post.likes = (post.likes ?? 0) - 1;
        if (post.likes! < 0) post.likes = 0;
      }
    });

    // Save to storage
    try {
      final postsJson = _posts.map((p) => p.toJson()).toList();
      await Keys.forumPosts.save(postsJson);
    } catch (e) {
      print('Error saving posts: $e');
    }
  }

  Future<void> _sharePost(ForumPost post) async {
    try {
      await Share.share(
        '${post.content}\n\nShared from Agrisiti Community Forum',
        subject: 'Post by ${post.userName}',
      );
      setState(() {
        post.shares = (post.shares ?? 0) + 1;
      });
      
      // Save to storage
      final postsJson = _posts.map((p) => p.toJson()).toList();
      await Keys.forumPosts.save(postsJson);
    } catch (e) {
      print('Error sharing post: $e');
    }
  }

  Future<void> _createNewPost() async {
    // TODO: Navigate to create post page
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Create post feature coming soon"),
        backgroundColor: Colors.orange,
      ),
    );
  }

  @override
  void dispose() {
    _searchController?.dispose();
    super.dispose();
  }

  @override
  LoadingStyle get loadingStyle => LoadingStyle.normal();

  @override
  Widget view(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? backgroundDark : backgroundLight;
    final surfaceColor = isDark ? Colors.white.withValues(alpha: 0.05) : surfaceLight;
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
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[100]!,
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
                          hintStyle: TextStyle(color: secondaryTextColor, fontSize: 14),
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
                  _buildFilterChip("Trending", _selectedFilter == "Trending", () {
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
                  _buildFilterChip("Soil Health", _selectedFilter == "Soil Health", () {
                    setState(() {
                      _selectedFilter = "Soil Health";
                      _sortPosts();
                    });
                  }, isDark, primary, secondary),
                  const SizedBox(width: 8),
                  _buildFilterChip("Market Trends", _selectedFilter == "Market Trends", () {
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
                          Icon(Icons.forum_outlined, size: 64, color: secondaryTextColor),
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
                color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[100]!,
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
                    color: (post.isVerified == true ? secondary : primary).withValues(alpha: 0.2),
                    width: 2,
                  ),
                  image: post.userAvatar != null && post.userAvatar!.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(post.userAvatar!),
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
                      post.content ?? '',
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
                            color: isDark ? Colors.grey[800]! : Colors.grey[100]!,
                          ),
                          image: DecorationImage(
                            image: NetworkImage(post.imageUrl!),
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
                          icon: post.isLiked == true ? Icons.favorite : Icons.favorite_outline,
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
                            routeTo(ForumPostDetailPage.path, data: {'post': post});
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
