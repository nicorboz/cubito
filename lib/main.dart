// Point d'entrée de l'application « Cubito ».
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'shared/fullscreen.dart';
import 'shared/prefs.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Plein écran : on masque la barre du bas et la barre d'état d'Android.
  await enterFullscreen();
  // Stockage local (progression et réglages), lu une fois au démarrage.
  final prefs = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [prefsProvider.overrideWithValue(prefs)],
      child: const FullscreenKeeper(child: CubeMagiqueApp()),
    ),
  );
}
