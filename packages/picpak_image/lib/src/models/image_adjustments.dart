import 'package:flutter/foundation.dart';
import 'package:picpak_image/src/models/image_metrics.dart';

class ImageAdjustments {
  final double brightness;
  final double contrast;
  final double saturation;
  final double sharpen;

  const ImageAdjustments({
    this.brightness = 0.0,
    this.contrast = 1.0,
    this.saturation = 1.0,
    this.sharpen = 0.0
  });

  ImageAdjustments copyWith({
    double? brightness,
    double? contrast,
    double? saturation,
    double? sharpen
  }) {
    return ImageAdjustments(
      brightness: brightness ?? this.brightness,
      contrast: contrast ?? this.contrast,
      saturation: saturation ?? this.saturation,
      sharpen: sharpen ?? this.sharpen
    );
  }

  static ImageAdjustments autoEnhance(
    ImageMetrics metrics,
  ) {
    final range = metrics.dynamicRange;

    double contrast = 1.0;

    if (range < 180) contrast = 1.1;
    if (range < 140) contrast = 1.2;
    if (range < 100) contrast = 1.3;
    if (range < 70) contrast = 1.4;

    final brightness =
        ((128 - metrics.avgLuma) / 128)
            .clamp(-1.0, 1.0);

    double saturation = 1.0;

    if (metrics.avgSaturation < 0.40) {
      saturation = 1.10;
    }

    if (metrics.avgSaturation < 0.30) {
      saturation = 1.20;
    }

    if (metrics.avgSaturation < 0.20) {
      saturation = 1.35;
    }

    double sharpen = 0.5;

    if (range < 100) {
      sharpen = 0.75;
    }

    debugPrint(
      '''
      Dynamic Range: ${metrics.dynamicRange}
      Average Luma: ${metrics.avgLuma}
      Average Saturation: ${metrics.avgSaturation}
      '''
    );

    return ImageAdjustments(
      brightness: brightness,
      contrast: contrast,
      saturation: saturation,
      sharpen: sharpen,
    );
  }
}