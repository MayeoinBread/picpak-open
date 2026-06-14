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
            Text('Palette Bias', style: Theme.of(context).textTheme.titleMedium),

            Row(
              children: [
                // Red
                SizedBox(
                  width: 70,
                  child: Text('Red', style: Theme.of(context).textTheme.bodyMedium)
                ),
                Expanded(
                  child: Slider(
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
                  )
                )
              ],
            ),

            Row(
              children: [
                SizedBox(
                  width: 70,
                  child: Text('Yellow', style: Theme.of(context).textTheme.bodyMedium)
                ),
                Expanded(
                  child: Slider(
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
                )
              ],
            )
          ]
        )
      )
    );
  }
}