import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:picpak_open/app/services/device_session_service.dart';
import 'package:picpak_open/app/state/device_session_state.dart';
import 'package:picpak_open/transport/ble_session.dart';
import 'package:picpak_open/transport/device_info.dart';
import 'package:flutter_blue_plus_windows/flutter_blue_plus_windows.dart';
import 'package:picpak_image/src/pipeline/palette_framebuffer.dart';
import 'package:picpak_image/src/encoding/framebuffer_decoder.dart';
import 'package:picpak_protocol/picpak_protocol.dart';

class BleManager {
  final BleSession bleSession = BleSession();
  BluetoothCharacteristic? ff01;  // frameBuffer
  BluetoothCharacteristic? ff02;

  StreamSubscription? _ff01Sub;
  StreamSubscription? _ff02Sub;

  ImageReadSession? _readSession;

  final session = DeviceSessionService.instance;

  // Function(PaletteFramebuffer frameBuffer)? onImageDownloaded;

  final StreamController<PaletteFramebuffer> imageStream = StreamController.broadcast();

  Function(DeviceInfo info)? onDeviceInfo;

  Function(List<int> slots)? onSlotList;

  Function()? onDownloadComplete;

  Function()? onUploadComplete;

  Future<BluetoothDevice?> scanForDevice({
    Duration timeout = const Duration(seconds: 5)
  }) async {
    BluetoothDevice? found;

    await FlutterBluePlusWindows.startScan(timeout: timeout);

    final sub = FlutterBluePlusWindows.scanResults.listen((results) {
      for (final r in results) {
        final name = r.device.platformName.toLowerCase();
        if (name.contains('picpak')) {
          found = r.device;
          break;
        }
      }
    });

    await Future.delayed(timeout);

    await sub.cancel();
    await FlutterBluePlusWindows.stopScan();

    return found;
  }

  Future<BluetoothDevice?> scanAndConnect() async {
    final device = await scanForDevice();

    if (device == null) return null;

    await connect(device);

    return device;
  }

  Future<BluetoothDevice?> _resolveDevice(BluetoothDevice scanDevice) async {
    final devices = FlutterBluePlusWindows.connectedDevices;

    try { 
      return devices.firstWhere(
        (d) => d.remoteId == scanDevice.remoteId
      );
    } catch (_) {
      return scanDevice;
    }
  }

  Future<void> initChannels(BluetoothDevice device) async {
    final services = await device.discoverServices();

    for (final s in services) {
      if (s.uuid.toString().toLowerCase().contains("ff00")) {
        for (final c in s.characteristics) {
          final id = c.uuid.toString().toLowerCase();

          if (id == "ff01") ff01 = c;
          if (id == "ff02") ff02 = c;
        }
      }
    }

    if (ff01 == null || ff02 == null) {
      throw Exception("Missing ff01/ff02 characteristic");
    }
  }

  Future<void> connect(BluetoothDevice scanDevice) async {
    final device = await _resolveDevice(scanDevice);

    if (device == null) throw Exception("Can't resolve scanDevice");

    await FlutterBluePlus.stopScan();

    // Always use THIS instance from now on
    bleSession.device = device;

    await device.connect(autoConnect: false);
    
    await initChannels(device);

    if (!(ff01?.isNotifying ?? false)) {
      await ff01!.setNotifyValue(true);
    }

    if (!(ff02?.isNotifying ?? false)) {
      await ff02!.setNotifyValue(true);
    }

    _ff01Sub = ff01!.lastValueStream.listen(_handleBleData);
    _ff02Sub = ff02!.lastValueStream.listen(_handleBleData);
  }

  Future<void> disconnect() async {
    if (bleSession.device == null) return;

    await _ff01Sub?.cancel();
    await _ff02Sub?.cancel();

    _ff01Sub = null;
    _ff02Sub = null;

    await bleSession.device?.disconnect();
    bleSession.device = null;
  }

  void _handleBleData(List<int> data) {
    if (data.length < 3) return;

    if (data.first != 0xAA) return;
    if (data.last != 0xFF) return;
    
    final opcode = data[1];
    
    switch (opcode) {
      case 0x02:
        _handleReadPacket(data);
        break;
      case 0x08:
        _parseDeviceInfo(data);
        break;
      case 0x31:
        _handleSlotList(data);
        break;
      case 0x33:
        debugPrint("Delete ACK: $data");
    }
  }

  Future<void> sendImage(List<ProtocolPacket> packets) async {
    final char = ff01;

    if (char == null) {
      throw Exception("No active BLE session");
    }

    for (int i=0; i<packets.length; i++){
      // debugPrint("Sending packet $i");
      try {
        await char.write(packets[i].bytes, withoutResponse: false);
      } catch (e, st) {
        debugPrint("BLE WRITE FAILED at $i: $e");
        debugPrintStack(stackTrace: st);
        rethrow;
      }
      final progress = (i + 1) / packets.length;

      session.state = session.state.copyWith(
        transfer: TransferState.uploading,
        progress: progress
      );
      
      // debugPrint("Upload percentage: $progress%");
      
      await Future.delayed(const Duration(milliseconds: 3));
    }
  }

  Future<void> sendMd5Trigger({
    required int imageNumber,
    required Uint8List imageData}) async {
      final char = ff01;

      if (char == null) {
        throw Exception("No active BLE session");
      }

      await Future.delayed(const Duration(milliseconds: 100));

      final packet = Md5Packet.create(imageNumber: imageNumber, imageData: imageData);
      await char.write(packet.bytes, withoutResponse: false);

      await Future.delayed(const Duration(milliseconds: 30));

      onUploadComplete?.call();
  }

  Future<void> requestDeviceInfo() async {
    await ff02!.write([0xAA, 0x08, 0x02, 0xFF]);
  }

  Future<void> imageList() async {
    await ff01!.write([0xAA, 0x30, 0xFF]);
  }

  Future<void> deleteImage(int slotNumber) async {
    final lo = slotNumber & 0xFF;
    final hi = (slotNumber >> 8) & 0xFF;

    await ff01!.write([0xAA, 0x32, lo, hi, 0xFF]);
  }

  Future<void> getImageInSlot(int slotNumber) async {
    _readSession = ImageReadSession();

    final lo = slotNumber & 0xFF;
    final hi = (slotNumber >> 8) & 0xFF;

    await ff01!.write([0xAA, 0x03, lo, hi, 0xFF]);
  }

  Future<PaletteFramebuffer> downloadFramebuffer(int slot) async {
    final completer = Completer<PaletteFramebuffer>();

    late StreamSubscription sub;

    sub = imageStream.stream.listen((fb) {
      if (!completer.isCompleted) {
        completer.complete(fb);
      }
    });

    await getImageInSlot(slot);

    final framebuffer = await completer.future;

    await sub.cancel();

    return framebuffer;

    // OLD
    // debugPrint('Requesting slot $slot');
    
    // await getImageInSlot(slot);

    // final fb = imageStream.stream.first;

    // debugPrint('Received framebuffer for slot $slot');

    // return fb;
  }

  DeviceInfo? _parseDeviceInfo(List<int> data) {
    if (data.length < 10) return null;

    final battery = data[2];
    final flag = data[3];

    String readString(int start, int length) {
      final bytes = data
        .sublist(start, start + length)
        .takeWhile((b) => b != 0x00)
        .toList();
      return String.fromCharCodes(bytes);
    }

    final hardware = readString(5, 10);
    final firmware = readString(15, 10);
    final serial = readString(25, 10);

    final deviceInfo = DeviceInfo(
      battery: battery,
      hardware: hardware,
      firmware: firmware,
      serial: serial,
      flag: flag
    );

    debugPrint("Battery: $battery%");
    debugPrint("Flag: 0x${flag.toRadixString(16)}");
    debugPrint("Hardware: $hardware");
    debugPrint("Firmware: $firmware");
    debugPrint("Serial: $serial");

    onDeviceInfo?.call(deviceInfo);

    return deviceInfo;
  }

  void _handleReadPacket(List<int> data) {
    final packetIndex = data[4];
    final isLast = data[5] == 0x01;
    final length = data[6] | (data[7] << 8);

    final payload = Uint8List.fromList(data.sublist(8, 8 + length));

    _readSession?.packets[packetIndex] = payload;

    if (isLast) {
      final sortedKeys = _readSession!.packets.keys.toList()..sort();

      final builder = BytesBuilder();

      for (final key in sortedKeys) {
        builder.add(_readSession!.packets[key]!);
      }

      final framebufferBytes = builder.toBytes();

      debugPrint(framebufferBytes.length.toString());

      final framebuffer = FramebufferDecoder.decode(framebufferBytes);
      
      // onImageDownloaded?.call(framebuffer);
      debugPrint('Framebuffer completed');
      imageStream.add(framebuffer);

      onDownloadComplete?.call();

      _readSession!.complete = true;
    }
  }

  void _handleSlotList(List<int> data) {
    if (data.length < 4) return;
    final slots = <int>[];
    
    for(int i=2; i<data.length - 1; i++) {
      if (data[i] == 1) {
        slots.add(i - 1);
      }
    }

    debugPrint("Slots: $slots");

    onSlotList?.call(slots);
  }
}

class ImageReadSession {
  final Map<int, Uint8List> packets = {};

  bool complete = false;
}