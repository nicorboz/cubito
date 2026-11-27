// Accueil : le mot « Cubito » en lettres-autocollants, la mascotte qui
// parle, où j'en suis, et 4 grosses tuiles aux vraies couleurs du cube.
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';
import '../../shared/edge_swipe_back.dart';
import '../../shared/mascot/cubi_avatar.dart';
import '../../shared/progress.dart';
import '../../shared/speech.dart';
import '../../shared/theme.dart';
import '../learn/lessons.dart';
import '../learn/learn_screen.dart';
import '../practice/practice_screen.dart';
import '../settings/settings_screen.dart';
import '../solve/solve_screen.dart';
import '../trophies/trophies_screen.dart';

/// Couleurs des tuiles : celles du cube (texte foncé sur jaune et orange
/// pour rester bien lisible).
abstract final class HomeColors {
  static const green = Color(0xFF168A3A);
  static const blue = Color(0xFF1E66F5);
  static const orange = Color(0xFFFF9500);
  static const yellow = Color(0xFFFFD21F);
  static const red = Color(0xFFE53935);
}

/// Courbe d'entrée : rapide puis très douce (ease-out marqué).
const _enter = Cubic(0.23, 1, 0.32, 1);

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _intro.value = 1;
    } else if (_intro.value == 0 && !_intro.isAnimating) {
      _intro.forward();
    }
  }

  // Cubito s'endort si l'enfant ne touche plus l'écran pendant un moment.
  static const _sleepAfter = Duration(seconds: 40);
  Timer? _sleepTimer;
  bool _asleep = false;

  @override
  void initState() {
    super.initState();
    _wakeUp();
  }

  void _wakeUp() {
    _sleepTimer?.cancel();
    _sleepTimer = Timer(_sleepAfter, () {
      if (mounted) setState(() => _asleep = true);
    });
    if (_asleep) setState(() => _asleep = false);
  }

  @override
  void dispose() {
    _sleepTimer?.cancel();
    _intro.dispose();
    super.dispose();
  }

  Future<void> _open(Widget screen) async {
    _sleepTimer?.cancel();
    await Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => screen));
    if (mounted) _wakeUp();
  }

  /// Apparition décalée : chaque élément glisse de 16 px et apparaît.
  Widget _reveal(int order, Widget child) {
    final start = (order * 0.07).clamp(0.0, 0.6);
    final anim = CurvedAnimation(
      parent: _intro,
      curve: Interval(start, (start + 0.5).clamp(0.0, 1.0), curve: _enter),
    );
    return AnimatedBuilder(
      animation: anim,
      child: child,
      builder: (context, child) => Opacity(
        opacity: anim.value,
        child: Transform.translate(
          offset: Offset(0, 16 * (1 - anim.value)),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final progress = ref.watch(progressProvider);
    final next = lessons.firstWhere(
      (i) => !progress.isDone(i.index),
      orElse: () => lessons.last,
    );

    final tiles = [
      _StickerTile(
        label: l.tileLearn,
        subtitle: l.lessonNumber(next.number),
        icon: Icons.school_rounded,
        color: HomeColors.green,
        onTap: () => _open(const LearnScreen()),
      ),
      _StickerTile(
        label: l.tileSolve,
        icon: Icons.extension_rounded,
        color: HomeColors.blue,
        onTap: () => _open(const SolveScreen()),
      ),
      _StickerTile(
        label: l.tilePractice,
        icon: Icons.sports_esports_rounded,
        color: HomeColors.orange,
        onTap: () => _open(const PracticeScreen()),
      ),
      _StickerTile(
        label: l.tileTrophies,
        icon: Icons.emoji_events_rounded,
        color: HomeColors.yellow,
        onTap: () => _open(const TrophiesScreen()),
      ),
    ];

    final header = Row(
      children: [
        const _Wordmark(),
        const Spacer(),
        IconButton(
          tooltip: l.settings,
          icon: const Icon(Icons.settings_rounded, color: CubeColors.ink),
          onPressed: () => _open(const SettingsScreen()),
        ),
      ],
    );

    // Si le glissement depuis le bord vient de ramener ici, le « retour »
    // d'Android pour ce même geste ne doit pas fermer l'appli.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !EdgeSwipeBack.justPopped) SystemNavigator.pop();
      },
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) => _wakeUp(),
        child: Scaffold(
          body: Stack(
            children: [
              const Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(painter: _StickerConfetti()),
                ),
              ),
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, c) {
                    final landscape = c.maxWidth > c.maxHeight;
                    final mascotSize =
                        (landscape
                                ? c.maxHeight * 0.5
                                : c.maxWidth * (c.maxWidth < 360 ? 0.38 : 0.48))
                            .clamp(110.0, 300.0);
                    final hero = _Hero(
                      mascotSize: mascotSize,
                      mood: _asleep ? CubiMood.dodo : CubiMood.joyeux,
                      onMascotTap: () => ref
                          .read(speechProvider)
                          .speak('${l.homeGreeting} ${l.homeSubtitle}'),
                    );
                    final grid = _TileGrid(
                      tiles: [
                        for (var k = 0; k < 4; k++) _reveal(3 + k, tiles[k]),
                      ],
                    );
                    if (landscape) {
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(24, 8, 16, 16),
                        child: Column(
                          children: [
                            _reveal(0, header),
                            Expanded(
                              child: Row(
                                children: [
                                  Expanded(flex: 5, child: _reveal(1, hero)),
                                  const SizedBox(width: 24),
                                  Expanded(flex: 6, child: grid),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 12, 20),
                      child: Column(
                        children: [
                          _reveal(0, header),
                          const SizedBox(height: 4),
                          // Sur les petits écrans, la mascotte et la bulle
                          // rétrécissent pour laisser la place aux tuiles.
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxHeight: c.maxHeight * 0.36,
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: SizedBox(
                                width: c.maxWidth - 32,
                                child: _reveal(1, hero),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: grid,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// « Cubito » écrit avec des lettres-autocollants, comme sur le cube.
class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) {
    const letters = [
      ('C', HomeColors.blue, Colors.white),
      ('U', HomeColors.red, Colors.white),
      ('B', HomeColors.yellow, CubeColors.ink),
      ('I', HomeColors.green, Colors.white),
      ('T', HomeColors.orange, CubeColors.ink),
      ('O', HomeColors.blue, Colors.white),
    ];
    return Semantics(
      label: AppLocalizations.of(context).appTitle,
      header: true,
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFF15111C),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (ch, bg, fg) in letters)
              Container(
                width: 30,
                height: 34,
                margin: const EdgeInsets.all(2),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  ch,
                  style: TextStyle(
                    color: fg,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Cubito + sa bulle de dialogue.
class _Hero extends StatelessWidget {
  const _Hero({
    required this.mascotSize,
    required this.mood,
    required this.onMascotTap,
  });
  final double mascotSize;
  final CubiMood mood;
  final VoidCallback onMascotTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final bubble = Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
          bottomRight: Radius.circular(24),
          bottomLeft: Radius.circular(6),
        ),
        boxShadow: [
          BoxShadow(
            color: CubeColors.ink.withValues(alpha: 0.1),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l.homeGreeting,
            style: t.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 4),
          Text(l.homeSubtitle, style: t.bodyLarge?.copyWith(height: 1.25)),
        ],
      ),
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        CubiAvatar(size: mascotSize, mood: mood, onPoke: onMascotTap),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: mascotSize * 0.42),
            child: bubble,
          ),
        ),
      ],
    );
  }
}

/// Grille 2 × 2 qui remplit l'espace disponible.
class _TileGrid extends StatelessWidget {
  const _TileGrid({required this.tiles});
  final List<Widget> tiles;

  @override
  Widget build(BuildContext context) {
    const gap = 16.0;
    return Column(
      children: [
        for (var row = 0; row < 2; row++) ...[
          if (row > 0) const SizedBox(height: gap),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: tiles[row * 2]),
                const SizedBox(width: gap),
                Expanded(child: tiles[row * 2 + 1]),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Grosse tuile façon autocollant de cube : bord inférieur plus foncé qui
/// donne du relief, reflet en haut, et qui s'enfonce quand on appuie.
class _StickerTile extends StatefulWidget {
  const _StickerTile({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.subtitle,
  });

  final String label;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  State<_StickerTile> createState() => _StickerTileState();
}

class _StickerTileState extends State<_StickerTile> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    const fg = Colors.white;
    return Semantics(
      button: true,
      label: widget.subtitle == null
          ? widget.label
          : '${widget.label}, ${widget.subtitle}',
      excludeSemantics: true,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) {
          setState(() => _down = false);
          HapticFeedback.lightImpact();
          widget.onTap();
        },
        // Tuile plate : la couleur, l'icône et le texte. Un léger
        // rétrécissement montre l'appui.
        child: AnimatedScale(
          scale: _down ? 0.96 : 1,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: LayoutBuilder(
            builder: (context, c) {
              // Sur tablette, les grandes tuiles ont un texte plus grand.
              final k = (math.min(c.maxWidth, c.maxHeight) / 180).clamp(
                1.0,
                1.5,
              );
              return DecoratedBox(
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(widget.icon, size: 48 * k, color: fg),
                          const SizedBox(height: 10),
                          ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: 170 * k),
                            child: Text(
                              widget.label,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              style: TextStyle(
                                color: fg,
                                fontSize: 21 * k,
                                fontWeight: FontWeight.w800,
                                height: 1.1,
                                // Lisible même en blanc sur le jaune.
                                shadows: const [
                                  Shadow(
                                    color: Color(0x40000000),
                                    blurRadius: 6,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (widget.subtitle != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              widget.subtitle!,
                              style: TextStyle(
                                color: fg.withValues(alpha: 0.85),
                                fontSize: 18 * k,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Décor discret : quelques autocollants dispersés sur le fond crème.
class _StickerConfetti extends CustomPainter {
  const _StickerConfetti();

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(7);
    const colors = [
      HomeColors.blue,
      HomeColors.red,
      HomeColors.yellow,
      HomeColors.green,
      HomeColors.orange,
    ];
    for (var k = 0; k < 14; k++) {
      final s = 18.0 + rnd.nextDouble() * 22;
      final x = rnd.nextDouble() * size.width;
      final y = rnd.nextDouble() * size.height;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate((rnd.nextDouble() - 0.5) * 0.8);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: s, height: s),
          Radius.circular(s * 0.22),
        ),
        Paint()..color = colors[k % colors.length].withValues(alpha: 0.08),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_StickerConfetti old) => false;
}
