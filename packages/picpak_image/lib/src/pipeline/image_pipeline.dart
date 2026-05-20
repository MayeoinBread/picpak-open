import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:picpak_core/picpak_core.dart';
import 'package:picpak_image/src/pipeline/framebuffer_preview_renderer.dart';
import 'package:picpak_image/src/pipeline/palette_framebuffer.dart';
import 'package:picpak_image/src/pipeline/pipeline_result.dart';
import 'package:picpak_image/src/processing/image_adjustment_processor.dart';
import 'package:picpak_image/src/processing/image_adjustments.dart';
import 'package:picpak_image/src/processing/image_filter.dart';
import 'package:picpak_image/src/processing/image_filter_processing.dart';
import '../pipeline/fit_strategy.dart';
import '../dithering/dither_mode.dart';
import '../dithering/floyd_steinberg_dither.dart';
import '../dithering/atkinson_dither.dart';

class ImagePipeline {
  final int targetWidth;
  final int targetHeight;

  const ImagePipeline({
    this.targetWidth = DeviceConstants.imageWidth,
    this.targetHeight = DeviceConstants.imageHeight
  });

  PipelineResult process(
    Uint8List inputBytes, {
    required ImageFilter filter,
    required bool simulateDevice,
    required ImageAdjustments adjustments,
    FitStrategy fit = FitStrategy.crop,
    DitherMode dither = DitherMode.floydSteinberg,
  }) {
    final decoded = img.decodeImage(inputBytes);

    if (decoded == null) {
      throw Exception('Failed to decode image');
    }

    final resized = _resize(decoded, fit);

    final filtered = ImageFilterProcessor.apply(
      resized, filter
    );

    final adjusted = ImageAdjustmentProcessor.apply(filtered, adjustments);
    
    // TODO dithering engine rather than this
    final PaletteFramebuffer framebuffer = switch(dither) {
      DitherMode.atkinson => AtkinsonDither().apply(adjusted),
      DitherMode.floydSteinberg => FloydSteinbergDither().apply(adjusted)
    };

    final preview = FramebufferPreviewRenderer.render(
      framebuffer, simulateDevice: simulateDevice
    );

    return PipelineResult(
      framebuffer: framebuffer,
      previewImage: preview
    );
  }

  img.Image _resize(img.Image src, FitStrategy fit) {
    switch(fit) {
      case FitStrategy.scale:
        return img.copyResize(
          src,
          width: targetWidth,
          height: targetHeight
        );
      case FitStrategy.crop:
      final ratioSrc = src.width / src.height;
      final ratioTarget = targetWidth / targetHeight;

      img.Image cropped;

      if (ratioSrc > ratioTarget) {
        final newWidth = (src.height * ratioTarget).round();
        final xOffset = ((src.width - newWidth) / 2).round();

        cropped = img.copyCrop(src, x: xOffset, y: 0, width: newWidth, height: src.height);
      } else {
        final newHeight = (src.width / ratioTarget).round();
        final yOffset = ((src.height - newHeight) / 2).round();

        cropped = img.copyCrop(src, x: 0, y: yOffset, width: src.width, height: newHeight);
      }

      return img.copyResize(cropped, width: targetWidth, height: targetHeight);
    }
  }
}