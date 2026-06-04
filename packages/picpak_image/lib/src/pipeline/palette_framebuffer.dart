import 'dart:typed_data';

import 'package:picpak_core/picpak_core.dart';

class PaletteFramebuffer {
  final int width;
  final int height;

  final Uint8List pixels;

  PaletteFramebuffer({
    required this.width,
    required this.height,
    required this.pixels
  });

  PaletteIndex getPixel(int x, int y) {
    // return pixels[y * width + x];
    return PaletteIndex.values[pixels[y * width + x]];
  }

  void setPixel(int x, int y, PaletteIndex value) {
    pixels[y * width + x] = value.index;
  }

  static PaletteFramebuffer empty() {
    return PaletteFramebuffer(width: 400, height: 300, pixels: Uint8List(300*400));
  }

  static PaletteFramebuffer downscale(PaletteFramebuffer fb, int targetW, int targetH) {
    final out = Uint8List(targetW * targetH);
    for (int y = 0; y < targetH; y++) {
      for (int x = 0; x < targetW; x++) {

        final srcX = (x * fb.width) ~/ targetW;
        final srcY = (y * fb.height) ~/ targetH;

        final srcIndex = srcY * fb.width + srcX;
        out[y * targetW + x] = fb.pixels[srcIndex];
      }
    }

    return PaletteFramebuffer(
      width: targetW,
      height: targetH,
      pixels: out,
    );
  }
}