// Contrôleur du cube 3D : état du cube, file de mouvements à animer,
// caméra, flèche et cases surlignées. Les écrans parlent au cube 3D
// uniquement par ce contrôleur.
import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart' show Curves;

import '../core/cube/cube.dart';
import 'cube_scene.dart';

class CubeController extends ChangeNotifier {
  CubeController({Cube? cube, this.camera = const CubeCamera()})
    : _cube = cube ?? Cube.solved();

  Cube _cube;

  /// État du cube (sans le mouvement en cours d'animation).
  Cube get cube => _cube;

  CubeCamera camera;

  /// Durée d'un quart de tour. 🐢 lent ≈ 900 ms, 🐇 rapide ≈ 250 ms.
  Duration quarterTurnDuration = const Duration(milliseconds: 450);

  /// Flèche à afficher (mouvement à faire), ou null.
  /// Le mouvement à faire est aussi « esquissé » par la tranche elle-même
  /// (un petit aller-retour en boucle) et le reste du cube est estompé.
  Move? get arrow => _arrow;
  Move? _arrow;
  set arrow(Move? m) {
    _arrow = m;
    _hintMs = 0;
    notifyListeners();
  }

  /// Esquisse du geste activée (désactivée si « réduire les animations »).
  bool nudgeEnabled = true;
  double _hintMs = 0;

  /// Le widget doit-il faire avancer le temps à chaque image ?
  bool get needsTick => _current != null || (_arrow != null && nudgeEnabled);

  /// Tranche mise en avant (mouvement en cours, ou mouvement à faire).
  /// Rien d'estompé pour une rotation du cube entier.
  LayerFocus? get focus {
    final m = _current ?? _arrow;
    if (m == null || m.kind.isRotation) return null;
    return LayerFocus.of(m);
  }

  /// Courbe de l'esquisse : part vite, revient en douceur, puis pause.
  static double _nudgeCurve(double ms) {
    const cycle = 2000.0;
    final p = (ms % cycle) / cycle;
    if (p < 0.22) {
      final t = p / 0.22;
      return 1 - math.pow(1 - t, 3).toDouble(); // sortie rapide
    }
    if (p < 0.55) {
      final t = (p - 0.22) / 0.33;
      return 1 - Curves.easeInOut.transform(t); // retour doux
    }
    return 0;
  }

  /// Cases qui clignotent doucement (ex. couleur douteuse).
  Set<int> get highlighted => _highlighted;
  Set<int> _highlighted = const {};
  set highlighted(Set<int> v) {
    _highlighted = v;
    notifyListeners();
  }

  final _queue = Queue<(Move, Completer<void>)>();
  Move? _current;
  double _elapsedMs = 0;
  Completer<void>? _currentDone;

  bool get isAnimating => _current != null;

  /// Animation de tranche à dessiner maintenant.
  LayerAnimation? get animation {
    final m = _current;
    if (m == null) {
      final a = _arrow;
      if (a == null || !nudgeEnabled) return null;
      final amp = a.kind.isRotation ? 0.28 : 0.4; // ~23° pour une tranche
      final sign = LayerAnimation.targetAngle(a) > 0 ? 1 : -1;
      final k = _nudgeCurve(_hintMs);
      if (k == 0) return null;
      return LayerAnimation(a.kind.axis, a.kind.layers, sign * amp * k);
    }
    final total = _durationOf(m);
    final t = Curves.easeInOut.transform((_elapsedMs / total).clamp(0, 1));
    return LayerAnimation(
      m.kind.axis,
      m.kind.layers,
      LayerAnimation.targetAngle(m) * t,
    );
  }

  double _durationOf(Move m) {
    final base = quarterTurnDuration.inMilliseconds.toDouble();
    return m.turns == 2 ? base * 1.6 : base;
  }

  /// Joue des mouvements animés, l'un après l'autre. Le Future se termine
  /// quand le dernier est fini.
  Future<void> play(List<Move> moves) {
    if (moves.isEmpty) return Future.value();
    late Future<void> last;
    for (final m in moves) {
      final c = Completer<void>();
      _queue.add((m, c));
      last = c.future;
    }
    _startNext();
    notifyListeners();
    return last;
  }

  /// Change l'état sans animation (annule les animations en attente).
  void jumpTo(Cube cube) {
    for (final (_, c) in _queue) {
      if (!c.isCompleted) c.complete();
    }
    _queue.clear();
    if (_currentDone != null && !_currentDone!.isCompleted) {
      _currentDone!.complete();
    }
    _current = null;
    _currentDone = null;
    _cube = cube;
    notifyListeners();
  }

  void _startNext() {
    if (_current != null || _queue.isEmpty) return;
    final (m, c) = _queue.removeFirst();
    _current = m;
    _currentDone = c;
    _elapsedMs = 0;
  }

  /// Avance l'animation (appelé à chaque image par le widget).
  void tick(Duration delta) {
    final m = _current;
    if (m == null) {
      if (_arrow != null && nudgeEnabled) {
        _hintMs += delta.inMicroseconds / 1000;
        notifyListeners();
      }
      return;
    }
    _elapsedMs += delta.inMicroseconds / 1000;
    if (_elapsedMs >= _durationOf(m)) {
      _cube = _cube.move(m);
      _current = null;
      _currentDone?.complete();
      _currentDone = null;
      _startNext();
    }
    notifyListeners();
  }

  /// Fait tourner la caméra (glisser le doigt sur le fond).
  void orbit(double dYaw, double dPitch) {
    camera = camera.copyWith(
      yaw: camera.yaw + dYaw,
      pitch: (camera.pitch + dPitch).clamp(-math.pi / 2.2, math.pi / 2.2),
    );
    notifyListeners();
  }

  /// Remet la caméra dans la position de départ.
  void resetCamera() {
    camera = const CubeCamera();
    notifyListeners();
  }
}
