import 'package:picpak_core/picpak_core.dart';

class PaletteFramebuffer {
  final int width;
  final int height;

  final List<PaletteIndex> pixels;

  PaletteFramebuffer({
    required this.width,
    required this.height,
    required this.pixels
  });

  PaletteIndex getPixel(int x, int y) {
    return pixels[y * width + x];
  }

  void setPixel(int x, int y, PaletteIndex value) {
    pixels[y * width + x] = value;
  }
}