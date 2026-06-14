import 'dart:math' as math;
import 'dart:ui';

import 'package:image/image.dart' as img;
import 'package:picpak_image/picpak_image.dart';

class ImageFilterProcessor {
  static img.Image apply(
    img.Image input,
    ImageFilter filter,
    ImageAdjustments adjustments
  ) {
    switch (filter) {
      case ImageFilter.posterise:
        return _posterise(input, adjustments);

      case ImageFilter.comic:
        return _comic(input, adjustments);
      
      case ImageFilter.halftone:
        return _halftone(input, adjustments.halftoneScale);

      case ImageFilter.crossHatch:
        return _crossHatch(input, adjustments.hatchDensity);
      
      case ImageFilter.pencilSketch:
        return _pencilSketch(input, adjustments.sketchStrength);
      
      default:
        return _perPixelFilter(input, filter);
    }
  }

  static img.Image _pencilSketch(
    img.Image input, double strength
  ) {
    final width = input.width;
    final height = input.height;

    final out = img.Image.from(input);

    // grayscale buffer
    final gray = List.generate(
      height,
      (_) => List<double>.filled(width, 0),
    );

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final p = input.getPixel(x, y);
        gray[y][x] = (0.299 * p.r + 0.587 * p.g + 0.114 * p.b);
      }
    }

    int clampi(double v) => v.clamp(0, 255).toInt();

    for (int y = 1; y < height - 1; y++) {
      for (int x = 1; x < width - 1; x++) {
        final gx =
            -gray[y - 1][x - 1] -
            2 * gray[y][x - 1] -
            gray[y + 1][x - 1] +
            gray[y - 1][x + 1] +
            2 * gray[y][x + 1] +
            gray[y + 1][x + 1];

        final gy =
            -gray[y - 1][x - 1] -
            2 * gray[y - 1][x] -
            gray[y - 1][x + 1] +
            gray[y + 1][x - 1] +
            2 * gray[y + 1][x] +
            gray[y + 1][x + 1];

        final magnitude = math.sqrt(gx * gx + gy * gy);

        // edge strength
        double edge = magnitude / 255.0;
        edge = (edge * strength).clamp(0.0, 1.0);

        // invert: edges become dark pencil strokes
        final base = gray[y][x];

        final sketch = 255 - (edge * 255);

        // blend base + sketch
        final finalVal = (base * 0.4 + sketch * 0.6);

        final v = clampi(finalVal);

        out.setPixelRgb(x, y, v, v, v);
      }
    }

    return out;
  }

  static img.Image _crossHatch(img.Image input, double density) {
    final out = img.Image.from(input);

    final width = out.width;
    final height = out.height;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final p = out.getPixel(x, y);

        final r = p.r.toDouble();
        final g = p.g.toDouble();
        final b = p.b.toDouble();

        final lum = (0.299 * r + 0.587 * g + 0.114 * b);

        // normalize 0..1
        final l = lum / 255.0;

        // base thresholds
        final t1 = 0.25;
        final t2 = 0.5;
        final t3 = 0.75;

        int value = 255;

        // basic tone bands
        if (l < t3) {
          // diagonal hatch /
          if (((x + y) % (density.round())) == 0) {
            value = 0;
          }
        }

        if (l < t2) {
          // opposite hatch \
          if (((x - y) % (density.round())) == 0) {
            value = 0;
          }
        }

        if (l < t1) {
          // dense cross hatch
          if (x % (density ~/ 2 == 0 ? 1 : density ~/ 2) == 0 &&
              y % (density ~/ 2 == 0 ? 1 : density ~/ 2) == 0) {
            value = 0;
          }
        }

        out.setPixelRgb(x, y, value, value, value);
      }
    }

    return out;
  }

  static img.Image _halftone(img.Image input, double density) {
    final out = img.Image.from(input);

    final width = out.width;
    final height = out.height;

    for (int y=0; y<height; y++) {
      for (int x=0; x<width; x++) {
        final p = out.getPixel(x, y);

        final r = p.r.toDouble();
        final g = p.g.toDouble();
        final b = p.b.toDouble();

        final luminance = (0.299 * r + 0.587 * g + 0.114 * b) / 255.0;

        // invert so dark = bigger dots
        final intensity = 1.0 - luminance;

        // cell coordinates
        final cx = (x / density).floor();
        final cy = (y / density).floor();

        final fx = (x / density) - cx;
        final fy = (y / density) - cy;

        // simple dot pattern (center-based)
        final dx = fx - 0.5;
        final dy = fy - 0.5;

        final dist = dx * dx + dy * dy;

        // threshold radius based on brightness
        final radius = intensity * 0.25;

        final isDot = dist < radius * radius;

        int value;
        if (isDot) {
          value = 0;
        } else {
          value = 255;
        }

        out.setPixelRgb(x, y, value, value, value);
      }
    }

    return out;
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

  static img.Image _posterise(img.Image input, ImageAdjustments adj) {
    final out = img.Image.from(input);

    // const levels = 4;
    final levels = adj.toneLevels.round().clamp(2, 8);
    final step = 255 ~/ (levels - 1);

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

  static img.Image _comic(img.Image input, ImageAdjustments adj) {
    final base = _posterise(input, adj);

    final blurred = img.gaussianBlur(
      img.grayscale(input),
      radius: 1,
    );

    final edges = img.sobel(blurred);

    final out = img.Image.from(base);

    // final threshold = lerpDouble(140, 60, adj.comicStrength)!;
    final threshold = adj.comicStrength == 1.0
      ? 90.0
      : lerpDouble(140, 60, adj.comicStrength)!;

    final thickness = adj.inkThickness.round().clamp(0, 3);

    for (int y = 0; y < out.height; y++) {
      for (int x = 0; x < out.width; x++) {
        final p = base.getPixel(x, y);
        final e = edges.getPixel(x, y);

        final edge =
            0.299 * e.r +
            0.587 * e.g +
            0.114 * e.b;

        if (edge > threshold) {
          if (thickness > 0) {
            _drawInk(out, x, y, thickness);
          } else {
            out.setPixelRgb(x, y, 0, 0, 0);
          }
        } else {
          out.setPixelRgb(
            x,
            y,
            p.r.toInt(),
            p.g.toInt(),
            p.b.toInt(),
          );
        }
      }
    }

    if (adj.toneLevels <= 1) return out;
    return _applyToon(out, adj.toneLevels);
  }

  static void _drawInk(img.Image img, int x, int y, int t) {
    for (int dy = -t; dy <= t; dy++) {
      for (int dx = -t; dx <= t; dx++) {
        final nx = x + dx;
        final ny = y + dy;

        if (nx < 0 ||
            ny < 0 ||
            nx >= img.width ||
            ny >= img.height) continue;

        img.setPixelRgb(nx, ny, 0, 0, 0);
      }
    }
  }

  static img.Image _applyToon(img.Image input, double levels) {
    final out = img.Image.from(input);

    final bands = levels.round().clamp(2, 8);
    final step = 255 / (bands - 1);

    for (int y = 0; y < out.height; y++) {
      for (int x = 0; x < out.width; x++) {
        final p = out.getPixel(x, y);

        int r = ((p.r / step).round() * step).clamp(0, 255).toInt();
        int g = ((p.g / step).round() * step).clamp(0, 255).toInt();
        int b = ((p.b / step).round() * step).clamp(0, 255).toInt();

        out.setPixelRgb(x, y, r, g, b);
      }
    }

    return out;
  }
}