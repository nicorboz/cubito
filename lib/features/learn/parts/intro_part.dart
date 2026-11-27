// Partie 1 « Regarde » : à quoi sert la formule (étape, avant → après) et
// la formule elle-même, geste par geste.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../l10n/app_localizations.dart';
import '../../../render/flat_cube.dart';
import '../../../shared/gesture_text.dart';
import '../../../shared/settings.dart';
import '../../../shared/speech.dart';
import '../../guide/guided_player.dart';
import '../lesson_examples.dart';
import '../lessons.dart';
import 'common.dart';

class IntroPart extends ConsumerStatefulWidget {
  const IntroPart({
    super.key,
    required this.lesson,
    required this.situation,
    required this.onNext,
  });
  final Lesson lesson;
  final Situation situation;
  final VoidCallback onNext;

  @override
  ConsumerState<IntroPart> createState() => _IntroPartState();
}

class _IntroPartState extends ConsumerState<IntroPart> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(speechProvider)
          .speak(widget.lesson.goal(AppLocalizations.of(context)));
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final lesson = widget.lesson;
    final symbols = ref.watch(settingsProvider.select((s) => s.colorBlind));
    final moves = lesson.moves;

    Widget pic(String label, Widget cube) => Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: lesson.color,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 8),
          cube,
        ],
      ),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: lesson.color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  lesson.when(l),
                  textAlign: TextAlign.center,
                  style: t.titleSmall?.copyWith(
                    color: lesson.color,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                lesson.goal(l),
                textAlign: TextAlign.center,
                style: t.titleLarge,
              ),
              if (lesson.kind != LessonKind.basics) ...[
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    pic(
                      l.goalBefore,
                      FlatCube(
                        cube: widget.situation.start,
                        style: FlatStyle.colors,
                        animate: false,
                        symbols: symbols,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(top: 70),
                      child: Icon(Icons.arrow_forward_rounded, size: 36),
                    ),
                    pic(
                      l.goalAfter,
                      FlatCube(
                        cube: widget.situation.end,
                        style: FlatStyle.colors,
                        animate: false,
                        symbols: symbols,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 18),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${lesson.emoji()} ${lesson.kind == LessonKind.basics ? l.lessonGestures : l.lessonFormula}',
                  style: t.titleLarge,
                ),
              ),
              const SizedBox(height: 8),
              // La formule en cartes numérotées (4 par ligne).
              for (var row = 0; row < moves.length; row += 4)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      for (var k = row; k < row + 4; k++)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: k < moves.length
                                ? MiniGestureCard(move: moves[k], number: k + 1)
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
              const SizedBox(height: 16),
              NextButton(onTap: widget.onNext),
            ],
          ),
        ),
      ),
    );
  }
}
