// Les phrases de l'appli ont bien un enregistrement de la voix.
import 'dart:convert';
import 'dart:io';

import 'package:cube_magique/l10n/app_localizations.dart';
import 'package:cube_magique/shared/speech.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final index =
      (jsonDecode(File('assets/voice/index.json').readAsStringSync())
              as Map<String, dynamic>)['files']
          as Map<String, dynamic>;

  test('chaque enregistrement existe', () {
    for (final f in index.values) {
      expect(File('assets/voice/$f').existsSync(), isTrue, reason: f as String);
    }
  });

  test('les phrases principales sont enregistrées', () {
    final l = lookupAppLocalizations(const Locale('fr'));
    for (final t in [
      '${l.homeGreeting} ${l.homeSubtitle}',
      l.solveFinished,
      l.checkRetry,
      l.challengeAllDone,
      l.voiceSample,
      l.inputHoldU,
      l.lessonBasicsGoal,
      l.stepsDone,
      l.cubeTwistedCorner,
      l.cubeFlippedEdge,
      l.cubeSwappedPieces,
      for (final t in ['jaune', 'rouge', 'bleu'])
        '${l.placeTitle}. ${l.onTop(t)}, ${l.inFront('vert')}.',
    ]) {
      expect(index.containsKey(voiceKey(t)), isTrue, reason: t);
    }
  });
}
