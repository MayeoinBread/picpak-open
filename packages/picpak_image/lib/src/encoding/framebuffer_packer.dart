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

        int value = 0;

        if (pixelIndex < totalPixels) {
          value = fb.pixels[pixelIndex];
        }

        byte |= (value << (6 - (j * 2)));
      }

      output.addByte(byte);
    }

    return output.toBytes();
  }
}