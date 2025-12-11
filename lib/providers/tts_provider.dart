import 'package:flutter/foundation.dart';
import 'dart:js' as js;

class TtsProvider extends ChangeNotifier {
  bool _isEnabled = false;
  
  bool get isEnabled => _isEnabled;

  TtsProvider() {
    _initTts();
  }

  Future<void> _initTts() async {
    // Initialize Web Speech API
    try {
      js.context.callMethod('eval', ['''
        window.speechSynthesis = window.speechSynthesis || {};
        window.SpeechSynthesisUtterance = window.SpeechSynthesisUtterance || function(text) {
          this.text = text;
          this.rate = 0.8;
          this.pitch = 1.0;
          this.volume = 1.0;
        };
      ''']);
      debugPrint('Web Speech API initialized');
    } catch (e) {
      debugPrint('Web Speech API not available: $e');
    }
  }

  void toggleTts() {
    _isEnabled = !_isEnabled;
    notifyListeners();
    speak(_isEnabled 
      ? 'Screen reader mode enabled. Hover over elements to hear them.' 
      : 'Screen reader mode disabled');
  }

  Future<void> speak(String text) async {
    if (!_isEnabled || text.isEmpty) return;
    
    try {
      if (kIsWeb) {
        // Use Web Speech API - properly escape the text for JavaScript
        final escapedText = text
            .replaceAll('\\', '\\\\')
            .replaceAll('"', '\\"')
            .replaceAll('\n', ' ')
            .replaceAll('\r', ' ');
        
        js.context.callMethod('eval', ['''
          if ('speechSynthesis' in window) {
            window.speechSynthesis.cancel();
            const utterance = new SpeechSynthesisUtterance("$escapedText");
            utterance.rate = 0.8;
            utterance.pitch = 1.0;
            utterance.volume = 1.0;
            window.speechSynthesis.speak(utterance);
          }
        ''']);
      }
      debugPrint('Speaking: $text');
    } catch (e) {
      debugPrint('TTS error: $e');
    }
  }

  Future<void> stop() async {
    try {
      if (kIsWeb) {
        js.context.callMethod('eval', ['window.speechSynthesis?.cancel();']);
      }
    } catch (e) {
      debugPrint('Stop error: $e');
    }
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
