import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:picpak_open/app/data/models/editor_result.dart';
import 'package:picpak_open/app/services/image_pipeline_controller.dart';
import 'package:picpak_open/app/widgets/common/image_preview_panel.dart';
import 'package:picpak_open/app/widgets/library/library_item.dart';
import 'package:picpak_open/app/widgets/library/slot_metadata.dart';
import 'package:image/image.dart' as img;
import 'package:picpak_core/picpak_core.dart';
import 'package:picpak_image/picpak_image.dart';

class NoteEditorTab extends StatefulWidget {
  final LibraryItem item;

  final void Function(
    EditorResult editorResult
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

  final ImagePipelineController pipeline = ImagePipelineController();

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

  void _save() async {
    final image = NoteRenderer.render(
      text: textController.text,
      w: DeviceConstants.imageWidth,
      h: DeviceConstants.imageHeight
    );

    previewBytes = Uint8List.fromList(img.encodePng(image));

    final metadata = SlotMetadata(
      type: SlotContentType.note,
      pendingAction: SlotPendingAction.verifyHash,
      text: textController.text
    );

    await pipeline.prepare(previewBytes!, FitStrategy.crop, null);
    await pipeline.processMetadata(metadata: metadata);

    final packedBytes = FramebufferPacker.pack(pipeline.framebuffer!);

    final edRes = EditorResult(
      metadata: metadata,
      originalBytes: null,
      previewBytes: previewBytes!,
      packedBytes: packedBytes
    );

    widget.onSaved(edRes);
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
                    ElevatedButton(
                      onPressed: () async {
                        _save();
                        Navigator.pop(context);
                      },
                      child: const Text('Save')
                    )
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
