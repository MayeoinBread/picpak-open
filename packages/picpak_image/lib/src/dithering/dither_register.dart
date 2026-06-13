import 'package:picpak_image/src/dithering/burkes_dither.dart';
import 'package:picpak_image/src/dithering/jjn_dither.dart';
import 'package:picpak_image/src/dithering/stucki_dither.dart';

import 'atkinson_dither.dart';
import 'dither_engine.dart';
import 'dither_mode.dart';
import 'floyd_steinberg_dither.dart';
import 'no_dither.dart';
import 'ordered_dither.dart';
import 'sierra_dither.dart';

class DitherRegistry {
  static DitherEngine create(DitherMode mode) {
    return switch (mode) {
      DitherMode.none =>
        NoDither(),

      DitherMode.ordered =>
        OrderedDither(),

      DitherMode.floydSteinberg =>
        FloydSteinbergDither(),

      DitherMode.atkinson =>
        AtkinsonDither(),

      DitherMode.sierra =>
        SierraDither(),
      
      DitherMode.burkes =>
        BurkesDither(),

      DitherMode.jjn =>
        JjnDither(),
      
      DitherMode.stucki =>
        StuckiDither()
    };
  }
}