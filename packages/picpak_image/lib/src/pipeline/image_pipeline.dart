import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:picpak_core/picpak_core.dart';
import 'package:picpak_image/picpak_image.dart';
import 'package:picpak_image/src/dithering/dither_register.dart';
import 'package:picpak_image/src/pipeline/framebuffer_preview_renderer.dart';
import 'package:picpak_image/src/processing/image_adjustment_processor.dart';
import 'package:picpak_image/src/processing/image_filter_processing.dart';

class ImagePipeline {
  final int targetWidth;
  final int targetHeight;

  const ImagePipeline({
    this.targetWidth = DeviceConstants.imageWidth,
    this.targetHeight = DeviceConstants.imageHeight
  });

  PipelineResult process(
    img.Image workingImage, {
    required ImageFilter filter,
    required bool simulateDevice,
    required ImageAdjustments adjustments,
    required PaletteBias paletteBias,
    FitStrategy fit = FitStrategy.crop,
    DitherMode dither = DitherMode.floydSteinberg,
  }) {
    final resized = workingImage;

    final filtered = ImageFilterProcessor.apply(
      resized, filter
    );

    final adjusted = ImageAdjustmentProcessor.apply(filtered, adjustments);

    final sharpened = ImageAdjustmentProcessor.applySharpen(adjusted, adjustments.sharpen);

    final framebuffer = DitherRegistry.create(dither).apply(sharpened, paletteBias);

    final preview = FramebufferPreviewRenderer.render(
      framebuffer, simulateDevice: simulateDevice
    );

    final previewBytes = Uint8List.fromList(
      img.encodePng(preview)
    );

    return PipelineResult(
      framebuffer: framebuffer,
      previewBytes: previewBytes
    );
  }

  img.Image prepareBaseImage(img.Image src, FitStrategy fit, Rect? cropRect) {

    debugPrint("src: $src");

    if (cropRect != null) {
      src = img.copyCrop(src, x: cropRect.left.round(), y: cropRect.top.round(), width: cropRect.width.round(), height: cropRect.height.round());
    }

    switch(fit) {
      case FitStrategy.scale:
        return img.copyResize(
          src,
          width: targetWidth,
          height: targetHeight
        );
      case FitStrategy.crop:
        if (src.width == 0 || src.height == 0) return src;

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
      case _:
        return src;
    }
  }

  Rect defaultCrop(Size imageSize) {
    final targetAspect = 4 / 3;
    final imageAspect = imageSize.width / imageSize.height;

    double cropW, cropH;

    if (imageAspect > targetAspect) {
      cropH = imageSize.height;
      cropW = cropH * targetAspect;
    } else {
      cropW = imageSize.width;
      cropH = cropW / targetAspect;
    }

    final left = (imageSize.width - cropW) / 2;
    final top = (imageSize.height - cropH) / 2;

    return Rect.fromLTWH(left, top, cropW, cropH);
  }
}