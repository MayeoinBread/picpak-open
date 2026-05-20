import 'package:image/image.dart' as img;
import 'package:picpak_core/picpak_core.dart';
import 'package:picpak_core/src/palette/protocol_palette.dart';
import 'package:picpak_image/src/pipeline/palette_framebuffer.dart';
import '../palette/palette_mapper.dart';
import 'dither_algorithm.dart';

class AtkinsonDither implements DitherAlgorithm {
  @override
  String get name => "Atkinson";

  @override
  PaletteFramebuffer apply(img.Image input) {
    final width = input.width;
    final height = input.height;

    final r = List.generate(height, (_) => List<double>.filled(width, 0));
    final g = List.generate(height, (_) => List<double>.filled(width, 0));
    final b = List.generate(height, (_) => List<double>.filled(width, 0));

    // copy input into float buffers
    for (int y=0; y<height; y++) {
      for (int x=0; x<width; x++) {
        final p = input.getPixel(x, y);
        r[y][x] = p.r.toDouble();
        g[y][x] = p.g.toDouble();
        b[y][x] = p.b.toDouble();
      }
    }

    final output = PaletteFramebuffer(width: width, height: height, pixels: List.filled(width * height, PaletteIndex.black));

    for (int y=0; y<height; y++) {
      for (int x=0; x<width; x++) {
        final oldR = r[y][x].clamp(0, 255).toInt();
        final oldG = g[y][x].clamp(0, 255).toInt();
        final oldB = b[y][x].clamp(0, 255).toInt();

        final mapped = PaletteMapper.map(oldR, oldG, oldB);

        final paletteColour = ProtocolPalette.all.firstWhere(
          (c) => c.index == mapped
        );

        output.setPixel(x, y, mapped);

        final errR = (oldR - paletteColour.r) / 8.0;
        final errG = (oldG - paletteColour.g) / 8.0;
        final errB = (oldB - paletteColour.b) / 8.0;

        _distributed(r, g, b, x + 1, y,     errR, errG, errB, width, height);
        _distributed(r, g, b, x + 2, y,     errR, errG, errB, width, height);

        _distributed(r, g, b, x - 1, y + 1, errR, errG, errB, width, height);
        _distributed(r, g, b, x,     y + 1, errR, errG, errB, width, height);
        _distributed(r, g, b, x + 1, y + 1, errR, errG, errB, width, height);

        _distributed(r, g, b, x,     y + 2, errR, errG, errB, width, height);
      }
    }

    return output;
  }

  void _distributed(
    List<List<double>> r,
    List<List<double>> g,
    List<List<double>> b,
    int x, int y,
    double errR, double errG, double errB,
    int width, int height
  ) {
    if (x < 0 || x >= width || y < 0 || y >= height) return;

    r[y][x] += errR;
    g[y][x] += errG;
    b[y][x] += errB;
  }
}