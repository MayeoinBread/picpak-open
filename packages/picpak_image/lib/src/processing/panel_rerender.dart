import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:picpak_core/src/palette/protocol_palette.dart';
import 'package:picpak_image/src/pipeline/palette_framebuffer.dart';

class PanelRerender {
  static img.Image renderFramebuffer(PaletteFramebuffer fb) {
    final imgOut = img.Image(width: fb.width, height: fb.height);

    for (int y = 0; y < fb.height; y++) {
      for (int x = 0; x < fb.width; x++) {
        // if (i >= data.length) break;

        // final byte = data[i++];

        // final p0 = (byte >> 6) & 0x03;
        // final p1 = (byte >> 4) & 0x03;
        // final p2 = (byte >> 2) & 0x03;
        // final p3 = byte & 0x03;

        // _setPixel(imgOut, x + 0, y, p0);
        // _setPixel(imgOut, x + 1, y, p1);
        // _setPixel(imgOut, x + 2, y, p2);
        // _setPixel(imgOut, x + 3, y, p3);
        final index = (y * fb.width + x);
        final colourIndex = fb.pixels[index];
        final colour = ProtocolPalette.all[colourIndex];

        imgOut.setPixelRgb(x, y, colour.r, colour.g, colour.b);
      }
    }

    return imgOut;
  }

  static void _setPixel(img.Image image, int x, int y, int index) {
    final c = ProtocolPalette.paletteFromIndex(index);

    image.setPixelRgb(x, y, c.r, c.g, c.b);
  }
}