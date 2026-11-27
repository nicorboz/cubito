// Liste toutes les phrases que l'appli peut dire à voix haute, pour préparer
// les voix enregistrées (tool/voice/generate.py). Lancement :
//   VOICE_DUMP=build/voice_lines.json flutter test test/tool/voice_lines_test.dart
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cube_magique/core/cube/cube.dart';
import 'package:cube_magique/core/cube/solver.dart';
import 'package:cube_magique/core/method/method.dart';
import 'package:cube_magique/core/scan/scan_plan.dart';
import 'package:cube_magique/features/guide/guide_cards.dart';
import 'package:cube_magique/features/guide/guided_player.dart';
import 'package:cube_magique/features/learn/islands.dart';
import 'package:cube_magique/features/learn/lesson_examples.dart';
import 'package:cube_magique/features/scan/scan_screen.dart';
import 'package:cube_magique/l10n/app_localizations.dart';
import 'package:cube_magique/shared/color_text.dart';
import 'package:cube_magique/shared/gesture_text.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final out = Platform.environment['VOICE_DUMP'];
  test('liste des phrases', () {
    final l = lookupAppLocalizations(const Locale('fr'));
    final lines = <String>{};
    void cards(List<GuideCard> cs) {
      for (final c in cs) {
        lines.add(cardSpeech(l, c));
      }
    }

    // Accueil
    lines.add('${l.homeGreeting} ${l.homeSubtitle}');
    // Cartes du livret : leçons, défis, résolution complète, indices.
    final rnd = Random(7);
    for (final island in islands) {
      lines.add(island.goal(l));
      final ex = exampleSituation(island);
      cards(buildCards(ex.start, ex.actions));
      for (var k = 0; k < 150; k++) {
        final s = randomSituation(island, rnd);
        cards(buildCards(s.start, s.actions));
        for (final a in s.actions) {
          cards(buildCards(s.start, [a], checks: false));
        }
      }
    }
    const hold = SolveAction(
      step: MethodStep.croixBlanche,
      type: ActionType.rotateCube,
      moves: [],
      hint: SolveHint.retournerJauneEnHaut,
    );
    for (var k = 0; k < 400; k++) {
      final c = Cube.solved().apply(randomScramble(random: rnd));
      final sol = solveBeginner(c);
      cards(buildCards(c, [hold, ...sol.actions]));
    }
    // Tous les gestes possibles (même ceux que le hasard n'a pas tirés).
    for (final f in ['U', 'D', 'R', 'L', 'F', 'B']) {
      for (final suffix in ['', "'", '2']) {
        final w = gestureWords(l, Move.parse('$f$suffix'));
        lines.add('${w.verb.toLowerCase()} ${w.object}.');
      }
    }
    // « Tiens ton cube comme ça » pour toutes les tenues possibles (chemin
    // le plus court : le cube reste tenu comme au scan).
    for (final top in CubeColor.values) {
      for (final front in CubeColor.values) {
        if (top == front) continue;
        lines.add(
          '${l.placeTitle}. ${l.onTop(colorName(l, top))}, ${l.inFront(colorName(l, front))}.',
        );
      }
    }
    // Saisie, scan, s'entraîner.
    for (final c in CubeColor.values) {
      lines.add(l.errTooMany(colorName(l, c)));
      lines.add(l.errPiece(faceName(l, c)));
      lines.add(l.scanRedoFace(faceName(l, c)));
      for (final t in CubeColor.values) {
        if (t != c) {
          lines.add(l.scanShowCenter(colorName(l, c), colorName(l, t)));
        }
      }
    }
    for (final g in ScanGesture.values) {
      lines.add(gestureText(l, g));
    }
    for (final island in islands) {
      final t = l.practiceStepIs(island.number, island.title(l));
      lines.add(t);
      lines.add('$t. ${l.practiceFlipWhiteUp}');
      lines.add('$t. ${l.practiceFlipYellowUp}');
    }
    if (out != null) {
      File(out)
        ..createSync(recursive: true)
        ..writeAsStringSync(
          const JsonEncoder.withIndent(' ').convert(lines.toList()..sort()),
        );
    }
    expect(lines.length, greaterThan(50));
  });
}
