import 'dart:math';
import 'package:flutter/material.dart';

class GlowingBubble extends StatefulWidget {
  final double percentage; // 0.0 to 1.0
  const GlowingBubble({super.key, required this.percentage});

  @override
  State<GlowingBubble> createState() => _GlowingBubbleState();
}

class _GlowingBubbleState extends State<GlowingBubble> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.blueAccent.withOpacity(0.4),
                blurRadius: 30,
                spreadRadius: 10,
              ),
            ],
            border: Border.all(color: Colors.white.withOpacity(0.5), width: 4),
          ),
          child: ClipOval(
            child: Stack(
              children: [
                // Wave Animation
                CustomPaint(
                  painter: WavePainter(_controller.value, widget.percentage),
                  child: Container(),
                ),
                // Percentage Text
                Center(
                  child: Text(
                    "${(widget.percentage * 100).toInt()}%",
                    style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white, shadows: [Shadow(blurRadius: 10, color: Colors.black26)]),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class WavePainter extends CustomPainter {
  final double value;
  final double percentage;
  WavePainter(this.value, this.percentage);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.blueAccent.withOpacity(0.8);
    final path = Path();

    double yOffset = size.height * (1 - percentage);
    path.moveTo(0, yOffset);

    for (double i = 0; i <= size.width; i++) {
      path.lineTo(i, yOffset + sin((i / size.width * 2 * pi) + (value * 2 * pi)) * 10);
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}