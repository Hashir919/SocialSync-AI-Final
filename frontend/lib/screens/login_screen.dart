import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  void _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showError("Please enter your email and password.");
      return;
    }
    if (!email.contains("@")) {
      _showError("Please enter a valid email address.");
      return;
    }

    final errorMessage = await ref.read(authProvider.notifier).login(
      email: email,
      password: password,
    );

    if (errorMessage == null && mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const HomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    } else if (mounted) {
      _showError(errorMessage ?? "Login failed. Please try again.");
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        backgroundColor: AppTheme.panelBg2,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(20),
        elevation: 0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppTheme.primaryBg,
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
              child: CustomScrollView(
                slivers: [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 48),
                        Text(
                          "WELCOME BACK",
                          style: GoogleFonts.dmMono(
                            color: AppTheme.textMuted,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1.8,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Enter your details",
                          style: GoogleFonts.manrope(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1.8,
                          ),
                        ),
                        const SizedBox(height: 48),
                        if (authState.isLoading) ...[
                          Expanded(
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SpinKitDoubleBounce(
                                    color: AppTheme.limeAccent,
                                    size: 24,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    "Signing in...",
                                    style: GoogleFonts.dmMono(
                                      color: AppTheme.textMuted,
                                      fontSize: 13,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ] else ...[
                          Text(
                            "EMAIL ADDRESS",
                            style: GoogleFonts.dmMono(
                              color: AppTheme.textMuted,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _emailController,
                            cursorColor: AppTheme.limeAccent,
                            keyboardType: TextInputType.emailAddress,
                            style: GoogleFonts.manrope(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                              filled: true,
                              fillColor: AppTheme.panelBg,
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(color: AppTheme.lineBorder),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(color: AppTheme.limeAccent),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "PASSWORD",
                                style: GoogleFonts.dmMono(
                                  color: AppTheme.textMuted,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              GestureDetector(
                                onTap: () async {
                                  final email = _emailController.text.trim();
                                  if (email.isEmpty) {
                                      _showError("Please enter your email first to reset.");
                                      return;
                                  }
                                  final success = await ref.read(authProvider.notifier).resetPassword(email);
                                  if (success && mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text("Password reset email sent.", style: GoogleFonts.manrope(fontSize: 13)),
                                        backgroundColor: AppTheme.successGreen,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        margin: const EdgeInsets.all(20),
                                      )
                                    );
                                  }
                                },
                                child: Text(
                                  "Forgot?",
                                  style: GoogleFonts.dmMono(
                                    color: AppTheme.textMuted,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _passwordController,
                            cursorColor: AppTheme.limeAccent,
                            obscureText: true,
                            style: GoogleFonts.manrope(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                              filled: true,
                              fillColor: AppTheme.panelBg,
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(color: AppTheme.lineBorder),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(color: AppTheme.limeAccent),
                              ),
                            ),
                          ),
                          const Spacer(),
                          const SizedBox(height: 48),
                          GestureDetector(
                            onTap: _handleLogin,
                            child: Container(
                              width: double.infinity,
                              height: 54,
                              decoration: BoxDecoration(
                                color: AppTheme.limeAccent,
                                borderRadius: BorderRadius.circular(17),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                "Sign In ✦",
                                style: GoogleFonts.manrope(
                                  color: const Color(0xFF090B05),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: () {
                              Navigator.pushReplacement(
                                context,
                                PageRouteBuilder(
                                  pageBuilder: (context, animation, secondaryAnimation) => const HomeScreen(),
                                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                    return FadeTransition(opacity: animation, child: child);
                                  },
                                  transitionDuration: const Duration(milliseconds: 600),
                                ),
                              );
                            },
                            child: Container(
                              width: double.infinity,
                              height: 54,
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(17),
                                border: Border.all(color: AppTheme.lineBorder),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                "Enter Exhibition Demo Mode",
                                style: GoogleFonts.manrope(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Center(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  PageRouteBuilder(
                                    pageBuilder: (context, animation, secondaryAnimation) => const SignupScreen(),
                                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                      return FadeTransition(opacity: animation, child: child);
                                    },
                                    transitionDuration: const Duration(milliseconds: 400),
                                  ),
                                );
                              },
                              child: Text.rich(
                                TextSpan(
                                  text: "Don't have an account? ",
                                  style: GoogleFonts.manrope(
                                    color: AppTheme.textMuted,
                                    fontSize: 12,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: "Create one",
                                      style: GoogleFonts.manrope(
                                        color: AppTheme.limeAccent,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ]
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
