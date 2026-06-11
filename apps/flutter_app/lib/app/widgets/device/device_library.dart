import 'package:picpak_open/app/widgets/library/library_item.dart';

class DeviceLibrary {
  final String deviceSerial;

  final List<LibraryItem> slots;

  DeviceLibrary({
    required this.deviceSerial,
    required this.slots
  });
}