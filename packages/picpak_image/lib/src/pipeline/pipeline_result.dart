import 'package:image/image.dart' as img;
import 'package:picpak_image/src/pipeline/palette_framebuffer.dart';

class PipelineResult {
  final PaletteFramebuffer framebuffer;
  final img.Image previewImage;

  PipelineResult({
    required this.framebuffer,
    required this.previewImage
  });
}