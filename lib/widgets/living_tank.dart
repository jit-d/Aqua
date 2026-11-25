import 'dart:math' as math;
import 'package:flutter/material.dart';

class LivingTank extends StatefulWidget {
  final double progress; // 0.0 to 1.0
  final int totalMl;
  final int goalMl;

  const LivingTank({
    super.key,
    required this.progress,
    required this.totalMl,
    required this.goalMl,
  });

  @override
  State<LivingTank> createState() => _LivingTankState();
}

class _LivingTankState extends State<LivingTank>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final waterColor = scheme.primary.withValues(alpha: 0.85);
    final tankColor = isDark ? scheme.surfaceContainerHighest : Colors.white;

    return SizedBox(
      width: 220,
      height: 320,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // The Tank Background and Border
          Container(
            decoration: BoxDecoration(
              color: tankColor,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: scheme.primary.withValues(alpha: 0.2),
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: scheme.shadow.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
          ),
          
          // The Clipped Water & Waves
          ClipRRect(
            borderRadius: BorderRadius.circular(27),
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  size: const Size(220, 320),
                  painter: _TankPainter(
                    progress: widget.progress,
                    animationValue: _controller.value,
                    color: waterColor,
                  ),
                  child: child,
                );
              },
            ),
          ),

          // The Text Overlay
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${widget.totalMl}',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: widget.progress > 0.4
                          ? Colors.white
                          : scheme.onSurface,
                      shadows: widget.progress > 0.4
                          ? [const Shadow(color: Colors.black26, blurRadius: 4)]
                          : null,
                    ),
              ),
              Text(
                'of ${widget.goalMl} ml',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: widget.progress > 0.4
                          ? Colors.white70
                          : scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TankPainter extends CustomPainter {
  final double progress;
  final double animationValue;
  final Color color;

  _TankPainter({
    required this.progress,
    required this.animationValue,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // The height of the water
    final waterHeight = size.height * progress;
    final topY = size.height - waterHeight;

    // Wave animation parameters
    final waveHeight = 12.0;
    final waveLength = size.width;
    final phase = animationValue * 2 * math.pi;

    final path = Path();
    path.moveTo(0, topY);

    // Draw the wavy top line
    for (double x = 0; x <= size.width; x += 5) {
      final y = topY + math.sin((x / waveLength) * 2 * math.pi + phase) * waveHeight;
      path.lineTo(x, y);
    }

    // Draw the rest of the rectangle
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);

    // Draw a lighter wave behind it for depth
    final wave2Paint = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;
    final path2 = Path();
    path2.moveTo(0, topY);
    for (double x = 0; x <= size.width; x += 5) {
      final y = topY + math.sin((x / waveLength) * 2 * math.pi - phase) * waveHeight;
      path2.lineTo(x, y);
    }
    path2.lineTo(size.width, size.height);
    path2.lineTo(0, size.height);
    path2.close();
    canvas.drawPath(path2, wave2Paint);
  }

  @override
  bool shouldRepaint(covariant _TankPainter old) =>
      old.progress != progress || old.animationValue != animationValue;
}
