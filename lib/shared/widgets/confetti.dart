// Confettis de réussite (dessinés en code, 2 secondes).
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../theme.dart';

class Confetti extends StatefulWidget {
  const Confetti({super.key});

  @override
  State<Confetti> createState() => _ConfettiState();
}

class _ConfettiState extends State<Confetti>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  );
  final _pieces = List.generate(70, (i) => _Piece(math.Random(i)));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!MediaQuery.of(context).disableAnimations &&
        !_c.isAnimating &&
        _c.value == 0) {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => CustomPaint(
          size: Size.infinite,
          painter: _ConfettiPainter(_pieces, _c.value),
        ),
      ),
    );
  }
}

class _Piece {
  _Piece(math.Random r)
    : x = r.nextDouble(),
      delay = r.nextDouble() * 0.3,
      speed = 0.7 + r.nextDouble() * 0.6,
      sway = r.nextDouble() * 2 * math.pi,
      color = const [
        CubeColors.cubeRed,
        CubeColors.cubeYellow,
        CubeColors.cubeGreen,
        CubeColors.cubeBlue,
        CubeColors.cubeOrange,
        Color(0xFFFF6FB5),
      ][r.nextInt(6)];
  final double x, delay, speed, sway;
  final Color color;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.pieces, this.t);
  final List<_Piece> pieces;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    if (t == 0 || t == 1) return;
    for (final p in pieces) {
      final local = ((t - p.delay) / (1 - p.delay)).clamp(0.0, 1.0);
      if (local == 0) continue;
      final y = -20 + local * p.speed * (size.height + 40);
      final x = p.x * size.width + math.sin(local * 8 + p.sway) * 18;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(local * 10 + p.sway);
      canvas.drawRect(
        const Rect.fromLTWH(-5, -3, 10, 6),
        Paint()..color = p.color.withValues(alpha: 1 - local * 0.5),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}
