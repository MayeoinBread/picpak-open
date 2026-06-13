import 'package:flutter/material.dart';
import 'package:picpak_image/picpak_image.dart';

class ImageAdjustmentControls extends StatelessWidget {
  final ImageAdjustments adjustments;

  final ValueChanged<ImageAdjustments> onChanged;

  const ImageAdjustmentControls({
    super.key,
    required this.adjustments,
    required this.onChanged
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Image Adjustments', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 24),

            // BRIGHTNESS
            Text('Brightness', style: Theme.of(context).textTheme.titleMedium),

            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: () {
                    final v = (adjustments.brightness - 0.1).clamp(-1.0, 1.0);
                    onChanged(adjustments.copyWith(brightness: v));
                  },
                ),
                Expanded(
                  child: Center(
                    child: Text(adjustments.brightness.toStringAsFixed(2))
                  )
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    final v = (adjustments.brightness + 0.1).clamp(-1.0, 1.0);
                    onChanged(adjustments.copyWith(brightness: v));
                  },
                )
              ]
            ),

            const SizedBox(height: 24),

            // CONTRAST
            Text('Contrast', style: Theme.of(context).textTheme.titleMedium),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: () {
                    final v = (adjustments.contrast - 0.1).clamp(0.0, 2.0);
                    onChanged(adjustments.copyWith(contrast: v));
                  },
                ),
                Expanded(
                  child: Center(
                    child: Text(adjustments.contrast.toStringAsFixed(2))
                  )
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    final v = (adjustments.contrast + 0.1).clamp(0.0, 2.0);
                    onChanged(adjustments.copyWith(contrast: v));
                  },
                )
              ]
            ),
            
            const SizedBox(height: 24),

            Text('Saturation', style: Theme.of(context).textTheme.titleMedium),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: () {
                    final v = (adjustments.saturation - 0.1).clamp(0.0, 2.0);
                    onChanged(adjustments.copyWith(saturation: v));
                  }),
                Expanded(
                  child: Center(
                    child: Text(adjustments.saturation.toStringAsFixed(2))
                  )
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    final v = (adjustments.saturation + 0.1).clamp(0.0, 2.0);
                    onChanged(adjustments.copyWith(saturation: v));
                  }
                )
              ]
            ),

            const SizedBox(height: 24),

            Text('Sharpen', style: Theme.of(context).textTheme.titleMedium),
            Slider(
              min: 0.0, max: 2.0, divisions: 20,
              value: adjustments.sharpen,
              onChanged: (value) {
                onChanged(adjustments.copyWith(sharpen: value));
              }
            )

          ]
        )
      )
    );
  }
}