// Détection de la face du cube dans une image de la caméra.
//
// Au lieu de lire 9 points fixes (fragile : le cube n'a jamais exactement
// la taille du carré guide), on CHERCHE la face :
//  1. on regarde le centre de l'image sur une petite grille (64 × 64) ;
//  2. les autocollants sont clairs ou colorés, le plastique est sombre ;
//  3. on bouche les fentes noires entre autocollants (fermeture) pour
//     obtenir un seul bloc, celui qui contient le centre de l'image ;
//  4. on rogne les petites fuites vers le fond (histogrammes) ;
//  5. le cadre du bloc est découpé en 3 × 3 ; dans chaque case on prend la
//     couleur médiane des pixels clairs (on ignore plastique et reflets).
// Dart pur : testé avec des images fabriquées (fond, bruit, décalage…).
import 'dart:math' as math;

import 'color_lab.dart';
import 'frame_analyzer.dart';

/// Résultat : la face trouvée (cadre en coordonnées 0..1 de l'image
/// affichée droite) et la mesure des 9 cases.
class FaceDetection {
  const FaceDetection(
    this.cells,
    this.left,
    this.top,
    this.right,
    this.bottom,
    this.coverage, {
    this.guided = false,
  });

  /// Lue directement dans le carré guide (cube non détecté précisément).
  final bool guided;

  final List<CellSample> cells;
  final double left, top, right, bottom;

  /// Taille de la face par rapport à la zone analysée (0..1).
  final double coverage;

  double get cx => (left + right) / 2;
  double get cy => (top + bottom) / 2;
  double get size => ((right - left) + (bottom - top)) / 2;
}

/// Pourquoi on n'a pas trouvé la face.
enum DetectFailure { none, tooDark, notFound, tooSmall }

class DetectResult {
  const DetectResult(this.face, this.failure);
  final FaceDetection? face;
  final DetectFailure failure;
}

/// Zone analysée : carré centré, part du petit côté de l'image affichée.
const searchFraction = 0.92;
const _n = 64;

DetectResult detectFace(YuvFrame f, {int rotation = 90, bool mirror = false}) {
  final rotated = rotation == 90 || rotation == 270;
  final wd = rotated ? f.height : f.width;
  final hd = rotated ? f.width : f.height;
  final side = searchFraction * math.min(wd, hd);
  final ox = (wd - side) / 2, oy = (hd - side) / 2;

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

  int lumaAt(double xd, double yd) {
    final (xs, ys) = toSensor(xd, yd);
    return f.y[ys * f.yRowStride + xs];
  }

  int chromaAt(double xd, double yd) {
    final (xs, ys) = toSensor(xd, yd);
    final i = (ys >> 1) * f.uvRowStride + (xs >> 1) * f.uvPixelStride;
    return (f.u[i] - 128).abs() + (f.v[i] - 128).abs();
  }

  // 1. Petite grille : luminosité et saturation.
  final luma = List<int>.filled(_n * _n, 0);
  final chroma = List<int>.filled(_n * _n, 0);
  final step = side / _n;
  for (var j = 0; j < _n; j++) {
    for (var i = 0; i < _n; i++) {
      final xd = ox + (i + 0.5) * step, yd = oy + (j + 0.5) * step;
      luma[j * _n + i] = lumaAt(xd, yd);
      chroma[j * _n + i] = chromaAt(xd, yd);
    }
  }
  final sorted = [...luma]..sort();
  final p90 = sorted[(sorted.length * 0.9).floor()];
  if (p90 < 45) return const DetectResult(null, DetectFailure.tooDark);

  // 2. Autocollant = nettement plus clair que le plastique noir (le plus
  //    sombre de l'image), ou bien coloré.
  final p5 = sorted[(sorted.length * 0.05).floor()];
  final threshold = math.min(
    math.max(p5 + 22, (p5 * 1.8).round()),
    (p90 * 0.6).round(),
  );
  bool sticker(int k) =>
      luma[k] > threshold || (chroma[k] > 30 && luma[k] > p5 + 10);
  final mask = List<bool>.generate(_n * _n, sticker);

  // 3. Méthode principale : les 9 autocollants, un par un (marche avec
  //    n'importe quel fond, car le plastique noir entoure chaque autocollant).
  final grid = _stickerGrid(mask);
  if (grid != null) {
    return _finish(
      f,
      grid.$1,
      grid.$2,
      grid.$3 - grid.$1 + 1,
      grid.$4 - grid.$2 + 1,
      ox,
      oy,
      step,
      wd,
      hd,
      threshold,
      toSensor,
    );
  }

  // 4. Secours (cube sans plastique noir…) : fermeture = dilater puis
  //    éroder pour boucher les fentes et obtenir un seul bloc.
  List<bool> morph(List<bool> m, {required bool dilate}) {
    final out = List<bool>.filled(_n * _n, false);
    for (var j = 0; j < _n; j++) {
      for (var i = 0; i < _n; i++) {
        var v = !dilate;
        for (var dj = -1; dj <= 1; dj++) {
          for (var di = -1; di <= 1; di++) {
            final x = i + di, y = j + dj;
            final inside = x >= 0 && y >= 0 && x < _n && y < _n;
            final b = inside ? m[y * _n + x] : false;
            if (dilate && b) v = true;
            if (!dilate && !b) v = false;
          }
        }
        out[j * _n + i] = v;
      }
    }
    return out;
  }

  final closed = morph(
    morph(morph(morph(mask, dilate: true), dilate: true), dilate: false),
    dilate: false,
  );

  // Bloc qui contient le centre (ou le pixel « autocollant » le plus proche).
  var seed = -1;
  var best = 1 << 30;
  for (var j = 0; j < _n; j++) {
    for (var i = 0; i < _n; i++) {
      if (!closed[j * _n + i]) continue;
      final d = (i - _n ~/ 2) * (i - _n ~/ 2) + (j - _n ~/ 2) * (j - _n ~/ 2);
      if (d < best) {
        best = d;
        seed = j * _n + i;
      }
    }
  }
  if (seed < 0 || best > (_n * 0.2) * (_n * 0.2)) {
    return const DetectResult(null, DetectFailure.notFound);
  }
  final comp = List<bool>.filled(_n * _n, false);
  final stack = [seed];
  comp[seed] = true;
  while (stack.isNotEmpty) {
    final k = stack.removeLast();
    final i = k % _n, j = k ~/ _n;
    for (final (di, dj) in const [(1, 0), (-1, 0), (0, 1), (0, -1)]) {
      final x = i + di, y = j + dj;
      if (x < 0 || y < 0 || x >= _n || y >= _n) continue;
      final kk = y * _n + x;
      if (closed[kk] && !comp[kk]) {
        comp[kk] = true;
        stack.add(kk);
      }
    }
  }

  // 4. Cadre robuste : on ignore les lignes/colonnes où le bloc est maigre
  //    (fuites vers le fond).
  final rows = List<int>.filled(_n, 0), cols = List<int>.filled(_n, 0);
  for (var k = 0; k < _n * _n; k++) {
    if (comp[k]) {
      rows[k ~/ _n]++;
      cols[k % _n]++;
    }
  }
  (int, int)? span(List<int> h) {
    final mx = h.reduce(math.max);
    if (mx == 0) return null;
    final lim = mx * 0.45;
    var a = 0, b = _n - 1;
    while (a < _n && h[a] < lim) {
      a++;
    }
    while (b > a && h[b] < lim) {
      b--;
    }
    return (a, b);
  }

  final sx = span(cols), sy = span(rows);
  if (sx == null || sy == null) {
    return const DetectResult(null, DetectFailure.notFound);
  }
  // Le bloc touche le bord : il s'est collé au fond, on ne sait pas.
  final touches =
      sx.$1 <= 2 || sy.$1 <= 2 || sx.$2 >= _n - 3 || sy.$2 >= _n - 3;
  if (touches) return const DetectResult(null, DetectFailure.notFound);
  return _finish(
    f,
    sx.$1,
    sy.$1,
    sx.$2 - sx.$1 + 1,
    sy.$2 - sy.$1 + 1,
    ox,
    oy,
    step,
    wd,
    hd,
    threshold,
    toSensor,
  );
}

/// Vérifie le cadre trouvé (forme, taille) et mesure les 9 cases.
DetectResult _finish(
  YuvFrame f,
  int x0,
  int y0,
  int w,
  int h,
  double ox,
  double oy,
  double step,
  int wd,
  int hd,
  int threshold,
  (int, int) Function(double, double) toSensor,
) {
  final aspect = w / h;
  if (aspect < 0.7 || aspect > 1.43) {
    return const DetectResult(null, DetectFailure.notFound);
  }
  final coverage = (w + h) / 2 / _n;
  if (coverage < 0.3) return const DetectResult(null, DetectFailure.tooSmall);

  // Les 9 cases : médiane des pixels « autocollant » au cœur de la case.
  final left = ox + x0 * step, top = oy + y0 * step;
  final cw = w * step / 3, ch = h * step / 3;
  final cells = <CellSample>[];
  for (var r = 0; r < 3; r++) {
    for (var c = 0; c < 3; c++) {
      final pixels = <Rgb>[];
      final all = <Rgb>[];
      for (var a = 0; a < 7; a++) {
        for (var b = 0; b < 7; b++) {
          final xd = left + (c + 0.3 + 0.4 * a / 6) * cw;
          final yd = top + (r + 0.3 + 0.4 * b / 6) * ch;
          final (xs, ys) = toSensor(xd, yd);
          final p = f.pixel(xs, ys);
          all.add(p);
          if (f.y[ys * f.yRowStride + xs] > threshold * 0.8) pixels.add(p);
        }
      }
      final use = pixels.length >= 8 ? pixels : all;
      final med = rgbToLab(medianRgb(use));
      final d = [for (final p in use) rgbToLab(p).distance(med)]..sort();
      cells.add(CellSample(med, d[(d.length * 0.6).floor()]));
    }
  }
  return DetectResult(
    FaceDetection(
      cells,
      left / wd,
      top / hd,
      (left + w * step) / wd,
      (top + h * step) / hd,
      coverage,
    ),
    DetectFailure.none,
  );
}

/// Les autocollants : petits blocs clairs à peu près carrés. On part de
/// celui le plus proche du centre et on ajoute de proche en proche ses
/// voisins de même taille ; on garde au plus les 9 plus centraux.
/// Renvoie le cadre (gauche, haut, droite, bas) en cases de la grille.
(int, int, int, int)? _stickerGrid(List<bool> mask) {
  final seen = List<bool>.filled(_n * _n, false);
  final blobs = <_Blob>[];
  for (var k = 0; k < _n * _n; k++) {
    if (!mask[k] || seen[k]) continue;
    var x0 = _n, y0 = _n, x1 = 0, y1 = 0, area = 0;
    final st = [k];
    seen[k] = true;
    while (st.isNotEmpty) {
      final q = st.removeLast();
      final i = q % _n, j = q ~/ _n;
      area++;
      x0 = math.min(x0, i);
      x1 = math.max(x1, i);
      y0 = math.min(y0, j);
      y1 = math.max(y1, j);
      for (final (di, dj) in const [(1, 0), (-1, 0), (0, 1), (0, -1)]) {
        final x = i + di, y = j + dj;
        if (x < 0 || y < 0 || x >= _n || y >= _n) continue;
        final kk = y * _n + x;
        if (mask[kk] && !seen[kk]) {
          seen[kk] = true;
          st.add(kk);
        }
      }
    }
    final w = x1 - x0 + 1, h = y1 - y0 + 1;
    if (area < 5 || w > _n / 2.6 || h > _n / 2.6) continue;
    if (w / h < 0.55 || w / h > 1.8 || area < w * h * 0.55) continue;
    blobs.add(_Blob(x0, y0, x1, y1, area));
  }
  if (blobs.length < 7) return null;

  double d2(_Blob b) =>
      math.pow(b.cx - _n / 2, 2) + math.pow(b.cy - _n / 2, 2) as double;
  blobs.sort((a, b) => d2(a).compareTo(d2(b)));
  final seed = blobs.first;
  final pitch = seed.size * 1.2;
  final kept = <_Blob>[seed];
  final pool = blobs
      .sublist(1)
      .where((b) => b.area > seed.area * 0.45 && b.area < seed.area * 2.2)
      .toList();
  var grew = true;
  while (grew) {
    grew = false;
    for (final b in [...pool]) {
      final near = kept.any(
        (k) =>
            (k.cx - b.cx).abs() <= pitch * 1.45 &&
            (k.cy - b.cy).abs() <= pitch * 1.45,
      );
      if (near) {
        kept.add(b);
        pool.remove(b);
        grew = true;
      }
    }
  }
  if (kept.length < 7) return null;
  // Trop de blocs (bouts de fond) : les 9 plus proches de leur centre.
  if (kept.length > 9) {
    final mx = kept.map((b) => b.cx).reduce((a, b) => a + b) / kept.length;
    final my = kept.map((b) => b.cy).reduce((a, b) => a + b) / kept.length;
    kept.sort(
      (a, b) => (math.pow(a.cx - mx, 2) + math.pow(a.cy - my, 2)).compareTo(
        math.pow(b.cx - mx, 2) + math.pow(b.cy - my, 2),
      ),
    );
    kept.removeRange(9, kept.length);
  }
  final box = (
    kept.map((b) => b.x0).reduce(math.min),
    kept.map((b) => b.y0).reduce(math.min),
    kept.map((b) => b.x1).reduce(math.max),
    kept.map((b) => b.y1).reduce(math.max),
  );
  // Un vrai 3 × 3 : le cadre fait environ 3 autocollants de côté.
  final bw = box.$3 - box.$1 + 1, bh = box.$4 - box.$2 + 1;
  if (bw < seed.size * 2.3 || bh < seed.size * 2.3) return null;
  return box;
}

class _Blob {
  _Blob(this.x0, this.y0, this.x1, this.y1, this.area);
  final int x0, y0, x1, y1, area;
  double get cx => (x0 + x1) / 2;
  double get cy => (y0 + y1) / 2;
  double get size => ((x1 - x0) + (y1 - y0)) / 2 + 1;
}
