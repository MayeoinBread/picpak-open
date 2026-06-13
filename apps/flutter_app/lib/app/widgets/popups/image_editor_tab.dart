import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:picpak_open/app/repositories/image_repository.dart';
import 'package:picpak_open/app/services/image_pipeline_controller.dart';
import 'package:picpak_open/app/services/thumbnail_service.dart';
import 'package:picpak_open/app/widgets/common/image_preview_panel.dart';
import 'package:picpak_open/app/widgets/controls/dithering_controls.dart';
import 'package:picpak_open/app/widgets/controls/image_adjustment_controls.dart';
import 'package:picpak_open/app/widgets/controls/palette_bias_controls.dart';
import 'package:picpak_open/app/widgets/controls/processing_options_panel.dart';
import 'package:picpak_open/app/widgets/library/library_item.dart';
import 'package:picpak_open/app/widgets/library/slot_metadata.dart';
import 'package:picpak_core/picpak_core.dart';
import 'package:picpak_image/picpak_image.dart';
import 'package:picpak_open/app/widgets/popups/crop_dialog.dart';

class ImageEditorTab extends StatefulWidget {
  final LibraryItem item;

  final void Function(
    SlotMetadata metadata,
    Uint8List thumbnailBytes
  ) onSaved;

  const ImageEditorTab({
    super.key,
    required this.item,
    required this.onSaved
  });

  @override
  State<ImageEditorTab> createState() => _ImageEditorTabState();
}

class _ImageEditorTabState extends State<ImageEditorTab> {
  Uint8List? _originalImageBytes;
  Uint8List? previewBytes;

  int _processVersion = 0;

  final ImagePipelineController pipeline = ImagePipelineController();

  // Image Adjustments/Dithering, etc.
  DitherMode algorithm = DitherMode.atkinson;
  ImageAdjustments adjustments = ImageAdjustments();
  PaletteBias paletteBias = PaletteBias();
  FitStrategy _fitStrategy = FitStrategy.crop;
  ImageFilter _filter = ImageFilter.normal;
  bool _simulateDeviceScreen = false;
  Rect? cropRect;

  @override
  void initState() {
    super.initState();

    debugPrint("--HYDRATING--");

    _hydrateFromItem();
  }

  Future<void> _hydrateFromItem() async {
    // pipeline.clear();
    final item = widget.item;

    final metadata = item.metadata;

    final imageId = metadata.imageId;
    debugPrint("ImageID: $imageId");
    if (imageId == null) return;

    setState(() {
      algorithm = metadata.dither;
      adjustments = metadata.adjustments;
      _fitStrategy = metadata.fit;
      _filter = metadata.filter;
      cropRect = metadata.cropRect;
    });

    _originalImageBytes = await ImageRepository().loadOriginalBytes(imageId);
    debugPrint("bytes length: ${_originalImageBytes!.length}");
    if (_originalImageBytes == null) return;

    await pipeline.prepare(_originalImageBytes!, _fitStrategy, cropRect);
    await pipeline.processMetadata(
      metadata: metadata,
      simulateDevice: _simulateDeviceScreen
    );

    if (!mounted) return;

    setState(() {});
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true
    );

    if (result == null || result.files.isEmpty) return;

    final bytes = result.files.first.bytes;

    if (bytes == null) return;

    await _loadImageBytes(bytes);
  }

  Future<void> _loadImageBytes(Uint8List bytes) async {
    setState(() {
      if (!listEquals(_originalImageBytes, bytes)) {
        _originalImageBytes = bytes;
      }
    });

    await _prepareWorkingImage();
    await _reprocess();
  }

  Future<void> _prepareWorkingImage() async {
    final bytes = _originalImageBytes;
    if (bytes == null) return;

    await pipeline.prepare(bytes, _fitStrategy, cropRect);
  }

  Future<void> _reprocess() async {
    final bytes = _originalImageBytes;
    if (bytes == null) return;

    final int version = ++_processVersion;

    await pipeline.process(
      dither: algorithm,
      filter: _filter,
      simulateDevice: _simulateDeviceScreen,
      fit: _fitStrategy,
      adjustments: adjustments,
      paletteBias: paletteBias
    );

    if (version != _processVersion) return;

    setState((){});
  }

  void _save() async {
    await pipeline.process(
      dither: algorithm,
      filter: _filter,
      simulateDevice: _simulateDeviceScreen,
      fit: _fitStrategy,
      adjustments: adjustments,
      paletteBias: paletteBias
    );

    final thumbnail = ThumbnailService.createFromBytes(pipeline.previewBytes!);
    
    final image = await ImageRepository().importImage(
      originalBytes: _originalImageBytes!,
      framebuffer: pipeline.framebuffer!,
      thumbnailBytes: thumbnail
    );

    final metadata = SlotMetadata(
      type: SlotContentType.image,
      pendingAction: SlotPendingAction.upload,
      adjustments: adjustments,
      dither: algorithm,
      fit: _fitStrategy,
      filter: _filter,
      imageId: image.id,
      cropRect: cropRect
    );

    widget.onSaved(metadata, thumbnail);

    Navigator.pop(context);
  }

  Future<void> _autoEnhance() async {
    final image = pipeline.sourceImage;
    if (image == null) return;
    final metrics = ImageMetrics.analyseImage(image);
    final suggested = ImageAdjustments.autoEnhance(metrics);
    setState(() {
      adjustments = suggested;
    });
    await _reprocess();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  ElevatedButton(
                    onPressed: _pickImage,
                    child: const Text('Import Image')
                  ),
                  const SizedBox(height: 8),
                  DitheringControls(
                    selectedAlgorithm: algorithm,
                    onAlgorithmChanged: (newAlg) async {
                      setState(() {
                        algorithm = newAlg;
                      });
                      _reprocess();
                    }
                  ),
                  const SizedBox(height: 8),
                  IconButton(
                    icon: const Icon(Icons.crop),
                    onPressed: () async {
                      final rect = await showDialog<Rect>(
                        context: context,
                        builder: (_) => CropDialog(
                          imageBytes: _originalImageBytes!,
                          initialRect: cropRect,
                        )
                      );

                      if (rect != null) {
                        setState(() {
                          cropRect = rect;
                        });
                      }

                      await _prepareWorkingImage();
                      await _reprocess();
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.diamond_sharp),
                    onPressed: () async {
                      await _autoEnhance();
                    }
                  ),
                  const SizedBox(height: 8),
                  ImageAdjustmentControls(
                    adjustments: adjustments,
                    onChanged: (newAdjustments) async {
                      setState(() {
                        adjustments = newAdjustments;
                      });
                      _reprocess();
                    }
                  ),
                  const SizedBox(height: 8),
                  PaletteBiasControls(
                    paletteBias: paletteBias,
                    onChanged: (newBias) async {
                      setState(() {
                        paletteBias = newBias;
                      });
                      _reprocess();
                    }
                  ),
                  const SizedBox(height: 8),
                  ProcessingOptionsPanel(
                    selectedFilter: _filter,
                    fitStrategy: _fitStrategy,
                    simulateDevice: _simulateDeviceScreen,
                    onFilterChanged: (filter) async {
                      setState(() {
                        _filter = filter;
                      });
                      _reprocess();
                    },
                    onFitChanged: (fit) async {
                      setState(() {
                        _fitStrategy = fit;
                      });
                      _reprocess();
                    },
                    onSimulateChanged: (simulate) async {
                      setState(() {
                        _simulateDeviceScreen = simulate;
                      });
                      _reprocess();
                    }
                  )
                ]
              )
            )
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              children: [
                ImagePreviewPanel(
                  title: 'Preview',
                  height: DeviceConstants.imageHeight,
                  imageBytes: pipeline.previewBytes
                ),
                const SizedBox(width: 8),
                ElevatedButton(onPressed: _save, child: const Text('Save'))
              ],
            )
            
          )
        ],
      )
    );
  }
}