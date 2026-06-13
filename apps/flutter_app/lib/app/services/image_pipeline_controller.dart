import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:picpak_image/picpak_image.dart';

import 'package:picpak_core/picpak_core.dart';
import 'package:picpak_open/app/widgets/library/slot_metadata.dart';

class ImagePipelineController {
  img.Image? sourceImage;
  PaletteFramebuffer? framebuffer;
  Uint8List? previewBytes;

  Future<void> prepare(Uint8List bytes, FitStrategy fit, Rect? cropRect) async {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return;

    final pipeline = ImagePipeline();
    sourceImage = pipeline.prepareBaseImage(decoded, fit, cropRect);
  }

  Future<void> processMetadata({
    required SlotMetadata metadata,
    bool simulateDevice = false
    }) async {
    if (sourceImage == null) return;

    debugPrint('Simulate Device: $simulateDevice');

    final result = await compute(
      runPipelineIsolate,
      PipelineRequest(
        workingImage: sourceImage!,
        filter: metadata.filter,
        simulateDevice: simulateDevice,
        width: DeviceConstants.imageWidth,
        height: DeviceConstants.imageHeight,
        fit: metadata.fit,
        dither: metadata.dither,
        adjustments: metadata.adjustments,
        paletteBias: metadata.paletteBias
      )
    );

    framebuffer = result.framebuffer;
    previewBytes = result.previewBytes;
  }

  Future<void> process({
    required DitherMode dither,
    required ImageFilter filter,
    required bool simulateDevice,
    required FitStrategy fit,
    required ImageAdjustments adjustments,
    required PaletteBias paletteBias
  }) async {
    if (sourceImage == null) return;

    debugPrint('Simulate Device: $simulateDevice');

    final result = await compute(
      runPipelineIsolate,
      PipelineRequest(
        workingImage: sourceImage!,
        filter: filter,
        simulateDevice: simulateDevice,
        width: DeviceConstants.imageWidth,
        height: DeviceConstants.imageHeight,
        fit: fit,
        dither: dither,
        adjustments: adjustments,
        paletteBias: paletteBias
      )
    );

    framebuffer = result.framebuffer;
    previewBytes = result.previewBytes;
  }

  void clear() {
    sourceImage = null;
    framebuffer = null;
    previewBytes = null;
  }
}