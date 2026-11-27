// Algorithme hongrois : affectation de coût minimal (matrice carrée).
// Utilisé pour imposer exactement 9 cases par couleur lors du scan.

/// Renvoie pour chaque ligne i la colonne affectée, en minimisant la somme
/// des coûts. Complexité O(n³) (n = 48 au scan : instantané).
List<int> hungarian(List<List<double>> cost) {
  final n = cost.length;
  const inf = double.infinity;
  final u = List<double>.filled(n + 1, 0), v = List<double>.filled(n + 1, 0);
  final p = List<int>.filled(n + 1, 0), way = List<int>.filled(n + 1, 0);
  for (var i = 1; i <= n; i++) {
    p[0] = i;
    var j0 = 0;
    final minv = List<double>.filled(n + 1, inf);
    final used = List<bool>.filled(n + 1, false);
    do {
      used[j0] = true;
      final i0 = p[j0];
      var delta = inf;
      var j1 = 0;
      for (var j = 1; j <= n; j++) {
        if (used[j]) continue;
        final cur = cost[i0 - 1][j - 1] - u[i0] - v[j];
        if (cur < minv[j]) {
          minv[j] = cur;
          way[j] = j0;
        }
        if (minv[j] < delta) {
          delta = minv[j];
          j1 = j;
        }
      }
      for (var j = 0; j <= n; j++) {
        if (used[j]) {
          u[p[j]] += delta;
          v[j] -= delta;
        } else {
          minv[j] -= delta;
        }
      }
      j0 = j1;
    } while (p[j0] != 0);
    do {
      final j1 = way[j0];
      p[j0] = p[j1];
      j0 = j1;
    } while (j0 != 0);
  }
  final result = List<int>.filled(n, -1);
  for (var j = 1; j <= n; j++) {
    if (p[j] != 0) result[p[j] - 1] = j - 1;
  }
  return result;
}
