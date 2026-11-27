// Lecture du cube par « petits cubes » (coins et arêtes).
// Sert à la validation d'un cube saisi et aux tests d'étapes.
import 'cube.dart';

/// Facettes de chaque emplacement de coin, dans l'ordre horaire en partant
/// de la facette U ou D. Ordre des coins : URF UFL ULB UBR DFR DLF DBL DRB.
const cornerFacelets = <List<int>>[
  [8, 9, 20], // URF
  [6, 18, 38], // UFL
  [0, 36, 47], // ULB
  [2, 45, 11], // UBR
  [29, 26, 15], // DFR
  [27, 44, 24], // DLF
  [33, 53, 42], // DBL
  [35, 17, 51], // DRB
];

/// Facettes de chaque emplacement d'arête (la 1ʳᵉ est la facette de
/// référence pour l'orientation). Ordre : UR UF UL UB DR DF DL DB FR FL BL BR.
const edgeFacelets = <List<int>>[
  [5, 10], // UR
  [7, 19], // UF
  [3, 37], // UL
  [1, 46], // UB
  [32, 16], // DR
  [28, 25], // DF
  [30, 43], // DL
  [34, 52], // DB
  [23, 12], // FR
  [21, 41], // FL
  [50, 39], // BL
  [48, 14], // BR
];

/// Faces de chaque coin et de chaque arête, dans le même ordre que les
/// facettes ci-dessus (le cube résolu a la pièce n dans l'emplacement n).
List<Face> _facesOf(List<int> facelets) => [
  for (final i in facelets) Face.values[i ~/ 9],
];

final cornerFaces = [for (final c in cornerFacelets) _facesOf(c)];
final edgeFaces = [for (final e in edgeFacelets) _facesOf(e)];

/// Vue « petits cubes » : pour chaque emplacement, quelle pièce s'y trouve et
/// comment elle est tournée. Les faces sont déduites des couleurs des
/// centres, donc ça marche quelle que soit l'orientation du cube.
///
/// Une valeur -1 dans [cornerPerm] ou [edgePerm] signifie : ces couleurs ne
/// correspondent à aucune pièce réelle.
class CubieView {
  CubieView._(this.cornerPerm, this.cornerOri, this.edgePerm, this.edgeOri);

  factory CubieView.of(Cube cube) {
    // Couleur → face, d'après les centres.
    final faceOfColor = <CubeColor, Face>{
      for (final f in Face.values) cube.center(f): f,
    };
    Face? faceAt(int i) => faceOfColor[cube[i]];

    final cp = List.filled(8, -1), co = List.filled(8, 0);
    for (var slot = 0; slot < 8; slot++) {
      final faces = [for (final i in cornerFacelets[slot]) faceAt(i)];
      for (var piece = 0; piece < 8 && cp[slot] < 0; piece++) {
        for (var ori = 0; ori < 3; ori++) {
          // La facette U/D de la pièce se trouve en position « ori ».
          if (faces[ori] == cornerFaces[piece][0] &&
              faces[(ori + 1) % 3] == cornerFaces[piece][1] &&
              faces[(ori + 2) % 3] == cornerFaces[piece][2]) {
            cp[slot] = piece;
            co[slot] = ori;
            break;
          }
        }
      }
    }

    final ep = List.filled(12, -1), eo = List.filled(12, 0);
    for (var slot = 0; slot < 12; slot++) {
      final a = faceAt(edgeFacelets[slot][0]);
      final b = faceAt(edgeFacelets[slot][1]);
      for (var piece = 0; piece < 12; piece++) {
        if (a == edgeFaces[piece][0] && b == edgeFaces[piece][1]) {
          ep[slot] = piece;
          eo[slot] = 0;
          break;
        }
        if (a == edgeFaces[piece][1] && b == edgeFaces[piece][0]) {
          ep[slot] = piece;
          eo[slot] = 1;
          break;
        }
      }
    }
    return CubieView._(cp, co, ep, eo);
  }

  final List<int> cornerPerm;
  final List<int> cornerOri;
  final List<int> edgePerm;
  final List<int> edgeOri;

  /// Coin bien placé ET bien orienté.
  bool cornerSolved(int slot) =>
      cornerPerm[slot] == slot && cornerOri[slot] == 0;

  /// Arête bien placée ET bien orientée.
  bool edgeSolved(int slot) => edgePerm[slot] == slot && edgeOri[slot] == 0;
}

/// Parité d'une permutation (0 = paire, 1 = impaire).
int permutationParity(List<int> perm) {
  var parity = 0;
  final seen = List.filled(perm.length, false);
  for (var i = 0; i < perm.length; i++) {
    if (seen[i]) continue;
    var len = 0;
    for (var j = i; !seen[j]; j = perm[j]) {
      seen[j] = true;
      len++;
    }
    parity ^= (len - 1) & 1;
  }
  return parity;
}
