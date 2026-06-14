import 'package:flutter/material.dart';
import 'package:picpak_image/picpak_image.dart';

class FilterControls extends StatelessWidget {
  final ImageFilter selectedFilter;

  final ValueChanged<ImageFilter> onFilterChanged;

  const FilterControls({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged
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
              Text('Filters', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),

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
              )
            ],
          )
        )
      )
    );
  }
}