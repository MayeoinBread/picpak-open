import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:picpak_image/picpak_image.dart';

import '../palette/palette_mapper.dart';
import '../pipeline/palette_framebuffer.dart';
import 'dither_engine.dart';

class OrderedDither implements DitherEngine {
  String get name => "Ordered";

  static const matrix = [
    [0, 8, 2, 10],
    [12, 4, 14, 6],
    [3, 11, 1, 9],
    [15, 7, 13, 5],
  ];

  @override
  PaletteFramebuffer apply(img.Image image, PaletteBias bias) {
    final output = PaletteFramebuffer(
      width: image.width,
      height: image.height,
      pixels: Uint8List(image.width * image.height),
    );

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);

        final threshold =
            (matrix[y % 4][x % 4] / 16.0 - 0.5) * 48.0;

        final r = (pixel.r + threshold).clamp(0, 255).toInt();
        final g = (pixel.g + threshold).clamp(0, 255).toInt();
        final b = (pixel.b + threshold).clamp(0, 255).toInt();

        final mapped = PaletteMapper.map(r, g, b, bias);

        output.setPixel(x, y, mapped);
      }
    }

    return output;
  }
}