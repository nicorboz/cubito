// Progression dans le mode « Apprendre » : étoiles gagnées à chaque leçon
// du parcours des formules.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'prefs.dart';

/// Nombre de leçons du parcours (voir features/learn/lessons.dart).
const lessonCount = 10;

class Progress {
  const Progress(this.stars);

  /// Étoiles (0 à 3) de chaque leçon, indice 0 = leçon 1.
  final List<int> stars;

  bool isDone(int island) => stars[island] > 0;

  /// Une leçon est ouverte si la précédente est réussie.
  bool isUnlocked(int island) => island == 0 || isDone(island - 1);

  int get totalStars => stars.fold(0, (a, b) => a + b);
}

class ProgressNotifier extends Notifier<Progress> {
  @override
  Progress build() {
    final p = ref.watch(prefsProvider);
    return Progress([
      for (var i = 0; i < lessonCount; i++) p.getInt('lesson_stars_$i') ?? 0,
    ]);
  }

  /// Enregistre un résultat (on garde le meilleur nombre d'étoiles).
  void recordStars(int island, int stars) {
    if (stars <= state.stars[island]) return;
    ref.read(prefsProvider).setInt('lesson_stars_$island', stars);
    final next = [...state.stars]..[island] = stars;
    state = Progress(next);
  }

  /// Espace parent : tout remettre à zéro.
  void reset() {
    final p = ref.read(prefsProvider);
    for (var i = 0; i < lessonCount; i++) {
      p.remove('lesson_stars_$i');
    }
    state = Progress(List.filled(lessonCount, 0));
  }
}

final progressProvider = NotifierProvider<ProgressNotifier, Progress>(
  ProgressNotifier.new,
);
