import 'package:flutter/material.dart';
import 'package:picpak_open/app/widgets/library/library_item.dart';

import 'slot_tile.dart';

class LibraryGrid extends StatelessWidget {
  final List<LibraryItem> items;
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
    debugPrint('LibraryGrid build'
    'items-${items.length}'
    'selected-$selectedSlot');
    // return GridView.builder(
    //   itemCount: items.length,
    //   gridDelegate:
    //       const SliverGridDelegateWithFixedCrossAxisCount(
    //     crossAxisCount: 5,
    //     crossAxisSpacing: 8,
    //     mainAxisSpacing: 8,
    //     childAspectRatio: 1.0
    //   ),
    //   itemBuilder: (context, index) {

    //     final item = items[index];

    //     return SlotTile(
    //       key: ValueKey(item.slot),
    //       thumbnail: item.thumbnailBytes,
    //       exists: item.exists,
    //       selected: selectedSlot == item.slot,
    //       metadata: item.metadata,
    //       onTap: () => onSelected(item.slot),
    //       onEdit: () => onEdit(item.slot),
    //       onDelete: () => onDelete(item.slot)
    //     );
    //   },
    // );
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemSize = 120.0;

        return SingleChildScrollView(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(items.length, (index) {
              final item = items[index];

              return SizedBox(
                width: itemSize,
                height: itemSize,
                child: SlotTile(
                  key: ValueKey(item.slot),
                  thumbnail: item.thumbnailBytes,
                  exists: item.exists,
                  selected: selectedSlot == item.slot,
                  metadata: item.metadata,
                  onTap: () => onSelected(item.slot),
                  onEdit: () => onEdit(item.slot),
                  onDelete: () => onDelete(item.slot),
                )
              );
            })
          )
        );
      }
    );
  }
}