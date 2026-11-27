// Le lecteur de cartes : montre UNE carte à la fois, comme un livret LEGO.
// Mode « suivre » : l'enfant fait le geste sur son vrai cube puis appuie sur
// « Fait ! ». Mode « à toi » : il fait le geste au doigt sur le dessin.
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/cube/cube.dart';
import '../../core/cube/solver.dart';
import '../../l10n/app_localizations.dart';
import '../../render/flat_cube.dart';
import '../../shared/color_text.dart';
import '../../shared/gesture_text.dart';
import '../../shared/settings.dart';
import '../../shared/solve_text.dart';
import '../../shared/sounds.dart';
import '../../shared/speech.dart';
import '../../shared/theme.dart';
import '../../shared/widgets/pill_button.dart';
import '../../shared/widgets/sticker.dart';
import 'guide_cards.dart';

enum GuideMode { follow, doIt }

/// Phrase lue à voix haute pour une carte (aussi utilisée pour préparer les
/// voix enregistrées : tool/voice).
String cardSpeech(AppLocalizations l, GuideCard card) => switch (card) {
  PlaceCard() =>
    '${l.placeTitle}. ${l.onTop(colorName(l, card.top))}, ${l.inFront(colorName(l, card.front))}.',
  FormulaCard() =>
    '${algorithmName(l, card.algorithm)}. ${l.formulaSing} ${formulaChant(l, card.action.moves)} ${l.formulaTimes(card.repetitions)}.',
  GestureCard() => () {
    final w = gestureWords(l, card.move);
    return '${w.verb.toLowerCase()} ${w.object}.';
  }(),
  CheckCard() => l.checkTitle,
};

class GuidedPlayer extends ConsumerStatefulWidget {
  const GuidedPlayer({
    super.key,
    required this.cards,
    this.mode = GuideMode.follow,
    this.color = kMoveColor,
    this.headerFor,
    this.onFinished,
    this.onMistake,
    this.done,
    this.memory = false,
    this.onHintsUsed,
  });

  /// Mode « par cœur » (avec [GuideMode.doIt]) : les gestes sont cachés,
  /// l'enfant les fait de mémoire. « Aide » (ou une erreur) les montre.
  final bool memory;

  /// Mode « par cœur » : appelé à la fin avec le nombre d'aides utilisées.
  final ValueChanged<int>? onHintsUsed;

  final List<GuideCard> cards;
  final GuideMode mode;

  /// Couleur d'accent (boutons, numéros).
  final Color color;

  /// Petit titre au-dessus de la carte (ex. « Étape 3 · Les coins blancs »).
  final String Function(int index)? headerFor;

  /// Appelé une fois la dernière carte faite.
  final VoidCallback? onFinished;

  /// « Pas tout à fait » sur une carte de vérification (mode Résoudre) :
  /// reçoit l'état attendu du cube. Sans ce rappel, on recommence la formule.
  final ValueChanged<Cube>? onMistake;

  /// Ce qu'on montre quand tout est fini.
  final Widget? done;

  @override
  ConsumerState<GuidedPlayer> createState() => _GuidedPlayerState();
}

class _GuidedPlayerState extends ConsumerState<GuidedPlayer> {
  int _i = 0;

  /// Mode « par cœur » : geste en cours montré (aide ou erreur), et total.
  bool _revealed = false;
  int _hints = 0;

  bool get _hidden =>
      widget.memory &&
      !_revealed &&
      _i < widget.cards.length &&
      widget.cards[_i] is GestureCard;

  void _reveal() {
    if (!_hidden) return;
    setState(() {
      _revealed = true;
      _hints++;
    });
    ref
        .read(speechProvider)
        .speak(cardSpeech(AppLocalizations.of(context), widget.cards[_i]));
  }

  /// Mode « à toi » : premier quart d'un double déjà fait.
  Move? _half;
  String? _feedback;
  bool _feedbackGood = true;

  bool get _finished => _i >= widget.cards.length;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _speak());
  }

  void _speak() {
    if (!mounted || _finished) return;
    final l = AppLocalizations.of(context);
    final card = widget.cards[_i];
    // Par cœur : on ne souffle pas le geste.
    if (widget.memory && card is GestureCard) return;
    final text = cardSpeech(l, card);
    ref.read(speechProvider).speak(text);
  }

  void _goTo(int i) {
    setState(() {
      _i = i.clamp(0, widget.cards.length);
      _half = null;
      _feedback = null;
      _revealed = false;
    });
    if (_finished) {
      ref.read(soundsProvider).play(Sfx.success);
      HapticFeedback.heavyImpact();
      widget.onHintsUsed?.call(_hints);
      widget.onFinished?.call();
    } else {
      _speak();
    }
  }

  void _next() {
    if (_finished) return;
    if (widget.cards[_i] is GestureCard) {
      ref.read(soundsProvider).play(Sfx.tick);
    }
    HapticFeedback.lightImpact();
    _goTo(_i + 1);
  }

  void _back() {
    if (_i > 0) _goTo(_i - 1);
  }

  void _checkNo() {
    final l = AppLocalizations.of(context);
    final card = widget.cards[_i];
    if (widget.onMistake != null) {
      widget.onMistake!(card.before);
      return;
    }
    final start = formulaStartOf(widget.cards, _i);
    _goTo(start);
    setState(() {
      _feedback = l.checkRetry;
      _feedbackGood = false;
    });
    ref.read(speechProvider).speak(l.checkRetry);
  }

  /// Mode « à toi » : l'enfant a glissé le doigt.
  void _onSwipe(Move m) {
    final card = widget.cards[_i];
    if (card is! GestureCard) return;
    final l = AppLocalizations.of(context);
    final expected = card.move;
    final ok = expected.turns == 2
        ? (m.kind == expected.kind && (_half == null || _half == m))
        : m == expected;
    if (!ok) {
      ref.read(soundsProvider).play(Sfx.oops);
      HapticFeedback.lightImpact();
      // Par cœur : après une erreur, on montre le bon geste.
      if (_hidden) _reveal();
      setState(() {
        _feedback = l.tryAgain;
        _feedbackGood = false;
      });
      return;
    }
    if (expected.turns == 2 && _half == null) {
      ref.read(soundsProvider).play(Sfx.tick);
      setState(() => _half = m);
      return;
    }
    _next();
    setState(() {
      _feedback = l.wellDoneShort;
      _feedbackGood = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    if (_finished) return widget.done ?? const SizedBox.shrink();
    final card = widget.cards[_i];
    final symbols = ref.watch(settingsProvider.select((s) => s.colorBlind));

    final progress = Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.headerFor != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                widget.headerFor!(_i),
                style: t.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: CubeColors.ink.withValues(alpha: 0.75),
                ),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: _i / widget.cards.length,
                    minHeight: 8,
                    color: widget.color,
                    backgroundColor: widget.color.withValues(alpha: 0.15),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${_i + 1}/${widget.cards.length}',
                style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ],
      ),
    );

    final content = switch (card) {
      PlaceCard() => _PlaceView(card: card, symbols: symbols),
      FormulaCard() => _FormulaView(card: card, color: widget.color),
      GestureCard() => _GestureView(
        card: card,
        color: widget.color,
        doIt: widget.mode == GuideMode.doIt,
        onSwipe: _onSwipe,
        symbols: symbols,
        half: _half != null,
        hidden: _hidden,
      ),
      CheckCard() => _CheckView(card: card, symbols: symbols),
    };

    final waitingSwipe = widget.mode == GuideMode.doIt && card is GestureCard;
    final primaryLabel = switch (card) {
      PlaceCard() => l.placeOk,
      FormulaCard() => l.formulaGo,
      GestureCard() => l.gestureDone,
      CheckCard() => l.checkYes,
    };

    final bottom = Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_feedback != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                _feedbackGood ? '✅ $_feedback' : '🙂 $_feedback',
                textAlign: TextAlign.center,
                style: t.titleMedium?.copyWith(
                  color: _feedbackGood ? CubeColors.learn : CubeColors.practice,
                ),
              ),
            ),
          Row(
            children: [
              PillButton(
                compact: true,
                icon: Icons.undo_rounded,
                label: l.previous,
                color: CubeColors.solve,
                onTap: _i == 0 ? null : _back,
              ),
              const SizedBox(width: 10),
              if (card is CheckCard) ...[
                Expanded(
                  child: _BigButton(
                    label: l.checkNo,
                    color: Colors.white,
                    textColor: CubeColors.ink,
                    onTap: _checkNo,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _BigButton(
                    label: l.checkYes,
                    color: CubeColors.learn,
                    onTap: _next,
                  ),
                ),
              ] else if (waitingSwipe && _hidden)
                Expanded(
                  child: _BigButton(
                    label: l.memoryHelp,
                    color: Colors.white,
                    textColor: CubeColors.ink,
                    onTap: _reveal,
                  ),
                )
              else if (waitingSwipe)
                Expanded(
                  child: Text(
                    l.yourTurnSwipe,
                    textAlign: TextAlign.center,
                    style: t.titleMedium,
                  ),
                )
              else
                Expanded(
                  child: _BigButton(
                    label: primaryLabel,
                    color: widget.color,
                    onTap: _next,
                  ),
                ),
            ],
          ),
        ],
      ),
    );

    return Column(
      children: [
        progress,
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            transitionBuilder: (child, a) =>
                FadeTransition(opacity: a, child: child),
            child: KeyedSubtree(key: ValueKey(_i), child: content),
          ),
        ),
        bottom,
      ],
    );
  }
}

class _BigButton extends StatelessWidget {
  const _BigButton({
    required this.label,
    required this.color,
    required this.onTap,
    this.textColor = Colors.white,
  });
  final String label;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        backgroundColor: color,
        foregroundColor: textColor,
        minimumSize: const Size.fromHeight(66),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(33),
          side: color == Colors.white
              ? const BorderSide(color: Color(0xFFD3CCDC), width: 3)
              : BorderSide.none,
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900),
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// Mise en page d'une carte : défile si l'écran est petit, cube centré.
class _CardScroll extends StatelessWidget {
  const _CardScroll({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) => SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: c.maxHeight - 12),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: children,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Taille du grand dessin selon la place disponible.
double _cubeWidth(BuildContext context, {double factor = 0.62}) {
  final s = MediaQuery.of(context).size;
  return (s.shortestSide * factor).clamp(180.0, 340.0);
}

class _PlaceView extends StatelessWidget {
  const _PlaceView({required this.card, required this.symbols});
  final PlaceCard card;
  final bool symbols;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    Widget line(CubeColor c, String text) => Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          StickerCell(color: c, size: 40),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
    return _CardScroll(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(l.placeTitle, style: t.headlineMedium),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: _cubeWidth(context),
          child: FlatCube(
            cube: card.after,
            style: FlatStyle.colors,
            rings: const {4, 22}, // centres du dessus et de devant
            animate: false,
            symbols: symbols,
            semanticLabel: l.placeTitle,
          ),
        ),
        line(card.top, l.onTop(_cap(colorName(l, card.top)))),
        line(card.front, l.inFront(_cap(colorName(l, card.front)))),
        const SizedBox(height: 8),
        Text(l.placeCenters, style: t.bodyMedium),
      ],
    );
  }
}

/// Mini carte numérotée d'une formule (frise).
class MiniGestureCard extends StatelessWidget {
  const MiniGestureCard({
    super.key,
    required this.move,
    required this.number,
    this.state = 0,
    this.color = kMoveColor,
  });
  final Move move;
  final int number;

  /// -1 fait, 0 à venir, 1 en cours.
  final int state;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: state < 0 ? 0.4 : 1,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.fromLTRB(4, 6, 4, 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: state == 1 ? color : Colors.transparent,
            width: 4,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$number',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: kMoveColorDark,
              ),
            ),
            SizedBox(
              width: 58,
              child: FlatCube(cube: Cube.solved(), move: move, animate: false),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  state < 0 ? Icons.check_rounded : gestureIcon(move),
                  size: 24,
                  color: CubeColors.ink,
                ),
                if (move.turns == 2 && state >= 0)
                  const Text(
                    '×2',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FormulaView extends StatelessWidget {
  const _FormulaView({required this.card, required this.color});
  final FormulaCard card;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final chunks = card.chunks;
    Widget row(List<Move> ms, int offset) => Row(
      children: [
        for (var k = 0; k < ms.length; k++)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: MiniGestureCard(move: ms[k], number: offset + k + 1),
            ),
          ),
        for (var k = ms.length; k < 4; k++) const Expanded(child: SizedBox()),
      ],
    );
    final box = BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
    );
    return _CardScroll(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.formulaLabel,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: kMoveColorDark,
                ),
              ),
              Text(
                '${card.algorithm.emoji} ${algorithmName(l, card.algorithm)}',
                style: t.headlineMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (chunks.length > 1)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(l.formulaParts(chunks.length), style: t.bodyLarge),
          ),
        for (var ci = 0; ci < chunks.length; ci++) ...[
          if (chunks.length > 1)
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                l.formulaPart(ci + 1, chunks.length),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          const SizedBox(height: 4),
          row(chunks[ci], chunks.take(ci).fold(0, (a, b) => a + b.length)),
          const SizedBox(height: 10),
        ],
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: box,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.formulaSing,
                style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              Text(
                formulaChant(l, card.action.moves),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: box,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l.formulaTimes(card.repetitions),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              for (var k = 0; k < card.repetitions; k++)
                Container(
                  width: 24,
                  height: 24,
                  margin: const EdgeInsets.only(left: 8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: kMoveColor, width: 4),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(l.formulaNoTurn, textAlign: TextAlign.center, style: t.bodyMedium),
      ],
    );
  }
}

class _GestureView extends StatelessWidget {
  const _GestureView({
    required this.card,
    required this.color,
    required this.doIt,
    required this.onSwipe,
    required this.symbols,
    required this.half,
    this.hidden = false,
  });
  final GestureCard card;
  final Color color;
  final bool doIt;
  final ValueChanged<Move> onSwipe;
  final bool symbols;
  final bool half;

  /// Par cœur : le geste n'est pas montré.
  final bool hidden;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final w = gestureWords(l, card.move);
    final reps = card.action.repetitions;
    final showStrip = card.chunk.length > 1 || reps > 1;
    // Formule : dessin neutre (gris + violet). Préparation ou « à toi » :
    // vraies couleurs du cube, partie qui bouge entourée de violet.
    // Toujours les vraies couleurs du cube : l'enfant retrouve sa face et
    // la ligne/colonne à tourner (entourée d'un gros contour).
    const style = FlatStyle.colors;

    return _CardScroll(
      children: [
        if (showStrip) ...[
          Row(
            children: [
              if (card.chunkCount > 1)
                Text(
                  l.formulaPart(card.chunkIndex + 1, card.chunkCount),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              const Spacer(),
              if (reps > 1) ...[
                Text(
                  l.formulaTimesProgress(card.repetition, reps),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                for (var k = 0; k < reps; k++)
                  Container(
                    width: 14,
                    height: 14,
                    margin: const EdgeInsets.only(left: 6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: k < card.repetition - 1
                          ? kMoveColor
                          : const Color(0xFFD3CCDC),
                    ),
                  ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              for (var k = 0; k < card.chunk.length; k++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: hidden && k >= card.indexInChunk
                        ? _MysteryCard(
                            number: k + 1,
                            current: k == card.indexInChunk,
                          )
                        : MiniGestureCard(
                            move: card.chunk[k],
                            number: k + 1,
                            state: k < card.indexInChunk
                                ? -1
                                : (k == card.indexInChunk ? 1 : 0),
                          ),
                  ),
                ),
              for (var k = card.chunk.length; k < 4; k++)
                const Expanded(child: SizedBox()),
            ],
          ),
          const SizedBox(height: 10),
        ],
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Column(
            children: [
              HoldReminder(cube: card.before),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (showStrip)
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: CubeColors.ink,
                      child: Text(
                        '${card.indexInChunk + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  const Spacer(),
                  if (w.hand != null && !hidden)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: kMoveColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.back_hand_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            w.hand!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              SizedBox(
                width: _cubeWidth(context, factor: 0.58),
                child: FlatCube(
                  cube: card.before,
                  move: hidden ? null : card.move,
                  style: style,
                  onSwipe: doIt ? onSwipe : null,
                  symbols: symbols,
                  semanticLabel: hidden
                      ? l.memoryPrompt
                      : '${w.verb} ${w.object}',
                ),
              ),
              const SizedBox(height: 6),
              if (hidden) ...[
                Text(
                  half ? '🧠 · 1/2' : '🧠',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 36, height: 1.05),
                ),
                Text(
                  l.memoryPrompt,
                  textAlign: TextAlign.center,
                  style: t.titleMedium?.copyWith(
                    color: const Color(0xFF4A4060),
                  ),
                ),
              ] else ...[
                Text(
                  half ? '${w.verb.split(' · ').first} · 1/2' : w.verb,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                  ),
                ),
                Text(
                  w.object,
                  textAlign: TextAlign.center,
                  style: t.titleMedium?.copyWith(
                    color: const Color(0xFF4A4060),
                  ),
                ),
              ],
              if (!card.inFormula &&
                  !hidden &&
                  card.action.hint != SolveHint.aucune) ...[
                const SizedBox(height: 6),
                Text(
                  hintText(l, card.action),
                  textAlign: TextAlign.center,
                  style: t.bodyMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Par cœur : carte retournée « ? » à la place d'un geste pas encore fait.
class _MysteryCard extends StatelessWidget {
  const _MysteryCard({required this.number, required this.current});
  final int number;
  final bool current;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 0.8,
      child: Container(
        decoration: BoxDecoration(
          color: current ? kMoveColor : const Color(0xFFE9E4F0),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$number',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: current ? Colors.white : CubeColors.ink,
              ),
            ),
            Text(
              '?',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w900,
                color: current
                    ? Colors.white
                    : CubeColors.ink.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckView extends StatelessWidget {
  const _CheckView({required this.card, required this.symbols});
  final CheckCard card;
  final bool symbols;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    return _CardScroll(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(l.checkTitle, style: t.headlineMedium),
        ),
        const SizedBox(height: 8),
        HoldReminder(cube: card.after),
        const SizedBox(height: 12),
        SizedBox(
          width: _cubeWidth(context),
          child: FlatCube(
            cube: card.after,
            style: FlatStyle.colors,
            animate: false,
            symbols: symbols,
            semanticLabel: l.checkTitle,
          ),
        ),
        const SizedBox(height: 10),
        Text(l.checkCompare, textAlign: TextAlign.center, style: t.titleMedium),
      ],
    );
  }
}

String _cap(String s) =>
    s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

/// Rappel « comment tenir le cube » : la couleur devant et la couleur en
/// haut, avec leurs pastilles. Affiché sur chaque geste.
class HoldReminder extends StatelessWidget {
  const HoldReminder({super.key, required this.cube});
  final Cube cube;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    Widget chip(CubeColor c, String text) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        StickerCell(color: c, size: 26),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
      ],
    );
    final front = cube.center(Face.f), top = cube.center(Face.u);
    return Semantics(
      label: '${l.inFront(colorName(l, front))}, ${l.onTop(colorName(l, top))}',
      excludeSemantics: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F0F7),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 16,
          runSpacing: 6,
          children: [
            chip(front, l.inFront(_cap(colorName(l, front)))),
            chip(top, l.onTop(_cap(colorName(l, top)))),
          ],
        ),
      ),
    );
  }
}
