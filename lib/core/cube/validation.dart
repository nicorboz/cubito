// Validation d'un cube saisi par l'enfant (couleurs de SON vrai cube).
// Renvoie le premier problème trouvé + les cases à surligner.
import 'cube.dart';
import 'cubies.dart';

/// Types de problèmes, du plus simple à expliquer au plus technique.
enum CubeProblem {
  /// Une couleur n'apparaît pas exactement 9 fois.
  wrongColorCount,

  /// Deux centres ont la même couleur.
  duplicateCenters,

  /// Les centres ne sont pas placés comme sur un vrai cube
  /// (ex. blanc à côté du jaune au lieu d'être opposés).
  impossibleCenters,

  /// Un coin a une combinaison de couleurs qui n'existe pas.
  impossibleCorner,

  /// Une arête a une combinaison de couleurs qui n'existe pas.
  impossibleEdge,

  /// La même pièce apparaît deux fois.
  duplicatePiece,

  /// Un coin est « tourné » d'une façon impossible (cube démonté/remonté ?).
  twistedCorner,

  /// Une arête est « retournée » d'une façon impossible.
  flippedEdge,

  /// Deux pièces sont échangées d'une façon impossible.
  swappedPieces,
}

class ValidationResult {
  const ValidationResult.ok()
    : problem = null,
      suspectFacelets = const [],
      suspectColor = null;

  const ValidationResult.error(
    CubeProblem this.problem, {
    this.suspectFacelets = const [],
    this.suspectColor,
  });

  /// null si le cube est possible.
  final CubeProblem? problem;

  /// Cases à faire clignoter (indices de facettes).
  final List<int> suspectFacelets;

  /// Couleur concernée, pour le message (« vérifie la face rouge »).
  final CubeColor? suspectColor;

  bool get isValid => problem == null;

  @override
  String toString() =>
      isValid ? 'OK' : '$problem couleur=$suspectColor cases=$suspectFacelets';
}

/// Paires de couleurs opposées sur un cube standard.
const _opposite = <CubeColor, CubeColor>{
  CubeColor.white: CubeColor.yellow,
  CubeColor.yellow: CubeColor.white,
  CubeColor.green: CubeColor.blue,
  CubeColor.blue: CubeColor.green,
  CubeColor.red: CubeColor.orange,
  CubeColor.orange: CubeColor.red,
};

const _oppositeFace = <Face, Face>{
  Face.u: Face.d,
  Face.d: Face.u,
  Face.r: Face.l,
  Face.l: Face.r,
  Face.f: Face.b,
  Face.b: Face.f,
};

ValidationResult validateCube(Cube cube) {
  // 1. Exactement 9 cases de chaque couleur.
  final counts = <CubeColor, int>{for (final c in CubeColor.values) c: 0};
  for (var i = 0; i < 54; i++) {
    counts[cube[i]] = counts[cube[i]]! + 1;
  }
  for (final c in CubeColor.values) {
    if (counts[c] != 9) {
      // On surligne la couleur en trop (plus facile à corriger).
      final over = CubeColor.values.firstWhere(
        (x) => counts[x]! > 9,
        orElse: () => c,
      );
      return ValidationResult.error(
        CubeProblem.wrongColorCount,
        suspectColor: over,
        suspectFacelets: [
          for (var i = 0; i < 54; i++)
            if (cube[i] == over && i % 9 != 4) i,
        ],
      );
    }
  }

  // 2. Centres tous différents.
  final centers = [for (final f in Face.values) cube.center(f)];
  if (centers.toSet().length != 6) {
    return ValidationResult.error(
      CubeProblem.duplicateCenters,
      suspectFacelets: [for (var f = 0; f < 6; f++) f * 9 + 4],
    );
  }

  // 3. Centres opposés cohérents (blanc/jaune, vert/bleu, rouge/orange).
  for (final f in Face.values) {
    if (cube.center(_oppositeFace[f]!) != _opposite[cube.center(f)]) {
      return ValidationResult.error(
        CubeProblem.impossibleCenters,
        suspectColor: cube.center(f),
        suspectFacelets: [f.index * 9 + 4, _oppositeFace[f]!.index * 9 + 4],
      );
    }
  }

  final view = CubieView.of(cube);

  // 4. Chaque coin et chaque arête existe physiquement, une seule fois.
  for (var slot = 0; slot < 8; slot++) {
    if (view.cornerPerm[slot] < 0) {
      return ValidationResult.error(
        CubeProblem.impossibleCorner,
        suspectFacelets: cornerFacelets[slot],
        suspectColor: cube[cornerFacelets[slot][0]],
      );
    }
  }
  for (var slot = 0; slot < 12; slot++) {
    if (view.edgePerm[slot] < 0) {
      return ValidationResult.error(
        CubeProblem.impossibleEdge,
        suspectFacelets: edgeFacelets[slot],
        suspectColor: cube[edgeFacelets[slot][0]],
      );
    }
  }
  for (var a = 0; a < 8; a++) {
    for (var b = a + 1; b < 8; b++) {
      if (view.cornerPerm[a] == view.cornerPerm[b]) {
        return ValidationResult.error(
          CubeProblem.duplicatePiece,
          suspectFacelets: [...cornerFacelets[a], ...cornerFacelets[b]],
          suspectColor: cube[cornerFacelets[a][0]],
        );
      }
    }
  }
  for (var a = 0; a < 12; a++) {
    for (var b = a + 1; b < 12; b++) {
      if (view.edgePerm[a] == view.edgePerm[b]) {
        return ValidationResult.error(
          CubeProblem.duplicatePiece,
          suspectFacelets: [...edgeFacelets[a], ...edgeFacelets[b]],
          suspectColor: cube[edgeFacelets[a][0]],
        );
      }
    }
  }

  // 5. Somme des orientations : coins ≡ 0 (mod 3), arêtes ≡ 0 (mod 2).
  if (view.cornerOri.reduce((a, b) => a + b) % 3 != 0) {
    return const ValidationResult.error(CubeProblem.twistedCorner);
  }
  if (view.edgeOri.reduce((a, b) => a + b) % 2 != 0) {
    return const ValidationResult.error(CubeProblem.flippedEdge);
  }

  // 6. Parité : coins et arêtes doivent avoir la même parité.
  if (permutationParity(view.cornerPerm) != permutationParity(view.edgePerm)) {
    return const ValidationResult.error(CubeProblem.swappedPieces);
  }

  return const ValidationResult.ok();
}
