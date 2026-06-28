import 'package:flutter/material.dart';
import 'package:picpak_open/app/state/device_session_state.dart';

class DeviceInfoCard extends StatelessWidget {
  final DeviceSessionState state;

  const DeviceInfoCard({
    super.key,
    required this.state
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              state.deviceName,
              style: Theme.of(context).textTheme.titleLarge
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.circle, size: 12, color: state.isConnected ? Colors.green : Colors.red
                ),
                const SizedBox(width: 8),
                Text(state.statusText)
              ]
            ),
            const SizedBox(height: 16),
            Text('Firmware: ${state.firmware}'),
            Text('Battery: ${state.batteryPercent}%'),
            const SizedBox(height: 16),
            Text('Image Refresh Period: ${state.settings.seconds}s'),
            Text('Accelerometer Enabled: ${state.settings.accelerometer}')
          ],
        )
      )
    );
  }
}