// Cubito : la mascotte de l'appli, dans le style du logo (cube brillant
// bleu / jaune / rouge) avec un visage expressif. Dessinée en code.
//
// Au repos : flotte doucement, cligne des yeux, regarde autour d'elle.
// Quand on la touche : petit saut (écrasement → bond → réception) et clin
// d'œil. Tout s'arrête si « réduire les animations » est activé.
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';
import '../theme.dart';

class Cubito extends StatefulWidget {
  const Cubito({super.key, this.size = 200, this.onTap});

  final double size;

  /// Appelé quand l'enfant touche Cubito (après le petit saut).
  final VoidCallback? onTap;

  @override
  State<Cubito> createState() => _CubitoState();
}

class _CubitoState extends State<Cubito> with TickerProviderStateMixin {
  // Boucle de vie : 6 s (flottement, clignement, regard).
  late final AnimationController _idle = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  );

  // Saut quand on le touche.
  late final AnimationController _hop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );
  bool _reduce = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduce = MediaQuery.of(context).disableAnimations;
    if (_reduce) {
      _idle.stop();
      _idle.value = 0;
    } else if (!_idle.isAnimating) {
      _idle.repeat();
    }
  }

  @override
  void dispose() {
    _idle.dispose();
    _hop.dispose();
    super.dispose();
  }

  void _tap() {
    HapticFeedback.lightImpact();
    if (!_reduce) _hop.forward(from: 0);
    widget.onTap?.call();
  }

  /// Saut : écrasement (anticipation) → bond → réception écrasée → repos.
  static (double lift, double squash) _hopCurve(double t) {
    if (t == 0 || t == 1) return (0, 0);
    if (t < 0.15) {
      return (0, 0.12 * Curves.easeOut.transform(t / 0.15)); // s'écrase
    }
    if (t < 0.6) {
      final u = (t - 0.15) / 0.45;
      return (
        math.sin(u * math.pi),
        -0.06 * math.sin(u * math.pi),
      ); // bond (s'étire)
    }
    if (t < 0.75) {
      return (0, 0.09 * math.sin((t - 0.6) / 0.15 * math.pi)); // réception
    }
    return (0, 0);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: AppLocalizations.of(context).mascotLabel,
      button: widget.onTap != null,
      child: GestureDetector(
        onTap: _tap,
        child: SizedBox.square(
          dimension: widget.size,
          child: AnimatedBuilder(
            animation: Listenable.merge([_idle, _hop]),
            builder: (context, _) {
              final t = _idle.value;
              final (lift, squash) = _hopCurve(_hop.value);
              // Clignement vers 30 % et 80 % du cycle ; clin d'œil au saut.
              double blinkAt(double c) => (t - c).abs() < 0.012 ? 0.08 : 1;
              final blink = math.min(blinkAt(0.3), blinkAt(0.8));
              final wink = _hop.value > 0.1 && _hop.value < 0.8;
              // Regard : à gauche, au centre, à droite, au centre.
              final look = switch ((t * 4).floor()) {
                0 => const Offset(0, 0),
                1 => const Offset(-1, 0.2),
                2 => const Offset(0, 0),
                _ => const Offset(1, -0.2),
              };
              return CustomPaint(
                painter: CubitoPainter(
                  bob: _reduce ? 0 : math.sin(t * 2 * math.pi * 2),
                  lift: lift,
                  squash: squash,
                  eyeOpen: blink,
                  winkLeft: wink,
                  look: look,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class CubitoPainter extends CustomPainter {
  CubitoPainter({
    this.bob = 0,
    this.lift = 0,
    this.squash = 0,
    this.eyeOpen = 1,
    this.winkLeft = false,
    this.look = Offset.zero,
  });

  final double bob, lift, squash, eyeOpen;
  final bool winkLeft;
  final Offset look;

  static const _blue = Color(0xFF1E66F5);
  static const _yellow = Color(0xFFFFD500);
  static const _red = Color(0xFFE53935);

  @override
  void paint(Canvas canvas, Size size) {
    final m = size.shortestSide;
    final w = m * 0.56; // côté de la face avant
    final depth = m * 0.2;
    final baseLeft = (size.width - w - depth) / 2;
    final ground = size.height * 0.9;
    final floatY = bob * m * 0.02 + lift * m * 0.16;
    final bottom = ground - m * 0.06 - floatY;

    // Ombre au sol (teintée), plus petite quand Cubito est en l'air.
    final shadowK = 1 - lift * 0.35 - bob * 0.03;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width / 2, ground),
        width: m * 0.62 * shadowK,
        height: m * 0.07 * shadowK,
      ),
      Paint()
        ..color = CubeColors.ink.withValues(alpha: 0.16)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // Écrasement / étirement autour du bas du cube.
    canvas.save();
    canvas.translate(size.width / 2, bottom);
    canvas.scale(1 + squash * 0.6, 1 - squash);
    canvas.translate(-size.width / 2, -bottom);

    final top = bottom - w;
    final fTL = Offset(baseLeft, top), fTR = Offset(baseLeft + w, top);
    final fBL = Offset(baseLeft, bottom), fBR = Offset(baseLeft + w, bottom);
    final back = Offset(depth, -depth * 0.72);

    // Corps : plastique noir arrondi.
    final body = Path()
      ..addPolygon([fBL, fTL, fTL + back, fTR + back, fBR + back, fBR], true);
    final bodyPaint = Paint()
      ..color = const Color(0xFF15111C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = m * 0.05
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(body, Paint()..color = const Color(0xFF15111C));
    canvas.drawPath(body, bodyPaint);

    _face(canvas, fTL + back, fTR + back, fTL, _yellow, m); // dessus
    _face(
      canvas,
      fTR,
      fTR + back,
      fBR,
      Color.lerp(_red, Colors.black, 0.12)!,
      m,
    ); // côté
    _face(canvas, fTL, fTR, fBL, _blue, m); // devant

    // Visage dans le carré avant (coordonnées 0..100).
    _inFace(canvas, fTL, fTR, fBL, () => _drawFaceFeatures(canvas));
    canvas.restore();
  }

  void _drawFaceFeatures(Canvas canvas) {
    final ink = Paint()..color = const Color(0xFF15111C);
    final white = Paint()..color = Colors.white;
    // Yeux : grands, avec reflets ; le gauche fait un clin d'œil au saut.
    for (final (ex, left) in [(31.0, true), (69.0, false)]) {
      final open = (left && winkLeft) ? 0.06 : eyeOpen;
      final eye = Rect.fromCenter(
        center: Offset(ex, 41),
        width: 25,
        height: 31 * open,
      );
      if (open < 0.2) {
        // Œil fermé : un petit arc souriant.
        final arc = Path()
          ..moveTo(ex - 10, 42)
          ..quadraticBezierTo(ex, 48, ex + 10, 42);
        canvas.drawPath(
          arc,
          Paint()
            ..color = const Color(0xFF15111C)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4.5
            ..strokeCap = StrokeCap.round,
        );
        continue;
      }
      canvas.drawOval(eye.inflate(3.2), ink);
      canvas.drawOval(eye, white);
      final pupil = Offset(ex + look.dx * 4.5, 43 + look.dy * 3);
      canvas.drawOval(
        Rect.fromCenter(center: pupil, width: 13, height: 16 * open),
        ink,
      );
      canvas.drawCircle(pupil + const Offset(2.6, -3.6), 2.8, white); // reflet
      canvas.drawCircle(pupil + const Offset(-2.4, 3.2), 1.2, white);
    }
    // Sourcils.
    final brow = Paint()
      ..color = const Color(0xFF15111C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
      Path()
        ..moveTo(21, 20)
        ..quadraticBezierTo(31, 15, 40, 19),
      brow,
    );
    canvas.drawPath(
      Path()
        ..moveTo(60, 19)
        ..quadraticBezierTo(69, 15, 79, 20),
      brow,
    );
    // Joues.
    final cheek = Paint()
      ..color = const Color(0xFFFF8FB1).withValues(alpha: 0.85);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(15, 63), width: 15, height: 8),
      cheek,
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(85, 63), width: 15, height: 8),
      cheek,
    );
    // Sourire ouvert avec la langue.
    final mouth = Path()
      ..moveTo(37, 62)
      ..quadraticBezierTo(50, 65, 63, 62)
      ..quadraticBezierTo(61, 80, 50, 80)
      ..quadraticBezierTo(39, 80, 37, 62)
      ..close();
    canvas.drawPath(mouth, ink);
    canvas.save();
    canvas.clipPath(mouth);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(50, 82), width: 18, height: 12),
      Paint()..color = const Color(0xFFFF6F91),
    );
    canvas.restore();
  }

  /// Une face de 3 × 3 autocollants brillants (reflet en haut, ombre en bas).
  void _face(
    Canvas canvas,
    Offset o,
    Offset xEnd,
    Offset yEnd,
    Color color,
    double m,
  ) {
    _inFace(canvas, o, xEnd, yEnd, () {
      const cell = 100 / 3;
      for (var r = 0; r < 3; r++) {
        for (var c = 0; c < 3; c++) {
          final rect = Rect.fromLTWH(
            c * cell + 3,
            r * cell + 3,
            cell - 6,
            cell - 6,
          );
          final rr = RRect.fromRectAndRadius(rect, const Radius.circular(6));
          canvas.drawRRect(rr, Paint()..color = color);
          // Ombre interne en bas, reflet en haut : effet « bonbon » du logo.
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(rect.left, rect.bottom - 6, rect.width, 6),
              const Radius.circular(6),
            ),
            Paint()..color = Color.lerp(color, Colors.black, 0.18)!,
          );
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(
                rect.left + 3,
                rect.top + 2.5,
                rect.width - 6,
                rect.height * 0.32,
              ),
              const Radius.circular(5),
            ),
            Paint()..color = Colors.white.withValues(alpha: 0.32),
          );
        }
      }
    });
  }

  void _inFace(
    Canvas canvas,
    Offset o,
    Offset xEnd,
    Offset yEnd,
    VoidCallback draw,
  ) {
    final ax = (xEnd - o) / 100, ay = (yEnd - o) / 100;
    canvas.save();
    canvas.transform(
      Float64List.fromList([
        ax.dx,
        ax.dy,
        0,
        0,
        ay.dx,
        ay.dy,
        0,
        0,
        0,
        0,
        1,
        0,
        o.dx,
        o.dy,
        0,
        1,
      ]),
    );
    draw();
    canvas.restore();
  }

  @override
  bool shouldRepaint(CubitoPainter old) => true;
}
