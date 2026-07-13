import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:http/http.dart' as http;
import 'practice_mode_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../services/websocket_service.dart';
import '../theme/app_theme.dart';
import 'profile_screen.dart';
import 'ai_coach_chat_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const HomeDashboardView(),
      const AICoachChatScreen(initialMessage: null),
      const RewriteEngineView(),
      const PracticeModeScreen(),
      const ProgressAnalyticsView(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBg,
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        height: 78,
        decoration: const BoxDecoration(
          color: Color(0xE007080A),
          border: Border(
            top: BorderSide(color: AppTheme.lineBorder, width: 1),
          ),
        ),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(0, "⌂", "HOME"),
                  _buildNavItem(1, "✣", "COACH"),
                  _buildNavItem(2, "✦", "REWRITE"),
                  _buildNavItem(3, "◎", "PRACTICE"),
                  _buildNavItem(4, "📊", "METRICS"),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, String symbol, String label) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              symbol,
              style: TextStyle(
                color: isSelected ? AppTheme.limeAccent : AppTheme.textMuted,
                fontSize: 19,
                height: 1,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              label,
              style: GoogleFonts.dmMono(
                color: isSelected ? AppTheme.limeAccent : AppTheme.textMuted,
                fontSize: 9,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RewriteToolCard extends StatefulWidget {
  const RewriteToolCard({super.key});

  @override
  State<RewriteToolCard> createState() => _RewriteToolCardState();
}

class _RewriteToolCardState extends State<RewriteToolCard> {
  final TextEditingController _inputController = TextEditingController();
  String _selectedTone = "Confident";
  String _rewrittenText = "";
  String _suggestion = "";
  bool _isLoading = false;

  final List<String> _tones = ["Confident", "Professional", "Friendly", "Warm"];

  void _performRewrite() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _isLoading = true;
      _rewrittenText = "";
      _suggestion = "";
    });

    try {
      final response = await http.post(
        Uri.parse("http://127.0.0.1:8000/rewrite"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "text": text,
          "tone": _selectedTone,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _rewrittenText = data["improved"] ?? "";
          _suggestion = data["suggestion"] ?? "";
        });
      } else {
        _simulateFallbackRewrite(text);
      }
    } catch (e) {
      _simulateFallbackRewrite(text);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _simulateFallbackRewrite(String text) {
    setState(() {
      _rewrittenText = "I couldn't generate a response right now. Please try again.";
      _suggestion = "Service is currently unavailable. Please verify that the backend server is running.";
    });
  }


  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _rewrittenText));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Polished message copied!", style: GoogleFonts.inter(fontSize: 13)),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06),
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(LucideIcons.pencil, color: Theme.of(context).colorScheme.secondary, size: 16),
              ),
              const SizedBox(width: 12),
              Text(
                "Message Rewrite Engine",
                style: GoogleFonts.inter(
                  color: Theme.of(context).colorScheme.onBackground,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04),
              ),
            ),
            child: TextField(
              controller: _inputController,
              maxLines: 2,
              style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onBackground, fontSize: 13.5),
              decoration: InputDecoration(
                hintText: "Paste your raw or awkward draft message...",
                hintStyle: GoogleFonts.inter(
                  color: Theme.of(context).colorScheme.onBackground.withOpacity(0.35),
                  fontSize: 13,
                ),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _tones.map((tone) {
                final isSelected = _selectedTone == tone;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(tone),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedTone = tone;
                        });
                      }
                    },
                    labelStyle: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? Colors.white : Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
                    ),
                    backgroundColor: Colors.transparent,
                    selectedColor: Theme.of(context).colorScheme.secondary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: isSelected ? Colors.transparent : Theme.of(context).colorScheme.onBackground.withOpacity(0.12),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 0,
              ),
              onPressed: _isLoading ? null : _performRewrite,
              child: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text("Polish Message", style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ),
          if (_rewrittenText.isNotEmpty) ...[
            const SizedBox(height: 20),
            Divider(color: Theme.of(context).colorScheme.onBackground.withOpacity(0.08), height: 1),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "POLISHED VERSION",
                  style: GoogleFonts.plusJakartaSans(
                    color: Theme.of(context).colorScheme.onBackground.withOpacity(0.4),
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.copy, size: 14),
                  color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
                  onPressed: _copyToClipboard,
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.6),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _rewrittenText,
                    style: GoogleFonts.inter(
                      color: Theme.of(context).colorScheme.onBackground,
                      fontSize: 13,
                      height: 1.45,
                    ),
                  ),
                  if (_suggestion.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      _suggestion,
                      style: GoogleFonts.inter(
                        color: Theme.of(context).colorScheme.secondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class HomeDashboardView extends ConsumerStatefulWidget {
  const HomeDashboardView({super.key});

  @override
  ConsumerState<HomeDashboardView> createState() => _HomeDashboardViewState();
}

class _HomeDashboardViewState extends ConsumerState<HomeDashboardView> {
  final TextEditingController _chatController = TextEditingController();
  int _selectedSegment = 0;

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return "S";
    final parts = name.split(" ");
    if (parts.length > 1) {
      return "${parts[0][0]}${parts[1][0]}".toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  void _startChat([String? initialMessage]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AICoachChatScreen(initialMessage: initialMessage),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final userName = auth.user?.name ?? "Alex";
    final initials = _getInitials(auth.user?.name);

    return Container(
      color: AppTheme.primaryBg,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
          children: [
            // Top Dashboard Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Friday · 10 July".toUpperCase(),
                      style: GoogleFonts.dmMono(
                        color: AppTheme.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.8,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      "Good evening,\n$userName.",
                      style: GoogleFonts.manrope(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.8,
                        height: 1.05,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) => const ProfileScreen(),
                        transitionsBuilder: (context, animation, secondaryAnimation, child) {
                          return FadeTransition(opacity: animation, child: child);
                        },
                        transitionDuration: const Duration(milliseconds: 300),
                      ),
                    );
                  },
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.limeAccent,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x26D8FF3E),
                          blurRadius: 40,
                        )
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initials,
                      style: GoogleFonts.manrope(
                        color: const Color(0xFF080A05),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Hero Ask Box Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AppTheme.lineBorder),
                gradient: const LinearGradient(
                  colors: [Color(0x0EFFFFFF), Color(0x04FFFFFF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.limeAccent,
                          boxShadow: [BoxShadow(color: AppTheme.limeAccent, blurRadius: 10)],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "AI COACH ONLINE",
                        style: GoogleFonts.dmMono(
                          color: const Color(0xFFAEB2BA),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),
                  Text(
                    "What conversation is on your mind?",
                    style: GoogleFonts.manrope(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1.2,
                      height: 1.12,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Think it through, rehearse it, or get the exact words you need. No judgement. Just clarity.",
                    style: GoogleFonts.manrope(
                      color: const Color(0xFF8D929C),
                      fontSize: 13,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 22),
                  GestureDetector(
                    onTap: () => _startChat(),
                    child: Container(
                      height: 58,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F3F5),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      padding: const EdgeInsets.only(left: 18, right: 8),
                      child: Row(
                        children: [
                          Text(
                            "Start a conversation",
                            style: GoogleFonts.manrope(
                              color: const Color(0xFF0B0C0E),
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFF0B0C0E),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            alignment: Alignment.center,
                            child: const Text("↗", style: TextStyle(color: Colors.white, fontSize: 20)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Quick Tools Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Quick tools",
                  style: GoogleFonts.manrope(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "02 / 04",
                  style: GoogleFonts.dmMono(
                    color: AppTheme.textMuted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Grid of Quick tools
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 145,
                    padding: const EdgeInsets.all(17),
                    decoration: BoxDecoration(
                      color: AppTheme.limeAccent,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("✦", style: TextStyle(fontSize: 20, color: Colors.black)),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Rewrite a message",
                              style: GoogleFonts.manrope(
                                color: const Color(0xFF090B05),
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Say it better",
                              style: GoogleFonts.manrope(
                                color: const Color(0xFF586319),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    height: 145,
                    padding: const EdgeInsets.all(17),
                    decoration: BoxDecoration(
                      color: AppTheme.panelBg,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: AppTheme.lineBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("◎", style: TextStyle(fontSize: 20, color: Colors.white)),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Practice a scenario",
                              style: GoogleFonts.manrope(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Build confidence",
                              style: GoogleFonts.manrope(
                                color: AppTheme.textMuted,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // Continue Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Continue where you left off",
                  style: GoogleFonts.manrope(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "VIEW ALL",
                  style: GoogleFonts.dmMono(
                    color: AppTheme.textMuted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _buildHTMLSessionRow("Interview preparation", "15 min ago · 8 messages"),
            _buildHTMLSessionRow("Starting difficult conversations", "Yesterday · Confidence 72%"),
          ],
        ),
      ),
    );
  }

  Widget _buildHTMLSessionRow(String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.lineBorder)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppTheme.panelBg2,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: const Text("◫", style: TextStyle(fontSize: 16, color: Colors.white)),
          ),
          const SizedBox(width: 13),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.manrope(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 3),
              Text(subtitle, style: GoogleFonts.manrope(color: AppTheme.textMuted, fontSize: 10)),
            ],
          ),
          const Spacer(),
          const Text("›", style: TextStyle(color: Color(0xFF5F646D), fontSize: 18)),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return const SizedBox.shrink();
  }
}

class HomeDashboardViewLegacy extends ConsumerStatefulWidget {
  const HomeDashboardViewLegacy({super.key});
  @override
  ConsumerState<HomeDashboardViewLegacy> createState() => _HomeDashboardViewStateLegacy();
}

class _HomeDashboardViewStateLegacy extends ConsumerState<HomeDashboardViewLegacy> {
  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

class RewriteEngineView extends StatefulWidget {
  const RewriteEngineView({super.key});

  @override
  State<RewriteEngineView> createState() => _RewriteEngineViewState();
}

class _RewriteEngineViewState extends State<RewriteEngineView> {
  final TextEditingController _inputController = TextEditingController();
  String _selectedTone = "Confident";
  String _rewrittenText = "";
  String _suggestion = "";
  bool _isLoading = false;
  String _selectedContext = "General";

  final List<String> _tones = ["Confident", "Warm", "Professional", "Friendly"];

  void _performRewrite() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _isLoading = true;
      _rewrittenText = "";
      _suggestion = "";
    });

    try {
      final response = await http.post(
        Uri.parse("http://127.0.0.1:8000/rewrite"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "text": text,
          "tone": _selectedTone,
          "context": _selectedContext,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _rewrittenText = data["improved"] ?? "";
          _suggestion = data["suggestion"] ?? "";
        });
      } else {
        _simulateFallbackRewrite(text);
      }
    } catch (e) {
      _simulateFallbackRewrite(text);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _simulateFallbackRewrite(String text) {
    setState(() {
      _rewrittenText = "I couldn't generate a response right now. Please try again.";
      _suggestion = "Service is currently unavailable. Please verify that the backend server is running.";
    });
  }


  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("REWRITE ENGINE", style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 8),
                  Text("Keep your meaning.\nChange the impact.", style: Theme.of(context).textTheme.headlineLarge),
                ],
              ),
              Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.limeAccent,
                ),
                alignment: Alignment.center,
                child: const Text("✦", style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.panelBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.lineBorder),
            ),
            child: TextField(
              controller: _inputController,
              maxLines: 4,
              style: GoogleFonts.manrope(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: "Paste the message you want to improve...",
                hintStyle: GoogleFonts.manrope(color: AppTheme.textMuted, fontSize: 14),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _tones.map((t) {
                final isSelected = _selectedTone == t;
                return GestureDetector(
                  onTap: () => setState(() => _selectedTone = t),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.limeAccent : AppTheme.panelBg,
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: isSelected ? Colors.transparent : AppTheme.lineBorder),
                    ),
                    child: Text(
                      t.toUpperCase(),
                      style: GoogleFonts.dmMono(
                        color: isSelected ? Colors.black : AppTheme.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "CONTEXT",
            style: GoogleFonts.dmMono(
              color: AppTheme.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w500,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppTheme.panelBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.lineBorder),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedContext,
                dropdownColor: AppTheme.panelBg,
                style: GoogleFonts.manrope(color: Colors.white, fontSize: 13),
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                items: ["General", "Interview", "Dating", "Friendship"].map((val) {
                  return DropdownMenuItem<String>(
                    value: val,
                    child: Text(val),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedContext = val;
                    });
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 32),
          GestureDetector(
            onTap: _isLoading ? null : _performRewrite,
            child: Container(
              height: 54,
              decoration: BoxDecoration(
                color: AppTheme.limeAccent,
                borderRadius: BorderRadius.circular(17),
              ),
              alignment: Alignment.center,
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.black)
                  : Text(
                      "Rewrite with AI ✦",
                      style: GoogleFonts.manrope(
                        color: const Color(0xFF090B05),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
          ),
          if (_rewrittenText.isNotEmpty) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0x0EFFFF00),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0x2ED8FF3E)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "REFINED VERSION",
                    style: GoogleFonts.dmMono(
                      color: const Color(0xFFA8BF43),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _rewrittenText,
                    style: GoogleFonts.manrope(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _suggestion,
                    style: GoogleFonts.manrope(
                      color: const Color(0xFF949A84),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class ProgressAnalyticsView extends StatelessWidget {
  const ProgressAnalyticsView({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("METRICS", style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 8),
                  Text("Your Progress", style: Theme.of(context).textTheme.headlineLarge),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF171922), Color(0xFF0D0F13)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppTheme.lineBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("AVERAGE CONFIDENCE", style: GoogleFonts.dmMono(color: AppTheme.limeAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                Center(
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.limeAccent, width: 4),
                    ),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("84", style: GoogleFonts.manrope(color: Colors.white, fontSize: 42, fontWeight: FontWeight.w800, letterSpacing: -2)),
                        Text("OVERALL", style: GoogleFonts.dmMono(color: AppTheme.textMuted, fontSize: 9)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildMetricRow("Clarity Average", "89%"),
                _buildMetricRow("Pacing Stability", "92%"),
                _buildMetricRow("Filler words reduction", "64% ↓"),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "RECENT MILESTONES",
            style: GoogleFonts.dmMono(
              color: AppTheme.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          _buildMilestoneRow("🏆", "STAR Method Champion", "Structure metric hit 95% in mock interview"),
          _buildMilestoneRow("⚡", "Anxiety Control", "Maintained < 15% anxiety score for 3 rounds"),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.lineBorder)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.manrope(color: Colors.white, fontSize: 12)),
          Text(value, style: GoogleFonts.dmMono(color: AppTheme.limeAccent, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildMilestoneRow(String icon, String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.panelBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.lineBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.panelBg2,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(icon, style: const TextStyle(fontSize: 14)),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.manrope(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(subtitle, style: GoogleFonts.manrope(color: AppTheme.textMuted, fontSize: 10)),
            ],
          )
        ],
      ),
    );
  }
}



