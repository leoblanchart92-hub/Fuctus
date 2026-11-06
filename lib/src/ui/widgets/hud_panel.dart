/// HudPanel — translucent HUD panel with corner brackets.
library;

import 'package:flutter/material.dart';

import '../hud_theme.dart';

class HudPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? borderColor;
  final double cornerRadius;
  final bool glow;

  const HudPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(12),
    this.borderColor,
    this.cornerRadius = 14,
    this.glow = false,
  });

  @override
  Widget build(BuildContext context) {
    final border = borderColor ?? HudPalette.panelBorder;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: HudPalette.panel,
        borderRadius: BorderRadius.circular(cornerRadius),
        border: Border.all(color: border, width: 1),
        boxShadow: [
          if (glow)
            BoxShadow(
              color: HudPalette.cyan.withValues(alpha: 0.14),
              blurRadius: 18,
              spreadRadius: 0.5,
            ),
        ],
      ),
      child: CustomPaint(
        painter: _CornerBrackets(),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class _CornerBrackets extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = HudPalette.cyan.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    const len = 15.0;
    const inset = 2.0;
    final w = size.width, h = size.height;

    void bracket(Offset origin, Offset hDir, Offset vDir) {
      final p = Path()
        ..moveTo(origin.dx + hDir.dx * len, origin.dy + hDir.dy * len)
        ..lineTo(origin.dx, origin.dy)
        ..lineTo(origin.dx + vDir.dx * len, origin.dy + vDir.dy * len);
      canvas.drawPath(p, paint);
    }

    bracket(const Offset(inset, inset), const Offset(1, 0), const Offset(0, 1)); // top-left
    bracket(Offset(w - inset, inset), const Offset(-1, 0), const Offset(0, 1)); // top-right
    bracket(Offset(w - inset, h - inset), const Offset(-1, 0), const Offset(0, -1)); // bottom-right
    bracket(Offset(inset, h - inset), const Offset(1, 0), const Offset(0, -1)); // bottom-left
  }

  @override
  bool shouldRepaint(covariant _CornerBrackets old) => false;
}
