// Mes trophées : badges gagnés grâce à la progression et aux cubes résolus.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';
import '../../shared/progress.dart';
import '../../shared/stats.dart';
import '../../shared/theme.dart';
import '../practice/practice_screen.dart' show formatTime;

class Trophy {
  const Trophy(this.emoji, this.title, this.help, this.color, this.earned);
  final String emoji;
  final String Function(AppLocalizations) title;
  final String Function(AppLocalizations) help;
  final Color color;
  final bool Function(Progress p, Stats s) earned;
}

final trophies = <Trophy>[
  Trophy(
    '🌼',
    (l) => l.trophyFirstCross,
    (l) => l.trophyFirstCrossHelp,
    const Color(0xFFE6A100),
    (p, s) => p.isDone(0),
  ),
  Trophy(
    '🧭',
    (l) => l.trophyHalfway,
    (l) => l.trophyHalfwayHelp,
    const Color(0xFF2E9CCA),
    (p, s) => p.isDone(4),
  ),
  Trophy(
    '🏝️',
    (l) => l.trophyAllIslands,
    (l) => l.trophyAllIslandsHelp,
    const Color(0xFF1E8E3E),
    (p, s) => p.isDone(9),
  ),
  Trophy(
    '🌟',
    (l) => l.trophyAllStars,
    (l) => l.trophyAllStarsHelp,
    const Color(0xFFE08A00),
    (p, s) => p.totalStars >= 30,
  ),
  Trophy(
    '🎉',
    (l) => l.trophyFirstSolve,
    (l) => l.trophyFirstSolveHelp,
    const Color(0xFFD9467A),
    (p, s) => s.totalSolves >= 1,
  ),
  Trophy(
    '🧊',
    (l) => l.trophyRealCube,
    (l) => l.trophyRealCubeHelp,
    const Color(0xFF1765CC),
    (p, s) => s.realSolves >= 1,
  ),
  Trophy(
    '🖐️',
    (l) => l.trophyFiveSolves,
    (l) => l.trophyFiveSolvesHelp,
    const Color(0xFF7B3FC4),
    (p, s) => s.totalSolves >= 5,
  ),
  Trophy(
    '⏱️',
    (l) => l.trophyUnder5,
    (l) => l.trophyUnder5Help,
    const Color(0xFFC2410C),
    (p, s) => s.bestTimeMs != null && s.bestTimeMs! < 5 * 60 * 1000,
  ),
  Trophy(
    '🚀',
    (l) => l.trophyUnder2,
    (l) => l.trophyUnder2Help,
    const Color(0xFF8E5AC8),
    (p, s) => s.bestTimeMs != null && s.bestTimeMs! < 2 * 60 * 1000,
  ),
];

class TrophiesScreen extends ConsumerWidget {
  const TrophiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final p = ref.watch(progressProvider);
    final s = ref.watch(statsProvider);
    final t = Theme.of(context).textTheme;
    final earned = trophies.where((x) => x.earned(p, s)).length;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.tileTrophies),
        leading: IconButton(
          tooltip: l.back,
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Column(
                  children: [
                    Text(
                      l.trophiesCount(earned, trophies.length),
                      style: t.headlineSmall,
                    ),
                    Text(
                      '⭐ ${p.totalStars} · ${l.statsSolves(s.totalSolves)}',
                      style: t.bodyLarge,
                    ),
                    if (s.bestTimeMs != null)
                      Text(
                        l.statsBest(
                          formatTime(Duration(milliseconds: s.bestTimeMs!)),
                        ),
                        style: t.bodyLarge,
                      ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 220,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  mainAxisExtent: 250,
                ),
                delegate: SliverChildBuilderDelegate(
                  childCount: trophies.length,
                  (context, i) {
                    final tr = trophies[i];
                    final got = tr.earned(p, s);
                    return Semantics(
                      label: '${tr.title(l)}. ${tr.help(l)}',
                      excludeSemantics: true,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: got ? tr.color : const Color(0xFFE9E3EF),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        // Le contenu rétrécit si la carte est petite.
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: SizedBox(
                            width: 180,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Opacity(
                                  opacity: got ? 1 : 0.35,
                                  child: Text(
                                    got ? tr.emoji : '🔒',
                                    style: const TextStyle(fontSize: 46),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  tr.title(l),
                                  textAlign: TextAlign.center,
                                  style: t.titleMedium?.copyWith(
                                    color: got ? Colors.white : CubeColors.ink,
                                  ),
                                ),
                                Text(
                                  tr.help(l),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: got
                                        ? Colors.white
                                        : CubeColors.ink.withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }
}
