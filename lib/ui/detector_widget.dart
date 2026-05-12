import 'dart:async';
import 'dart:isolate';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:visorngin/models/recognition.dart';
import 'package:visorngin/models/screen_params.dart';
import 'package:visorngin/service/detector_service.dart';
import 'package:visorngin/ui/box_widget.dart';
import 'package:visorngin/ui/chat_widget.dart';
import 'package:visorngin/service/speech_to_text.dart';
import 'package:visorngin/service/text_to_speech.dart';


/// [DetectorWidget] sends each frame for inference
class DetectorWidget extends StatefulWidget {
  /// Constructor
  const DetectorWidget({super.key});

  @override
  State<DetectorWidget> createState() => _DetectorWidgetState();
}

class _DetectorWidgetState extends State<DetectorWidget>
    with WidgetsBindingObserver {
  /// List of available cameras
  late List<CameraDescription> cameras;

  /// Controller
  CameraController? _cameraController;

  // use only when initialized, so - not null
  get _controller => _cameraController;

  /// Object Detector is running on a background [Isolate]. This is nullable
  /// because acquiring a [Detector] is an asynchronous operation. This
  /// value is `null` until the detector is initialized.
  Detector? _detector;
  StreamSubscription? _subscription;

  /// Results to draw bounding boxes
  List<Recognition>? results;

  /// Realtime stats
  Map<String, String>? stats;


  //For the start and stop button
  bool _isCameraActive = false;

  // // To control frame processing rate
  DateTime _lastFrameTime = DateTime.now();
  final int _frameIntervalMs = 1000; // process 10 frames per second

  //for speech to text
  final SpeechService _speechService = SpeechService();

  //for text to speech
  final TtsService _ttsService = TtsService();
  DateTime _lastSpokenTime = DateTime.now();
  final int _speakIntervalMs = 3000; // minimum interval between spoken messages

  // add with other state variables
  List<ChatEntry> _chatEntries = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // observer first
     _ttsService.initTts(); 
     _speechService.onWordRecognized = _handleSpeechWord;
     _speechService.onFinalResult = (sentence) {
      _addChatEntry(sentence, true); // green, user spoke this
    };
    _initStateAsync();
    Future.delayed(const Duration(seconds: 2), () => _speechService.initSpeech()); // speech last, after camera settles
    
  }

  void _handleSpeechWord(String word) {
    debugPrint('Handling word: $word');
    if (word == 'start' && !_isCameraActive) {
      _turnOnCamera();
      setState(() => _isCameraActive = true);
      _ttsService.speak('Processing started. Double tap to stop.');
      _addChatEntry('Processing started. Double tap to stop.', false);
    } else if (word == 'stop' && _isCameraActive) {
      _turnOffCamera();
      setState(() => _isCameraActive = false);
      _ttsService.speak('Processing stopped. Double tap to start.');
      _addChatEntry('Processing stopped. Double tap to start.', false);
    }
  }

  void _addChatEntry(String text, bool isRecognized) {
    setState(() {
      _chatEntries.add(ChatEntry(text: text, isRecognized: isRecognized));
      if (_chatEntries.length > 6) {
        _chatEntries.removeAt(0); // keep list from growing forever
      }
    });
  }

  void positionOnScreen(List<Recognition>? results) {
    if (results == null) return;
    if(results.isEmpty) return;
  
    final screenWidth = ScreenParams.screenPreviewSize.width;
    if(screenWidth == 0) return;
    final screenHeight = ScreenParams.screenPreviewSize.height;
    if(screenHeight == 0) return;
    //debugPrint("Entered function");

    final now = DateTime.now();
    if (now.difference(_lastSpokenTime).inMilliseconds < _speakIntervalMs) return;
    _lastSpokenTime = now;

    for (var result in results) {
      //debugPrint("Entered loop ${result.label}");
      //debugPrint("Location raw: ${result.location}"); 
      //debugPrint("screenPreviewSize: ${ScreenParams.screenPreviewSize}");
      final objectCenter = result.renderLocation.left + (result.renderLocation.width / 2);
      final verticalCenter= result.renderLocation.top + (result.renderLocation.height / 2);
      final objectWidth = result.renderLocation.width;
      final objectHeight = result.renderLocation.height;
      final objectArea = objectWidth * objectHeight;
      final screenArea = screenWidth * screenHeight;
      final areaRatio = objectArea / screenArea;

      //debugPrint("Object center: $objectCenter, Vertical center: $verticalCenter");
      
      final leftBoundary = screenWidth * 0.40;
      final rightBoundary = screenWidth * 0.60;
      
      final topBoundary = screenHeight * 0.40;
      final bottomBoundary = screenHeight * 0.60; 

      String sizeDescription;
      if (areaRatio < 0.01) {
        sizeDescription = 'small';
      } else if (areaRatio < 0.10) {
        sizeDescription = 'medium';
      } else {
        sizeDescription = 'large';
      }

      //debugPrint("Object center: $objectCenter, LB: $leftBoundary, RB: $rightBoundary");
      String hposition;
      if (objectCenter < leftBoundary) {
        hposition = 'LEFT';
      } else if (objectCenter < rightBoundary) {
        hposition = 'CENTER';
      } else {
        hposition = 'RIGHT';
      }
      String vposition;
      if (verticalCenter < topBoundary) {
        vposition = 'TOP';
      } else if (verticalCenter < bottomBoundary) {
        vposition = 'MIDDLE';
      } else {
        vposition = 'BOTTOM';
      }
      final announcement = '${result.label} is $sizeDescription, located at $vposition and $hposition';
      debugPrint(announcement);
      _ttsService.speak(announcement);
      _addChatEntry(announcement, false);
    }
  }

  void _initStateAsync() async {
    Detector.start().then((instance) {
      if (!mounted) return; // add this
      setState(() {
        _detector = instance;
        _subscription = instance.resultsStream.stream.listen((values) {
          if (!mounted) return; // add this
          setState(() {
            results = values['recognitions'];
            stats = values['stats'];
            positionOnScreen(results);
          });
        });
      });
    });
  }

  /// Initializes the camera by setting [_cameraController]
  Future<void> _initializeCamera() async {
    cameras = await availableCameras();
    // cameras[0] for back-camera
    _cameraController = CameraController(
      cameras[0],
      ResolutionPreset.medium,
      fps: 1,
      enableAudio: false,
    );
    await _cameraController!.initialize();
    ScreenParams.previewSize = _cameraController!.value.previewSize!;
    setState(() {});

        /// previewSize is size of each image frame captured by controller
        ///
        /// 352x288 on iOS, 240p (320x240) on Android with ResolutionPreset.low
  }

  Future<void> _turnOffCamera() async {
    if (_cameraController != null) {
      if (_cameraController!.value.isStreamingImages) {
        await _cameraController!.stopImageStream();
      }
      await _cameraController!.dispose();
      setState(() {
        _cameraController = null;
        _isCameraActive = false;
      });
    }
  }

  Future<void> _turnOnCamera() async {
    await _initializeCamera(); 
    await _cameraController?.startImageStream(onLatestImageAvailable);
    setState(() => _isCameraActive = true);
  }

@override
Widget build(BuildContext context) {
  return GestureDetector(
    behavior: HitTestBehavior.opaque,
    onDoubleTap: () async {
      if (_isCameraActive) {
        await _turnOffCamera();
        _ttsService.speak('Processing stopped. Double tap to start.');
        _addChatEntry('Processing stopped. Double tap to start.', false);
      } else {
        await _turnOnCamera();
        _ttsService.speak('Processing started. Double tap to stop.');
        _addChatEntry('Processing started. Double tap to stop.', false);
      }
    },
    child: Stack(
      children: [
        // only show camera preview when active and initialized
        if (_isCameraActive && 
            _cameraController != null && 
            _cameraController!.value.isInitialized)
          AspectRatio(
            aspectRatio: 1 / _cameraController!.value.aspectRatio,
            child: CameraPreview(_cameraController!),
          ),
        ChatWidget(entries: _chatEntries),
        if (_isCameraActive && 
            _cameraController != null && 
            _cameraController!.value.isInitialized)
          AspectRatio(
            aspectRatio: 1 / _cameraController!.value.aspectRatio,
            child: _boundingBoxes(),
          ),
        _cameraOffWidget(),
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _isCameraActive ? Colors.red : Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              onPressed: () async {
                if (_isCameraActive) {
                  await _turnOffCamera();
                  _ttsService.speak('Processing stopped. Double tap to start.');
                  _addChatEntry('Processing stopped. Double tap to start.', false);
                } else {
                  await _turnOnCamera();
                  _ttsService.speak('Processing started. Double tap to stop.');
                  _addChatEntry('Processing started. Double tap to stop.', false);
                }
              },
              child: Text(_isCameraActive ? 'Stop' : 'Start'),
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _cameraOffWidget() => !_isCameraActive
    ? const Center(
        child: Padding(
          padding: EdgeInsets.all(22.0),
          child: Text(
            'Camera turned off. Say "start" or press twice to begin.',
            style: TextStyle(
              color: Color.fromARGB(255, 208, 208, 208),
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      )
    : const SizedBox.shrink();

  /// Returns Stack of bounding boxes
  Widget _boundingBoxes() {
    if (results == null||results!.isEmpty||!_isCameraActive) {
      return const SizedBox.shrink();
    }
    return Stack(
        children: results!.map((box) => BoxWidget(result: box)).toList());
  }

  /// Callback to receive each frame [CameraImage] perform inference on it
  void onLatestImageAvailable(CameraImage cameraImage) async {
  final now = DateTime.now();
  if (now.difference(_lastFrameTime).inMilliseconds < _frameIntervalMs) {
    return; // skip this frame
  }
  _lastFrameTime = now;
  
  //debugPrint("Processing frame");
  _detector?.processFrame(cameraImage);
}

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.inactive:
        if (_cameraController?.value.isStreamingImages == true) {
          await _cameraController?.stopImageStream();
        }
        _detector?.stop();
        _subscription?.cancel();
        break;
      case AppLifecycleState.resumed:
        if (_cameraController == null || !_controller.value.isInitialized) {
          _initStateAsync(); // only reinitialize if actually needed
        }
        break;
      default:
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    _detector?.stop();
    _subscription?.cancel();
    super.dispose();
    _ttsService.dispose();
  }
}
