import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/auth_provider.dart';
import '../theme/theme_provider.dart';
import 'login_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  bool _isEditingName = false;
  
  bool _weeklyInsights = true;
  bool _gentlePacing = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authProvider).user;
      if (user != null) {
        _nameController.text = user.name ?? '';
      }
    });
  }

  void _handleLogout() async {
    await ref.read(authProvider.notifier).logout();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  void _saveName() async {
    final newName = _nameController.text.trim();
    if (newName.isNotEmpty) {
      final success = await ref.read(authProvider.notifier).updateProfile(newName);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Profile updated successfully.", style: GoogleFonts.inter(fontSize: 13)),
            backgroundColor: const Color(0xFF34C759),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(20),
          ),
        );
      }
    }
    setState(() {
      _isEditingName = false;
    });
  }

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return "S";
    final parts = name.split(" ");
    if (parts.length > 1) {
      return "${parts[0][0]}${parts[1][0]}".toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final user = auth.user;
    final initials = _getInitials(user?.name);
    final themeMode = ref.watch(themeProvider);
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Gentle ambient glow
          Positioned(
            top: -150,
            left: -50,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.tertiary.withOpacity(0.04),
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            LucideIcons.chevronLeft,
                            color: Theme.of(context).colorScheme.onBackground,
                            size: 20,
                          ),
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),

                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 12.0),
                    children: [
                      // Avatar
                      Center(
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF5E5CE6), Color(0xFF0A84FF)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF5E5CE6).withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            initials,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -1,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // User Info
                      if (_isEditingName) ...[
                        TextField(
                          controller: _nameController,
                          cursorColor: Theme.of(context).colorScheme.primary,
                          style: GoogleFonts.inter(
                            color: Theme.of(context).colorScheme.onBackground,
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 8),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Theme.of(context).colorScheme.onBackground.withOpacity(0.2)),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                            ),
                          ),
                          onSubmitted: (_) => _saveName(),
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: GestureDetector(
                            onTap: _saveName,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                "Save",
                                style: GoogleFonts.inter(
                                  color: Theme.of(context).colorScheme.onPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ] else ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              user?.name ?? "Alex",
                              style: GoogleFonts.inter(
                                color: Theme.of(context).colorScheme.onBackground,
                                fontSize: 28,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _nameController.text = user?.name ?? "";
                                  _isEditingName = true;
                                });
                              },
                              child: Icon(
                                LucideIcons.edit2,
                                color: Theme.of(context).colorScheme.onBackground.withOpacity(0.4),
                                size: 16,
                              ),
                            ),
                          ],
                        ),
                      ],
                      
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          user?.email ?? "alex@example.com",
                          style: GoogleFonts.inter(
                            color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      const SizedBox(height: 48),

                      // Account Settings Section
                      Text(
                        "Preferences",
                        style: GoogleFonts.inter(
                          color: Theme.of(context).colorScheme.onBackground.withOpacity(0.4),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Theme.of(context).colorScheme.onBackground.withOpacity(0.08)),
                        ),
                        child: Column(
                          children: [
                            _buildPreferenceSwitch(
                              "Weekly Insights",
                              "Receive personalized progress summaries.",
                              _weeklyInsights,
                              (val) => setState(() => _weeklyInsights = val),
                            ),
                            Divider(color: Theme.of(context).colorScheme.onBackground.withOpacity(0.08), height: 1),
                            _buildPreferenceSwitch(
                              "Gentle Pacing Prompts",
                              "Softer visual cues during live sessions.",
                              _gentlePacing,
                              (val) => setState(() => _gentlePacing = val),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Appearance Theme Selector
                      Text(
                        "Appearance",
                        style: GoogleFonts.inter(
                          color: Theme.of(context).colorScheme.onBackground.withOpacity(0.4),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Theme.of(context).colorScheme.onBackground.withOpacity(0.08)),
                        ),
                        child: Column(
                          children: [
                            _buildThemeSelectorOption(
                              "System Theme",
                              "Match device system preferences.",
                              ThemeMode.system,
                              themeMode,
                            ),
                            Divider(color: Theme.of(context).colorScheme.onBackground.withOpacity(0.08), height: 1),
                            _buildThemeSelectorOption(
                              "Light Theme",
                              "Classic clear styling.",
                              ThemeMode.light,
                              themeMode,
                            ),
                            Divider(color: Theme.of(context).colorScheme.onBackground.withOpacity(0.08), height: 1),
                            _buildThemeSelectorOption(
                              "Dark Theme",
                              "Low light comfort.",
                              ThemeMode.dark,
                              themeMode,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Logout Section
                      GestureDetector(
                        onTap: _handleLogout,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF453A).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFFF453A).withOpacity(0.2)),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            "Sign Out",
                            style: GoogleFonts.inter(
                              color: const Color(0xFFFF453A),
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildPreferenceSwitch(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    color: Theme.of(context).colorScheme.onBackground,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
                    fontSize: 13,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.white,
            activeTrackColor: const Color(0xFF34C759),
            inactiveThumbColor: Colors.white54,
            inactiveTrackColor: const Color(0xFF3A3A3C),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSelectorOption(String title, String subtitle, ThemeMode mode, ThemeMode currentMode) {
    final isSelected = mode == currentMode;
    return InkWell(
      onTap: () => ref.read(themeProvider.notifier).setThemeMode(mode),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      color: Theme.of(context).colorScheme.onBackground,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
                      fontSize: 13,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                LucideIcons.check,
                color: Theme.of(context).colorScheme.secondary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
