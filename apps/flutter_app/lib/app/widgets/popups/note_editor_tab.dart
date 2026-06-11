import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:picpak_open/app/services/thumbnail_service.dart';
import 'package:picpak_open/app/widgets/common/image_preview_panel.dart';
import 'package:picpak_open/app/widgets/library/library_item.dart';
import 'package:picpak_open/app/widgets/library/slot_metadata.dart';
import 'package:image/image.dart' as img;
import 'package:picpak_core/picpak_core.dart';
import 'package:picpak_image/picpak_image.dart';

class NoteEditorTab extends StatefulWidget {
  final LibraryItem item;

  final void Function(
    SlotMetadata metadata,
    Uint8List thumbnailBytes
  ) onSaved;

  const NoteEditorTab({
    super.key,
    required this.item,
    required this.onSaved
  });

  @override
  State<NoteEditorTab> createState() => _NoteEditorTabState();
}

class _NoteEditorTabState extends State<NoteEditorTab> {
  late final TextEditingController textController;

  Uint8List? previewBytes;

  @override
  void initState() {
    super.initState();
    textController = TextEditingController(
      text: widget.item.metadata.type == SlotContentType.note ? widget.item.metadata.text ?? '' : ''
    );
  }

  void _generatePreview() {
    final image = NoteRenderer.render(
      text: textController.text,
      w: DeviceConstants.imageWidth,
      h: DeviceConstants.imageHeight
    );

    setState(() {
      previewBytes = Uint8List.fromList(img.encodePng(image));
    });
  }

  void _save() {
    final image = NoteRenderer.render(
      text: textController.text,
      w: DeviceConstants.imageWidth,
      h: DeviceConstants.imageHeight
    );

    final thumbnail = ThumbnailService.createFromImage(image);

    final metadata = SlotMetadata(
      type: SlotContentType.note,
      pendingAction: SlotPendingAction.upload,
      text: textController.text
    );

    widget.onSaved(metadata, thumbnail);

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: TextField(
                    controller: textController,
                    maxLines: null,
                    expands: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder()
                    )
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    ElevatedButton(onPressed: _generatePreview, child: const Text('Preview')),
                    const SizedBox(width: 8),
                    ElevatedButton(onPressed: _save, child: const Text('Save'))
                  ]
                )
              ]
            )
          ),

          const SizedBox(width: 16),

          Expanded(
            child: previewBytes == null
              ? const Center(child: Text('No Preview'))
              : ImagePreviewPanel(height: DeviceConstants.imageHeight, imageBytes: previewBytes!)
          )
        ]
      )
    );
  }
}
