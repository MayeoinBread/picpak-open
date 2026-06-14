import 'package:flutter/material.dart';
import 'package:picpak_image/picpak_image.dart';

class CropControls extends StatelessWidget {
  final FitStrategy fitStrategy;

  final ValueChanged<FitStrategy> onFitChanged;

  const CropControls({
    super.key,
    required this.fitStrategy,
    required this.onFitChanged
  });

  @override
  Widget build(BuildContext context) {

    return SizedBox(
      width: double.infinity,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Crop Options', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: FitStrategy.values.map((fit) {
                  final selected = fit == fitStrategy;
                  return ChoiceChip(
                    label: Text(fit.name),
                    selected: selected,
                    showCheckmark: false,
                    onSelected: (_) {
                      onFitChanged(fit);
                    }
                  );
                }).toList(),
              )
            ],
          )
        )
      )
    );
  }
}