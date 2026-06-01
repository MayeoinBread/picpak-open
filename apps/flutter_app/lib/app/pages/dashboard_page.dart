import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide ConnectionState;
import 'package:flutter_app/app/services/ble_service.dart';
import 'package:flutter_app/app/services/dashboard_actions.dart';
import 'package:flutter_app/app/services/device_session_service.dart';
import 'package:flutter_app/app/services/image_pipeline_controller.dart';
import 'package:flutter_app/app/state/device_session_state.dart';
import 'package:flutter_app/app/widgets/common/image_preview_panel.dart';
import 'package:flutter_app/app/widgets/common/status_bar.dart';
import 'package:flutter_app/app/widgets/controls/dithering_controls.dart';
import 'package:flutter_app/app/widgets/controls/image_adjustment_controls.dart';
import 'package:flutter_app/app/widgets/controls/processing_options_panel.dart';
import 'package:flutter_app/app/widgets/device/device_actions_panel.dart';
import 'package:flutter_app/app/widgets/device/device_info_card.dart';
import 'package:image/image.dart' as img;
import 'package:picpak_core/picpak_core.dart';
import 'package:picpak_image/picpak_image.dart';
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

  // DeviceSessionState session = DeviceSessionState(connection: ConnectionState.disconnected, transfer: TransferState.idle, progress: 0.0, deviceName: 'Not Connected', batteryPercent: 0, firmware: '-', availableSlots: const []);
  final session = DeviceSessionService.instance;

  FitStrategy _fitStrategy = FitStrategy.crop;
  ImageFilter _filter = ImageFilter.normal;
  bool _simulateDeviceScreen = false;

  final ImagePipelineController pipeline = ImagePipelineController();
  Uint8List? _originalImageBytes;

  bool _processing = false;

  DateTime _lastProgressUpdate = DateTime.fromMillisecondsSinceEpoch(0);

  final ble = BleService.instance.manager;

  late final void Function(PaletteFramebuffer) _imageListener;

  void updateSession(DeviceSessionState Function(DeviceSessionState current) updater) {
    setState(() { session.state = updater(session.state);});
  }

  @override
  void initState() {
    super.initState();

    ble.onImageDownloaded = (framebuffer) {
      pipeline.framebuffer = framebuffer;

      pipeline.previewBytes = Uint8List.fromList(
        img.encodePng(PanelRerender.renderFramebuffer(framebuffer))
      );


      setState(() {
        session.state = session.state.copyWith(
          transfer: TransferState.idle,
          progress: 0,
          activeSlot: null
        );
      });
    };

    ble.onDeviceInfo = (info) {
      setState(() {
        session.state = session.state.copyWith(
          batteryPercent: info.battery,
          firmware: info.firmware
        );
      });
    };

    ble.onSlotList = (slots) {
      final safeActive = session.state.activeSlot;

      setState(() {
        session.state = session.state.copyWith(
          availableSlots: slots,
          // activeSlot: slots.isNotEmpty ? slots.first : null
          activeSlot: slots.contains(safeActive) ? safeActive : (slots.isNotEmpty ? slots.first : null)
        );
      });
    };

    ble.onUploadComplete = () {
      setState(() {
        session.state = session.state.copyWith(
          transfer: TransferState.idle,
          progress: 0
        );
      });
    };

    _imageListener = (fb) {
      if (!mounted) return;

      pipeline.framebuffer = fb;
      pipeline.previewBytes = Uint8List.fromList(
        img.encodePng(PanelRerender.renderFramebuffer(fb))
      );

      setState(() {
        session.update((s) => s.copyWith(
          transfer: TransferState.idle,
          progress: 0,
          activeSlot: null
        ));
      });
    };

    ble.addImageListener(_imageListener);
  }

  @override
  void dispose() {
    ble.removeImageListener(_imageListener);
    super.dispose();
  }

  Future<void> _prepareWorkingImage() async {
    final bytes = _originalImageBytes;
    if (bytes == null) return;

    await pipeline.prepare(bytes, _fitStrategy);
  }

  Future<void> _reprocess() async {
    final bytes = _originalImageBytes;
    if (bytes == null) return;

    setState(() => _processing = true);

    await pipeline.process(
      dither: algorithm,
      filter: _filter,
      simulateDevice: _simulateDeviceScreen,
      fit: _fitStrategy,
      adjustments: adjustments
    );

    setState(() {
      _processing = false;
    });
  }

  Future<void> _loadImageBytes(Uint8List bytes) async {
    setState(() {
      if (!listEquals(_originalImageBytes, bytes)) {
        _originalImageBytes = bytes;
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
    final fb = pipeline.framebuffer;
    if (fb == null) return;

    setState(() {
      session.state = session.state.copyWith(
        transfer: TransferState.uploading,
        progress: 0
      );
    });

    final flipped = flipVertical(fb);
    final packed = FramebufferPacker.pack(flipped);

    final packets = UploadSession.build(imageNumber: session.state.activeSlot!, packedImageData: packed);

    await ble.sendImage(packets);
    await ble.sendMd5Trigger(imageNumber: session.state.activeSlot!, imageData: packed);
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
                        DeviceInfoCard(state: session.state),
                        const SizedBox(height: 16),
                        DeviceActionsPanel(
                          activeSlot: session.state.activeSlot,
                          onConnect: session.state.canConnect
                            ? () => DashboardActions.connect(ble: ble, updateSession: updateSession)
                            : null,
                          onDisconnect: session.state.canDisconnect
                            ? () => DashboardActions.disconnect(ble: ble, updateSession: updateSession)
                            : null,
                          onDownload: session.state.canDownload
                            ? () => DashboardActions.downloadSlot(ble: ble, slot: session.state.activeSlot!, updateSession: updateSession)
                            : null,
                          onUpload: session.state.canTransfer
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
                        ImagePreviewPanel(
                          title: 'Original',
                          height: DeviceConstants.imageHeight,
                          imageBytes: _originalImageBytes
                        ),
                        const SizedBox(height: 16),
                        ImagePreviewPanel(
                          title: 'Preview',
                          height: DeviceConstants.imageHeight,
                          imageBytes: pipeline.previewBytes
                        )
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
          // ValueListenableBuilder<double>(
          //   valueListenable: ble.uploadProgress,
          //   builder: (context, value, _) {
          //     return StatusBar(
          //       state: session.state,
          //       progressListenable: ble.uploadProgress,
          //     );
          //   }
          // )
        ],
      )
    );
  }
}