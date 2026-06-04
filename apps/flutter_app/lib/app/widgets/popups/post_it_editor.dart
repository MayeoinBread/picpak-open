import 'dart:ffi';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_app/app/widgets/common/image_preview_panel.dart';
import 'package:flutter_app/app/widgets/library/slot_metadata.dart';
import 'package:image/image.dart' as img;
import 'package:picpak_core/picpak_core.dart';
import 'package:picpak_image/picpak_image.dart';

Future<SlotMetadata?> showPostItEditor(
  BuildContext context,
  SlotMetadata metadata
) async {
  final textController = TextEditingController(text: metadata.text ?? '');

  Uint8List? preview;

  return showDialog<SlotMetadata>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Edit Post-it'),
            content: SizedBox(
              width: 800,
              height: 450,
              child: Row(
                children: [
                  // LEFT
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: textController,
                            maxLines: null,
                            expands: true,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder()
                            ),
                          )
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () {
                            final image = NoteRenderer.render(
                              text: textController.text,
                              w: DeviceConstants.imageWidth,
                              h: DeviceConstants.imageHeight
                            );

                            setState(() {
                              preview = Uint8List.fromList(img.encodePng(image));
                            });
                          },
                          child: const Text('Preview')
                        ),
                      ]
                    )
                  ),
                  const SizedBox(width: 16),

                  // RIGHT
                  Expanded(
                    child: preview == null
                      ? const Center(child: Text('No Preview'))
                      : ImagePreviewPanel(title: null, height: DeviceConstants.imageHeight, imageBytes: preview!)
                  )
                ]
              )
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Cancel')
              ),

              ElevatedButton(
                onPressed: () {
                  Navigator.pop(
                    context,
                    metadata.copyWith(
                      type: SlotContentType.postit,
                      text: textController.text,
                      syncState: SlotSyncState.modified
                    )
                  );
                },
                child: const Text('Save')
              )
            ],
          );
        }
      );
    }
  );
}