import 'dart:math';
import 'package:flutter/material.dart';

class WavePainter extends CustomPainter {
  final double value;
  final double percentage;
  final Color waveColor;

  WavePainter(this.value, this.percentage, this.waveColor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = waveColor.withOpacity(0.5);
    final path = Path();

    double yOffset = size.height * (1 - percentage);
    path.moveTo(0, yOffset);

    for (double i = 0; i <= size.width; i++) {
      path.lineTo(i, yOffset + sin((i / size.width * 2 * pi) + (value * 2 * pi)) * 8);
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}