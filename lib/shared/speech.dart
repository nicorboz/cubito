// Voix française : lit les consignes à voix haute, hors ligne. Respecte le
// réglage « voix ».
//
// Les phrases de l'appli sont enregistrées à l'avance avec la voix
// « Pulcherrima » (assets/voice/, préparées par tool/voice/generate.py).
// Une phrase qui n'a pas d'enregistrement (ex. un temps au chrono) est lue
// par la synthèse vocale du téléphone.
import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'settings.dart';

abstract class Speech {
  Future<void> speak(String text);
  Future<void> stop();
}

/// Voix du téléphone. Si elle n'est pas disponible, l'appli reste muette
/// sans planter.
class DeviceSpeech implements Speech {
  FlutterTts? _tts;
  bool _broken = false;

  Future<FlutterTts?> _engine() async {
    if (_broken) return null;
    if (_tts != null) return _tts;
    try {
      final tts = FlutterTts();
      await tts.setLanguage('fr-FR');
      await tts.setSpeechRate(0.45); // un peu lent, pour les enfants
      await tts.setPitch(1.1);
      _tts = tts;
      return tts;
    } catch (_) {
      _broken = true;
      return null;
    }
  }

  @override
  Future<void> speak(String text) async {
    try {
      final tts = await _engine();
      await tts?.stop();
      await tts?.speak(text);
    } catch (_) {}
  }

  @override
  Future<void> stop() async {
    try {
      await _tts?.stop();
    } catch (_) {}
  }
}

/// Normalisation du texte pour retrouver son enregistrement (identique à
/// `normalize` dans tool/voice/generate.py).
String voiceKey(String text) => text
    .replaceAll('\u00a0', ' ')
    .replaceAll('\u202f', ' ')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

/// Voix enregistrée (Pulcherrima), avec la voix du téléphone en secours.
class RecordedSpeech implements Speech {
  RecordedSpeech(this.fallback);

  final Speech fallback;
  AudioPlayer? _player;
  Map<String, String>? _files;
  bool _broken = false;

  Future<Map<String, String>> _index() async {
    if (_files != null) return _files!;
    try {
      final raw = await rootBundle.loadString('assets/voice/index.json');
      final files = (jsonDecode(raw) as Map<String, dynamic>)['files'] as Map;
      _files = files.map((k, v) => MapEntry(k as String, v as String));
    } catch (_) {
      _files = const {};
    }
    return _files!;
  }

  Future<AudioPlayer> _audio() async {
    if (_player != null) return _player!;
    final p = AudioPlayer();
    // Ne coupe pas les petits bruitages de récompense joués en même temps.
    await p.setAudioContext(
      AudioContextConfig(focus: AudioContextConfigFocus.mixWithOthers).build(),
    );
    return _player = p;
  }

  @override
  Future<void> speak(String text) async {
    final file = (await _index())[voiceKey(text)];
    if (file == null || _broken) {
      await _player?.stop();
      return fallback.speak(text);
    }
    try {
      await fallback.stop();
      final p = await _audio();
      await p.stop();
      await p.play(AssetSource('voice/$file'));
    } catch (_) {
      _broken = true; // on bascule sur la voix du téléphone
      await fallback.speak(text);
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _player?.stop();
    } catch (_) {}
    await fallback.stop();
  }
}

/// Voix muette (tests, ou réglage « voix » désactivé).
class SilentSpeech implements Speech {
  @override
  Future<void> speak(String text) async {}
  @override
  Future<void> stop() async {}
}

final deviceSpeechProvider = Provider<Speech>(
  (ref) => RecordedSpeech(DeviceSpeech()),
);

/// La voix à utiliser, selon le réglage.
final speechProvider = Provider<Speech>((ref) {
  final on = ref.watch(settingsProvider.select((s) => s.voice));
  return on ? ref.watch(deviceSpeechProvider) : SilentSpeech();
});
