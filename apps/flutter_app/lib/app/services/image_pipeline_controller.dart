import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:picpak_image/picpak_image.dart';

import 'package:picpak_core/picpak_core.dart';
import 'package:picpak_open/app/widgets/library/slot_metadata.dart';

class ImagePipelineController {
  img.Image? sourceImage;
  PaletteFramebuffer? framebuffer;
  Uint8List? previewBytes;

  Future<void> prepare(Uint8List bytes, FitStrategy fit) async {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return;

    final pipeline = ImagePipeline();
    sourceImage = pipeline.prepareBaseImage(decoded, fit);
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
        adjustments: metadata.adjustments
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
    required ImageAdjustments adjustments
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
        adjustments: adjustments
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