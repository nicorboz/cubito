// Transforme une solution (actions du solveur) en « cartes » façon livret
// LEGO : une image = une seule chose à faire.
//
//  - PlaceCard   : « Tiens ton cube comme ça » (remplace toute rotation du
//                  cube entier : on donne la couleur du haut et de devant) ;
//  - FormulaCard : présentation d'une formule (cartes numérotées, chanson,
//                  nombre de fois) ;
//  - GestureCard : un seul geste (partie violette + flèche) ;
//  - CheckCard   : « Ton cube ressemble à ça ? » après chaque formule.
import '../../core/cube/cube.dart';
import '../../core/cube/solver.dart';
import '../../core/method/method.dart';

sealed class GuideCard {
  GuideCard(this.before, this.action);

  /// État du cube (virtuel) au début de la carte.
  final Cube before;

  /// Action du solveur à laquelle appartient la carte.
  final SolveAction action;

  /// Mouvements appliqués quand la carte est faite.
  List<Move> get moves;

  Cube get after => before.apply(moves);
}

class PlaceCard extends GuideCard {
  PlaceCard(super.before, super.action, this.rotation);
  final List<Move> rotation;

  @override
  List<Move> get moves => rotation;

  CubeColor get top => after.center(Face.u);
  CubeColor get front => after.center(Face.f);
}

class FormulaCard extends GuideCard {
  FormulaCard(super.before, super.action);
  @override
  List<Move> get moves => const [];

  Algorithm get algorithm => action.algorithm!;
  int get repetitions => action.repetitions;

  /// Les morceaux de 4 gestes au plus (8 gestes = 2 morceaux).
  List<List<Move>> get chunks => chunksOf(action.moves);
}

class GestureCard extends GuideCard {
  GestureCard(
    super.before,
    super.action, {
    required this.move,
    required this.chunk,
    required this.indexInChunk,
    required this.chunkIndex,
    required this.chunkCount,
    required this.repetition,
  });

  final Move move;

  /// Les gestes du morceau en cours (frise de cartes numérotées).
  final List<Move> chunk;
  final int indexInChunk;
  final int chunkIndex;
  final int chunkCount;
  final int repetition;

  bool get inFormula => action.algorithm != null;

  @override
  List<Move> get moves => [move];
}

class CheckCard extends GuideCard {
  CheckCard(super.before, super.action);
  @override
  List<Move> get moves => const [];
}

/// Coupe une suite en morceaux de 4 au plus (et équilibrés : 8 → 4 + 4).
List<List<Move>> chunksOf(List<Move> moves) {
  if (moves.length <= 5) return [moves];
  final n = (moves.length / 4).ceil();
  final size = (moves.length / n).ceil();
  return [
    for (var i = 0; i < moves.length; i += size)
      moves.sublist(i, (i + size).clamp(0, moves.length)),
  ];
}

/// Les cartes d'une suite d'actions, à partir de l'état [start].
/// [checks] : ajouter « Ton cube ressemble à ça ? » après chaque formule.
List<GuideCard> buildCards(
  Cube start,
  List<SolveAction> actions, {
  bool checks = true,
}) {
  final cards = <GuideCard>[];
  var cube = start;
  for (var ai = 0; ai < actions.length; ai++) {
    final a = actions[ai];
    if (a.type == ActionType.rotateCube) {
      // Plusieurs rotations à la suite : une seule carte « place ton cube ».
      final last = cards.isNotEmpty ? cards.last : null;
      if (last is PlaceCard) {
        cards.removeLast();
        final merged = PlaceCard(last.before, last.action, [
          ...last.rotation,
          ...a.allMoves,
        ]);
        cards.add(merged);
      } else {
        cards.add(PlaceCard(cube, a, a.allMoves));
      }
      cube = cube.apply(a.allMoves);
      continue;
    }
    if (a.algorithm != null) {
      cards.add(FormulaCard(cube, a));
    }
    final chunks = chunksOf(a.moves);
    for (var rep = 1; rep <= a.repetitions; rep++) {
      for (var ci = 0; ci < chunks.length; ci++) {
        for (var k = 0; k < chunks[ci].length; k++) {
          final card = GestureCard(
            cube,
            a,
            move: chunks[ci][k],
            chunk: chunks[ci],
            indexInChunk: k,
            chunkIndex: ci,
            chunkCount: chunks.length,
            repetition: rep,
          );
          cards.add(card);
          cube = card.after;
        }
      }
    }
    if (a.algorithm != null && checks) cards.add(CheckCard(cube, a));
  }
  return cards;
}

/// Indice de la carte « formule » d'une carte (pour recommencer la formule).
int formulaStartOf(List<GuideCard> cards, int index) {
  final action = cards[index].action;
  for (var i = index; i >= 0; i--) {
    if (cards[i] is FormulaCard && identical(cards[i].action, action)) return i;
  }
  return index;
}
