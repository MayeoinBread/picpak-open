import 'dart:typed_data';

import 'package:flutter/material.dart';

class ImagePreviewPanel extends StatelessWidget {
  final String title;
  final int height;
  final Uint8List? imageBytes;

  const ImagePreviewPanel({
    super.key,
    required this.title,
    required this.height,
    required this.imageBytes
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: height.toDouble(),
              child: Center(
                child: imageBytes == null
                  ? const Text('No image loaded')
                  : Image.memory(imageBytes!, fit: BoxFit.contain)
              )
            )
          ]
        )
      )
    );
  }
}