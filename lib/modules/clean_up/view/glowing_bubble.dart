import 'package:flutter/material.dart';
import 'wave_painter.dart';

class GlowingBubble extends StatelessWidget {
  final double percentage;
  final double animationValue;
  final bool isCleaning;
  final bool showResults;

  const GlowingBubble({
    super.key,
    required this.percentage,
    required this.animationValue,
    required this.isCleaning,
    required this.showResults,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        width: showResults ? 140 : 220,
        height: showResults ? 140 : 220,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(isCleaning ? 0.4 : 0.1),
              blurRadius: isCleaning ? 50 : 20,
              spreadRadius: isCleaning ? 10 : 2,
            )
          ],
        ),
        child: ClipOval(
          child: CustomPaint(
            painter: WavePainter(
                animationValue,
                percentage,
                theme.colorScheme.primary
            ),
            child: Center(
              child: Text(
                "${(percentage * 100).toInt()}%",
                style: TextStyle(
                  fontSize: showResults ? 28 : 42,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}