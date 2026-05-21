import 'dart:typed_data';

class Chunking {
  static List<Uint8List> split(
    Uint8List data, {
      int chunkSize = 200
    }) {
      final chunks = <Uint8List>[];

      for (int i=0; i<data.length; i+=chunkSize) {
        final end = (i + chunkSize < data.length)
          ? i + chunkSize
          : data.length;
        
        chunks.add(Uint8List.sublistView(data, i, end));
      }

      return chunks;
    }
}