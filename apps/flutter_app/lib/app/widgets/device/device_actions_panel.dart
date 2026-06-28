import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:picpak_open/app/data/models/device_settings.dart';
import 'package:picpak_open/app/widgets/controls/slot_input_field.dart';

class DeviceActionsPanel extends StatefulWidget {
  final VoidCallback? onConnect;
  final VoidCallback? onDisconnect;
  final VoidCallback? onDownload;
  final VoidCallback? onUpload;

  final int? activeSlot;
  final ValueChanged<int?> onSlotChanged;

  final ValueChanged<DeviceSettings> onSettingsChanged;

  final DeviceSettings settings;

  const DeviceActionsPanel({
    super.key,
    required this.onConnect,
    required this.onDisconnect,
    required this.onDownload,
    required this.onUpload,
    required this.activeSlot,
    required this.onSlotChanged,
    required this.onSettingsChanged,
    required this.settings
  });

  @override
  State<DeviceActionsPanel> createState() => _DeviceActionsPanelState();
}

class _DeviceActionsPanelState extends State<DeviceActionsPanel> {
  late final TextEditingController _refreshTextController;

  @override
  void initState() {
    super.initState();

    _refreshTextController = TextEditingController(
      text: widget.settings.seconds.toString()
    );
  }

  @override
  void didUpdateWidget(covariant DeviceActionsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);

    final newText = widget.settings.seconds.toString();

    if (_refreshTextController.text != newText) {
      _refreshTextController.text = newText;
    }
  }

  @override
  void dispose() {
    _refreshTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton(
          onPressed: widget.onConnect,
          child: const Text('Connect'),
        ),  

        const SizedBox(height: 8),

        ElevatedButton(
          onPressed: widget.onDisconnect,
          child: const Text('Disconnect'),
        ),

        const SizedBox(height: 48),

        SlotInputField(value: widget.activeSlot, onChanged: widget.onSlotChanged),

        const SizedBox(height: 24),

        ElevatedButton(
          onPressed: widget.onDownload,
          child: Text('Download')
        ),

        const SizedBox(height: 8),

        ElevatedButton(
          onPressed: widget.onUpload,
          child: const Text('Upload'),
        ),

        const SizedBox(height: 32),

        Text('Device Settings', style: Theme.of(context).textTheme.titleMedium),

        const SizedBox(height: 16),

        TextField(
          controller: _refreshTextController,
          decoration: const InputDecoration(
            labelText: 'Refresh Seconds',
            border: OutlineInputBorder()
          ),

          keyboardType: TextInputType.number,

          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly
          ]
        ),

        const SizedBox(height: 8),

        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Color.fromARGB(48, 255, 128, 0),
            borderRadius: BorderRadius.circular(8)
          ),
          child: Text("Possible to set any duration, but actual usage not verified")
        ),

        const SizedBox(height: 16),

        ElevatedButton(
          onPressed: () {
            widget.settings.seconds = int.parse(_refreshTextController.text);
            widget.onSettingsChanged(widget.settings);
          },
          child: const Text('Set Refresh Period')
        ),

        const SizedBox(height: 16),

        Material(
          borderRadius: BorderRadius.circular(12),
          child: SwitchListTile(
            title: const Text('Accelerometer'),
            value: widget.settings.accelerometer,
            onChanged: (accel) async {
              setState(() {
                widget.settings.accelerometer = accel;
              });
              widget.onSettingsChanged(widget.settings);
            },
          )
        ),
      ],
    );
  }
}