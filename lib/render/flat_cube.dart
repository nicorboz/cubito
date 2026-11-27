// Le cube « à plat » des consignes : toujours le même dessin, comme le cube
// tenu devant soi (grande face avant, dessus et côté droit en biais).
// Pas de 3D qui tourne : un enfant de 8 ans voit exactement son cube.
//
// Trois usages :
//  - geste d'une formule : tout est gris, la partie qui bouge est violette,
//    grosse flèche, et la partie violette esquisse le geste en boucle ;
//  - « place ton cube » : seuls les centres sont en couleur ;
//  - vraies couleurs (vérifier, préparer) : la partie qui bouge est
//    entourée de violet et le reste est estompé.
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../core/cube/cube.dart';
import '../shared/theme.dart';
import 'cube_view.dart' show cubeColorToColor, paintColorSymbol;

/// Violet « partie qui bouge » (n'est la couleur d'aucune face du cube).
const kMoveColor = Color(0xFF8B5CF6);
const kMoveColorDark = Color(0xFF6D3FE0);
const _grey = Color(0xFFE9E4EF);

/// Une case visible : face (F, U ou R), ligne, colonne.
typedef FlatCell = (Face, int, int);

/// Cases qui bougent avec un mouvement (vues sur F, U et R).
Set<FlatCell> cellsMovedBy(Move m) {
  final all = [
    for (var r = 0; r < 3; r++)
      for (var c = 0; c < 3; c++) (r, c),
  ];
  Set<FlatCell> on(Face f, Iterable<(int, int)> rc) => {
    for (final (r, c) in rc) (f, r, c),
  };
  return switch (m.kind) {
    MoveKind.r => {
      ...on(Face.f, [(0, 2), (1, 2), (2, 2)]),
      ...on(Face.u, [(0, 2), (1, 2), (2, 2)]),
      ...on(Face.r, all),
    },
    MoveKind.l => {
      ...on(Face.f, [(0, 0), (1, 0), (2, 0)]),
      ...on(Face.u, [(0, 0), (1, 0), (2, 0)]),
    },
    MoveKind.u => {
      ...on(Face.f, [(0, 0), (0, 1), (0, 2)]),
      ...on(Face.r, [(0, 0), (0, 1), (0, 2)]),
      ...on(Face.u, all),
    },
    MoveKind.d => {
      ...on(Face.f, [(2, 0), (2, 1), (2, 2)]),
      ...on(Face.r, [(2, 0), (2, 1), (2, 2)]),
    },
    MoveKind.f => {
      ...on(Face.f, all),
      ...on(Face.u, [(2, 0), (2, 1), (2, 2)]),
      ...on(Face.r, [(0, 0), (1, 0), (2, 0)]),
    },
    _ => const {},
  };
}

/// Indice de facette d'une case visible (U, R, F lues comme sur le patron).
int faceletOf(FlatCell cell) {
  final (f, r, c) = cell;
  return f.index * 9 + r * 3 + c;
}

/// Ce que montre le dessin.
enum FlatStyle {
  /// Tout gris, partie qui bouge en violet plein (gestes de formule).
  gesture,

  /// Seuls les centres en couleur (placer le cube).
  centers,

  /// Vraies couleurs ; partie qui bouge entourée de violet, reste estompé.
  colors,
}

class FlatCube extends StatefulWidget {
  const FlatCube({
    super.key,
    required this.cube,
    this.move,
    this.style = FlatStyle.gesture,
    this.glow = const {},
    this.rings = const {},
    this.animate = true,
    this.onSwipe,
    this.symbols = false,
    this.semanticLabel,
  });

  final Cube cube;

  /// Geste à montrer (flèche + partie violette), ou null.
  final Move? move;
  final FlatStyle style;

  /// Facettes à faire clignoter (pièce à repérer).
  final Set<int> glow;

  /// Facettes entourées (ex. les centres à vérifier pour tenir le cube).
  final Set<int> rings;

  /// La partie violette esquisse le geste en boucle.
  final bool animate;

  /// Glisser sur une ligne/colonne (mode « À toi ») : le mouvement fait.
  final ValueChanged<Move>? onSwipe;

  /// Mode daltonien.
  final bool symbols;
  final String? semanticLabel;

  @override
  State<FlatCube> createState() => _FlatCubeState();
}

class _FlatCubeState extends State<FlatCube>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );
  Offset? _dragStart;
  bool _dragDone = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.of(context).disableAnimations;
    if (reduce || !widget.animate) {
      _loop.stop();
      _loop.value = 0;
    } else if (!_loop.isAnimating) {
      _loop.repeat();
    }
  }

  @override
  void didUpdateWidget(FlatCube old) {
    super.didUpdateWidget(old);
    // Nouveau geste : l'esquisse repart du début.
    if (old.move != widget.move && _loop.isAnimating) {
      _loop.forward(from: 0);
      _loop.repeat();
    }
  }

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails d, Size size) {
    final start = _dragStart;
    if (start == null || _dragDone || widget.onSwipe == null) return;
    final drag = d.localPosition - start;
    if (drag.distance < 24) return;
    _dragDone = true;
    final m = flatSwipeToMove(FlatGeometry(size), start, drag);
    if (m != null) {
      HapticFeedback.selectionClick();
      widget.onSwipe!(m);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.semanticLabel,
      image: true,
      child: AspectRatio(
        aspectRatio: FlatGeometry.width / FlatGeometry.height,
        child: LayoutBuilder(
          builder: (context, c) {
            final size = c.biggest;
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanStart: widget.onSwipe == null
                  ? null
                  : (d) {
                      _dragStart = d.localPosition;
                      _dragDone = false;
                    },
              onPanUpdate: widget.onSwipe == null
                  ? null
                  : (d) => _onPanUpdate(d, size),
              child: AnimatedBuilder(
                animation: _loop,
                builder: (context, _) => CustomPaint(
                  size: size,
                  painter: FlatCubePainter(
                    cube: widget.cube,
                    move: widget.move,
                    style: widget.style,
                    glow: widget.glow,
                    rings: widget.rings,
                    phase: _loop.value,
                    symbols: widget.symbols,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Géométrie du dessin (repère de base 282 × 266, mis à l'échelle).
class FlatGeometry {
  FlatGeometry(Size size) : k = size.width / width;

  static const width = 282.0, height = 266.0;
  static const s = 180.0, dx = 62.0, dy = 46.0, x0 = 20.0, y0 = 20.0 + dy;
  static const c = s / 3;
  final double k;

  Offset _p(double x, double y) => Offset(x * k, y * k);

  /// Les 4 coins d'une case.
  List<Offset> cell(FlatCell cell) {
    final (f, r, cc) = cell;
    switch (f) {
      case Face.u:
        Offset p(double u, double v) =>
            _p(x0 + u * c + (3 - v) / 3 * dx, y0 - (3 - v) / 3 * dy);
        return [
          p(cc + 0.0, r + 0.0),
          p(cc + 1.0, r + 0.0),
          p(cc + 1.0, r + 1.0),
          p(cc + 0.0, r + 1.0),
        ];
      case Face.r:
        Offset p(double u, double v) =>
            _p(x0 + s + u / 3 * dx, y0 + v * c - u / 3 * dy);
        return [
          p(cc + 0.0, r + 0.0),
          p(cc + 1.0, r + 0.0),
          p(cc + 1.0, r + 1.0),
          p(cc + 0.0, r + 1.0),
        ];
      default:
        final x = x0 + cc * c, y = y0 + r * c;
        return [_p(x, y), _p(x + c, y), _p(x + c, y + c), _p(x, y + c)];
    }
  }

  List<Offset> get body => [
    _p(x0 - 4, y0 + s + 4),
    _p(x0 - 4, y0),
    _p(x0 + dx - 4, y0 - dy - 4),
    _p(x0 + s + dx + 4, y0 - dy - 4),
    _p(x0 + s + dx + 4, y0 + s - dy),
    _p(x0 + s + 4, y0 + s + 4),
  ];

  /// Face (et case) sous un point, ou null.
  FlatCell? hit(Offset p) {
    for (final f in [Face.f, Face.u, Face.r]) {
      for (var r = 0; r < 3; r++) {
        for (var cc = 0; cc < 3; cc++) {
          if (_inside(cell((f, r, cc)), p)) return (f, r, cc);
        }
      }
    }
    return null;
  }

  static bool _inside(List<Offset> poly, Offset p) {
    var sign = 0;
    for (var i = 0; i < poly.length; i++) {
      final a = poly[i], b = poly[(i + 1) % poly.length];
      final cr = (b.dx - a.dx) * (p.dy - a.dy) - (b.dy - a.dy) * (p.dx - a.dx);
      final s = cr > 0 ? 1 : -1;
      if (sign == 0) {
        sign = s;
      } else if (s != sign) {
        return false;
      }
    }
    return true;
  }

  /// Début et fin de la flèche d'un mouvement (face avant).
  (Offset, Offset)? arrow(Move m) {
    final ccw = m.turns == 3;
    double col(int i) => x0 + (i + 0.5) * c;
    const lo = y0 + 0.12 * c, hi = y0 + s - 0.12 * c;
    const le = x0 + 0.12 * c, ri = x0 + s - 0.12 * c;
    final pair = switch (m.kind) {
      MoveKind.r =>
        ccw ? ((col(2), lo), (col(2), hi)) : ((col(2), hi), (col(2), lo)),
      MoveKind.l =>
        ccw ? ((col(0), hi), (col(0), lo)) : ((col(0), lo), (col(0), hi)),
      MoveKind.u =>
        ccw
            ? ((le, col(0) - x0 + y0), (ri, col(0) - x0 + y0))
            : ((ri, col(0) - x0 + y0), (le, col(0) - x0 + y0)),
      MoveKind.d =>
        ccw
            ? ((ri, col(2) - x0 + y0), (le, col(2) - x0 + y0))
            : ((le, col(2) - x0 + y0), (ri, col(2) - x0 + y0)),
      _ => null,
    };
    if (pair == null) return null;
    final ((ax, ay), (bx, by)) = pair;
    return (_p(ax, ay), _p(bx, by));
  }

  Offset get frontCenter => _p(x0 + s / 2, y0 + s / 2);
  double get frontRadius => s * 0.3 * k;
}

/// Traduit un glissement sur le dessin en mouvement (vocabulaire enfant).
/// Face avant : lignes du haut/bas, colonnes de gauche/droite. Dessus :
/// glisser à droite = la face avant tourne comme une horloge (F).
Move? flatSwipeToMove(FlatGeometry g, Offset start, Offset drag) {
  final cell = g.hit(start);
  if (cell == null) return null;
  final (f, r, c) = cell;
  final horizontal = drag.dx.abs() > drag.dy.abs();
  switch (f) {
    case Face.f:
      if (horizontal) {
        final left = drag.dx < 0;
        if (r == 0) return Move(MoveKind.u, left ? 1 : 3);
        if (r == 2) return Move(MoveKind.d, left ? 3 : 1);
      } else {
        final up = drag.dy < 0;
        if (c == 2) return Move(MoveKind.r, up ? 1 : 3);
        if (c == 0) return Move(MoveKind.l, up ? 3 : 1);
      }
      return null;
    case Face.u:
      if (horizontal) return Move(MoveKind.f, drag.dx > 0 ? 1 : 3);
      return null;
    case Face.r:
      if (!horizontal && c == 0) return Move(MoveKind.f, drag.dy > 0 ? 1 : 3);
      return null;
    default:
      return null;
  }
}

class FlatCubePainter extends CustomPainter {
  FlatCubePainter({
    required this.cube,
    this.move,
    this.style = FlatStyle.gesture,
    this.glow = const {},
    this.rings = const {},
    this.phase = 0,
    this.symbols = false,
  });

  final Set<int> rings;

  final Cube cube;
  final Move? move;
  final FlatStyle style;
  final Set<int> glow;
  final double phase;
  final bool symbols;

  /// Esquisse : part vite, revient doucement, pause (0 → 1 → 0).
  static double nudge(double p) {
    if (p < 0.2) return 1 - math.pow(1 - p / 0.2, 3).toDouble();
    if (p < 0.55) return 1 - Curves.easeInOut.transform((p - 0.2) / 0.35);
    return 0;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final g = FlatGeometry(size);
    final m = move;
    final moved = m == null || m.kind.isRotation
        ? <FlatCell>{}
        : cellsMovedBy(m);

    // Décalage de l'esquisse (translation, ou rotation pour F).
    final k = nudge(phase);
    var shift = Offset.zero;
    var angle = 0.0;
    if (m != null && !m.kind.isRotation) {
      final ccw = m.turns == 3;
      final d = 14 * g.k * k;
      shift = switch (m.kind) {
        MoveKind.r => Offset(0, ccw ? d : -d),
        MoveKind.l => Offset(0, ccw ? -d : d),
        MoveKind.u => Offset(ccw ? d : -d, 0),
        MoveKind.d => Offset(ccw ? -d : d, 0),
        _ => Offset.zero,
      };
      if (m.kind == MoveKind.f) angle = (ccw ? -1 : 1) * 0.16 * k;
    }

    // Plastique noir.
    final body = Path()..addPolygon(g.body, true);
    canvas.drawPath(body, Paint()..color = CubeColors.ink);
    canvas.drawPath(
      body,
      Paint()
        ..color = CubeColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6 * g.k
        ..strokeJoin = StrokeJoin.round,
    );

    void drawCell(FlatCell cell, {required bool moving}) {
      final pts = g.cell(cell);
      final center = pts.reduce((a, b) => a + b) / 4;
      final inset = [for (final p in pts) center + (p - center) * 0.84];
      var poly = inset;
      if (moving) {
        if (angle != 0) {
          final o = g.frontCenter;
          poly = [
            for (final p in inset)
              o +
                  Offset(
                    (p - o).dx * math.cos(angle) - (p - o).dy * math.sin(angle),
                    (p - o).dx * math.sin(angle) + (p - o).dy * math.cos(angle),
                  ),
          ];
        } else {
          poly = [for (final p in inset) p + shift];
        }
      }
      final (f, r, c) = cell;
      final facelet = faceletOf(cell);
      final real = cubeColorToColor(cube[facelet]);
      Color fill;
      switch (style) {
        case FlatStyle.gesture:
          fill = moving ? kMoveColor : _grey;
        case FlatStyle.centers:
          fill = (r == 1 && c == 1) ? real : Colors.white;
        case FlatStyle.colors:
          // Ce qui ne bouge pas est un peu estompé, sauf les centres : ce
          // sont les repères pour tenir le cube.
          final isCenter = r == 1 && c == 1;
          fill = (moved.isEmpty || moving || isCenter)
              ? real
              : Color.lerp(real, _grey, 0.5)!;
      }
      if (f == Face.r) fill = Color.lerp(fill, CubeColors.ink, 0.12)!;
      final path = Path()..addPolygon(poly, true);
      canvas.drawPath(path, Paint()..color = fill);
      // Partie à tourner (dans ses vraies couleurs) : gros contour foncé
      // + liseré blanc, lisible sur toutes les couleurs.
      if ((style == FlatStyle.colors && moving) || rings.contains(facelet)) {
        canvas.drawPath(
          path,
          Paint()
            ..color = CubeColors.ink
            ..style = PaintingStyle.stroke
            ..strokeWidth = 6 * g.k
            ..strokeJoin = StrokeJoin.round,
        );
        canvas.drawPath(
          path,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.2 * g.k
            ..strokeJoin = StrokeJoin.round,
        );
      }
      if (glow.contains(facelet)) {
        canvas.drawPath(
          path,
          Paint()
            ..color = const Color(0xFFFF2D95).withValues(
              alpha:
                  0.25 + 0.75 * (0.5 + 0.5 * math.sin(phase * 2 * math.pi * 2)),
            )
            ..style = PaintingStyle.stroke
            ..strokeWidth = 5 * g.k
            ..strokeJoin = StrokeJoin.round,
        );
      }
      if (symbols &&
          (style == FlatStyle.colors ||
              (style == FlatStyle.centers && r == 1 && c == 1))) {
        paintColorSymbol(canvas, poly, cube[facelet]);
      }
    }

    // D'abord ce qui ne bouge pas, puis la partie qui bouge (au-dessus).
    for (final face in [Face.u, Face.r, Face.f]) {
      for (var r = 0; r < 3; r++) {
        for (var c = 0; c < 3; c++) {
          final cell = (face, r, c);
          if (!moved.contains(cell)) drawCell(cell, moving: false);
        }
      }
    }
    for (final cell in moved) {
      drawCell(cell, moving: true);
    }

    if (m != null && !m.kind.isRotation) _paintArrow(canvas, g, m);
    if (m != null && m.turns == 2) _badge(canvas, size, g);
  }

  void _paintArrow(Canvas canvas, FlatGeometry g, Move m) {
    final w = 15 * g.k;
    late List<Offset> pts;
    if (m.kind == MoveKind.f) {
      final cw = m.turns != 3;
      final o = g.frontCenter, r = g.frontRadius;
      final a0 = cw ? 200 * math.pi / 180 : -20 * math.pi / 180;
      final sweep = (cw ? 1 : -1) * 250 * math.pi / 180;
      pts = [
        for (var t = 0; t <= 30; t++)
          o +
              Offset(
                math.cos(a0 + sweep * t / 30) * r,
                math.sin(a0 + sweep * t / 30) * r,
              ),
      ];
    } else {
      final a = g.arrow(m);
      if (a == null) return;
      pts = [a.$1, a.$2];
    }
    final tip = pts.last;
    final from = pts.length > 2 ? pts[pts.length - 3] : pts.first;
    final dir = (tip - from) / (tip - from).distance;
    final perp = Offset(-dir.dy, dir.dx);
    final hl = 26 * g.k, hw = 22 * g.k;
    final base = tip - dir * hl;
    final head = Path()
      ..moveTo(tip.dx + dir.dx * 4 * g.k, tip.dy + dir.dy * 4 * g.k)
      ..lineTo(base.dx + perp.dx * hw, base.dy + perp.dy * hw)
      ..lineTo(base.dx - perp.dx * hw, base.dy - perp.dy * hw)
      ..close();
    final shaftPts = pts.length > 2
        ? [...pts.sublist(0, pts.length - 2), base]
        : [pts.first, base];
    final shaft = Path()..addPolygon(shaftPts, false);
    final round = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(
      shaft,
      round
        ..color = CubeColors.ink
        ..strokeWidth = w + 11 * g.k,
    );
    canvas.drawPath(
      head,
      Paint()
        ..color = CubeColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8 * g.k
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(
      shaft,
      round
        ..color = Colors.white
        ..strokeWidth = w,
    );
    canvas.drawPath(head, Paint()..color = Colors.white);
  }

  void _badge(Canvas canvas, Size size, FlatGeometry g) {
    final tp = TextPainter(
      text: TextSpan(
        text: '×2',
        style: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 30 * g.k,
          fontWeight: FontWeight.w900,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final r = Rect.fromLTWH(
      size.width - tp.width - 26 * g.k,
      size.height - tp.height - 18 * g.k,
      tp.width + 20 * g.k,
      tp.height + 8 * g.k,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(r, Radius.circular(r.height / 2)),
      Paint()..color = CubeColors.ink,
    );
    tp.paint(canvas, r.topLeft + Offset(10 * g.k, 4 * g.k));
  }

  @override
  bool shouldRepaint(FlatCubePainter old) => true;
}
