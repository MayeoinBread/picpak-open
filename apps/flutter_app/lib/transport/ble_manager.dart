import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:picpak_open/app/services/device_session_service.dart';
import 'package:picpak_open/app/state/device_session_state.dart';
import 'package:picpak_open/transport/ble_session.dart';
import 'package:picpak_open/transport/device_info.dart';
// import 'package:flutter_blue_plus_windows/flutter_blue_plus_windows.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:picpak_protocol/picpak_protocol.dart';
import 'package:picpak_image/picpak_image.dart';

class BleManager {
  final BleSession bleSession = BleSession();
  BluetoothCharacteristic? ff01;  // frameBuffer
  BluetoothCharacteristic? ff02;

  StreamSubscription? _ff01Sub;
  StreamSubscription? _ff02Sub;

  ImageReadSession? _readSession;

  Completer<String>? _slotHashCompleter;

  final session = DeviceSessionService.instance;

  final StreamController<PaletteFramebuffer> imageStream = StreamController.broadcast();

  Function(DeviceInfo info)? onDeviceInfo;

  Function(List<int> slots)? onSlotList;

  Function(int slot)? onDeleteAck;

  Function()? onDownloadComplete;

  Function()? onUploadComplete;

  Future<BluetoothDevice?> scanForDevice() async {
    final completer = Completer<BluetoothDevice?>();

    late final StreamSubscription sub;

    sub = FlutterBluePlus.onScanResults.listen((results) {
      for (final r in results) {
        debugPrint(r.device.platformName);

        if (r.device.platformName == "PicPak") {
          sub.cancel();
          FlutterBluePlus.stopScan();

          completer.complete(r.device);
          return;
        }
      }
    });

    await FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 10)
    );

    return completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        sub.cancel();
        return null;
      }
    );
  }

  Future<BluetoothDevice?> scanAndConnect() async {
    final device = await scanForDevice();

    if (device == null) return null;

    // // await connect(device);
    var sub2 = device.connectionState.listen((BluetoothConnectionState state) async {
      if (state == BluetoothConnectionState.disconnected) {
        // 1. typically, start a periodic timer that tries to 
        //    reconnect, or just call connect() again right now
        // 2. you must always re-discover services after disconnection!
        debugPrint("${device.disconnectReason?.code} ${device.disconnectReason?.description}");
      }
    });

    device.cancelWhenDisconnected(sub2, delayed: true, next: true);

    try {
      debugPrint("Connecting...");

      await device.connect(license: License.nonprofit);

      debugPrint("Connected");
    } catch(e) {
      debugPrint("Connect failed: ");
      debugPrint("$e");
    }

    // return device;
  }

  Future<BluetoothDevice?> _resolveDevice(BluetoothDevice scanDevice) async {
    // final devices = FlutterBluePlusWindows.connectedDevices;
    final devices = FlutterBluePlus.connectedDevices;

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

    await device.connect(autoConnect: false, license: License.nonprofit);
    
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
        _handleDeleteAck(data);
        break;
      case 0x04:
        _parseSlotHash(data);
    }
  }

  Future<void> sendImage(List<ProtocolPacket> packets) async {
    final char = ff01;

    if (char == null) {
      throw Exception("No active BLE session");
    }

    for (int i=0; i<packets.length; i++){
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

  Future<void> getHashForSlot(int slotNumber) async {
    final lo = slotNumber & 0xFF;
    final hi = (slotNumber >> 8) & 0xFF;

    await ff01!.write([0xAA, 0x04, lo, hi, 0x02, 0xFF]);
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

      final framebuffer = FramebufferDecoder.decode(framebufferBytes);
      
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

  void _handleDeleteAck(List<int> data) {
    if (data.length < 5) return;

    final lo = data[2];
    final hi = data[3];

    final slot = (hi << 8) | lo;

    onDeleteAck?.call(slot);
  }

  void _parseSlotHash(List<int> data) {
    if (data.length < 22) return;

    final digestBytes = data.sublist(5, 21);

    final md5 = digestBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

    _slotHashCompleter?.complete(md5);
    _slotHashCompleter = null;
  }

  Future<String> requestSlotHash(int slot) async {
    final completer = Completer<String>();
    // _slotHashCompleter = Completer<String>();
    _slotHashCompleter = completer;

    final lo = slot & 0xFF;
    final hi = (slot >> 8) & 0xFF;

    await ff01!.write([0xAA, 0x04, lo, hi, 0x02, 0xFF]);

    return completer.future;
  }
}

class ImageReadSession {
  final Map<int, Uint8List> packets = {};

  bool complete = false;
}