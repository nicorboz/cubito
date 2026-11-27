// Patron déplié du cube (croix) : aperçu de la saisie et des erreurs.
import 'package:material_ui/material_ui.dart';

import '../../core/cube/cube.dart';
import '../../shared/theme.dart';
import '../../shared/widgets/sticker.dart';

/// Position (colonne, ligne) de chaque face dans la croix 4 × 3.
const netPosition = <Face, (int, int)>{
  Face.u: (1, 0),
  Face.l: (0, 1),
  Face.f: (1, 1),
  Face.r: (2, 1),
  Face.b: (3, 1),
  Face.d: (1, 2),
};

class CubeNet extends StatelessWidget {
  const CubeNet({
    super.key,
    required this.colors,
    this.currentFace,
    this.suspects = const {},
    this.pulse = 0,
    this.onFaceTap,
    this.width = 240,
  });

  final List<CubeColor?> colors;
  final Face? currentFace;
  final Set<int> suspects;
  final double pulse;
  final ValueChanged<Face>? onFaceTap;
  final double width;

  @override
  Widget build(BuildContext context) {
    final cell = width / 12;
    return SizedBox(
      width: width,
      height: cell * 9,
      child: Stack(
        children: [
          for (final face in Face.values)
            Positioned(
              left: netPosition[face]!.$1 * cell * 3,
              top: netPosition[face]!.$2 * cell * 3,
              child: GestureDetector(
                onTap: onFaceTap == null ? null : () => onFaceTap!(face),
                child: Container(
                  padding: const EdgeInsets.all(1.5),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: face == currentFace
                          ? CubeColors.ink
                          : Colors.transparent,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: SizedBox(
                    width: cell * 3 - 7,
                    height: cell * 3 - 7,
                    child: GridView.count(
                      crossAxisCount: 3,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      mainAxisSpacing: 1.5,
                      crossAxisSpacing: 1.5,
                      children: [
                        for (var k = 0; k < 9; k++)
                          StickerCell(
                            color: colors[face.index * 9 + k],
                            size: cell - 3,
                            highlight: suspects.contains(face.index * 9 + k)
                                ? (0.4 + 0.6 * pulse)
                                : 0,
                          ),
                      ],
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
