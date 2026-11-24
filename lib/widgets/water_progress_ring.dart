import 'dart:math' as math;
import 'package:flutter/material.dart';

class WaterProgressRing extends StatelessWidget {
  final double progress;
  final int totalMl;
  final int goalMl;
  final int remainingMl;

  const WaterProgressRing({
    super.key,
    required this.progress,
    required this.totalMl,
    required this.goalMl,
    required this.remainingMl,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 240,
      height: 240,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) => CustomPaint(
              size: const Size(240, 240),
              painter: _RingPainter(value, scheme.primary, scheme.primaryContainer),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$totalMl',
                  style: Theme.of(context)
                      .textTheme
                      .displaySmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              Text('of $goalMl ml',
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 8),
              Text('${(progress * 100).round()}%',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: scheme.primary, fontWeight: FontWeight.bold)),
              Text('$remainingMl ml left',
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color fg;
  final Color bg;
  _RingPainter(this.progress, this.fg, this.bg);

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 12;
    final bgPaint = Paint()
      ..color = bg
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    final fgPaint = Paint()
      ..color = fg
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.progress != progress;
}