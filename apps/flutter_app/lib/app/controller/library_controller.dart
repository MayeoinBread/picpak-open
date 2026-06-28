import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:picpak_core/picpak_core.dart';
import 'package:picpak_open/app/repositories/image_repository.dart';
import 'package:picpak_open/app/repositories/slot_repository.dart';
import 'package:picpak_open/app/services/device_session_service.dart';
import 'package:picpak_open/app/state/device_session_state.dart';
import 'package:picpak_open/app/widgets/library/library_item.dart';
import 'package:picpak_open/app/widgets/library/slot_metadata.dart';
import 'package:picpak_open/transport/ble_manager.dart';
import 'package:picpak_image/picpak_image.dart';
import 'package:picpak_protocol/picpak_protocol.dart';

class LibraryController extends ChangeNotifier {

  final SlotRepository repository = SlotRepository();

  Map<int, LibraryItem> items = {};

  double progress = 0;

  bool syncing = false;

  void initialise(int slotCount) {
    items.clear();

    for (int i = 1; i <= slotCount; i++) {
      items[i] = LibraryItem(
          slot: i,
          exists: false,
          thumbnailBytes: null,
          metadata: SlotMetadata(type: SlotContentType.empty)
        );
    }

    notifyListeners();
  }

  void updateSlot({
    required int slot,
    required bool exists,
    Uint8List? thumbnailBytes,
    SlotMetadata? metadata
  }) {
    final current = items[slot]!;
    items[slot] = current.copyWith(
      exists: exists,
      thumbnailBytes: thumbnailBytes,
      metadata: metadata
    );

    notifyListeners();
  }

  Future<void> loadFromDatabase() async {
    items = await repository.loadLibrary();

    notifyListeners();
  }

  Future<List<LibraryItem>> getPendingItems() async {
    return items.values.where((item) => item.metadata.pendingAction != SlotPendingAction.none).toList();
  }

  Future<void> pullFromDevice({
    required BleManager ble,
    required DeviceSessionService session,
    required List<int> availableSlots,
    required void Function(int slot, bool isDirty) onSlotReady
  }) async {
    
    session.state = session.state.copyWith(
      transfer: TransferState.downloading,
      progress: 0,
      activeSlot: null
    );

    final total = availableSlots.length;

    for (int i=0; i<total; i++) {
      final slot = availableSlots[i];

      session.state = session.state.copyWith(
        transfer: TransferState.downloading,
        activeSlot: slot,
        progress: i / total
      );

      final deviceHash = await ble.requestSlotHash(slot);

      final imageId = items[slot]!.metadata.imageId;
      String? localHash;
      if (imageId != null) {
        final stored = await ImageRepository().getImage(imageId);
        localHash = stored?.deviceHash;
      }

      final isDirty = localHash != deviceHash;
      debugPrint('isDirty: $isDirty - app hash: $localHash - device hash: $deviceHash');
      
      onSlotReady(slot, isDirty);
    }

    session.state = session.state.copyWith(
      transfer: TransferState.idle,
      progress: 0
    );
  }

  Future<String> pushToDevice({
    required BleManager ble,
    required DeviceSessionService session
  }) async {
    final dirtySlots = await getPendingItems();

    List<int> updates = [0, 0, 0];

    for (final dirtySlot in dirtySlots) {
      final slot = dirtySlot.slot;

      if (dirtySlot.metadata.pendingAction == SlotPendingAction.delete) {
        // TODO see what we get back for a Hash if an image doesn't exist/is deleted so we can check properly
        await ble.deleteImage(slot);
        await SlotRepository().saveSlot(slot: slot, imageId: null, metadata: SlotMetadataDefaults.empty(slot));
        items[slot] = items[slot]!.copyWith(exists: false, thumbnailBytes: null, metadata: SlotMetadataDefaults.empty(slot));
        notifyListeners();
        updates[0] += 1;
      } else if (dirtySlot.metadata.pendingAction == SlotPendingAction.upload) {

        final slotType = dirtySlot.metadata.type;
        final imageId = dirtySlot.metadata.imageId;

        Uint8List? packed;

        switch (slotType) {
          case SlotContentType.image:
          case SlotContentType.generated:
            if (imageId == null) continue;
            packed = await ImageRepository().loadProcessedBytes(imageId);
            if (packed == null) continue;
            
            // TODO might need to do generated separate as it might need to be flipped still?
            break;
          
          case SlotContentType.qr:
            final image = QrRenderer.renderForDevice(
              qrType: dirtySlot.metadata.qrType,
              text: dirtySlot.metadata.text,
              wifiSsid: dirtySlot.metadata.wifiSsid,
              wifiPassword: dirtySlot.metadata.wifiPassword,
              wifiSecurity: dirtySlot.metadata.wifiSecurity
            );

            final pipeline = ImagePipeline();
            final prepared = pipeline.prepareBaseImage(image, dirtySlot.metadata.fit, dirtySlot.metadata.cropRect);

            final result = await compute(
              runPipelineIsolate,
              PipelineRequest(
                workingImage: prepared,
                filter: ImageFilter.normal,
                simulateDevice: false,
                width: DeviceConstants.imageWidth,
                height: DeviceConstants.imageHeight,
                fit: FitStrategy.contain,
                dither: DitherMode.none,
                adjustments: ImageAdjustments(),
                paletteBias: PaletteBias()
              )
            );

            packed = FramebufferPacker.pack(flipVertical(result.framebuffer));
            break;
          
          case SlotContentType.note:
            final note = NoteRenderer.render(
              text: dirtySlot.metadata.text!,
              w: DeviceConstants.imageWidth,
              h: DeviceConstants.imageHeight
            );

            final pipeline = ImagePipeline();
            final prepared = pipeline.prepareBaseImage(note, dirtySlot.metadata.fit, dirtySlot.metadata.cropRect);

            final result = await compute(
              runPipelineIsolate,
              PipelineRequest(
                workingImage: prepared,
                filter: ImageFilter.normal,
                simulateDevice: false,
                width: DeviceConstants.imageWidth,
                height: DeviceConstants.imageHeight,
                fit: FitStrategy.contain,
                dither: DitherMode.none,
                adjustments: ImageAdjustments(),
                paletteBias: PaletteBias()
              )
            );

            packed = FramebufferPacker.pack(flipVertical(result.framebuffer));
            break;

          case SlotContentType.empty:
            await ble.deleteImage(slot);
            await SlotRepository().saveSlot(slot: slot, imageId: null, metadata: SlotMetadataDefaults.empty(slot));
            continue;
        }

        final packets = UploadSession.build(imageNumber: slot, packedImageData: packed);

        await ble.sendImage(packets);
        await ble.sendMd5Trigger(imageNumber: slot, imageData: packed);

        final deviceHash = await ble.requestSlotHash(slot);

        final appHash = md5.convert(packed).toString();

        if (deviceHash == appHash) {
          final updatedMetadata = dirtySlot.metadata.copyWith(syncState: SlotSyncState.clean, pendingAction: SlotPendingAction.none);
          await SlotRepository().saveSlot(slot: slot, imageId: imageId, metadata: updatedMetadata);
          final current = items[slot]!;
          items[slot] = current.copyWith(metadata: updatedMetadata);
          updates[1] += 1;
        } else {
          debugPrint("Uploaded hash does not match expected");
          updates[2] += 1;
        }
        notifyListeners();

        await Future.delayed(const Duration(milliseconds: 100));
      }

    }

    return "Updated: ${updates[1]} - Failed: ${updates[2]} - Deleted: ${updates[0]}";
  }

  void updateMetadata(int slot, SlotMetadata metadata) {
    final current = items[slot]!;
    items[slot] = current.copyWith(metadata: metadata);
    notifyListeners();
  }
}