import 'dart:typed_data';

import 'package:flutter/material.dart';

class SlotTile extends StatelessWidget {
  final Uint8List? thumbnail;

  final bool selected;

  final bool exists;

  final VoidCallback onTap;

  const SlotTile({
    super.key,
    required this.thumbnail,
    required this.selected,
    required this.exists,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: selected
              ? Colors.blue
              : Colors.grey,
            width: selected ? 2 : 1,
          ),
        ),
        child: exists && thumbnail != null
          ? Image.memory(
              thumbnail!,
              fit: BoxFit.cover,
            )
          : const Center(
              child: Icon(Icons.image_not_supported),
            ),
      ),
    );
  }
}