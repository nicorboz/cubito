// Solveur rapide « deux phases » (algorithme de Herbert Kociemba), écrit
// pour l'appli : trouve en général une solution de 19 à 23 coups.
//
// Phase 1 : amener le cube dans le sous-groupe <U, D, R2, L2, F2, B2>
//           (coins et arêtes bien orientés, arêtes du milieu dans la tranche).
// Phase 2 : finir avec seulement ces mouvements.
//
// Les tables (environ 4 Mo) sont calculées au premier appel, de préférence
// dans un isolat (voir [FastSolver.solveInBackground]).
import 'dart:typed_data';

import 'cube.dart';
import 'cubies.dart';
// Calcul en arrière-plan : isolat sur téléphone, « Web Worker » dans le
// navigateur (où les isolats n'existent pas).
import 'solver_background_io.dart'
    if (dart.library.js_interop) 'solver_background_web.dart';

/// Résultat : la suite de mouvements (U R F D L B, ' et 2) qui résout le cube
/// tel qu'il est tenu (les faces sont repérées par les centres).
class FastSolution {
  const FastSolution(this.moves);
  final List<Move> moves;
  int get length => moves.length;
  @override
  String toString() => formatMoves(moves);
}

class FastSolverException implements Exception {
  FastSolverException(this.message);
  final String message;
  @override
  String toString() => 'FastSolverException: $message';
}

// ---------------------------------------------------------------- cubies

class _CubieCube {
  _CubieCube(this.cp, this.co, this.ep, this.eo);

  _CubieCube.solved()
    : cp = List.generate(8, (i) => i),
      co = List.filled(8, 0),
      ep = List.generate(12, (i) => i),
      eo = List.filled(12, 0);

  factory _CubieCube.of(Cube c) {
    final v = CubieView.of(c);
    return _CubieCube(
      [...v.cornerPerm],
      [...v.cornerOri],
      [...v.edgePerm],
      [...v.edgeOri],
    );
  }

  final List<int> cp, co, ep, eo;

  _CubieCube copy() => _CubieCube([...cp], [...co], [...ep], [...eo]);

  /// this ← this * m (on applique le mouvement m).
  void multiply(_CubieCube m) {
    final ncp = List<int>.filled(8, 0), nco = List<int>.filled(8, 0);
    for (var i = 0; i < 8; i++) {
      ncp[i] = cp[m.cp[i]];
      nco[i] = (co[m.cp[i]] + m.co[i]) % 3;
    }
    final nep = List<int>.filled(12, 0), neo = List<int>.filled(12, 0);
    for (var i = 0; i < 12; i++) {
      nep[i] = ep[m.ep[i]];
      neo[i] = (eo[m.ep[i]] + m.eo[i]) % 2;
    }
    cp.setAll(0, ncp);
    co.setAll(0, nco);
    ep.setAll(0, nep);
    eo.setAll(0, neo);
  }

  // --- coordonnées
  int get twist {
    var r = 0;
    for (var i = 0; i < 7; i++) {
      r = r * 3 + co[i];
    }
    return r;
  }

  set twist(int t) {
    var s = 0;
    for (var i = 6; i >= 0; i--) {
      co[i] = t % 3;
      s += co[i];
      t ~/= 3;
    }
    co[7] = (3 - s % 3) % 3;
  }

  int get flip {
    var r = 0;
    for (var i = 0; i < 11; i++) {
      r = r * 2 + eo[i];
    }
    return r;
  }

  set flip(int f) {
    var s = 0;
    for (var i = 10; i >= 0; i--) {
      eo[i] = f % 2;
      s += eo[i];
      f ~/= 2;
    }
    eo[11] = s % 2;
  }

  /// Positions des 4 arêtes de la tranche du milieu (pièces 8 à 11).
  int get slice {
    var r = 0, k = 0;
    for (var pos = 0; pos < 12; pos++) {
      if (ep[pos] >= 8) {
        k++;
        r += _binom(pos, k);
      }
    }
    return r;
  }

  set slice(int s) {
    // Décodage du système combinatoire : on cherche les positions de haut en bas.
    final occupied = List.filled(12, false);
    var k = 4;
    for (var pos = 11; pos >= 0 && k > 0; pos--) {
      final b = _binom(pos, k);
      if (b <= s) {
        s -= b;
        occupied[pos] = true;
        k--;
      }
    }
    var a = 0, b = 8;
    for (var pos = 0; pos < 12; pos++) {
      ep[pos] = occupied[pos] ? b++ : a++;
    }
  }

  int get cornerPerm => _permIndex(cp, 0, 8);
  set cornerPerm(int c) => _permSet(cp, 0, 8, c, 0);

  int get udEdgePerm => _permIndex(ep, 0, 8);
  set udEdgePerm(int c) => _permSet(ep, 0, 8, c, 0);

  int get slicePerm => _permIndex(ep, 8, 4, offset: 8);
  set slicePerm(int c) => _permSet(ep, 8, 4, c, 8);
}

int _parity(List<int> p) {
  var s = 0;
  for (var i = 0; i < p.length; i++) {
    for (var j = i + 1; j < p.length; j++) {
      if (p[j] < p[i]) s++;
    }
  }
  return s % 2;
}

int _binom(int n, int k) {
  if (k < 0 || k > n) return 0;
  var r = 1;
  for (var i = 0; i < k; i++) {
    r = r * (n - i) ~/ (i + 1);
  }
  return r;
}

/// Rang (code de Lehmer) des valeurs list[start..start+n] (valeurs offset..offset+n-1).
int _permIndex(List<int> list, int start, int n, {int offset = 0}) {
  var r = 0;
  for (var i = 0; i < n; i++) {
    var smaller = 0;
    for (var j = i + 1; j < n; j++) {
      if (list[start + j] < list[start + i]) smaller++;
    }
    r = r * (n - i) + smaller;
  }
  return r;
}

void _permSet(List<int> list, int start, int n, int c, int offset) {
  final digits = List<int>.filled(n, 0);
  for (var i = n - 1; i >= 0; i--) {
    digits[i] = c % (n - i);
    c ~/= (n - i);
  }
  final pool = List.generate(n, (i) => i + offset);
  for (var i = 0; i < n; i++) {
    list[start + i] = pool.removeAt(digits[i]);
  }
}

// ---------------------------------------------------------------- tables

const _faces = [
  MoveKind.u,
  MoveKind.r,
  MoveKind.f,
  MoveKind.d,
  MoveKind.l,
  MoveKind.b,
];

/// Mouvements de la phase 2 : U, U2, U', R2, F2, D, D2, D', L2, B2.
const _phase2Moves = [0, 1, 2, 4, 7, 9, 10, 11, 13, 16];

const _nTwist = 2187, _nFlip = 2048, _nSlice = 495;
const _nPerm8 = 40320, _nSlicePerm = 24;

class _Tables {
  _Tables() {
    // Les 6 quarts de tour, lus sur notre propre moteur à facettes.
    final quarter = [
      for (final k in _faces) _CubieCube.of(Cube.solved().move(Move(k))),
    ];
    moveCubes = [
      for (var f = 0; f < 6; f++)
        for (var t = 1; t <= 3; t++)
          () {
            final c = _CubieCube.solved();
            for (var i = 0; i < t; i++) {
              c.multiply(quarter[f]);
            }
            return c;
          }(),
    ];
    final solved = _CubieCube.solved();
    sliceSolved = solved.slice;

    twistMove = _table(_nTwist, 18, (c, v) => c.twist = v, (c) => c.twist);
    flipMove = _table(_nFlip, 18, (c, v) => c.flip = v, (c) => c.flip);
    sliceMove = _table(_nSlice, 18, (c, v) => c.slice = v, (c) => c.slice);
    cornerMove = _table(
      _nPerm8,
      18,
      (c, v) => c.cornerPerm = v,
      (c) => c.cornerPerm,
    );
    udEdgeMove = _table(
      _nPerm8,
      18,
      (c, v) => c.udEdgePerm = v,
      (c) => c.udEdgePerm,
      only: _phase2Moves,
    );
    slicePermMove = _table(
      _nSlicePerm,
      18,
      (c, v) => c.slicePerm = v,
      (c) => c.slicePerm,
      only: _phase2Moves,
    );

    sliceTwistPrun = _prune(
      _nSlice,
      _nTwist,
      sliceMove,
      twistMove,
      List.generate(18, (i) => i),
      sliceSolved,
      0,
    );
    sliceFlipPrun = _prune(
      _nSlice,
      _nFlip,
      sliceMove,
      flipMove,
      List.generate(18, (i) => i),
      sliceSolved,
      0,
    );
    cornerSlicePrun = _prune(
      _nSlicePerm,
      _nPerm8,
      slicePermMove,
      cornerMove,
      _phase2Moves,
      0,
      0,
    );
    edgeSlicePrun = _prune(
      _nSlicePerm,
      _nPerm8,
      slicePermMove,
      udEdgeMove,
      _phase2Moves,
      0,
      0,
    );
  }

  late final List<_CubieCube> moveCubes;
  late final int sliceSolved;
  late final Int32List twistMove, flipMove, sliceMove;
  late final Int32List cornerMove, udEdgeMove, slicePermMove;
  late final Int8List sliceTwistPrun, sliceFlipPrun;
  late final Int8List cornerSlicePrun, edgeSlicePrun;

  Int32List _table(
    int n,
    int m,
    void Function(_CubieCube, int) set,
    int Function(_CubieCube) get, {
    List<int>? only,
  }) {
    final t = Int32List(n * m);
    final moves = only ?? List.generate(m, (i) => i);
    for (var i = 0; i < n; i++) {
      for (final mv in moves) {
        // On repart d'un cube « propre » pour chaque mouvement.
        final x = _CubieCube.solved();
        set(x, i);
        x.multiply(moveCubes[mv]);
        t[i * m + mv] = get(x);
      }
    }
    return t;
  }

  /// Table de distance (largeur d'abord) sur le couple (a, b).
  Int8List _prune(
    int na,
    int nb,
    Int32List moveA,
    Int32List moveB,
    List<int> moves,
    int startA,
    int startB,
  ) {
    final dist = Int8List(na * nb)..fillRange(0, na * nb, -1);
    dist[startA * nb + startB] = 0;
    var frontier = <int>[startA * nb + startB];
    var depth = 0;
    while (frontier.isNotEmpty) {
      final next = <int>[];
      for (final idx in frontier) {
        final a = idx ~/ nb, b = idx % nb;
        for (final mv in moves) {
          final na2 = moveA[a * 18 + mv], nb2 = moveB[b * 18 + mv];
          final j = na2 * nb + nb2;
          if (dist[j] < 0) {
            dist[j] = depth + 1;
            next.add(j);
          }
        }
      }
      frontier = next;
      depth++;
    }
    return dist;
  }
}

_Tables? _tables;

// ---------------------------------------------------------------- recherche

class FastSolver {
  /// Calcule les tables maintenant (sinon au premier appel de [solve]).
  static void warmUp() => _tables ??= _Tables();

  /// Résout [cube]. Cherche une solution de plus en plus courte pendant
  /// [timeLimit] (la première solution arrive en général tout de suite).
  static FastSolution solve(
    Cube cube, {
    int maxLength = 24,
    Duration timeLimit = const Duration(milliseconds: 1500),
  }) {
    final t = _tables ??= _Tables();
    final start = _CubieCube.of(cube);
    if (start.cp.contains(-1) ||
        start.ep.contains(-1) ||
        start.cp.toSet().length != 8 ||
        start.ep.toSet().length != 12 ||
        start.co.fold(0, (a, b) => a + b) % 3 != 0 ||
        start.eo.fold(0, (a, b) => a + b) % 2 != 0 ||
        _parity(start.cp) != _parity(start.ep)) {
      throw FastSolverException('Cube impossible');
    }
    if (cube.isSolved) return const FastSolution([]);
    final search = _Search(t, start, Stopwatch()..start(), timeLimit);
    final best = search.run(maxLength);
    if (best == null) throw FastSolverException('Pas de solution trouvée');
    return FastSolution([
      for (final m in best) Move(_faces[m ~/ 3], m % 3 + 1),
    ]);
  }

  /// Même chose en arrière-plan (l'interface reste fluide).
  static Future<FastSolution> solveInBackground(Cube cube) async {
    final s = await solveStringInBackground(cube.toString());
    return FastSolution(parseMoves(s));
  }
}

/// Cube (texte) → solution (texte). Utilisé par l'isolat et le Web Worker.
String solveCubeString(String cube) =>
    FastSolver.solve(Cube.fromString(cube)).toString();

class _Search {
  _Search(this.t, this.start, this.clock, this.limit);

  final _Tables t;
  final _CubieCube start;
  final Stopwatch clock;
  final Duration limit;

  final _path1 = List<int>.filled(30, 0);
  final _path2 = List<int>.filled(30, 0);
  List<int>? _best;
  int _bestLen = 99;
  bool _timeUp = false;

  List<int>? run(int maxLength) {
    final tw = start.twist, fl = start.flip, sl = start.slice;
    for (var d1 = 0; d1 <= maxLength && !_timeUp; d1++) {
      if (_best != null && d1 >= _bestLen) break;
      _phase1(tw, fl, sl, 0, d1, -1, maxLength);
    }
    return _best;
  }

  int _h1(int tw, int fl, int sl) {
    final a = t.sliceTwistPrun[sl * _nTwist + tw];
    final b = t.sliceFlipPrun[sl * _nFlip + fl];
    return a > b ? a : b;
  }

  /// Évite les suites inutiles : même face deux fois, ou faces opposées
  /// dans le « mauvais » ordre (D puis U = U puis D).
  static bool _skip(int face, int last) {
    if (last < 0) return false;
    if (face == last) return true;
    return face % 3 == last % 3 && face < last;
  }

  void _phase1(
    int tw,
    int fl,
    int sl,
    int depth,
    int target,
    int last,
    int maxLength,
  ) {
    if (_timeUp) return;
    if (depth == target) {
      if (tw == 0 && fl == 0 && sl == t.sliceSolved) {
        // La dernière action de la phase 1 ne doit pas être un mouvement de
        // phase 2 (sinon cette branche a déjà été vue plus courte).
        if (depth > 0 && _phase2Moves.contains(_path1[depth - 1])) return;
        _startPhase2(depth, maxLength);
      }
      return;
    }
    if (_h1(tw, fl, sl) > target - depth) return;
    for (var mv = 0; mv < 18; mv++) {
      final face = mv ~/ 3;
      if (_skip(face, last)) continue;
      _path1[depth] = mv;
      _phase1(
        t.twistMove[tw * 18 + mv],
        t.flipMove[fl * 18 + mv],
        t.sliceMove[sl * 18 + mv],
        depth + 1,
        target,
        face,
        maxLength,
      );
      if (_timeUp) return;
    }
  }

  void _startPhase2(int d1, int maxLength) {
    if (clock.elapsed > limit && _best != null) {
      _timeUp = true;
      return;
    }
    final c = start.copy();
    for (var i = 0; i < d1; i++) {
      c.multiply(t.moveCubes[_path1[i]]);
    }
    final cpc = c.cornerPerm, ude = c.udEdgePerm, spc = c.slicePerm;
    // Phase 2 limitée à 12 coups (au-delà, une autre phase 1 fait mieux).
    final total = (_best == null ? maxLength : _bestLen - 1) - d1;
    final cap = total < 12 ? total : 12;
    final last = d1 > 0 ? _path1[d1 - 1] ~/ 3 : -1;
    for (var d2 = 0; d2 <= cap; d2++) {
      if (_phase2(cpc, ude, spc, 0, d2, last)) {
        _best = [..._path1.sublist(0, d1), ..._path2.sublist(0, d2)];
        _bestLen = d1 + d2;
        return;
      }
    }
  }

  bool _phase2(int cpc, int ude, int spc, int depth, int target, int last) {
    if (depth == target) return cpc == 0 && ude == 0 && spc == 0;
    final h = _max(
      t.cornerSlicePrun[spc * _nPerm8 + cpc],
      t.edgeSlicePrun[spc * _nPerm8 + ude],
    );
    if (h > target - depth) return false;
    for (final mv in _phase2Moves) {
      final face = mv ~/ 3;
      if (_skip(face, last)) continue;
      _path2[depth] = mv;
      if (_phase2(
        t.cornerMove[cpc * 18 + mv],
        t.udEdgeMove[ude * 18 + mv],
        t.slicePermMove[spc * 18 + mv],
        depth + 1,
        target,
        face,
      )) {
        return true;
      }
    }
    return false;
  }

  static int _max(int a, int b) => a > b ? a : b;
}
