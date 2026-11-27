// Couleurs : conversion RVB → CIELAB et distance perçue (ΔE).
// CIELAB est bien plus proche de la vision humaine que le RVB brut : c'est
// ce qui permet de distinguer rouge/orange et blanc/jaune sous une lampe.
import 'dart:math' as math;

class Rgb {
  const Rgb(this.r, this.g, this.b);
  final int r, g, b; // 0..255
}

class Lab {
  const Lab(this.l, this.a, this.b);
  final double l, a, b;

  /// ΔE 1976 (distance euclidienne dans CIELAB).
  double distance(Lab o) {
    final dl = l - o.l, da = a - o.a, db = b - o.b;
    return math.sqrt(dl * dl + da * da + db * db);
  }

  /// Saturation (chroma).
  double get chroma => math.sqrt(a * a + b * b);

  @override
  String toString() =>
      'Lab(${l.toStringAsFixed(1)}, ${a.toStringAsFixed(1)}, ${b.toStringAsFixed(1)})';
}

double _linear(int c) {
  final v = c / 255.0;
  return v <= 0.04045
      ? v / 12.92
      : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
}

double _f(double t) => t > 216 / 24389
    ? math.pow(t, 1 / 3).toDouble()
    : (24389 / 27 * t + 16) / 116;

/// sRGB (D65) → CIELAB.
Lab rgbToLab(Rgb c) {
  final r = _linear(c.r), g = _linear(c.g), b = _linear(c.b);
  final x = (0.4124 * r + 0.3576 * g + 0.1805 * b) / 0.95047;
  final y = 0.2126 * r + 0.7152 * g + 0.0722 * b;
  final z = (0.0193 * r + 0.1192 * g + 0.9505 * b) / 1.08883;
  final fx = _f(x), fy = _f(y), fz = _f(z);
  return Lab(116 * fy - 16, 500 * (fx - fy), 200 * (fy - fz));
}

/// YUV (BT.601, plage pleine, comme les caméras Android) → RVB.
Rgb yuvToRgb(int y, int u, int v) {
  final uu = u - 128, vv = v - 128;
  int clamp(double x) => x < 0 ? 0 : (x > 255 ? 255 : x.round());
  return Rgb(
    clamp(y + 1.402 * vv),
    clamp(y - 0.344136 * uu - 0.714136 * vv),
    clamp(y + 1.772 * uu),
  );
}

/// Médiane composante par composante (résiste aux reflets et aux bords).
Rgb medianRgb(List<Rgb> pixels) {
  int med(List<int> v) {
    v.sort();
    return v[v.length ~/ 2];
  }

  return Rgb(
    med([for (final p in pixels) p.r]),
    med([for (final p in pixels) p.g]),
    med([for (final p in pixels) p.b]),
  );
}
