import 'package:flutter/material.dart';

/// طبقة زخرفية فوق معاينة الكاميرا في `qr_scan_screen.dart` — إطار
/// مربّع بزوايا بارزة (أسلوب ماسحات QR القياسي) مع تعتيم خارج منطقة
/// المسح، لتوجيه المستخدم بصرياً دون أي منطق مسح فعلي (المسح الفعلي
/// عبر `mobile_scanner` في الشاشة الأب).
///
/// مكوّن عرض بحت مبني بالكامل عبر [CustomPaint] — لا حالة داخلية ولا
/// اعتماد على أي حزمة مسح.
class QrScannerOverlay extends StatelessWidget {
  const QrScannerOverlay({super.key, this.cutOutSize = 260, this.borderColor});

  /// طول ضلع مربع منطقة المسح الشفافة، بالبكسل المنطقي.
  final double cutOutSize;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final Color color = borderColor ?? Theme.of(context).colorScheme.primary;
    return IgnorePointer(
      child: CustomPaint(
        size: Size.infinite,
        painter: _ScannerOverlayPainter(cutOutSize: cutOutSize, borderColor: color),
      ),
    );
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  _ScannerOverlayPainter({required this.cutOutSize, required this.borderColor});

  final double cutOutSize;
  final Color borderColor;

  static const double _cornerLength = 28;
  static const double _cornerStroke = 5;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect cutOutRect = Rect.fromCenter(
      center: size.center(Offset.zero),
      width: cutOutSize,
      height: cutOutSize,
    );
    final RRect cutOutRRect = RRect.fromRectAndRadius(cutOutRect, const Radius.circular(16));

    // تعتيم كل ما حول منطقة المسح.
    final Path overlayPath = Path.combine(
      PathOperation.difference,
      Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
      Path()..addRRect(cutOutRRect),
    );
    canvas.drawPath(overlayPath, Paint()..color = Colors.black.withValues(alpha: 0.55));

    // إطار منطقة المسح.
    canvas.drawRRect(
      cutOutRRect,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // زوايا بارزة بلون العلامة التجارية.
    final Paint cornerPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = _cornerStroke
      ..strokeCap = StrokeCap.round;

    void drawCorner(Offset origin, Offset dx, Offset dy) {
      canvas.drawLine(origin, origin + dx, cornerPaint);
      canvas.drawLine(origin, origin + dy, cornerPaint);
    }

    final Rect r = cutOutRect;
    drawCorner(r.topLeft, const Offset(_cornerLength, 0), const Offset(0, _cornerLength));
    drawCorner(r.topRight, const Offset(-_cornerLength, 0), const Offset(0, _cornerLength));
    drawCorner(r.bottomLeft, const Offset(_cornerLength, 0), const Offset(0, -_cornerLength));
    drawCorner(r.bottomRight, const Offset(-_cornerLength, 0), const Offset(0, -_cornerLength));
  }

  @override
  bool shouldRepaint(covariant _ScannerOverlayPainter oldDelegate) {
    return oldDelegate.cutOutSize != cutOutSize || oldDelegate.borderColor != borderColor;
  }
}
