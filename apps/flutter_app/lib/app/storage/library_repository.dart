import 'package:flutter_app/app/widgets/device/device_library.dart';

abstract class LibraryRepository {
  Future<DeviceLibrary?> load(String deviceSerial);
  Future<void> save(DeviceLibrary library);
}