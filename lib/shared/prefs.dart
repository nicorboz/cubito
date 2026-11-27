// Accès au stockage local (progression, réglages). Rien ne quitte le téléphone.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Fourni au démarrage (main.dart) par `overrideWithValue`.
final prefsProvider = Provider<SharedPreferences>(
  (ref) =>
      throw UnimplementedError('prefsProvider doit être fourni au démarrage'),
);
