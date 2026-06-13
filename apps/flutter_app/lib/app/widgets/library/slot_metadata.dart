import 'package:flutter/material.dart';
import 'package:picpak_image/picpak_image.dart';

enum SlotContentType {
  empty,
  image,
  qr,
  note,
  generated
}

enum SlotSyncState {
  clean,
  uploading,
  failed
}

enum SlotPendingAction {
  none,
  delete,
  upload
}

class SlotStatusIndicator {
  final IconData icon;
  final Color colour;
  final double size;

  const SlotStatusIndicator({
    required this.icon,
    required this.colour,
    required this.size
  });
}

SlotStatusIndicator? getStatusIndicator(SlotMetadata metadata) {
  switch (metadata.pendingAction) {
    case SlotPendingAction.delete:
      return const SlotStatusIndicator(icon: Icons.delete_outline, colour: Colors.red, size: 36);
    case SlotPendingAction.upload:
      return const SlotStatusIndicator(icon: Icons.cloud_upload_outlined, colour: Colors.orange, size: 36);
    case SlotPendingAction.none:
      break;
  }

  switch (metadata.syncState) {
    case SlotSyncState.uploading:
      return const SlotStatusIndicator(icon: Icons.sync, colour: Colors.blue, size: 36);
    case SlotSyncState.failed:
      return const SlotStatusIndicator(icon: Icons.error_outline, colour: Colors.red, size: 36);
    case SlotSyncState.clean:
      return null;
  }
}

class SlotMetadata {
  final SlotContentType type;
  final SlotSyncState syncState;
  final SlotPendingAction pendingAction;

  final QrType? qrType;

  final String? text;

  final String? wifiSsid;
  final String? wifiPassword;
  final String? wifiSecurity;

  final ImageAdjustments adjustments;

  final DitherMode dither;
  final FitStrategy fit;
  final ImageFilter filter;

  final String? imageId;

  final Rect? cropRect;

  final PaletteBias paletteBias;

  const SlotMetadata({
    required this.type,
    this.syncState = SlotSyncState.clean,
    this.pendingAction = SlotPendingAction.none,
    this.qrType,
    this.text,
    this.wifiSsid,
    this.wifiPassword,
    this.wifiSecurity,

    this.adjustments = const ImageAdjustments(brightness: 0.0, contrast: 1.0, saturation: 1.0),
    this.dither = DitherMode.none,
    this.fit = FitStrategy.contain,
    this.filter = ImageFilter.normal,

    this.paletteBias = const PaletteBias(),

    this.imageId,

    this.cropRect
  });

  SlotMetadata copyWith({
    SlotContentType? type,
    SlotSyncState? syncState,
    SlotPendingAction? pendingAction,
    QrType? qrType,
    String? text,
    String? wifiSsid,
    String? wifiPassword,
    String? wifiSecurity,
    ImageAdjustments? adjustments,
    PaletteBias? paletteBias,
    DitherMode? dither,
    FitStrategy? fit,
    ImageFilter? filter,
    String? imageId,
    Rect? cropRect
  }) {
    return SlotMetadata(
      type: type ?? this.type,
      syncState: syncState ?? this.syncState,
      pendingAction: pendingAction ?? this.pendingAction,
      qrType: qrType ?? this.qrType,
      text: text ?? this.text,
      wifiSsid: wifiSsid ?? this.wifiSsid,
      wifiPassword: wifiPassword ?? this.wifiPassword,
      wifiSecurity: wifiSecurity ?? this.wifiSecurity,
      adjustments: adjustments ?? this.adjustments,
      paletteBias: paletteBias ?? this.paletteBias,
      dither: dither ?? this.dither,
      fit: fit ?? this.fit,
      filter: filter ?? this.filter,
      imageId: imageId ?? this.imageId,
      cropRect: cropRect ?? this.cropRect
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'syncState': syncState.name,
      'pendingAction': pendingAction.name,
      'text': text,
      'wifiSsid': wifiSsid,
      'wifiPassword': wifiPassword,
      'wifiSecurity': wifiSecurity,
      'imageId': imageId,
      'brightness': adjustments.brightness,
      'contrast': adjustments.contrast,
      'saturation': adjustments.saturation,
      'sharpen': adjustments.sharpen,
      'blackBias': paletteBias.black,
      'whiteBias': paletteBias.white,
      'redBias': paletteBias.red,
      'yellowBias': paletteBias.yellow,
      'dither': dither.name,
      'fit': fit.name,
      'filter': filter.name,
      'cropX': cropRect?.left,
      'cropY': cropRect?.top,
      'cropW': cropRect?.width,
      'cropH': cropRect?.height
    };
  }

  factory SlotMetadata.fromJson(
    Map<String, dynamic> json,
  ) {
    return SlotMetadata(
      type: SlotContentType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => SlotContentType.empty,
      ),
      syncState: SlotSyncState.values.firstWhere(
        (e) => e.name == json['syncState'],
        orElse: () => SlotSyncState.clean,
      ),
      pendingAction: SlotPendingAction.values.firstWhere(
        (e) => e.name == json['pendingAction'],
        orElse: () => SlotPendingAction.none,
      ),
      text: json['text'],
      wifiSsid: json['wifiSsid'],
      wifiPassword: json['wifiPassword'],
      wifiSecurity: json['wifiSecurity'],
      imageId: json['imageId'],

      adjustments: ImageAdjustments(
        brightness: (json['brightness'] as num?)?.toDouble() ?? 0.0,
        contrast: (json['contrast'] as num?)?.toDouble() ?? 1.0,
        saturation: (json['saturation'] as num?)?.toDouble() ?? 1.0,
        sharpen: (json['sharpen'] as num?)?.toDouble() ?? 0.0
      ),

      paletteBias: PaletteBias(
        black: (json['blackBias'] as num?)?.toDouble() ?? 1.0,
        white: (json['whiteBias'] as num?)?.toDouble() ?? 1.0,
        red: (json['redBias'] as num?)?.toDouble() ?? 1.0,
        yellow: (json['yellowBias'] as num?)?.toDouble() ?? 1.0
      ),

      dither: DitherMode.values.firstWhere(
        (e) => e.name == json['dither'],
        orElse: () => DitherMode.none,
      ),

      fit: FitStrategy.values.firstWhere(
        (e) => e.name == json['fit'],
        orElse: () => FitStrategy.contain,
      ),

      filter: ImageFilter.values.firstWhere(
        (e) => e.name == json['filter'],
        orElse: () => ImageFilter.normal,
      ),

      cropRect: (json['cropX'] != null &&
                json['cropY'] != null &&
                json['cropW'] != null &&
                json['cropH'] != null)
          ? Rect.fromLTWH(
              (json['cropX'] as num).toDouble(),
              (json['cropY'] as num).toDouble(),
              (json['cropW'] as num).toDouble(),
              (json['cropH'] as num).toDouble(),
            )
          : null
    );
  }
}

class SlotMetadataDefaults {
  static SlotMetadata empty(int slot) {
    return SlotMetadata(
      type: SlotContentType.empty,
      syncState: SlotSyncState.clean,
      pendingAction: SlotPendingAction.none,
      adjustments: ImageAdjustments(),
      dither: DitherMode.atkinson,
      fit: FitStrategy.crop,
      filter: ImageFilter.normal
    );
  }
}