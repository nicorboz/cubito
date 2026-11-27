// Mise en page commune : le cube 3D en grand + un panneau de consignes.
// Portrait : cube en haut ; paysage : cube à gauche.
import 'package:material_ui/material_ui.dart';

class CubeLayout extends StatelessWidget {
  const CubeLayout({
    super.key,
    required this.cube,
    required this.panel,
    this.top,
  });

  final Widget cube;
  final Widget panel;

  /// Bandeau optionnel au-dessus du cube (consigne courte).
  final Widget? top;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth > c.maxHeight) {
          return Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    ?top,
                    Expanded(child: cube),
                  ],
                ),
              ),
              SizedBox(
                width: (c.maxWidth * 0.42).clamp(280.0, 520.0),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(8, 12, 16, 12),
                  child: panel,
                ),
              ),
            ],
          );
        }
        return Column(
          children: [
            ?top,
            Expanded(child: cube),
            // Le panneau ne prend jamais plus de 60 % de la hauteur : au-delà,
            // il défile (petits téléphones).
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: c.maxHeight * 0.6),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: panel,
              ),
            ),
          ],
        );
      },
    );
  }
}
