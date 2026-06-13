import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:picpak_core/picpak_core.dart';
import 'package:picpak_image/picpak_image.dart';

import '../palette/palette_mapper.dart';
import 'dither_engine.dart';

class SierraDither implements DitherEngine {
  String get name => "Sierra Lite";

  @override
  PaletteFramebuffer apply(img.Image image, PaletteBias bias) {
    final working = img.Image.from(image);

    final output = PaletteFramebuffer(
      width: image.width,
      height: image.height,
      pixels: Uint8List(image.width * image.height),
    );

    for (int y = 0; y < working.height; y++) {
      for (int x = 0; x < working.width; x++) {
        final oldPixel = working.getPixel(x, y);

        final mapped = PaletteMapper.map(
          oldPixel.r.toInt(),
          oldPixel.g.toInt(),
          oldPixel.b.toInt(),
          bias
        );

        output.setPixel(x, y, mapped);

        final paletteColour = ProtocolPalette.all.firstWhere(
          (c) => c.index == mapped
        );

        final errR = oldPixel.r.toInt() - paletteColour.r;
        final errG = oldPixel.g.toInt() - paletteColour.g;
        final errB = oldPixel.b.toInt() - paletteColour.b;

        _distribute(
          working,
          x + 1,
          y,
          errR,
          errG,
          errB,
          2 / 4,
        );

        _distribute(
          working,
          x - 1,
          y + 1,
          errR,
          errG,
          errB,
          1 / 4,
        );

        _distribute(
          working,
          x,
          y + 1,
          errR,
          errG,
          errB,
          1 / 4,
        );
      }
    }

    return output;
  }

  void _distribute(
    img.Image image,
    int x,
    int y,
    int errR,
    int errG,
    int errB,
    double factor,
  ) {
    if (x < 0 || y < 0 || x >= image.width || y >= image.height) {
      return;
    }

    final pixel = image.getPixel(x, y);

    final r = (pixel.r + errR * factor)
        .clamp(0, 255)
        .toInt();

    final g = (pixel.g + errG * factor)
        .clamp(0, 255)
        .toInt();

    final b = (pixel.b + errB * factor)
        .clamp(0, 255)
        .toInt();

    image.setPixelRgb(x, y, r, g, b);
  }
}