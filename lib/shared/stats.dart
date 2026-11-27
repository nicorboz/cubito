// Statistiques pour les trophées : cubes résolus, meilleur temps…
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'prefs.dart';

class Stats {
  const Stats({this.realSolves = 0, this.virtualSolves = 0, this.bestTimeMs});

  /// Vrais cubes résolus avec le mode « Résoudre mon cube ».
  final int realSolves;

  /// Cubes virtuels résolus après un mélange (mode « S'entraîner »).
  final int virtualSolves;

  /// Meilleur temps au chrono (cube virtuel), en millisecondes.
  final int? bestTimeMs;

  int get totalSolves => realSolves + virtualSolves;
}

class StatsNotifier extends Notifier<Stats> {
  @override
  Stats build() {
    final p = ref.watch(prefsProvider);
    return Stats(
      realSolves: p.getInt('realSolves') ?? 0,
      virtualSolves: p.getInt('virtualSolves') ?? 0,
      bestTimeMs: p.getInt('bestTimeMs'),
    );
  }

  void addRealSolve() {
    ref.read(prefsProvider).setInt('realSolves', state.realSolves + 1);
    state = Stats(
      realSolves: state.realSolves + 1,
      virtualSolves: state.virtualSolves,
      bestTimeMs: state.bestTimeMs,
    );
  }

  void addVirtualSolve({int? timeMs}) {
    final p = ref.read(prefsProvider);
    final best =
        (timeMs != null &&
            (state.bestTimeMs == null || timeMs < state.bestTimeMs!))
        ? timeMs
        : state.bestTimeMs;
    p.setInt('virtualSolves', state.virtualSolves + 1);
    if (best != null) p.setInt('bestTimeMs', best);
    state = Stats(
      realSolves: state.realSolves,
      virtualSolves: state.virtualSolves + 1,
      bestTimeMs: best,
    );
  }

  void reset() {
    final p = ref.read(prefsProvider);
    for (final k in ['realSolves', 'virtualSolves', 'bestTimeMs']) {
      p.remove(k);
    }
    state = const Stats();
  }
}

final statsProvider = NotifierProvider<StatsNotifier, Stats>(StatsNotifier.new);
