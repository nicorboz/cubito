// Petites briques de maths 3D pour le moteur de rendu (aucun paquet externe).
import 'dart:math' as math;

/// Vecteur 3D à virgule.
class V3 {
  const V3(this.x, this.y, this.z);
  final double x, y, z;

  static const zero = V3(0, 0, 0);

  V3 operator +(V3 o) => V3(x + o.x, y + o.y, z + o.z);
  V3 operator -(V3 o) => V3(x - o.x, y - o.y, z - o.z);
  V3 operator *(double k) => V3(x * k, y * k, z * k);
  V3 operator -() => V3(-x, -y, -z);

  double dot(V3 o) => x * o.x + y * o.y + z * o.z;
  V3 cross(V3 o) => V3(y * o.z - z * o.y, z * o.x - x * o.z, x * o.y - y * o.x);
  double get length => math.sqrt(dot(this));
  V3 get normalized => this * (1 / length);

  /// Composante n° [axis] (0=x, 1=y, 2=z).
  double operator [](int axis) => axis == 0 ? x : (axis == 1 ? y : z);

  /// Vecteur unitaire de l'axe [axis].
  static V3 unit(int axis) => axis == 0
      ? const V3(1, 0, 0)
      : (axis == 1 ? const V3(0, 1, 0) : const V3(0, 0, 1));

  @override
  String toString() =>
      '(${x.toStringAsFixed(2)}, ${y.toStringAsFixed(2)}, ${z.toStringAsFixed(2)})';
}

/// Matrice 3×3 de rotation (ligne par ligne).
class Mat3 {
  const Mat3(this.m);
  final List<double> m;

  static const identity = Mat3([1, 0, 0, 0, 1, 0, 0, 0, 1]);

  /// Rotation d'angle [angle] (radians, sens direct) autour de l'axe [axis].
  factory Mat3.rotation(int axis, double angle) {
    final c = math.cos(angle), s = math.sin(angle);
    switch (axis) {
      case 0:
        return Mat3([1, 0, 0, 0, c, -s, 0, s, c]);
      case 1:
        return Mat3([c, 0, s, 0, 1, 0, -s, 0, c]);
      default:
        return Mat3([c, -s, 0, s, c, 0, 0, 0, 1]);
    }
  }

  V3 apply(V3 v) => V3(
    m[0] * v.x + m[1] * v.y + m[2] * v.z,
    m[3] * v.x + m[4] * v.y + m[5] * v.z,
    m[6] * v.x + m[7] * v.y + m[8] * v.z,
  );

  Mat3 operator *(Mat3 o) {
    final r = List<double>.filled(9, 0);
    for (var i = 0; i < 3; i++) {
      for (var j = 0; j < 3; j++) {
        var s = 0.0;
        for (var k = 0; k < 3; k++) {
          s += m[i * 3 + k] * o.m[k * 3 + j];
        }
        r[i * 3 + j] = s;
      }
    }
    return Mat3(r);
  }

  /// Transposée = inverse pour une rotation.
  Mat3 get transposed =>
      Mat3([m[0], m[3], m[6], m[1], m[4], m[7], m[2], m[5], m[8]]);
}
