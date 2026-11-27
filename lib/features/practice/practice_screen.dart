// Mode « S'entraîner » : cube virtuel libre. Mélanger, annuler, tourner le
// cube, chrono optionnel et indice « quelle étape maintenant ? ».
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/cube/cube.dart';
import '../../core/cube/solver.dart';
import '../../core/method/method.dart';
import '../../l10n/app_localizations.dart';
import '../../render/cube_controller.dart';
import '../../shared/move_text.dart';
import '../../shared/settings.dart';
import '../../shared/speech.dart';
import '../../shared/stats.dart';
import '../../shared/theme.dart';
import '../../shared/widgets/confetti.dart';
import '../../shared/widgets/cube_layout.dart';
import '../../shared/widgets/pill_button.dart';
import '../guide/hint_sheet.dart';
import '../learn/islands.dart';
import '../../shared/widgets/app_cube_view.dart';
import '../../shared/sounds.dart';
import '../../shared/mascot/cubi_avatar.dart';

/// Où en est le cube ? Renvoie l'étape à faire (null si résolu).
/// Indépendant de l'orientation du cube.
MethodStep? currentStep(Cube c) {
  if (c.isSolved) return null;
  if (!isWhiteCrossFormed(c)) return MethodStep.croixBlanche;
  if (!isWhiteCrossDone(c)) return MethodStep.aretesCroix;
  if (!isFirstLayerDone(c)) return MethodStep.coinsBlancs;
  if (!isSecondLayerDone(c)) {
    return c.center(Face.u) == CubeColor.white
        ? MethodStep.retourner
        : MethodStep.deuxiemeCouronne;
  }
  if (!isYellowCrossFormed(c)) return MethodStep.etoileJaune;
  if (!isYellowEdgesDone(c)) return MethodStep.aretesJaunes;
  if (!isYellowCornersPlaced(c)) return MethodStep.placerCoinsJaunes;
  return MethodStep.tournerCoinsJaunes;
}

/// Mise en forme d'un temps (« 1:05 »).
String formatTime(Duration d) =>
    '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

class PracticeScreen extends ConsumerStatefulWidget {
  const PracticeScreen({super.key});

  @override
  ConsumerState<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends ConsumerState<PracticeScreen> {
  late final _cube = CubeController()
    ..quarterTurnDuration = Duration(
      milliseconds: ref.read(settingsProvider).speed.quarterTurnMs,
    );
  final _history = <Move>[];
  String? _info;
  bool _scrambled = false;
  bool _celebrate = false;

  // Chrono.
  bool _timerOn = false;
  final _watch = Stopwatch();
  Timer? _ticker;

  @override
  void dispose() {
    _ticker?.cancel();
    _cube.dispose();
    super.dispose();
  }

  Future<void> _play(Move m, {bool record = true}) async {
    if (_cube.isAnimating) return;
    if (record) _history.add(m);
    _cube.arrow = null;
    if (_timerOn && _scrambled && !_watch.isRunning && !m.kind.isRotation) {
      _watch.start();
      _ticker = Timer.periodic(
        const Duration(milliseconds: 250),
        (_) => setState(() {}),
      );
    }
    setState(() => _info = moveLabel(AppLocalizations.of(context), m));
    await _cube.play([m]);
    if (_scrambled && _cube.cube.isSolved && mounted) _onSolved();
  }

  void _onSolved() {
    final l = AppLocalizations.of(context);
    HapticFeedback.heavyImpact();
    ref.read(soundsProvider).play(Sfx.success);
    _watch.stop();
    _ticker?.cancel();
    final time = _timerOn ? _watch.elapsed : null;
    ref
        .read(statsProvider.notifier)
        .addVirtualSolve(timeMs: time?.inMilliseconds);
    final msg = time != null
        ? l.practiceSolvedIn(formatTime(time))
        : l.solvedBravo;
    ref.read(speechProvider).speak(msg);
    setState(() {
      _scrambled = false;
      _celebrate = true;
      _info = '🎉 $msg';
    });
  }

  void _resetTimer() {
    _watch
      ..stop()
      ..reset();
    _ticker?.cancel();
  }

  void _scramble() {
    _cube.jumpTo(Cube.solved().apply(randomScramble()));
    _cube.arrow = null;
    _resetTimer();
    setState(() {
      _history.clear();
      _info = null;
      _scrambled = true;
      _celebrate = false;
    });
  }

  void _undo() {
    if (_history.isEmpty || _cube.isAnimating) return;
    _play(_history.removeLast().inverse, record: false);
  }

  void _restart() {
    _cube.jumpTo(Cube.solved());
    _cube.arrow = null;
    _resetTimer();
    setState(() {
      _history.clear();
      _info = null;
      _scrambled = false;
      _celebrate = false;
    });
  }

  /// Indice : quelle étape maintenant, et le prochain geste.
  void _hint() {
    final l = AppLocalizations.of(context);
    final c = _cube.cube;
    final step = currentStep(c);
    if (step == null) {
      setState(() => _info = l.practiceAlreadySolved);
      ref.read(speechProvider).speak(l.practiceAlreadySolved);
      return;
    }
    final island = islands.firstWhere((i) => i.steps.contains(step));
    var text = l.practiceStepIs(island.number, island.title(l));
    // La méthode tient le cube blanc en haut jusqu'à l'étape 3, jaune ensuite.
    final needsWhiteUp = step.index <= MethodStep.retourner.index;
    final whiteUp = c.center(Face.u) == CubeColor.white;
    if (needsWhiteUp != whiteUp) {
      text =
          '$text. ${needsWhiteUp ? l.practiceFlipWhiteUp : l.practiceFlipYellowUp}';
      _cube.arrow = Move.parse('x2');
    } else {
      try {
        final sol = solveSteps(c, from: step);
        setState(() => _info = text);
        // Les cartes de la prochaine action, comme dans le livret.
        showHintSheet(context, c, sol.actions.first);
        return;
      } on SolverException {
        _cube.arrow = null;
      }
    }
    setState(() => _info = text);
    ref.read(speechProvider).speak(text);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final info = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_celebrate)
          const CubiAvatar(size: 110, mood: CubiMood.rire, jumpOnShow: true),
        if (_timerOn)
          Text('⏱ ${formatTime(_watch.elapsed)}', style: t.headlineMedium),
        Text(
          _info ?? l.practiceHelp,
          textAlign: TextAlign.center,
          style: t.titleMedium,
        ),
        if (_info == null)
          Text(
            l.practiceHelpOrbit,
            textAlign: TextAlign.center,
            style: t.bodyMedium,
          ),
      ],
    );
    final buttons = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 10,
          runSpacing: 10,
          children: [
            PillButton(
              compact: true,
              icon: Icons.shuffle_rounded,
              label: l.scramble,
              color: CubeColors.practice,
              onTap: _scramble,
            ),
            PillButton(
              compact: true,
              icon: Icons.undo_rounded,
              label: l.undo,
              color: CubeColors.solve,
              onTap: _history.isEmpty ? null : _undo,
            ),
            PillButton(
              compact: true,
              icon: Icons.lightbulb_rounded,
              label: l.practiceWhichStep,
              color: const Color(0xFFE6A100),
              onTap: _hint,
            ),
            PillButton(
              compact: true,
              icon: _timerOn ? Icons.timer_rounded : Icons.timer_off_rounded,
              label: l.timer,
              color: _timerOn ? CubeColors.learn : const Color(0xFF8C8399),
              onTap: () => setState(() {
                _timerOn = !_timerOn;
                if (!_timerOn) _resetTimer();
              }),
            ),
            PillButton(
              compact: true,
              icon: Icons.restart_alt_rounded,
              label: l.restart,
              color: CubeColors.trophies,
              onTap: _restart,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 10,
          children: [
            PillButton(
              compact: true,
              icon: Icons.rotate_left_rounded,
              label: l.turnLeft,
              color: CubeColors.ink,
              onTap: () => _play(Move.parse('y')),
            ),
            PillButton(
              compact: true,
              icon: Icons.flip_rounded,
              label: l.flipCube,
              color: CubeColors.ink,
              onTap: () => _play(Move.parse('x2')),
            ),
            PillButton(
              compact: true,
              icon: Icons.rotate_right_rounded,
              label: l.turnRight,
              color: CubeColors.ink,
              onTap: () => _play(Move.parse("y'")),
            ),
          ],
        ),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(l.tilePractice),
        leading: IconButton(
          tooltip: l.back,
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            CubeLayout(
              cube: AppCubeView(
                controller: _cube,
                onSwipeMove: _play,
                semanticLabel: l.cubeLabel,
              ),
              panel: Column(
                mainAxisSize: MainAxisSize.min,
                children: [info, const SizedBox(height: 12), buttons],
              ),
            ),
            if (_celebrate) const Positioned.fill(child: Confetti()),
          ],
        ),
      ),
    );
  }
}
