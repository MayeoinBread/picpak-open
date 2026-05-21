class ImageAdjustments {
  final double brightness;  // -1.0 to +1.0
  final double contrast;    // 0.0 to 2.0 (1.0 = no change)

  const ImageAdjustments({
    this.brightness = 0.0,
    this.contrast = 1.0
  });
}