// Une face montrée tournée (ou une caméra orientée autrement) donne un cube
// impossible : l'appli remet les faces dans le bon sens toute seule.
import 'dart:math' as math;

import 'package:cube_magique/core/cube/cube.dart';
import 'package:cube_magique/core/cube/validation.dart';
import 'package:cube_magique/core/scan/scan_plan.dart';
import 'package:flutter_test/flutter_test.dart';

bool valid(List<CubeColor> c) => validateCube(Cube.fromColors(c)).isValid;

/// Les 6 grilles vues par la caméra pour un cube donné.
List<List<CubeColor>> filmed(Cube cube) {
  var held = cube;
  return [
    for (final step in scanPlan)
      () {
        held = held.apply(step.rotation);
        return [for (var k = 0; k < 9; k++) held[Face.f.index * 9 + k]];
      }(),
  ];
}

void main() {
  test('rotateGrid : 4 quarts de tour = identité', () {
    final g = List.generate(9, (i) => i);
    expect(rotateGrid(g, 1), [6, 3, 0, 7, 4, 1, 8, 5, 2]);
    expect(rotateGrid(g, 4), g);
  });

  test('Une face montrée tournée : corrigée', () {
    final rnd = math.Random(4);
    var fixed = 0;
    for (var t = 0; t < 30; t++) {
      final cube = Cube.solved().apply(randomScramble(random: rnd));
      final grids = filmed(cube);
      final s = rnd.nextInt(6);
      grids[s] = rotateGrid(grids[s], 1 + rnd.nextInt(3));
      final colors = assembleScan(grids);
      final sw = Stopwatch()..start();
      final out = fixScanOrientation(colors, valid);
      expect(sw.elapsedMilliseconds, lessThan(3000));
      if (out != null && Cube.fromColors(out) == cube) fixed++;
    }
    expect(fixed, greaterThanOrEqualTo(28));
  });

  test('Toutes les faces tournées pareil (caméra) : corrigées', () {
    final rnd = math.Random(9);
    for (var t = 0; t < 10; t++) {
      final cube = Cube.solved().apply(randomScramble(random: rnd));
      final turns = 1 + t % 3;
      final grids = [for (final g in filmed(cube)) rotateGrid(g, turns)];
      final out = fixScanOrientation(assembleScan(grids), valid);
      expect(out, isNotNull);
      expect(Cube.fromColors(out!), cube);
    }
  });

  test('Cube déjà bon : inchangé ; vraie erreur de couleur : pas inventé', () {
    final cube = Cube.solved().apply("R U F' L2 D");
    final colors = assembleScan(filmed(cube));
    expect(fixScanOrientation(colors, valid), colors);
    final wrong = [...colors];
    wrong[0] = wrong[0] == CubeColor.red ? CubeColor.blue : CubeColor.red;
    final sw = Stopwatch()..start();
    expect(fixScanOrientation(wrong, valid), isNull);
    // ignore: avoid_print
    print('recherche complète : ${sw.elapsedMilliseconds} ms');
  });

  test('Rouge et orange échangés entre deux cases : corrigé', () {
    final rnd = math.Random(6);
    var fixed = 0;
    for (var t = 0; t < 20; t++) {
      final cube = Cube.solved().apply(randomScramble(random: rnd));
      final colors = assembleScan(filmed(cube));
      final reds = [
        for (var i = 0; i < 54; i++)
          if (i % 9 != 4 && colors[i] == CubeColor.red) i,
      ];
      final oranges = [
        for (var i = 0; i < 54; i++)
          if (i % 9 != 4 && colors[i] == CubeColor.orange) i,
      ];
      final i = reds[rnd.nextInt(reds.length)],
          j = oranges[rnd.nextInt(oranges.length)];
      final wrong = [...colors]
        ..[i] = CubeColor.orange
        ..[j] = CubeColor.red;
      final out = fixConfusedPair(wrong, valid, doubtful: {i, j});
      if (out != null && Cube.fromColors(out.colors) == cube) fixed++;
    }
    expect(fixed, greaterThanOrEqualTo(18));
  });
}
