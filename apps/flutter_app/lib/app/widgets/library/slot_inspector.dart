import 'package:flutter/material.dart';
import 'package:picpak_open/app/widgets/library/library_item.dart';

class SlotInspector extends StatelessWidget {
  final LibraryItem? item;
  final Future<void> Function() onSync;

  const SlotInspector({
    super.key,
    required this.item,
    required this.onSync
  });

  @override
  Widget build(BuildContext context) {
    debugPrint('Inspector build item=${item?.slot}');

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ElevatedButton(
            onPressed: onSync,
            child: const Text('Sync Device')
          ),

          const SizedBox(height: 16),

          if (item == null)  
            const Text('No slot selected')
          else ...[
            Text(
              'Slot ${item!.slot}',
              style: Theme.of(context).textTheme.titleLarge,
            ),

            const SizedBox(height: 16),

            Text(
              item!.exists ? 'Contains Image' : 'Empty Slot',
            ),
          ],
        ],
      ),
    );
  }
}