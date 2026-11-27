// Démarrage de l'appli pour les tests (stockage simulé, voix muette).
import 'package:cube_magique/shared/prefs.dart';
import 'package:cube_magique/shared/sounds.dart';
import 'package:cube_magique/shared/speech.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> pumpWithProviders(
  WidgetTester tester,
  Widget child, {
  Size size = const Size(400, 800),
  Map<String, Object> prefs = const {},
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues(prefs);
  final p = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        prefsProvider.overrideWithValue(p),
        deviceSpeechProvider.overrideWithValue(SilentSpeech()),
        deviceSoundsProvider.overrideWithValue(SilentSounds()),
      ],
      child: child,
    ),
  );
  await tester.pump();
}
