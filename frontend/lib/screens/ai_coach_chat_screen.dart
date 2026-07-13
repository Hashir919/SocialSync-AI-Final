import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../state/chat_provider.dart';
import '../theme/app_theme.dart';
import '../theme/app_theme.dart'; // GlassBox is defined here

class AICoachChatScreen extends ConsumerStatefulWidget {
  final String? initialMessage;

  const AICoachChatScreen({super.key, this.initialMessage});

  @override
  ConsumerState<AICoachChatScreen> createState() => _AICoachChatScreenState();
}

class _AICoachChatScreenState extends ConsumerState<AICoachChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    final chat = ref.read(chatProvider);
    if (widget.initialMessage != null && widget.initialMessage!.trim().isNotEmpty) {
      chat.sendMessage(widget.initialMessage!);
    }
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

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _messageController.clear();
    ref.read(chatProvider).sendMessage(text);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final chat = ref.watch(chatProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    return Scaffold(
      backgroundColor: AppTheme.primaryBg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF07080A),
        elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: AppTheme.limeAccent),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "AI Coach Chat",
                  style: GoogleFonts.manrope(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                ),
                Text(
                  "ONLINE & READY",
                  style: GoogleFonts.dmMono(color: AppTheme.textMuted, fontSize: 8, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => ref.read(chatProvider).resetChat(),
            icon: const Icon(Icons.refresh, color: AppTheme.textMuted, size: 20),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Divider(height: 1, color: AppTheme.lineBorder),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                itemCount: chat.messages.length + (chat.isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == chat.messages.length) {
                    // Loading placeholder using GlassBox
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: GlassBox(
                        blur: 12,
                        opacity: 0.12,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Text(
                            "Thinking...",
                            style: TextStyle(color: Colors.white70, fontStyle: FontStyle.italic),
                          ),
                        ),
                      ),
                    );
                  }
                  final msg = chat.messages[index];
                  final isUser = msg['sender'] == 'user';
                  return Align(
                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: GlassBox(
                      blur: 16,
                      opacity: isUser ? 0.25 : 0.12,
                      color: isUser ? AppTheme.limeAccent : AppTheme.panelBg,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(18),
                        topRight: const Radius.circular(18),
                        bottomLeft: isUser ? const Radius.circular(18) : Radius.zero,
                        bottomRight: isUser ? Radius.zero : const Radius.circular(18),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Text(
                          msg['text'] ?? '',
                          style: GoogleFonts.manrope(
                            color: isUser ? const Color(0xFF090B05) : Colors.white,
                            fontSize: 13.5,
                            height: 1.45,
                            fontWeight: isUser ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: const BoxDecoration(color: Color(0xFF07080A), border: Border(top: BorderSide(color: AppTheme.lineBorder, width: 1))),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(color: AppTheme.panelBg, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppTheme.lineBorder)),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              style: GoogleFonts.manrope(color: Colors.white, fontSize: 14),
                              cursorColor: AppTheme.limeAccent,
                              decoration: InputDecoration(
                                hintText: "Talk to AI Coach...",
                                hintStyle: GoogleFonts.manrope(color: AppTheme.textMuted, fontSize: 14),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              ),
                              onSubmitted: (_) => _sendMessage(),
                            ),
                          ),
                          GestureDetector(
                            onTap: _sendMessage,
                            child: const Padding(
                              padding: EdgeInsets.all(6.0),
                              child: CircleAvatar(radius: 12, backgroundColor: AppTheme.limeAccent, child: Icon(Icons.arrow_upward, color: Colors.black, size: 14)),
                            ),
                          ),
                        ],
                      ),
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
