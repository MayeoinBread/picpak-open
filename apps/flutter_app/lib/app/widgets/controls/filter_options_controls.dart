import 'package:flutter/material.dart';
import 'package:picpak_image/picpak_image.dart';

class FilterOptionsControls extends StatelessWidget {
  
  final ImageAdjustments adjustments;
  final ImageFilter filter;

  final ValueChanged<ImageAdjustments> onChanged;

  const FilterOptionsControls({
    super.key,
    required this.adjustments,
    required this.filter,
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
            Text('Filter Options', style: Theme.of(context).textTheme.titleMedium),

            Row(
              children: [
                SizedBox(
                  width: 100,
                  child: Text('Tone Levels', style: Theme.of(context).textTheme.bodyMedium)
                ),
                Expanded(
                  child: Slider(
                    min: 2.0, max: 8.0, divisions: 12,
                    value: adjustments.toneLevels,
                    label: adjustments.toneLevels.toStringAsFixed(2),
                    onChanged: (filter == ImageFilter.comic || filter == ImageFilter.posterise)
                      ? (value) {
                        onChanged(adjustments.copyWith(toneLevels: value));
                      }
                      : null,
                  )
                ) 
              ]
            ),

            Row(
              children: [
                SizedBox(
                  width: 100,
                  child: Text('Comic Strength', style: Theme.of(context).textTheme.bodyMedium)
                ),
                Expanded(
                  child: Slider(
                    min: 0.5, max: 2.0, divisions: 6,
                    value: adjustments.comicStrength,
                    label: adjustments.comicStrength.toStringAsFixed(2),
                    onChanged: filter == ImageFilter.comic
                      ? (value) {
                        onChanged(adjustments.copyWith(comicStrength: value));
                      }
                      : null,
                  )
                )
              ]
            ),

            Row(
              children: [
                SizedBox(
                  width: 100,
                  child: Text('Ink Thickness', style: Theme.of(context).textTheme.bodyMedium)
                ),
                Expanded(
                  child: Slider(
                    min: 0.0, max: 3.0, divisions: 12,
                    value: adjustments.inkThickness,
                    label: adjustments.inkThickness.toStringAsFixed(2),
                    onChanged: filter == ImageFilter.comic
                      ? (value) {
                        onChanged(adjustments.copyWith(inkThickness: value));
                      }
                      : null,
                  )
                )
              ]
            ),

            Row(
              children: [
                SizedBox(
                  width: 100,
                  child: Text('Halftone Scale', style: Theme.of(context).textTheme.bodyMedium)
                ),
                Expanded(
                  child: Slider(
                    min: 2.0, max: 12.0, divisions: 20,
                    value: adjustments.halftoneScale,
                    label: adjustments.halftoneScale.toStringAsFixed(2),
                    onChanged: filter == ImageFilter.halftone
                      ? (value) {onChanged(adjustments.copyWith(halftoneScale: value));}
                      : null
                  )
                )
              ]
            ),

            Row(
              children: [
                SizedBox(
                  width: 100,
                  child: Text('CrossHatch Density', style: Theme.of(context).textTheme.bodyMedium)
                ),
                Expanded(
                  child: Slider(
                    min: 4.0, max: 16.0, divisions: 24,
                    value: adjustments.hatchDensity,
                    label: adjustments.hatchDensity.toStringAsFixed(2),
                    onChanged: filter == ImageFilter.crossHatch
                      ? (value) {onChanged(adjustments.copyWith(hatchDensity: value));}
                      : null
                  )
                )
              ]
            ),

            Row(
              children: [
                SizedBox(
                  width: 100,
                  child: Text('Sketch Strength', style: Theme.of(context).textTheme.bodyMedium)
                ),
                Expanded(
                  child: Slider(
                    min: 0.5, max: 2.0, divisions: 15,
                    value: adjustments.sketchStrength,
                    label: adjustments.sketchStrength.toStringAsFixed(2),
                    onChanged: filter == ImageFilter.pencilSketch
                      ? (value) {onChanged(adjustments.copyWith(sketchStrength: value));}
                      : null
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