// Indice : les cartes de la prochaine action, dans une feuille qui monte
// du bas de l'écran (défis, s'entraîner).
import 'package:material_ui/material_ui.dart';

import '../../core/cube/cube.dart';
import '../../core/cube/solver.dart';
import '../../l10n/app_localizations.dart';
import '../learn/parts/common.dart';
import 'guide_cards.dart';
import 'guided_player.dart';
import '../../shared/mascot/cubi_avatar.dart';

Future<void> showHintSheet(
  BuildContext context,
  Cube cube,
  SolveAction action, {
  Color color = const Color(0xFF8B5CF6),
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: const Color(0xFFFFF8EC),
    builder: (ctx) => SizedBox(
      height: MediaQuery.of(ctx).size.height * 0.86,
      child: Column(
        children: [
          // Cubito fait un clin d'œil : c'est un petit secret entre nous.
          CubiSays(
            mood: CubiMood.clin,
            message: AppLocalizations.of(ctx).hint,
            size: 64,
            style: Theme.of(ctx).textTheme.titleLarge,
          ),
          Expanded(
            child: GuidedPlayer(
              cards: buildCards(cube, [action], checks: false),
              color: color,
              done: Center(
                child: NextButton(
                  label: AppLocalizations.of(ctx).back,
                  onTap: () => Navigator.of(ctx).pop(),
                ),
              ),
              onFinished: () => Navigator.of(ctx).pop(),
            ),
          ),
        ],
      ),
    ),
  );
}
