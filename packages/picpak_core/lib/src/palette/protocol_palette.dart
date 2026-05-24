import 'package:picpak_core/picpak_core.dart';

class ProtocolPaletteColour {
  final PaletteIndex index;
  final int r;
  final int g;
  final int b;

  const ProtocolPaletteColour({
    required this.index,
    required this.r,
    required this.g,
    required this.b
  });
}

class ProtocolPalette {
  static const black = ProtocolPaletteColour(
    index: PaletteIndex.black,
    r: 0,
    g: 0,
    b: 0
  );

  static const white = ProtocolPaletteColour(
    index: PaletteIndex.white,
    r: 255,
    g: 255,
    b: 255
  );

  static const yellow = ProtocolPaletteColour(
    index: PaletteIndex.yellow,
    r: 255,
    g: 255,
    b: 0
  );

  static const red = ProtocolPaletteColour(
    index: PaletteIndex.red,
    r: 255,
    g: 0,
    b: 0
  );

  static const all = [
    black, white, yellow, red
  ];

  static ProtocolPaletteColour paletteFromIndex(int i) {
    switch(i) {
      case 0:
        return ProtocolPalette.black;
      case 1:
        return ProtocolPalette.white;
      case 2:
        return ProtocolPalette.yellow;
      case 3:
        return ProtocolPalette.red;
      default:
        return ProtocolPalette.black;
    }
  }
}