import 'package:flutter/material.dart';
import 'package:picpak_open/app/data/models/editor_result.dart';
import 'package:picpak_open/app/widgets/library/library_item.dart';
import 'package:picpak_open/app/widgets/popups/image_editor_tab.dart';
import 'package:picpak_open/app/widgets/popups/note_editor_tab.dart';
import 'package:picpak_open/app/widgets/popups/qr_code_tab.dart';

class ContentEditorDialog extends StatelessWidget {
  final LibraryItem item;

  final void Function(
    EditorResult editorResult
  ) onSaved;

  const ContentEditorDialog({
    super.key,
    required this.item,
    required this.onSaved
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: 900,
        height: 600,
        child: DefaultTabController(
          length: 3,
          child: Column(
            children: [
              const TabBar(
                tabs: [
                  Tab(text: 'Image'),
                  Tab(text: 'Note'),
                  Tab(text: 'QR')
                ]
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    ImageEditorTab(
                      item: item,
                      onSaved: onSaved
                    ),
                    NoteEditorTab(
                      item: item,
                      onSaved: onSaved
                    ),
                    QrCodeTab(
                      item: item,
                      onSaved: onSaved
                    )
                  ],
                )
              )
            ]
          )
        )
      )
    );
  }
}