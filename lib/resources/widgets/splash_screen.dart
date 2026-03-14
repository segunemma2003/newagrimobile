import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:nylo_framework/nylo_framework.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  /// Create a new instance of the MaterialApp
  static MaterialApp app() {
    return MaterialApp(
      home: SplashScreen(),
      debugShowCheckedModeBanner: true,
    );
  }

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();

    // The splash screen will be automatically replaced by the main app
    // after 5 seconds (handled in boot.dart)
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    print('SplashScreen _animationController: $_animationController');
  }

  @override
  void dispose() {
    _animationController.dispose();
    print('SplashScreen dispose');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: const Color(0xFF3E6866), // primary background
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top App Bar Space (iOS Status Bar Area)
            SizedBox(height: MediaQuery.of(context).padding.top + 16),
            // Main Logo Area
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Branding Container
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Subtle Glow behind logo (simplified to reduce memory)
                      Container(
                        width: 192, // scale-150 on 128px base
                        height: 192,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF0fbd38)
                              .withValues(alpha: 0.2), // primary/20
                        ),
                      ),
                      // Logo
                      Container(
                        padding: const EdgeInsets.all(24), // p-6
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              Colors.white.withValues(alpha: 0.1), // white/10
                          border: Border.all(
                            color:
                                Colors.white.withValues(alpha: 0.05), // white/5
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 20,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: Image.asset(
                          "logo-without.png",
                          width: 84,
                          height: 84,
                          fit: BoxFit.contain,
                          cacheWidth: 84,
                          cacheHeight: 84,
                        ).localAsset(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32), // mb-8
                  // Headline Text
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      "Learn with Agrisiti",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 32, // text-[32px]
                        fontWeight: FontWeight.w700, // font-bold
                        color: Colors.white,
                        height: 1.2, // leading-tight
                        letterSpacing: -0.5, // tracking-tight
                      ),
                    ),
                  ),
                  const SizedBox(height: 48), // mt-12
                  // Loading Dots (animated with pulsing effect)
                  AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(3, (index) {
                          final double delay = index * 0.2;
                          final double value =
                              (_animationController.value + delay) % 1.0;
                          final double opacity =
                              (math.sin(value * math.pi)).abs();
                          final double scale = 0.7 + (opacity * 0.3);

                          // Base opacities: 40%, 70%, 100%
                          final List<double> baseOpacities = [0.4, 0.7, 1.0];
                          final double finalOpacity =
                              baseOpacities[index] * (0.5 + opacity * 0.5);

                          return Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 4.0),
                            child: Transform.scale(
                              scale: scale,
                              child: Container(
                                width: 6, // w-1.5
                                height: 6, // h-1.5
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFF0fbd38)
                                      .withValues(alpha: finalOpacity),
                                ),
                              ),
                            ),
                          );
                        }),
                      );
                    },
                  ),
                ],
              ),
            ),
            // Footer Area
            Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom + 40, // pb-10
              ),
              child: Column(
                children: [
                  // Meta Text
                  Text(
                    "from Agrisiti",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12, // text-xs
                      fontWeight: FontWeight.w500, // font-medium
                      color: const Color(0xFF0fbd38)
                          .withValues(alpha: 0.6), // primary/60
                      letterSpacing: 2.4, // tracking-[0.2em]
                    ),
                  ),
                  const SizedBox(height: 32), // pb-8
                  // iOS Home Indicator
                  Container(
                    width: 134, // w-32 (approx)
                    height: 5, // h-1.5 (approx)
                    decoration: BoxDecoration(
                      color: Colors.white
                          .withValues(alpha: 0.3), // rgba(255, 255, 255, 0.3)
                      borderRadius: BorderRadius.circular(100), // rounded-full
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
