// Mots des cartes de gestes : un verbe en gros, la partie en petit, la main
// à utiliser, et la « chanson » d'une formule.
import 'package:material_ui/material_ui.dart' show IconData, Icons;

import '../core/cube/cube.dart';
import '../l10n/app_localizations.dart';

class GestureWords {
  const GestureWords(this.verb, this.object, {this.hand});
  final String verb;
  final String object;

  /// « main droite » / « main gauche », ou null.
  final String? hand;
}

GestureWords gestureWords(AppLocalizations l, Move m) {
  final ccw = m.turns == 3;
  final twice = m.turns == 2 ? ' · ${l.twiceSuffix}' : '';
  return switch (m.kind) {
    MoveKind.r => GestureWords(
      (ccw ? l.verbDown : l.verbUp) + twice,
      l.objRightCol,
      hand: l.handRight,
    ),
    MoveKind.l => GestureWords(
      (ccw ? l.verbUp : l.verbDown) + twice,
      l.objLeftCol,
      hand: l.handLeft,
    ),
    MoveKind.u => GestureWords(
      (ccw ? l.verbRight : l.verbLeft) + twice,
      l.objTopRow,
    ),
    MoveKind.d => GestureWords(
      (ccw ? l.verbLeft : l.verbRight) + twice,
      l.objBottomRow,
    ),
    MoveKind.f => GestureWords(
      l.verbTurn + twice,
      ccw ? l.objFrontCcw : l.objFrontCw,
    ),
    _ => GestureWords(l.verbTurn, l.objBack),
  };
}

/// Flèche courte d'un geste (frise de cartes numérotées).
String gestureArrow(Move m) {
  final ccw = m.turns == 3;
  final a = switch (m.kind) {
    MoveKind.r => ccw ? '↓' : '↑',
    MoveKind.l => ccw ? '↑' : '↓',
    MoveKind.u => ccw ? '→' : '←',
    MoveKind.d => ccw ? '←' : '→',
    MoveKind.f => ccw ? '↺' : '↻',
    _ => '•',
  };
  return m.turns == 2 ? '$a$a' : a;
}

/// La chanson d'une formule : « descends, à gauche, monte, à droite ».
String formulaChant(AppLocalizations l, List<Move> moves) {
  String word(Move m) {
    final ccw = m.turns == 3;
    final w = switch (m.kind) {
      MoveKind.r => ccw ? l.chantDown : l.chantUp,
      MoveKind.l => ccw ? l.chantUp : l.chantDown,
      MoveKind.u => ccw ? l.chantRight : l.chantLeft,
      MoveKind.d => ccw ? l.chantLeft : l.chantRight,
      MoveKind.f => ccw ? l.chantTurnBack : l.chantTurn,
      _ => l.chantTurn,
    };
    return m.turns == 2 ? '$w ${l.twiceSuffix}' : w;
  }

  final s = moves.map(word).join(', ');
  return '${s[0].toUpperCase()}${s.substring(1)}.';
}

/// Icône de la direction d'un geste (frise de cartes numérotées).
IconData gestureIcon(Move m) {
  final ccw = m.turns == 3;
  return switch (m.kind) {
    MoveKind.r =>
      ccw ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
    MoveKind.l =>
      ccw ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
    MoveKind.u => ccw ? Icons.arrow_forward_rounded : Icons.arrow_back_rounded,
    MoveKind.d => ccw ? Icons.arrow_back_rounded : Icons.arrow_forward_rounded,
    MoveKind.f => ccw ? Icons.rotate_left_rounded : Icons.rotate_right_rounded,
    _ => Icons.circle,
  };
}
