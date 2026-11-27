// Modèle du Rubik's Cube par facettes (54 autocollants) et mouvements.
// Dart pur : aucune dépendance à Flutter, pour être testé facilement.
//
// Repère 3D utilisé partout dans l'appli :
//   x vers la DROITE, y vers le HAUT, z vers l'AVANT (vers l'enfant).
//
// Ordre des facettes (convention de Kociemba) : U(0-8) R(9-17) F(18-26)
// D(27-35) L(36-44) B(45-53). Chaque face est lue ligne par ligne, telle
// qu'on la voit sur le patron déplié :
//
//              U0 U1 U2
//              U3 U4 U5
//              U6 U7 U8
//   L0 L1 L2   F0 F1 F2   R0 R1 R2   B0 B1 B2
//   L3 L4 L5   F3 F4 F5   R3 R4 R5   B3 B4 B5
//   L6 L7 L8   F6 F7 F8   R6 R7 R8   B6 B7 B8
//              D0 D1 D2
//              D3 D4 D5
//              D6 D7 D8
import 'dart:math';
import 'dart:typed_data';

/// Les 6 faces, dans l'ordre des facettes.
enum Face { u, r, f, d, l, b }

/// Les 6 couleurs. Orientation de référence : blanc en haut, vert devant,
/// donc rouge à droite, orange à gauche, jaune en bas, bleu derrière.
enum CubeColor { white, red, green, yellow, orange, blue }

/// Couleur de chaque face quand le cube est résolu en orientation de référence.
const referenceColors = <Face, CubeColor>{
  Face.u: CubeColor.white,
  Face.r: CubeColor.red,
  Face.f: CubeColor.green,
  Face.d: CubeColor.yellow,
  Face.l: CubeColor.orange,
  Face.b: CubeColor.blue,
};

/// Vecteur entier 3D (positions et normales des autocollants).
class Vec3 {
  const Vec3(this.x, this.y, this.z);
  final int x, y, z;

  @override
  bool operator ==(Object other) =>
      other is Vec3 && other.x == x && other.y == y && other.z == z;

  @override
  int get hashCode => Object.hash(x, y, z);

  int dot(Vec3 o) => x * o.x + y * o.y + z * o.z;

  /// Rotation d'un quart de tour autour d'un axe (0=x, 1=y, 2=z).
  /// [sign] = +1 : sens inverse des aiguilles d'une montre vu depuis le côté
  /// positif de l'axe ; -1 : sens des aiguilles.
  Vec3 rotate(int axis, int sign) {
    switch (axis) {
      case 0:
        return Vec3(x, -sign * z, sign * y);
      case 1:
        return Vec3(sign * z, y, -sign * x);
      default:
        return Vec3(-sign * y, sign * x, z);
    }
  }

  @override
  String toString() => '($x,$y,$z)';
}

/// Position et normale de chaque autocollant (calculées une fois).
final List<Vec3> stickerPositions = List.unmodifiable(
  List.generate(54, (i) => _stickerGeometry(i).$1),
);
final List<Vec3> stickerNormals = List.unmodifiable(
  List.generate(54, (i) => _stickerGeometry(i).$2),
);

(Vec3, Vec3) _stickerGeometry(int index) {
  final face = Face.values[index ~/ 9];
  final r = (index % 9) ~/ 3;
  final c = index % 3;
  switch (face) {
    case Face.u:
      return (Vec3(c - 1, 1, r - 1), const Vec3(0, 1, 0));
    case Face.r:
      return (Vec3(1, 1 - r, 1 - c), const Vec3(1, 0, 0));
    case Face.f:
      return (Vec3(c - 1, 1 - r, 1), const Vec3(0, 0, 1));
    case Face.d:
      return (Vec3(c - 1, -1, 1 - r), const Vec3(0, -1, 0));
    case Face.l:
      return (Vec3(-1, 1 - r, c - 1), const Vec3(-1, 0, 0));
    case Face.b:
      return (Vec3(1 - c, 1 - r, -1), const Vec3(0, 0, -1));
  }
}

int _indexOf(Vec3 pos, Vec3 normal) {
  for (var i = 0; i < 54; i++) {
    if (stickerPositions[i] == pos && stickerNormals[i] == normal) return i;
  }
  throw StateError('Autocollant introuvable $pos $normal');
}

/// Type de mouvement : une face (U, R…) ou une rotation du cube entier.
enum MoveKind {
  u('U', 1, 1, {1}),
  d('D', 1, -1, {-1}),
  r('R', 0, 1, {1}),
  l('L', 0, -1, {-1}),
  f('F', 2, 1, {1}),
  b('B', 2, -1, {-1}),
  // Rotations du cube entier : x comme R, y comme U, z comme F.
  x('x', 0, 1, {-1, 0, 1}),
  y('y', 1, 1, {-1, 0, 1}),
  z('z', 2, 1, {-1, 0, 1});

  const MoveKind(this.symbol, this.axis, this.direction, this.layers);

  /// Lettre utilisée dans la notation.
  final String symbol;

  /// Axe de rotation (0=x, 1=y, 2=z).
  final int axis;

  /// +1 si la face regarde vers le côté positif de l'axe, -1 sinon.
  final int direction;

  /// Couches (coordonnée le long de l'axe) qui tournent.
  final Set<int> layers;

  bool get isRotation => layers.length == 3;
}

/// Un mouvement : un type + un nombre de quarts de tour horaires (1, 2 ou 3).
/// 3 quarts de tour = un quart de tour antihoraire (noté avec ').
class Move {
  const Move(this.kind, [this.turns = 1]) : assert(turns >= 1 && turns <= 3);

  final MoveKind kind;
  final int turns;

  Move get inverse => Move(kind, 4 - turns);

  /// Lit un mouvement en notation : « R », « U' », « F2 », « x2 », « y' ».
  static Move parse(String token) {
    final t = token.trim().replaceAll('’', "'");
    final kind = MoveKind.values.firstWhere(
      (k) => t.startsWith(k.symbol),
      orElse: () => throw FormatException('Mouvement inconnu : $token'),
    );
    final suffix = t.substring(kind.symbol.length);
    final turns = switch (suffix) {
      '' => 1,
      "'" => 3,
      '2' || "2'" => 2,
      _ => throw FormatException('Mouvement inconnu : $token'),
    };
    return Move(kind, turns);
  }

  @override
  bool operator ==(Object other) =>
      other is Move && other.kind == kind && other.turns == turns;

  @override
  int get hashCode => Object.hash(kind, turns);

  @override
  String toString() =>
      kind.symbol + (turns == 1 ? '' : (turns == 2 ? '2' : "'"));
}

/// Lit une séquence comme « R U R' U' » (espaces libres).
List<Move> parseMoves(String sequence) => sequence
    .split(RegExp(r'\s+'))
    .where((t) => t.isNotEmpty)
    .map(Move.parse)
    .toList();

/// Écrit une séquence en notation.
String formatMoves(Iterable<Move> moves) => moves.join(' ');

/// Inverse une séquence (ordre inversé, chaque mouvement inversé).
List<Move> invertMoves(List<Move> moves) =>
    moves.reversed.map((m) => m.inverse).toList();

/// Permutation d'un quart de tour horaire pour chaque type de mouvement :
/// la facette i part à la position _quarterTurn[kind][i].
final Map<MoveKind, Uint8List> _quarterTurn = {
  for (final kind in MoveKind.values) kind: _buildQuarterTurn(kind),
};

Uint8List _buildQuarterTurn(MoveKind kind) {
  final perm = Uint8List(54);
  // Horaire vu depuis la face = antihoraire vu depuis le côté opposé.
  final sign = -kind.direction;
  for (var i = 0; i < 54; i++) {
    final p = stickerPositions[i];
    final layer = [p.x, p.y, p.z][kind.axis];
    if (kind.layers.contains(layer)) {
      perm[i] = _indexOf(
        p.rotate(kind.axis, sign),
        stickerNormals[i].rotate(kind.axis, sign),
      );
    } else {
      perm[i] = i;
    }
  }
  return perm;
}

/// Permutation complète d'un mouvement : la facette i va en position p[i].
/// (Utilisé par le solveur pour suivre quelques autocollants très vite.)
Uint8List movePermutation(Move m) {
  final q = _quarterTurn[m.kind]!;
  final p = Uint8List.fromList(List.generate(54, (i) => i));
  for (var t = 0; t < m.turns; t++) {
    for (var i = 0; i < 54; i++) {
      p[i] = q[p[i]];
    }
  }
  return p;
}

/// État d'un cube : la couleur de chacun des 54 autocollants.
/// Immuable : chaque mouvement renvoie un nouveau cube.
class Cube {
  Cube._(this._s);

  /// Cube résolu en orientation de référence (blanc haut, vert devant).
  factory Cube.solved() => Cube._(
    Uint8List.fromList([
      for (final face in Face.values)
        for (var k = 0; k < 9; k++) referenceColors[face]!.index,
    ]),
  );

  /// Cube à partir de 54 couleurs (dans l'ordre des facettes).
  factory Cube.fromColors(List<CubeColor> colors) {
    if (colors.length != 54) {
      throw ArgumentError('Il faut 54 couleurs, reçu ${colors.length}');
    }
    return Cube._(Uint8List.fromList(colors.map((c) => c.index).toList()));
  }

  /// Cube à partir d'une chaîne de 54 lettres W R G Y O B.
  factory Cube.fromString(String s) {
    const letters = 'WRGYOB';
    final clean = s.replaceAll(RegExp(r'\s'), '');
    return Cube.fromColors([
      for (final ch in clean.split(''))
        CubeColor.values[!letters.contains(ch)
            ? throw FormatException('Lettre inconnue $ch')
            : letters.indexOf(ch)],
    ]);
  }

  final Uint8List _s;

  CubeColor operator [](int index) => CubeColor.values[_s[index]];

  List<CubeColor> get colors =>
      List.unmodifiable(_s.map((c) => CubeColor.values[c]));

  /// Couleur du centre d'une face.
  CubeColor center(Face face) => this[face.index * 9 + 4];

  /// Applique un mouvement.
  Cube move(Move m) {
    final perm = _quarterTurn[m.kind]!;
    var cur = _s;
    for (var t = 0; t < m.turns; t++) {
      final next = Uint8List(54);
      for (var i = 0; i < 54; i++) {
        next[perm[i]] = cur[i];
      }
      cur = next;
    }
    return Cube._(cur);
  }

  /// Applique une séquence (liste ou chaîne en notation).
  Cube apply(Object moves) {
    final list = moves is String ? parseMoves(moves) : moves as List<Move>;
    var c = this;
    for (final m in list) {
      c = c.move(m);
    }
    return c;
  }

  /// Vrai si chaque face est d'une seule couleur (quelle que soit
  /// l'orientation du cube).
  bool get isSolved {
    for (var f = 0; f < 6; f++) {
      for (var k = 0; k < 9; k++) {
        if (_s[f * 9 + k] != _s[f * 9 + 4]) return false;
      }
    }
    return true;
  }

  @override
  bool operator ==(Object other) {
    if (other is! Cube) return false;
    for (var i = 0; i < 54; i++) {
      if (other._s[i] != _s[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(_s);

  /// Chaîne de 54 lettres W R G Y O B.
  @override
  String toString() => _s.map((c) => 'WRGYOB'[c]).join();
}

/// Mélange aléatoire de [length] coups de faces, sans deux coups consécutifs
/// sur la même face ni sur deux faces opposées qui s'annuleraient (ex. R L R).
List<Move> randomScramble({int length = 25, Random? random}) {
  final rnd = random ?? Random();
  const faces = [
    MoveKind.u,
    MoveKind.d,
    MoveKind.r,
    MoveKind.l,
    MoveKind.f,
    MoveKind.b,
  ];
  final moves = <Move>[];
  while (moves.length < length) {
    final kind = faces[rnd.nextInt(6)];
    if (moves.isNotEmpty) {
      final last = moves.last.kind;
      if (last == kind) continue;
      // Deux faces opposées de suite : imposer un ordre pour éviter R L R.
      if (last.axis == kind.axis && last.index > kind.index) continue;
      if (moves.length >= 2 &&
          moves[moves.length - 2].kind == kind &&
          last.axis == kind.axis) {
        continue;
      }
    }
    moves.add(Move(kind, 1 + rnd.nextInt(3)));
  }
  return moves;
}
