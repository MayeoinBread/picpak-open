import 'dart:math' as math;

import 'package:image/image.dart' as img;

class ImageMetrics {
  final double minLuma;
  final double maxLuma;
  final double avgLuma;
  final double avgSaturation;

  const ImageMetrics({
    required this.minLuma,
    required this.maxLuma,
    required this.avgLuma,
    required this.avgSaturation
  });

  double get dynamicRange => maxLuma - minLuma;

  static ImageMetrics analyseImage(img.Image image) {
  double minLuma = 255;
  double maxLuma = 0;

  double totalLuma = 0;
  double totalSaturation = 0;

  int count = 0;

  for (int y = 0; y < image.height; y++) {
    for (int x = 0; x < image.width; x++) {
      final p = image.getPixel(x, y);

      final r = p.r.toDouble();
      final g = p.g.toDouble();
      final b = p.b.toDouble();

      final luma =
          0.299 * r +
          0.587 * g +
          0.114 * b;

      minLuma = math.min(minLuma, luma);
      maxLuma = math.max(maxLuma, luma);

      totalLuma += luma;

      final maxChannel = math.max(r, math.max(g, b));
      final minChannel = math.min(r, math.min(g, b));

      totalSaturation +=
          (maxChannel - minChannel) / 255.0;

      count++;
    }
  }

  return ImageMetrics(
    minLuma: minLuma,
    maxLuma: maxLuma,
    avgLuma: totalLuma / count,
    avgSaturation: totalSaturation / count,
  );
}
}