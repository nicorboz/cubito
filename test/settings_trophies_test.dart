// Réglages, espace parent et trophées.
import 'package:cube_magique/app.dart';
import 'package:cube_magique/features/settings/settings_screen.dart';
import 'package:cube_magique/features/trophies/trophies_screen.dart';
import 'package:cube_magique/shared/progress.dart';
import 'package:cube_magique/shared/stats.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'test_app.dart';

void main() {
  test('Trophées : conditions', () {
    final p = Progress(List.filled(10, 3));
    const s = Stats(realSolves: 1, virtualSolves: 4, bestTimeMs: 100000);
    expect(trophies.every((t) => t.earned(p, s)), isTrue);
    final p0 = Progress(List.filled(10, 0));
    expect(trophies.where((t) => t.earned(p0, const Stats())), isEmpty);
  });

  testWidgets('Écran trophées : compte les trophées gagnés', (tester) async {
    await pumpWithProviders(
      tester,
      const CubeMagiqueApp(home: TrophiesScreen()),
      prefs: {'lesson_stars_0': 2, 'virtualSolves': 1},
    );
    expect(find.text('2 trophées sur 9'), findsOneWidget);
  });

  testWidgets('Réglages : couper la voix est sauvegardé', (tester) async {
    await pumpWithProviders(
      tester,
      const CubeMagiqueApp(home: SettingsScreen()),
    );
    await tester.tap(find.text('Voix'));
    await tester.pump();
    expect(find.text('Essayer la voix'), findsNothing);
  });

  testWidgets('Espace parent : bon calcul → remise à zéro', (tester) async {
    await pumpWithProviders(
      tester,
      const CubeMagiqueApp(home: SettingsScreen()),
      prefs: {'lesson_stars_0': 3},
      size: const Size(420, 900),
    );
    await tester.scrollUntilVisible(find.text('Espace parent'), 200);
    await tester.tap(find.text('Espace parent'));
    await tester.pump();
    final q = tester.widget<Text>(find.textContaining('Combien font')).data!;
    final nums = RegExp(r'\d+')
        .allMatches(q)
        .map((m) => int.parse(m.group(0)!))
        .toList();
    await tester.enterText(find.byType(TextField), '${nums[0] + nums[1]}');
    await tester.tap(find.text('Valider'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Remettre la progression à zéro'), findsOneWidget);
    await tester.tap(find.text('Remettre la progression à zéro'));
    await tester.pump();
    await tester.tap(find.text('Valider'));
    await tester.pump();
    expect(find.text('La progression a été remise à zéro.'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('Espace parent : mauvais calcul → refusé', (tester) async {
    await pumpWithProviders(
      tester,
      const CubeMagiqueApp(home: SettingsScreen()),
    );
    await tester.scrollUntilVisible(find.text('Espace parent'), 200);
    await tester.tap(find.text('Espace parent'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), '0');
    await tester.tap(find.text('Valider'));
    await tester.pump();
    expect(find.text('Remettre la progression à zéro'), findsNothing);
    await tester.pump(const Duration(seconds: 5));
  });
}
