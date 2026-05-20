import 'package:image/image.dart' as img;
import 'package:picpak_core/picpak_core.dart';

import 'palette_framebuffer.dart';

class FramebufferPreviewRenderer {
  static img.Image render(
    PaletteFramebuffer fb, {
    required bool simulateDevice}) {
    final output = img.Image(
      width: fb.width,
      height: fb.height
    );

    for (int y=0; y<fb.height; y++) {
      for (int x=0; x<fb.width; x++) {
        final pixel = fb.getPixel(x, y);

        final colour = simulateDevice
          ? DevicePalette.colours[pixel]!
          : _applyPreviewStyle(pixel);

        output.setPixelRgb(x, y, colour.$1, colour.$2, colour.$3);
      }
    }

    return output;
  }

  static (int, int, int) _applyPreviewStyle(
    PaletteIndex p
  ) {
    switch (p) {
      case PaletteIndex.black:
        return (0, 0, 0);
      case PaletteIndex.white:
        return (255, 255, 255);
      case PaletteIndex.yellow:
        return (255, 255, 0);
      case PaletteIndex.red:
        return (255, 0, 0);
    }
  }
}