import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

final webSocketServiceProvider = ChangeNotifierProvider<WebSocketService>((ref) {
  return WebSocketService();
});

class WebSocketService extends ChangeNotifier {
  WebSocketChannel? _channel;
  Timer? _reconnectTimer;
  bool _isConnected = false;
  bool _isUsingLocalSimulation = false;
  
  // State variables
  String _transcript = "...";
  String _emotion = "Neutral";
  String _confidence = "0%";
  String _anxiety = "0%";
  String _clarity = "0%";
  String _pace = "N/A";
  String _suggestion = "Ready to analyze...";
  String _improved = "";
  List<String> _coachingTips = [];
  String _personaReply = "";
  int _replyCounter = 0;
  
  String _selectedContext = "Friendship";
  String _selectedPersona = "";
  String _mode = "chat";
  
  bool _isListening = false;
  
  final _supabase = Supabase.instance.client;
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechEnabled = false;

  WebSocketService() {
    _initSpeech();
  }

  void _initSpeech() async {
    try {
      _speechEnabled = await _speech.initialize(
        onStatus: (status) {
          if (status == 'done' && _isListening) {
            _speech.listen(onResult: _onSpeechResult);
          }
        },
        onError: (errorNotification) => debugPrint('STT Error: $errorNotification'),
      );
    } catch (e) {
      debugPrint("STT initialization failed: $e");
    }
  }

  // Getters
  String get transcript => _transcript;
  String get emotion => _emotion;
  String get confidence => _confidence;
  String get anxiety => _anxiety;
  String get clarity => _clarity;
  String get pace => _pace;
  String get suggestion => _suggestion;
  String get improved => _improved;
  List<String> get coachingTips => _coachingTips;
  String get personaReply => _personaReply;
  int get replyCounter => _replyCounter;
  bool get isListening => _isListening;
  bool get isConnected => _isConnected;
  bool get isUsingLocalSimulation => _isUsingLocalSimulation;
  
  String get selectedContext => _selectedContext;
  String get selectedPersona => _selectedPersona;
  String get mode => _mode;

  set selectedContext(String val) {
    _selectedContext = val;
    notifyListeners();
  }

  set selectedPersona(String val) {
    _selectedPersona = val;
    notifyListeners();
  }

  set mode(String val) {
    _mode = val;
    notifyListeners();
  }

  void connect() {
    if (_isConnected && !_isUsingLocalSimulation) return;
    _channel?.sink.close();
    _initConnection();
  }

  void _initConnection() {
    try {
      const backendUrl = String.fromEnvironment(
        'BACKEND_URL',
        defaultValue: 'ws://127.0.0.1:8000/ws',
      );
      debugPrint("WS: Attempting to connect to $backendUrl");
      _channel = WebSocketChannel.connect(
        Uri.parse(backendUrl),
      );
      
      _isConnected = true;
      _isUsingLocalSimulation = false;
      _suggestion = "Connected to local server";
      notifyListeners();

      _channel!.stream.listen((message) {
        debugPrint("WS: Received message: $message");
        final data = jsonDecode(message);
        
        _transcript = data['transcript'] ?? _transcript;
        _emotion = data['emotion'] ?? _emotion;
        _confidence = data['confidence'] ?? _confidence;
        _anxiety = data['anxiety'] ?? _anxiety;
        _clarity = data['clarity'] ?? _clarity;
        _pace = data['pace'] ?? _pace;
        _suggestion = data['suggestion'] ?? _suggestion;
        _improved = data['improved'] ?? "";
        
        if (data['coaching_tips'] != null) {
          _coachingTips = List<String>.from(data['coaching_tips']);
        } else {
          _coachingTips = [];
        }
        
        _personaReply = data['persona_reply'] ?? "";
        _replyCounter++;
        
        _saveToSupabase();
        notifyListeners();
      }, onDone: () {
        debugPrint("WS: Stream closed. Activating client-side simulation fallback.");
        _enableLocalSimulation();
      }, onError: (error) {
        debugPrint("WS: Stream error: $error. Activating client-side simulation fallback.");
        _enableLocalSimulation();
      });
    } catch (e) {
      debugPrint("WS: Exception during connect: $e. Activating client-side simulation fallback.");
      _enableLocalSimulation();
    }
  }

  void _enableLocalSimulation() {
    _isConnected = true;
    _isUsingLocalSimulation = true;
    _suggestion = "Active (Offline AI Coach Engine)";
    notifyListeners();
  }

  void simulateLocalResponse(String text) {
    // Mimic processing latency
    Future.delayed(const Duration(milliseconds: 400), () {
      _transcript = text;
      _anxiety = "0%";
      _confidence = "0%";
      _clarity = "0%";
      _emotion = "Neutral";
      _suggestion = "Service is currently offline. Please verify that the backend server is running.";
      _improved = "";
      _coachingTips = [];
      _personaReply = "I couldn't generate a response right now. Please try again.";
      _replyCounter++;
      
      _saveToSupabase();
      notifyListeners();
    });
  }

  Future<void> _saveToSupabase() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;
      
      await _supabase.from('conversations').insert({
        'user_id': user.id,
        'transcript': _transcript,
        'emotion': _emotion,
        'pace': _pace,
        'confidence': _confidence,
        'suggestion': _suggestion,
        'context': _selectedContext,
        'mode': _mode,
        'created_at': DateTime.now().toIso8601String(),
      });
      
      int anxietyVal = int.tryParse(_anxiety.replaceAll('%', '')) ?? 0;
      int confidenceVal = int.tryParse(_confidence.replaceAll('%', '')) ?? 0;
      int clarityVal = int.tryParse(_clarity.replaceAll('%', '')) ?? 0;
      
      await _supabase.from('anxiety_logs').insert({
        'user_id': user.id,
        'anxiety': anxietyVal,
        'confidence': confidenceVal,
        'clarity': clarityVal,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint("Supabase insert suppressed (expected in offline demo): $e");
    }
  }

  void toggleListening() {
    if (!_isConnected) return;
    _isListening = !_isListening;
    _mode = "voice";
    
    if (_isListening) {
      if (_speechEnabled) {
        _suggestion = "Listening...";
        _speech.listen(onResult: _onSpeechResult);
      } else {
        _suggestion = "Mic permission denied.";
        sendText("Starting voice analysis...");
      }
    } else {
      _speech.stop();
      _suggestion = "Paused";
    }
    notifyListeners();
  }

  void _onSpeechResult(result) {
    if (result.recognizedWords.isNotEmpty) {
      _transcript = result.recognizedWords;
      if (result.finalResult) {
        sendText(result.recognizedWords);
      }
      notifyListeners();
    }
  }

  void sendText(String text) {
    if (_channel != null && text.isNotEmpty && _isConnected && !_isUsingLocalSimulation) {
      try {
        final payload = {
          "text": text,
          "context": _selectedContext,
          "mode": _mode,
          "persona": _selectedPersona
        };
        debugPrint("WS: Sending payload: ${jsonEncode(payload)}");
        _channel!.sink.add(jsonEncode(payload));
        _transcript = text;
        notifyListeners();
      } catch (e) {
        debugPrint("WebSocket write error, fallback to local simulation: $e");
        _enableLocalSimulation();
        simulateLocalResponse(text);
      }
    } else {
      _transcript = text;
      notifyListeners();
      simulateLocalResponse(text);
    }
  }

  @override
  void dispose() {
    _reconnectTimer?.cancel();
    _channel?.sink.close(status.goingAway);
    super.dispose();
  }
}
