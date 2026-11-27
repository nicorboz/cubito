// Tests du cœur du scan (sans caméra) : plan des faces, CIELAB, hongrois,
// classement robuste sous des lumières simulées.
import 'dart:math';

import 'package:cube_magique/core/cube/cube.dart';
import 'package:cube_magique/core/scan/classifier.dart';
import 'package:cube_magique/core/scan/color_lab.dart';
import 'package:cube_magique/core/scan/hungarian.dart';
import 'package:cube_magique/core/scan/scan_plan.dart';
import 'package:flutter_test/flutter_test.dart';

/// Couleurs « réelles » d'un cube du commerce (sRGB approximatif).
const realColors = {
  CubeColor.white: Rgb(235, 235, 230),
  CubeColor.yellow: Rgb(240, 220, 20),
  CubeColor.red: Rgb(200, 20, 30),
  CubeColor.orange: Rgb(255, 110, 10),
  CubeColor.blue: Rgb(10, 70, 200),
  CubeColor.green: Rgb(0, 160, 70),
};

/// Simule une prise de vue : teinte de la lampe, luminosité, bruit.
Rgb shoot(
  Rgb c, {
  required List<double> tint,
  required double gain,
  required Random rnd,
  double noise = 10,
}) {
  int ch(int v, double t) =>
      (v * t * gain + (rnd.nextDouble() * 2 - 1) * noise).round().clamp(0, 255);
  return Rgb(ch(c.r, tint[0]), ch(c.g, tint[1]), ch(c.b, tint[2]));
}

void main() {
  test(
    'Plan de scan : 6 faces, 54 facettes chacune une fois, bons centres',
    () {
      expect(scanPlan.length, 6);
      final all = [for (final s in scanPlan) ...s.facelets];
      expect(all.toSet().length, 54);
      expect(
        [for (final s in scanPlan) s.center],
        [
          CubeColor.white,
          CubeColor.green,
          CubeColor.yellow,
          CubeColor.blue,
          CubeColor.orange,
          CubeColor.red,
        ],
      );
      expect(scanPlan.first.top, CubeColor.green); // blanc devant, vert en haut
      for (final s in scanPlan) {
        expect(s.facelets[4] % 9, 4); // la case du milieu est un centre
      }
    },
  );

  test('Plan de scan : reconstruit exactement un cube réel', () {
    final rnd = Random(1);
    for (var t = 0; t < 200; t++) {
      final cube = Cube.solved().apply(randomScramble(random: rnd));
      // Ce que voit la caméra : la face avant après chaque geste.
      var held = cube;
      final faces = <List<CubeColor>>[];
      for (final s in scanPlan) {
        held = held.apply(s.rotation);
        faces.add([for (var k = 0; k < 9; k++) held[Face.f.index * 9 + k]]);
      }
      expect(Cube.fromColors(assembleScan(faces)), cube);
    }
  });

  test('CIELAB : blanc, noir, rouge', () {
    expect(rgbToLab(const Rgb(255, 255, 255)).l, closeTo(100, 0.5));
    expect(rgbToLab(const Rgb(0, 0, 0)).l, closeTo(0, 0.5));
    final red = rgbToLab(const Rgb(255, 0, 0));
    expect(red.l, closeTo(53.2, 0.5));
    expect(red.a, closeTo(80.1, 0.5));
    expect(red.b, closeTo(67.2, 0.5));
    final y = yuvToRgb(128, 128, 128);
    expect([y.r, y.g, y.b], [128, 128, 128]);
  });

  test('Hongrois : affectation optimale', () {
    final cost = <List<double>>[
      [4, 1, 3],
      [2, 0, 5],
      [3, 2, 2],
    ];
    final a = hungarian(cost);
    final total = [for (var i = 0; i < 3; i++) cost[i][a[i]]]
        .reduce((x, y) => x + y);
    expect(total, 5); // 1 + 2 + 2
    expect(a.toSet().length, 3);
  });

  test('Classement ≥ 98 % sous lumières variées (jour, lampe jaune, néon)', () {
    final rnd = Random(2);
    final lights = {
      'jour': [1.0, 1.0, 1.0],
      'lampe jaune': [1.05, 0.92, 0.62],
      'néon': [0.92, 1.0, 1.08],
    };
    var good = 0, total = 0;
    for (final light in lights.entries) {
      for (var t = 0; t < 300; t++) {
        final cube = Cube.solved().apply(randomScramble(random: rnd));
        final gain = 0.65 + rnd.nextDouble() * 0.45;
        final labs = [
          for (var i = 0; i < 54; i++)
            rgbToLab(
              shoot(
                realColors[cube[i]]!,
                tint: light.value,
                gain: gain,
                rnd: rnd,
              ),
            ),
        ];
        final r = classifyColors(labs);
        for (var i = 0; i < 54; i++) {
          if (i % 9 == 4) continue;
          total++;
          if (r.colors[i] == cube[i]) good++;
        }
        // Toujours exactement 9 cases par couleur.
        for (final c in CubeColor.values) {
          expect(r.colors.where((x) => x == c).length, 9);
        }
      }
    }
    final rate = good / total;
    // ignore: avoid_print
    print('Taux de cases correctes : ${(rate * 100).toStringAsFixed(2)} %');
    expect(rate, greaterThanOrEqualTo(0.98));
  });

  test('Conditions difficiles : lampe très jaune, ombres, bruit fort', () {
    final rnd = Random(4);
    var good = 0, total = 0;
    for (var t = 0; t < 500; t++) {
      final cube = Cube.solved().apply(randomScramble(random: rnd));
      final tint = [1.1, 0.86, 0.5];
      final labs = [
        for (var i = 0; i < 54; i++)
          rgbToLab(
            shoot(
              realColors[cube[i]]!,
              tint: tint,
              gain: 0.55 + rnd.nextDouble() * 0.5, // ombre propre à chaque case
              rnd: rnd,
              noise: 18,
            ),
          ),
      ];
      final r = classifyColors(labs);
      for (var i = 0; i < 54; i++) {
        if (i % 9 == 4) continue;
        total++;
        if (r.colors[i] == cube[i]) good++;
      }
    }
    final rate = good / total;
    // ignore: avoid_print
    print('Conditions difficiles : ${(rate * 100).toStringAsFixed(2)} %');
    expect(rate, greaterThanOrEqualTo(0.98));
  });

  test(
    'Une case très douteuse est corrigée par la règle des 9 et signalée',
    () {
      final cube = Cube.solved();
      final labs = [
        for (var i = 0; i < 54; i++) rgbToLab(realColors[cube[i]]!),
      ];
      // Une case rouge mesurée presque orange.
      labs[10] = rgbToLab(const Rgb(240, 85, 15));
      final r = classifyColors(labs);
      expect(r.colors[10], CubeColor.red);
      expect(r.doubtful, contains(10));
    },
  );
}
