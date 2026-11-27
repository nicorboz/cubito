// Navigateur : le solveur rapide tourne dans un « Web Worker »
// (solver_worker.js, compilé depuis web_worker/solver_worker.dart), pour que
// l'écran ne se fige pas pendant le calcul des tables (plusieurs secondes).
// Si le worker n'est pas disponible, on calcule directement (plus lent).
import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'fast_solver.dart';

web.Worker? _worker;
bool _workerBroken = false;

/// Une demande à la fois (le worker garde ses tables entre deux demandes).
Future<void> _queue = Future.value();

Future<String> solveStringInBackground(String cube) {
  final result = _queue.then((_) => _solve(cube));
  _queue = result.then((_) {}, onError: (_) {});
  return result;
}

Future<String> _solve(String cube) async {
  if (!_workerBroken) {
    try {
      return await _askWorker(cube);
    } on FastSolverException {
      rethrow;
    } catch (_) {
      _workerBroken = true; // fichier absent, navigateur trop ancien…
      _worker = null;
    }
  }
  // Repli : laisse d'abord l'écran se dessiner, puis calcule.
  await Future<void>.delayed(const Duration(milliseconds: 50));
  return solveCubeString(cube);
}

Future<String> _askWorker(String cube) {
  final worker = _worker ??= web.Worker('solver_worker.js'.toJS);
  final done = Completer<String>();
  late final JSFunction onMessage, onError;
  void cleanup() {
    worker.removeEventListener('message', onMessage);
    worker.removeEventListener('error', onError);
  }

  onMessage = ((web.MessageEvent e) {
    cleanup();
    final answer = (e.data as JSString?)?.toDart ?? '!';
    if (answer.startsWith('!')) {
      done.completeError(FastSolverException(answer.substring(1)));
    } else {
      done.complete(answer.substring(1)); // réponse préfixée par « = »
    }
  }).toJS;
  onError = ((web.Event e) {
    cleanup();
    e.preventDefault();
    done.completeError(StateError('worker indisponible'));
  }).toJS;
  worker.addEventListener('message', onMessage);
  worker.addEventListener('error', onError);
  worker.postMessage(cube.toJS);
  return done.future;
}
