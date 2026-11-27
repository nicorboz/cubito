// Lecture des 9 cases d'une image de la caméra (format YUV 4:2:0 des
// téléphones Android). Dart pur : testé avec des images fabriquées.
import 'dart:typed_data';

import 'color_lab.dart';

/// Une image caméra brute (copie des plans utiles).
class YuvFrame {
  YuvFrame({
    required this.width,
    required this.height,
    required this.y,
    required this.yRowStride,
    required this.u,
    required this.v,
    required this.uvRowStride,
    required this.uvPixelStride,
  });

  /// Image en couleurs RVBA (4 octets par pixel), comme celles que donne le
  /// navigateur (version web) : convertie en YUV 4:2:0 (BT.601, plage
  /// pleine) pour être lue exactement comme une image de téléphone.
  /// La couleur (U, V) d'un carré de 2×2 pixels est leur moyenne.
  factory YuvFrame.fromRgba(int width, int height, Uint8List rgba) {
    final cw = (width + 1) >> 1, ch = (height + 1) >> 1;
    final ys = Uint8List(width * height);
    final us = Uint8List(cw * ch), vs = Uint8List(cw * ch);
    final su = Float64List(cw * ch), sv = Float64List(cw * ch);
    final n = Uint8List(cw * ch);
    int clamp(double x) => x < 0 ? 0 : (x > 255 ? 255 : x.round());
    for (var yy = 0; yy < height; yy++) {
      for (var x = 0; x < width; x++) {
        final i = (yy * width + x) * 4;
        final r = rgba[i], g = rgba[i + 1], b = rgba[i + 2];
        ys[yy * width + x] = clamp(0.299 * r + 0.587 * g + 0.114 * b);
        final c = (yy >> 1) * cw + (x >> 1);
        su[c] += -0.168736 * r - 0.331264 * g + 0.5 * b + 128;
        sv[c] += 0.5 * r - 0.418688 * g - 0.081312 * b + 128;
        n[c]++;
      }
    }
    for (var c = 0; c < cw * ch; c++) {
      us[c] = clamp(su[c] / n[c]);
      vs[c] = clamp(sv[c] / n[c]);
    }
    return YuvFrame(
      width: width,
      height: height,
      y: ys,
      yRowStride: width,
      u: us,
      v: vs,
      uvRowStride: cw,
      uvPixelStride: 1,
    );
  }

  final int width, height;
  final Uint8List y, u, v;
  final int yRowStride, uvRowStride, uvPixelStride;

  Rgb pixel(int x, int yy) {
    final yv = y[yy * yRowStride + x];
    final uvIndex = (yy >> 1) * uvRowStride + (x >> 1) * uvPixelStride;
    return yuvToRgb(yv, u[uvIndex], v[uvIndex]);
  }
}

/// Mesure d'une case : couleur médiane et dispersion (grande dispersion =
/// la zone mesurée déborde sur le plastique noir : cube trop loin).
class CellSample {
  const CellSample(this.lab, this.spread);
  final Lab lab;
  final double spread;
}

/// Part du petit côté de l'image occupée par la grille guide.
const gridFraction = 0.6;

/// Mesure les 9 cases de la grille guide, centrée dans l'image affichée.
/// [rotation] : rotation horaire (0, 90, 180, 270) pour passer de l'image
/// du capteur à l'image affichée droite. [mirror] : caméra avant.
List<CellSample> sampleGrid(
  YuvFrame f, {
  int rotation = 90,
  bool mirror = false,
}) {
  final rotated = rotation == 90 || rotation == 270;
  final wd = rotated ? f.height : f.width; // taille affichée
  final hd = rotated ? f.width : f.height;
  final side = gridFraction * (wd < hd ? wd : hd);
  final cell = side / 3;
  final radius = cell * 0.2;

  // Affichage (xd, yd) → capteur (xs, ys).
  (int, int) toSensor(double xd, double yd) {
    final x = xd.round().clamp(0, wd - 1), yy = yd.round().clamp(0, hd - 1);
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
      final col = mirror ? 2 - c : c;
      final cx = wd / 2 + (col - 1) * cell, cy = hd / 2 + (r - 1) * cell;
      final pixels = <Rgb>[];
      for (var i = -2; i <= 2; i++) {
        for (var j = -2; j <= 2; j++) {
          final (xs, ys) = toSensor(cx + i * radius / 2, cy + j * radius / 2);
          pixels.add(f.pixel(xs, ys));
        }
      }
      final med = rgbToLab(medianRgb(pixels));
      final labs = [for (final p in pixels) rgbToLab(p).distance(med)]..sort();
      out.add(CellSample(med, labs[(labs.length * 0.75).floor()]));
    }
  }
  return out;
}
