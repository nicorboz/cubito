// Le parcours des formules, dans l'ordre de la résolution : on débloque
// la leçon suivante en réussissant la précédente (partie « Par cœur »).
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';
import '../../shared/progress.dart';
import '../../shared/theme.dart';
import 'lessons.dart';
import 'lesson_screen.dart';

class LearnScreen extends ConsumerWidget {
  const LearnScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final progress = ref.watch(progressProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.learnMapTitle),
        leading: IconButton(
          tooltip: l.back,
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                l.lessonSeenCount(
                  [for (var i = 0; i < lessons.length; i++) i]
                      .where(progress.isDone)
                      .length,
                  lessons.length,
                ),
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          itemCount: lessons.length,
          itemBuilder: (context, i) {
            final lesson = lessons[i];
            final unlocked = progress.isUnlocked(i);
            return _LessonTile(
              lesson: lesson,
              unlocked: unlocked,
              stars: progress.stars[i],
              alignRight: i.isOdd,
              onTap: () {
                if (!unlocked) {
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      SnackBar(
                        content: Text(
                          l.learnLocked,
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                    );
                  return;
                }
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => LessonScreen(lesson: lesson),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _LessonTile extends StatelessWidget {
  const _LessonTile({
    required this.lesson,
    required this.unlocked,
    required this.stars,
    required this.alignRight,
    required this.onTap,
  });

  final Lesson lesson;
  final bool unlocked;
  final int stars;
  final bool alignRight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final color = unlocked ? lesson.color : const Color(0xFFBDB6C8);
    final circle = Container(
      width: 84,
      height: 84,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.45),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: unlocked
          ? Text(
              '${lesson.number}',
              style: const TextStyle(
                fontSize: 38,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.lock_rounded, color: Colors.white, size: 36),
    );
    final text = Column(
      crossAxisAlignment: alignRight
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          lesson.when(l),
          textAlign: alignRight ? TextAlign.right : TextAlign.left,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        Text(
          '${lesson.emoji()} ${lesson.title(l)}',
          textAlign: alignRight ? TextAlign.right : TextAlign.left,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: unlocked
                ? CubeColors.ink
                : CubeColors.ink.withValues(alpha: 0.45),
          ),
        ),
        if (stars > 0)
          Text(
            l.lessonLearned,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: CubeColors.learn,
              fontWeight: FontWeight.w800,
            ),
          ),
      ],
    );
    return Semantics(
      button: true,
      label:
          '${l.lessonNumber(lesson.number)}, ${lesson.title(l)}, ${lesson.when(l)}',
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          child: Row(
            textDirection: alignRight ? TextDirection.rtl : TextDirection.ltr,
            children: [
              circle,
              const SizedBox(width: 16),
              Expanded(child: text),
            ],
          ),
        ),
      ),
    );
  }
}
