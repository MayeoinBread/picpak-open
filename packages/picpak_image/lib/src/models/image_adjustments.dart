class ImageAdjustments {
  final double brightness;
  final double contrast;

  const ImageAdjustments({
    required this.brightness,
    required this.contrast
  });

  ImageAdjustments copyWith({
    double? brightness,
    double? contrast
  }) {
    return ImageAdjustments(
      brightness: brightness ?? this.brightness,
      contrast: contrast ?? this.contrast
    );
  }
}