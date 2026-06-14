import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:picpak_core/picpak_core.dart';
import 'package:picpak_image/picpak_image.dart';

import '../palette/palette_mapper.dart';
import 'dither_engine.dart';

class SierraLiteDither implements DitherEngine {
  String get name => "Sierra Lite";

  @override
  PaletteFramebuffer apply(img.Image image, PaletteBias bias) {
    final width = image.width;
    final height = image.height;

    final r = List.generate(height, (_) => List<double>.filled(width, 0));
    final g = List.generate(height, (_) => List<double>.filled(width, 0));
    final b = List.generate(height, (_) => List<double>.filled(width, 0));

    for (int y=0; y<height; y++) {
      for(int x=0; x<width; x++) {
        final p = image.getPixel(x, y);

        r[y][x] = p.r.toDouble();
        g[y][x] = p.g.toDouble();
        b[y][x] = p.b.toDouble();
      }
    }

    final output = PaletteFramebuffer(
      width: width, height: height,
      pixels: Uint8List(width * height),
    );

    for (int y=0; y<height; y++) {
      for (int x=0; x<width; x++) {
        final oldR = r[y][x].clamp(0, 255).toInt();
        final oldG = g[y][x].clamp(0, 255).toInt();
        final oldB = b[y][x].clamp(0, 255).toInt();

        final mapped = PaletteMapper.map(oldR, oldG, oldB, bias);

        output.setPixel(x, y, mapped);

        final c = ProtocolPalette.all.firstWhere((e) => e.index == mapped);

        final errR = oldR - c.r;
        final errG = oldG - c.g;
        final errB = oldB - c.b;

        _spread(r, g, b, x+1, y, errR, errG, errB, 2 / 4, width, height);
        _spread(r, g, b, x-1, y+1, errR, errG, errB, 1 / 4, width, height);
        _spread(r, g, b, x, y+1, errR, errG, errB, 1 / 4, width, height);
      }
    }

    return output;
  }

  void _spread(
    List<List<double>> r,
    List<List<double>> g,
    List<List<double>> b,
    int x,
    int y,
    int errR,
    int errG,
    int errB,
    double factor,
    int width,
    int height
  ) {
    if (x < 0 || y < 0 || x >= width || y >= height) return;

    r[y][x] += errR * factor;
    g[y][x] += errG * factor;
    b[y][x] += errB * factor;
  }
}