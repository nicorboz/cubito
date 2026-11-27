// Écran de vérification (obligatoire) après le scan : le cube scanné en 3D,
// « C'est bien ton cube ? ». Les cases douteuses clignotent doucement ; on
// les touche pour choisir la bonne couleur.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/cube/cube.dart';
import '../../core/cube/validation.dart';
import '../../core/scan/classifier.dart';
import '../../core/scan/color_lab.dart';
import '../../core/scan/scan_plan.dart';
import '../../l10n/app_localizations.dart';
import '../../render/cube_controller.dart';
import '../../shared/color_text.dart';
import '../../shared/speech.dart';
import '../../shared/theme.dart';
import '../../shared/widgets/app_cube_view.dart';
import '../../shared/widgets/cube_layout.dart';
import '../../shared/widgets/pill_button.dart';
import '../../shared/widgets/sticker.dart';
import '../../shared/mascot/cubi_avatar.dart';

/// Ce que décide l'enfant sur l'écran de vérification.
sealed class VerifyResult {}

class VerifyConfirmed extends VerifyResult {
  VerifyConfirmed(this.colors);
  final List<CubeColor> colors;
}

class VerifyRedoFace extends VerifyResult {
  VerifyRedoFace(this.step);
  final int step; // indice dans scanPlan
}

/// Tout recommencer (le cube a été réparé à la main).
class VerifyRescan extends VerifyResult {}

/// Message quand les couleurs sont justes mais que le cube a été « bricolé »
/// à la main (coin tourné, arête retournée, pièces échangées) : aucun geste
/// normal ne peut le résoudre. Null pour les autres problèmes.
bool isHandTampered(CubeProblem? p) =>
    p == CubeProblem.twistedCorner ||
    p == CubeProblem.flippedEdge ||
    p == CubeProblem.swappedPieces;

String? handTamperedMessage(AppLocalizations l, CubeProblem? p) => switch (p) {
  CubeProblem.twistedCorner => l.cubeTwistedCorner,
  CubeProblem.flippedEdge => l.cubeFlippedEdge,
  CubeProblem.swappedPieces => l.cubeSwappedPieces,
  _ => null,
};

class VerifyManual extends VerifyResult {
  VerifyManual(this.colors);
  final List<CubeColor> colors;
}

class ScanVerifyScreen extends ConsumerStatefulWidget {
  const ScanVerifyScreen({super.key, required this.faces});

  /// Les 6 faces mesurées, dans l'ordre du plan de scan.
  final List<List<Lab>> faces;

  @override
  ConsumerState<ScanVerifyScreen> createState() => _ScanVerifyScreenState();
}

class _ScanVerifyScreenState extends ConsumerState<ScanVerifyScreen> {
  late final ClassificationResult _result = classifyColors(
    assembleScan(widget.faces),
  );
  // Cube impossible alors que les couleurs semblent justes ? Souvent une
  // face montrée tournée (on la remet dans le bon sens), plus rarement
  // rouge/orange ou blanc/jaune confondus entre deux cases (on les échange
  // et on les fait clignoter pour que l'enfant vérifie).
  late final ({List<CubeColor> colors, Set<int> highlight}) _fixed = () {
    bool valid(List<CubeColor> c) => validateCube(Cube.fromColors(c)).isValid;
    final read = _result.colors;
    final first = validateCube(Cube.fromColors(read));
    if (first.isValid) return (colors: read, highlight: _result.doubtful);
    // Toutes les pièces existent mais le cube a été bricolé à la main :
    // on ne « corrige » rien (ce serait inventer), on l'expliquera.
    if (isHandTampered(first.problem)) {
      return (colors: read, highlight: _result.doubtful);
    }
    final turned = fixScanOrientation(read, valid);
    if (turned != null) return (colors: turned, highlight: <int>{});
    final swapped = fixConfusedPair(read, valid, doubtful: _result.doubtful);
    if (swapped != null) {
      return (colors: swapped.colors, highlight: swapped.changed);
    }
    return (colors: read, highlight: _result.doubtful);
  }();
  late final List<CubeColor> _colors = [..._fixed.colors];
  late final CubeController _cube = CubeController(
    cube: Cube.fromColors(_colors),
  )..highlighted = _fixed.highlight;

  String? _problem;
  int? _redoStep;
  bool _tampered = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(speechProvider)
          .speak(AppLocalizations.of(context).scanVerifyTitle);
    });
  }

  @override
  void dispose() {
    _cube.dispose();
    super.dispose();
  }

  Future<void> _fix(int facelet) async {
    if (facelet % 9 == 4) return; // les centres sont sûrs
    final l = AppLocalizations.of(context);
    final picked = await showModalBottomSheet<CubeColor>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l.scanPickColor,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final c in CubeColor.values)
                    Semantics(
                      button: true,
                      label: colorName(l, c),
                      child: GestureDetector(
                        onTap: () => Navigator.pop(ctx, c),
                        child: StickerCell(
                          color: c,
                          size: 64,
                          selected: c == _colors[facelet],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (picked == null) return;
    setState(() {
      _colors[facelet] = picked;
      _problem = null;
      _tampered = false;
    });
    _cube.jumpTo(Cube.fromColors(_colors));
    _cube.highlighted = {..._cube.highlighted}..remove(facelet);
  }

  void _confirm() {
    final l = AppLocalizations.of(context);
    final cube = Cube.fromColors(_colors);
    final r = validateCube(cube);
    if (r.isValid) {
      Navigator.of(context).pop(VerifyConfirmed(_colors));
      return;
    }
    // Cube démonté / coin tourné à la main : refaire une face ne servirait
    // à rien, on explique et on propose de tout recommencer une fois réparé.
    final tampered = handTamperedMessage(l, r.problem);
    if (tampered != null) {
      ref.read(speechProvider).speak(tampered);
      setState(() {
        _problem = tampered;
        _redoStep = null;
        _tampered = true;
      });
      return;
    }
    // On ne dit pas « erreur » : on propose de refaire une seule face.
    final face = r.suspectFacelets.isEmpty
        ? Face.f
        : Face.values[r.suspectFacelets.first ~/ 9];
    final center = cube.center(face);
    final step = scanPlan.indexWhere((s) => s.center == center);
    final msg = l.scanRedoFace(faceName(l, center));
    ref.read(speechProvider).speak(msg);
    _cube.highlighted = r.suspectFacelets.toSet();
    setState(() {
      _problem = msg;
      _redoStep = step;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.scanVerifyTitle),
        leading: IconButton(
          tooltip: l.back,
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: CubeLayout(
          cube: AppCubeView(
            controller: _cube,
            onStickerTap: _fix,
            semanticLabel: l.cubeLabel,
          ),
          panel: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Cubito découvre le cube (surpris), ou encourage à refaire
              // une face (triste).
              CubiSays(
                mood: _problem != null ? CubiMood.triste : CubiMood.surpris,
                message: _problem ?? l.scanVerifyHelp,
                size: 76,
                style: (_problem != null
                    ? t.titleMedium?.copyWith(color: CubeColors.practice)
                    : t.bodyLarge),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  if (_tampered)
                    PillButton(
                      icon: Icons.restart_alt_rounded,
                      label: l.scanRestart,
                      color: CubeColors.solve,
                      onTap: () => Navigator.of(context).pop(VerifyRescan()),
                    )
                  else if (_problem != null &&
                      _redoStep != null &&
                      _redoStep! >= 0)
                    PillButton(
                      icon: Icons.photo_camera_rounded,
                      label: l.scanRedoYes,
                      color: CubeColors.solve,
                      onTap: () =>
                          Navigator.of(context).pop(VerifyRedoFace(_redoStep!)),
                    )
                  else
                    PillButton(
                      icon: Icons.thumb_up_rounded,
                      label: l.scanYes,
                      color: CubeColors.learn,
                      onTap: _confirm,
                    ),
                  PillButton(
                    icon: Icons.edit_rounded,
                    label: l.scanFix,
                    color: CubeColors.trophies,
                    onTap: () =>
                        Navigator.of(context).pop(VerifyManual(_colors)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
