// Petits widgets partagés par les parties de la leçon.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/method/method.dart';
import '../../../l10n/app_localizations.dart';
import '../../../render/cube_controller.dart';
import '../../../shared/settings.dart';
import '../../../shared/solve_text.dart';
import '../../../shared/theme.dart';
import '../lesson_examples.dart';

/// Crée un contrôleur de cube réglé à la vitesse choisie dans les réglages.
CubeController lessonController(WidgetRef ref, Situation s) {
  final c = CubeController(cube: s.start);
  c.quarterTurnDuration = Duration(
    milliseconds: ref.read(settingsProvider).speed.quarterTurnMs,
  );
  return c;
}

/// Liste numérotée des règles de l'étape.
class RulesList extends StatelessWidget {
  const RulesList({super.key, required this.rules, required this.color});
  final List<String> rules;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < rules.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 15,
                  backgroundColor: color,
                  child: Text(
                    '${i + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    rules[i],
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Bouton principal « Suivant ».
class NextButton extends StatelessWidget {
  const NextButton({super.key, required this.onTap, this.label});
  final VoidCallback? onTap;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return FilledButton.icon(
      onPressed: onTap,
      style: FilledButton.styleFrom(backgroundColor: CubeColors.learn),
      icon: const Icon(Icons.arrow_forward_rounded, size: 28),
      label: Text(label ?? l.next),
    );
  }
}

/// Le nom de l'algorithme d'une action, ou null.
String? algoLabel(AppLocalizations l, Algorithm? a) =>
    a == null ? null : algorithmName(l, a);
