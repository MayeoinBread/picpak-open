import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/app/widgets/controls/slot_input_field.dart';

class DeviceActionsPanel extends StatelessWidget {
  final VoidCallback? onConnect;
  final VoidCallback? onDisconnect;
  final VoidCallback? onDownload;
  final VoidCallback? onUpload;

  final int? activeSlot;
  final ValueChanged<int?> onSlotChanged;

  const DeviceActionsPanel({
    super.key,
    required this.onConnect,
    required this.onDisconnect,
    required this.onDownload,
    required this.onUpload,
    required this.activeSlot,
    required this.onSlotChanged
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton(
          onPressed: onConnect,
          child: const Text('Connect'),
        ),

        const SizedBox(height: 8),

        ElevatedButton(
          onPressed: onDisconnect,
          child: const Text('Disconnect'),
        ),

        const SizedBox(height: 48),

        SlotInputField(value: activeSlot, onChanged: onSlotChanged),

        const SizedBox(height: 24),

        ElevatedButton(
          onPressed: onDownload,
          child: Text('Download')
          // child: Text(activeSlot == null
          //   ? 'Download'
          //   : 'Download Slot $activeSlot'),
        ),

        const SizedBox(height: 8),

        ElevatedButton(
          onPressed: onUpload,
          child: const Text('Upload'),
        ),
      ],
    );
  }
}