// Les 8 îles du mode « Apprendre » (une île = une étape vue par l'enfant).
import 'package:material_ui/material_ui.dart';

import '../../core/cube/cube.dart';
import '../../core/method/method.dart';
import '../../l10n/app_localizations.dart';

class Island {
  const Island(this.index, this.steps, this.color, this.algorithms);

  /// 0 à 7 (affiché « Île 1 » à « Île 8 »).
  final int index;

  /// Étapes de la méthode couvertes (l'île 8 regroupe 8a et 8b).
  final List<MethodStep> steps;
  final Color color;

  /// Algorithmes à surnom appris sur cette île.
  final List<Algorithm> algorithms;

  int get number => index + 1;
  MethodStep get first => steps.first;
  MethodStep get last => steps.last;

  String title(AppLocalizations l) => [
    l.island1Title,
    l.island2Title,
    l.island3Title,
    l.island4Title,
    l.island5Title,
    l.island6Title,
    l.island7Title,
    l.island8Title,
  ][index];

  String goal(AppLocalizations l) => [
    l.island1Goal,
    l.island2Goal,
    l.island3Goal,
    l.island4Goal,
    l.island5Goal,
    l.island6Goal,
    l.island7Goal,
    l.island8Goal,
  ][index];

  List<String> rules(AppLocalizations l) => switch (index) {
    0 => [l.island1Rule1, l.island1Rule2, l.island1Rule3, l.island1Rule4],
    1 => [l.island2Rule1, l.island2Rule2, l.island2Rule3, l.island2Rule4],
    2 => [l.island3Rule1, l.island3Rule2, l.island3Rule3, l.island3Rule4],
    3 => [l.island4Rule1, l.island4Rule2],
    4 => [l.island5Rule1, l.island5Rule2, l.island5Rule3, l.island5Rule4],
    5 => [l.island6Rule1, l.island6Rule2, l.island6Rule3],
    6 => [l.island7Rule1, l.island7Rule2, l.island7Rule3, l.island7Rule4],
    _ => [
      l.island8Rule1,
      l.island8Rule2,
      l.island8Rule3,
      l.island8Rule4,
      l.island8Rule5,
    ],
  };

  /// L'île est réussie quand cet état est atteint (orientation comprise).
  bool isGoalReached(Cube c) {
    final whiteUp = c.center(Face.u) == CubeColor.white;
    return switch (index) {
      0 => whiteUp && isWhiteCrossFormed(c),
      1 => whiteUp && isWhiteCrossDone(c),
      2 => whiteUp && isFirstLayerDone(c),
      _ => isStepDone(last, c),
    };
  }
}

const islands = [
  Island(0, [MethodStep.croixBlanche], Color(0xFFE6A100), []),
  Island(1, [MethodStep.aretesCroix], Color(0xFF8E5AC8), [Algorithm.escargot]),
  Island(
    2,
    [MethodStep.coinsBlancs],
    Color(0xFFD9467A),
    [Algorithm.petiteDanse],
  ),
  Island(3, [MethodStep.retourner], Color(0xFF2E9CCA), []),
  Island(
    4,
    [MethodStep.deuxiemeCouronne],
    Color(0xFF1E8E3E),
    [Algorithm.tobogganDroit, Algorithm.tobogganGauche],
  ),
  Island(
    5,
    [MethodStep.etoileJaune],
    Color(0xFFE08A00),
    [Algorithm.etoileJaune],
  ),
  Island(6, [MethodStep.aretesJaunes], Color(0xFF7B3FC4), [Algorithm.escargot]),
  Island(
    7,
    [MethodStep.placerCoinsJaunes, MethodStep.tournerCoinsJaunes],
    Color(0xFFC2410C),
    [Algorithm.manege, Algorithm.petiteDanse],
  ),
];
