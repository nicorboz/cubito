// « Web Worker » de la version web : calcule la solution la plus courte
// sans figer l'écran. Compilé en JavaScript au moment de la publication :
//   dart compile js -O2 -o build/web/solver_worker.js web_worker/solver_worker.dart
// Message reçu : le cube (texte). Réponse : « =solution » ou « !erreur ».
import 'dart:js_interop';

import 'package:cube_magique/core/cube/fast_solver.dart';
import 'package:web/web.dart' as web;

@JS('self')
external web.DedicatedWorkerGlobalScope get _self;

void main() {
  _self.onmessage = ((web.MessageEvent e) {
    final cube = (e.data as JSString).toDart;
    String answer;
    try {
      answer = '=${solveCubeString(cube)}';
    } catch (err) {
      answer = '!${err is FastSolverException ? err.message : err}';
    }
    _self.postMessage(answer.toJS);
  }).toJS;
}
