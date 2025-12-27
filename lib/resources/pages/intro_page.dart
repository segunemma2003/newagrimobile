import 'package:flutter/material.dart';
import 'package:nylo_framework/nylo_framework.dart';
import '/resources/widgets/safearea_widget.dart';
import '/config/keys.dart';

class IntroPage extends NyStatefulWidget {
  static RouteView path = ("/intro", (_) => IntroPage());

  IntroPage({super.key}) : super(child: () => _IntroPageState());
}

class _IntroPageState extends NyPage<IntroPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  get init => () async {
        // Check if intro has already been seen
        try {
          final hasSeenIntro = await Keys.hasSeenIntro.read<bool>() ?? false;
          if (hasSeenIntro) {
            // Check if user is authenticated
            final isAuthenticated = await Auth.isAuthenticated();
            if (isAuthenticated) {
              routeTo("/main");
            } else {
              routeTo("/login");
            }
          }
        } catch (e) {
          // Handle storage errors gracefully - assume intro hasn't been seen
          // Suppress error logging for Keychain issues on simulator
          if (!e.toString().contains('-34018')) {
            print('Warning: Failed to read intro status: $e');
          }
        }
      };

  @override
  LoadingStyle get loadingStyle => LoadingStyle.none();

  @override
  Widget view(BuildContext context) {
    return Scaffold(
      body: SafeAreaWidget(
        child: PageView(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _currentPage = index;
            });
          },
          children: [
            _buildIntroPage(
              context,
              title: "Revolutionizing\nUrban\nFarming",
              description:
                  "Master the art of hydroponics and learn how to grow fresh food anywhere, efficiently and sustainably. Join the future of agriculture.",
              image: "logo-without.png",
              showSponsor: false,
            ),
            _buildIntroPage(
              context,
              title: "Making Agriculture\nMatter for All",
              description:
                  "Agrisiti empowers future farmers with skills, tools, and confidence to transform agriculture and solve real-world challenges.",
              image: "logo-without.png",
              showSponsor: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntroPage(
    BuildContext context, {
    required String title,
    required String description,
    required String image,
    bool showSponsor = false,
  }) {
    return Container(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 2),
            // Logo
            Image.asset(
              image,
              height: 140,
              width: 140,
            ).localAsset(),
            const SizedBox(height: 48),
            // Title
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                height: 1.2,
                color: Color(0xFF1A1A1A),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 20),
            // Description
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                height: 1.5,
                color: Colors.grey[700],
              ),
            ),
            if (showSponsor) ...[
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F7F3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF2D8659).withOpacity(0.2),
                  ),
                ),
                child: Column(
                  children: [
                    const Text(
                      "Powered by Agrisiti",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D8659),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Courses sponsored by Tagdev",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const Spacer(flex: 2),
            // Get Started Button
            if (_currentPage == 1)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    // Mark intro as seen
                    try {
                      await Keys.hasSeenIntro.save(true);
                } catch (e) {
                  // Handle storage errors gracefully - continue to login anyway
                  // Suppress error logging for Keychain issues on simulator
                  if (!e.toString().contains('-34018')) {
                    print('Warning: Failed to save intro status: $e');
                  }
                }
                    routeTo("/login");
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2D8659),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    "Get Started",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 24),
            // Page Indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                2,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? const Color(0xFF2D8659)
                        : const Color(0xFF2D8659).withOpacity(0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

