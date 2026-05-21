import 'package:image/image.dart' as img;

class NoteRenderer {
  static img.Image render({
    required String text,
    required int w,
    required int h
  }) {
    final image = img.Image(
      width: w,
      height: h
    );

    img.fill(image, color: img.ColorRgb8(255, 255, 255));

    img.drawString(
      image, text, font: img.arial24, x: 20, y: 20,
      color: img.ColorRgb8(0, 0, 0));

    return image;
  }
}