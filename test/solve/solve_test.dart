// Tests du mode « Résoudre mon cube » et de l'indice de « S'entraîner ».
import 'dart:math';

import 'package:cube_magique/app.dart';
import 'package:cube_magique/core/cube/cube.dart';
import 'package:cube_magique/core/cube/solver.dart';
import 'package:cube_magique/core/cube/validation.dart';
import 'package:cube_magique/core/method/method.dart';
import 'package:cube_magique/features/practice/practice_screen.dart';
import 'package:cube_magique/features/solve/cube_input.dart';
import 'package:cube_magique/features/solve/solve_screen.dart';
import 'package:cube_magique/l10n/app_localizations_fr.dart';
import 'package:cube_magique/shared/widgets/sticker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../test_app.dart';

final l = AppLocalizationsFr();

void main() {
  test("Retour à l'orientation de saisie", () {
    final c = Cube.solved().apply("R U F'");
    for (final r in ['x2', 'y', 'x2 y2', "y'"]) {
      expect(toReferenceOrientation(c.apply(r)), c);
    }
  });

  test('Messages de validation gentils', () {
    final colors = Cube.solved().colors.toList()..[0] = CubeColor.red;
    final bad = Cube.fromColors(colors);
    expect(
      validationMessage(l, bad, validateCube(bad)),
      'Oups, il y a trop de cases rouge. Vérifie !',
    );
    final c2 = Cube.solved().colors.toList();
    c2[9] = CubeColor.white;
    c2[7] = CubeColor.red; // coin URF impossible (deux blancs)
    final bad2 = Cube.fromColors(c2);
    expect(
      validationMessage(l, bad2, validateCube(bad2)),
      contains('Vérifie la face blanche'),
    );
  });

  test('Quelle étape ? suit la progression de la méthode', () {
    final rnd = Random(5);
    for (var i = 0; i < 200; i++) {
      var c = Cube.solved().apply(randomScramble(random: rnd));
      for (final step in solveBeginner(c).steps) {
        if (step.actions.isNotEmpty) expect(currentStep(c), step.step);
        c = c.apply([for (final a in step.actions) ...a.allMoves]);
      }
      expect(currentStep(c), isNull);
    }
  });

  for (final path in ['Toute la méthode', 'Le plus court']) {
    testWidgets(
      'Saisie complète au doigt, puis « $path » jusqu\'au cube résolu',
      (tester) async {
        final target = Cube.solved().apply("R U R' F2 D L'");
        await pumpWithProviders(
          tester,
          const CubeMagiqueApp(home: SolveScreen()),
          prefs: {'speed': 'rapide'},
          size: const Size(420, 900),
        );
        await tester.tap(find.text('Colorier à la main'));
        await tester.pump();
        // On colorie les 6 faces dans l'ordre imposé.
        for (final face in inputOrder) {
          for (var k = 0; k < 9; k++) {
            if (k == 4) continue;
            final color = target[face.index * 9 + k];
            await tester.tap(
              find.byType(StickerCell).at(9 + color.index),
            ); // palette
            await tester.tap(find.byType(StickerCell).at(k)); // case de la face
          }
          await tester.pump();
          if (face != Face.d) {
            await tester.tap(find.text('Face suivante'));
            await tester.pump();
          }
        }
        await tester.tap(find.text('Vérifier'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        // Choix du chemin.
        expect(find.text('Toute la méthode'), findsOneWidget);
        if (path == 'Le plus court') {
          // La solution courte est calculée en arrière-plan.
          for (
            var k = 0;
            k < 40 && find.textContaining('Je cherche').evaluate().isNotEmpty;
            k++
          ) {
            await tester.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 500)),
            );
            await tester.pump();
          }
        }
        await tester.tap(find.text(path));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(
          find.textContaining(
            path == 'Le plus court' ? 'Chemin court' : 'Étape',
          ),
          findsOneWidget,
        );

        // On suit le guide jusqu'au bout.
        // On suit les cartes : quel que soit le bouton (bon, on y va, fait, oui).
        for (var k = 0; k < 600; k++) {
          final btn = ["C'est bon !", 'On y va !', 'Fait !', 'Oui !']
              .map(find.text)
              .firstWhere(
                (f) => f.evaluate().isNotEmpty,
                orElse: () => find.text('§'),
              );
          if (btn.evaluate().isEmpty) break;
          await tester.tap(btn.first);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
        }
        expect(
          find.text('Bravo, tu as résolu ton vrai cube ! 🎉'),
          findsOneWidget,
        );
        await tester.pump(const Duration(seconds: 3));
      },
    );
  }

  testWidgets('Saisie impossible : message gentil et cases qui clignotent', (
    tester,
  ) async {
    await pumpWithProviders(
      tester,
      const CubeMagiqueApp(home: SolveScreen()),
      size: const Size(420, 900),
    );
    await tester.tap(find.text('Colorier à la main'));
    await tester.pump();
    // Tout en blanc sur la première face… et partout ailleurs (trop de blancs).
    for (var face = 0; face < 6; face++) {
      for (var k = 0; k < 9; k++) {
        if (k == 4) continue;
        await tester.tap(find.byType(StickerCell).at(k));
      }
      await tester.pump();
      if (face < 5) {
        await tester.tap(find.text('Face suivante'));
        await tester.pump();
      }
    }
    await tester.tap(find.text('Vérifier'));
    await tester.pump();
    expect(find.textContaining('trop de cases blanc'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets("S'entraîner : l'indice donne l'étape", (tester) async {
    await pumpWithProviders(
      tester,
      const CubeMagiqueApp(home: PracticeScreen()),
    );
    await tester.tap(find.byTooltip('Mélanger'));
    await tester.pump();
    await tester.tap(find.byTooltip('Quelle étape ?'));
    await tester.pump();
    expect(find.textContaining("Tu en es à l'île 1"), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
  });

  test('Le solveur part du cube saisi tel quel', () {
    final c = Cube.solved().apply("R U R' F2 D L'");
    final s = solveBeginner(c);
    expect(s.steps.first.step, MethodStep.croixBlanche);
    expect(c.apply(s.allMoves).isSolved, isTrue);
  });
}
