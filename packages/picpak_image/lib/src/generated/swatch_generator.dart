import 'package:image/image.dart' as img;

enum SwatchType {
  gradientHorizontal,
  gradientVertical,
  checkerboard,
  stripes,
  colourBlocks,
  noise,
  textEdges,
  rgbSpectrum,
  warmRamp,
  impossibleColours
}

class SwatchGenerator {
  static img.Image generate(
    SwatchType type, {
      required int width,
      required int height
    }
  ) {
    return switch(type) {
      SwatchType.gradientHorizontal => _gradientHorizontal(width, height),
      SwatchType.gradientVertical => _gradientVertical(width, height),
      SwatchType.checkerboard => _checkerboard(width, height),
      SwatchType.stripes => _stripes(width, height),
      SwatchType.colourBlocks => _colourBlocks(width, height),
      SwatchType.noise => _noise(width, height),
      SwatchType.textEdges => _textEdges(width, height),
      SwatchType.rgbSpectrum => _rgbSpectrum(width, height),
      SwatchType.warmRamp => _warmRamp(width, height),
      SwatchType.impossibleColours => _impossibleColours(width, height)
    };
  }

  static img.Image _gradientHorizontal(int w, int h) {
    final image = img.Image(width: w, height: h);

    for (int y=0; y<h; y++) {
      for (int x=0; x<w; x++) {
        final t = x / (w - 1);

        final r = (255 * t).toInt();
        final g = (255 * t).toInt();
        final b = (255 * t).toInt();

        image.setPixelRgb(x, y, r, g, b);
      }
    }

    return image;
  }

  static img.Image _gradientVertical(int w, int h) {
    final image = img.Image(width: w, height: h);

    for (int y=0; y<h; y++) {
      final t = y / (h-1);
      final v = (255 * t).toInt();

      for (int x=0; x<w; x++) {
        image.setPixelRgb(x, y, v, v, v);
      }
    }

    return image;
  }

  static img.Image _checkerboard(int w, int h) {
    final image = img.Image(width: w, height: h);

    const size = 10;

    for (int y=0; y<h; y++) {
      for (int x=0; x<w; x++) {
        final on = ((x ~/ size) + (y ~/ size)) % 2 == 0;

        final c = on ? 255 : 0;
        image.setPixelRgb(x, y, c, c, c);
      }
    }

    return image;
  }

  static img.Image _colourBlocks(int w, int h) {
    final image = img.Image(width: w, height: h);

    final colours = [
      (0, 0, 0), (255, 255, 255), (255, 0, 0), (255, 255, 0)
    ];

    final bw = w ~/ 2;
    final bh = h ~/ 2;

    for (int i=0; i<colours.length; i++) {
      final cx = (i%2) * bw;
      final cy = (i~/2) * bh;

      final (r, g, b) = colours[i];

      for (int y=cy; y<cy+bh; y++) {
        for (int x=cx; x<cx+bw; x++) {
          image.setPixelRgb(x, y, r, g, b);
        }
      }
    }

    return image;
  }

  static img.Image _noise(int w, int h) {
    final image = img.Image(width: w, height: h);
    final rng = DateTime.now().millisecondsSinceEpoch;

    int seed = rng;

    int next() {
      seed = (seed * 1664525 + 1013904223) & 0xFFFFFFFF;
      return seed;
    }

    for (int y=0; y<h; y++) {
      for (int x=0; x<w; x++) {
        final v = next() % 256;
        image.setPixelRgb(x, y, v, v, v);
      }
    }

    return image;
  }

  static img.Image _stripes(int w, int h) {
    final image = img.Image(width: w, height: h);

    for (int y=0; y<h; y++) {
      final on = (y ~/ 2) % 2 == 0;
      final v = on ? 255 : 0;

      for (int x=0; x<w; x++) {
        image.setPixelRgb(x, y, v, v, v);
      }
    }

    return image;
  }

  static img.Image _textEdges(int w, int h) {
    final image = img.Image(width: w, height: h);

    img.fill(image, color: img.ColorRgb8(255, 255, 255));

    // simple synthetic "edge blocks"
    for (int i=0; i<w; i+=10) {
      for (int j=0; j<h; j+=10) {
        image.setPixelRgb(i, j, 0, 0, 0);
      }
    }

    return image;
  }

  static img.Image _rgbSpectrum(int w, int h) {
    final image = img.Image(width: w, height: h);

    for (int y=0; y<h; y++) {
      for (int x=0; x<w; x++) {
        final hue = (x / w) * 360.0;

        List<num> rgb = [0, 0, 0];
        img.hsvToRgb(hue, 1.0, 1.0, rgb);

        image.setPixelRgb(x, y, rgb[0] * 255, rgb[1] * 255, rgb[2] * 255);
      }
    }

    return image;
  }

  static img.Image _warmRamp(int w, int h) {
    final image = img.Image(width: w, height: h);

    for (int y=0; y<h; y++) {
      for (int x=0; x<w; x++) {
        final t = x / (w - 1);

        final r = 255;
        final g = (255 * t).toInt();
        final b = 0;

        image.setPixelRgb(x, y, r, g, b);
      }
    }

    return image;
  }

  static img.Image _impossibleColours(int w, int h) {
    final image = img.Image(width: w, height: h);

    final colours = [
      (0, 255, 255),   // cyan
      (255, 0, 255),   // magenta
      (0, 0, 255),     // blue
      (0, 255, 0),     // green
      (128, 0, 255),   // purple
      (0, 128, 255),   // sky blue
    ];

    const cols = 3;
    final rows = (colours.length / cols).ceil();

    final cellW = w ~/ cols;
    final cellH = h ~/ rows;

    for (int i = 0; i < colours.length; i++) {
      final col = i % cols;
      final row = i ~/ cols;

      final startX = col * cellW;
      final startY = row * cellH;

      final (r, g, b) = colours[i];

      for (int y = startY; y < startY + cellH; y++) {
        for (int x = startX; x < startX + cellW; x++) {
          image.setPixelRgb(x, y, r, g, b);
        }
      }
    }

    return image;
  }
}