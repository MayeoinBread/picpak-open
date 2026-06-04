import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_app/app/widgets/library/slot_metadata.dart';
import 'package:flutter_app/app/widgets/popups/post_it_editor.dart';

class SlotTile extends StatelessWidget {
  final Uint8List? thumbnail;

  final bool selected;

  final bool exists;

  final VoidCallback onTap;

  final VoidCallback? onLongPress;

  final SlotMetadata metadata;

  const SlotTile({
    super.key,
    required this.thumbnail,
    required this.selected,
    required this.exists,
    required this.onTap,
    required this.metadata,
    this.onLongPress
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
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
            exists && thumbnail != null
              ? Image.memory(
                  thumbnail!,
                  fit: BoxFit.cover,
                )
              : const Center(
                  child: Icon(Icons.image_not_supported),
                ),
            if (metadata.syncState == SlotSyncState.modified)
              Positioned(
                top: 4,
                right: 4,
                child: Icon (
                  Icons.circle,
                  size: 12,
                  color: Colors.orange
                )
              )
          ]
        )
      )
    );
  }
}