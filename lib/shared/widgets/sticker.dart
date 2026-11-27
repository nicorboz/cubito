// Une case de couleur (saisie, patron) avec symbole optionnel pour le
// mode daltonien.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/cube/cube.dart';
import '../../render/cube_view.dart';
import '../settings.dart';
import '../theme.dart';

/// Symbole de chaque couleur (mode daltonien).
IconData colorSymbol(CubeColor c) => switch (c) {
  CubeColor.white => Icons.circle_outlined,
  CubeColor.yellow => Icons.star_rounded,
  CubeColor.red => Icons.favorite_rounded,
  CubeColor.orange => Icons.change_history_rounded,
  CubeColor.blue => Icons.circle,
  CubeColor.green => Icons.square_rounded,
};

class StickerCell extends ConsumerWidget {
  const StickerCell({
    super.key,
    required this.color,
    this.size = 56,
    this.highlight = 0,
    this.locked = false,
    this.selected = false,
  });

  /// null = case pas encore coloriée.
  final CubeColor? color;
  final double size;

  /// 0 à 1 : intensité du contour clignotant.
  final double highlight;
  final bool locked;
  final bool selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final symbols = ref.watch(settingsProvider.select((s) => s.colorBlind));
    final c = color;
    final border = highlight > 0
        ? Color.lerp(CubeColors.ink, const Color(0xFFFF2D95), highlight)!
        : (selected ? CubeColors.ink : CubeColors.ink.withValues(alpha: 0.25));
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: c == null ? const Color(0xFFEDE6F3) : cubeColorToColor(c),
        borderRadius: BorderRadius.circular(size * 0.18),
        border: Border.all(
          color: border,
          width: highlight > 0 || selected ? 4 : 2,
        ),
      ),
      alignment: Alignment.center,
      child: c == null
          ? Icon(
              Icons.question_mark_rounded,
              size: size * 0.4,
              color: CubeColors.ink.withValues(alpha: 0.3),
            )
          : (locked
                ? Icon(
                    Icons.lock_rounded,
                    size: size * 0.32,
                    color: CubeColors.ink.withValues(alpha: 0.35),
                  )
                : (symbols
                      ? Icon(
                          colorSymbol(c),
                          size: size * 0.45,
                          color: CubeColors.ink.withValues(alpha: 0.55),
                        )
                      : null)),
    );
  }
}
