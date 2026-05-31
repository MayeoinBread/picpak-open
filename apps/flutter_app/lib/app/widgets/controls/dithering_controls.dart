import 'package:flutter/material.dart';
import 'package:picpak_image/picpak_image.dart';

class DitheringControls extends StatefulWidget {
  final DitherMode selectedAlgorithm;

  final ValueChanged<DitherMode> onAlgorithmChanged;

  const DitheringControls({
    super.key,
    required this.selectedAlgorithm,
    required this.onAlgorithmChanged
  });

  @override
  State<DitheringControls> createState() => _DitheringControlsState();
}

class _DitheringControlsState extends State<DitheringControls> {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Dithering', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: DitherMode.values.map((dither) {
                final selected = dither == widget.selectedAlgorithm;
                return ChoiceChip(
                  label: Text(dither.name),
                  selected: selected,
                  showCheckmark: false,
                  onSelected: (_) {
                    widget.onAlgorithmChanged(dither);
                  },
                );
              }).toList(),
            ),
          ],
        )
      )
    );
  }
}