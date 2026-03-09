import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:nylo_framework/nylo_framework.dart';
import '/resources/pages/login_page.dart';
import '/resources/pages/register_page.dart';
import '/resources/pages/main_navigation_page.dart';

class WelcomePage extends NyStatefulWidget {
  static RouteView path = ("/welcome", (_) => WelcomePage());

  WelcomePage({super.key}) : super(child: () => _WelcomePageState());
}

class _WelcomePageState extends NyPage<WelcomePage> {
  @override
  LoadingStyle get loadingStyle => LoadingStyle.none();

  @override
  get init => () async {
        print('WELCOME: init called');
      };

  @override
  Widget view(BuildContext context) {
    // Color scheme
    const primary = Color(0xFF3E6866);
    const secondary = Color(0xFF50C1AE);
    const backgroundDark = Color(0xFF10221f);
    const backgroundLight = Color(0xFFf6f8f8);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: isDark ? backgroundDark : backgroundLight,
          // Gradient mesh effect
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.5,
            colors: [
              secondary.withValues(alpha: 0.15),
              Colors.transparent,
            ],
            stops: const [0.0, 0.5],
          ),
        ),
        child: Stack(
          children: [
            // Decorative background pattern (bottom)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: MediaQuery.of(context).size.height * 0.5,
              child: Opacity(
                opacity: 0.1,
                child: Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(
                        "https://lh3.googleusercontent.com/aida-public/AB6AXuAJl8IC9k6KhwMkWtzx5rrFm7g8I6KtupDxuw1JuJgF36mNKMafcoUu03B71aElib1ryjDgnIVL4E3efPIlDR8AtvJubYoI_1Msa1c4EJShcyr7h50WWNkHCLyd1TwwnkmDZpYlFmEXIU8m_3_KfV8OHQg5yZ-ZPrcyBEeKXuvxNEHtWl-WGEGoDMei2CbKzMiz7HK5eIKPeAmz35N1un19zHwvn1HffNw6y4r1GCO94qbUm18JSWWmtbHBGSMVh5MZec-PMN-5uSU",
                      ),
                      fit: BoxFit.contain,
                      alignment: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
            ),
            // Main content
            SafeArea(
              child: Column(
                children: [
                  // Top App Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24.0, vertical: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: secondary.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Image.asset(
                            "logo-without.png",
                            width: 20,
                            height: 20,
                            fit: BoxFit.contain,
                          ).localAsset(),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Agrisiti",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color:
                                isDark ? Colors.white : const Color(0xFF1e293b),
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Hero Content Section
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Central Brand Logo with Glow
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            // Glow effect (blur-3xl scale-150)
                            Container(
                              width: 192, // scale-150 on 128px base
                              height: 192,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: secondary.withValues(alpha: 0.2),
                              ),
                              child: BackdropFilter(
                                filter:
                                    ImageFilter.blur(sigmaX: 60, sigmaY: 60),
                                child: Container(),
                              ),
                            ),
                            // Logo container
                            Container(
                              width: 128,
                              height: 128,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: secondary.withValues(alpha: 0.1),
                                border: Border.all(
                                  color: secondary.withValues(alpha: 0.2),
                                  width: 1,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Image.asset(
                                  "logo-without.png",
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.contain,
                                ).localAsset(),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 48),
                        // Headline Section
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Column(
                            children: [
                              Text(
                                "Empowering the next generation of farmers",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF1e293b),
                                  height: 1.2,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                "Master modern agriculture with expert-led courses and digital tools.",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 18,
                                  height: 1.5,
                                  color: isDark
                                      ? Colors.grey[400]
                                      : const Color(0xFF64748b),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Action Section (iOS Style Floating Bottom)
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 480),
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      children: [
                        const SizedBox(height: 24),
                        // Primary Action - Join the Academy
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () {
                              routeTo(RegisterPage.path);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  secondary, // primary (secondary color)
                              foregroundColor: backgroundDark,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              "Join the Academy",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Secondary Action - Welcome Back
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: OutlinedButton(
                            onPressed: () {
                              routeTo(LoginPage.path);
                            },
                            style: OutlinedButton.styleFrom(
                              backgroundColor: isDark
                                  ? Colors.grey[800]!.withValues(alpha: 0.5)
                                  : secondary.withValues(alpha: 0.1),
                              foregroundColor: isDark ? Colors.white : primary,
                              side: BorderSide(
                                color: secondary.withValues(alpha: 0.3),
                                width: 1,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              "Welcome Back",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Guest Action
                        TextButton(
                          onPressed: () {
                            // Navigate to main navigation (courses tab) as guest
                            routeTo(MainNavigationPage.path);
                          },
                          child: Text(
                            "Browse courses as a guest",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color:
                                  isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // iOS Home Indicator
                        Container(
                          width: 128,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.grey[700]!.withValues(alpha: 0.3)
                                : Colors.grey[400]!.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        SizedBox(
                            height: MediaQuery.of(context).padding.bottom + 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
