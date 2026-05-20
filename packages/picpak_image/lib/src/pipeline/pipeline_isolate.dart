import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:picpak_image/picpak_image.dart';
import 'package:picpak_image/src/pipeline/fit_strategy.dart';
import 'package:picpak_image/src/processing/image_adjustments.dart';

import 'image_pipeline.dart';
import 'pipeline_result.dart';
import '../processing/image_filter.dart';

PipelineResult runPipelineIsolate(dynamic data) {
  final req = data as PipelineRequest;
  final pipeline = ImagePipeline(
    targetWidth: req.width,
    targetHeight: req.height,
  );

  return pipeline.process(
    req.bytes,
    filter: req.filter,
    simulateDevice: req.simulateDevice,
    adjustments: req.adjustments,
    fit: req.fit,
    dither: req.dither,
  );
}

class PipelineRequest {
  final Uint8List bytes;
  final ImageFilter filter;
  final bool simulateDevice;
  final int width;
  final int height;
  final FitStrategy fit;
  final DitherMode dither;
  final ImageAdjustments adjustments;

  PipelineRequest({
    required this.bytes,
    required this.filter,
    required this.simulateDevice,
    required this.width,
    required this.height,
    required this.fit,
    required this.dither,
    required this.adjustments
  });
}