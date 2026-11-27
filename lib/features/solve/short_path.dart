// « Le plus court » : la solution du solveur rapide, traduite en cartes
// pour un enfant. La face arrière n'est jamais tournée directement : on
// fait d'abord tourner le cube (carte « Tiens ton cube comme ça ») pour
// qu'elle passe à droite. Une vérification tous les 4 gestes.
import '../../core/cube/cube.dart';
import '../../core/cube/solver.dart';
import '../../core/method/method.dart';
import '../guide/guide_cards.dart';

/// Les gestes « enfant » : rotations du cube entier (y) insérées pour éviter
/// la face arrière. Renvoie la suite d'actions (rotations et gestes).
List<SolveAction> kidActions(List<Move> solution) {
  const faces = [
    MoveKind.u,
    MoveKind.r,
    MoveKind.f,
    MoveKind.d,
    MoveKind.l,
    MoveKind.b,
  ];
  final rotations = <Move>[];
  // Où se trouve maintenant chaque face d'origine (repérée par son centre).
  MoveKind where(MoveKind original) {
    final tracker = Cube.solved().apply(rotations);
    final color = Cube.solved().center(Face.values[faces.indexOf(original)]);
    final f = Face.values.firstWhere((f) => tracker.center(f) == color);
    return faces[f.index];
  }

  final out = <SolveAction>[];
  var group = <Move>[];
  void flush() {
    if (group.isEmpty) return;
    out.add(
      SolveAction(
        step: MethodStep.croixBlanche,
        type: ActionType.turnLayer,
        moves: group,
        hint: SolveHint.aucune,
      ),
    );
    group = <Move>[];
  }

  for (final m in solution) {
    var k = where(m.kind);
    if (k == MoveKind.b) {
      flush();
      const y = Move(MoveKind.y);
      rotations.add(y);
      out.add(
        const SolveAction(
          step: MethodStep.croixBlanche,
          type: ActionType.rotateCube,
          moves: [y],
          hint: SolveHint.aucune,
        ),
      );
      k = where(m.kind);
    }
    group.add(Move(k, m.turns));
    if (group.length == 4) flush();
  }
  flush();
  return out;
}

/// Cartes du chemin court : position de départ, gestes par groupes de 4,
/// « Ton cube ressemble à ça ? » après chaque groupe.
List<GuideCard> buildShortCards(Cube start, List<Move> solution) {
  const hold = SolveAction(
    step: MethodStep.croixBlanche,
    type: ActionType.rotateCube,
    moves: [],
    hint: SolveHint.aucune,
  );
  final cards = <GuideCard>[PlaceCard(start, hold, const [])];
  var cube = start;
  for (final a in kidActions(solution)) {
    if (a.type == ActionType.rotateCube) {
      cards.add(PlaceCard(cube, a, a.moves));
      cube = cube.apply(a.moves);
      continue;
    }
    for (var k = 0; k < a.moves.length; k++) {
      final card = GestureCard(
        cube,
        a,
        move: a.moves[k],
        chunk: a.moves,
        indexInChunk: k,
        chunkIndex: 0,
        chunkCount: 1,
        repetition: 1,
      );
      cards.add(card);
      cube = card.after;
    }
    cards.add(CheckCard(cube, a));
  }
  return cards;
}

/// Nombre de gestes d'une suite (sans les rotations du cube entier).
int gestureCount(List<Move> moves) => moves
    .where(
      (m) =>
          m.kind != MoveKind.x && m.kind != MoveKind.y && m.kind != MoveKind.z,
    )
    .length;
