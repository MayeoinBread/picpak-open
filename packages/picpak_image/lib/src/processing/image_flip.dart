import 'dart:typed_data';

import 'package:picpak_image/src/pipeline/palette_framebuffer.dart';

PaletteFramebuffer flipVertical(PaletteFramebuffer fb) {
  final width = fb.width;
  final height = fb.height;

  final flipped = Uint8List(width * height);

  for (int y=0; y<height; y++) {
    final srcRow = y * width;
    final dstRow = (height - 1 - y) * width;

    for (int x=0; x<width; x++) {
      flipped[dstRow + x] = fb.pixels[srcRow + x];
    }
  }

  return PaletteFramebuffer(width: width, height: height, pixels: flipped);
}