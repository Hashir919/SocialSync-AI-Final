import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// ChatProvider handles the list of messages and loading state for the AI coach chat.
class ChatProvider extends ChangeNotifier {
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  List<Map<String, String>> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;

  /// Sends a user message to the backend and appends the coach reply.
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    // Add user message
    _messages.add({'sender': 'user', 'text': text.trim()});
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:8002/generate'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"prompt": text.trim()}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final coachReply = data['reply'] ?? 'I couldn\'t generate a response.';
        _messages.add({'sender': 'coach', 'text': coachReply});
      } else {
        _messages.add({
          'sender': 'coach',
          'text': 'I couldn\'t generate a response right now. Please try again later.'
        });
      }
    } catch (e) {
      _messages.add({
        'sender': 'coach',
        'text': 'I couldn\'t generate a response right now. Please try again later.'
      });
    }
    _isLoading = false;
    notifyListeners();
  }

  /// Clears the conversation and resets the loading flag.
  void resetChat() {
    _messages.clear();
    _isLoading = false;
    notifyListeners();
  }
}
final chatProvider = ChangeNotifierProvider<ChatProvider>((ref) => ChatProvider());
