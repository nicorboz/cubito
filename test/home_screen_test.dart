// Tests de l'écran d'accueil : les 4 tuiles sont là et ouvrent leur écran.
import 'package:cube_magique/app.dart';
import 'package:cube_magique/render/cube_view.dart';
import 'package:cube_magique/shared/mascot/cubito.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'test_app.dart';

Future<void> _pumpApp(
  WidgetTester tester, {
  Size size = const Size(400, 800),
}) => pumpWithProviders(tester, const CubeMagiqueApp(), size: size);

void main() {
  testWidgets("L'accueil affiche Cubito et les 4 tuiles", (tester) async {
    await _pumpApp(tester);
    expect(find.byType(Cubito), findsOneWidget);
    for (final label in [
      'Apprendre',
      'Résoudre mon cube',
      "S'entraîner",
      'Mes trophées',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
  });

  testWidgets('Chaque tuile ouvre son écran puis on revient', (tester) async {
    await _pumpApp(tester);
    for (final (label, title) in [
      ('Mes trophées', '0 trophées sur 9'),
      ('Résoudre mon cube', 'Comment veux-tu me montrer ton cube ?'),
    ]) {
      await tester.tap(find.text(label));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.text(title), findsOneWidget);
      await tester.tap(find.byTooltip('Retour'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.text(title), findsNothing);
    }
  });

  testWidgets('Fonctionne en paysage et sur tablette sans débordement', (
    tester,
  ) async {
    for (final size in const [
      Size(800, 400),
      Size(1280, 800),
      Size(800, 1280),
      Size(320, 568),
    ]) {
      await _pumpApp(tester, size: size);
      expect(tester.takeException(), isNull, reason: 'taille $size');
      expect(find.text('Apprendre'), findsOneWidget);
    }
  });

  testWidgets('Les tuiles font au moins 56 dp', (tester) async {
    await _pumpApp(tester, size: const Size(320, 568));
    final box = tester.getSize(
      find
          .ancestor(
            of: find.text('Apprendre'),
            matching: find.byType(GestureDetector),
          )
          .first,
    );
    expect(box.width, greaterThanOrEqualTo(56));
    expect(box.height, greaterThanOrEqualTo(56));
  });

  testWidgets("S'entraîner : mélanger puis recommencer", (tester) async {
    await _pumpApp(tester);
    await tester.tap(find.text("S'entraîner"));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(CubeView), findsOneWidget);
    await tester.tap(find.byTooltip('Mélanger'));
    await tester.pump();
    await tester.tap(find.byTooltip('Recommencer'));
    await tester.pump();
    await tester.tap(find.byTooltip('Retour'));
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('Glisser depuis le bord ramène à l\'accueil', (tester) async {
    await _pumpApp(tester);
    for (final startX in [2.0, 398.0]) {
      await tester.tap(find.text('Mes trophées'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('0 trophées sur 9'), findsOneWidget);
      // Un glissement qui part du milieu ne fait rien.
      await tester.dragFrom(const Offset(200, 400), const Offset(150, 0));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('0 trophées sur 9'), findsOneWidget);
      // Depuis le bord : retour.
      final dx = startX < 200 ? 150.0 : -150.0;
      await tester.dragFrom(Offset(startX, 400), Offset(dx, 0));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('0 trophées sur 9'), findsNothing);
      expect(find.byType(Cubito), findsOneWidget);
    }
  });
}
