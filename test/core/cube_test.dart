// Tests du modèle et des mouvements.
import 'dart:math';

import 'package:cube_magique/core/cube/cube.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final all = [
    for (final k in MoveKind.values)
      for (var t = 1; t <= 3; t++) Move(k, t),
  ];

  test('Cube résolu : 9 cases par couleur, résolu', () {
    final c = Cube.solved();
    expect(c.isSolved, isTrue);
    expect(
      c.toString(),
      'W' * 9 + 'R' * 9 + 'G' * 9 + 'Y' * 9 + 'O' * 9 + 'B' * 9,
    );
  });

  test('Chaque mouvement × 4 = identité', () {
    final start = Cube.solved().apply(randomScramble(random: Random(1)));
    for (final m in MoveKind.values) {
      expect(
        start.apply([for (var i = 0; i < 4; i++) Move(m)]),
        start,
        reason: m.symbol,
      );
    }
  });

  test('Mouvement + inverse = identité', () {
    final start = Cube.solved().apply(randomScramble(random: Random(2)));
    for (final m in all) {
      expect(start.move(m).move(m.inverse), start, reason: '$m');
    }
  });

  test('Séquence + séquence inverse = identité', () {
    final rnd = Random(3);
    for (var i = 0; i < 200; i++) {
      final s = randomScramble(random: rnd);
      expect(Cube.solved().apply(s).apply(invertMoves(s)).isSolved, isTrue);
    }
  });

  test('Les rotations du cube entier ne dérèglent rien', () {
    for (final r in ['x', 'y', 'z', 'x2', "y'", 'z2']) {
      expect(Cube.solved().apply(r).isSolved, isTrue, reason: r);
    }
    // x = R + tranche du milieu + L'
    expect(Cube.solved().apply('x').center(Face.u), CubeColor.green);
    expect(Cube.solved().apply('y').center(Face.f), CubeColor.red);
    expect(Cube.solved().apply('x2').center(Face.u), CubeColor.yellow);
  });

  test('Un mouvement de face change bien la face voisine', () {
    expect(Cube.solved().apply('R').isSolved, isFalse);
    // Sexy move × 6 = identité (propriété connue).
    expect(
      Cube.solved().apply(List.filled(6, "R U R' U'").join(' ')).isSolved,
      isTrue,
    );
  });

  test('Lecture / écriture de la notation', () {
    final m = parseMoves("R U' F2 x2 y' D");
    expect(formatMoves(m), "R U' F2 x2 y' D");
    expect(formatMoves(invertMoves(parseMoves("R U F'"))), "F U' R'");
    expect(() => Move.parse('Q'), throwsFormatException);
    expect(Move.parse('R’'), Move(MoveKind.r, 3)); // apostrophe typographique
  });

  test('Mélange : 25 coups, sans annulations', () {
    final rnd = Random(4);
    for (var i = 0; i < 500; i++) {
      final s = randomScramble(random: rnd);
      expect(s.length, 25);
      for (var k = 1; k < s.length; k++) {
        expect(s[k].kind == s[k - 1].kind, isFalse);
        if (k >= 2 && s[k].kind.axis == s[k - 1].kind.axis) {
          expect(s[k].kind == s[k - 2].kind, isFalse);
        }
      }
      expect(Cube.solved().apply(s).isSolved, isFalse);
    }
  });

  test('fromString / toString aller-retour', () {
    final c = Cube.solved().apply(randomScramble(random: Random(5)));
    expect(Cube.fromString(c.toString()), c);
  });
}
