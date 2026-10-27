import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Aproximação desenhada em código do "G" do Google, dentro de um círculo
/// branco (como no protótipo).
///
/// Para publicar o app, troque por o asset oficial seguindo as diretrizes de
/// marca do Google (https://developers.google.com/identity/branding-guidelines).
class GoogleLogo extends StatelessWidget {
  const GoogleLogo({super.key, this.size = 22});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      child: CustomPaint(painter: _GoogleGPainter()),
    );
  }
}

class _GoogleGPainter extends CustomPainter {
  static const _red = Color(0xFFEA4335);
  static const _yellow = Color(0xFFFBBC05);
  static const _green = Color(0xFF34A853);
  static const _blue = Color(0xFF4285F4);

  double _rad(double deg) => deg * math.pi / 180;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.17;
    final radius = size.width * 0.5 * 0.62;
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(center: center, radius: radius);

    Paint paintFor(Color c) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = c;

    // Ângulos em graus, sentido horário a partir do eixo x.
    canvas.drawArc(rect, _rad(215), _rad(105), false, paintFor(_red));
    canvas.drawArc(rect, _rad(135), _rad(80), false, paintFor(_yellow));
    canvas.drawArc(rect, _rad(45), _rad(90), false, paintFor(_green));
    canvas.drawArc(rect, _rad(-5), _rad(50), false, paintFor(_blue));
    canvas.drawLine(
      center,
      Offset(center.dx + radius + stroke / 2, center.dy),
      paintFor(_blue)..strokeCap = StrokeCap.butt,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
