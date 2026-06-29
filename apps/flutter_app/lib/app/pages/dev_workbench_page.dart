import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:picpak_core/picpak_core.dart';
import 'package:picpak_image/picpak_image.dart';
import 'package:image/image.dart' as img;
import 'package:picpak_open/app/widgets/common/image_preview_panel.dart';
import 'package:picpak_open/app/widgets/controls/dithering_controls.dart';
import 'package:picpak_open/app/widgets/controls/filter_controls.dart';
import 'package:picpak_open/app/widgets/controls/filter_options_controls.dart';
import 'package:picpak_open/app/widgets/controls/image_adjustment_controls.dart';
import 'package:picpak_open/app/widgets/controls/palette_bias_controls.dart';
import 'package:picpak_protocol/picpak_protocol.dart';

class DevWorkbenchPage extends StatefulWidget {
  const DevWorkbenchPage({super.key});

  @override
  State<DevWorkbenchPage> createState() => _DevWorkbenchPageState();
}

class _DevWorkbenchPageState extends State<DevWorkbenchPage> {
  img.Image? _workingImage;
  Uint8List? _originalImage;
  Uint8List? _processedImage;

  final pipeline = ImagePipeline();

  PaletteFramebuffer? _framebuffer;

  DitherMode _ditherMode = DitherMode.floydSteinberg;
  FitStrategy _fitStrategy = FitStrategy.crop;
  SwatchType _swatchType = SwatchType.noise;

  ImageAdjustments _adjustments = ImageAdjustments();
  PaletteBias _bias = PaletteBias();

  final _noteController = TextEditingController();

  ImageFilter _filter = ImageFilter.normal;
  bool _simulateDevice = false;

  int _processToken = 0;
  bool _processing = false;

  late StreamSubscription sub;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    sub.cancel();
    super.dispose();
  }

  Future<void> _prepareWorkingImage() async {
    final bytes = _originalImage;
    if (bytes == null) return;

    final decoded = img.decodeImage(bytes);

    if (decoded == null) return;

    final pipeline = ImagePipeline();

    final prepared = pipeline.prepareBaseImage(decoded, _fitStrategy, null);

    setState(() {
      _workingImage = prepared;
    });
  }

  Future<void> _reprocess() async {

    _prepareWorkingImage();

    final image = _originalImage;
    if (image == null) return;

    final token = ++_processToken;

    setState(() => _processing = true);

    await Future.delayed(Duration.zero);

    final result = await compute(
      runPipelineIsolate,
      PipelineRequest(
        workingImage: _workingImage!,
        filter: _filter,
        simulateDevice: _simulateDevice,
        width: DeviceConstants.imageWidth,
        height: DeviceConstants.imageHeight,
        fit: _fitStrategy,
        dither: _ditherMode,
        adjustments: _adjustments,
        paletteBias: _bias
      ),
    );

    if (token != _processToken) return;

    setState(() {
      _framebuffer = result.framebuffer;
      _processedImage = result.previewBytes;
      _processing = false;
    });
  }

  Future<void> _loadImageBytes(Uint8List bytes) async {
    setState(() {
      _originalImage = bytes;
    });

    await _reprocess();

    if (_framebuffer == null) return;
  }

  Future<void> _loadSwatch() async {
    final swatch = await SwatchGenerator.generate(
      _swatchType,
      width: DeviceConstants.imageWidth,
      height: DeviceConstants.imageHeight
    );
    final bytes = Uint8List.fromList(
      img.encodePng(swatch)
    );

    await _loadImageBytes(bytes);
  }

  Future<void> _generateNote() async {
    final note = NoteRenderer.render(
      text: _noteController.text,
      w: DeviceConstants.imageWidth,
      h: DeviceConstants.imageHeight
    );

    final bytes = Uint8List.fromList(
      img.encodePng(note)
    );

    await _loadImageBytes(bytes);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Row (
          children: [
            SizedBox(
              width: 340,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    ImageAdjustmentControls(
                      adjustments: _adjustments,
                      onChanged: (newAdjustments) async {
                        setState(() {
                          _adjustments = newAdjustments;
                        });
                        _reprocess();
                      }
                    ),
                    PaletteBiasControls(
                      paletteBias: _bias,
                      onChanged: (newBias) async {
                        setState(() {
                          _bias = newBias;
                        });
                        _reprocess();
                      }
                    ),
                    DitheringControls(
                      selectedAlgorithm: _ditherMode,
                      onAlgorithmChanged: (newAlg) async {
                        setState(() {
                          _ditherMode = newAlg;
                        });
                        _reprocess();
                      }
                    ),
                    FilterControls(
                      selectedFilter: _filter,
                      onFilterChanged: (filter) async {
                        setState(() {
                          _filter = filter;
                        });
                        _reprocess();
                      }
                    ),
                    FilterOptionsControls(
                      adjustments: _adjustments,
                      filter: _filter,
                      onChanged: (newAdjustments) async {
                        setState(() {
                          _adjustments = newAdjustments;
                        });
                        _reprocess();
                      }
                    ),
                  ],
                )
              ),
            ),

            SizedBox(
              width: 340,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    DropdownButton<SwatchType>(
                      value: _swatchType,
                      onChanged: (value) async {
                        if (value == null) return;
                        setState(() {
                          _swatchType = value;
                        });
                        await _loadSwatch();
                      },
                      items: SwatchType.values.map((t) {
                        return DropdownMenuItem(
                          value: t,
                          child: Text(t.name)
                        );
                      }).toList()
                    ),

                    SwitchListTile(title: const Text("Simulate Device Colours"), value: _simulateDevice,
                      onChanged: (v) {
                        setState(() => _simulateDevice = v);
                        _reprocess();
                      }
                    ),

                    ElevatedButton(
                      onPressed: _generateNote,
                      child: const Text("Generate Note")
                    ),

                    TextField(
                      controller: _noteController,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: "Note Text",
                        border: OutlineInputBorder()
                      ),
                    )
                  ],
                )
              ),
            ),

            Expanded(
              child: Column(
                children: [
                  ImagePreviewPanel(title: "Original", height: 300, imageBytes: _originalImage),
                  ImagePreviewPanel(title: "Processed", height: 300, imageBytes: _processedImage)
                ],
              )
            )
          ],
        )
      ),
    );
  }
}
