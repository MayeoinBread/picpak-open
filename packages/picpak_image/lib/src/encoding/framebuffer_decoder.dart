import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:picpak_core/picpak_core.dart';
import 'package:picpak_image/picpak_image.dart';
import 'package:picpak_image/src/pipeline/palette_framebuffer.dart';

class FramebufferDecoder {
  static PaletteFramebuffer decode(Uint8List bytes) {
    debugPrint("decoding/unpacking");
    final totalPixels = DeviceConstants.imageWidth * DeviceConstants.imageHeight;
    final pixels = Uint8List(totalPixels);

    int p = 0;

    for (final byte in bytes) {
      if (p < totalPixels) pixels[p++] = (byte >> 6) & 0x03;
      if (p < totalPixels) pixels[p++] = (byte >> 4) & 0x03;
      if (p < totalPixels) pixels[p++] = (byte >> 2) & 0x03;
      if (p < totalPixels) pixels[p++] = (byte >> 0) & 0x03;
    }

    final flippedBuffer =  PaletteFramebuffer(width: DeviceConstants.imageWidth, height: DeviceConstants.imageHeight, pixels: pixels);
    return flipVertical(flippedBuffer);
  }
}