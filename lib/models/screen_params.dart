import 'dart:math';
import 'dart:ui';

/// Singleton to record size related data
class ScreenParams {
  static late Size screenSize;
  static late Size previewSize;

  static double get previewRatio => max(previewSize.height, previewSize.width) /
      min(previewSize.height, previewSize.width);

  static Size get screenPreviewSize =>
      Size(screenSize.width, screenSize.width * previewRatio);
}
