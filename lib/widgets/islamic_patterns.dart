import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme.dart';

/// Draws a subtle geometric Islamic star pattern as a background decoration.
class IslamicPatternPainter extends CustomPainter {
  IslamicPatternPainter({required this.color, this.opacity = 0.06});

  final Color color;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withAlpha((255 * opacity).round())
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    const spacing = 48.0;
    final cols = (size.width / spacing).ceil() + 1;
    final rows = (size.height / spacing).ceil() + 1;

    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < cols; col++) {
        final cx = col * spacing + (row.isOdd ? spacing / 2 : 0);
        final cy = row * spacing;
        _drawStar(canvas, Offset(cx, cy), spacing * 0.3, paint);
      }
    }
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    const points = 8;
    final innerRadius = radius * 0.45;
    final path = Path();

    for (var i = 0; i < points * 2; i++) {
      final angle = (i * math.pi / points) - math.pi / 2;
      final r = i.isEven ? radius : innerRadius;
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant IslamicPatternPainter oldDelegate) =>
      color != oldDelegate.color || opacity != oldDelegate.opacity;
}

/// Gradient + star pattern used behind the app bar and status bar.
class IslamicAppBarBackground extends StatelessWidget {
  const IslamicAppBarBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final startColor = isDark ? AppColors.emeraldDark : AppColors.emerald;
    final endColor = isDark ? const Color(0xFF021F14) : AppColors.emeraldLight;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [startColor, endColor],
        ),
      ),
      child: CustomPaint(
        painter: IslamicPatternPainter(
          color: Colors.white,
          opacity: isDark ? 0.05 : 0.08,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

/// Small decorative divider with an Islamic diamond motif.
class IslamicDivider extends StatelessWidget {
  const IslamicDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.outline;
    return Row(
      children: [
        Expanded(child: Divider(color: color, thickness: 0.5)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Transform.rotate(
            angle: math.pi / 4,
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: AppColors.gold.withAlpha(160),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
        ),
        Expanded(child: Divider(color: color, thickness: 0.5)),
      ],
    );
  }
}
