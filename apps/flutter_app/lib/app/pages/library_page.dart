import 'dart:async';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:picpak_open/app/controller/library_controller.dart';
import 'package:picpak_open/app/data/models/editor_result.dart';
import 'package:picpak_open/app/repositories/image_repository.dart';
import 'package:picpak_open/app/services/ble_service.dart';
import 'package:picpak_open/app/services/device_session_service.dart';
import 'package:picpak_open/app/services/image_pipeline_controller.dart';
import 'package:picpak_open/app/services/thumbnail_service.dart';
import 'package:picpak_open/app/state/device_session_state.dart';
import 'package:picpak_open/app/widgets/library/album_selector.dart';
import 'package:picpak_open/app/widgets/library/library_grid.dart';
import 'package:picpak_open/app/widgets/library/library_item.dart';
import 'package:picpak_open/app/widgets/library/slot_inspector.dart';
import 'package:picpak_open/app/widgets/library/slot_metadata.dart';
import 'package:picpak_open/app/widgets/popups/content_editor_dialog.dart';
import 'package:picpak_open/app/widgets/popups/content_editor_screen.dart';

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

    controller.init();

    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   controller.loadFromDatabase();
    // });
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

    controller.commitAllSlots();
  }

  Future<void> _onEdit(int slot) async {
    final item = controller.items[slot];
    if (item == null) return;

    final result = await _openEditor(context, slot, item);
    if (result == null) return;

    await _handleEditorResult(slot, item, result);
  }

  Future<EditorResult?> _openEditor(
    BuildContext context, int slot, LibraryItem item
  ) {
    final isMobile = MediaQuery.sizeOf(context).width < 700;

    if (isMobile) {
      return Navigator.push<EditorResult>(
        context,
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => ContentEditorScreen(
            item: item,
            onSaved: (result) => Navigator.pop(context, result)
          )
        )
      );
    }

    return showDialog<EditorResult>(
      context: context,
      builder: (_) => Dialog(
        child: SizedBox(
          width: 900,
          height: 700,
          child: ContentEditorDialog(
            item: item,
            onSaved: (result) => Navigator.pop(context, result),
          )
        )
      )
    );
  }

  Future<void> _handleEditorResult(int slot, LibraryItem item, EditorResult editorResult) async {
    final previewMd5 = md5.convert(editorResult.packedBytes).toString();

    if (item.exists) {
      final existingImage = await ImageRepository().getImage(item.metadata.imageId!);
      if (previewMd5 == existingImage?.deviceHash){
        return;
      }
    }
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
      slot: slot,
      exists: true,
      thumbnailBytes: thumbnail,
      metadata: newMetadata
    );

    controller.commitSlot(slot);
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

    controller.commitSlot(slot);
  }

  Widget _buildGrid(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: LibraryGrid(
        items: controller.items,
        selectedSlot: selectedSlot,
        onSelected: (slot) { setState(() => selectedSlot = slot);},
        onEdit: _onEdit, onDelete: _onDelete)
    );
  }

  Widget _buildDesktopSidebar(BuildContext context) {
    return SizedBox(
      width: 200,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          AlbumSelector(
            albums: controller.albums,
            currentAlbum: controller.currentAlbum!,
            onAlbumSelected: controller.onAlbumSelected,
            onCreateAlbum: controller.onCreateAlbum,
            onRenameAlbum: controller.onRenameAlbum,
            onDeleteAlbum: controller.onDeleteAlbum
          ),
          SlotInspector(item: selectedSlot == null ? null : controller.items[selectedSlot], onSync: _sync),
          ElevatedButton(onPressed: () async {await controller.pushToDevice(ble: ble, session: session);}, child: const Text('Push Updates')),
          ElevatedButton(
            onPressed: () async {
              final deleted = await ImageRepository().cleanupUnusedImages();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Deleted $deleted unused images'))
                );
              }
            },
            child: const Text('Cleanup Storage')
          )
        ]
      )
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Row (
      children: [
        _buildDesktopSidebar(context),
        Expanded(child: _buildGrid(context))
      ]
    );
  }

  Widget _buildMobileLayout(BuildContext context ) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: LibraryGrid(
          items: controller.items,
          selectedSlot: selectedSlot,
          onSelected: (slot) {
            setState(() => selectedSlot = slot);
            if (controller.items[slot] != null) {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                builder: (_) {
                  return FractionallySizedBox(
                    heightFactor: 0.4,
                    child: SlotInspector(item: controller.items[slot], onSync: _sync)
                  );
                }
              );
            }
          },
          onEdit: _onEdit, onDelete: _onDelete
        )
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await controller.pushToDevice(ble: ble, session: session);
        },
        icon: const Icon(Icons.upload),
        label: const Text('Push')
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 700;

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (!controller.initialised) {
          return const Center(
            child: CircularProgressIndicator()
          );
        }
        return isMobile
          ? _buildMobileLayout(context)
          : Scaffold(
              body: _buildDesktopLayout(context)
            );
      },
    );
  }
} 