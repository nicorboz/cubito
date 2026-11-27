// Tests des cartes du livret (place / formule / geste / vérifie).
import 'dart:math';

import 'package:cube_magique/core/cube/cube.dart';
import 'package:cube_magique/core/cube/solver.dart';
import 'package:cube_magique/core/method/method.dart';
import 'package:cube_magique/features/guide/guide_cards.dart';
import 'package:cube_magique/features/guide/guided_player.dart';
import 'package:cube_magique/app.dart';
import 'package:cube_magique/render/flat_cube.dart';
import 'package:cube_magique/shared/gesture_text.dart';
import 'package:cube_magique/l10n/app_localizations_fr.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'test_app.dart';

void main() {
  test('Les cartes rejouent exactement la solution', () {
    final rnd = Random(4);
    for (var i = 0; i < 300; i++) {
      final start = Cube.solved().apply(randomScramble(random: rnd));
      final sol = solveBeginner(start);
      final cards = buildCards(start, sol.actions);
      var c = start;
      for (final card in cards) {
        expect(card.before, c);
        c = card.after;
      }
      expect(c.isSolved, isTrue);
      // Aucune rotation du cube entier hors des cartes « place ton cube ».
      for (final card in cards.whereType<GestureCard>()) {
        expect(card.move.kind.isRotation, isFalse);
      }
      // Jamais deux cartes « place » de suite.
      for (var k = 1; k < cards.length; k++) {
        expect(cards[k] is PlaceCard && cards[k - 1] is PlaceCard, isFalse);
      }
      // Une vérification après chaque formule.
      expect(
        cards.whereType<CheckCard>().length,
        cards.whereType<FormulaCard>().length,
      );
    }
  });

  test('Formules longues coupées en morceaux de 4', () {
    expect(chunksOf(Algorithm.petiteDanse.moves).length, 1);
    final tob = chunksOf(Algorithm.tobogganDroit.moves);
    expect(tob.map((c) => c.length).toList(), [4, 4]);
    expect(
      chunksOf(Algorithm.etoileJaune.moves).map((c) => c.length).toList(),
      [3, 3],
    );
  });

  test('Chanson de la petite danse', () {
    expect(
      formulaChant(AppLocalizationsFr(), Algorithm.petiteDanse.moves),
      'Descends, à gauche, monte, à droite.',
    );
  });

  test('Glisser sur le dessin donne le bon geste', () {
    final g = FlatGeometry(const Size(282, 266));
    Offset center(FlatCell c) => g.cell(c).reduce((a, b) => a + b) / 4;
    expect(
      flatSwipeToMove(g, center((Face.f, 1, 2)), const Offset(0, -40)),
      Move.parse('R'),
    );
    expect(
      flatSwipeToMove(g, center((Face.f, 1, 2)), const Offset(0, 40)),
      Move.parse("R'"),
    );
    expect(
      flatSwipeToMove(g, center((Face.f, 0, 1)), const Offset(-40, 0)),
      Move.parse('U'),
    );
    expect(
      flatSwipeToMove(g, center((Face.f, 2, 1)), const Offset(40, 0)),
      Move.parse('D'),
    );
    expect(
      flatSwipeToMove(g, center((Face.f, 1, 0)), const Offset(0, 40)),
      Move.parse('L'),
    );
    expect(
      flatSwipeToMove(g, center((Face.u, 2, 1)), const Offset(40, 0)),
      Move.parse('F'),
    );
    expect(
      flatSwipeToMove(g, center((Face.f, 1, 1)), const Offset(40, 0)),
      isNull,
    );
  });

  test('Les cases dessinées correspondent aux facettes du modèle', () {
    // Après R, la colonne de droite de la face avant vient du bas (jaune).
    final c = Cube.solved().apply('R');
    expect(c[faceletOf((Face.f, 0, 2))], CubeColor.yellow);
    expect(c[faceletOf((Face.u, 2, 2))], CubeColor.green);
  });

  testWidgets('À toi : glisser la colonne de droite vers le haut valide R', (
    tester,
  ) async {
    final a = SolveAction(
      step: MethodStep.coinsBlancs,
      type: ActionType.algorithm,
      moves: parseMoves('R'),
      hint: SolveHint.petiteDanseCoinBlanc,
    );
    var finished = false;
    await pumpWithProviders(
      tester,
      CubeMagiqueApp(
        home: Scaffold(
          body: GuidedPlayer(
            cards: buildCards(Cube.solved(), [a], checks: false),
            mode: GuideMode.doIt,
            onFinished: () => finished = true,
          ),
        ),
      ),
      size: const Size(420, 900),
    );
    final box = tester.getRect(find.byType(FlatCube));
    final g = FlatGeometry(box.size);
    final p = box.topLeft + g.cell((Face.f, 1, 2)).reduce((a, b) => a + b) / 4;
    await tester.dragFrom(p, const Offset(0, 60));
    await tester.pump();
    expect(find.textContaining('Presque'), findsOneWidget); // mauvais sens
    await tester.dragFrom(p, const Offset(0, -60));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(finished, isTrue);
  });

  test('Résoudre : une seule carte « tiens ton cube » au début', () {
    final rnd = Random(12);
    const hold = SolveAction(
      step: MethodStep.croixBlanche,
      type: ActionType.rotateCube,
      moves: [],
      hint: SolveHint.retournerJauneEnHaut,
    );
    for (var i = 0; i < 200; i++) {
      final start = Cube.solved().apply(randomScramble(random: rnd));
      final cards = buildCards(start, [hold, ...solveBeginner(start).actions]);
      expect(cards.first, isA<PlaceCard>());
      expect(cards[1], isNot(isA<PlaceCard>()));
      expect(cards.first.before, start);
    }
  });
}
