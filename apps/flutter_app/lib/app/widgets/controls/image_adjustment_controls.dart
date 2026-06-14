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
            Text('Adjustments', style: Theme.of(context).textTheme.titleMedium),

            // BRIGHTNESS
            Row(
              children: [
                SizedBox(
                  width: 70,
                  child: Text('Brightness', style: Theme.of(context).textTheme.bodyMedium)
                ),
                Expanded(
                  child: Slider(
                    min: -1.0, max: 1.0, divisions: 20,
                    value: adjustments.brightness,
                    label: adjustments.brightness.toStringAsFixed(2),
                    onChanged: (value) {
                      onChanged(adjustments.copyWith(brightness: value));
                    }
                  )
                )
              ]
            ),

            // CONTRAST
            Row(
              children: [
                SizedBox(
                  width: 70,
                  child: Text('Contrast', style: Theme.of(context).textTheme.bodyMedium)
                ),
                Expanded(
                  child: Slider(
                    min: 0.0, max: 2.0, divisions: 20,
                    value: adjustments.contrast,
                    label: adjustments.contrast.toStringAsFixed(2),
                    onChanged: (value) {
                      onChanged(adjustments.copyWith(contrast: value));
                    }
                  )
                )
              ]
            ),

            Row(
              children: [
                SizedBox(
                  width: 70,
                  child: Text('Saturation', style: Theme.of(context).textTheme.bodyMedium)
                ),
                Expanded(
                  child: Slider(
                    min: 0.0, max: 2.0, divisions: 20,
                    value: adjustments.saturation,
                    label: adjustments.saturation.toStringAsFixed(2),
                    onChanged: (value) {
                      onChanged(adjustments.copyWith(saturation: value));
                    }
                  )
                )
              ]
            ),

            Row(
              children: [
                SizedBox(
                  width: 70,
                  child: Text('Sharpen', style: Theme.of(context).textTheme.bodyMedium)
                ),
                Expanded(
                  child: Slider(
                    min: 0.0, max: 2.0, divisions: 20,
                    value: adjustments.sharpen,
                    onChanged: (value) {
                      onChanged(adjustments.copyWith(sharpen: value));
                    }
                  )
                )
              ]
            )
          ]
        )
      )
    );
  }
}