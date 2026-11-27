// La méthode enseignée à l'enfant : 8 étapes, 6 algorithmes à surnom,
// et les tests « cette étape est-elle faite ? ».
// Dart pur (aucune dépendance Flutter).
import '../cube/cube.dart';
import '../cube/cubies.dart';

/// Les algorithmes de la méthode, avec leur surnom.
/// Tous sont vérifiés par simulation dans test/core/method_test.dart.
enum Algorithm {
  /// La petite danse : coins blancs (étape 3) et coins jaunes (étape 8b).
  petiteDanse("R' D' R D", '💃'),

  /// L'escargot : échange l'arête de DEVANT et celle de GAUCHE du haut,
  /// sans toucher les deux autres (étapes 2 et 7).
  escargot("R U R' U R U2 R' U", '🐌'),

  /// Toboggan droit : l'arête de devant (en haut) descend à droite.
  tobogganDroit("U R U' R' U' F' U F", '🛝'),

  /// Toboggan gauche : l'arête de devant (en haut) descend à gauche.
  tobogganGauche("U' L' U L U F U' F'", '🛝'),

  /// L'étoile jaune (version du protocole, validée par simulation) :
  /// petit L en haut à gauche → croix ; ligne avant-arrière → petit L.
  etoileJaune("R' U' F' U F R", '⭐'),

  /// Le manège des coins : garde le coin en haut à droite, fait tourner
  /// les 3 autres coins du haut.
  manege("L' U R U' L U R' U'", '🎠');

  const Algorithm(this.notation, this.emoji);

  final String notation;
  final String emoji;

  List<Move> get moves => parseMoves(notation);
}

/// Les étapes de la méthode, dans l'ordre.
enum MethodStep {
  /// 1. La marguerite puis la croix blanche.
  croixBlanche,

  /// 2. Les arêtes de la croix dans l'ordre (souvent déjà fait grâce à
  /// l'alignement des pétales de l'étape 1).
  aretesCroix,

  /// 3. Les coins blancs.
  coinsBlancs,

  /// 4. Retourner le cube (blanc en bas).
  retourner,

  /// 5. La 2ᵉ couronne.
  deuxiemeCouronne,

  /// 6. L'étoile jaune.
  etoileJaune,

  /// 7. Les arêtes jaunes dans l'ordre.
  aretesJaunes,

  /// 8a. Placer les coins jaunes.
  placerCoinsJaunes,

  /// 8b. Tourner les coins jaunes : cube résolu.
  tournerCoinsJaunes,
}

// ---------------------------------------------------------------------------
// Tests d'état. Ils ne dépendent pas de l'orientation du cube : les faces
// sont repérées par la couleur de leur centre.
// ---------------------------------------------------------------------------

/// Face dont le centre a cette couleur.
Face faceOfColor(Cube cube, CubeColor color) =>
    Face.values.firstWhere((f) => cube.center(f) == color);

bool _stickerOk(Cube cube, int i) =>
    cube[i] == cube.center(Face.values[i ~/ 9]);

bool _touches(List<int> facelets, Face face) =>
    facelets.any((i) => i ~/ 9 == face.index);

/// Arêtes (emplacements) qui touchent une face.
List<List<int>> edgesAround(Face face) => [
  for (final e in edgeFacelets)
    if (_touches(e, face)) e,
];

/// Coins (emplacements) qui touchent une face.
List<List<int>> cornersAround(Face face) => [
  for (final c in cornerFacelets)
    if (_touches(c, face)) c,
];

bool _pieceSolved(Cube cube, List<int> facelets) =>
    facelets.every((i) => _stickerOk(cube, i));

/// La marguerite : 4 arêtes blanches avec le blanc posé autour du centre jaune.
bool isDaisy(Cube cube) {
  final yellow = faceOfColor(cube, CubeColor.yellow);
  return edgesAround(yellow).every((e) {
    final onYellow = e.firstWhere((i) => i ~/ 9 == yellow.index);
    return cube[onYellow] == CubeColor.white;
  });
}

/// Croix blanche formée (blanc autour du centre blanc), alignée ou non.
bool isWhiteCrossFormed(Cube cube) {
  final white = faceOfColor(cube, CubeColor.white);
  return edgesAround(white).every((e) {
    final onWhite = e.firstWhere((i) => i ~/ 9 == white.index);
    return cube[onWhite] == CubeColor.white;
  });
}

/// Croix blanche faite ET alignée avec les centres (étapes 1 et 2).
bool isWhiteCrossDone(Cube cube) {
  final white = faceOfColor(cube, CubeColor.white);
  return edgesAround(white).every((e) => _pieceSolved(cube, e));
}

/// 1ʳᵉ couronne : face blanche complète + première rangée (étape 3).
bool isFirstLayerDone(Cube cube) {
  final white = faceOfColor(cube, CubeColor.white);
  return isWhiteCrossDone(cube) &&
      cornersAround(white).every((c) => _pieceSolved(cube, c));
}

/// Deux premières couronnes faites (étape 5).
bool isSecondLayerDone(Cube cube) {
  if (!isFirstLayerDone(cube)) return false;
  final white = faceOfColor(cube, CubeColor.white);
  final yellow = faceOfColor(cube, CubeColor.yellow);
  return edgeFacelets
      .where((e) => !_touches(e, white) && !_touches(e, yellow))
      .every((e) => _pieceSolved(cube, e));
}

/// Croix jaune sur la face jaune (étape 6), arêtes pas forcément alignées.
bool isYellowCrossFormed(Cube cube) {
  final yellow = faceOfColor(cube, CubeColor.yellow);
  return edgesAround(yellow).every((e) {
    final onYellow = e.firstWhere((i) => i ~/ 9 == yellow.index);
    return cube[onYellow] == CubeColor.yellow;
  });
}

/// Arêtes jaunes alignées avec leurs centres (étape 7).
bool isYellowEdgesDone(Cube cube) {
  final yellow = faceOfColor(cube, CubeColor.yellow);
  return edgesAround(yellow).every((e) => _pieceSolved(cube, e));
}

/// Un coin est « à sa place » : ses couleurs sont celles des 3 centres
/// qui l'entourent, même s'il est mal tourné.
bool isCornerPlaced(Cube cube, List<int> facelets) {
  final colors = {for (final i in facelets) cube[i]};
  final centers = {for (final i in facelets) cube.center(Face.values[i ~/ 9])};
  return colors.length == 3 && colors.containsAll(centers);
}

/// Tous les coins jaunes à leur place (étape 8a).
bool isYellowCornersPlaced(Cube cube) {
  final yellow = faceOfColor(cube, CubeColor.yellow);
  return cornersAround(yellow).every((c) => isCornerPlaced(cube, c));
}

/// Vrai si l'étape est réussie (pour l'étape 4 : blanc en bas).
bool isStepDone(MethodStep step, Cube cube) => switch (step) {
  MethodStep.croixBlanche => isWhiteCrossFormed(cube),
  MethodStep.aretesCroix => isWhiteCrossDone(cube),
  MethodStep.coinsBlancs => isFirstLayerDone(cube),
  MethodStep.retourner =>
    isFirstLayerDone(cube) && cube.center(Face.d) == CubeColor.white,
  MethodStep.deuxiemeCouronne => isSecondLayerDone(cube),
  MethodStep.etoileJaune =>
    isSecondLayerDone(cube) && isYellowCrossFormed(cube),
  MethodStep.aretesJaunes => isSecondLayerDone(cube) && isYellowEdgesDone(cube),
  MethodStep.placerCoinsJaunes =>
    isSecondLayerDone(cube) &&
        isYellowEdgesDone(cube) &&
        isYellowCornersPlaced(cube),
  MethodStep.tournerCoinsJaunes => cube.isSolved,
};

/// Motif jaune sur le dessus pour l'étape 6 (cube tenu jaune en haut).
enum YellowPattern {
  /// Seulement le centre jaune.
  point,

  /// Petit L tenu en haut à gauche (arêtes du fond et de gauche).
  lHautGauche,

  /// Petit L, mais pas en haut à gauche : il faut tourner la ligne du haut.
  lAilleurs,

  /// Ligne de l'avant vers l'arrière.
  ligneVerticale,

  /// Ligne de gauche à droite : il faut tourner la ligne du haut.
  ligneHorizontale,

  /// Croix jaune terminée.
  croix,
}

/// Lit le motif jaune du dessus (le cube doit être tenu jaune en haut).
YellowPattern yellowPattern(Cube cube) {
  final y = cube.center(Face.u);
  final back = cube[1] == y, left = cube[3] == y;
  final right = cube[5] == y, front = cube[7] == y;
  final n = [back, left, right, front].where((v) => v).length;
  if (n == 4) return YellowPattern.croix;
  if (n == 0) return YellowPattern.point;
  if (back && front) return YellowPattern.ligneVerticale;
  if (left && right) return YellowPattern.ligneHorizontale;
  if (back && left) return YellowPattern.lHautGauche;
  return YellowPattern.lAilleurs;
}

/// Position du blanc d'un coin blanc posé dans le coin bas-avant-droit
/// (étape 3) et nombre de « petites danses » nécessaires.
enum WhiteCornerFacing {
  droite(1),
  dessous(3),
  devant(5);

  const WhiteCornerFacing(this.danses);
  final int danses;
}
