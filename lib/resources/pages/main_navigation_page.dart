import 'package:flutter/material.dart';
import 'package:nylo_framework/nylo_framework.dart';
import '/resources/pages/home_page.dart';
import '/resources/pages/explore_page.dart';
import '/resources/pages/courses_page.dart';
import '/resources/pages/messages_page.dart';
import '/resources/pages/profile_page.dart';
import '/resources/pages/community_forum_page.dart';
import '/app/providers/language_provider.dart';

class MainNavigationPage extends NyStatefulWidget {
  static RouteView path = ("/main", (_) => MainNavigationPage());

  MainNavigationPage({super.key})
      : super(child: () => _MainNavigationPageState());
}

class _MainNavigationPageState extends NyPage<MainNavigationPage> {
  int _currentIndex = 0;
  final _languageProvider = LanguageProvider();

  @override
  void initState() {
    super.initState();
    _languageProvider.addListener(_onLanguageChanged);
  }

  @override
  void dispose() {
    _languageProvider.removeListener(_onLanguageChanged);
    super.dispose();
  }

  void _onLanguageChanged() {
    setState(() {});
  }

  final List<Widget> _pages = [
    HomePage(),
    ExplorePage(),
    CoursesPage(),
    CommunityForumPage(),
    MessagesPage(),
    ProfilePage(),
  ];

  @override
  Widget view(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF13251E) : Colors.white;
    final borderColor =
        isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[200]!;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: bgColor,
          border: Border(
            top: BorderSide(color: borderColor),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          selectedItemColor: const Color(0xFF50C1AE), // Accent color
          unselectedItemColor:
              isDark ? const Color(0xFF9DB9A3) : Colors.grey[400],
          selectedLabelStyle: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
          elevation: 0,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home_outlined),
              activeIcon: const Icon(Icons.home),
              label: "Home",
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.explore_outlined),
              activeIcon: const Icon(Icons.explore),
              label: "Explore",
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.school_outlined),
              activeIcon: const Icon(Icons.school),
              label: "Learning",
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.forum_outlined),
              activeIcon: const Icon(Icons.forum),
              label: "Community",
            ),
            BottomNavigationBarItem(
              icon: Stack(
                children: [
                  const Icon(Icons.chat_bubble_outline),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
              activeIcon: Stack(
                children: [
                  const Icon(Icons.chat_bubble),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
              label: "Messages",
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person_outline),
              activeIcon: const Icon(Icons.person),
              label: "Profile",
            ),
          ],
        ),
      ),
    );
  }
}
