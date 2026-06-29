import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide ConnectionState;
import 'package:picpak_open/app/services/ble_service.dart';
import 'package:picpak_open/app/services/dashboard_actions.dart';
import 'package:picpak_open/app/services/device_session_service.dart';
import 'package:picpak_open/app/services/image_pipeline_controller.dart';
import 'package:picpak_open/app/state/device_session_state.dart';
import 'package:picpak_open/app/widgets/common/image_preview_panel.dart';
import 'package:picpak_open/app/widgets/controls/dithering_controls.dart';
import 'package:picpak_open/app/widgets/controls/image_adjustment_controls.dart';
import 'package:picpak_open/app/widgets/controls/filter_controls.dart';
import 'package:picpak_open/app/widgets/device/device_actions_panel.dart';
import 'package:picpak_open/app/widgets/device/device_info_card.dart';
import 'package:image/image.dart' as img;
import 'package:picpak_core/picpak_core.dart';
import 'package:picpak_image/picpak_image.dart';
import 'package:picpak_protocol/picpak_protocol.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {

  DitherMode algorithm = DitherMode.atkinson;
  ImageAdjustments adjustments = ImageAdjustments();
  PaletteBias paletteBias = PaletteBias();

  final session = DeviceSessionService.instance;

  FitStrategy _fitStrategy = FitStrategy.crop;
  ImageFilter _filter = ImageFilter.normal;
  bool _simulateDeviceScreen = false;

  final ImagePipelineController pipeline = ImagePipelineController();
  Uint8List? _originalImageBytes;

  final ble = BleService.instance.manager;

  late StreamSubscription sub;

  void updateSession(DeviceSessionState Function(DeviceSessionState current) updater) {
    setState(() { session.state = updater(session.state);});
  }

  @override
  void initState() {
    super.initState();

    sub = ble.imageStream.stream.listen((fb) {
      if (!mounted) return;

      pipeline.framebuffer = fb;
      pipeline.previewBytes = Uint8List.fromList(
        img.encodePng(PanelRerender.renderFramebuffer(fb))
      );

      setState(() {
        session.state = session.state.copyWith(
          transfer: TransferState.idle,
          progress: 0.0,
          activeSlot: null
        );
      });
    });

    ble.onDeviceInfo = (info) {
      if (mounted) {
        debugPrint("DASH PAGE: onDeviceInfo, mounted");
        setState(() {
        session.state = session.state.copyWith(
          batteryPercent: info.battery,
          firmware: info.firmware
        );
      });
      }
    };

    ble.onDeviceSettings = (settings) {
      if (mounted) {
        debugPrint("DASH PAGE: onDeviceSettings, mounted");
        setState(() {
          session.state = session.state.copyWith(
            settings: settings
          );
        });
      }
    };

    ble.onSlotList = (slots) {
      final safeActive = session.state.activeSlot;

      setState(() {
        session.state = session.state.copyWith(
          availableSlots: slots,
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
  }

  @override
  void dispose() {
    sub.cancel();
    super.dispose();
  }

  Future<void> _prepareWorkingImage() async {
    final bytes = _originalImageBytes;
    if (bytes == null) return;

    await pipeline.prepare(bytes, _fitStrategy, null);
  }

  Future<void> _reprocess() async {
    final bytes = _originalImageBytes;
    if (bytes == null) return;

    await pipeline.process(
      dither: algorithm,
      filter: _filter,
      simulateDevice: _simulateDeviceScreen,
      fit: _fitStrategy,
      adjustments: adjustments,
      paletteBias: paletteBias
    );
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

  List<Widget> _buildDesktopLayout(BuildContext context) {
    return [
      SizedBox(width: 300, child: _leftPanel(context)),
      _centerPanel(context),
      SizedBox(width: 340, child: _rightPanel(context))
    ];
  }

  Widget _buildMobileLayout(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _leftPanel(context),
          _centerPanel(context),
          _rightPanel(context)
        ],
      )
    );
  }

  Widget _leftPanel(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DeviceInfoCard(state: session.state),
          const SizedBox(height: 16),
          DeviceActionsPanel(
            activeSlot: session.state.activeSlot,
            settings: session.state.settings,
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
            onSettingsChanged: (settings) async {
              await ble.setDeviceSettings(settings);
            },
          )
        ],
      ),
    );
  }

  Widget _centerPanel(BuildContext context) {
    return Column(
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
    );
  }

  Widget _rightPanel(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
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
          FilterControls(
            selectedFilter: _filter,
            onFilterChanged: (filter) async {
              setState(() {
                _filter = filter;
              });
              _reprocess();
            }
          )
        ]
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;
    return Scaffold(
      body:  isMobile
              ? _buildMobileLayout(context)
              : Row(children: _buildDesktopLayout(context))
    );
  }
}