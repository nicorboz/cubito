import 'dart:math';

import 'package:cube_magique/core/cube/cube.dart';
import 'package:cube_magique/core/cube/fast_solver.dart';
import 'package:cube_magique/features/guide/guide_cards.dart';
import 'package:cube_magique/features/solve/short_path.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('chemin court : jamais la face arrière, et le cube finit résolu', () {
    final rnd = Random(11);
    for (var i = 0; i < 25; i++) {
      final c = Cube.solved().apply(randomScramble(random: rnd));
      final sol = FastSolver.solve(
        c,
        timeLimit: const Duration(milliseconds: 200),
      );
      final cards = buildShortCards(c, sol.moves);
      expect(cards.first, isA<PlaceCard>());
      var cube = c;
      for (final card in cards) {
        expect(card.before, cube);
        if (card is GestureCard) {
          expect(card.move.kind, isNot(MoveKind.b));
          expect(card.chunk.length, lessThanOrEqualTo(4));
        }
        cube = card.after;
      }
      expect(cube.isSolved, isTrue);
      // Une vérification après chaque groupe, et au moins une à la fin.
      expect(cards.last, isA<CheckCard>());
    }
  });
}
