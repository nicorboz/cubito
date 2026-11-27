// Sons courts de récompense (embarqués), selon le réglage « sons ».
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'settings.dart';

enum Sfx {
  bip('bip.wav'),
  success('success.wav'),
  tick('tick.wav'),
  oops('oops.wav');

  const Sfx(this.file);
  final String file;
}

abstract class SoundPlayer {
  Future<void> play(Sfx s);
}

class DeviceSounds implements SoundPlayer {
  final _player = AudioPlayer();
  bool _broken = false;

  @override
  Future<void> play(Sfx s) async {
    if (_broken) return;
    try {
      await _player.stop();
      await _player.play(
        AssetSource('sounds/${s.file}'),
        mode: PlayerMode.lowLatency,
      );
    } catch (_) {
      _broken = true; // pas de son plutôt qu'un plantage
    }
  }
}

class SilentSounds implements SoundPlayer {
  @override
  Future<void> play(Sfx s) async {}
}

final deviceSoundsProvider = Provider<SoundPlayer>((ref) => DeviceSounds());

final soundsProvider = Provider<SoundPlayer>((ref) {
  final on = ref.watch(settingsProvider.select((s) => s.sounds));
  return on ? ref.watch(deviceSoundsProvider) : SilentSounds();
});
