import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/websocket_service.dart';
import '../theme/app_theme.dart';

class PracticeSessionScreen extends ConsumerStatefulWidget {
  final String coachName;
  final String contextName;
  final IconData coachIcon;
  final Color themeColor;

  const PracticeSessionScreen({
    super.key,
    required this.coachName,
    required this.contextName,
    required this.coachIcon,
    required this.themeColor,
  });

  @override
  ConsumerState<PracticeSessionScreen> createState() => _PracticeSessionScreenState();
}

class _PracticeSessionScreenState extends ConsumerState<PracticeSessionScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  
  final List<int> _anxietyScores = [];
  final List<int> _confidenceScores = [];
  final List<int> _clarityScores = [];
  final Set<String> _collectedTips = {};
  int _lastProcessedReplyCounter = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ws = ref.read(webSocketServiceProvider.notifier);
      _lastProcessedReplyCounter = ref.read(webSocketServiceProvider).replyCounter;
      ws.selectedContext = widget.contextName;
      ws.selectedPersona = widget.coachName;
      ws.mode = "chat";
      ws.connect();
      
      Future.delayed(const Duration(milliseconds: 500), () {
        ws.sendText("hello");
      });
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ws = ref.watch(webSocketServiceProvider);
    
    ref.listen<WebSocketService>(webSocketServiceProvider, (prev, next) {
      if (next.transcript.isNotEmpty && next.transcript != "..." && next.transcript != "hello") {
        if (next.isListening) {
          if (_messages.isNotEmpty && _messages.last["sender"] == "user") {
            setState(() {
              _messages.last["text"] = next.transcript;
            });
          } else {
            setState(() {
              _messages.add({
                "sender": "user",
                "text": next.transcript,
              });
            });
          }
          _scrollToBottom();
        } else {
          final lastUserIndex = _messages.lastIndexWhere((m) => m["sender"] == "user");
          final alreadyAdded = lastUserIndex != -1 && _messages[lastUserIndex]["text"] == next.transcript;
          if (!alreadyAdded) {
            setState(() {
              _messages.add({
                "sender": "user",
                "text": next.transcript,
              });
            });
            _scrollToBottom();
          }
        }
      }

      if (next.replyCounter > _lastProcessedReplyCounter) {
        _lastProcessedReplyCounter = next.replyCounter;
        if (next.personaReply.isNotEmpty) {
          setState(() {
            _messages.add({
              "sender": "coach",
              "text": next.personaReply,
            });
          });
          
          int anx = int.tryParse(next.anxiety.replaceAll('%', '')) ?? 0;
          int conf = int.tryParse(next.confidence.replaceAll('%', '')) ?? 0;
          int clar = int.tryParse(next.clarity.replaceAll('%', '')) ?? 0;
          if (anx > 0) _anxietyScores.add(anx);
          if (conf > 0) _confidenceScores.add(conf);
          if (clar > 0) _clarityScores.add(clar);
          
          for (var tip in next.coachingTips) {
            _collectedTips.add(tip);
          }
          
          _scrollToBottom();
        }
      }
    });

    return Scaffold(
      backgroundColor: AppTheme.primaryBg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF07080A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
          onPressed: () => _confirmExit(context),
        ),
        title: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.themeColor,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.coachName,
                  style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Text(
                  "PRACTICE ACTIVE",
                  style: GoogleFonts.dmMono(fontSize: 8, color: const Color(0xFF34C759)),
                ),
              ],
            )
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: TextButton(
              onPressed: () => _showEndSessionSummary(context),
              style: TextButton.styleFrom(
                backgroundColor: AppTheme.panelBg,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                "End Session",
                style: GoogleFonts.manrope(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          )
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _messages.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.limeAccent,
                        strokeWidth: 2,
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final msg = _messages[index];
                        final isUser = msg["sender"] == "user";
                        return Align(
                          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: isUser ? AppTheme.limeAccent : AppTheme.panelBg,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(18),
                                topRight: const Radius.circular(18),
                                bottomLeft: isUser ? const Radius.circular(18) : Radius.zero,
                                bottomRight: isUser ? Radius.zero : const Radius.circular(18),
                              ),
                              border: Border.all(
                                color: isUser ? Colors.transparent : AppTheme.lineBorder,
                                width: 1,
                              ),
                            ),
                            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                            child: Text(
                              msg["text"] ?? "",
                              style: GoogleFonts.manrope(
                                color: isUser ? const Color(0xFF090B05) : Colors.white,
                                fontSize: 13.5,
                                height: 1.45,
                                fontWeight: isUser ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),

            // Metrics quick panel
            if (_anxietyScores.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: const BoxDecoration(
                  color: Color(0xFF07080A),
                  border: Border(top: BorderSide(color: AppTheme.lineBorder)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatIndicator("Anxiety", "${_anxietyScores.last}%", const Color(0xFFFF3B30)),
                    _buildStatIndicator("Confidence", "${_confidenceScores.last}%", AppTheme.limeAccent),
                    _buildStatIndicator("Clarity", "${_clarityScores.last}%", Colors.cyanAccent),
                  ],
                ),
              ),

            // Input panel
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              decoration: const BoxDecoration(
                color: Color(0xFF07080A),
                border: Border(
                  top: BorderSide(color: AppTheme.lineBorder, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.panelBg,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppTheme.lineBorder),
                      ),
                      child: TextField(
                        controller: _messageController,
                        style: GoogleFonts.manrope(color: Colors.white, fontSize: 14),
                        cursorColor: AppTheme.limeAccent,
                        decoration: InputDecoration(
                          hintText: "Respond to coach...",
                          hintStyle: GoogleFonts.manrope(color: AppTheme.textMuted, fontSize: 14),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                        onSubmitted: (val) {
                          if (val.trim().isNotEmpty) {
                            ws.mode = "chat";
                            ws.sendText(val);
                            _messageController.clear();
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: ws.toggleListening,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: ws.isListening ? Colors.red : AppTheme.panelBg,
                        border: Border.all(
                          color: ws.isListening ? Colors.transparent : AppTheme.lineBorder,
                        ),
                      ),
                      child: Icon(
                        ws.isListening ? Icons.stop : Icons.mic,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStatIndicator(String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 6),
        Text(
          "$label: ",
          style: GoogleFonts.dmMono(color: AppTheme.textMuted, fontSize: 10.5),
        ),
        Text(
          value,
          style: GoogleFonts.dmMono(color: color, fontSize: 10.5, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  void _confirmExit(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.panelBg,
        title: Text("Exit Practice?", style: GoogleFonts.manrope(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text("Your session progress will not be saved.", style: GoogleFonts.manrope(color: AppTheme.textMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: GoogleFonts.manrope(color: AppTheme.textMuted)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text("Exit", style: GoogleFonts.manrope(color: const Color(0xFFFF3B30), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showEndSessionSummary(BuildContext context) async {
    int finalAnxiety = _anxietyScores.isEmpty ? 25 : (_anxietyScores.reduce((a, b) => a + b) / _anxietyScores.length).round();
    int finalConfidence = _confidenceScores.isEmpty ? 70 : (_confidenceScores.reduce((a, b) => a + b) / _confidenceScores.length).round();
    int finalClarity = _clarityScores.isEmpty ? 80 : (_clarityScores.reduce((a, b) => a + b) / _clarityScores.length).round();
    
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user != null) {
        await supabase.from('practice_sessions').insert({
          'user_id': user.id,
          'persona': widget.coachName,
          'duration_seconds': 120,
          'final_anxiety': finalAnxiety,
          'final_confidence': finalConfidence,
          'final_clarity': finalClarity,
          'feedback_tips': _collectedTips.toList().isEmpty ? ["Try to speak confidently", "Maintain eye contact"] : _collectedTips.toList(),
          'created_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      debugPrint("Failed to save practice session summary: $e");
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppTheme.primaryBg,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          border: Border(top: BorderSide(color: AppTheme.lineBorder, width: 1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: AppTheme.panelBg2, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Session Summary",
              style: GoogleFonts.manrope(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(
              "Here is how you performed with the ${widget.coachName}.",
              style: GoogleFonts.manrope(color: AppTheme.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(child: _buildMetricSummaryBox(context, "Anxiety", "$finalAnxiety%", const Color(0xFFFF3B30))),
                const SizedBox(width: 8),
                Expanded(child: _buildMetricSummaryBox(context, "Confidence", "$finalConfidence%", AppTheme.limeAccent)),
                const SizedBox(width: 8),
                Expanded(child: _buildMetricSummaryBox(context, "Clarity", "$finalClarity%", Colors.cyanAccent)),
              ],
            ),
            const SizedBox(height: 24),

            Text(
              "IMPROVEMENT TIPS",
              style: GoogleFonts.dmMono(color: AppTheme.textMuted, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.5),
            ),
            const SizedBox(height: 12),
            _collectedTips.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: _buildTipRow("Great job! Keep practicing to maintain your steady pacing and flow."),
                  )
                : Column(
                    children: _collectedTips.map((tip) => _buildTipRow(tip)).toList(),
                  ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.limeAccent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    "Complete Session ✦",
                    style: GoogleFonts.manrope(
                      color: const Color(0xFF090B05),
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricSummaryBox(BuildContext context, String label, String val, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.panelBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.lineBorder),
      ),
      child: Column(
        children: [
          Text(
            val,
            style: GoogleFonts.manrope(color: color, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.dmMono(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.w500),
          )
        ],
      ),
    );
  }

  Widget _buildTipRow(String tipText) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("✓", style: TextStyle(color: AppTheme.limeAccent, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              tipText,
              style: GoogleFonts.manrope(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
