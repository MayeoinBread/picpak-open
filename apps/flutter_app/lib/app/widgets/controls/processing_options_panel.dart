import 'package:flutter/material.dart';
import 'package:picpak_image/picpak_image.dart';
import 'package:picpak_image/src/pipeline/fit_strategy.dart';

class ProcessingOptionsPanel extends StatelessWidget {
  final ImageFilter selectedFilter;
  final FitStrategy fitStrategy;
  final bool simulateDevice;

  final ValueChanged<ImageFilter> onFilterChanged;
  final ValueChanged<FitStrategy> onFitChanged;
  final ValueChanged<bool> onSimulateChanged;

  const ProcessingOptionsPanel({
    super.key,
    required this.selectedFilter,
    required this.fitStrategy,
    required this.simulateDevice,
    required this.onFilterChanged,
    required this.onFitChanged,
    required this.onSimulateChanged
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Image Processing', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 24),

            // Fit
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: FitStrategy.values.map((fit) {
                final selected = fit == fitStrategy;
                return ChoiceChip(
                  label: Text(fit.name),
                  selected: selected,
                  showCheckmark: false,
                  onSelected: (_) {
                    onFitChanged(fit);
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 12),

            // Filters
            // Chip list
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ImageFilter.values.map((filter) {
                final selected = filter == selectedFilter;
                return ChoiceChip(
                  label: Text(filter.name),
                  selected: selected,
                  showCheckmark: false,
                  onSelected: (_) {
                    onFilterChanged(filter);
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 12),

            SwitchListTile(
              title: const Text('Simulate Device Colours'),
              value: simulateDevice,
              onChanged: onSimulateChanged,
            )
          ],
        )
      )
    );
  }
}