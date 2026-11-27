// Phrases enfant pour les actions du solveur et les noms d'algorithmes.
import '../core/cube/solver.dart';
import '../core/method/method.dart';
import '../l10n/app_localizations.dart';

String algorithmName(AppLocalizations l, Algorithm a) => switch (a) {
  Algorithm.petiteDanse => l.algoPetiteDanse,
  Algorithm.escargot => l.algoEscargot,
  Algorithm.tobogganDroit => l.algoTobogganDroit,
  Algorithm.tobogganGauche => l.algoTobogganGauche,
  Algorithm.etoileJaune => l.algoEtoileJaune,
  Algorithm.manege => l.algoManege,
};

String hintText(AppLocalizations l, SolveAction a) => switch (a.hint) {
  SolveHint.retournerJauneEnHaut => l.hintRetournerJauneEnHaut,
  SolveHint.petale => l.hintPetale,
  SolveHint.petaleAuDessusDeSaCouleur => l.hintPetaleAuDessusDeSaCouleur,
  SolveHint.petaleDevant => l.hintPetaleDevant,
  SolveHint.petaleDescend => l.hintPetaleDescend,
  SolveHint.retournerBlancEnHaut => l.hintRetournerBlancEnHaut,
  SolveHint.arretesAligner => l.hintArretesAligner,
  SolveHint.aucune => '',
  SolveHint.faceAreteNonAlignee => l.hintFaceAreteNonAlignee,
  SolveHint.escargot => l.hintEscargot,
  SolveHint.coinCibleDevantDroite => l.hintCoinCibleDevantDroite,
  SolveHint.coinSousSaPlace => l.hintCoinSousSaPlace,
  SolveHint.petiteDanseCoinBlanc => l.hintPetiteDanseCoinBlanc(a.repetitions),
  SolveHint.sortirCoinBlanc => l.hintSortirCoinBlanc,
  SolveHint.tournerCoinBlancEnPlace => l.hintTournerCoinBlancEnPlace,
  SolveHint.retournerBlancEnBas => l.hintRetournerBlancEnBas,
  SolveHint.faireTAlEnvers => l.hintFaireTAlEnvers,
  SolveHint.tDevant => l.hintTDevant,
  SolveHint.tobogganDroit => l.hintTobogganDroit,
  SolveHint.tobogganGauche => l.hintTobogganGauche,
  SolveHint.areteMalPlaceeDevantDroite => l.hintAreteMalPlaceeDevantDroite,
  SolveHint.sortirArete => l.hintSortirArete,
  SolveHint.placerMotifJaune => l.hintPlacerMotifJaune,
  SolveHint.etoileJaune => l.hintEtoileJaune,
  SolveHint.coinBienPlaceEnHautADroite => l.hintCoinBienPlaceEnHautADroite,
  SolveHint.manege => l.hintManege,
  SolveHint.amenerCoinJaune => l.hintAmenerCoinJaune,
  SolveHint.petiteDanseCoinJaune => l.hintPetiteDanseCoinJaune,
  SolveHint.alignerDernierePlace => l.hintAlignerDernierePlace,
};
