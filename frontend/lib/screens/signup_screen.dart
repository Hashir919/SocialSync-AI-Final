import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  void _handleSignup() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      _showError("Please fill in all fields.");
      return;
    }

    if (password.length < 8) {
      _showError("Password must be at least 8 characters.");
      return;
    }

    if (password != confirmPassword) {
      _showError("Passwords do not match.");
      return;
    }

    final errorMessage = await ref.read(authProvider.notifier).register(
      name: name,
      email: email,
      password: password,
    );

    if (errorMessage == null && mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const HomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 600),
        ),
        (route) => false,
      );
    } else if (mounted) {
      _showError(errorMessage ?? "Signup failed. Email might already be in use.");
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  Text(
                    "GET STARTED",
                    style: GoogleFonts.dmMono(
                      color: AppTheme.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Create account",
                    style: GoogleFonts.manrope(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.8,
                    ),
                  ),
                  const SizedBox(height: 32),

                  if (authState.isLoading) ...[
                    Center(
                      child: Column(
                        children: [
                          const SpinKitDoubleBounce(
                            color: AppTheme.limeAccent,
                            size: 24,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Creating your profile...",
                            style: GoogleFonts.dmMono(
                              color: AppTheme.textMuted,
                              fontSize: 13,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInputField("Full Name", _nameController, false),
                        const SizedBox(height: 20),
                        _buildInputField("Email Address", _emailController, false, TextInputType.emailAddress),
                        const SizedBox(height: 20),
                        _buildInputField("Password", _passwordController, true),
                        const SizedBox(height: 20),
                        _buildInputField("Confirm Password", _confirmPasswordController, true),
                      ],
                    ),
                    const SizedBox(height: 40),

                    GestureDetector(
                      onTap: _handleSignup,
                      child: Container(
                        width: double.infinity,
                        height: 54,
                        decoration: BoxDecoration(
                          color: AppTheme.limeAccent,
                          borderRadius: BorderRadius.circular(17),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          "Create Account ↗",
                          style: GoogleFonts.manrope(
                            color: const Color(0xFF090B05),
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Text.rich(
                          TextSpan(
                            text: "Already have an account? ",
                            style: GoogleFonts.manrope(
                              color: AppTheme.textMuted,
                              fontSize: 12,
                            ),
                            children: [
                              TextSpan(
                                text: "Sign In",
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
                    const SizedBox(height: 32),
                  ]
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, bool isPassword, [TextInputType type = TextInputType.text]) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.dmMono(
            color: AppTheme.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          cursorColor: AppTheme.limeAccent,
          obscureText: isPassword,
          keyboardType: type,
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
      ],
    );
  }
}
