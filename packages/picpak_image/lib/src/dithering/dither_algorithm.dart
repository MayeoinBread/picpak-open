import 'package:image/image.dart' as img;
import '../pipeline/palette_framebuffer.dart';

abstract class DitherAlgorithm {
  String get name;

  PaletteFramebuffer apply(img.Image input);
}