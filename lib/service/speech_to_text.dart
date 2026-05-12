import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';

class SpeechService {
  final SpeechToText _speechToText = SpeechToText();
  final List<String> recognizedWords = [];
  Function(String)? onWordRecognized;
  Function(String)? onFinalResult;

  final List<String> _startVariations = ['start', 'art', 'snark'];
  final List<String> _stopVariations = ['stop', 'top', 'cop'];

  Future<void> initSpeech() async {
    bool enabled = await _speechToText.initialize(
      onError: (error) {
        if (error.errorMsg == 'error_speech_timeout' ||
            error.errorMsg == 'error_no_match') {
          Future.delayed(const Duration(milliseconds: 500), () => startListening());
        } else if (error.permanent) {
          Future.delayed(const Duration(seconds: 1), () => initSpeech());
        }
      },
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          startListening();
        }
      },
    );

    if (enabled) startListening();
  }

  Future<void> startListening() async {
    if (_speechToText.isListening) return;
    await _speechToText.listen(
      onResult: (result) {
        if (result.finalResult) {
          final sentence = result.recognizedWords.toLowerCase().trim();
          debugPrint('Final sentence: $sentence');
          onFinalResult?.call(sentence); // send full sentence to chat

          // check each word for commands
          final words = sentence.split(' ');
          
          for (final word in words) {
            recognizedWords.add(word);
            debugPrint('Recognized words list: $recognizedWords');

            if(_startVariations.contains(word)) {
              debugPrint("Start command recognized via: $word");
              onWordRecognized?.call('start');
              break;
            } else if (_stopVariations.contains(word)) {
              debugPrint("Stop command recognized via: $word");
              onWordRecognized?.call('stop');
              break;
            }
          }

          if(recognizedWords.length>50) {
            recognizedWords.clear();
          }
        }
      },
      listenFor: const Duration(seconds: 10),
      pauseFor: const Duration(seconds: 2),
      listenOptions: SpeechListenOptions(
        cancelOnError: false,
        partialResults: false,
        listenMode: ListenMode.dictation,
      ),
    );
  }
}