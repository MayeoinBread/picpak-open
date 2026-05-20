import 'package:picpak_core/picpak_core.dart';

class PaletteMapper {
  static PaletteIndex map(int r, g, b) {
    ProtocolPaletteColour best = ProtocolPalette.all.first;
    int bestDist = _dist(r, g, b, best);

    for (final c in ProtocolPalette.all.skip(1)) {
      final d = _dist(r, g, b, c);

      if (d < bestDist) {
        bestDist = d;
        best = c;
      }
    }

    return best.index;
  }

  static int _dist(int r, int g, int b, ProtocolPaletteColour c) {
    final dr = r - c.r;
    final dg = g - c.g;
    final db = b - c.b;

    return dr * dr + dg * dg + db * db;
  }
}