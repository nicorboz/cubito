// Téléphone : le solveur rapide tourne dans un isolat (Flutter `compute`).
import 'package:flutter/foundation.dart' show compute;

import 'fast_solver.dart';

Future<String> solveStringInBackground(String cube) =>
    compute(solveCubeString, cube);
