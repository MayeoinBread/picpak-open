import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:picpak_open/app/widgets/library/slot_metadata.dart';

class SlotTile extends StatelessWidget {
  final Uint8List? thumbnail;

  final bool selected;

  final bool exists;

  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  final SlotMetadata metadata;

  const SlotTile({
    super.key,
    required this.thumbnail,
    required this.selected,
    required this.exists,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.metadata
  });

  void _showMenu(BuildContext context, TapDownDetails details) async {
    final result = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        details.globalPosition.dx,
        details.globalPosition.dy,
        details.globalPosition.dx,
        details.globalPosition.dy,
      ),
      items: const [
        PopupMenuItem(
          value: 'edit',
          child: Text('Add/Edit')
        ),
        PopupMenuItem(
          value: 'delete',
          child: Text('Delete')
        )
      ]
    );
    if (result == 'edit') {
      onEdit();
    } else if (result == 'delete') {
      onDelete();
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('Tile build selected=$selected exists=$exists thumb=${thumbnail?.length}');
    final indicator = getStatusIndicator(metadata);
    return GestureDetector(
      onTap: onTap,
      onLongPress: onEdit,
      onSecondaryTapDown: (details) {
        Future.microtask(() => _showMenu(context, details));
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: selected
              ? Colors.blue
              : Colors.grey,
            width: selected ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            // SizedBox.expand(
            AspectRatio(
              aspectRatio: 1,
              child: exists && thumbnail != null
                ? Opacity(
                    opacity: metadata.pendingAction == SlotPendingAction.delete ? 0.4 : 1.0,
                    child: Image.memory(
                      thumbnail!,
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                    )
                  )
                : const Center(child: Icon(Icons.image_not_supported_outlined))
            ),
            if (indicator != null)
              Positioned(
                top: 4, right: 4,
                child: Icon(
                  indicator.icon,
                  size: indicator.size,
                  color: indicator.colour
                )
              )
          ]
        )
      )
    );
  }
}