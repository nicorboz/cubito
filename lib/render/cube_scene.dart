// Construction de la scène 3D : les 27 petits cubes, leurs autocollants,
// la projection en perspective et l'ordre de dessin (du plus loin au plus
// proche). Ne dépend que de dart:ui (pas de widgets).
import 'dart:math' as math;
import 'dart:ui';

import '../core/cube/cube.dart';
import 'math3d.dart';

/// Orientation de la caméra autour du cube.
class CubeCamera {
  const CubeCamera({this.yaw = -0.55, this.pitch = 0.5});

  /// Rotation horizontale (radians). Négatif : on voit la face droite.
  final double yaw;

  /// Rotation verticale (radians). Positif : on voit le dessus.
  final double pitch;

  /// Distance de la caméra au centre du cube (unités : 1 = un petit cube).
  static const distance = 10.0;

  Mat3 get view => Mat3.rotation(0, pitch) * Mat3.rotation(1, yaw);

  CubeCamera copyWith({double? yaw, double? pitch}) =>
      CubeCamera(yaw: yaw ?? this.yaw, pitch: pitch ?? this.pitch);
}

/// Animation en cours d'une tranche : axe, couches qui tournent, angle.
class LayerAnimation {
  const LayerAnimation(this.axis, this.layers, this.angle);
  final int axis;
  final Set<int> layers;

  /// Angle en radians, sens direct autour de +axe.
  final double angle;

  /// Angle total (fin d'animation) d'un mouvement.
  static double targetAngle(Move m) {
    // Quart horaire vu depuis la face = -90° autour de l'axe orienté vers
    // la face, soit -direction × 90° autour de +axe.
    final quarters = m.turns == 3 ? -1 : m.turns;
    return -m.kind.direction * quarters * math.pi / 2;
  }
}

/// Tranche mise en avant (le reste du cube est estompé).
class LayerFocus {
  const LayerFocus(this.axis, this.layers);
  final int axis;
  final Set<int> layers;

  factory LayerFocus.of(Move m) => LayerFocus(m.kind.axis, m.kind.layers);
}

/// Un polygone prêt à dessiner.
class ScenePolygon {
  ScenePolygon(this.points, this.color, {this.facelet, this.cubeColor});
  final List<Offset> points;
  final Color color;

  /// Couleur logique de l'autocollant (pour les symboles daltoniens).
  final CubeColor? cubeColor;

  /// Indice de la facette pour un autocollant, null pour le plastique noir.
  final int? facelet;

  Path get path => Path()..addPolygon(points, true);

  bool contains(Offset p) {
    // Test « point dans polygone convexe » par les signes des produits.
    var sign = 0;
    for (var i = 0; i < points.length; i++) {
      final a = points[i], b = points[(i + 1) % points.length];
      final cross =
          (b.dx - a.dx) * (p.dy - a.dy) - (b.dy - a.dy) * (p.dx - a.dx);
      if (cross.abs() < 1e-9) continue;
      final s = cross > 0 ? 1 : -1;
      if (sign == 0) {
        sign = s;
      } else if (s != sign) {
        return false;
      }
    }
    return true;
  }
}

/// Projection perspective pour une taille d'écran donnée.
class Projector {
  Projector(this.size, this.camera) : view = camera.view {
    // Échelle choisie pour que le cube tienne toujours dans le cadre,
    // quelle que soit l'orientation (rayon de la sphère englobante ≈ 2,6).
    const radius = 2.65;
    const d = CubeCamera.distance;
    final half = size.shortestSide / 2;
    focal = half * 0.95 * math.sqrt(d * d - radius * radius) / radius;
    center = Offset(size.width / 2, size.height / 2);
  }

  final Size size;
  final CubeCamera camera;
  final Mat3 view;
  late final double focal;
  late final Offset center;

  /// Point du monde → repère caméra.
  V3 toView(V3 world) => view.apply(world);

  /// Point du repère caméra → écran.
  Offset projectView(V3 v) {
    final k = focal / (CubeCamera.distance - v.z);
    return Offset(center.dx + v.x * k, center.dy - v.y * k);
  }

  Offset project(V3 world) => projectView(toView(world));

  /// Position de la caméra dans le repère du monde.
  V3 get cameraWorld =>
      view.transposed.apply(const V3(0, 0, CubeCamera.distance));
}

/// Couleurs d'affichage des 6 couleurs du cube.
typedef ColorOf = Color Function(CubeColor c);

/// Construit la liste des polygones visibles, dans l'ordre de dessin.
List<ScenePolygon> buildScene({
  required Cube cube,
  required Projector projector,
  required ColorOf colorOf,
  LayerAnimation? animation,
  Color body = const Color(0xFF1C1626),
  LayerFocus? focus,
}) {
  final camWorld = projector.cameraWorld;
  final light = const V3(-0.35, 0.75, 0.9).normalized;

  // Rotation de la tranche animée (identité sinon).
  final rot = animation == null
      ? Mat3.identity
      : Mat3.rotation(animation.axis, animation.angle);
  bool moving(Vec3 p) {
    if (animation == null) return false;
    return animation.layers.contains([p.x, p.y, p.z][animation.axis]);
  }

  // Autocollants regroupés par petit cube.
  final stickersOf = <Vec3, List<int>>{};
  for (var i = 0; i < 54; i++) {
    stickersOf.putIfAbsent(stickerPositions[i], () => []).add(i);
  }

  final cubies = <_Cubie>[];
  for (var x = -1; x <= 1; x++) {
    for (var y = -1; y <= 1; y++) {
      for (var z = -1; z <= 1; z++) {
        if (x == 0 && y == 0 && z == 0) continue;
        final p = Vec3(x, y, z);
        final m = moving(p);
        final center = V3(x.toDouble(), y.toDouble(), z.toDouble());
        final c = m ? rot.apply(center) : center;
        cubies.add(_Cubie(p, m, c, projector.toView(c).z));
      }
    }
  }

  // Ordre des deux groupes (tranche qui tourne / reste du cube) : on dessine
  // d'abord celui qui est du côté opposé à la caméra.
  var movingFirst = false;
  if (animation != null && animation.layers.length < 3) {
    final layer = animation.layers.first;
    final boundary = layer * 0.5;
    final camSide = camWorld[animation.axis] - boundary;
    movingFirst = camSide * layer < 0;
  }
  cubies.sort((a, b) {
    if (a.moving != b.moving) {
      return (a.moving == movingFirst) ? -1 : 1;
    }
    return a.depth.compareTo(b.depth); // le plus loin d'abord
  });

  final polys = <ScenePolygon>[];
  Color shade(Color c, V3 normalView) {
    final k = 0.68 + 0.32 * math.max(0.0, normalView.dot(light));
    return Color.from(alpha: c.a, red: c.r * k, green: c.g * k, blue: c.b * k);
  }

  // Mise en avant : ce qui ne bouge pas est estompé (couleurs fanées).
  bool inFocus(Vec3 p) =>
      focus == null || focus.layers.contains([p.x, p.y, p.z][focus.axis]);
  const fadedSticker = Color(0xFFE4E0E8), fadedBody = Color(0xFFB3ADBC);

  for (final cb in cubies) {
    final r = cb.moving ? rot : Mat3.identity;
    final lit = inFocus(cb.pos);
    final base = V3(
      cb.pos.x.toDouble(),
      cb.pos.y.toDouble(),
      cb.pos.z.toDouble(),
    );
    for (var axis = 0; axis < 3; axis++) {
      for (final s in const [-1, 1]) {
        final n = V3.unit(axis) * s.toDouble();
        final nw = r.apply(n);
        final faceCenter = r.apply(base + n * 0.5);
        // Face cachée (tournée vers l'arrière) : on ne la dessine pas.
        if (nw.dot(camWorld - faceCenter) <= 0) continue;
        final t1 = V3.unit((axis + 1) % 3), t2 = V3.unit((axis + 2) % 3);
        final nv = projector.view.apply(nw);

        // Plastique noir de la face.
        polys.add(
          ScenePolygon([
            for (final (a, b) in const [(-1, -1), (1, -1), (1, 1), (-1, 1)])
              projector.project(
                r.apply(base + n * 0.5 + t1 * (0.5 * a) + t2 * (0.5 * b)),
              ),
          ], shade(lit ? body : Color.lerp(body, fadedBody, 0.6)!, nv)),
        );

        // Autocollant éventuel sur cette face.
        final facelet = (stickersOf[cb.pos] ?? const <int>[]).where((i) {
          final sn = stickerNormals[i];
          return [sn.x, sn.y, sn.z][axis] == s;
        });
        if (facelet.isEmpty) continue;
        final i = facelet.first;
        polys.add(
          ScenePolygon(
            [
              for (final o in _roundedSquare)
                projector.project(
                  r.apply(base + n * 0.502 + t1 * o.dx + t2 * o.dy),
                ),
            ],
            shade(
              lit
                  ? colorOf(cube[i])
                  : Color.lerp(colorOf(cube[i]), fadedSticker, 0.8)!,
              nv,
            ),
            facelet: i,
            cubeColor: cube[i],
          ),
        );
      }
    }
  }
  return polys;
}

class _Cubie {
  _Cubie(this.pos, this.moving, this.center, this.depth);
  final Vec3 pos;
  final bool moving;
  final V3 center;
  final double depth;
}

/// Carré aux coins arrondis (demi-côté 0,43, rayon 0,1), dans le plan.
final List<Offset> _roundedSquare = () {
  const h = 0.43, r = 0.11;
  final pts = <Offset>[];
  const corners = [(1, 1), (-1, 1), (-1, -1), (1, -1)];
  for (var k = 0; k < 4; k++) {
    final (sx, sy) = corners[k];
    final cx = sx * (h - r), cy = sy * (h - r);
    final start = k * math.pi / 2;
    for (var j = 0; j <= 3; j++) {
      final a = start + j * (math.pi / 2) / 3;
      pts.add(Offset(cx + r * math.cos(a), cy + r * math.sin(a)));
    }
  }
  return pts;
}();

/// Chemin 3D d'une flèche qui suit le mouvement : elle épouse la tranche
/// qui tourne en passant d'une face à l'autre (anneau aux coins arrondis
/// autour de la tranche), du côté visible par la caméra.
/// Pour F : un arc d'horloge sur la face avant. Pour les rotations du cube
/// entier (x, y) : un grand anneau qui flotte autour du cube.
List<V3>? arrowPath(Move m, {V3 camera = const V3(5, 5, 8), double? offset}) {
  final kind = m.kind;
  if (kind == MoveKind.b || kind == MoveKind.z) return null;
  // Sens réel du mouvement autour de +axe.
  final dir = LayerAnimation.targetAngle(m) > 0 ? 1.0 : -1.0;
  final axis = kind.axis;

  // Plan perpendiculaire à l'axe : (u, v) tourne dans le sens direct.
  V3 compose(double u, double v, double w) => switch (axis) {
    0 => V3(w, u, v), // (y, z)
    1 => V3(v, w, u), // (z, x)
    _ => V3(u, v, w), // (x, y)
  };
  final camU = axis == 0 ? camera.y : (axis == 1 ? camera.z : camera.x);
  final camV = axis == 0 ? camera.z : (axis == 1 ? camera.x : camera.y);

  if (kind == MoveKind.f) {
    // Arc d'horloge sur la face avant (270°).
    const z = 1.6;
    const start = 2.6;
    return [
      for (var k = 0; k <= 36; k++)
        V3(
          math.cos(start + dir * k * 0.13) * 0.95,
          math.sin(start + dir * k * 0.13) * 0.95,
          z,
        ),
    ];
  }

  final whole = kind.isRotation;
  final w = whole ? (offset ?? 1.1) : kind.layers.first.toDouble();
  final radius = whole ? (axis == 0 ? 1.95 : 2.25) : 1.64;
  // « Carré arrondi » (superellipse) : colle aux faces, arrondi aux arêtes.
  const n = 6.0;
  V3 ring(double t) {
    final c = math.cos(t), sn = math.sin(t);
    final u = radius * c.sign * math.pow(c.abs(), 2 / n);
    final v = radius * sn.sign * math.pow(sn.abs(), 2 / n);
    return whole
        ? compose(radius * c, radius * sn, w)
        : compose(u.toDouble(), v.toDouble(), w);
  }

  // Centré sur la direction de la caméra, sur 150° (ou 120° pour le cube).
  final center = math.atan2(camV, camU);
  final half = (whole ? 120 : 150) * math.pi / 360;
  final t0 = center - dir * half, t1 = center + dir * half;
  return [for (var k = 0; k <= 40; k++) ring(t0 + (t1 - t0) * k / 40)];
}

/// Tous les chemins de flèche d'un mouvement : un seul pour une tranche,
/// deux anneaux parallèles pour le cube entier (« tout tourne »).
List<List<V3>> arrowPaths(Move m, {V3 camera = const V3(5, 5, 8)}) {
  if (m.kind == MoveKind.y) {
    // Tourner à plat : un anneau en haut et un en bas, « tout tourne ».
    return [
      for (final o in const [-1.1, 1.1])
        ?arrowPath(m, camera: camera, offset: o),
    ];
  }
  if (m.kind.isRotation) {
    // Retourner : un seul grand anneau, sur le côté droit du cube.
    final p = arrowPath(m, camera: camera, offset: 1.85);
    return p == null ? const [] : [p];
  }
  final p = arrowPath(m, camera: camera);
  return p == null ? const [] : [p];
}
