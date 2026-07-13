import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _revealController;
  late AnimationController _pulseController;
  late AnimationController _loaderController;

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _textOpacity;

  @override
  void initState() {
    super.initState();

    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _logoScale = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: _revealController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _revealController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _textOpacity = Tween<double>(begin: 0.0, end: 0.9).animate(
      CurvedAnimation(
        parent: _revealController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeIn),
      ),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _loaderController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    _revealController.forward();
    
    Timer(const Duration(milliseconds: 400), () {
      if (mounted) {
        _loaderController.forward().then((_) => _navigateBasedOnSession());
      }
    });
  }

  @override
  void dispose() {
    _revealController.dispose();
    _pulseController.dispose();
    _loaderController.dispose();
    super.dispose();
  }

  void _navigateBasedOnSession() {
    if (mounted) {
      // Safely handle cases where Supabase failed to initialize (e.g., during tests).
      final session = Supabase.instance?.client.auth.currentSession;
      final targetScreen = session != null ? const HomeScreen() : const LoginScreen();

      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => targetScreen,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 1000),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBg,
      body: Stack(
        children: [
          // Background Glow Centered
          Center(
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                double scaleGlow = 1.0 + (_pulseController.value * 0.1);
                double opacityGlow = 0.05 + (_pulseController.value * 0.05);
                return Transform.scale(
                  scale: scaleGlow,
                  child: Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.accentPurple.withOpacity(opacityGlow),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.limeAccent.withOpacity(opacityGlow * 0.5),
                          blurRadius: 140,
                          spreadRadius: 20,
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Central Elements Centered
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Logo Symbol Reveal
                AnimatedBuilder(
                  animation: _revealController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _logoOpacity.value,
                      child: Transform.scale(
                        scale: _logoScale.value,
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            color: AppTheme.limeAccent,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.limeAccent.withOpacity(0.2),
                                blurRadius: 40,
                              )
                            ],
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            "✣",
                            style: TextStyle(
                              color: Color(0xFF080A05),
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),

                // Title Typography Reveal
                AnimatedBuilder(
                  animation: _revealController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _textOpacity.value,
                      child: Column(
                        children: [
                          Text(
                            "SocialSync AI",
                            style: GoogleFonts.manrope(
                              color: Colors.white,
                              fontSize: 42,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -2.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "PREMIUM COMMUNICATION ASSISTANT",
                            style: GoogleFonts.dmMono(
                              color: AppTheme.limeAccent,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 1.8,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 48),

                // Apple-style Minimal Progress Loader
                AnimatedBuilder(
                  animation: _loaderController,
                  builder: (context, child) {
                    return Container(
                      width: 120,
                      height: 2,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(1),
                      ),
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: _loaderController.value,
                        child: Container(
                          height: 2,
                          decoration: BoxDecoration(
                            color: AppTheme.limeAccent,
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
