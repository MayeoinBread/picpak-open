import 'package:image/image.dart' as img;
import 'package:picpak_core/picpak_core.dart';
import 'package:qr/qr.dart';

enum QrType {
  text,
  url,
  wifi,
  none
}

class QrRenderer {

  static String generatePayloadString(
    QrType qrType,
    String? text,
    String? wifiSsid,
    String? wifiPassword,
    String? wifiSecurity
  ) {
    String payload;
    switch (qrType) {
      case QrType.text:
        payload = text!;
        break;
      case QrType.url:
        payload = text!;
        break;
      case QrType.wifi:
        payload =
          'WIFI:'
          'T:$wifiSecurity!;'
          'S:$wifiSsid!;'
          'P:$wifiPassword!;;';
        break;
      case QrType.none:
        payload = '';
        break;
    }

    return payload;
  }

  static img.Image render({
    required String data
  }) {
    final image = img.Image(width: DeviceConstants.imageWidth, height: DeviceConstants.imageHeight);
    
    img.fill(image, color: img.ColorRgb8(255, 255, 255));

    final qrCode = QrCode(
      payload: QrPayload.fromString(data),
      errorCorrectLevel: QrErrorCorrectLevel.low
    );
    final qrImage = QrImage(qrCode);

    final blockSize = DeviceConstants.imageHeight ~/ qrImage.moduleCount;

    final xOffset = (DeviceConstants.imageWidth - DeviceConstants.imageHeight) ~/ 2;

    for (int y=0; y<qrImage.moduleCount; y++) {
      for (int x=0; x<qrImage.moduleCount; x++) {
        if (qrImage.isDark(y, x)) {
          img.fillRect(
            image,
            x1: (x * blockSize) + xOffset, y1: y * blockSize,
            x2: (x + 1) * blockSize - 1 + xOffset, y2: (y + 1) * blockSize - 1,
            color: img.ColorRgb8(0, 0, 0)
          );
        }
      }
    }

    return image;
  }

  static img.Image renderForDevice({
    required QrType? qrType,
    required String? text,
    required String? wifiSsid,
    required String? wifiPassword,
    required String? wifiSecurity
  }) {
    final image = img.Image(width: DeviceConstants.imageWidth, height: DeviceConstants.imageHeight);
    
    img.fill(image, color: img.ColorRgb8(255, 255, 255));

    final qrCode = QrCode(
      payload: QrPayload.fromString(
        generatePayloadString(qrType!, text, wifiSsid, wifiPassword, wifiSecurity)
      ),
      errorCorrectLevel: QrErrorCorrectLevel.low
    );
    final qrImage = QrImage(qrCode);

    final blockSize = DeviceConstants.imageHeight ~/ qrImage.moduleCount;

    final xOffset = (DeviceConstants.imageWidth - DeviceConstants.imageHeight) ~/ 2;

    for (int y=0; y<qrImage.moduleCount; y++) {
      for (int x=0; x<qrImage.moduleCount; x++) {
        if (qrImage.isDark(y, x)) {
          img.fillRect(
            image,
            x1: (x * blockSize) + xOffset, y1: y * blockSize,
            x2: (x + 1) * blockSize - 1 + xOffset, y2: (y + 1) * blockSize - 1,
            color: img.ColorRgb8(0, 0, 0)
          );
        }
      }
    }

    return image;
  }
}