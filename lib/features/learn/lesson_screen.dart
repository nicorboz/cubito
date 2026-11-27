// Une leçon du parcours = une formule, en 3 parties :
// 1. Regarde · 2. Pas à pas (les gestes, un par un) · 3. Fiche.
// On n'a pas besoin du vrai cube : on regarde et on retient.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';
import '../../shared/gesture_text.dart';
import '../../shared/mascot/cubi_avatar.dart';
import '../../shared/progress.dart';
import '../../shared/speech.dart';
import '../../shared/theme.dart';
import '../../shared/widgets/confetti.dart';
import '../../shared/widgets/pill_button.dart';
import '../guide/guide_cards.dart';
import '../guide/guided_player.dart';
import 'lesson_examples.dart';
import 'lessons.dart';
import 'parts/common.dart';
import 'parts/intro_part.dart';
import 'parts/memo_part.dart';

class LessonScreen extends ConsumerStatefulWidget {
  const LessonScreen({super.key, required this.lesson});
  final Lesson lesson;

  @override
  ConsumerState<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends ConsumerState<LessonScreen> {
  int _part = 0;
  int _run = 0;
  late final Situation _situation = lessonSituation(widget.lesson);
  late final List<GuideCard> _cards = buildCards(
    _situation.start,
    _situation.actions,
  );

  /// Gardée de côté pour pouvoir couper la voix dans dispose().
  late final Speech _voice;

  @override
  void initState() {
    super.initState();
    _voice = ref.read(deviceSpeechProvider);
  }

  void _goTo(int part) {
    ref.read(speechProvider).stop();
    setState(() {
      _part = part;
      if (part == 1) _run++;
    });
  }

  @override
  void dispose() {
    _voice.stop();
    super.dispose();
  }

  /// Fin du pas à pas : la leçon est vue (ouvre la suivante) et Cubito dit
  /// le texte affiché.
  void _finished() {
    ref.read(progressProvider.notifier).recordStars(widget.lesson.index, 3);
    ref.read(speechProvider).speak(AppLocalizations.of(context).stepsDone);
  }

  void _nextLesson() {
    final i = widget.lesson.index + 1;
    if (i >= lessons.length) {
      Navigator.of(context).pop();
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => LessonScreen(lesson: lessons[i])),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lesson = widget.lesson;

    final body = switch (_part) {
      0 => IntroPart(
        key: const ValueKey(0),
        lesson: lesson,
        situation: _situation,
        onNext: () => _goTo(1),
      ),
      1 => GuidedPlayer(
        key: ValueKey('steps$_run'),
        cards: _cards,
        color: lesson.color,
        onFinished: _finished,
        done: _LessonDone(
          lesson: lesson,
          onReplay: () => _goTo(1),
          onMemo: () => _goTo(2),
          onNext: _nextLesson,
        ),
      ),
      _ => MemoPart(key: const ValueKey(2), lesson: lesson),
    };

    return Scaffold(
      appBar: AppBar(
        title: Text('${lesson.emoji()} ${lesson.title(l)}'),
        leading: IconButton(
          tooltip: l.back,
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _PartTabs(current: _part, color: lesson.color, onTap: _goTo),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: body,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fin de la leçon : Cubito saute, rappel de la formule qu'on vient de voir,
/// et la suite (revoir, fiche, leçon suivante).
class _LessonDone extends StatelessWidget {
  const _LessonDone({
    required this.lesson,
    required this.onReplay,
    required this.onMemo,
    required this.onNext,
  });
  final Lesson lesson;
  final VoidCallback onReplay;
  final VoidCallback onMemo;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final moves = lesson.moves;
    final isLast = lesson.index == lessons.length - 1;
    return Stack(
      children: [
        LayoutBuilder(
          builder: (context, c) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: c.maxHeight - 28),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      CubiAvatar(
                        size: (c.maxHeight * 0.3).clamp(140.0, 240.0),
                        mood: CubiMood.rire,
                        jumpOnShow: true,
                      ),
                      Text(
                        l.stepsDone,
                        textAlign: TextAlign.center,
                        style: t.headlineMedium,
                      ),
                      const SizedBox(height: 16),
                      // Rappel : la formule qu'on vient de voir.
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: lesson.color.withValues(alpha: 0.35),
                            width: 3,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              l.lessonYouSaw,
                              style: t.bodyMedium?.copyWith(
                                color: CubeColors.ink.withValues(alpha: 0.7),
                              ),
                            ),
                            Text(
                              '${lesson.emoji()} ${lesson.title(l)}',
                              textAlign: TextAlign.center,
                              style: t.titleLarge?.copyWith(
                                color: lesson.color,
                              ),
                            ),
                            const SizedBox(height: 10),
                            for (var row = 0; row < moves.length; row += 4)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    for (var k = row; k < row + 4; k++)
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 3,
                                          ),
                                          child: k < moves.length
                                              ? MiniGestureCard(
                                                  move: moves[k],
                                                  number: k + 1,
                                                )
                                              : const SizedBox(),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            if (lesson.kind == LessonKind.formula)
                              Text(
                                '${l.formulaSing} ${formulaChant(l, moves)}',
                                textAlign: TextAlign.center,
                                style: t.titleMedium,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        alignment: WrapAlignment.center,
                        children: [
                          PillButton(
                            icon: Icons.replay_rounded,
                            label: l.lessonReplay,
                            color: lesson.color,
                            onTap: onReplay,
                          ),
                          PillButton(
                            icon: Icons.description_rounded,
                            label: l.partMemo,
                            color: CubeColors.solve,
                            onTap: onMemo,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      NextButton(
                        label: isLast ? l.backToMap : l.lessonNext,
                        onTap: onNext,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const Positioned.fill(child: IgnorePointer(child: Confetti())),
      ],
    );
  }
}

/// Les 3 pastilles des parties de la leçon (on peut revenir à tout moment).
class _PartTabs extends StatelessWidget {
  const _PartTabs({
    required this.current,
    required this.color,
    required this.onTap,
  });
  final int current;
  final Color color;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final labels = [l.partGoal, l.partSteps, l.partMemo];
    const icons = [
      Icons.movie_rounded,
      Icons.directions_walk_rounded,
      Icons.description_rounded,
    ];
    // Onglet actif : icône + nom ; les autres : icône seule (nom lu par
    // TalkBack et affiché en info-bulle). Tient sur les petits écrans.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              flex: i == current ? 3 : 1,
              child: Tooltip(
                message: labels[i],
                child: Semantics(
                  button: true,
                  selected: i == current,
                  label: labels[i],
                  excludeSemantics: true,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(28),
                    onTap: () => onTap(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      height: 56,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: i == current
                            ? color
                            : color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            icons[i],
                            size: 26,
                            color: i == current ? Colors.white : color,
                          ),
                          if (i == current) ...[
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                labels[i],
                                maxLines: 1,
                                overflow: TextOverflow.fade,
                                softWrap: false,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
