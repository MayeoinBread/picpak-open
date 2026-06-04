import 'package:picpak_image/picpak_image.dart';

enum SlotContentType {
  empty,
  image,
  qr,
  postit,
  generated
}

enum SlotSyncState {
  clean,
  modified,
  pendingUpload,
  uploading,
  failed
}

class SlotMetadata {
  final SlotContentType type;
  final SlotSyncState syncState;

  final String? text;
  final String? qrData;

  final ImageAdjustments adjustments;

  final DitherMode dither;
  final FitStrategy fit;
  final ImageFilter filter;

  const SlotMetadata({
    required this.type,
    this.syncState = SlotSyncState.clean,
    this.text,
    this.qrData,

    this.adjustments = const ImageAdjustments(brightness: 1.0, contrast: 1.0),
    this.dither = DitherMode.none,
    this.fit = FitStrategy.contain,
    this.filter = ImageFilter.normal
  });

  SlotMetadata copyWith({
    SlotContentType? type,
    SlotSyncState? syncState,
    String? text,
    String? qrData,
    ImageAdjustments? adjustments,
    DitherMode? dither,
    FitStrategy? fit,
    ImageFilter? filter
  }) {
    return SlotMetadata(
      type: type ?? this.type,
      syncState: syncState ?? this.syncState,
      text: text ?? this.text,
      qrData: qrData ?? this.qrData,
      adjustments: adjustments ?? this.adjustments,
      dither: dither ?? this.dither,
      fit: fit ?? this.fit,
      filter: filter ?? this.filter
    );
  }
}