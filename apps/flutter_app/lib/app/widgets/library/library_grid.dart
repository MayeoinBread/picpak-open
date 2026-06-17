import 'package:flutter/material.dart';
import 'package:picpak_open/app/widgets/library/library_item.dart';

import 'slot_tile.dart';

class LibraryGrid extends StatelessWidget {
  final Map<int, LibraryItem> items;
  final int? selectedSlot;
  final ValueChanged<int> onSelected;

  final void Function(int slot) onEdit;
  final Future<void> Function(int slot) onDelete;

  const LibraryGrid({
    super.key,
    required this.items,
    required this.selectedSlot,
    required this.onSelected,
    required this.onEdit,
    required this.onDelete
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemSize = 120.0;

        final slots = items.keys.toList()..sort();

        return SingleChildScrollView(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: slots.map((slot) {
              final item = items[slot]!;

              return SizedBox(
                width: itemSize,
                height: itemSize,
                child: SlotTile(
                  key: ValueKey(slot),
                  thumbnail: item.thumbnailBytes,
                  exists: item.exists,
                  selected: selectedSlot == slot,
                  metadata: item.metadata,
                  onTap: () => onSelected(slot),
                  onEdit: () => onEdit(slot),
                  onDelete: () => onDelete(slot),
                )
              );
            }).toList()
          )
        );
      }
    );
  }
}