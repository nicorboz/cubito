// Tests de la reconnaissance caméra avec des images fabriquées réalistes :
// cube décalé, plus ou moins grand, légèrement penché, fond sombre ou
// clair, bruit, capteur tourné. Aucune caméra nécessaire.
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:cube_magique/core/cube/cube.dart';
import 'package:cube_magique/core/scan/capture_logic.dart';
import 'package:cube_magique/core/scan/classifier.dart';
import 'package:cube_magique/core/scan/scan_plan.dart';
import 'package:cube_magique/core/scan/color_lab.dart';
import 'package:cube_magique/core/scan/face_detector.dart';
import 'package:cube_magique/core/scan/frame_analyzer.dart';
import 'package:flutter_test/flutter_test.dart';

const rgbOf = {
  CubeColor.white: Rgb(225, 225, 218),
  CubeColor.yellow: Rgb(232, 212, 28),
  CubeColor.red: Rgb(190, 25, 35),
  CubeColor.orange: Rgb(245, 108, 18),
  CubeColor.blue: Rgb(15, 68, 190),
  CubeColor.green: Rgb(5, 150, 68),
};

(int, int, int) rgbToYuv(Rgb c) {
  final y = (0.299 * c.r + 0.587 * c.g + 0.114 * c.b).round();
  final u = (-0.168736 * c.r - 0.331264 * c.g + 0.5 * c.b + 128).round();
  final v = (0.5 * c.r - 0.418688 * c.g - 0.081312 * c.b + 128).round();
  return (y.clamp(0, 255), u.clamp(0, 255), v.clamp(0, 255));
}

/// Image capteur avec une face de cube dessinée dans l'image AFFICHÉE.
YuvFrame scene(
  List<CubeColor> face, {
  int rotation = 90,
  int w = 320,
  int h = 240,
  double size = 0.6, // côté de la face / petit côté de l'image affichée
  double dx = 0,
  double dy = 0, // décalage du centre (fraction du petit côté)
  double tilt = 0, // rotation de la face (radians)
  bool brightBackground = false,
  double gain = 1,
  int noise = 8,
  int seed = 1,
  bool glare = false,
  bool stickerless = false, // cube sans plastique noir (pièces colorées)
  Rgb? wall, // fond uni (mur, table) et pas de cube du tout
}) {
  final rnd = math.Random(seed);
  final ys = Uint8List(w * h),
      us = Uint8List((w ~/ 2) * (h ~/ 2)),
      vs = Uint8List((w ~/ 2) * (h ~/ 2));
  final rotated = rotation == 90 || rotation == 270;
  final wd = rotated ? h : w, hd = rotated ? w : h;
  final m = math.min(wd, hd);
  final side = size * m;
  final cx = wd / 2 + dx * m, cy = hd / 2 + dy * m;
  final body = side * 1.06; // bord de plastique autour des autocollants
  for (var sy = 0; sy < h; sy++) {
    for (var sx = 0; sx < w; sx++) {
      final (xd, yd) = switch (rotation) {
        90 => (h - 1 - sy, sx),
        180 => (w - 1 - sx, h - 1 - sy),
        270 => (sy, w - 1 - sx),
        _ => (sx, sy),
      };
      // Repère de la face (avec inclinaison).
      final px = xd - cx, py = yd - cy;
      final u = px * math.cos(-tilt) - py * math.sin(-tilt);
      final v = px * math.sin(-tilt) + py * math.cos(-tilt);
      Rgb c;
      if (wall != null) {
        c = wall;
      } else if (stickerless && u.abs() < side / 2 && v.abs() < side / 2) {
        // Pièces de couleur, séparées par de fines fentes un peu sombres.
        final gx = (u + side / 2) / (side / 3),
            gy = (v + side / 2) / (side / 3);
        final base =
            rgbOf[face[gy.floor().clamp(0, 2) * 3 + gx.floor().clamp(0, 2)]]!;
        final fx = gx % 1, fy = gy % 1;
        final seam = fx < 0.03 || fx > 0.97 || fy < 0.03 || fy > 0.97;
        c = seam
            ? Rgb(base.r * 45 ~/ 100, base.g * 45 ~/ 100, base.b * 45 ~/ 100)
            : base;
      } else if (u.abs() < body / 2 && v.abs() < body / 2) {
        c = const Rgb(28, 26, 30); // plastique noir
        final gx = (u + side / 2) / (side / 3),
            gy = (v + side / 2) / (side / 3);
        if (gx >= 0 && gx < 3 && gy >= 0 && gy < 3) {
          final fx = gx % 1, fy = gy % 1;
          if (fx > 0.07 && fx < 0.93 && fy > 0.07 && fy < 0.93) {
            c = rgbOf[face[gy.floor() * 3 + gx.floor()]]!;
            // Reflet de lampe : une tache blanche dans le coin de la case.
            if (glare && fx > 0.6 && fx < 0.85 && fy > 0.15 && fy < 0.35) {
              c = const Rgb(250, 250, 250);
            }
          }
        }
      } else {
        // Fond : sombre et uni, ou clair et un peu texturé (table, mur).
        c = brightBackground
            ? Rgb(200 + (xd ~/ 9 % 3) * 10, 196 + (yd ~/ 11 % 2) * 8, 180)
            : const Rgb(70, 62, 58);
      }
      int n(int x) =>
          (x * gain + rnd.nextInt(2 * noise + 1) - noise).round().clamp(0, 255);
      final (y, uu, vv) = rgbToYuv(Rgb(n(c.r), n(c.g), n(c.b)));
      ys[sy * w + sx] = y;
      us[(sy ~/ 2) * (w ~/ 2) + sx ~/ 2] = uu;
      vs[(sy ~/ 2) * (w ~/ 2) + sx ~/ 2] = vv;
    }
  }
  return YuvFrame(
    width: w,
    height: h,
    y: ys,
    yRowStride: w,
    u: us,
    v: vs,
    uvRowStride: w ~/ 2,
    uvPixelStride: 1,
  );
}

/// Couleur la plus proche, sous la même lumière ([gain]) : comme l'appli,
/// qui se calibre avec les centres du cube.
CubeColor nearest(Lab lab, [double gain = 1]) {
  Lab ref(CubeColor c) {
    final r = rgbOf[c]!;
    return rgbToLab(
      Rgb((r.r * gain).round(), (r.g * gain).round(), (r.b * gain).round()),
    );
  }

  return CubeColor.values.reduce(
    (a, b) => lab.distance(ref(a)) <= lab.distance(ref(b)) ? a : b,
  );
}

List<CubeColor> randomFace(math.Random r) => [
  for (var k = 0; k < 9; k++) CubeColor.values[r.nextInt(6)],
];

void main() {
  final face = [
    CubeColor.red,
    CubeColor.green,
    CubeColor.blue,
    CubeColor.yellow,
    CubeColor.white,
    CubeColor.orange,
    CubeColor.green,
    CubeColor.red,
    CubeColor.yellow,
  ];

  for (final rot in [0, 90, 180, 270]) {
    test('Trouve et lit la face (capteur tourné de $rot°)', () {
      final r = detectFace(scene(face, rotation: rot), rotation: rot);
      expect(r.face, isNotNull, reason: '${r.failure}');
      expect([for (final c in r.face!.cells) nearest(c.lab)], face);
    });
  }

  test('Cube décalé, petit ou grand, penché, fonds variés : bien lu', () {
    final rnd = math.Random(7);
    var ok = 0, total = 0, found = 0;
    for (var t = 0; t < 120; t++) {
      final f = randomFace(rnd);
      final frame = scene(
        f,
        size: 0.4 + rnd.nextDouble() * 0.42,
        dx: (rnd.nextDouble() - 0.5) * 0.16,
        dy: (rnd.nextDouble() - 0.5) * 0.16,
        tilt: (rnd.nextDouble() - 0.5) * 0.16,
        brightBackground: t.isOdd,
        gain: 0.7 + rnd.nextDouble() * 0.4,
        seed: t,
      );
      final r = detectFace(frame);
      total++;
      if (r.face == null) continue;
      found++;
      final read = [for (final c in r.face!.cells) nearest(c.lab)].join();
      if (read == f.join()) ok++;
    }
    // ignore: avoid_print
    print('Faces trouvées : $found/$total, lues parfaitement : $ok/$total');
    expect(found / total, greaterThanOrEqualTo(0.95));
    expect(ok / total, greaterThanOrEqualTo(0.9));
  });

  test('Conditions dures : reflets, peu de lumière, petite image', () {
    final rnd = math.Random(11);
    var ok = 0;
    const total = 80;
    for (var t = 0; t < total; t++) {
      final f = randomFace(rnd);
      final gain = 0.45 + rnd.nextDouble() * 0.3;
      final frame = scene(
        f,
        w: 176,
        h: 144,
        size: 0.5 + rnd.nextDouble() * 0.3,
        dx: (rnd.nextDouble() - 0.5) * 0.1,
        dy: (rnd.nextDouble() - 0.5) * 0.1,
        tilt: (rnd.nextDouble() - 0.5) * 0.12,
        brightBackground: t.isEven,
        gain: gain,
        noise: 14,
        glare: true,
        seed: 500 + t,
      );
      final r = detectFace(frame);
      if (r.face == null) continue;
      final read = [for (final c in r.face!.cells) nearest(c.lab, gain)].join();
      if (read == f.join()) ok++;
    }
    // ignore: avoid_print
    print('Conditions dures : $ok/$total');
    expect(ok / total, greaterThanOrEqualTo(0.85));
  });

  test('Pas de cube → « mets ton cube dans le carré » ; trop loin → « rapproche-toi »', () {
    final empty = detectFace(scene(face, size: 0.0001));
    expect(empty.face, isNull);
    final far = detectFace(scene(face, size: 0.2));
    expect(far.face, isNull);
    expect(far.failure, anyOf(DetectFailure.tooSmall, DetectFailure.notFound));
  });

  test('Trop sombre', () {
    expect(
      detectFace(scene(face, gain: 0.12, noise: 2)).failure,
      DetectFailure.tooDark,
    );
  });

  group('Capture automatique', () {
    DetectResult shot(List<CubeColor> f, int seed, {double dx = 0}) =>
        detectFace(scene(f, dx: dx, seed: seed, noise: 10));

    test('Tenue ~1,5 s → capturée, malgré une image floue au milieu', () {
      final logic = CaptureLogic(expectedCenter: CubeColor.white);
      List<Lab>? got;
      for (var k = 0; k <= 25 && got == null; k++) {
        // Pas avant 1,3 s : on laisse le temps de bien placer le cube.
        if (k < 13) expect(got, isNull);
        // Image 4 : le cube bouge beaucoup (flou de bougé).
        final r = k == 4 ? shot(face, k, dx: 0.12) : shot(face, k);
        got = logic.feed(Duration(milliseconds: k * 100), r);
      }
      expect(got, isNotNull);
      expect([for (final c in got!) nearest(c)], face);
    });

    test('Après une capture, on attend le geste (pas de double capture)', () {
      final logic = CaptureLogic(expectedCenter: CubeColor.white);
      List<Lab>? first;
      var k = 0;
      for (; first == null; k++) {
        first = logic.feed(Duration(milliseconds: k * 100), shot(face, k));
      }
      logic.reset(CubeColor.green, previous: first[4]);
      for (var j = 0; j < 15; j++) {
        expect(
          logic.feed(
            Duration(milliseconds: (k + j) * 100),
            shot(face, 100 + j),
          ),
          isNull,
        );
      }
      expect(logic.advice, ScanAdvice.doGesture);
    });

    test('Blanc sous une lampe jaune : accepté (pas « mauvaise face »)', () {
      final logic = CaptureLogic(expectedCenter: CubeColor.white);
      final f = [...face]..[4] = CubeColor.yellow; // le blanc paraît jaune
      logic.feed(Duration.zero, shot(f, 1));
      expect(logic.advice, isNot(ScanAdvice.wrongFace));
    });

    test('Vraiment la mauvaise face → consigne', () {
      final logic = CaptureLogic(expectedCenter: CubeColor.blue);
      final f = [...face]..[4] = CubeColor.orange;
      logic.feed(Duration.zero, shot(f, 1));
      expect(logic.advice, ScanAdvice.wrongFace);
    });

    test('Bouton « Prendre cette face »', () {
      final logic = CaptureLogic(expectedCenter: CubeColor.white);
      logic.feed(Duration.zero, shot(face, 1));
      final got = logic.captureNow();
      expect(got, isNotNull);
      expect([for (final c in got!) nearest(c)], face);
    });
  });

  test('L\'ancienne lecture à points fixes reste disponible', () {
    final cells = sampleGrid(scene(face), rotation: 90);
    expect(cells.length, 9);
  });

  test('De bout en bout : 6 faces filmées sous une lampe → le bon cube', () {
    final rnd = math.Random(21);
    var ok = 0;
    const total = 25;
    for (var t = 0; t < total; t++) {
      final cube = Cube.solved().apply(randomScramble(random: rnd));
      var held = cube;
      final faces = <List<Lab>>[];
      for (final step in scanPlan) {
        held = held.apply(step.rotation);
        final face = [for (var k = 0; k < 9; k++) held[Face.f.index * 9 + k]];
        // Lampe un peu jaune : on teinte les couleurs avant de « filmer ».
        final r = detectFace(
          scene(
            face,
            size: 0.55 + rnd.nextDouble() * 0.2,
            gain: 0.8,
            seed: t * 10 + faces.length,
          ),
        );
        expect(r.face, isNotNull);
        faces.add([for (final c in r.face!.cells) c.lab]);
      }
      final result = classifyColors(assembleScan(faces));
      if (Cube.fromColors(result.colors) == cube) ok++;
    }
    expect(ok, total);
  });
}
