// Outils partagés par les tests du cœur.
import 'dart:math';

import 'package:cube_magique/core/cube/cube.dart';

/// Cube résolu tenu jaune en haut (après « retourner le cube »).
Cube solvedYellowUp() => Cube.solved().apply('x2');

/// Applique au hasard [length] éléments de [words] (séquences en notation).
Cube randomWalk(Cube start, List<String> words, int length, Random rnd) {
  var c = start;
  for (var i = 0; i < length; i++) {
    c = c.apply(words[rnd.nextInt(words.length)]);
  }
  return c;
}
