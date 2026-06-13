import 'package:flutter/material.dart';

enum CropHandle {
  none,
  topLeft,
  topRight,
  bottomLeft,
  bottomRight
}

class CropOverlay extends StatefulWidget {
  final Rect? initialRect;
  final double aspectRatio;
  final Size imageSize;
  final ValueChanged<Rect> onChanged;

  const CropOverlay({
    super.key,
    required this.aspectRatio,
    required this.imageSize,
    required this.onChanged,
    this.initialRect
  });

  @override
  State<CropOverlay> createState() => _CropOverlayState();
}

class _CropOverlayState extends State<CropOverlay> {
  late Rect cropRect;

  CropHandle _activeHandle = CropHandle.none;
  static const double _handleRadius = 20;

  @override
  void initState() {
    super.initState();

    cropRect = widget.initialRect ?? _defaultCenterCrop(widget.imageSize, widget.aspectRatio);
  }

  CropHandle _hitTestHandle(Offset pos, Rect paintRect) {
    if ((pos - paintRect.topLeft).distance <= _handleRadius) {
      return CropHandle.topLeft;
    }

    if ((pos - paintRect.topRight).distance <= _handleRadius) {
      return CropHandle.topRight;
    }

    if ((pos - paintRect.bottomLeft).distance <= _handleRadius) {
      return CropHandle.bottomLeft;
    }

    if ((pos - paintRect.bottomRight).distance <= _handleRadius) {
      return CropHandle.bottomRight;
    }

    return CropHandle.none;
  }

  void _resize(CropHandle handle, Offset delta, double scaleX) {
    final dx = delta.dx / scaleX;

    Rect r = cropRect;

    switch (handle) {
      case CropHandle.bottomRight:
        final width = (r.width + dx).clamp(50.0, widget.imageSize.width);
        final height = width / widget.aspectRatio;
        r = Rect.fromLTWH(r.left, r.top, width, height);
        break;
      case CropHandle.bottomLeft:
        final width = (r.width - dx).clamp(50.0, widget.imageSize.width);
        final height = width / widget.aspectRatio;
        r = Rect.fromLTWH(r.right - width, r.top, width, height);
        break;
      case CropHandle.topRight:
        final width = (r.width + dx).clamp(50.0, widget.imageSize.width);
        final height = width / widget.aspectRatio;
        r = Rect.fromLTWH(r.left, r.bottom - height, width, height);
        break;
      case CropHandle.topLeft:
        final width = (r.width - dx).clamp(50.0, widget.imageSize.width);
        final height = width / widget.aspectRatio;
        r = Rect.fromLTWH(r.right - width, r.bottom - height, width, height);
        break;
      case CropHandle.none:
        return;
    }

    setState(() {
      cropRect = _clampToBounds(r);
    });

    widget.onChanged(cropRect);
  }

  Rect _defaultCenterCrop(Size size, double aspect) {
    final imageAspect = size.width / size.height;

    double w, h;

    if (imageAspect > aspect) {
      h = size.height;
      w = h * aspect;
    } else {
      w = size.width;
      h = w / aspect;
    }

    final left = (size.width - w) / 2;
    final top = (size.height - h) / 2;

    return Rect.fromLTWH(left, top, w, h);
  }

  Rect _clampToBounds(Rect r) {
    double left = r.left;
    double top = r.top;

    if (left < 0) left = 0;
    if (top < 0) top = 0;

    if (left + r.width > widget.imageSize.width) {
      left = widget.imageSize.width - r.width;
    }

    if (top + r.height > widget.imageSize.height) {
      top = widget.imageSize.height - r.height;
    }

    return Rect.fromLTWH(left, top, r.width, r.height);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scaleX = constraints.maxWidth / widget.imageSize.width;
        final scaleY = constraints.maxHeight / widget.imageSize.height;

        final paintRect = Rect.fromLTWH(
          cropRect.left * scaleX,
          cropRect.top * scaleY,
          cropRect.width * scaleX,
          cropRect.height * scaleY,
        );

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (details) {
            _activeHandle = _hitTestHandle(details.localPosition, paintRect);
          },
          onPanUpdate: (details) {
            if (_activeHandle != CropHandle.none) {
              _resize(_activeHandle, details.delta, scaleX);
              return;
            }

            final dx = details.delta.dx / scaleX;
            final dy = details.delta.dy / scaleY;

            setState(() {
              cropRect = _clampToBounds(cropRect.shift(Offset(dx, dy)));
            });

            widget.onChanged(cropRect);
          },
          onPanEnd: (_) {
            _activeHandle = CropHandle.none;
          },
          child: CustomPaint(
            size: Size(constraints.maxWidth, constraints.maxHeight),
            painter: _CropPainter(paintRect),
          ),
        );
      },
    );
  }
}

class _CropPainter extends CustomPainter {
  final Rect rect;

  _CropPainter(this.rect);

  @override
  void paint(Canvas canvas, Size size) {
    final overlayPaint = Paint()
      ..color = Colors.black45;

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // top
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, rect.top),
      overlayPaint,
    );

    // bottom
    canvas.drawRect(
      Rect.fromLTWH(
        0,
        rect.bottom,
        size.width,
        size.height - rect.bottom,
      ),
      overlayPaint,
    );

    // left
    canvas.drawRect(
      Rect.fromLTWH(
        0,
        rect.top,
        rect.left,
        rect.height,
      ),
      overlayPaint,
    );

    // right
    canvas.drawRect(
      Rect.fromLTWH(
        rect.right,
        rect.top,
        size.width - rect.right,
        rect.height,
      ),
      overlayPaint,
    );

    canvas.drawRect(rect, borderPaint);

    final handlePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(rect.topLeft, 8, handlePaint);
    canvas.drawCircle(rect.topRight, 8, handlePaint);
    canvas.drawCircle(rect.bottomLeft, 8, handlePaint);
    canvas.drawCircle(rect.bottomRight, 8, handlePaint);
  }

  @override
  bool shouldRepaint(covariant _CropPainter oldDelegate) {
    return oldDelegate.rect != rect;
  }
}
