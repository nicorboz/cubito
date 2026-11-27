// Le parcours « Apprendre » : les formules dans l'ordre où on s'en sert
// pour résoudre le cube, de A à Z. Une formule qui resservira plus tard
// revient à sa place, en révision.
import 'dart:math';

import 'package:material_ui/material_ui.dart';

import '../../core/cube/cube.dart';
import '../../core/cube/solver.dart';
import '../../core/method/method.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/solve_text.dart';
import 'islands.dart';
import 'lesson_examples.dart';

enum LessonKind { basics, rotate, formula }

class Lesson {
  const Lesson(
    this.index,
    this.kind,
    this.islandIndex, {
    this.algorithm,
    this.review = false,
  });

  /// 0 à 9 (affiché « Leçon 1 » à « Leçon 10 »).
  final int index;
  final LessonKind kind;

  /// Étape de la méthode où l'on s'en sert.
  final int islandIndex;
  final Algorithm? algorithm;

  /// La formule a déjà été apprise : on la revoit pour une autre étape.
  final bool review;

  int get number => index + 1;
  Island get island => islands[islandIndex];
  Color get color => island.color;

  String title(AppLocalizations l) => switch (kind) {
    LessonKind.basics => l.lessonBasicsTitle,
    LessonKind.rotate => island.title(l),
    LessonKind.formula =>
      review
          ? l.lessonReview(algorithmName(l, algorithm!))
          : algorithmName(l, algorithm!),
  };

  String emoji() => switch (kind) {
    LessonKind.basics => '👆',
    LessonKind.rotate => '🔄',
    LessonKind.formula => algorithm!.emoji,
  };

  /// « Étape 3 : Les coins blancs » (ou « Avant de commencer »).
  String when(AppLocalizations l) => kind == LessonKind.basics
      ? l.lessonBasicsUse
      : l.solveStep(island.number, island.title(l));

  String goal(AppLocalizations l) =>
      kind == LessonKind.basics ? l.lessonBasicsGoal : island.goal(l);

  /// Gestes appris (la formule, ou les 10 gestes de base).
  List<Move> get moves => switch (kind) {
    LessonKind.basics => basicMoves,
    LessonKind.rotate => [Move.parse('x2')],
    LessonKind.formula => algorithm!.moves,
  };
}

/// Les 10 gestes de base, par paires (le 2ᵉ défait le 1ᵉʳ).
final basicMoves = parseMoves("R R' L L' U U' D D' F F'");

const lessons = [
  Lesson(0, LessonKind.basics, 0),
  Lesson(1, LessonKind.formula, 1, algorithm: Algorithm.escargot),
  Lesson(2, LessonKind.formula, 2, algorithm: Algorithm.petiteDanse),
  Lesson(3, LessonKind.rotate, 3),
  Lesson(4, LessonKind.formula, 4, algorithm: Algorithm.tobogganDroit),
  Lesson(5, LessonKind.formula, 4, algorithm: Algorithm.tobogganGauche),
  Lesson(6, LessonKind.formula, 5, algorithm: Algorithm.etoileJaune),
  Lesson(7, LessonKind.formula, 6, algorithm: Algorithm.escargot, review: true),
  Lesson(8, LessonKind.formula, 7, algorithm: Algorithm.manege),
  Lesson(
    9,
    LessonKind.formula,
    7,
    algorithm: Algorithm.petiteDanse,
    review: true,
  ),
];

final _cache = <int, Situation>{};

/// La situation d'une leçon : un vrai moment de la résolution où l'on fait
/// la formule UNE fois (avec la carte « tiens ton cube » qui la précède).
Situation lessonSituation(Lesson lesson) =>
    _cache[lesson.index] ??= _build(lesson);

Situation _build(Lesson lesson) {
  switch (lesson.kind) {
    case LessonKind.basics:
      // Cube résolu, tenu blanc en haut et orange devant.
      var start = Cube.solved();
      for (final r in ['', 'y', 'y2', "y'"]) {
        final c = Cube.solved().apply(r);
        if (c.center(Face.f) == CubeColor.orange) start = c;
      }
      return Situation(start, [
        for (final m in basicMoves)
          SolveAction(
            step: MethodStep.croixBlanche,
            type: ActionType.turnLayer,
            moves: [m],
            hint: SolveHint.aucune,
          ),
      ]);
    case LessonKind.rotate:
      return exampleSituation(lesson.island);
    case LessonKind.formula:
      final rnd = Random(4242 + lesson.index);
      Situation? best;
      var bestReps = 99;
      for (var k = 0; k < 60 && bestReps > 1; k++) {
        final s = randomSituation(lesson.island, rnd);
        var cube = s.start;
        for (var i = 0; i < s.actions.length; i++) {
          final a = s.actions[i];
          if (a.algorithm == lesson.algorithm && a.repetitions < bestReps) {
            // On garde la rotation juste avant (« tiens ton cube comme ça »).
            final prev = i > 0 && s.actions[i - 1].type == ActionType.rotateCube
                ? s.actions[i - 1]
                : null;
            final start = prev == null
                ? cube
                : cube.apply(
                    [for (final m in prev.allMoves) m.inverse].reversed
                        .toList(),
                  );
            best = Situation(start, [?prev, a]);
            bestReps = a.repetitions;
          }
          cube = cube.apply(a.allMoves);
        }
      }
      return best ?? exampleSituation(lesson.island);
  }
}
