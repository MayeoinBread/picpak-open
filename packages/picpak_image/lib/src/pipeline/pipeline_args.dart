import 'dart:typed_data';

import 'package:picpak_image/picpak_image.dart';
import 'package:picpak_image/src/pipeline/fit_strategy.dart';

class PipelineArgs {
  final Uint8List image;
  final ImageFilter filter;
  final bool simulateDevice;
  final FitStrategy fit;
  final DitherMode dither;

  const PipelineArgs({
    required this.image,
    required this.filter,
    required this.simulateDevice,
    required this.fit,
    required this.dither
  });
}