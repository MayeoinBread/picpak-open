import 'package:picpak_image/src/models/image_metrics.dart';

class ImageAdjustments {
  final double brightness;
  final double contrast;
  final double saturation;
  final double sharpen;

  // 0.5 -> subtle line art
  // 1.0 -> balanced comic
  // 1.5 -> strong ink style
  // 2.0 -> heavy stylisation
  final double comicStrength;

  // 0 -> pencil thin
  // 1 -> standard ink
  // 2 -> bold comic lines
  // 3 -> graphic poster style
  final double inkThickness;

  // 2 -> poster-like flat shading
  // 3 -> classic comic
  // 4-5 -> semi-realistic stylisation
  // 5-8 -> ???
  final double toneLevels;

  final double halftoneScale;
  final double hatchDensity;
  final double sketchStrength;

  const ImageAdjustments({
    this.brightness = 0.0,
    this.contrast = 1.0,
    this.saturation = 1.0,
    this.sharpen = 0.0,
    this.comicStrength = 1.0,
    this.inkThickness = 0.0,
    this.toneLevels = 2.0,
    this.halftoneScale = 6,
    this.hatchDensity = 8.0,
    this.sketchStrength = 1.0
  });

  ImageAdjustments copyWith({
    double? brightness,
    double? contrast,
    double? saturation,
    double? sharpen,
    double? comicStrength,
    double? inkThickness,
    double? toneLevels,
    double? halftoneScale,
    double? hatchDensity,
    double? sketchStrength
  }) {
    return ImageAdjustments(
      brightness: brightness ?? this.brightness,
      contrast: contrast ?? this.contrast,
      saturation: saturation ?? this.saturation,
      sharpen: sharpen ?? this.sharpen,
      comicStrength: comicStrength ?? this.comicStrength,
      inkThickness: inkThickness ?? this.inkThickness,
      toneLevels: toneLevels ?? this.toneLevels,
      halftoneScale: halftoneScale ?? this.halftoneScale,
      hatchDensity: hatchDensity ?? this.hatchDensity,
      sketchStrength: sketchStrength ?? this.sketchStrength
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

    return ImageAdjustments(
      brightness: brightness,
      contrast: contrast,
      saturation: saturation,
      sharpen: sharpen,
    );
  }
}