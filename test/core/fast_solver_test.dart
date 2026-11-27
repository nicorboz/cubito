import 'dart:math';

import 'package:cube_magique/core/cube/cube.dart';
import 'package:cube_magique/core/cube/fast_solver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('résout des cubes mélangés en peu de coups', () {
    final sw = Stopwatch()..start();
    FastSolver.warmUp();
    // ignore: avoid_print
    print('tables : ${sw.elapsedMilliseconds} ms');
    final rnd = Random(3);
    var total = 0, worst = 0;
    const n = 60;
    final solveTime = Stopwatch()..start();
    for (var i = 0; i < n; i++) {
      // Orientation quelconque (le cube peut être tenu n'importe comment).
      final c = Cube.solved()
          .apply(['', 'x', 'x2', 'y', "z'"][i % 5])
          .apply(randomScramble(random: rnd));
      final s = FastSolver.solve(
        c,
        timeLimit: const Duration(milliseconds: 300),
      );
      expect(c.apply(s.moves).isSolved, isTrue, reason: '$c → $s');
      total += s.length;
      worst = max(worst, s.length);
    }
    // ignore: avoid_print
    print(
      'moyenne ${total / n} coups, pire $worst, ${solveTime.elapsedMilliseconds ~/ n} ms/cube',
    );
    expect(total / n, lessThan(23));
    expect(worst, lessThanOrEqualTo(24));
  });

  test('cube déjà résolu et cube à un coup', () {
    expect(FastSolver.solve(Cube.solved()).length, 0);
    expect(FastSolver.solve(Cube.solved().apply("R")).toString(), "R'");
  });

  test('cube impossible (coin tourné) refusé', () {
    // Un coin tourné sur place : URF = facettes 8, 9, 20.
    final s = Cube.solved().toString().split('');
    final a = s[8], b = s[9], c = s[20];
    s[8] = c;
    s[9] = a;
    s[20] = b;
    expect(
      () => FastSolver.solve(Cube.fromString(s.join())),
      throwsA(isA<FastSolverException>()),
    );
  });

  test('cube impossible refusé', () {
    final s = Cube.solved().toString().split('');
    final tmp = s[0];
    s[0] = s[9]; // deux autocollants échangés
    s[9] = tmp;
    expect(
      () => FastSolver.solve(Cube.fromString(s.join())),
      throwsA(isA<FastSolverException>()),
    );
  });
}
