import 'package:flutter/material.dart';
import 'package:picpak_open/app/repositories/album_repository.dart';

class AlbumSelector extends StatelessWidget{
  final List<Album> albums;
  final Album currentAlbum;

  final ValueChanged<String> onAlbumSelected;

  final Future<void> Function(String name) onCreateAlbum;
  final Future<void> Function(String albumId, String newName) onRenameAlbum;
  final Future<void> Function(String albumId) onDeleteAlbum;

  const AlbumSelector({
    super.key,
    required this.albums,
    required this.currentAlbum,
    required this.onAlbumSelected,
    required this.onCreateAlbum,
    required this.onRenameAlbum,
    required this.onDeleteAlbum
  });

  Future<String?> _showNameDialog(
    BuildContext context, {
      required String title,
      String initialValue = '',
    }) async {
      final controller = TextEditingController(text: initialValue);

      return showDialog(context: context, builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Album name'
            ),
            onSubmitted: (_) {
              Navigator.pop(context, controller.text.trim());
            },
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            FilledButton(onPressed: () {Navigator.pop(context, controller.text.trim());}, child: const Text('OK'))
          ]
        );
      }
    );
  }
    
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
              Text('Album Management', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),

              DropdownButton<String>(
                value: currentAlbum.id,
                isExpanded: true,
                items: albums.map((album) {
                  return DropdownMenuItem<String>(
                    value: album.id,
                    child: Text(album.name)
                  );
                }).toList(),
                onChanged: (id) {
                  print(id);
                  if (id == null) return;
                  onAlbumSelected(id);
                },
              ),

              SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(
                    onPressed: () async {
                      final name = await _showNameDialog(context, title: 'New Album');
                      if (name == null || name.isEmpty) return;

                      await onCreateAlbum(name);
                    },
                    icon: Icon(Icons.add_box_outlined)
                  ),

                  IconButton(
                    onPressed: currentAlbum.id == 'default'
                      ? null
                      : () async {
                        final name = await _showNameDialog(context, title: 'Rename Album', initialValue: currentAlbum.name);
                        if (name == null || name.isEmpty) return;
                        await onRenameAlbum(currentAlbum.id, name);
                      },
                    icon: Icon(Icons.edit_note_outlined)
                  ),

                  IconButton(
                    onPressed: currentAlbum.id == 'default'
                      ? null
                      : () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Delete Album?'),
                            content: const Text(
                              'All slot assignments in this album will be removed.'
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel')
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Delete')
                              )
                            ]
                          )
                        );

                        if (confirm == true) {
                          await onDeleteAlbum(currentAlbum.id);
                        }
                      },
                    icon: Icon(Icons.delete_outline)
                  )
                ],
              )
            ]
          )
        )
      )
    );
  }
}