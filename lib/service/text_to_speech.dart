import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/material.dart';

class TtsService {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isSpeaking = false;

  Future<void> initTts() async {
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setSpeechRate(0.5); 
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);

    _flutterTts.setStartHandler(() => _isSpeaking = true);
    _flutterTts.setCompletionHandler(() => _isSpeaking = false);
    _flutterTts.setErrorHandler((msg) {
      _isSpeaking = false;
      debugPrint('TTS error: $msg');
    });

    debugPrint('TTS initialized');
  }

  Future<void> speak(String text) async {
    if (_isSpeaking) return; 
    await _flutterTts.speak(text);
  }

  Future<void> stop() async {
    await _flutterTts.stop();
    _isSpeaking = false;
  }

  void dispose() {
    _flutterTts.stop();
  }
}