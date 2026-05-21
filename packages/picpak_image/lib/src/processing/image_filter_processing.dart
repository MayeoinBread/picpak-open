import 'package:image/image.dart' as img;
import 'image_filter.dart';

class ImageFilterProcessor {
  static img.Image apply(
    img.Image input,
    ImageFilter filter,
  ) {
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
        }

        out.setPixelRgb(x, y, r, g, b);
      }
    }

    return out;
  }
}