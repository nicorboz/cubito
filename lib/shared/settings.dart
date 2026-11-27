// Réglages de l'appli, sauvegardés sur le téléphone.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'prefs.dart';

/// Vitesse des animations du cube.
enum AnimationSpeed {
  lent(900),
  normal(500),
  rapide(250);

  const AnimationSpeed(this.quarterTurnMs);
  final int quarterTurnMs;
}

class Settings {
  const Settings({
    this.voice = true,
    this.sounds = true,
    this.speed = AnimationSpeed.normal,
    this.colorBlind = false,
    this.leftHanded = false,
  });

  final bool voice;
  final bool sounds;
  final AnimationSpeed speed;
  final bool colorBlind;
  final bool leftHanded;

  Settings copyWith({
    bool? voice,
    bool? sounds,
    AnimationSpeed? speed,
    bool? colorBlind,
    bool? leftHanded,
  }) => Settings(
    voice: voice ?? this.voice,
    sounds: sounds ?? this.sounds,
    speed: speed ?? this.speed,
    colorBlind: colorBlind ?? this.colorBlind,
    leftHanded: leftHanded ?? this.leftHanded,
  );
}

class SettingsNotifier extends Notifier<Settings> {
  @override
  Settings build() {
    final p = ref.watch(prefsProvider);
    return Settings(
      voice: p.getBool('voice') ?? true,
      sounds: p.getBool('sounds') ?? true,
      speed: AnimationSpeed.values.firstWhere(
        (s) => s.name == p.getString('speed'),
        orElse: () => AnimationSpeed.normal,
      ),
      colorBlind: p.getBool('colorBlind') ?? false,
      leftHanded: p.getBool('leftHanded') ?? false,
    );
  }

  void update(Settings s) {
    final p = ref.read(prefsProvider);
    p.setBool('voice', s.voice);
    p.setBool('sounds', s.sounds);
    p.setString('speed', s.speed.name);
    p.setBool('colorBlind', s.colorBlind);
    p.setBool('leftHanded', s.leftHanded);
    state = s;
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, Settings>(
  SettingsNotifier.new,
);
