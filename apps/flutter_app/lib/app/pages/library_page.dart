import 'dart:async';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:picpak_open/app/controller/library_controller.dart';
import 'package:picpak_open/app/repositories/image_repository.dart';
import 'package:picpak_open/app/repositories/slot_repository.dart';
import 'package:picpak_open/app/services/ble_service.dart';
import 'package:picpak_open/app/services/device_session_service.dart';
import 'package:picpak_open/app/services/image_pipeline_controller.dart';
import 'package:picpak_open/app/services/thumbnail_service.dart';
import 'package:picpak_open/app/state/device_session_state.dart';
import 'package:picpak_open/app/widgets/library/library_grid.dart';
import 'package:picpak_open/app/widgets/library/slot_inspector.dart';
import 'package:picpak_open/app/widgets/library/slot_metadata.dart';
import 'package:picpak_open/app/widgets/popups/content_editor_dialog.dart';

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
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadFromDatabase();
    });
  }

  @override
  void dispose() {
    sub?.cancel();
    super.dispose();
  }

  Future<void> _sync() async {
    await controller.pullFromDevice(
      ble: ble,
      session: session,
      availableSlots: session.state.availableSlots,
      onSlotReady: (slot, isDirty) async {
        final item = controller.items[slot]!;

        final newMetadata = item.metadata.copyWith(
          pendingAction: isDirty ? SlotPendingAction.upload : SlotPendingAction.none
        );

        controller.updateSlot(
          slot: slot,
          exists: true,
          metadata: newMetadata
        );
      }
    );

    final repo = SlotRepository();
    for (final entry in controller.items.entries) {
      final slot = entry.key;
      final item = entry.value;

      await repo.saveSlot(
        slot: slot,
        imageId: item.metadata.imageId,
        metadata: item.metadata
      );
    }
  }

  Future<void> _onEdit(int slot) async {
    final item = controller.items[slot];

    await showDialog(
      context: context,
      builder: (_) => ContentEditorDialog(
        item: item!,
        onSaved: (editorResult) async {
          final mslot = slot;

          final previewMd5 = md5.convert(editorResult.packedBytes).toString();

          if (item.exists) {
            final existingImage = await ImageRepository().getImage(item.metadata.imageId!);
            if (previewMd5 == existingImage?.deviceHash){
              return;
            }
          }

          final thumbnail = ThumbnailService.createFromBytes(editorResult.previewBytes);
    
          final image = await ImageRepository().storeImage(
            originalBytes: editorResult.originalBytes,
            thumbnailBytes: thumbnail,
            packedBytes: editorResult.packedBytes
          );

          final newMetadata = editorResult.metadata.copyWith(
            imageId: image.id,
            syncState: SlotSyncState.uploading,
            pendingAction: SlotPendingAction.upload
          );

          controller.updateSlot(
            slot: mslot,
            exists: true,
            thumbnailBytes: thumbnail,
            metadata: newMetadata
          );

          await SlotRepository().saveSlot(
            slot: slot,
            imageId: image.id,
            metadata: newMetadata
          );
        }
      )
    );
  }

  Future<void> _onDelete(int slot) async {
    final item = controller.items[slot];
    final metadata = item!.metadata;

    final newAction = metadata.pendingAction == SlotPendingAction.delete
        ? SlotPendingAction.none
        : SlotPendingAction.delete;

    final updatedMetadata = metadata.copyWith(
      pendingAction: newAction,
    );

    controller.updateMetadata(slot, updatedMetadata);

    await SlotRepository().saveSlot(
      slot: slot,
      imageId: metadata.imageId,
      metadata: updatedMetadata,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return Row(
          children: [
            SizedBox(
              width: 300,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  SlotInspector(
                    onSync: _sync,
                    item: selectedSlot == null
                      ? null
                      : controller.items[selectedSlot!]
                  ),
                  ElevatedButton(
                    onPressed: (() async {
                      final updateMessage = await controller.pushToDevice(ble: ble, session: session);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(updateMessage))
                        );
                      }
                    }),
                    child: const Text("Push Updates")
                  ),
                  ElevatedButton(
                    onPressed: (() async {
                      final deleted = await ImageRepository().cleanupUnusedImages();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Deleted $deleted unused images'))
                        );
                      }
                    }),
                    child: const Text("Cleanup Storage")
                  ),
                ],
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