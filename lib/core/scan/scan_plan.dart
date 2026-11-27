// Ordre imposé du scan : quelle face montrer, quel geste faire ensuite, et
// à quelle facette correspond chaque case de la grille vue par la caméra.
//
// Déroulé (raconté par la mascotte) :
//   1. blanc face à toi, vert en haut
//   2. fais rouler le cube vers toi (le dessus vient devant)  → vert
//   3. encore une fois                                          → jaune
//   4. encore une fois                                          → bleu
//   5. tourne le cube vers la gauche                            → orange
//   6. tourne-le encore 2 fois vers la gauche                   → rouge
import '../cube/cube.dart';

/// Geste à faire AVANT de montrer la face.
enum ScanGesture { start, rollTowardYou, turnLeft, turnLeftTwice }

class ScanStep {
  ScanStep(this.gesture, this.rotation, this.center, this.top, this.facelets);

  final ScanGesture gesture;

  /// Rotation du cube entier (notation) correspondant au geste.
  final String rotation;

  /// Couleur du centre montré à la caméra.
  final CubeColor center;

  /// Couleur du centre qui doit être en haut.
  final CubeColor top;

  /// facelets[k] = facette (orientation de référence) vue dans la case k
  /// de la grille caméra (lue ligne par ligne, en haut à gauche d'abord).
  final List<int> facelets;
}

/// Les 6 étapes du scan, calculées en simulant les rotations du cube.
final List<ScanStep> scanPlan = () {
  const gestures = [
    (ScanGesture.start, "x' z2"),
    (ScanGesture.rollTowardYou, "x'"),
    (ScanGesture.rollTowardYou, "x'"),
    (ScanGesture.rollTowardYou, "x'"),
    (ScanGesture.turnLeft, 'y'),
    (ScanGesture.turnLeftTwice, 'y2'),
  ];
  // label[i] = facette d'origine qui se trouve maintenant en position i.
  var label = List<int>.generate(54, (i) => i);
  var cube = Cube.solved();
  final steps = <ScanStep>[];
  for (final (g, rot) in gestures) {
    for (final m in parseMoves(rot)) {
      final p = movePermutation(m);
      final next = List<int>.filled(54, 0);
      for (var i = 0; i < 54; i++) {
        next[p[i]] = label[i];
      }
      label = next;
    }
    cube = cube.apply(rot);
    steps.add(
      ScanStep(g, rot, cube.center(Face.f), cube.center(Face.u), [
        for (var k = 0; k < 9; k++) label[Face.f.index * 9 + k],
      ]),
    );
  }
  return List<ScanStep>.unmodifiable(steps);
}();

/// Assemble les 6 grilles scannées (9 valeurs chacune, dans l'ordre du
/// plan) en 54 valeurs dans l'ordre des facettes.
List<T> assembleScan<T>(List<List<T>> faces) {
  final out = List<T?>.filled(54, null);
  for (var s = 0; s < 6; s++) {
    for (var k = 0; k < 9; k++) {
      out[scanPlan[s].facelets[k]] = faces[s][k];
    }
  }
  return [for (final x in out) x as T];
}

/// Grille 3 × 3 tournée d'un quart de tour (sens horaire) [turns] fois.
List<T> rotateGrid<T>(List<T> g, int turns) {
  var out = g;
  for (var t = 0; t < turns % 4; t++) {
    // Nouvelle case (r, c) = ancienne case (2 - c, r).
    out = [
      for (var r = 0; r < 3; r++)
        for (var c = 0; c < 3; c++) out[(2 - c) * 3 + r],
    ];
  }
  return out;
}

/// Le cube scanné est impossible ? C'est très souvent une face montrée
/// tournée (geste fait autrement que demandé, ou caméra de la tablette
/// orientée différemment) : les couleurs sont justes mais pas dans le bon
/// sens. On essaie de tourner les faces (le moins possible) jusqu'à
/// obtenir un cube possible. Renvoie les 54 couleurs corrigées, ou null.
List<CubeColor>? fixScanOrientation(
  List<CubeColor> colors,
  bool Function(List<CubeColor>) isValid,
) {
  if (isValid(colors)) return colors;
  final grids = [
    for (final s in scanPlan) [for (final i in s.facelets) colors[i]],
  ];
  List<CubeColor> build(List<int> turns) => assembleScan([
    for (var s = 0; s < 6; s++) rotateGrid(grids[s], turns[s]),
  ]);

  // 1. Toutes les faces tournées pareil (caméra orientée autrement).
  for (final t in [1, 2, 3]) {
    final c = build(List.filled(6, t));
    if (isValid(c)) return c;
  }
  // 2. Le moins de faces tournées possible.
  List<CubeColor>? best;
  var bestCount = 99;
  for (var code = 1; code < 4096; code++) {
    final turns = [for (var s = 0; s < 6; s++) (code >> (2 * s)) & 3];
    final count = turns.where((t) => t != 0).length;
    if (count >= bestCount) continue;
    final c = build(turns);
    if (isValid(c)) {
      best = c;
      bestCount = count;
      if (count == 1) break;
    }
  }
  return best;
}

/// Deux couleurs faciles à confondre sous une lampe (rouge/orange,
/// blanc/jaune) échangées entre deux cases : on cherche l'UNIQUE échange
/// qui rend le cube possible (en commençant par les cases douteuses).
/// Renvoie les couleurs corrigées et les deux cases changées, ou null.
({List<CubeColor> colors, Set<int> changed})? fixConfusedPair(
  List<CubeColor> colors,
  bool Function(List<CubeColor>) isValid, {
  Set<int> doubtful = const {},
}) {
  const pairs = [
    (CubeColor.red, CubeColor.orange),
    (CubeColor.white, CubeColor.yellow),
  ];
  final found = <(int, int)>[];
  for (final (a, b) in pairs) {
    for (var i = 0; i < 54; i++) {
      if (i % 9 == 4 || colors[i] != a) continue;
      for (var j = 0; j < 54; j++) {
        if (j % 9 == 4 || colors[j] != b) continue;
        final c = [...colors];
        c[i] = b;
        c[j] = a;
        if (isValid(c)) found.add((i, j));
      }
    }
  }
  if (found.isEmpty) return null;
  // Plusieurs possibilités : on ne garde que celles sur des cases douteuses.
  final sure = found.length == 1
      ? found
      : found
            .where((p) => doubtful.contains(p.$1) && doubtful.contains(p.$2))
            .toList();
  if (sure.length != 1) return null;
  final (i, j) = sure.single;
  final c = [...colors];
  final tmp = c[i];
  c[i] = c[j];
  c[j] = tmp;
  return (colors: c, changed: {i, j});
}
