// Lecture tolérante d'une face pendant le scan.
//
// 1. On essaie de TROUVER la face (face_detector) : précis quand ça marche.
// 2. Sinon, on lit directement les 9 cases du grand carré guide affiché à
//    l'écran : il suffit que l'enfant mette à peu près son cube dedans.
//    Dans chaque case, on ne garde que le cœur et on écarte les pixels
//    sombres (fentes en plastique noir quand le cube est un peu décalé).
import 'dart:math' as math;

import 'color_lab.dart';
import 'face_detector.dart';
import 'frame_analyzer.dart';

/// Part du petit côté de l'image occupée par le carré guide affiché.
const guideFraction = 0.62;

/// Les 9 cases du carré guide.
List<CellSample> sampleGuide(
  YuvFrame f, {
  int rotation = 90,
  bool mirror = false,
}) {
  final rotated = rotation == 90 || rotation == 270;
  final wd = rotated ? f.height : f.width;
  final hd = rotated ? f.width : f.height;
  final side = guideFraction * math.min(wd, hd);
  final cell = side / 3;

  (int, int) toSensor(double xd, double yd) {
    var x = xd.round().clamp(0, wd - 1);
    final yy = yd.round().clamp(0, hd - 1);
    if (mirror) x = wd - 1 - x;
    return switch (rotation) {
      90 => (yy, f.height - 1 - x),
      180 => (f.width - 1 - x, f.height - 1 - yy),
      270 => (f.width - 1 - yy, x),
      _ => (x, yy),
    };
  }

  final out = <CellSample>[];
  for (var r = 0; r < 3; r++) {
    for (var c = 0; c < 3; c++) {
      final cx = wd / 2 + (c - 1) * cell, cy = hd / 2 + (r - 1) * cell;
      // 7 × 7 points sur les 56 % centraux de la case.
      final pixels = <Rgb>[];
      for (var i = -3; i <= 3; i++) {
        for (var j = -3; j <= 3; j++) {
          final (xs, ys) = toSensor(
            cx + i * cell * 0.093,
            cy + j * cell * 0.093,
          );
          pixels.add(f.pixel(xs, ys));
        }
      }
      // On écarte le tiers le plus sombre s'il est nettement plus sombre
      // (plastique noir entre deux autocollants, ombre portée).
      int luma(Rgb p) => (p.r * 299 + p.g * 587 + p.b * 114) ~/ 1000;
      pixels.sort((a, b) => luma(a).compareTo(luma(b)));
      final cut = pixels.length ~/ 3;
      final darkMed = luma(pixels[cut ~/ 2]);
      final brightMed = luma(pixels[cut + (pixels.length - cut) ~/ 2]);
      final kept = darkMed < brightMed * 0.6 ? pixels.sublist(cut) : pixels;
      final med = rgbToLab(medianRgb(kept));
      final d = [for (final p in kept) rgbToLab(p).distance(med)]..sort();
      out.add(CellSample(med, d[(d.length * 0.75).floor()]));
    }
  }
  return out;
}

/// Cadre du carré guide (coordonnées 0..1 de l'image affichée).
({double left, double top, double right, double bottom}) guideRect(
  int width,
  int height,
  int rotation,
) {
  final rotated = rotation == 90 || rotation == 270;
  final wd = rotated ? height : width;
  final hd = rotated ? width : height;
  final side = guideFraction * math.min(wd, hd);
  return (
    left: (wd - side) / 2 / wd,
    top: (hd - side) / 2 / hd,
    right: (wd + side) / 2 / wd,
    bottom: (hd + side) / 2 / hd,
  );
}

/// Les 9 cases ressemblent-elles à des autocollants (couleur franche et
/// régulière, pas du noir) ? Et a-t-on bien un cube, pas un mur uni : soit
/// les couleurs varient, soit on voit les fentes sombres entre les cases.
bool guideLooksLikeFace(List<CellSample> cells, {required int darkSeams}) {
  var good = 0;
  for (final c in cells) {
    if (c.lab.l > 22 && c.spread < 22) good++;
  }
  if (good < 7 || cells[4].lab.l <= 22 || cells[4].spread >= 26) {
    return false;
  }
  final varied = cells.any((c) => c.lab.distance(cells[4].lab) > 25);
  return varied || darkSeams >= 6;
}

/// Nombre de « fentes » sombres entre deux cases voisines du carré guide
/// (sur 12) : la marque d'un vrai cube, même quand toute la face est d'une
/// seule couleur.
int guideDarkSeams(YuvFrame f, {int rotation = 90, bool mirror = false}) {
  final rotated = rotation == 90 || rotation == 270;
  final wd = rotated ? f.height : f.width;
  final hd = rotated ? f.width : f.height;
  final side = guideFraction * math.min(wd, hd);
  final cell = side / 3;
  int lumaAt(double xd, double yd) {
    var x = xd.round().clamp(0, wd - 1);
    final yy = yd.round().clamp(0, hd - 1);
    if (mirror) x = wd - 1 - x;
    final (xs, ys) = switch (rotation) {
      90 => (yy, f.height - 1 - x),
      180 => (f.width - 1 - x, f.height - 1 - yy),
      270 => (f.width - 1 - yy, x),
      _ => (x, yy),
    };
    return f.y[ys * f.yRowStride + xs];
  }

  // Le plus sombre sur une petite bande autour de la frontière (le cube
  // peut être un peu décalé), comparé au cœur des deux cases.
  var seams = 0;
  final x0 = wd / 2 - 1.5 * cell, y0 = hd / 2 - 1.5 * cell;
  for (var r = 0; r < 3; r++) {
    for (var c = 0; c < 3; c++) {
      for (final (dc, dr) in const [(1, 0), (0, 1)]) {
        if (c + dc > 2 || r + dr > 2) continue;
        final ax = x0 + (c + 0.5) * cell, ay = y0 + (r + 0.5) * cell;
        final bx = ax + dc * cell, by = ay + dr * cell;
        final core = (lumaAt(ax, ay) + lumaAt(bx, by)) / 2;
        var darkest = 255;
        for (var k = -6; k <= 6; k++) {
          final t = 0.5 + k * 0.04; // de 26 % à 74 % du chemin
          final x = ax + (bx - ax) * t, y = ay + (by - ay) * t;
          // Trois points le long de la fente, on garde la médiane.
          final perpX = dr.toDouble(), perpY = dc.toDouble();
          final v = [
            for (final o in const [-0.2, 0.0, 0.2])
              lumaAt(x + perpX * o * cell, y + perpY * o * cell),
          ]..sort();
          if (v[1] < darkest) darkest = v[1];
        }
        if (darkest < core * 0.7) seams++;
      }
    }
  }
  return seams;
}

/// Lecture d'une image : face détectée si possible, sinon le carré guide.
/// Quand rien ne ressemble à une face, [DetectResult.face] contient quand
/// même la lecture du carré guide (pour le bouton « Prendre cette face »),
/// avec un [DetectResult.failure] qui dit pourquoi on ne capture pas seul.
DetectResult readFace(YuvFrame f, {int rotation = 90, bool mirror = false}) {
  final det = detectFace(f, rotation: rotation, mirror: mirror);
  final face = det.face;
  if (face != null &&
      (face.cx - 0.5).abs() < 0.22 &&
      (face.cy - 0.5).abs() < 0.22) {
    return det;
  }
  if (det.failure == DetectFailure.tooDark) return det;
  final cells = sampleGuide(f, rotation: rotation, mirror: mirror);
  final g = guideRect(f.width, f.height, rotation);
  final guided = FaceDetection(
    cells,
    g.left,
    g.top,
    g.right,
    g.bottom,
    guideFraction,
    guided: true,
  );
  final ok = guideLooksLikeFace(
    cells,
    darkSeams: guideDarkSeams(f, rotation: rotation, mirror: mirror),
  );
  return DetectResult(guided, ok ? DetectFailure.none : DetectFailure.notFound);
}
