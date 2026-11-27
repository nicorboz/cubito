// Classement des couleurs scannées :
// 1. calibration avec les 6 centres (la vraie couleur du cube de l'enfant
//    sous SA lumière) ;
// 2. chaque case va vers le centre le plus proche (CIELAB) ;
// 3. si ça ne donne pas 9 cases par couleur, affectation globale de coût
//    minimal (algorithme hongrois) qui impose exactement 9 par couleur.
import '../cube/cube.dart';
import 'color_lab.dart';
import 'hungarian.dart';

class ClassificationResult {
  ClassificationResult(this.colors, this.doubtful);

  /// Les 54 couleurs.
  final List<CubeColor> colors;

  /// Cases douteuses (à faire clignoter sur l'écran de vérification).
  final Set<int> doubtful;
}

/// [labs] : les 54 mesures, dans l'ordre des facettes. Les centres (indices
/// 4, 13, 22…) servent de référence, avec la couleur [centerColors].
ClassificationResult classifyColors(
  List<Lab> labs, {
  Map<Face, CubeColor> centerColors = referenceColors,
}) {
  assert(labs.length == 54);
  final colorsOrder = CubeColor.values;
  final stickers = [
    for (var i = 0; i < 54; i++)
      if (i % 9 != 4) i,
  ];

  // Mesure peu sensible aux ombres : une case dans l'ombre garde sa teinte
  // mais devient plus sombre et moins saturée. On ramène donc a et b à une
  // clarté commune, et la clarté ne compte qu'un peu.
  ({double l, double a, double b}) feature(Lab x) {
    final k = 60 / x.l.clamp(15, 100);
    return (l: x.l * 0.35, a: x.a * k, b: x.b * k);
  }

  final feats = [for (final x in labs) feature(x)];
  double dist(
    ({double l, double a, double b}) x,
    ({double l, double a, double b}) y,
  ) {
    final dl = x.l - y.l, da = x.a - y.a, db = x.b - y.b;
    return dl * dl + da * da + db * db;
  }

  // 1. Calibration : la couleur de référence = le centre de chaque face.
  var refs = <CubeColor, ({double l, double a, double b})>{
    for (final f in Face.values) centerColors[f]!: feats[f.index * 9 + 4],
  };

  final result = List<CubeColor>.filled(54, CubeColor.white);
  for (final f in Face.values) {
    result[f.index * 9 + 4] = centerColors[f]!;
  }

  // 2. Plus proche centre (sert aussi à repérer les hésitations).
  final nearest = <int, CubeColor>{};
  final doubtful = <int>{};
  for (final i in stickers) {
    final sorted = [...colorsOrder]
      ..sort(
        (a, b) => dist(feats[i], refs[a]!).compareTo(dist(feats[i], refs[b]!)),
      );
    nearest[i] = sorted[0];
    final d1 = dist(feats[i], refs[sorted[0]]!),
        d2 = dist(feats[i], refs[sorted[1]]!);
    if (d2 < d1 * 1.8) doubtful.add(i);
  }

  // 3. Affectation globale « exactement 9 par couleur » (hongrois), puis
  //    affinage : la référence de chaque couleur devient la moyenne de ses
  //    9 cases, et on recommence (plus fiable qu'un seul centre).
  var assigned = Map<int, CubeColor>.from(nearest);
  for (var round = 0; round < 3; round++) {
    final cost = [
      for (final i in stickers)
        [
          for (final c in colorsOrder)
            for (var k = 0; k < 8; k++) dist(feats[i], refs[c]!),
        ],
    ];
    final assign = hungarian(cost);
    assigned = {
      for (var r = 0; r < stickers.length; r++)
        stickers[r]: colorsOrder[assign[r] ~/ 8],
    };
    refs = {
      for (final c in colorsOrder)
        c: () {
          final members = [
            ...[
              for (final e in assigned.entries)
                if (e.value == c) feats[e.key],
            ],
            for (final f in Face.values)
              if (centerColors[f] == c) feats[f.index * 9 + 4],
          ];
          double avg(double Function(({double l, double a, double b}) m) g) =>
              members.map(g).reduce((x, y) => x + y) / members.length;
          return (l: avg((m) => m.l), a: avg((m) => m.a), b: avg((m) => m.b));
        }(),
    };
  }

  for (final e in assigned.entries) {
    result[e.key] = e.value;
    if (e.value != nearest[e.key]) doubtful.add(e.key); // couleur corrigée
  }
  return ClassificationResult(result, doubtful);
}
