// Le cube 3D avec les réglages de l'appli (symboles du mode daltonien).
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/cube/cube.dart';
import '../../render/cube_controller.dart';
import '../../render/cube_view.dart';
import '../settings.dart';

class AppCubeView extends ConsumerWidget {
  const AppCubeView({
    super.key,
    required this.controller,
    this.onSwipeMove,
    this.onStickerTap,
    this.semanticLabel,
  });

  final CubeController controller;
  final ValueChanged<Move>? onSwipeMove;
  final ValueChanged<int>? onStickerTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CubeView(
      controller: controller,
      onSwipeMove: onSwipeMove,
      onStickerTap: onStickerTap,
      semanticLabel: semanticLabel,
      symbols: ref.watch(settingsProvider.select((s) => s.colorBlind)),
    );
  }
}
