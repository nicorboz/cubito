// Tests de la validation d'un cube saisi.
import 'dart:math';

import 'package:cube_magique/core/cube/cube.dart';
import 'package:cube_magique/core/cube/cubies.dart';
import 'package:cube_magique/core/cube/validation.dart';
import 'package:flutter_test/flutter_test.dart';

/// Échange deux cases.
Cube swap(Cube c, int a, int b) {
  final colors = c.colors.toList();
  final t = colors[a];
  colors[a] = colors[b];
  colors[b] = t;
  return Cube.fromColors(colors);
}

Cube setColor(Cube c, int i, CubeColor color) {
  final colors = c.colors.toList()..[i] = color;
  return Cube.fromColors(colors);
}

void main() {
  test('Cube résolu et 2000 mélanges : valides', () {
    expect(validateCube(Cube.solved()).isValid, isTrue);
    final rnd = Random(10);
    for (var i = 0; i < 2000; i++) {
      final c = Cube.solved().apply(randomScramble(random: rnd));
      expect(validateCube(c).isValid, isTrue, reason: '$c');
      // Même tenu dans une autre orientation.
      expect(validateCube(c.apply('y x')).isValid, isTrue);
    }
  });

  test('Une case de la mauvaise couleur → mauvais nombre de couleurs', () {
    final c = setColor(Cube.solved(), 0, CubeColor.red);
    final r = validateCube(c);
    expect(r.problem, CubeProblem.wrongColorCount);
    expect(r.suspectColor, CubeColor.red);
    expect(r.suspectFacelets, isNotEmpty);
  });

  test('Deux centres identiques', () {
    // Le centre blanc échange avec une case rouge : 9 cases par couleur,
    // mais deux centres rouges.
    expect(
      validateCube(swap(Cube.solved(), 4, 9)).problem,
      CubeProblem.duplicateCenters,
    );
  });

  test('Centres impossibles (blanc à côté du jaune)', () {
    // Échange du centre jaune et du centre vert + d'une case pour garder 9/9.
    final c = swap(Cube.solved(), 31, 22);
    final r = validateCube(c);
    expect(r.problem, CubeProblem.impossibleCenters);
  });

  test('Coin tourné → impossible', () {
    // On fait tourner les 3 autocollants du coin URF.
    final s = Cube.solved().apply(randomScramble(random: Random(11)));
    final colors = s.colors.toList();
    final f = cornerFacelets[0];
    final t = colors[f[0]];
    colors[f[0]] = colors[f[1]];
    colors[f[1]] = colors[f[2]];
    colors[f[2]] = t;
    expect(
      validateCube(Cube.fromColors(colors)).problem,
      CubeProblem.twistedCorner,
    );
  });

  test('Arête retournée → impossible', () {
    final s = Cube.solved().apply(randomScramble(random: Random(12)));
    final e = edgeFacelets[3];
    expect(validateCube(swap(s, e[0], e[1])).problem, CubeProblem.flippedEdge);
  });

  test('Deux arêtes échangées → parité impossible', () {
    var c = Cube.solved();
    final a = edgeFacelets[0], b = edgeFacelets[1]; // UR <-> UF
    c = swap(c, a[0], b[0]);
    c = swap(c, a[1], b[1]);
    expect(validateCube(c).problem, CubeProblem.swappedPieces);
  });

  test('Coin aux couleurs impossibles (deux blancs)', () {
    var c = Cube.solved();
    // Le coin URF reçoit blanc/blanc/vert : on échange avec une case blanche
    // d'ailleurs pour garder 9 cases blanches… et 9 rouges.
    c = swap(c, 9, 7); // R1 (rouge) <-> U8 (blanc)
    final r = validateCube(c);
    expect(r.problem, CubeProblem.impossibleCorner);
    expect(r.suspectFacelets, cornerFacelets[0]);
  });

  test('Arête en double', () {
    // UF devient blanc/rouge (copie de UR) et DR devient jaune/vert (copie
    // de DF) : toujours 9 cases par couleur.
    final colors = Cube.solved().colors.toList();
    colors[19] = CubeColor.red;
    colors[16] = CubeColor.green;
    expect(
      validateCube(Cube.fromColors(colors)).problem,
      CubeProblem.duplicatePiece,
    );
  });
}
