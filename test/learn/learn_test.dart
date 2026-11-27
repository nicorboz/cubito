// Tests du mode « Apprendre ».
import 'dart:math';

import 'package:cube_magique/app.dart';
import 'package:cube_magique/core/cube/cube.dart';
import 'package:cube_magique/features/learn/islands.dart';
import 'package:cube_magique/features/learn/lesson_examples.dart';
import 'package:cube_magique/features/learn/lesson_screen.dart';
import 'package:cube_magique/features/learn/lessons.dart';
import 'package:cube_magique/core/method/method.dart';
import 'package:cube_magique/shared/prefs.dart';
import 'package:cube_magique/shared/progress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test_app.dart';

void main() {
  group('Situations des îles', () {
    test("Chaque île a un exemple qui atteint l'objectif", () {
      for (final island in islands) {
        final s = exampleSituation(island);
        expect(
          island.isGoalReached(s.start),
          isFalse,
          reason: 'île ${island.number}',
        );
        expect(
          island.isGoalReached(s.end),
          isTrue,
          reason: 'île ${island.number}',
        );
        expect(s.moves, isNotEmpty);
      }
    });

    test('Situations aléatoires : 50 par île, toutes réussissables', () {
      final rnd = Random(3);
      for (final island in islands) {
        for (var k = 0; k < 50; k++) {
          final s = randomSituation(island, rnd);
          expect(island.isGoalReached(s.start), isFalse);
          expect(island.isGoalReached(s.end), isTrue);
        }
      }
    });

    test("L'exemple de l'étoile jaune part du point (3 étoiles)", () {
      final s = exampleSituation(islands[5]);
      expect(s.actions.where((a) => a.algorithm != null).length, 3);
    });

    test("L'île 8 couvre placer + tourner les coins et finit le cube", () {
      final s = exampleSituation(islands[7]);
      expect(s.end.isSolved, isTrue);
    });
  });

  group('Progression', () {
    Future<ProviderContainer> container([
      Map<String, Object> init = const {},
    ]) async {
      SharedPreferences.setMockInitialValues(init);
      final p = await SharedPreferences.getInstance();
      return ProviderContainer(overrides: [prefsProvider.overrideWithValue(p)]);
    }

    test('Au départ seule la 1ʳᵉ île est ouverte', () async {
      final c = await container();
      final pr = c.read(progressProvider);
      expect(pr.isUnlocked(0), isTrue);
      expect(pr.isUnlocked(1), isFalse);
    });

    test(
      'Réussir une île ouvre la suivante, on garde le meilleur score',
      () async {
        final c = await container();
        c.read(progressProvider.notifier).recordStars(0, 2);
        expect(c.read(progressProvider).isUnlocked(1), isTrue);
        c.read(progressProvider.notifier).recordStars(0, 1);
        expect(c.read(progressProvider).stars[0], 2);
        c.read(progressProvider.notifier).recordStars(0, 3);
        expect(c.read(progressProvider).totalStars, 3);
        // Sauvegardé sur le téléphone.
        final p = await SharedPreferences.getInstance();
        expect(p.getInt('lesson_stars_0'), 3);
        c.read(progressProvider.notifier).reset();
        expect(c.read(progressProvider).totalStars, 0);
      },
    );
  });

  group('Parcours des formules', () {
    test('10 leçons, dans l\'ordre de la méthode', () {
      expect(lessons.length, lessonCount);
      var lastIsland = 0;
      for (final lesson in lessons) {
        expect(lesson.islandIndex, greaterThanOrEqualTo(lastIsland));
        lastIsland = lesson.islandIndex;
      }
      expect(lessons.first.kind, LessonKind.basics);
      expect(
        [for (final l in lessons) l.algorithm],
        [
          null,
          Algorithm.escargot,
          Algorithm.petiteDanse,
          null,
          Algorithm.tobogganDroit,
          Algorithm.tobogganGauche,
          Algorithm.etoileJaune,
          Algorithm.escargot,
          Algorithm.manege,
          Algorithm.petiteDanse,
        ],
      );
    });

    test('Chaque leçon de formule fait la formule une fois, au bon moment', () {
      for (final lesson in lessons.where((l) => l.kind == LessonKind.formula)) {
        final s = lessonSituation(lesson);
        final algos = s.actions.where((a) => a.algorithm != null).toList();
        expect(algos.length, 1, reason: lesson.title.toString());
        expect(algos.single.algorithm, lesson.algorithm);
        // Une seule fois, sauf pour tourner un coin jaune (la petite danse
        // va toujours par 2).
        expect(
          algos.single.repetitions,
          lesson.index == 9 ? 2 : 1,
          reason: 'leçon ${lesson.number}',
        );
        expect(s.start, isNot(s.end));
      }
    });

    test('Gestes de base : le cube revient résolu', () {
      final s = lessonSituation(lessons.first);
      expect(s.end.isSolved, isTrue);
      expect(s.moves.length, 10);
    });
  });

  group('Écrans', () {
    testWidgets('Parcours : leçon 1 ouverte, leçon 2 fermée', (tester) async {
      await pumpWithProviders(tester, const CubeMagiqueApp());
      await tester.tap(find.text('Apprendre'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Le parcours des formules'), findsOneWidget);
      expect(find.text('👆 Les gestes de base'), findsOneWidget);
      await tester.tap(find.text('🐌 L\'escargot'));
      await tester.pump();
      expect(
        find.text("Réussis la leçon d'avant pour ouvrir celle-ci."),
        findsOneWidget,
      );
      await tester.pump(const Duration(seconds: 5));
    });

    for (final lesson in lessons) {
      testWidgets('Leçon ${lesson.number} : les 3 parties s\'affichent', (
        tester,
      ) async {
        await pumpWithProviders(tester, _LessonHost(lesson: lesson));
        for (final part in ['Regarde', 'Pas à pas', 'Fiche']) {
          await tester.tap(find.byTooltip(part).first);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 400));
          final e = tester.takeException();
          if (e is FlutterError) debugPrint(e.toStringDeep());
          expect(e, isNull, reason: '$part leçon ${lesson.number}');
        }
        await tester.pump(const Duration(seconds: 2));
      });
    }

    testWidgets('Pas à pas jusqu\'au bout : leçon vue, rappel, suivante', (
      tester,
    ) async {
      await pumpWithProviders(
        tester,
        _LessonHost(lesson: lessons[2]), // la petite danse
        size: const Size(420, 900),
      );
      await tester.tap(find.byTooltip('Pas à pas'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byTooltip('À toi\u00a0!'), findsNothing);
      for (var k = 0; k < 30; k++) {
        final btn =
            ["C'est bon\u00a0!", 'On y va\u00a0!', 'Fait\u00a0!', 'Oui\u00a0!']
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
      expect(find.text('Bien joué, tu as tout vu\u00a0!'), findsOneWidget);
      expect(find.text('Tu viens de voir'), findsOneWidget);
      expect(find.text('Leçon suivante'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
    });
  });

  test('Le cube de départ du défi est bien mélangé', () {
    final s = randomSituation(islands[0], Random(1));
    expect(s.start.isSolved, isFalse);
    expect(s.start.center(Face.u), CubeColor.white);
  });
}

/// Ouvre directement une leçon dans l'appli (localisation comprise).
class _LessonHost extends StatelessWidget {
  const _LessonHost({required this.lesson});
  final Lesson lesson;

  @override
  Widget build(BuildContext context) {
    return CubeMagiqueApp(home: LessonScreen(lesson: lesson));
  }
}
