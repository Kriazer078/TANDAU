import 'package:flutter/material.dart';

/// A locally rendered Google "G" logo widget.
/// Eliminates the need for a network image on auth screens.
class GoogleLogo extends StatelessWidget {
  final double size;

  const GoogleLogo({super.key, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.width;
    final double center = s / 2;
    final double radius = s * 0.45;
    final double strokeWidth = s * 0.14;

    // Blue arc (top-right)
    final Paint bluePaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    canvas.drawArc(
      Rect.fromCircle(center: Offset(center, center), radius: radius),
      -0.6, // ~-34°
      1.8, // ~103°
      false,
      bluePaint,
    );

    // Green arc (bottom-right)
    final Paint greenPaint = Paint()
      ..color = const Color(0xFF34A853)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    canvas.drawArc(
      Rect.fromCircle(center: Offset(center, center), radius: radius),
      1.2, // ~69°
      1.2, // ~69°
      false,
      greenPaint,
    );

    // Yellow arc (bottom-left)
    final Paint yellowPaint = Paint()
      ..color = const Color(0xFFFBBC05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    canvas.drawArc(
      Rect.fromCircle(center: Offset(center, center), radius: radius),
      2.4, // ~137°
      1.0, // ~57°
      false,
      yellowPaint,
    );

    // Red arc (top-left)
    final Paint redPaint = Paint()
      ..color = const Color(0xFFEA4335)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    canvas.drawArc(
      Rect.fromCircle(center: Offset(center, center), radius: radius),
      3.4, // ~195°
      2.14, // ~123°
      false,
      redPaint,
    );

    // Blue horizontal bar (the crossbar of "G")
    final Paint barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromLTWH(center, center - strokeWidth / 2, radius, strokeWidth),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
