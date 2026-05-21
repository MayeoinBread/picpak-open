import 'dart:async';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:picpak_core/picpak_core.dart';
import 'package:picpak_image/picpak_image.dart';
import 'package:picpak_image/src/pipeline/image_pipeline.dart';
import 'package:picpak_image/src/pipeline/fit_strategy.dart';
import 'package:picpak_image/src/encoding/framebuffer_packer.dart';
import 'package:picpak_image/src/dithering/dither_mode.dart';
import 'package:picpak_image/src/pipeline/palette_framebuffer.dart';
import 'package:picpak_image/src/pipeline/pipeline_isolate.dart';
import 'package:picpak_image/src/processing/image_adjustment_processor.dart';
import 'package:picpak_image/src/processing/image_adjustments.dart';
import 'package:image/image.dart' as img;
import 'package:picpak_protocol/picpak_protocol.dart';

// Bluetooth stuff
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'transport/ble_transport.dart';

void main() {
  runApp(const PicPakApp());
}

class PicPakApp extends StatelessWidget {
  const PicPakApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PicPak Open',
      debugShowCheckedModeBanner: true,
      theme: ThemeData.dark(),
      home: const ImageComparePage(),
    );
  }
}

class ImageComparePage extends StatefulWidget {
  const ImageComparePage({super.key});

  @override
  State<ImageComparePage> createState() => _ImageComparePageState();
}

class _ImageComparePageState extends State<ImageComparePage> {
  img.Image? _workingImage;
  Uint8List? _originalImage;
  Uint8List? _processedImage;
  final pipeline = ImagePipeline();

  PaletteFramebuffer? _framebuffer;

  // DitherMode? _ditherMode;
  DitherMode _ditherMode = DitherMode.floydSteinberg;

  ImageFilter _filter = ImageFilter.normal;
  bool _simulateDevice = false;

  final BleTransport _ble = BleTransport();
  BluetoothDevice? _device;

  int _processToken = 0;
  bool _processing = false;

  double _brightness = 0.0;
  double _pendingBrightness = 0.0;
  double _contrast = 1.0;
  double _pendingContrast = 1.0;

  Timer? _sliderTimer;

  Future<void> _prepareWorkingImage() async {
    final bytes = _originalImage;
    if (bytes == null) return;

    final decoded = img.decodeImage(bytes);

    if (decoded == null) return;

    final pipeline = ImagePipeline();

    final prepared = pipeline.prepareBaseImage(decoded, FitStrategy.crop);

    setState(() {
      _workingImage = prepared;
    });
  }

  Future<void> _reprocess() async {
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
        width: 400,
        height: 300,
        fit: FitStrategy.crop,
        dither: DitherMode.floydSteinberg,
        adjustments: ImageAdjustments(brightness: _brightness, contrast: _contrast)
      ),
    );

    if (token != _processToken) return;

    setState(() {
      _framebuffer = result.framebuffer;
      _processedImage = result.previewBytes;
      _processing = false;
    });
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final bytes = result.files.first.bytes;
    if (bytes == null) return;

    setState(() {
      _originalImage = bytes;
    });

    await _prepareWorkingImage();

    await _reprocess();

    if (_framebuffer == null) return;

    final packed = FramebufferPacker.pack(_framebuffer!);
    debugPrint("Packed bytes: ${packed.length}");

    final packets = UploadSession.build(packedImageData: packed);
    debugPrint("Packets: ${packets.length}");
    debugPrint("First packet size: ${packets.first.bytes.length}");
  }

  Future<void> scanAndConnect() async {
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));

    FlutterBluePlus.scanResults.listen((results) async {
      for (final r in results) {
        if (r.advertisementData.serviceUuids.contains(ProtocolConstants.serviceUuid)) {
          _device = r.device;
          await FlutterBluePlus.stopScan();
          setState(() {});
          return;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PicPak Image Pipeline'),
        actions: [
        ]
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 12, runSpacing: 12,
              children: [
                ElevatedButton(
                  onPressed: _pickImage,
                  child: const Text("Load Image")
                ),

                ElevatedButton(
                  onPressed: scanAndConnect,
                  child: Text( _device == null ? "Scan for Frame" : "Connected"),
                ),
                
                DropdownButton<DitherMode>(
                  value: _ditherMode,
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _ditherMode = value;
                    });

                    if (_originalImage != null) {
                      _reprocess();

                      final packed = FramebufferPacker.pack(_framebuffer!);
                      debugPrint("Packed bytes: ${packed.length}");
                    }
                  },
                  items: const [
                    DropdownMenuItem(
                      value: DitherMode.floydSteinberg,
                      child: Text("Floyd-Steinberg")
                    ),
                    DropdownMenuItem(
                      value: DitherMode.atkinson,
                      child: Text("Atkinson")
                    )
                  ],
                ),

                DropdownButton<ImageFilter>(
                  value: _filter,
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => _filter = v);
                    _reprocess();
                  },
                  items: const [
                    DropdownMenuItem(value: ImageFilter.normal, child: Text("Normal")),
                    DropdownMenuItem(value: ImageFilter.vibrant, child: Text("Vibrant")),
                    DropdownMenuItem(value: ImageFilter.grayscale, child: Text("Grayscale")),
                    DropdownMenuItem(value: ImageFilter.highContrast, child: Text("High Contrast"))
                  ]
                ),

                SwitchListTile(title: const Text("Simulate Device Colours"), value: _simulateDevice,
                  onChanged: (v) {
                    setState(() => _simulateDevice = v);
                    _reprocess();
                  }
                ),

                ElevatedButton(
                  onPressed: () async {
                    if (_device == null || _originalImage == null) {
                      return;
                    }
                    _reprocess();
                    
                    final packed = FramebufferPacker.pack(_framebuffer!);
                    final packets = UploadSession.build(packedImageData: packed);

                    await _ble.sendImage(device: _device!, packets: packets, onProgress: (p) {
                      debugPrint("Upload ${(p * 100).toStringAsFixed(1)}%");
                    });

                    await _ble.sendMd5Trigger(device: _device!, imageNumber: 1, imageData: packed);

                    debugPrint("Upload compelte");
                  },
                  child: const Text("Send to Frame"),
                ),

                Slider(
                  value: _brightness,
                  divisions: 20,
                  min: -1.0,
                  max: 1.0,
                  onChanged: (v) {
                    setState(() {
                      _brightness = v;
                    });
                  },
                  onChangeEnd: (_) {
                    _reprocess();
                  }
                ),

                Slider(
                  value: _contrast,
                  divisions: 20,
                  min: 0.0,
                  max: 2.0,
                  onChanged: (v) {
                    setState(() {
                      _contrast = v;
                    });
                  },
                  onChangeEnd: (_) {
                    _reprocess();
                  },
                )
              ],
            ),
          ),

          Expanded(child: Row(
            children: [
              Expanded(
                child: ImagePanel(
                  title: 'Original',
                  imageBytes: _originalImage
                )
              ),
              const VerticalDivider(width: 1),
              Expanded(
                child: Stack(
                  children: [
                    ImagePanel(
                      title: "Processed",
                      imageBytes: _processedImage,
                    ),

                    if (_processing)
                      Positioned.fill(
                        child: Container(
                          color: const Color(0x88000000),
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ]),
          )
        ],
      ),
    );
  }
}

class ImagePanel extends StatelessWidget {
  final String title;
  final Uint8List? imageBytes;

  const ImagePanel({
    super.key,
    required this.title,
    required this.imageBytes
  });

  @override
  Widget build(BuildContext context){
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          child: Text(title)
        ),
        const Divider(height: 1),
        Expanded(
          child: Center(
            child: imageBytes == null
              ? const Text("No image loaded")
              : Image.memory(imageBytes!)
          )
        )
      ],
    );
  }
}