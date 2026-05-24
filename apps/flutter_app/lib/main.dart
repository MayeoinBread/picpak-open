import 'dart:async';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/transport/ble_manager.dart';
import 'package:picpak_core/picpak_core.dart';
import 'package:picpak_image/picpak_image.dart';
import 'package:picpak_image/src/pipeline/image_pipeline.dart';
import 'package:picpak_image/src/pipeline/fit_strategy.dart';
import 'package:picpak_image/src/encoding/framebuffer_packer.dart';
import 'package:picpak_image/src/dithering/dither_mode.dart';
import 'package:picpak_image/src/pipeline/palette_framebuffer.dart';
import 'package:picpak_image/src/pipeline/pipeline_isolate.dart';
import 'package:picpak_image/src/processing/image_adjustments.dart';
import 'package:image/image.dart' as img;
import 'package:picpak_protocol/picpak_protocol.dart';

// Bluetooth stuff
// import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_blue_plus_windows/flutter_blue_plus_windows.dart';

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
  Uint8List? _deviceImageBytes;
  final pipeline = ImagePipeline();

  PaletteFramebuffer? _framebuffer;

  DitherMode _ditherMode = DitherMode.floydSteinberg;
  FitStrategy _fitStrategy = FitStrategy.crop;
  SwatchType _swatchType = SwatchType.noise;

  final _noteController = TextEditingController();

  ImageFilter _filter = ImageFilter.normal;
  bool _simulateDevice = false;

  final BleManager _ble = BleManager();

  int _processToken = 0;
  bool _processing = false;

  double _brightness = 0.0;
  double _contrast = 1.0;

  @override
  void initState() {
    super.initState();

    debugPrint("UI BLE INSTANCE: ${identityHashCode(_ble)}");

    _ble.onImageDownloaded = (fb) {
      debugPrint(fb.pixels.length.toString());
      // TODO move the img.encode into the renderFrameBuffer?
      final previewBytes = Uint8List.fromList(
        img.encodePng(PanelRerender.renderFramebuffer(fb))
      );
      setState(() {
        _deviceImageBytes = previewBytes;
      });
    };
  }

  Future<void> _prepareWorkingImage() async {
    final bytes = _originalImage;
    if (bytes == null) return;

    final decoded = img.decodeImage(bytes);

    if (decoded == null) return;

    final pipeline = ImagePipeline();

    final prepared = pipeline.prepareBaseImage(decoded, _fitStrategy);

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
        width: DeviceConstants.imageWidth,
        height: DeviceConstants.imageHeight,
        fit: _fitStrategy,
        dither: _ditherMode,
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

  Future<void> _loadImageBytes(Uint8List bytes) async {
    setState(() {
      _originalImage = bytes;
    });

    await _prepareWorkingImage();
    await _reprocess();

    if (_framebuffer == null) return;

    final packed = FramebufferPacker.pack(_framebuffer!);

    debugPrint("Packed bytes: ${packed.length}");

    final packets = UploadSession.build(
      packedImageData: packed,
      imageNumber: 1
    );

    debugPrint("Packets: ${packets.length}");
    debugPrint("First packet size: ${packets.first.bytes.length}");
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final bytes = result.files.first.bytes;
    
    if (bytes == null) return;

    await _loadImageBytes(bytes);
  }

  Future<void> _loadSwatch() async {
    final swatch = SwatchGenerator.generate(
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

  Future<void> scanAndConnect() async {
    final device = await FlutterBluePlusWindows.startScan(timeout: const Duration(seconds: 5)).then((_) async {
      BluetoothDevice? found;
      final sub = FlutterBluePlusWindows.scanResults.listen((results) {
        for (final r in results) {
          if (r.device.platformName.toLowerCase().contains("picpak")) {
            found = r.device;
            break;
          }
        }
      });

      await Future.delayed(const Duration(seconds: 5));
      await sub.cancel();
      return found;
    });

    if (device == null) return;
    await _ble.connect(device);
    setState(() {});
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
                  child: Text(_ble.session.isConnected ? "Connected" : "Scan for Frame"),
                ),

                ElevatedButton(
                  onPressed: () => _ble.getImageInSlot(1),
                  child: Text("Read image 1")
                ),

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
                
                DropdownButton<DitherMode>(
                  value: _ditherMode,
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _ditherMode = value;
                    });

                    if (_originalImage != null) {
                      _reprocess();
                    }
                  },
                  items: DitherMode.values.map((t) {
                    return DropdownMenuItem(
                      value: t,
                      child: Text(t.name)
                    );
                  }).toList()
                ),

                DropdownButton<FitStrategy>(
                  value: _fitStrategy,
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => _fitStrategy = v);
                    _reprocess();
                  },
                  items: FitStrategy.values.map((t) {
                    return DropdownMenuItem(
                      value: t,
                      child: Text(t.name)
                    );
                  }).toList()
                ),

                DropdownButton<ImageFilter>(
                  value: _filter,
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => _filter = v);
                    _reprocess();
                  },
                  items: ImageFilter.values.map((t) {
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
                  onPressed: () async {
                    if (!_ble.session.isConnected || _originalImage == null) {
                      return;
                    }
                    _reprocess();
                    final flipped = flipVertical(_framebuffer!);
                    final packed = FramebufferPacker.pack(flipped);
                    final packets = UploadSession.build(imageNumber: 3, packedImageData: packed);

                    await _ble.sendImage(packets);

                    await _ble.sendMd5Trigger(imageNumber: 3, imageData: packed);

                    debugPrint("Upload compelte");
                  },
                  child: const Text("Send to Frame"),
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
                ),

                Column (
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Brightness"),
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
                    )
                  ]
                ),

                Column (
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Contrast"),
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
                  ]
                ),
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
              Expanded(
                child: ImagePanel(
                  title: "Device (raw download)",
                  imageBytes: _deviceImageBytes,
                )
              )
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