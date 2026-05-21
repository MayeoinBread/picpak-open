import 'package:image/image.dart' as img;
import 'image_adjustments.dart';

class ImageAdjustmentProcessor {
  static img.Image apply(img.Image src, ImageAdjustments adj) {
    if (adj.brightness == 0.0 && adj.contrast == 1.0) {
      return src;
    }

    final out = img.Image.from(src);

    for (int y = 0; y < out.height; y++) {
      for (int x = 0; x < out.width; x++) {
        final p = out.getPixel(x, y);

        int r = p.r.toInt();
        int g = p.g.toInt();
        int b = p.b.toInt();

        // brightness
        r = (r + (adj.brightness * 255)).toInt();
        g = (g + (adj.brightness * 255)).toInt();
        b = (b + (adj.brightness * 255)).toInt();

        // contrast
        r = (((r - 127.5) * adj.contrast) + 127.5).toInt();
        g = (((g - 127.5) * adj.contrast) + 127.5).toInt();
        b = (((b - 127.5) * adj.contrast) + 127.5).toInt();

        r = r.clamp(0, 255);
        g = g.clamp(0, 255);
        b = b.clamp(0, 255);

        out.setPixelRgb(x, y, r, g, b);
      }
    }

    return out;
  }
}