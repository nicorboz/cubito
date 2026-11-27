// Le solveur « méthode débutant » : 10 000 mélanges résolus, en restant
// strictement dans la méthode enseignée.
import 'dart:math';

import 'package:cube_magique/core/cube/cube.dart';
import 'package:cube_magique/core/cube/solver.dart';
import 'package:cube_magique/core/method/method.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mouvements que l'enfant connaît (vocabulaire de la section 3.1, plus
/// « 2 fois » une face) : jamais B, ni tranche, ni rotation x/z hors x2.
final allowedFaces = {
  MoveKind.u,
  MoveKind.d,
  MoveKind.r,
  MoveKind.l,
  MoveKind.f,
};

void checkSolution(Cube start, Solution s) {
  var c = start;
  final order = MethodStep.values;
  expect(s.steps.map((e) => e.step).toList(), order);
  for (final step in s.steps) {
    for (final a in step.actions) {
      expect(a.step, step.step);
      switch (a.type) {
        case ActionType.rotateCube:
          for (final m in a.moves) {
            expect(
              m.kind == MoveKind.y || (m.kind == MoveKind.x && m.turns == 2),
              isTrue,
              reason: 'rotation $m',
            );
          }
          // Étape 8b : interdit de tourner le cube entier.
          expect(step.step, isNot(MethodStep.tournerCoinsJaunes));
        case ActionType.turnLayer:
          for (final m in a.moves) {
            expect(
              allowedFaces.contains(m.kind),
              isTrue,
              reason: 'mouvement $m',
            );
          }
          expect(a.algorithm, isNull);
        case ActionType.algorithm:
          expect(a.algorithm, isNotNull);
          expect(formatMoves(a.moves), a.algorithm!.notation);
      }
      c = c.apply(a.allMoves);
    }
    // Chaque étape est réussie, et les précédentes ne sont pas cassées
    // (l'étape 4 ne compte qu'une fois le cube retourné).
    for (final done in order.take(step.step.index + 1)) {
      if (done.index <= MethodStep.coinsBlancs.index) {
        expect(isFirstLayerDone(c) || isStepDone(done, c), isTrue);
      } else {
        expect(
          isStepDone(done, c),
          isTrue,
          reason: '${done.name} après ${step.step.name}',
        );
      }
    }
  }
  expect(c.isSolved, isTrue);
}

void main() {
  test('10 000 mélanges aléatoires résolus sans échec, dans la méthode', () {
    final rnd = Random(2026);
    for (var i = 0; i < 10000; i++) {
      final start = Cube.solved().apply(randomScramble(random: rnd));
      checkSolution(start, solveBeginner(start));
    }
  });

  test('Algorithmes utilisés à la bonne étape', () {
    final rnd = Random(7);
    const expected = {
      MethodStep.aretesCroix: {Algorithm.escargot},
      MethodStep.coinsBlancs: {Algorithm.petiteDanse},
      MethodStep.deuxiemeCouronne: {
        Algorithm.tobogganDroit,
        Algorithm.tobogganGauche,
      },
      MethodStep.etoileJaune: {Algorithm.etoileJaune},
      MethodStep.aretesJaunes: {Algorithm.escargot},
      MethodStep.placerCoinsJaunes: {Algorithm.manege},
      MethodStep.tournerCoinsJaunes: {Algorithm.petiteDanse},
    };
    for (var i = 0; i < 500; i++) {
      final s = solveBeginner(Cube.solved().apply(randomScramble(random: rnd)));
      for (final step in s.steps) {
        for (final a in step.actions.where((a) => a.algorithm != null)) {
          expect(
            expected[step.step],
            contains(a.algorithm),
            reason: step.step.name,
          );
        }
      }
    }
  });

  test('Règles de répétition respectées', () {
    final rnd = Random(8);
    for (var i = 0; i < 1000; i++) {
      final s = solveBeginner(Cube.solved().apply(randomScramble(random: rnd)));
      for (final a in s.actions) {
        if (a.hint == SolveHint.petiteDanseCoinBlanc) {
          expect([1, 3, 5], contains(a.repetitions));
        }
        if (a.hint == SolveHint.petiteDanseCoinJaune) {
          expect([2, 4], contains(a.repetitions));
        }
      }
      final stars = s.steps[MethodStep.etoileJaune.index].actions
          .where((a) => a.algorithm == Algorithm.etoileJaune)
          .length;
      expect(stars, lessThanOrEqualTo(3));
      final manege = s.steps[MethodStep.placerCoinsJaunes.index].actions
          .where((a) => a.algorithm == Algorithm.manege)
          .length;
      expect(manege, lessThanOrEqualTo(3));
    }
  });

  test('Cube déjà résolu : seulement retourner le cube', () {
    final s = solveBeginner(Cube.solved());
    expect(s.allMoves.every((m) => m.kind.isRotation), isTrue);
  });

  test('Croix blanche déjà faite : pas de marguerite', () {
    final start = Cube.solved().apply("R' D' R D D F2 F2"); // croix intacte
    final s = solveBeginner(start);
    expect(s.steps.first.actions, isEmpty);
    checkSolution(start, s);
  });

  test('solveSteps : chaque étape seule, à partir du bon état', () {
    final rnd = Random(9);
    for (var i = 0; i < 300; i++) {
      var c = Cube.solved().apply(randomScramble(random: rnd));
      for (final step in MethodStep.values) {
        final part = solveSteps(c, from: step, to: step);
        expect(part.steps.single.step, step);
        c = c.apply(part.allMoves);
        expect(isStepDone(step, c), isTrue);
      }
      expect(c.isSolved, isTrue);
    }
  });
}
