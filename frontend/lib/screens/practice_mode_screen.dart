import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'practice_session_screen.dart';

class PracticeModeScreen extends StatelessWidget {
  const PracticeModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Row(
                children: [
                  if (Navigator.canPop(context)) ...[
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 16),
                  ],
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "SCENARIOS",
                        style: GoogleFonts.dmMono(
                          color: AppTheme.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.8,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Practice Mode",
                        style: GoogleFonts.manrope(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1.8,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "Choose a simulated social scenario. Practice real-time responses to build immediate confidence.",
                style: GoogleFonts.manrope(
                  color: AppTheme.textMuted,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Scenarios linked to AI Personas
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _buildScenarioCard(
                    context: context,
                    title: "Job Interview Coach",
                    description: "Practice answering tough behavioral questions and managing professional pacing.",
                    symbol: "💼",
                    color: AppTheme.limeAccent,
                    coachName: "Interview Coach",
                    contextName: "Interview",
                  ),
                  const SizedBox(height: 12),
                  _buildScenarioCard(
                    context: context,
                    title: "Dating Coach",
                    description: "Work on maintaining engaging, warm small talk and avoiding dry pauses.",
                    symbol: "❤️",
                    color: Colors.pinkAccent,
                    coachName: "Dating Coach",
                    contextName: "Dating",
                  ),
                  const SizedBox(height: 12),
                  _buildScenarioCard(
                    context: context,
                    title: "Public Speaking Coach",
                    description: "Deliver presentations while the coach monitors your confidence, pace, and clarity.",
                    symbol: "🎤",
                    color: Colors.cyanAccent,
                    coachName: "Public Speaking Coach",
                    contextName: "Public Speaking",
                  ),
                  const SizedBox(height: 12),
                  _buildScenarioCard(
                    context: context,
                    title: "Networking Coach",
                    description: "Practice asserting value, asking follow-up questions, and active listening.",
                    symbol: "🤝",
                    color: Colors.orangeAccent,
                    coachName: "Networking Coach",
                    contextName: "Networking",
                  ),
                  const SizedBox(height: 12),
                  _buildScenarioCard(
                    context: context,
                    title: "Friendship Coach",
                    description: "Practice casual conversations, handling dry replies or conflicts with friends.",
                    symbol: "💬",
                    color: Colors.greenAccent,
                    coachName: "Friendship Coach",
                    contextName: "Friendship",
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScenarioCard({
    required BuildContext context,
    required String title,
    required String description,
    required String symbol,
    required Color color,
    required String coachName,
    required String contextName,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PracticeSessionScreen(
              coachName: coachName,
              contextName: contextName,
              coachIcon: Icons.psychology,
              themeColor: color,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.panelBg,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppTheme.lineBorder, width: 1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.panelBg2,
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Text(symbol, style: const TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.manrope(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    description,
                    style: GoogleFonts.manrope(
                      color: AppTheme.textMuted,
                      fontSize: 12,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text("›", style: TextStyle(color: Color(0xFF5F646D), fontSize: 20)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
