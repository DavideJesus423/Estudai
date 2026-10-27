import 'package:flutter/material.dart';

/// Cartão pastel que representa um material de estudo (PDF).
class StudyMaterialCard extends StatelessWidget {
  const StudyMaterialCard({
    super.key,
    required this.subject,
    required this.title,
    required this.color,
  });

  final String subject;
  final String title;
  final Color color;

  static const TextStyle _labelStyle = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    color: Colors.black,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(5, 8, 5, 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(subject, style: _labelStyle),
          ),
          const Expanded(child: Center(child: _PdfBadge())),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              title,
              style: _labelStyle.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _PdfBadge extends StatelessWidget {
  const _PdfBadge();

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomPaint(size: const Size(22, 20), painter: _PageIconPainter()),
          const SizedBox(height: 2),
          const Text(
            'PDF',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

/// Folha com canto dobrado.
class _PageIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeJoin = StrokeJoin.round
      ..color = Colors.black;
    final w = size.width;
    final h = size.height;

    final page = Path()
      ..moveTo(1, 1)
      ..lineTo(w * 0.6, 1)
      ..lineTo(w - 1, h * 0.35)
      ..lineTo(w - 1, h - 1)
      ..lineTo(1, h - 1)
      ..close();
    final fold = Path()
      ..moveTo(w * 0.6, 1)
      ..lineTo(w * 0.6, h * 0.35)
      ..lineTo(w - 1, h * 0.35);

    canvas.drawPath(page, paint);
    canvas.drawPath(fold, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
