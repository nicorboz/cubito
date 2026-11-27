// Retour à l'écran précédent en glissant le doigt depuis le bord gauche ou
// droit de l'écran (comme le geste « retour » d'Android).
//
// L'appli est en plein écran immersif : dans ce mode, Android garde le
// premier glissement depuis le bord pour réafficher ses barres, et le geste
// retour du système ne marche donc pas du premier coup (et pas du tout avec
// la navigation à 3 boutons cachée). Ce widget fait le geste lui-même,
// sans rien afficher (seulement une petite vibration quand c'est validé).
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

class EdgeSwipeBack extends StatefulWidget {
  const EdgeSwipeBack({
    super.key,
    required this.navigatorKey,
    required this.child,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final Widget child;

  /// Largeur de la bande sensible le long de chaque bord.
  static const edgeWidth = 28.0;

  /// Distance à parcourir pour valider le retour.
  static const commitDistance = 90.0;

  static DateTime? _lastPop;

  /// Vrai juste après un retour fait par ce geste : si Android envoie aussi
  /// son propre « retour » pour le même glissement, on l'ignore.
  static bool get justPopped =>
      _lastPop != null &&
      DateTime.now().difference(_lastPop!) < const Duration(milliseconds: 800);

  @override
  State<EdgeSwipeBack> createState() => _EdgeSwipeBackState();
}

class _EdgeSwipeBackState extends State<EdgeSwipeBack> {
  int? _pointer;
  bool _fromLeft = true;
  Offset _start = Offset.zero;
  bool _tracking = false; // le geste est reconnu comme un glissement horizontal
  bool _armed = false; // assez loin : relâcher = retour

  void _down(PointerDownEvent e) {
    if (_pointer != null) return;
    final width = context.size?.width ?? 0;
    final x = e.localPosition.dx;
    final nearLeft = x <= EdgeSwipeBack.edgeWidth;
    final nearRight = x >= width - EdgeSwipeBack.edgeWidth;
    if (!nearLeft && !nearRight) return;
    if (!(widget.navigatorKey.currentState?.canPop() ?? false)) return;
    _pointer = e.pointer;
    _fromLeft = nearLeft;
    _start = e.localPosition;
    _tracking = false;
    _armed = false;
  }

  void _move(PointerMoveEvent e) {
    if (e.pointer != _pointer) return;
    final d = e.localPosition - _start;
    final inward = _fromLeft ? d.dx : -d.dx;
    if (!_tracking) {
      // Le doigt part surtout vers le haut ou le bas : ce n'est pas un retour.
      if (d.dy.abs() > 24 && d.dy.abs() > inward.abs()) {
        _reset();
        return;
      }
      if (inward < 12) return;
      _tracking = true;
    }
    final armed = inward >= EdgeSwipeBack.commitDistance;
    if (armed && !_armed) HapticFeedback.selectionClick();
    _armed = armed;
  }

  void _up(PointerUpEvent e) {
    if (e.pointer != _pointer) return;
    final go = _tracking && _armed;
    _reset();
    if (go) {
      EdgeSwipeBack._lastPop = DateTime.now();
      widget.navigatorKey.currentState?.maybePop();
    }
  }

  void _cancel(PointerCancelEvent e) {
    if (e.pointer == _pointer) _reset();
  }

  void _reset() {
    _pointer = null;
    _tracking = false;
    _armed = false;
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _down,
      onPointerMove: _move,
      onPointerUp: _up,
      onPointerCancel: _cancel,
      child: widget.child,
    );
  }
}
