import 'dart:typed_data';

import 'package:image/image.dart' as img;

class ThumbnailService {

  static Uint8List create(Uint8List imageBytes) {

    final decoded = img.decodeImage(imageBytes);

    if (decoded == null) {
      return Uint8List(0);
    }

    final thumb = img.copyResize(
      decoded,
      width: 120,
    );

    return Uint8List.fromList(
      img.encodeJpg(
        thumb,
        quality: 70,
      ),
    );
  }
}