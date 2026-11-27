// Fabrique des situations d'exemple pour chaque île : un cube où les étapes
// précédentes sont faites et l'étape de l'île reste à faire.
import 'dart:math';

import '../../core/cube/cube.dart';
import '../../core/cube/solver.dart';
import '../../core/method/method.dart';
import 'islands.dart';

/// Une situation : l'état de départ et la solution de l'île.
class Situation {
  Situation(this.start, this.actions);
  final Cube start;
  final List<SolveAction> actions;

  Cube get end => start.apply([for (final a in actions) ...a.allMoves]);

  /// La solution coup par coup (doubles gardés tels quels).
  List<LessonMove> get moves => [
    for (final a in actions)
      for (var r = 1; r <= a.repetitions; r++)
        for (var k = 0; k < a.moves.length; k++)
          LessonMove(a.moves[k], a, r, k),
  ];
}

/// Un coup de la leçon, avec son contexte (action, répétition…).
class LessonMove {
  const LessonMove(this.move, this.action, this.repetition, this.indexInRep);
  final Move move;
  final SolveAction action;

  /// N° de la répétition (1 = première fois).
  final int repetition;
  final int indexInRep;
}

/// Cube au début de l'île [island] à partir d'un cube mélangé.
Cube startOfIsland(Cube scrambled, Island island) {
  if (island.index == 0) return scrambled;
  final before = solveSteps(
    scrambled,
    from: MethodStep.croixBlanche,
    to: MethodStep.values[island.first.index - 1],
  );
  return scrambled.apply(before.allMoves);
}

/// Situation aléatoire (non vide) pour une île.
Situation randomSituation(Island island, Random rnd) {
  for (var attempt = 0; attempt < 200; attempt++) {
    var start = startOfIsland(
      Cube.solved().apply(randomScramble(random: rnd)),
      island,
    );
    if (island.index == 1) {
      // Croix faite mais pas dans l'ordre : on mélange les arêtes du haut.
      for (var k = 0; k < 2; k++) {
        start = start.apply(['', 'y', 'y2', "y'"][rnd.nextInt(4)]);
        start = start.apply(Algorithm.escargot.notation);
      }
      start = start.apply(['U', 'U2', "U'"][rnd.nextInt(3)]);
    }
    final sol = solveSteps(start, from: island.first, to: island.last);
    final actions = sol.actions;
    final useful =
        island.index == 3 ||
        actions.any(
          (a) =>
              a.type == ActionType.algorithm || a.type == ActionType.turnLayer,
        );
    if (actions.isNotEmpty && useful) return Situation(start, actions);
  }
  throw StateError('Pas de situation pour l\'île ${island.number}');
}

/// Situation d'exemple courte et toujours la même pour une île (leçon).
Situation exampleSituation(Island island) {
  final rnd = Random(1000 + island.index);
  Situation? best;
  for (var k = 0; k < 25; k++) {
    final s = randomSituation(island, rnd);
    final n = s.moves.length;
    // Pour l'étoile jaune, on montre le cas du point (3 fois) : plus parlant.
    final isPoint = yellowPattern(s.start) == YellowPattern.point;
    if (island.index == 5 && !isPoint) {
      continue;
    }
    if (best == null || n < best.moves.length) best = s;
  }
  return best ?? randomSituation(island, rnd);
}
