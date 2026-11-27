// Saisie des couleurs du vrai cube, face par face, avec de très gros
// boutons. L'ordre des faces et la façon de tenir le cube sont imposés :
// ainsi l'appli sait comment chaque face est orientée.
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/cube/cube.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/speech.dart';
import '../../shared/theme.dart';
import '../../shared/widgets/pill_button.dart';
import '../../shared/widgets/sticker.dart';
import 'cube_net.dart';
import '../../shared/mascot/cubi_avatar.dart';

/// Ordre de saisie : blanc, vert, rouge, bleu, orange, jaune.
const inputOrder = [Face.u, Face.f, Face.r, Face.b, Face.l, Face.d];

/// Couleurs vides avec seulement les centres (orientation de référence).
List<CubeColor?> emptyInput() => [
  for (var i = 0; i < 54; i++)
    i % 9 == 4 ? referenceColors[Face.values[i ~/ 9]] : null,
];

String holdInstruction(AppLocalizations l, Face f) => switch (f) {
  Face.u => l.inputHoldU,
  Face.f => l.inputHoldF,
  Face.r => l.inputHoldR,
  Face.b => l.inputHoldB,
  Face.l => l.inputHoldL,
  Face.d => l.inputHoldD,
};

class CubeInput extends ConsumerStatefulWidget {
  const CubeInput({
    super.key,
    required this.initial,
    required this.onSubmit,
    this.suspects = const {},
    this.message,
    this.startFace,
  });

  final List<CubeColor?> initial;
  final ValueChanged<List<CubeColor>> onSubmit;

  /// Cases à faire clignoter (problème détecté à la validation).
  final Set<int> suspects;

  /// Message gentil à afficher (erreur de validation…).
  final String? message;

  /// Face à afficher en premier.
  final Face? startFace;

  @override
  ConsumerState<CubeInput> createState() => _CubeInputState();
}

class _CubeInputState extends ConsumerState<CubeInput>
    with SingleTickerProviderStateMixin {
  late final List<CubeColor?> _colors = [...widget.initial];
  late int _faceIdx = widget.startFace == null
      ? 0
      : inputOrder.indexOf(widget.startFace!);
  CubeColor _brush = CubeColor.white;
  late Set<int> _suspects = {...widget.suspects};
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  )..repeat(reverse: true);

  Face get _face => inputOrder[_faceIdx];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _speakFace());
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  void _speakFace() {
    if (!mounted) return;
    final l = AppLocalizations.of(context);
    ref.read(speechProvider).speak(widget.message ?? holdInstruction(l, _face));
  }

  void _goFace(int idx) {
    setState(() => _faceIdx = idx.clamp(0, 5));
    final l = AppLocalizations.of(context);
    ref.read(speechProvider).speak(holdInstruction(l, _face));
  }

  void _paint(int facelet) {
    if (facelet % 9 == 4) return; // centre fixe
    HapticFeedback.selectionClick();
    setState(() {
      _colors[facelet] = _brush;
      _suspects.remove(facelet);
    });
  }

  void _clearFace() {
    setState(() {
      for (var k = 0; k < 9; k++) {
        if (k != 4) _colors[_face.index * 9 + k] = null;
      }
    });
  }

  int _count(CubeColor c) => _colors.where((x) => x == c).length;
  bool get _complete => !_colors.contains(null);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;

    final grid = LayoutBuilder(
      builder: (context, c) {
        final side = (c.biggest.shortestSide).clamp(180.0, 420.0);
        final cell = (side - 24) / 3;
        return Center(
          child: SizedBox(
            width: side,
            height: side,
            child: AnimatedBuilder(
              animation: _pulse,
              builder: (context, _) => GridView.count(
                crossAxisCount: 3,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                children: [
                  for (var k = 0; k < 9; k++)
                    Semantics(
                      button: true,
                      label: '${l.inputTitle} ${k + 1}',
                      child: GestureDetector(
                        onTap: () => _paint(_face.index * 9 + k),
                        child: StickerCell(
                          color: _colors[_face.index * 9 + k],
                          size: cell,
                          locked: k == 4,
                          highlight: _suspects.contains(_face.index * 9 + k)
                              ? 0.4 + 0.6 * _pulse.value
                              : 0,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );

    final palette = Wrap(
      alignment: WrapAlignment.center,
      spacing: 4,
      runSpacing: 8,
      children: [
        for (final c in CubeColor.values)
          Semantics(
            button: true,
            selected: c == _brush,
            label: l.inputColorCount(_count(c)),
            child: GestureDetector(
              onTap: () => setState(() => _brush = c),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  StickerCell(color: c, size: 56, selected: c == _brush),
                  Text(
                    '${_count(c)}/9',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: _count(c) > 9
                          ? CubeColors.practice
                          : CubeColors.ink,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );

    final header = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(l.inputFaceCounter(_faceIdx + 1), style: t.bodyMedium),
        Text(
          holdInstruction(l, _face),
          textAlign: TextAlign.center,
          style: t.titleLarge,
        ),
        if (widget.message != null && _suspects.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: CubiSays(
              mood: CubiMood.triste,
              message: widget.message!,
              size: 72,
              style: t.titleMedium?.copyWith(color: CubeColors.practice),
            ),
          ),
      ],
    );

    final net = AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) => CubeNet(
        colors: _colors,
        currentFace: _face,
        suspects: _suspects,
        pulse: _pulse.value,
        width: 216,
        onFaceTap: (f) => _goFace(inputOrder.indexOf(f)),
      ),
    );

    final isLast = _faceIdx == 5;
    final buttons = Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 10,
      children: [
        PillButton(
          compact: true,
          icon: Icons.arrow_back_rounded,
          label: l.inputPrevFace,
          color: CubeColors.solve,
          onTap: _faceIdx == 0 ? null : () => _goFace(_faceIdx - 1),
        ),
        PillButton(
          compact: true,
          icon: Icons.backspace_rounded,
          label: l.inputClear,
          color: CubeColors.trophies,
          onTap: _clearFace,
        ),
        if (!isLast)
          PillButton(
            icon: Icons.arrow_forward_rounded,
            label: l.inputNextFace,
            color: CubeColors.learn,
            onTap: () => _goFace(_faceIdx + 1),
          ),
        if (isLast || _complete)
          PillButton(
            icon: Icons.check_rounded,
            label: l.inputCheck,
            color: CubeColors.learn,
            onTap: () {
              if (!_complete) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      l.inputMissing,
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                );
                final missing = _colors.indexOf(null);
                _goFace(inputOrder.indexOf(Face.values[missing ~/ 9]));
                return;
              }
              widget.onSubmit([for (final c in _colors) c!]);
            },
          ),
      ],
    );

    return LayoutBuilder(
      builder: (context, c) {
        final landscape = c.maxWidth > c.maxHeight;
        if (landscape) {
          return Row(
            children: [
              Expanded(
                child: Padding(padding: const EdgeInsets.all(16), child: grid),
              ),
              SizedBox(
                width: c.maxWidth * 0.48,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      header,
                      const SizedBox(height: 8),
                      palette,
                      const SizedBox(height: 8),
                      net,
                      const SizedBox(height: 8),
                      buttons,
                    ],
                  ),
                ),
              ),
            ],
          );
        }
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: header,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                child: grid,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: palette,
            ),
            const SizedBox(height: 8),
            net,
            Padding(padding: const EdgeInsets.all(12), child: buttons),
          ],
        );
      },
    );
  }

  @override
  void didUpdateWidget(CubeInput old) {
    super.didUpdateWidget(old);
    if (old.suspects != widget.suspects) _suspects = {...widget.suspects};
  }
}
