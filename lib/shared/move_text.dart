// Traduction d'un mouvement en phrase pour enfant (section 3.1).
import '../core/cube/cube.dart';
import '../l10n/app_localizations.dart';

String moveLabel(AppLocalizations l, Move m) {
  final t = m.turns;
  return switch (m.kind) {
    MoveKind.r => t == 1 ? l.moveR : (t == 3 ? l.moveRp : l.moveR2),
    MoveKind.l => t == 1 ? l.moveL : (t == 3 ? l.moveLp : l.moveL2),
    MoveKind.u => t == 1 ? l.moveU : (t == 3 ? l.moveUp : l.moveU2),
    MoveKind.d => t == 1 ? l.moveD : (t == 3 ? l.moveDp : l.moveD2),
    MoveKind.f => t == 1 ? l.moveF : (t == 3 ? l.moveFp : l.moveF2),
    MoveKind.b => l.moveB,
    MoveKind.y => t == 1 ? l.moveY : (t == 3 ? l.moveYp : l.moveY2),
    MoveKind.x when t == 2 => l.moveX2,
    _ => l.moveOther,
  };
}
