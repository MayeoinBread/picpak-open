import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_app/app/controller/library_controller.dart';
import 'package:flutter_app/app/services/ble_service.dart';
import 'package:flutter_app/app/services/device_session_service.dart';
import 'package:flutter_app/app/services/image_pipeline_controller.dart';
import 'package:flutter_app/app/state/device_session_state.dart';
import 'package:flutter_app/app/widgets/common/status_bar.dart';
import 'package:flutter_app/app/widgets/library/library_grid.dart';
import 'package:flutter_app/app/widgets/library/slot_inspector.dart';
import 'package:image/image.dart' as img;
import 'package:picpak_image/picpak_image.dart';

class LibraryPage extends StatefulWidget {

  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() =>
      _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {

  final controller = LibraryController();

  final ble = BleService.instance.manager;

  final session = DeviceSessionService.instance;

  late final void Function(PaletteFramebuffer) _imageListener;

  void updateSession(DeviceSessionState Function(DeviceSessionState current) updater) {
    setState(() { session.state = updater(session.state);});
  }

  final ImagePipelineController pipeline = ImagePipelineController();

  int? selectedSlot;

  final Map<int, Uint8List> thumbnails = {};
  double progress = 0.0;

  @override
  void initState() {
    super.initState();

    controller.initialise(700);

    _imageListener = (fb) {
      if (!mounted) return;

      pipeline.framebuffer = fb;
      pipeline.previewBytes = Uint8List.fromList(
        img.encodePng(PanelRerender.renderFramebuffer(fb))
      );

      setState(() {
        // session.update((s) => s.copyWith(
        //   transfer: TransferState.idle,
        //   progress: 0,
        //   activeSlot: null
        // ));
        debugPrint("Library BLE event fired");
      });
    };

    ble.addImageListener(_imageListener);
  }

  // @override
  // void dispose() {
  //   ble.removeImageListener(_imageListener);
  //   super.dispose();
  // }

  Future<void> _sync() async {
    await controller.syncLibrary(
      ble: ble,
      availableSlots: session.state.availableSlots,
      onSlotReady: (slot, thumb) {
        setState(() {
          thumbnails[slot] = thumb;
        });
      },
      onProgress: (p) {
        setState(() {
          progress = p;
        });
      }
    );
  }

  @override
  Widget build(BuildContext context) {

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {

        return Row(
          children: [

            SizedBox(
              width: 300,
              child: SlotInspector(
                onSync: _sync,
                item: selectedSlot == null
                  ? null
                  : controller.items[selectedSlot!]
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: LibraryGrid(
                  items: controller.items,
                  selectedSlot: selectedSlot,
                  onSelected: (slot) {
                    setState(() {
                      selectedSlot = slot;
                    });
                  },
                ),
              ),
            ),

            // ValueListenableBuilder<double>(
            //   valueListenable: ble.uploadProgress,
            //   builder: (context, value, _) {
            //     return StatusBar(
            //       state: session.state,
            //       progressListenable: ble.uploadProgress,
            //     );
            //   }
            // )
            // StatusBar(state: session.state, progressListenable: ble.uploadProgress)
          ],
        );
      },
    );
  }
}