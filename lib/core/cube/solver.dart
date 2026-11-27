// Solveur « méthode débutant » : résout le cube EXACTEMENT avec la méthode
// apprise par l'enfant (8 étapes), pour pouvoir le guider coup par coup.
// Ce n'est volontairement PAS un solveur optimal (type Kociemba).
//
// Le cube doit être donné tenu dans l'orientation de référence
// (centre blanc en haut, centre vert devant).
import 'dart:typed_data';

import '../method/method.dart';
import 'cube.dart';
import 'cubies.dart';

/// Nature d'une action, pour choisir la bonne illustration.
enum ActionType {
  /// Tourner tout le cube dans les mains (x2, y…) : rien ne se dérègle.
  rotateCube,

  /// Tourner une seule ligne/colonne/face pour préparer (U, D, F2…).
  turnLayer,

  /// Faire un algorithme à surnom, éventuellement plusieurs fois.
  algorithm,
}

/// Pourquoi on fait cette action (sert à choisir la phrase pour l'enfant).
enum SolveHint {
  retournerJauneEnHaut,
  petale,
  petaleAuDessusDeSaCouleur,
  petaleDevant,
  petaleDescend,
  retournerBlancEnHaut,
  arretesAligner,
  faceAreteNonAlignee,
  escargot,
  coinCibleDevantDroite,
  coinSousSaPlace,
  petiteDanseCoinBlanc,
  sortirCoinBlanc,
  tournerCoinBlancEnPlace,
  retournerBlancEnBas,
  faireTAlEnvers,
  tDevant,
  tobogganDroit,
  tobogganGauche,
  areteMalPlaceeDevantDroite,
  sortirArete,
  placerMotifJaune,
  etoileJaune,
  coinBienPlaceEnHautADroite,
  manege,
  amenerCoinJaune,
  petiteDanseCoinJaune,
  alignerDernierePlace,

  /// Pas d'explication (gestes de base, chemin le plus court).
  aucune,
}

/// Une action à faire par l'enfant.
class SolveAction {
  const SolveAction({
    required this.step,
    required this.type,
    required this.moves,
    required this.hint,
    this.repetitions = 1,
    this.algorithm,
  });

  final MethodStep step;
  final ActionType type;

  /// Les mouvements d'UNE répétition.
  final List<Move> moves;

  /// Nombre de fois à faire [moves] (ex. « la petite danse 3 fois »).
  final int repetitions;

  /// Algorithme à surnom utilisé, s'il y en a un.
  final Algorithm? algorithm;

  final SolveHint hint;

  /// Tous les mouvements, répétitions comprises.
  List<Move> get allMoves => [for (var i = 0; i < repetitions; i++) ...moves];

  @override
  String toString() =>
      '${step.name}/${hint.name}: ${formatMoves(moves)}'
      '${repetitions > 1 ? ' ×$repetitions' : ''}';
}

/// Une étape de la méthode avec ses actions (vide si déjà faite).
class SolveStep {
  const SolveStep(this.step, this.actions);
  final MethodStep step;
  final List<SolveAction> actions;
}

class Solution {
  const Solution(this.steps);
  final List<SolveStep> steps;

  List<SolveAction> get actions => [for (final s in steps) ...s.actions];
  List<Move> get allMoves => [for (final a in actions) ...a.allMoves];
}

class SolverException implements Exception {
  SolverException(this.message);
  final String message;
  @override
  String toString() => 'SolverException: $message';
}

/// Résout [start] avec la méthode débutant.
Solution solveBeginner(Cube start) => _BeginnerSolver(start).solve();

/// Résout seulement les étapes de [from] à [to] (incluses). Le cube doit
/// être tenu comme la méthode le prévoit à cette étape (blanc en haut
/// jusqu'à l'étape 3, jaune en haut à partir de l'étape 5) et les étapes
/// précédentes doivent être faites. Lève [SolverException] sinon.
Solution solveSteps(Cube start, {required MethodStep from, MethodStep? to}) =>
    _BeginnerSolver(start)
        .solve(from: from, to: to ?? MethodStep.tournerCoinsJaunes);

class _BeginnerSolver {
  _BeginnerSolver(this._cube);

  Cube _cube;
  final _steps = <SolveStep>[];
  List<SolveAction> _current = [];
  late MethodStep _step;

  Solution solve({
    MethodStep from = MethodStep.croixBlanche,
    MethodStep to = MethodStep.tournerCoinsJaunes,
  }) {
    _from = from;
    _to = to;
    _run(MethodStep.croixBlanche, _croixBlanche);
    _run(MethodStep.aretesCroix, () => _alignerAretesDuHaut());
    _run(MethodStep.coinsBlancs, _coinsBlancs);
    _run(MethodStep.retourner, () {
      _rotate('x2', SolveHint.retournerBlancEnBas);
    });
    _run(MethodStep.deuxiemeCouronne, _deuxiemeCouronne);
    _run(MethodStep.etoileJaune, _etoileJaune);
    _run(MethodStep.aretesJaunes, () => _alignerAretesDuHaut());
    _run(MethodStep.placerCoinsJaunes, _placerCoinsJaunes);
    _run(MethodStep.tournerCoinsJaunes, _tournerCoinsJaunes);
    return Solution(List.unmodifiable(_steps));
  }

  late MethodStep _from, _to;

  void _run(MethodStep step, void Function() body) {
    if (step.index < _from.index || step.index > _to.index) return;
    _step = step;
    _current = [];
    body();
    if (!isStepDone(step, _cube)) {
      throw SolverException('Étape ${step.name} non terminée : $_cube');
    }
    _steps.add(SolveStep(step, List.unmodifiable(_current)));
  }

  // --- Outils pour enregistrer les actions -------------------------------

  void _record(
    ActionType type,
    List<Move> moves,
    SolveHint hint, {
    int repetitions = 1,
    Algorithm? algorithm,
  }) {
    if (moves.isEmpty || repetitions == 0) return;
    final action = SolveAction(
      step: _step,
      type: type,
      moves: moves,
      hint: hint,
      repetitions: repetitions,
      algorithm: algorithm,
    );
    _cube = _cube.apply(action.allMoves);
    _current.add(action);
  }

  void _rotate(String notation, SolveHint hint) =>
      _record(ActionType.rotateCube, parseMoves(notation), hint);

  void _turn(List<Move> moves, SolveHint hint) =>
      _record(ActionType.turnLayer, moves, hint);

  void _algo(Algorithm a, SolveHint hint, {int times = 1}) => _record(
    ActionType.algorithm,
    a.moves,
    hint,
    repetitions: times,
    algorithm: a,
  );

  /// Mouvement de [kind] répété [quarter] fois (0 à 3), ou rien.
  static List<Move> _q(MoveKind kind, int quarter) =>
      quarter % 4 == 0 ? const [] : [Move(kind, quarter % 4)];

  /// Plus petit nombre de quarts de tour de [kind] qui rend [test] vrai.
  int? _findTurns(MoveKind kind, bool Function(Cube c) test) {
    var c = _cube;
    for (var q = 0; q < 4; q++) {
      if (test(c)) return q;
      c = c.move(Move(kind));
    }
    return null;
  }

  // --- Étape 1 : marguerite puis croix blanche ---------------------------

  void _croixBlanche() {
    if (isWhiteCrossFormed(_cube)) return; // déjà faite : on passe
    _rotate('x2', SolveHint.retournerJauneEnHaut); // jaune en haut

    // a) La marguerite : un pétale à la fois.
    var guard = 0;
    while (!isDaisy(_cube)) {
      if (++guard > 8) throw SolverException('Marguerite impossible');
      final seq = _chercherPetale();
      final rot = seq.where((m) => m.kind.isRotation).toList();
      final rest = seq.where((m) => !m.kind.isRotation).toList();
      _record(ActionType.rotateCube, rot, SolveHint.petale);
      _turn(rest, SolveHint.petale);
    }

    // b) Chaque pétale au-dessus de son centre, puis 2 fois la face.
    for (var k = 0; k < 4; k++) {
      final q = _findTurns(MoveKind.u, (c) => _petaleAligne(c) != null)!;
      _turn(_q(MoveKind.u, q), SolveHint.petaleAuDessusDeSaCouleur);
      final face = _petaleAligne(_cube)!;
      final y = const {Face.f: 0, Face.r: 1, Face.b: 2, Face.l: 3}[face]!;
      _record(ActionType.rotateCube, _q(MoveKind.y, y), SolveHint.petaleDevant);
      _turn([const Move(MoveKind.f, 2)], SolveHint.petaleDescend);
    }

    _rotate('x2', SolveHint.retournerBlancEnHaut); // croix blanche en haut
  }

  /// Face (F, R, B, L) d'un pétale blanc au-dessus de son centre, ou null.
  static Face? _petaleAligne(Cube c) {
    const tops = {
      Face.b: (1, 46),
      Face.l: (3, 37),
      Face.r: (5, 10),
      Face.f: (7, 19),
    };
    for (final e in tops.entries) {
      final (top, side) = e.value;
      if (c[top] == CubeColor.white && c[side] == c.center(e.key)) return e.key;
    }
    return null;
  }

  static final _petaleMoves = parseMoves(
    "U U' U2 D D' D2 R R' R2 L L' L2 F F' F2",
  );
  static final _yRotations = [
    <Move>[],
    ...[
      for (final t in ['y', 'y2', "y'"]) parseMoves(t),
    ],
  ];
  static final Map<Move, Uint8List> _perm = {
    for (final m in [..._petaleMoves, ...parseMoves("y y2 y'")])
      m: movePermutation(m),
  };
  static const _petalSpots = {1, 3, 5, 7};

  /// Cherche la plus courte suite qui ajoute un pétale sans en perdre un.
  /// On ne suit que les 4 autocollants blancs des arêtes blanches : rapide.
  List<Move> _chercherPetale() {
    final white = <int>[];
    for (final e in edgeFacelets) {
      for (final i in e) {
        if (_cube[i] == CubeColor.white) white.add(i);
      }
    }
    final before = white.where(_petalSpots.contains).length;

    for (var depth = 1; depth <= 5; depth++) {
      for (final rot in _yRotations) {
        var start = white;
        for (final m in rot) {
          start = [for (final i in start) _perm[m]![i]];
        }
        final path = <Move>[];
        if (_dfs(start, before, depth, path, null)) return [...rot, ...path];
      }
    }
    throw SolverException('Pétale introuvable');
  }

  bool _dfs(
    List<int> st,
    int before,
    int depth,
    List<Move> path,
    MoveKind? last,
  ) {
    if (depth == 0) {
      // Objectif : au moins un pétale de plus qu'avant (on progresse
      // toujours, donc la marguerite se termine en 4 recherches au plus).
      return st.where(_petalSpots.contains).length > before;
    }
    for (final m in _petaleMoves) {
      if (m.kind == last) continue;
      final p = _perm[m]!;
      path.add(m);
      if (_dfs([for (final i in st) p[i]], before, depth - 1, path, m.kind)) {
        return true;
      }
      path.removeLast();
    }
    return false;
  }

  // --- Étapes 2 et 7 : arêtes du haut dans l'ordre (l'escargot) ----------

  static const _topEdges = {
    Face.b: (1, 46),
    Face.l: (3, 37),
    Face.r: (5, 10),
    Face.f: (7, 19),
  };

  static Set<Face> _alignees(Cube c) => {
    for (final e in _topEdges.entries)
      if (c[e.value.$2] == c.center(e.key)) e.key,
  };

  void _alignerAretesDuHaut() {
    for (var guard = 0; guard < 6; guard++) {
      // Tourner la ligne du haut pour aligner le plus d'arêtes possible.
      var best = 0, bestCount = -1;
      var c = _cube;
      for (var q = 0; q < 4; q++) {
        final n = _alignees(c).length;
        if (n > bestCount) {
          best = q;
          bestCount = n;
        }
        c = c.move(const Move(MoveKind.u));
      }
      _turn(_q(MoveKind.u, best), SolveHint.arretesAligner);
      if (bestCount == 4) return;

      // Se placer face à une arête non alignée, celle de droite alignée.
      final y = _findTurns(MoveKind.y, (c) {
        final a = _alignees(c);
        return !a.contains(Face.f) && a.contains(Face.r);
      })!;
      _record(
        ActionType.rotateCube,
        _q(MoveKind.y, y),
        SolveHint.faceAreteNonAlignee,
      );
      _algo(Algorithm.escargot, SolveHint.escargot);
    }
    throw SolverException('Escargot : arêtes non alignées');
  }

  // --- Étape 3 : les coins blancs (la petite danse) ----------------------

  static const _urf = 0, _dfr = 4;

  void _coinsBlancs() {
    for (var guard = 0; guard < 12; guard++) {
      if (isFirstLayerDone(_cube)) return;

      // Un coin blanc dans la ligne du bas ?
      final bas = [
        4,
        5,
        6,
        7,
      ].where((s) => cornerFacelets[s].any((i) => _cube[i] == CubeColor.white));
      if (bas.isNotEmpty) {
        final colors = {for (final i in cornerFacelets[bas.first]) _cube[i]};
        // Tourner le cube pour que la place du coin soit en haut à droite.
        final y = _findTurns(MoveKind.y, (c) {
          final centers = {
            for (final i in cornerFacelets[_urf]) c.center(Face.values[i ~/ 9]),
          };
          return centers.containsAll(colors);
        })!;
        _record(
          ActionType.rotateCube,
          _q(MoveKind.y, y),
          SolveHint.coinCibleDevantDroite,
        );
        // Amener le coin juste en dessous (ligne du bas).
        final d = _findTurns(MoveKind.d, (c) {
          return {for (final i in cornerFacelets[_dfr]) c[i]}
              .containsAll(colors);
        })!;
        _turn(_q(MoveKind.d, d), SolveHint.coinSousSaPlace);
        // 1× si blanc à droite, 3× si dessous, 5× si devant.
        final facing = switch (Face.values[cornerFacelets[_dfr].firstWhere(
              (i) => _cube[i] == CubeColor.white,
            ) ~/
            9]) {
          Face.r => WhiteCornerFacing.droite,
          Face.d => WhiteCornerFacing.dessous,
          _ => WhiteCornerFacing.devant,
        };
        _algo(
          Algorithm.petiteDanse,
          SolveHint.petiteDanseCoinBlanc,
          times: facing.danses,
        );
        continue;
      }

      // Sinon, un coin blanc en haut est mal placé ou mal tourné.
      final y = _findTurns(MoveKind.y, (c) {
        final f = cornerFacelets[_urf];
        return !f.every((i) => c[i] == c.center(Face.values[i ~/ 9]));
      })!;
      _record(
        ActionType.rotateCube,
        _q(MoveKind.y, y),
        SolveHint.sortirCoinBlanc,
      );
      if (isCornerPlaced(_cube, cornerFacelets[_urf])) {
        // Bonne place mais mal tourné : la petite danse jusqu'au blanc en haut.
        var c = _cube, n = 0;
        while (!isFirstLayerDoneAt(c)) {
          c = c.apply(Algorithm.petiteDanse.moves);
          n++;
          if (n > 6) throw SolverException('Coin blanc bloqué');
        }
        _algo(
          Algorithm.petiteDanse,
          SolveHint.tournerCoinBlancEnPlace,
          times: n,
        );
      } else {
        // Mauvaise place : une petite danse le fait descendre.
        _algo(Algorithm.petiteDanse, SolveHint.sortirCoinBlanc);
      }
    }
    throw SolverException('Coins blancs non terminés');
  }

  static bool isFirstLayerDoneAt(Cube c) =>
      cornerFacelets[_urf].every((i) => c[i] == c.center(Face.values[i ~/ 9]));

  // --- Étape 5 : la 2ᵉ couronne (les toboggans) --------------------------

  static const _middleEdges = [8, 9, 10, 11]; // FR FL BL BR

  void _deuxiemeCouronne() {
    for (var guard = 0; guard < 16; guard++) {
      if (isSecondLayerDone(_cube)) return;
      final yellow = _cube.center(Face.u);

      bool sansJaune(Cube c, int slot) =>
          edgeFacelets[slot].every((i) => c[i] != yellow);

      // Chercher un « T à l'envers » : arête du haut sans jaune dont la
      // couleur de côté est au-dessus de son centre.
      int? quarter;
      for (var q = 0; q < 4 && quarter == null; q++) {
        var c = _cube;
        for (var k = 0; k < q; k++) {
          c = c.move(const Move(MoveKind.u));
        }
        for (final slot in [0, 1, 2, 3]) {
          final side = edgeFacelets[slot][1];
          if (sansJaune(c, slot) &&
              c[side] == c.center(Face.values[side ~/ 9])) {
            quarter = q;
            break;
          }
        }
      }

      if (quarter != null) {
        _turn(_q(MoveKind.u, quarter), SolveHint.faireTAlEnvers);
        final y = _findTurns(
          MoveKind.y,
          (c) => sansJaune(c, 1) && c[19] == c.center(Face.f),
        )!;
        _record(ActionType.rotateCube, _q(MoveKind.y, y), SolveHint.tDevant);
        if (_cube[7] == _cube.center(Face.r)) {
          _algo(Algorithm.tobogganDroit, SolveHint.tobogganDroit);
        } else {
          _algo(Algorithm.tobogganGauche, SolveHint.tobogganGauche);
        }
        continue;
      }

      // Aucune arête utilisable en haut : une arête du milieu est mal placée,
      // on la fait remonter avec un toboggan.
      final y = _findTurns(MoveKind.y, (c) {
        return !edgeFacelets[_middleEdges[0]].every(
          (i) => c[i] == c.center(Face.values[i ~/ 9]),
        );
      })!;
      _record(
        ActionType.rotateCube,
        _q(MoveKind.y, y),
        SolveHint.areteMalPlaceeDevantDroite,
      );
      _algo(Algorithm.tobogganDroit, SolveHint.sortirArete);
    }
    throw SolverException('2e couronne non terminée');
  }

  // --- Étape 6 : l'étoile jaune -------------------------------------------

  void _etoileJaune() {
    for (var guard = 0; guard < 8; guard++) {
      switch (yellowPattern(_cube)) {
        case YellowPattern.croix:
          return;
        case YellowPattern.lAilleurs || YellowPattern.ligneHorizontale:
          final q = _findTurns(MoveKind.u, (c) {
            final p = yellowPattern(c);
            return p == YellowPattern.lHautGauche ||
                p == YellowPattern.ligneVerticale;
          })!;
          _turn(_q(MoveKind.u, q), SolveHint.placerMotifJaune);
        case YellowPattern.point ||
            YellowPattern.lHautGauche ||
            YellowPattern.ligneVerticale:
          _algo(Algorithm.etoileJaune, SolveHint.etoileJaune);
      }
    }
    throw SolverException('Étoile jaune non terminée');
  }

  // --- Étape 8a : placer les coins jaunes (le manège) -------------------

  void _placerCoinsJaunes() {
    for (var guard = 0; guard < 6; guard++) {
      final placed = [
        0,
        1,
        2,
        3,
      ].where((s) => isCornerPlaced(_cube, cornerFacelets[s]));
      if (placed.length == 4) return;
      if (placed.isNotEmpty) {
        final y = _findTurns(
          MoveKind.y,
          (c) => isCornerPlaced(c, cornerFacelets[_urf]),
        )!;
        _record(
          ActionType.rotateCube,
          _q(MoveKind.y, y),
          SolveHint.coinBienPlaceEnHautADroite,
        );
      }
      _algo(Algorithm.manege, SolveHint.manege);
    }
    throw SolverException('Coins jaunes non placés');
  }

  // --- Étape 8b : tourner les coins jaunes (la petite danse) -------------

  void _tournerCoinsJaunes() {
    final yellow = _cube.center(Face.u);
    for (var guard = 0; guard < 6; guard++) {
      // Coins du haut dont le jaune n'est pas sur le dessus.
      final todo = [
        0,
        1,
        2,
        3,
      ].where((s) => _cube[cornerFacelets[s][0]] != yellow).toList();
      if (todo.isEmpty) break;
      // Amener le plus proche en haut à droite en tournant SEULEMENT le haut.
      final q = _findTurns(MoveKind.u, (c) => c[8] != yellow)!;
      _turn(_q(MoveKind.u, q), SolveHint.amenerCoinJaune);
      var c = _cube, n = 0;
      while (c[8] != yellow) {
        c = c.apply(Algorithm.petiteDanse.moves);
        n++;
      }
      _algo(Algorithm.petiteDanse, SolveHint.petiteDanseCoinJaune, times: n);
    }
    final q = _findTurns(MoveKind.u, (c) => c.isSolved);
    if (q == null) throw SolverException('Coins jaunes : cube non résolu');
    _turn(_q(MoveKind.u, q), SolveHint.alignerDernierePlace);
  }
}
