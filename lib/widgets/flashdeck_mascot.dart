import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class FlashDeckMascot extends StatelessWidget {
  const FlashDeckMascot({this.size = 96, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: 'มาสคอตบัตรคำ FlashDeck',
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(painter: _FlashDeckMascotPainter()),
      ),
    );
  }
}

class _FlashDeckMascotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.shortestSide / 100;
    canvas
      ..save()
      ..translate((size.width - 100 * scale) / 2, (size.height - 100 * scale) / 2)
      ..scale(scale);

    final shadowPaint = Paint()..color = AppTheme.green.withValues(alpha: .12);
    final cardPaint = Paint()..color = AppTheme.green;
    final paperPaint = Paint()..color = AppTheme.cream;
    final foldPaint = Paint()..color = AppTheme.orange;
    final strokePaint = Paint()
      ..color = AppTheme.green
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(15, 12, 70, 76),
        const Radius.circular(15),
      ),
      shadowPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(13, 7, 70, 76),
        const Radius.circular(15),
      ),
      cardPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(19, 13, 58, 64),
        const Radius.circular(10),
      ),
      paperPaint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(63, 13)
        ..lineTo(77, 27)
        ..lineTo(63, 27)
        ..close(),
      foldPaint,
    );

    final eyePaint = Paint()..color = AppTheme.ink;
    canvas
      ..drawCircle(const Offset(38, 42), 3, eyePaint)
      ..drawCircle(const Offset(58, 42), 3, eyePaint)
      ..drawArc(
        const Rect.fromLTWH(39, 44, 18, 14),
        .15,
        2.8,
        false,
        strokePaint,
      );

    final limbPaint = Paint()
      ..color = AppTheme.green
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas
      ..drawLine(const Offset(13, 49), const Offset(5, 57), limbPaint)
      ..drawLine(const Offset(83, 49), const Offset(91, 42), limbPaint)
      ..drawLine(const Offset(35, 84), const Offset(32, 91), limbPaint)
      ..drawLine(const Offset(62, 84), const Offset(65, 91), limbPaint)
      ..restore();
  }

  @override
  bool shouldRepaint(covariant _FlashDeckMascotPainter oldDelegate) => false;
}
