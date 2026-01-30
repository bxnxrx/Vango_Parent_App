import 'package:flutter/material.dart';

import 'package:vango_parent_app/theme/app_colors.dart';

class MockMap extends StatelessWidget {
  const MockMap({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        height: 180,
        width: double.infinity,
        child: CustomPaint(
          painter: _MockMapPainter(),
        ),
      ),
    );
  }
}

class _MockMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF8EC5FC), Color(0xFFE0C3FC)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final pathPaint = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(size.width * 0.1, size.height * 0.8)
      ..quadraticBezierTo(size.width * 0.2, size.height * 0.4, size.width * 0.4, size.height * 0.5)
      ..quadraticBezierTo(size.width * 0.6, size.height * 0.7, size.width * 0.8, size.height * 0.2);
    canvas.drawPath(path, pathPaint);

    void drawPin(Offset offset, Color color, IconData icon) {
      final pinPaint = Paint()..color = color;
      canvas.drawCircle(offset, 14, pinPaint);
      final textPainter = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(icon.codePoint),
          style: TextStyle(
            fontSize: 16,
            fontFamily: icon.fontFamily,
            package: icon.fontPackage,
            color: Colors.white,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, offset - Offset(textPainter.width / 2, textPainter.height / 2));
    }

    drawPin(Offset(size.width * 0.1, size.height * 0.8), AppColors.accent, Icons.home_filled);
    drawPin(Offset(size.width * 0.65, size.height * 0.6), AppColors.warning, Icons.directions_bus_filled);
    drawPin(Offset(size.width * 0.8, size.height * 0.2), AppColors.success, Icons.school);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
