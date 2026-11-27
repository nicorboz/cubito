// Lecture tolérante : le carré guide prend le relais quand la face n'est
// pas trouvée précisément (cube sans plastique noir, décalé, penché…).
import 'dart:math' as math;

import 'package:cube_magique/core/cube/cube.dart';
import 'package:cube_magique/core/scan/capture_logic.dart';
import 'package:cube_magique/core/scan/color_lab.dart';
import 'package:cube_magique/core/scan/face_detector.dart';
import 'package:cube_magique/core/scan/scan_reader.dart';
import 'package:flutter_test/flutter_test.dart';

import 'scan_camera_test.dart' show scene, nearest, randomFace;

void main() {
  test('Cube sans plastique noir, décalé, penché : lu sans erreur', () {
    final rnd = math.Random(5);
    var ok = 0, total = 0;
    for (var k = 0; k < 60; k++) {
      final face = randomFace(rnd);
      final f = scene(
        face,
        stickerless: true,
        size: 0.58 + rnd.nextDouble() * 0.14,
        dx: (rnd.nextDouble() - 0.5) * 0.08,
        dy: (rnd.nextDouble() - 0.5) * 0.08,
        tilt: (rnd.nextDouble() - 0.5) * 0.12,
        brightBackground: k.isOdd,
        seed: k,
      );
      final r = readFace(f);
      total++;
      if (r.failure != DetectFailure.none || r.face == null) continue;
      final read = [for (final c in r.face!.cells) nearest(c.lab)];
      if (read.join() == face.join()) ok++;
    }
    expect(
      ok,
      greaterThanOrEqualTo((total * 0.95).ceil()),
      reason: '$ok/$total',
    );
  });

  test('Cube classique : toujours lu (détection précise)', () {
    final rnd = math.Random(8);
    var ok = 0;
    for (var k = 0; k < 40; k++) {
      final face = randomFace(rnd);
      final r = readFace(
        scene(face, size: 0.5 + rnd.nextDouble() * 0.3, seed: k),
      );
      if (r.failure == DetectFailure.none &&
          [for (final c in r.face!.cells) nearest(c.lab)].join() ==
              face.join()) {
        ok++;
      }
    }
    expect(ok, greaterThanOrEqualTo(38));
  });

  test('Face d\'une seule couleur (déjà finie) : acceptée', () {
    final r = readFace(
      scene(List.filled(9, CubeColor.white), size: 0.62, stickerless: true),
    );
    expect(r.failure, DetectFailure.none);
  });

  test('Mur ou table uni, sans cube : pas de capture', () {
    for (final wall in const [Rgb(222, 218, 205), Rgb(120, 110, 100)]) {
      final r = readFace(scene(List.filled(9, CubeColor.white), wall: wall));
      expect(r.failure, isNot(DetectFailure.none));
      // Mais le bouton « Prendre cette face » a quelque chose à lire.
      expect(r.face, isNotNull);
    }
  });

  test(
    'Capture automatique avec le carré guide (cube sans plastique noir)',
    () {
      final face = randomFace(math.Random(2));
      final logic = CaptureLogic(expectedCenter: face[4]);
      List<Lab>? got;
      for (var k = 0; k < 25 && got == null; k++) {
        final r = readFace(
          scene(face, stickerless: true, size: 0.64, seed: k, noise: 10),
        );
        got = logic.feed(Duration(milliseconds: 100 * k), r);
      }
      expect(got, isNotNull);
      expect([for (final c in got!) nearest(c)].join(), face.join());
    },
  );
}
