import 'package:image/image.dart' as img;

import '../pipeline/palette_framebuffer.dart';

abstract class DitherEngine {
  PaletteFramebuffer apply(img.Image image);
}