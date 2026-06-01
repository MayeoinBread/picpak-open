import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_app/app/services/thumbnail_service.dart';
import 'package:flutter_app/app/widgets/library/library_item.dart';
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
          thumbnail: null,
          type: SlotContentType.empty,
        ),
      );
    }

    notifyListeners();
  }

  void updateSlot({
    required int slot,
    required bool exists,
    Uint8List? thumbnail,
  }) {
    items[slot] = items[slot].copyWith(
      exists: exists,
      thumbnail: thumbnail,
      type: exists
          ? SlotContentType.image
          : SlotContentType.empty,
    );

    notifyListeners();
  }

  void updateProgress(double value) {
    progress = value;
    notifyListeners();
  }

  Future<void> syncLibrary({
    required BleManager ble,
    required List<int> availableSlots,
    required void Function(int slot, Uint8List thumbnail) onSlotReady,
    required void Function(double progress) onProgress
  }) async {
    final total = availableSlots.length;
    if (total == 0) return;

    for (int i=0; i<total; i++) {
      final exists = availableSlots.contains(i);

      if (!exists) {
        onProgress((i + 1) / total);
        continue;
      }

      final framebuffer = await ble.downloadFramebuffer(i);

      final png = img.encodePng(
        PanelRerender.renderFramebuffer(framebuffer)
      );

      onSlotReady(i, Uint8List.fromList(png));

      onProgress((i + 1) / total);
    }
  }
}