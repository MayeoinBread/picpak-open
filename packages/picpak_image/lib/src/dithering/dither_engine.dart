import 'package:image/image.dart' as img;
import 'package:picpak_image/picpak_image.dart';

abstract class DitherEngine {
  PaletteFramebuffer apply(img.Image image, PaletteBias bias);
}