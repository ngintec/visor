import 'package:flutter/material.dart';
import 'package:visorngin/models/screen_params.dart';
import 'package:visorngin/service/speech_to_text.dart';
import 'package:visorngin/service/text_to_speech.dart';
import 'package:visorngin/ui/detector_widget.dart';
import 'package:ultralytics_yolo/ultralytics_yolo.dart';

final modelId = YOLO.defaultOfficialModel() ?? 'yolo26n';

/// [HomeView] stacks [DetectorWidget]
class HomeView extends StatelessWidget {
  HomeView({super.key});

  //for speech to text
  final SpeechService _speechService = SpeechService();
  final TtsService _ttsService = TtsService();

  @override
  Widget build(BuildContext context) {
    ScreenParams.screenSize = MediaQuery.sizeOf(context);
    return Scaffold(
        key: GlobalKey(),
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: Image.asset(
            'assets/images/visor_appbar.png',
            alignment: Alignment.topCenter,
            fit: BoxFit.contain,
          ),
        ),
        // body: const DetectorWidget(),
        body: YOLOView(
          modelPath: modelId,
          confidenceThreshold: 0.50,
          streamingConfig:
              const YOLOStreamingConfig(maxFPS: 1, inferenceFrequency: 1),
          onResult: (results) async {
            for (final r in results) {
              debugPrint('${r.className}: ${r.confidence}');
              debugPrint(
                  '${r.boundingBox.width}/${MediaQuery.of(context).size.width}:${r.boundingBox.height}/${MediaQuery.of(context).size.height}');
              var wideplacement =
                  r.boundingBox.width / MediaQuery.of(context).size.width;
              if (wideplacement > 0.8) {
                await _ttsService.speak("${r.className} is in front of you");
              } else if (wideplacement > 0.4 &&
                  r.boundingBox.left < MediaQuery.of(context).size.width / 2) {
                await _ttsService.speak("${r.className} is towards left");
              } else if (wideplacement > 0.4 &&
                  r.boundingBox.left < MediaQuery.of(context).size.width / 2) {
                await _ttsService.speak("${r.className} is towards right");
              }
            }
          },
        ));
  }
}
