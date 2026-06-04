import 'dart:typed_data';

import 'package:image/image.dart' as img;

class ThumbnailService {

  static Uint8List createFromBytes(Uint8List imageBytes) {

    final decoded = img.decodeImage(imageBytes);

    if (decoded == null) {
      return Uint8List(0);
    }

    return createFromImage(decoded);
  }

  static Uint8List createFromImage(img.Image image) {
    final thumb = img.copyResize(image, width: 120, interpolation: img.Interpolation.nearest);

    final thumbBytes = Uint8List.fromList(img.encodePng(thumb));

    return thumbBytes;
  }
}