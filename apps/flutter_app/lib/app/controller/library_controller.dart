import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_app/app/services/device_session_service.dart';
import 'package:flutter_app/app/services/thumbnail_service.dart';
import 'package:flutter_app/app/state/device_session_state.dart';
import 'package:flutter_app/app/widgets/library/library_item.dart';
import 'package:flutter_app/app/widgets/library/slot_metadata.dart';
import 'package:flutter_app/transport/ble_manager.dart';
import 'package:image/image.dart' as img;
import 'package:picpak_image/picpak_image.dart';

class LibraryController extends ChangeNotifier {

  final List<LibraryItem> items = [];

  double progress = 0;

  bool syncing = false;

  void initialise(int slotCount) {
    items.clear();

    for (int i = 0; i < slotCount; i++) {
      items.add(
        LibraryItem(
          slot: i,
          exists: false,
          thumbnailBytes: null,
          metadata: SlotMetadata(type: SlotContentType.empty)
        ),
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
    items[slot] = items[slot].copyWith(
      exists: exists,
      thumbnailBytes: thumbnailBytes,
      metadata: metadata
    );

    notifyListeners();
  }

  Future<void> syncLibrary({
    required BleManager ble,
    required DeviceSessionService session,
    required List<int> availableSlots,
    required void Function(int slot, Uint8List thumbnail) onSlotReady
  }) async {
    
    session.state = session.state.copyWith(
      transfer: TransferState.downloading,
      progress: 0,
      activeSlot: null
    );

    debugPrint("Syncing from device");
    final total = availableSlots.length;

    for (int i=0; i<total; i++) {
      final slot = availableSlots[i];

      session.state = session.state.copyWith(
        transfer: TransferState.downloading,
        activeSlot: slot,
        progress: i / total
      );

      final framebuffer = await ble.downloadFramebuffer(slot);

      final smallFb = PaletteFramebuffer.downscale(framebuffer, 300, 225);

      final image = PanelRerender.renderFramebuffer(smallFb);
      // final thumbnailBytes = ThumbnailService.createFromImage(image);
      final thumbnailBytes = Uint8List.fromList(img.encodePng(image));

      debugPrint('Synced bytes: ${thumbnailBytes.length}');
      
      onSlotReady(slot - 1, thumbnailBytes);
    }

    session.state = session.state.copyWith(
      transfer: TransferState.idle,
      progress: 0
    );
  }

  void updateMetadata(int slot, SlotMetadata metadata) {
    items[slot] = items[slot].copyWith(metadata: metadata);
    notifyListeners();
  }
}