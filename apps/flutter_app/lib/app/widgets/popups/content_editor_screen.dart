import 'package:flutter/material.dart';
import 'package:picpak_open/app/data/models/editor_result.dart';
import 'package:picpak_open/app/widgets/library/library_item.dart';

class ContentEditorScreen extends StatelessWidget {
  final LibraryItem item;

  final void Function(EditorResult editorResult) onSaved;

  const ContentEditorScreen({
    super.key,
    required this.item,
    required this.onSaved
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Container(

            ),
          )
        ]
      )
    );
  }
}