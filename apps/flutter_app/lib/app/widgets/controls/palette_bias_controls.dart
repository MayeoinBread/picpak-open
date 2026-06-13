import 'package:flutter/material.dart';
import 'package:picpak_image/picpak_image.dart';

class PaletteBiasControls extends StatelessWidget{
  final PaletteBias paletteBias;

  final ValueChanged<PaletteBias> onChanged;

  const PaletteBiasControls({
    super.key,
    required this.paletteBias,
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
            Text('Palette Bias', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 24),

            // Red
            Text('Red', style: Theme.of(context).textTheme.titleMedium),
            Slider(
              min: 0.5,
              max: 1.5,
              divisions: 20,
              value: paletteBias.red,
              label: paletteBias.red.toStringAsFixed(2),
              onChanged: (value) {
                onChanged(
                  paletteBias.copyWith(
                    red: value
                  )
                );
              }
            ),

            // Red
            Text('Yellow', style: Theme.of(context).textTheme.titleMedium),
            Slider(
              min: 0.5,
              max: 1.5,
              divisions: 20,
              value: paletteBias.yellow,
              label: paletteBias.yellow.toStringAsFixed(2),
              onChanged: (value) {
                onChanged(
                  paletteBias.copyWith(
                    yellow: value
                  )
                );
              }
            )
          ]
        )
      )
    );
  }
}