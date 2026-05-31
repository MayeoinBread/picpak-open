import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide ConnectionState;
import 'package:flutter_app/app/services/dashboard_actions.dart';
import 'package:flutter_app/app/state/device_session_state.dart';
import 'package:flutter_app/app/widgets/common/image_preview_panel.dart';
import 'package:flutter_app/app/widgets/common/status_bar.dart';
import 'package:flutter_app/app/widgets/controls/dithering_controls.dart';
import 'package:flutter_app/app/widgets/controls/image_adjustment_controls.dart';
import 'package:flutter_app/app/widgets/controls/processing_options_panel.dart';
import 'package:flutter_app/app/widgets/device/device_actions_panel.dart';
import 'package:flutter_app/app/widgets/device/device_info_card.dart';
import 'package:flutter_app/transport/ble_manager.dart';
import 'package:image/image.dart' as img;
import 'package:picpak_core/picpak_core.dart';
import 'package:picpak_image/picpak_image.dart';
import 'package:picpak_image/src/pipeline/image_pipeline.dart';
import 'package:picpak_image/src/pipeline/pipeline_isolate.dart';
import 'package:picpak_image/src/encoding/framebuffer_packer.dart';
import 'package:picpak_protocol/picpak_protocol.dart';
import 'package:picpak_image/src/pipeline/fit_strategy.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {

  DitherMode algorithm = DitherMode.atkinson;
  ImageAdjustments adjustments = ImageAdjustments(brightness: 0.0, contrast: 1.0);

  DeviceSessionState session = DeviceSessionState(connection: ConnectionState.disconnected, transfer: TransferState.idle, progress: 0.0, deviceName: 'Not Connected', batteryPercent: 0, firmware: '-', availableSlots: const []);

  FitStrategy _fitStrategy = FitStrategy.crop;
  ImageFilter _filter = ImageFilter.normal;
  bool _simulateDeviceScreen = false;

  ImageProvider? _previewImage;

  img.Image? _sourceImage;
  Uint8List? _originalImageBytes;
  PaletteFramebuffer? _processedFramebuffer;
  Uint8List? _deviceImageBytes;

  bool _processing = false;
  int _processToken = 0;

  final BleManager ble = BleManager();

  void updateSession(DeviceSessionState Function(DeviceSessionState current) updater) {
    setState(() { session = updater(session);});
  }

  @override
  void initState() {
    super.initState();

    ble.onImageDownloaded = (framebuffer) {
      final previewBytes = Uint8List.fromList(
        img.encodePng(PanelRerender.renderFramebuffer(framebuffer))
      );
      setState(() {
        _deviceImageBytes = previewBytes;
        session = session.copyWith(
          transfer: TransferState.idle,
          progress: 0,
          activeSlot: null
        );
      });
    };

    ble.onDeviceInfo = (info) {
      setState(() {
        session = session.copyWith(
          batteryPercent: info.battery,
          firmware: info.firmware
        );
      });
    };

    ble.onSlotList = (slots) {
      final safeActive = session.activeSlot;

      setState(() {
        session = session.copyWith(
          availableSlots: slots,
          // activeSlot: slots.isNotEmpty ? slots.first : null
          activeSlot: slots.contains(safeActive) ? safeActive : (slots.isNotEmpty ? slots.first : null)
        );
      });
    };

    ble.uploadProgress.addListener(() {
      updateSession((s) => s.copyWith(
        transfer: TransferState.uploading,
        progress: ble.uploadProgress.value
      ));
    });

    ble.onUploadComplete = () {
      setState(() {
        session = session.copyWith(
          transfer: TransferState.idle,
          progress: 0
        );
      });
    };
  }

  Future<void> _prepareWorkingImage() async {
    final bytes = _originalImageBytes;
    if (bytes == null) return;

    final decoded = img.decodeImage(bytes);

    if (decoded == null) return;

    final pipeline = ImagePipeline();

    final prepared = pipeline.prepareBaseImage(decoded, _fitStrategy);

    setState(() {
      _sourceImage = prepared;
    });
  }

  Future<void> _reprocess() async {
    if (_processing) return;
    final image = _sourceImage;
    if (image == null) return;

    final token = ++_processToken;

    setState(() => _processing = true);

    await Future.delayed(Duration.zero);

    final result = await compute(
      runPipelineIsolate,
      PipelineRequest(
        workingImage: _sourceImage!,
        filter: _filter,
        simulateDevice: _simulateDeviceScreen,
        width: DeviceConstants.imageWidth,
        height: DeviceConstants.imageHeight,
        fit: _fitStrategy,
        dither: algorithm,
        adjustments: ImageAdjustments(brightness: adjustments.brightness, contrast: adjustments.contrast)
      ),
    );

    if (token != _processToken) return;

    setState(() {
      _processedFramebuffer = result.framebuffer;
      _deviceImageBytes = result.previewBytes;
      _processing = false;
    });
  }

  Future<void> _loadImageBytes(Uint8List bytes) async {
    setState(() {
      if (!listEquals(_originalImageBytes, bytes)) {
        _originalImageBytes = bytes;
        _previewImage = MemoryImage(
          Uint8List.fromList(bytes)
        );
      }
    });

    await _prepareWorkingImage();
    _reprocess();
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

  Future<void> _uploadImage() async {
    debugPrint("Active slot: ${session.activeSlot}");
    await _reprocess();

    final fb = _processedFramebuffer;
    if (fb == null) {
      debugPrint("framebuffer is null");
      return;
    }

    final flipped = flipVertical(fb);
    final packed = FramebufferPacker.pack(flipped);

    debugPrint("packed bytes: ${packed.length}");

    final packets = UploadSession.build(imageNumber: session.activeSlot!, packedImageData: packed);

    debugPrint("Packets: ${packets.length}");
    debugPrint("First packet size: ${packets.first.bytes.length}");

    await ble.sendImage(packets);
    await ble.sendMd5Trigger(imageNumber: session.activeSlot!, imageData: packed);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PicPak Open')
      ),

      body: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                // LEFT PANEL
                SizedBox(
                  width: 300,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    color: Theme.of(context).colorScheme.surfaceContainerLowest,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        DeviceInfoCard(state: session),
                        const SizedBox(height: 16),
                        DeviceActionsPanel(
                          activeSlot: session.activeSlot,
                          onConnect: session.canConnect
                            ? () => DashboardActions.connect(ble: ble, updateSession: updateSession)
                            : null,
                          onDisconnect: session.canDisconnect
                            ? () => DashboardActions.disconnect(ble: ble, updateSession: updateSession)
                            : null,
                          onDownload: session.canDownload
                            ? () => DashboardActions.downloadSlot(ble: ble, slot: session.activeSlot!, updateSession: updateSession)
                            : null,
                          onUpload: session.canTransfer
                            ? _uploadImage
                            : null,
                          onSlotChanged: (slot) {
                            updateSession((s) => s.copyWith(activeSlot: slot));
                          },
                        )
                      ],
                    ),
                  ),
                ),

                // CENTER
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        ImagePreviewPanel(title: 'Original', height: DeviceConstants.imageHeight, imageBytes: _originalImageBytes),
                        const SizedBox(height: 16),
                        ImagePreviewPanel(title: 'Preview', height: DeviceConstants.imageHeight, imageBytes: _deviceImageBytes)
                      ]
                    )
                  )
                ),

                // RIGHT PANEL
                SizedBox(
                  width: 340,
                  child: Container(
                    color: Theme.of(context).colorScheme.surfaceContainerLowest,
                    child: Column(
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
                      ],
                    )
                  )
                )
              ]
            )
          ),
          // STATUS BAR
          StatusBar(state: session)
        ],
      )
    );
  }
}