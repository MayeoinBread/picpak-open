import 'dart:ui';

import 'package:image/image.dart' as img;
import 'image_filter.dart';

class ImageFilterProcessor {
  static img.Image apply(
    img.Image input,
    ImageFilter filter,
  ) {
    switch (filter) {
      case ImageFilter.posterise:
        return _posterise(input);

      case ImageFilter.comic:
        return _comic(input);
      
      default:
        return _perPixelFilter(input, filter);
    }
  }

  static img.Image _perPixelFilter(img.Image input, ImageFilter filter) {
    final out = img.Image.from(input);

    for (int y = 0; y < out.height; y++) {
      for (int x = 0; x < out.width; x++) {
        final p = out.getPixel(x, y);

        int r = p.r.toInt();
        int g = p.g.toInt();
        int b = p.b.toInt();

        switch (filter) {
          case ImageFilter.normal:
            break;

          case ImageFilter.vibrant:
            r = (r * 1.25).clamp(0, 255).toInt();
            g = (g * 1.25).clamp(0, 255).toInt();
            b = (b * 1.25).clamp(0, 255).toInt();
            break;

          case ImageFilter.grayscale:
            final l = ((r + g + b) / 3).round();
            r = g = b = l;
            break;

          case ImageFilter.highContrast:
            final l = ((r + g + b) / 3).round();
            final v = l > 128 ? 255 : 0;
            r = g = b = v;
            break;
          
          default:
            break;
        }

        out.setPixelRgb(x, y, r, g, b);
      }
    }

    return out;
  }

  static img.Image _posterise(img.Image input) {
    final out = img.Image.from(input);

    const levels = 4;
    const step = 255 ~/ (levels - 1);

    for (int y=0; y<out.height; y++) {
      for (int x=0; x<out.width; x++) {
        final p = out.getPixel(x, y);

        int r = ((p.r / step).round() * step).clamp(0, 255).toInt();
        int g = ((p.g / step).round() * step).clamp(0, 255).toInt();
        int b = ((p.b / step).round() * step).clamp(0, 255).toInt();

        out.setPixelRgb(x, y, r, g, b);
      }
    }

    return out;
  }

  static img.Image _comic(img.Image input) {
    final base = _posterise(input);

    // final edges = img.sobel(input); // IMPORTANT: use original, not posterized
    final edges = img.sobel(img.grayscale(input));

    final out = img.Image.from(base);

    const edgeThreshold = 150;

    for (int y = 0; y < out.height; y++) {
      for (int x = 0; x < out.width; x++) {
        final p = base.getPixel(x, y);
        final e = edges.getPixel(x, y);

        // FIX: proper luminance of edge response
        final edge =
            (0.299 * e.r +
            0.587 * e.g +
            0.114 * e.b);

        int r = p.r.toInt();
        int g = p.g.toInt();
        int b = p.b.toInt();

        if (edge > edgeThreshold) {
          // ink line
          r = 0;
          g = 0;
          b = 0;
        }

        out.setPixelRgb(x, y, r, g, b);
      }
    }

    return out;
  }
}