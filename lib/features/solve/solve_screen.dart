// Mode « Résoudre mon cube » : 1. saisie des couleurs du vrai cube,
// 2. validation, 3. choix du chemin (toute la méthode, ou le plus court),
// 4. guidage coup par coup.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/cube/cube.dart';
import '../../core/cube/fast_solver.dart';
import '../../core/cube/solver.dart';
import '../../core/cube/validation.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/color_text.dart';
import '../../shared/speech.dart';
import '../../shared/stats.dart';
import '../../shared/theme.dart';
import '../../shared/widgets/confetti.dart';
import '../learn/islands.dart';
import '../learn/parts/common.dart';
import '../../core/scan/color_lab.dart';
import '../scan/scan_screen.dart';
import '../scan/scan_verify_screen.dart';
import '../../core/method/method.dart';
import '../guide/guide_cards.dart';
import '../guide/guided_player.dart';
import 'cube_input.dart';
import 'short_path.dart';
import '../../shared/mascot/cubi_avatar.dart';

/// Message gentil pour un problème de validation.
String validationMessage(AppLocalizations l, Cube cube, ValidationResult r) {
  switch (r.problem!) {
    case CubeProblem.wrongColorCount:
      return l.errTooMany(colorName(l, r.suspectColor!));
    case CubeProblem.impossibleCorner ||
        CubeProblem.impossibleEdge ||
        CubeProblem.duplicatePiece ||
        CubeProblem.duplicateCenters ||
        CubeProblem.impossibleCenters:
      final face = Face.values[r.suspectFacelets.first ~/ 9];
      return l.errPiece(faceName(l, cube.center(face)));
    case CubeProblem.twistedCorner ||
        CubeProblem.flippedEdge ||
        CubeProblem.swappedPieces:
      return handTamperedMessage(l, r.problem) ?? l.errImpossible;
  }
}

/// Remet un cube dans l'orientation de saisie (blanc en haut, vert devant).
Cube toReferenceOrientation(Cube c) {
  for (final flip in ['', 'x2']) {
    for (final turn in ['', 'y', 'y2', "y'"]) {
      final r = c.apply('$flip $turn');
      final ok =
          r.center(Face.u) == CubeColor.white &&
          r.center(Face.f) == CubeColor.green;
      if (ok) return r;
    }
  }
  return c;
}

class SolveScreen extends ConsumerStatefulWidget {
  const SolveScreen({super.key});

  @override
  ConsumerState<SolveScreen> createState() => _SolveScreenState();
}

class _SolveScreenState extends ConsumerState<SolveScreen> {
  /// Faut-il encore choisir caméra / coloriage ?
  bool _choosing = true;
  List<CubeColor?> _input = emptyInput();
  Set<int> _suspects = {};
  String? _message;
  Face? _startFace;
  Cube? _cube; // cube validé → choix du chemin
  int _inputVersion = 0;

  /// Chemin choisi (null : on n'a pas encore choisi).
  SolvePath? _path;

  /// Gestes de la méthode complète, et solution la plus courte (calculée en
  /// arrière-plan dès que le cube est validé).
  int? _methodCount;
  List<Move>? _short;
  bool _shortFailed = false;

  void _prepare(Cube cube) {
    _path = null;
    _short = null;
    _shortFailed = false;
    try {
      _methodCount = gestureCount(solveBeginner(cube).allMoves);
    } catch (_) {
      _methodCount = null;
    }
    FastSolver.solveInBackground(cube).then(
      (s) {
        if (mounted && _cube == cube) setState(() => _short = s.moves);
      },
      onError: (_) {
        if (mounted && _cube == cube) setState(() => _shortFailed = true);
      },
    );
  }

  void _onSubmit(List<CubeColor> colors) {
    final l = AppLocalizations.of(context);
    final cube = Cube.fromColors(colors);
    final r = validateCube(cube);
    if (!r.isValid) {
      final msg = validationMessage(l, cube, r);
      ref.read(speechProvider).speak(msg);
      setState(() {
        _input = colors;
        _suspects = r.suspectFacelets.toSet();
        _message = msg;
        _startFace = r.suspectFacelets.isEmpty
            ? null
            : Face.values[r.suspectFacelets.first ~/ 9];
        _inputVersion++;
      });
      return;
    }
    setState(() {
      _cube = cube;
      _prepare(cube);
    });
  }

  /// Scan à la caméra, puis écran de vérification.
  Future<void> _scan({int? onlyStep, List<List<Lab>>? previous}) async {
    final faces = await Navigator.of(context).push<List<List<Lab>>>(
      MaterialPageRoute(
        builder: (_) => ScanScreen(onlyStep: onlyStep, previous: previous),
      ),
    );
    if (faces == null || !mounted) return;
    final res = await Navigator.of(context).push<VerifyResult>(
      MaterialPageRoute(builder: (_) => ScanVerifyScreen(faces: faces)),
    );
    if (res == null || !mounted) return;
    switch (res) {
      case VerifyConfirmed(:final colors):
        setState(() => _choosing = false);
        _onSubmit(colors);
      case VerifyRedoFace(:final step):
        await _scan(onlyStep: step, previous: faces);
      case VerifyRescan():
        await _scan();
      case VerifyManual(:final colors):
        setState(() {
          _choosing = false;
          _input = colors;
          _suspects = {};
          _message = null;
          _startFace = Face.u;
          _inputVersion++;
        });
    }
  }

  void _onMistake(Cube expected) {
    final l = AppLocalizations.of(context);
    final ref0 = toReferenceOrientation(expected);
    setState(() {
      _cube = null;
      _path = null;
      _input = ref0.colors;
      _suspects = {};
      _message = l.solveMistakeHelp;
      _startFace = Face.u;
      _inputVersion++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cube = _cube;
    return Scaffold(
      appBar: AppBar(
        title: Text(cube == null && !_choosing ? l.inputTitle : l.tileSolve),
        leading: IconButton(
          tooltip: l.back,
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (cube != null && _path != null) {
              setState(() => _path = null); // retour au choix du chemin
            } else if (cube != null) {
              setState(() => _cube = null); // retour à la saisie
            } else if (!_choosing) {
              setState(() => _choosing = true);
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
      ),
      body: SafeArea(
        child: _choosing && cube == null
            ? _ModeChooser(
                onScan: () => _scan(),
                onHand: () => setState(() => _choosing = false),
              )
            : cube == null
            ? CubeInput(
                key: ValueKey(_inputVersion),
                initial: _input,
                suspects: _suspects,
                message: _message,
                startFace: _startFace,
                onSubmit: _onSubmit,
              )
            : _path == null
            ? _PathChooser(
                methodCount: _methodCount,
                shortCount: _short == null ? null : gestureCount(_short!),
                shortFailed: _shortFailed,
                onPick: (p) => setState(() => _path = p),
              )
            : SolveGuide(
                key: ValueKey(_path),
                start: cube,
                shortMoves: _path == SolvePath.short ? _short : null,
                onMistake: _onMistake,
              ),
      ),
    );
  }
}

/// Guidage avec les cartes du livret : place ton cube, formule, un geste à
/// la fois, vérifie. Le dessin reproduit exactement le vrai cube.
class SolveGuide extends ConsumerStatefulWidget {
  const SolveGuide({
    super.key,
    required this.start,
    required this.onMistake,
    this.shortMoves,
  });
  final Cube start;
  final ValueChanged<Cube> onMistake;

  /// Solution la plus courte : si elle est donnée, on la suit au lieu de la
  /// méthode (pas d'étapes, un geste à la fois).
  final List<Move>? shortMoves;

  @override
  ConsumerState<SolveGuide> createState() => _SolveGuideState();
}

class _SolveGuideState extends ConsumerState<SolveGuide> {
  late final List<GuideCard> _cards;
  late final List<Island> _islandOfCard;
  late final List<int> _gestureNumber;
  int _gestureTotal = 0;
  bool _recorded = false;

  @override
  void initState() {
    super.initState();
    final short = widget.shortMoves;
    if (short != null) {
      _cards = buildShortCards(widget.start, short);
      _islandOfCard = const [];
      // Numéro du geste en cours pour chaque carte.
      var n = 0;
      _gestureNumber = [
        for (final c in _cards) c is GestureCard ? ++n : (n == 0 ? 1 : n),
      ];
      _gestureTotal = n;
      return;
    }
    _gestureNumber = const [];
    final solution = solveBeginner(widget.start);
    // Toutes les actions à la suite, précédées de « tiens ton cube » : les
    // rotations qui se suivent (même d'une étape à l'autre) ne font qu'UNE
    // carte « tiens ton cube comme ça », celle où l'on commence vraiment.
    const hold = SolveAction(
      step: MethodStep.croixBlanche,
      type: ActionType.rotateCube,
      moves: [],
      hint: SolveHint.retournerJauneEnHaut,
    );
    _cards = buildCards(widget.start, [hold, ...solution.actions]);
    _islandOfCard = [
      for (final c in _cards)
        islands.firstWhere((i) => i.steps.contains(c.action.step)),
    ];
    // La carte « tiens ton cube » fusionnée porte l'étape du 1er vrai geste.
    for (var k = 0; k < _cards.length; k++) {
      if (_cards[k] is! PlaceCard) {
        for (var j = 0; j < k; j++) {
          _islandOfCard[j] = _islandOfCard[k];
        }
        break;
      }
    }
  }

  void _finished() {
    if (_recorded) return;
    _recorded = true;
    ref.read(statsProvider.notifier).addRealSolve();
    ref.read(speechProvider).speak(AppLocalizations.of(context).solveFinished);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    return GuidedPlayer(
      cards: _cards,
      color: CubeColors.solve,
      headerFor: (i) {
        if (widget.shortMoves != null) {
          final k = _gestureNumber[i.clamp(0, _gestureNumber.length - 1)];
          return l.solveShortHeader(k, _gestureTotal);
        }
        final island = _islandOfCard[i.clamp(0, _islandOfCard.length - 1)];
        return l.solveStep(island.number, island.title(l));
      },
      onMistake: widget.onMistake,
      onFinished: _finished,
      done: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CubiAvatar(
                    size: 220,
                    mood: CubiMood.rire,
                    jumpOnShow: true,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l.solveFinished,
                    textAlign: TextAlign.center,
                    style: t.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  NextButton(
                    label: l.backHome,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
          ),
          const Positioned.fill(child: Confetti()),
        ],
      ),
    );
  }
}

/// Les deux façons de résoudre.
enum SolvePath { method, short }

/// Choix du chemin : toute la méthode, ou le plus court.
class _PathChooser extends StatelessWidget {
  const _PathChooser({
    required this.methodCount,
    required this.shortCount,
    required this.shortFailed,
    required this.onPick,
  });
  final int? methodCount;
  final int? shortCount;
  final bool shortFailed;
  final ValueChanged<SolvePath> onPick;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    Widget tile({
      required IconData icon,
      required String title,
      required String help,
      required String badge,
      required Color color,
      VoidCallback? onTap,
      bool busy = false,
    }) => Semantics(
      button: true,
      enabled: onTap != null,
      label: '$title. $help. $badge',
      excludeSemantics: true,
      child: Opacity(
        opacity: onTap == null && !busy ? 0.5 : 1,
        child: Material(
          color: color,
          borderRadius: BorderRadius.circular(28),
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(icon, size: 56, color: Colors.white),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: t.titleLarge?.copyWith(color: Colors.white),
                        ),
                        Text(
                          help,
                          style: t.bodyMedium?.copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (busy) ...[
                                const SizedBox.square(
                                  dimension: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              Flexible(
                                child: Text(
                                  badge,
                                  style: t.titleSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    final shortReady = shortCount != null;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            children: [
              CubiSays(
                mood: CubiMood.surpris,
                message: l.solvePathTitle,
                size: 84,
                style: t.headlineSmall,
              ),
              const SizedBox(height: 20),
              tile(
                icon: Icons.stairs_rounded,
                title: l.solvePathMethod,
                help: l.solvePathMethodHelp,
                badge: methodCount == null
                    ? ''
                    : l.solvePathMoves(methodCount!),
                color: CubeColors.learn,
                onTap: () => onPick(SolvePath.method),
              ),
              const SizedBox(height: 16),
              if (!shortFailed)
                tile(
                  icon: Icons.bolt_rounded,
                  title: l.solvePathShort,
                  help: l.solvePathShortHelp,
                  badge: shortReady
                      ? l.solvePathMoves(shortCount!)
                      : l.solvePathThinking,
                  color: CubeColors.solve,
                  busy: !shortReady,
                  onTap: shortReady ? () => onPick(SolvePath.short) : null,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Choix : caméra ou coloriage à la main.
class _ModeChooser extends StatelessWidget {
  const _ModeChooser({required this.onScan, required this.onHand});
  final VoidCallback onScan;
  final VoidCallback onHand;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    Widget tile(
      IconData icon,
      String title,
      String help,
      Color color,
      VoidCallback onTap,
    ) => Semantics(
      button: true,
      label: '$title. $help',
      excludeSemantics: true,
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(28),
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(icon, size: 56, color: Colors.white),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: t.titleLarge?.copyWith(color: Colors.white),
                      ),
                      Text(
                        help,
                        style: t.bodyMedium?.copyWith(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            children: [
              Text(
                l.solveChooseTitle,
                textAlign: TextAlign.center,
                style: t.headlineSmall,
              ),
              const SizedBox(height: 20),
              tile(
                Icons.photo_camera_rounded,
                l.solveChooseScan,
                l.solveChooseScanHelp,
                CubeColors.solve,
                onScan,
              ),
              const SizedBox(height: 16),
              tile(
                Icons.edit_rounded,
                l.solveChooseHand,
                l.solveChooseHandHelp,
                CubeColors.trophies,
                onHand,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
