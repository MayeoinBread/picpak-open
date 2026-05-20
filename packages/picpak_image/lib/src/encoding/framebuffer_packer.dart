import 'dart:typed_data';

import 'package:picpak_core/picpak_core.dart';
import 'package:picpak_image/src/pipeline/palette_framebuffer.dart';

class FramebufferPacker {
  static Uint8List pack(PaletteFramebuffer fb) {
    final output = BytesBuilder();

    final totalPixels = fb.width * fb.height;

    for (int i=0; i<totalPixels; i+=4) {
      int byte = 0;

      for (int j=0; j<4; j++) {
        final pixelIndex = i + j;

        PaletteIndex pixel = PaletteIndex.black;

        if (pixelIndex < totalPixels) {
          pixel = fb.pixels[pixelIndex];
        }

        final value = _paletteToBits(pixel);

        byte |= (value << (6 - (j * 2)));
      }

      output.addByte(byte);
    }

    return output.toBytes();
  }

  static int _paletteToBits(PaletteIndex index) {
    switch (index) {
      case PaletteIndex.black:
        return 0;
      case PaletteIndex.white:
        return 1;
      case PaletteIndex.yellow:
        return 2;
      case PaletteIndex.red:
        return 3;
    }
  }
}