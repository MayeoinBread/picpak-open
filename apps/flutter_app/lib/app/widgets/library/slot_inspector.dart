import 'package:flutter/material.dart';
import 'package:flutter_app/app/widgets/library/library_item.dart';

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
    if (item == null) {
      return const Center(
        child: Text('No slot selected'),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ElevatedButton(
            onPressed: onSync,
            child: const Text('Sync Device')
          ),

          Text(
            'Slot ${item!.slot}',
            style: Theme.of(context).textTheme.titleLarge,
          ),

          const SizedBox(height: 16),

          Text(
            item!.exists
              ? 'Contains Image'
              : 'Empty Slot',
          ),
        ],
      ),
    );
  }
}