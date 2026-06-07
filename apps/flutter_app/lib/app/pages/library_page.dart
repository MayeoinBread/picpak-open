import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_app/app/controller/library_controller.dart';
import 'package:flutter_app/app/services/ble_service.dart';
import 'package:flutter_app/app/services/device_session_service.dart';
import 'package:flutter_app/app/services/image_pipeline_controller.dart';
import 'package:flutter_app/app/state/device_session_state.dart';
import 'package:flutter_app/app/widgets/library/library_grid.dart';
import 'package:flutter_app/app/widgets/library/library_item.dart';
import 'package:flutter_app/app/widgets/library/slot_inspector.dart';
import 'package:flutter_app/app/widgets/library/slot_metadata.dart';
import 'package:flutter_app/app/widgets/popups/content_editor_dialog.dart';

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

  void updateSession(DeviceSessionState Function(DeviceSessionState current) updater) {
    setState(() { session.state = updater(session.state);});
  }

  final ImagePipelineController pipeline = ImagePipelineController();

  late StreamSubscription? sub;

  int? selectedSlot;

  double progress = 0.0;

  @override
  void initState() {
    debugPrint('Library initState');
    super.initState();

    controller.initialise(20);
  }

  @override
  void dispose() {
    debugPrint('Library dispose');
    sub?.cancel();
    super.dispose();
  }

  Future<void> _sync() async {
    await controller.syncLibrary(
      ble: ble,
      session: session,
      availableSlots: session.state.availableSlots,
      onSlotReady: (slot, thumb) {
        controller.updateSlot(
          slot: slot,
          exists: true,
          thumbnailBytes: thumb,
          metadata: const SlotMetadata(type: SlotContentType.image)
        );
      }
    );
  }

  Future<void> _onEdit(int slot) async {
    final item = controller.items[slot];

    await showDialog(
      context: context,
      builder: (_) => ContentEditorDialog(
        item: item,
        onSaved: (metadata, thumbnail) {
          debugPrint('SAVE slot=$slot');
          final mslot = slot;

          setState(() {
            selectedSlot = null;
          });

          controller.updateSlot(
            slot: mslot,
            exists: true,
            thumbnailBytes: thumbnail,
            metadata: metadata
          );
        }
      )
    );
  }

  Future<void> _onDelete(int slot) async {
    final item = controller.items[slot];
    final metadata = item.metadata;

    // TODO this messes up if an image was "pending upload"
    if (metadata.pendingAction == SlotPendingAction.delete) {
      controller.updateMetadata(slot, metadata.copyWith(pendingAction: SlotPendingAction.none));
    } else {
      controller.updateMetadata(slot, metadata.copyWith(pendingAction: SlotPendingAction.delete));
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('Library build selected=$selectedSlot items=${controller.items.length}');
    // return AnimatedBuilder(
      // animation: controller,
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final items = List<LibraryItem>.from(controller.items);
        return Row(
          children: [

            SizedBox(
              width: 300,
              child: ExcludeSemantics(
                child: SlotInspector(
                  onSync: _sync,
                  item: selectedSlot == null
                    ? null
                    : controller.items[selectedSlot!]
                ),
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: LibraryGrid(
                  // items: controller.items,
                  items: items,
                  selectedSlot: selectedSlot,
                  onSelected: (slot) {
                    setState(() {
                      selectedSlot = slot;
                    });
                  },
                  onEdit: _onEdit,
                  onDelete: _onDelete,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
} 