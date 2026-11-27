// Widget du cube 3D : dessin, animation, rotation au doigt et mouvements
// par glissement sur une ligne ou une colonne.
import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../core/cube/cube.dart';
import '../shared/theme.dart';
import 'cube_controller.dart';
import 'cube_scene.dart';
import 'math3d.dart';

/// Couleur d'écran de chaque couleur du cube.
Color cubeColorToColor(CubeColor c) => switch (c) {
  CubeColor.white => CubeColors.cubeWhite,
  CubeColor.yellow => CubeColors.cubeYellow,
  CubeColor.red => CubeColors.cubeRed,
  CubeColor.orange => CubeColors.cubeOrange,
  CubeColor.blue => CubeColors.cubeBlue,
  CubeColor.green => CubeColors.cubeGreen,
};

class CubeView extends StatefulWidget {
  const CubeView({
    super.key,
    required this.controller,
    this.onSwipeMove,
    this.onStickerTap,
    this.allowOrbit = true,
    this.semanticLabel,
    this.symbols = false,
  });

  final CubeController controller;

  /// Appelé quand l'enfant glisse le doigt sur une ligne ou une colonne.
  /// Si null, glisser sur le cube le fait tourner (caméra).
  final ValueChanged<Move>? onSwipeMove;

  /// Appelé quand l'enfant touche un autocollant (correction du scan).
  final ValueChanged<int>? onStickerTap;

  /// Autoriser la rotation de la caméra au doigt.
  final bool allowOrbit;

  /// Mode daltonien : un symbole sur chaque couleur.
  final bool symbols;

  final String? semanticLabel;

  @override
  State<CubeView> createState() => _CubeViewState();
}

class _CubeViewState extends State<CubeView> with TickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _last = Duration.zero;

  // Clignotement des cases surlignées.
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  // Geste en cours.
  _Gesture? _gesture;
  List<ScenePolygon> _lastScene = const [];
  Projector? _lastProjector;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
    widget.controller.addListener(_onControllerChange);
    _syncPulse();
  }

  @override
  void didUpdateWidget(CubeView old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_onControllerChange);
      widget.controller.addListener(_onControllerChange);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    widget.controller.nudgeEnabled = !MediaQuery.of(context).disableAnimations;
  }

  void _onControllerChange() {
    _syncPulse();
    if (mounted) setState(() {});
  }

  void _syncPulse() {
    if (widget.controller.highlighted.isNotEmpty) {
      if (!_pulse.isAnimating) _pulse.repeat(reverse: true);
    } else if (_pulse.isAnimating) {
      _pulse.stop();
    }
  }

  void _onTick(Duration elapsed) {
    final delta = elapsed - _last;
    _last = elapsed;
    if (widget.controller.needsTick) widget.controller.tick(delta);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChange);
    _ticker.dispose();
    _pulse.dispose();
    super.dispose();
  }

  // --- Gestes ------------------------------------------------------------

  void _onPanStart(DragStartDetails d) {
    final hit = _hitSticker(d.localPosition);
    if (hit != null &&
        widget.onSwipeMove != null &&
        !widget.controller.isAnimating) {
      _gesture = _Gesture.swipe(d.localPosition, hit);
    } else if (widget.allowOrbit) {
      _gesture = _Gesture.orbit();
    } else {
      _gesture = null;
    }
  }

  void _onPanUpdate(DragUpdateDetails d) {
    final g = _gesture;
    if (g == null) return;
    if (g.facelet == null) {
      widget.controller.orbit(d.delta.dx * 0.012, d.delta.dy * 0.012);
      return;
    }
    if (g.done) return;
    final drag = d.localPosition - g.start;
    if (drag.distance < 18) return;
    g.done = true;
    final move = _moveFromSwipe(g.facelet!, drag);
    if (move != null) {
      HapticFeedback.selectionClick();
      widget.onSwipeMove!(move);
    }
  }

  void _onPanEnd(DragEndDetails d) => _gesture = null;

  int? _hitSticker(Offset p) {
    for (final poly in _lastScene.reversed) {
      if (poly.contains(p)) return poly.facelet;
    }
    return null;
  }

  /// Traduit un glissement sur un autocollant en mouvement de face.
  Move? _moveFromSwipe(int facelet, Offset drag) {
    final proj = _lastProjector;
    if (proj == null) return null;
    final pos = stickerPositions[facelet];
    final nrm = stickerNormals[facelet];
    final p = V3(pos.x.toDouble(), pos.y.toDouble(), pos.z.toDouble());
    final n = V3(nrm.x.toDouble(), nrm.y.toDouble(), nrm.z.toDouble());
    final at = p + n * 0.5;
    final screenAt = proj.project(at);
    final dir = drag / drag.distance;

    // Direction 3D (le long de la face) qui ressemble le plus au geste.
    V3? best;
    var bestScore = -2.0;
    for (var axis = 0; axis < 3; axis++) {
      if ([nrm.x, nrm.y, nrm.z][axis] != 0) continue;
      for (final s in const [-1.0, 1.0]) {
        final t = V3.unit(axis) * s;
        final sd = proj.project(at + t * 0.4) - screenAt;
        if (sd.distance < 1e-6) continue;
        final score =
            (sd / sd.distance).dx * dir.dx + (sd / sd.distance).dy * dir.dy;
        if (score > bestScore) {
          bestScore = score;
          best = t;
        }
      }
    }
    if (best == null || bestScore < 0.5) return null;

    // Axe de rotation = normale × direction ; la rotation est de +90°.
    final a = n.cross(best);
    final axis = [a.x.abs(), a.y.abs(), a.z.abs()].indexOf(1.0);
    final sign = a[axis] > 0 ? 1 : -1;
    final layer = [pos.x, pos.y, pos.z][axis];
    if (layer == 0) return null; // tranche du milieu : pas dans la méthode

    final kind = switch ((axis, layer)) {
      (0, 1) => MoveKind.r,
      (0, _) => MoveKind.l,
      (1, 1) => MoveKind.u,
      (1, _) => MoveKind.d,
      (2, 1) => MoveKind.f,
      _ => MoveKind.b,
    };
    // +90° autour de +axe = quart horaire pour L/D/B, antihoraire pour R/U/F.
    final clockwise = (layer == 1) ? sign < 0 : sign > 0;
    return Move(kind, clockwise ? 1 : 3);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return Semantics(
      label: widget.semanticLabel,
      image: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        onDoubleTap: widget.allowOrbit ? c.resetCamera : null,
        onTapUp: widget.onStickerTap == null
            ? null
            : (d) {
                final f = _hitSticker(d.localPosition);
                if (f != null) widget.onStickerTap!(f);
              },
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = constraints.biggest;
            final projector = Projector(size, c.camera);
            final scene = buildScene(
              cube: c.cube,
              projector: projector,
              colorOf: cubeColorToColor,
              animation: c.animation,
              focus: c.focus,
            );
            _lastScene = scene;
            _lastProjector = projector;
            return AnimatedBuilder(
              animation: _pulse,
              builder: (context, _) => CustomPaint(
                size: size,
                painter: CubePainter(
                  scene: scene,
                  projector: projector,
                  arrow: c.isAnimating ? null : c.arrow,
                  highlighted: c.highlighted,
                  pulse: _pulse.value,
                  symbols: widget.symbols,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Gesture {
  _Gesture.swipe(this.start, this.facelet);
  _Gesture.orbit() : start = Offset.zero, facelet = null;
  final Offset start;
  final int? facelet;
  bool done = false;
}

/// Dessine la scène, la flèche et les cases surlignées.
class CubePainter extends CustomPainter {
  CubePainter({
    required this.scene,
    required this.projector,
    this.arrow,
    this.highlighted = const {},
    this.pulse = 0,
    this.symbols = false,
  });

  final bool symbols;
  final List<ScenePolygon> scene;
  final Projector projector;
  final Move? arrow;
  final Set<int> highlighted;
  final double pulse;

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()..isAntiAlias = true;
    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..strokeJoin = StrokeJoin.round;
    for (final p in scene) {
      final path = p.path;
      canvas.drawPath(path, fill..color = p.color);
      // Un fin contour de la même couleur évite les fentes entre faces.
      canvas.drawPath(path, edge..color = p.color);
    }

    if (symbols) {
      for (final p in scene) {
        if (p.cubeColor != null) {
          paintColorSymbol(canvas, p.points, p.cubeColor!);
        }
      }
    }

    // Cases surlignées : contour blanc qui pulse.
    if (highlighted.isNotEmpty) {
      final hl = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.shortestSide * 0.012
        ..color = Color.lerp(Colors.white, const Color(0xFFFF2D95), pulse)!;
      for (final p in scene) {
        if (p.facelet != null && highlighted.contains(p.facelet)) {
          canvas.drawPath(p.path, hl);
        }
      }
    }

    final m = arrow;
    if (m != null) {
      final paths = arrowPaths(m, camera: projector.cameraWorld);
      for (var k = 0; k < paths.length; k++) {
        _paintArrow(canvas, size, m, paths[k], label: k == 0);
      }
    }
  }

  void _paintArrow(
    Canvas canvas,
    Size size,
    Move m,
    List<V3> pts3, {
    bool label = true,
  }) {
    final pts = [for (final p in pts3) projector.project(p)];
    final w = size.shortestSide * 0.05; // flèche épaisse, lisible de loin

    // Pointe : grande, arrondie, dans le prolongement des derniers points.
    final tip = pts.last;
    final from = pts[pts.length - 4];
    final dir = (tip - from) / (tip - from).distance;
    final perp = Offset(-dir.dy, dir.dx);
    final headLen = w * 2.1, headW = w * 1.55;
    final base = tip - dir * headLen;
    final head = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(base.dx + perp.dx * headW, base.dy + perp.dy * headW)
      ..quadraticBezierTo(
        base.dx + dir.dx * w * 0.3,
        base.dy + dir.dy * w * 0.3,
        base.dx - perp.dx * headW,
        base.dy - perp.dy * headW,
      )
      ..close();

    // Corps : on s'arrête au pied de la pointe.
    final body = <Offset>[];
    for (final p in pts) {
      if ((p - tip).distance < headLen * 0.9) break;
      body.add(p);
    }
    body.add(base + dir * (w * 0.2));
    final shaft = Path()..addPolygon(body, false);

    const outline = Color(0xFF2B2140);
    final round = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    // Ombre douce sous la flèche (elle « flotte » au-dessus du cube).
    final shadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.save();
    canvas.translate(0, w * 0.25);
    canvas.drawPath(
      shaft,
      Paint.from(round)
        ..color = shadow.color
        ..maskFilter = shadow.maskFilter
        ..strokeWidth = w * 1.3,
    );
    canvas.drawPath(head, shadow);
    canvas.restore();
    // Contour foncé puis blanc : lisible sur toutes les couleurs.
    canvas.drawPath(
      shaft,
      round
        ..color = outline
        ..strokeWidth = w * 1.35,
    );
    canvas.drawPath(
      head,
      Paint()
        ..color = outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.35
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(
      shaft,
      round
        ..color = Colors.white
        ..strokeWidth = w,
    );
    canvas.drawPath(head, Paint()..color = Colors.white);
    const yellow = Color(0xFFFFB300);
    // « ×2 » pour un double mouvement.
    if (m.turns == 2 && label) {
      final tp = TextPainter(
        text: TextSpan(
          text: '×2',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w900,
            fontSize: w * 2.2,
            color: yellow,
            shadows: const [Shadow(color: outline, blurRadius: 4)],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        tip + perp * headW * 1.6 - Offset(tp.width / 2, tp.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(CubePainter old) => true;
}

/// Dessine le symbole d'une couleur au centre d'un autocollant (mode
/// daltonien) : ○ blanc, ★ jaune, ♥ rouge, ▲ orange, ● bleu, ■ vert.
void paintColorSymbol(Canvas canvas, List<Offset> pts, CubeColor c) {
  var cx = 0.0, cy = 0.0;
  for (final p in pts) {
    cx += p.dx;
    cy += p.dy;
  }
  final center = Offset(cx / pts.length, cy / pts.length);
  var r = double.infinity;
  for (final p in pts) {
    final d = (p - center).distance;
    if (d < r) r = d;
  }
  r *= 0.45;
  if (r < 2) return;
  final paint = Paint()..color = const Color(0x992B2140);
  final path = Path();
  switch (c) {
    case CubeColor.white:
      canvas.drawCircle(
        center,
        r * 0.8,
        paint
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.3,
      );
      return;
    case CubeColor.blue:
      canvas.drawCircle(center, r * 0.8, paint);
      return;
    case CubeColor.green:
      canvas.drawRect(Rect.fromCircle(center: center, radius: r * 0.7), paint);
      return;
    case CubeColor.orange:
      path
        ..moveTo(center.dx, center.dy - r)
        ..lineTo(center.dx + r * 0.9, center.dy + r * 0.7)
        ..lineTo(center.dx - r * 0.9, center.dy + r * 0.7)
        ..close();
    case CubeColor.yellow:
      for (var k = 0; k < 10; k++) {
        final a = -math.pi / 2 + k * math.pi / 5;
        final rr = k.isEven ? r : r * 0.45;
        final p = center + Offset(math.cos(a) * rr, math.sin(a) * rr);
        k == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
      }
      path.close();
    case CubeColor.red:
      final w = r * 0.55;
      path
        ..addOval(
          Rect.fromCircle(
            center: center + Offset(-w * 0.8, -w * 0.5),
            radius: w,
          ),
        )
        ..addOval(
          Rect.fromCircle(
            center: center + Offset(w * 0.8, -w * 0.5),
            radius: w,
          ),
        );
      final tri = Path()
        ..moveTo(center.dx - r * 1.05, center.dy - r * 0.25)
        ..lineTo(center.dx + r * 1.05, center.dy - r * 0.25)
        ..lineTo(center.dx, center.dy + r)
        ..close();
      path.addPath(tri, Offset.zero);
  }
  canvas.drawPath(path, paint);
}
