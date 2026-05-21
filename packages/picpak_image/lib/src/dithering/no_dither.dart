import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:picpak_image/src/dithering/dither_engine.dart';

import '../palette/palette_mapper.dart';
import '../pipeline/palette_framebuffer.dart';

class NoDither implements DitherEngine {
  String get name => "None";
  
  @override
  PaletteFramebuffer apply(img.Image image) {
    final output = PaletteFramebuffer(
      width: image.width,
      height: image.height,
      pixels: Uint8List(image.width * image.height),
    );

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);

        final mapped = PaletteMapper.map(
          pixel.r.toInt(),
          pixel.g.toInt(),
          pixel.b.toInt(),
        );

        output.setPixel(x, y, mapped);
      }
    }

    return output;
  }
}