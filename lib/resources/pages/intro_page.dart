import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:nylo_framework/nylo_framework.dart';
import '/config/keys.dart';
import 'dart:math' as math;

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

  void _skipIntro() async {
    try {
      await Keys.hasSeenIntro.save(true);
    } catch (e) {
      if (!e.toString().contains('-34018')) {
        print('Warning: Failed to save intro status: $e');
      }
    }
    routeTo("/login");
  }

  @override
  Widget view(BuildContext context) {
    return Scaffold(
      body: PageView(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _currentPage = index;
            });
          },
          children: [
          _buildScreen1(context),
          _buildScreen2(context),
          _buildScreen3(context),
        ],
      ),
    );
  }

  // Screen 1: Light background - Empowering Agriculture
  Widget _buildScreen1(BuildContext context) {
    // Color scheme
    const primary = Color(0xFF3E6866);
    const secondary = Color(0xFF50C1AE);

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: secondary
          .withOpacity(0.1), // Light teal background (#50C1AE with opacity)
      child: SafeArea(
        child: Column(
          children: [
            // Header with logo and Skip
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Logo
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: primary.withOpacity(0.2), // primary/20
                          shape: BoxShape.circle,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(6.0),
                          child: Image.asset(
                            "logo-without.png",
                            width: 28,
                            height: 28,
                            fit: BoxFit.contain,
                          ).localAsset(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Agrisiti",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: const Color(
                              0xFF0d5c63), // Darker teal for better visibility
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  // Skip button
                  TextButton(
                    onPressed: _skipIntro,
                    child: Text(
                      "Skip",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: primary.withOpacity(0.6), // primary/60
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Hero Section - Image
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: primary.withOpacity(0.1), // primary/10
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(
                          children: [
                            // Background image
                            Container(
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                  image: NetworkImage(
                                    "https://lh3.googleusercontent.com/aida-public/AB6AXuCqTpy-S8kyuaevR2mmivH86ePRnIGY5NjgP-Gog9Nhy0zJLc8CBDNEH9LHmW4H4MiOhwfdP0v1OU2_6q8JbMrBX43WAh4SSfznrVdHGbe2L0KalcHcm63Gi75NC2TtI1H5Xp3q-L_ljNFvCbYqP-e7wAbWlMrOmy58nHyF6F16PVjRYA5A6wXq4cbbHes3zIU0qPqcXQcGoONRFVQ-EtpZTZ4M2iZM2YVtbseFfPocJZTVoHB1R5DuhL2r5bE-u2OmpD9ZPaWj5CY",
                                  ),
                                  fit: BoxFit.cover,
                                  onError: (_, __) {},
                                ),
                              ),
                            ),
                            // Gradient overlay (from bottom to top)
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: [
                                      primary.withOpacity(0.4), // primary/40
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Content Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  const SizedBox(height: 32),
                  // Title
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: "Empowering ",
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : primary, // primary
                            height: 1.2,
                            letterSpacing: -0.5,
                          ),
                        ),
                        TextSpan(
                          text: "Agriculture",
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: secondary, // secondary
                            height: 1.2,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Description
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      "Join a community of modern farmers and learners dedicated to sustainable growth and agricultural innovation.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.5,
                        color: primary.withOpacity(0.8), // primary/80
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Page Indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      3,
                      (index) {
                        final isDark =
                            Theme.of(context).brightness == Brightness.dark;
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          width: index == 0 ? 24 : 10, // First dot is elongated
                          height: 10,
                          decoration: BoxDecoration(
                            color: index == 0
                                ? secondary // secondary
                                : (isDark
                                    ? Colors.white.withOpacity(0.2)
                                    : primary.withOpacity(0.2)), // primary/20
                            borderRadius: BorderRadius.circular(999),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Get Started Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            primary, // primary (same as second intro page)
                        foregroundColor: Colors
                            .white, // white text (same as second intro page)
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(999), // full rounded
                        ),
                        elevation: 8,
                        shadowColor: primary.withOpacity(0.2),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Get Started",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward, size: 20),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
            // iOS Home Indicator
            Container(
              height: 32,
              width: double.infinity,
              padding: const EdgeInsets.only(bottom: 8),
              child: Center(
                child: Container(
                  width: 128,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Screen 2: Dark background - Master Agriculture Step-by-Step
  Widget _buildScreen2(BuildContext context) {
    // Color scheme
    const primary = Color(0xFF3E6866);
    const secondary = Color(0xFF50C1AE);
    const backgroundDark = Color(0xFF102214);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: secondary
          .withOpacity(0.1), // Light teal background (#50C1AE with opacity)
      child: SafeArea(
        child: Column(
          children: [
            // Top Navigation
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back button
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(Icons.chevron_left, color: primary, size: 24),
                      onPressed: () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  // Logo (centered)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
            Image.asset(
                        "logo-without.png",
                        width: 24,
                        height: 24,
                        fit: BoxFit.contain,
            ).localAsset(),
                      const SizedBox(width: 4),
                      Text(
                        "Agrisiti",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: primary, // Dark text for white background
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  // Spacer for symmetry
                  const SizedBox(width: 40),
                ],
              ),
            ),
            // Content Area
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    // Headline Section
            Text(
                      "Master Agriculture Step-by-Step",
              textAlign: TextAlign.center,
                      style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                        color: const Color(
                            0xFF1e293b), // Dark text for white background
                height: 1.2,
                letterSpacing: -0.5,
              ),
            ),
                    const SizedBox(height: 12),
            // Description
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        "Our courses are divided into easy-to-digest modules and lessons, designed to take you from beginner to expert.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                height: 1.5,
                          color: const Color(
                              0xFF475569), // Dark text for white background
                        ),
              ),
            ),
              const SizedBox(height: 32),
                    // Module Cards with decorative glow
                    Stack(
                      children: [
                        // Decorative Teal Glow
                        Positioned(
                          top: -40,
                          left: MediaQuery.of(context).size.width / 2 - 96,
                          child: Container(
                            width: 192,
                            height: 192,
                            decoration: BoxDecoration(
                              color: secondary.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                              child: Container(),
                            ),
                          ),
                        ),
                        // Module Cards
                        Column(
                          children: [
                            // Completed Module Card
              Container(
                              padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.grey[800]!.withOpacity(0.4)
                                    : Colors.white.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                                  color: isDark
                                      ? Colors.white.withOpacity(0.05)
                                      : Colors.grey[300]!,
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 15,
                                    spreadRadius: 0,
                                    offset: const Offset(0, 4),
                                  ),
                                  BoxShadow(
                                    color: primary.withOpacity(0.1),
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                    offset: const Offset(0, 0),
                                  ),
                                ],
                              ),
                              child: BackdropFilter(
                                filter:
                                    ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: primary.withOpacity(0.2),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.check_circle,
                                            color: primary,
                                            size: 16,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          "MODULE 1",
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: isDark
                                                ? Colors.white.withOpacity(0.6)
                                                : Colors.grey[700],
                                            letterSpacing: 1.0,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      "Soil Science Basics",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: isDark
                                            ? Colors.white
                                            : const Color(0xFF1e293b),
                                        letterSpacing: -0.015,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          "10/10 lessons • Completed",
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: primary,
                                          ),
                                        ),
                                        Container(
                                          decoration: BoxDecoration(
                                            boxShadow: [
                                              BoxShadow(
                                                color: primary.withOpacity(0.3),
                                                blurRadius: 8,
                                                spreadRadius: 0,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: ElevatedButton(
                                            onPressed: () {},
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: primary,
                                              foregroundColor: backgroundDark,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 8,
                                              ),
                                              minimumSize: const Size(84, 32),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              elevation: 4,
                                            ),
                                            child: const Text(
                                              "Review",
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // In Progress Module Card
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.grey[800]!.withOpacity(0.8)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: primary.withOpacity(0.3),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: primary.withOpacity(0.2),
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                    offset: const Offset(0, 4),
                                  ),
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.4),
                                    blurRadius: 15,
                                    spreadRadius: 0,
                                    offset: const Offset(0, 6),
                                  ),
                                  BoxShadow(
                                    color: secondary.withOpacity(0.15),
                                    blurRadius: 30,
                                    spreadRadius: -5,
                                    offset: const Offset(0, 0),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                  children: [
                                                Icon(
                                                  Icons.pending,
                                                  color: secondary,
                                                  size: 16,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  "MODULE 2",
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                    color: isDark
                                                        ? Colors.white
                                                            .withOpacity(0.6)
                                                        : Colors.grey[700],
                                                    letterSpacing: 1.0,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              "Crop Rotation Systems",
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w700,
                                                color: isDark
                                                    ? Colors.white
                                                    : const Color(0xFF1e293b),
                                                height: 1.2,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? Colors.white.withOpacity(0.1)
                                              : primary.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          "4/10",
                      style: TextStyle(
                        fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color:
                                                isDark ? Colors.white : primary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  // Progress Bar
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(999),
                                    child: Container(
                                      height: 10,
                                      color: isDark
                                          ? Colors.grey[700]
                                          : Colors.grey[300],
                                      child: FractionallySizedBox(
                                        alignment: Alignment.centerLeft,
                                        widthFactor: 0.4,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: primary,
                                            borderRadius:
                                                BorderRadius.circular(999),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Currently studying: N-Fixing Plants",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: primary.withOpacity(0.8),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Icon(
                                        Icons.play_circle,
                                        color: primary,
                                        size: 24,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Locked Module Card
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.grey[900]!.withOpacity(0.4)
                                    : Colors.grey[100]!.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white.withOpacity(0.05)
                                      : Colors.grey[300]!,
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 10,
                                    spreadRadius: 0,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Opacity(
                                opacity: 0.5,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? Colors.grey[800]
                                            : Colors.grey[200],
                                        borderRadius: BorderRadius.circular(8),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.3),
                                            blurRadius: 8,
                                            spreadRadius: 0,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        Icons.lock,
                                        color: isDark
                                            ? Colors.grey[500]
                                            : Colors.grey[600],
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "MODULE 3",
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: isDark
                                                  ? Colors.white
                                                      .withOpacity(0.4)
                                                  : Colors.grey[600],
                                              letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                                            "Advanced Irrigation",
                      style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              color: isDark
                                                  ? Colors.white
                                                      .withOpacity(0.6)
                                                  : Colors.grey[700],
                      ),
                    ),
                  ],
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
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
            // Navigation Footer
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  // Progress Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      3,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: index == 1 ? 24 : 8, // Second dot is elongated
                        height: 8,
                        decoration: BoxDecoration(
                          color: index == 1
                              ? primary
                              : (isDark ? Colors.grey[700] : Colors.grey[300]),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          child: Text(
                            "Back",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color:
                                  isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                child: ElevatedButton(
                          onPressed: () {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                  },
                  style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                    foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 8,
                            shadowColor: primary.withOpacity(0.2),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Next Step",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16), // Safe area spacer
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Screen 3: Dark background - Mastery Through Action
  Widget _buildScreen3(BuildContext context) {
    // Color scheme
    const primary = Color(0xFF3E6866);
    const secondary = Color(0xFF50C1AE);
    const backgroundDark = Color(0xFF102214);

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: secondary
          .withOpacity(0.1), // Light teal background (#50C1AE with opacity)
      child: SafeArea(
        child: Column(
          children: [
            // Header with logo and Skip
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Logo
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: primary.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Image.asset(
                      "logo-without.png",
                      width: 28,
                      height: 28,
                      fit: BoxFit.contain,
                    ).localAsset(),
                  ),
                  // Skip button
                  TextButton(
                    onPressed: _skipIntro,
                    child: Text(
                      "Skip",
                    style: TextStyle(
                      fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF9db9a3), // dark:text-[#9db9a3]
                        letterSpacing: 0.015,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Main content
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 24),
                      // Hero Graphic Section
                      Container(
                        height: 320, // min-h-80
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              primary.withOpacity(0.2), // primary/20
                              backgroundDark,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: primary.withOpacity(0.1),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: primary.withOpacity(0.05),
                              blurRadius: 20,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            children: [
                              // Background image
                              Positioned.fill(
                                child: Image.network(
                                  "https://lh3.googleusercontent.com/aida-public/AB6AXuCXk_T3ABy3pj3P63iuqgRsJsL9S6qQ6IFc-nxkWPynnsNlRtOrlZVVgmPnx0teGe1uWsJPYHAxh1s8umgaGPzGYhgSYBKp8Bqeb_omDunu4UpOnkirIu-2t7KDaXbyzg5Rj0-WY0pVV0hw4HfbnP5Jke1AmnsbU9mqBLycM5vS1qc1yfWsMxJHIfguUCLnqtmOdXFHj8Nu5QvRmgd4WNXzmxXWe8oDUEw7wv8o4Op161a1__qL5YemYtaSsbXW9Xxro7vunAultEw",
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                    color: backgroundDark.withOpacity(0.6),
                                    child: Center(
                                      child: Image.asset(
                                        "logo-without.png",
                                        height: 200,
                                        width: 200,
                                        color: Colors.white.withOpacity(0.2),
                                      ).localAsset(),
                                    ),
                                  ),
                                ),
                              ),
                              // Backdrop blur overlay
                              Positioned.fill(
                                child: Container(
                                  color: backgroundDark.withOpacity(0.4),
                                  child: BackdropFilter(
                                    filter:
                                        ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                                    child: Container(),
                                  ),
                                ),
                              ),
                              // VR Icon in center with pulsing animation
                              Center(
                                child: _PulsingVRIcon(primary: primary),
                              ),
                            ],
                          ),
                        ),
              ),
            const SizedBox(height: 24),
                      // Text Content
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          children: [
                            // Title
                            RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: "Mastery Through ",
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(
                                          0xFF1e293b), // Dark text for white background
                                      height: 1.2,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  TextSpan(
                                    text: "Action",
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w700,
                                      color:
                                          secondary, // primary (secondary color)
                                      height: 1.2,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Description
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Text(
                                "Experience agriculture like never before with VR simulations and hands-on DIY projects. Track your progress and earn rewards as you grow.",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  height: 1.5,
                                  color: const Color(
                                      0xFF475569), // Dark text for white background
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                      // Progress Indicators
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                            3,
                            (index) {
                              final isActive = _currentPage == index;
                              return Container(
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 6),
                                width: isActive ? 32 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                                  color: isActive
                                      ? secondary // primary (secondary color)
                                      : (Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? secondary.withOpacity(0.2)
                                          : Colors.grey[300]),
                                  borderRadius: BorderRadius.circular(999),
                                  boxShadow: isActive
                                      ? [
                                          BoxShadow(
                                            color: secondary.withOpacity(0.5),
                                            blurRadius: 10,
                                            spreadRadius: 0,
                                          ),
                                        ]
                                      : null,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // CTA Section
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          children: [
                            // Get Started Button
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: () async {
                                  try {
                                    await Keys.hasSeenIntro.save(true);
                                  } catch (e) {
                                    if (!e.toString().contains('-34018')) {
                                      print(
                                          'Warning: Failed to save intro status: $e');
                                    }
                                  }
                                  routeTo("/welcome");
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      secondary, // primary (secondary color)
                                  foregroundColor: backgroundDark,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  elevation: 8,
                                  shadowColor: secondary.withOpacity(0.2),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Get Started",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Icon(Icons.arrow_forward, size: 20),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Footer text
                            Text(
                              "Part of the Agrisiti Ecosystem",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.grey[500]
                                    : const Color(0xFF64748b), // text-slate-500
                                letterSpacing: 2.4, // tracking-widest
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Pulsing VR Icon Widget
class _PulsingVRIcon extends StatefulWidget {
  final Color primary;

  const _PulsingVRIcon({required this.primary});

  @override
  State<_PulsingVRIcon> createState() => _PulsingVRIconState();
}

class _PulsingVRIconState extends State<_PulsingVRIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.95 + (_controller.value * 0.05),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.primary.withOpacity(0.2),
              border: Border.all(
                color: widget.primary.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.vrpano, // VR icon
              color: widget.primary,
              size: 60,
            ),
          ),
        );
      },
    );
  }
}

// Custom painter for digital interface overlay (circular network pattern)
class DigitalInterfacePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.3;

    // Draw circular network pattern
    for (int i = 0; i < 3; i++) {
      canvas.drawCircle(center, radius - (i * 30), paint);
    }

    // Draw connecting lines (simplified)
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..strokeWidth = 1.5;

    // Draw some connecting lines
    for (int i = 0; i < 8; i++) {
      final angle = (i / 8) * 2 * math.pi;
      final x = center.dx + (radius - 30) * math.cos(angle);
      final y = center.dy + (radius - 30) * math.sin(angle);
      canvas.drawLine(center, Offset(x, y), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
