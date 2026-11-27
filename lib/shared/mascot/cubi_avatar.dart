// Avatar 3D animé de Cubito (cube-puzzle avec un visage expressif).
//
// Sur Android, il est affiché par une WebView native hors ligne
// (android/app/src/main/assets/cubi/index.html, Three.js inclus, aucune
// permission Internet). Ailleurs (iPhone, tests), on garde la mascotte
// dessinée en Flutter (Cubito).
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';
import 'cubito.dart';

/// Les 6 expressions de l'avatar.
enum CubiMood {
  /// Par défaut : content, au repos.
  joyeux('joyeux'),

  /// Bravo, réussite (souvent avec un saut).
  rire('rire'),

  /// Complice : astuce, indice.
  clin('clin'),

  /// Nouveauté, découverte.
  surpris('surpris'),

  /// Erreur : on encourage.
  triste('triste'),

  /// Pause : l'enfant ne touche plus l'écran.
  dodo('dodo');

  const CubiMood(this.jsName);
  final String jsName;
}

class CubiAvatar extends StatefulWidget {
  const CubiAvatar({
    super.key,
    this.size = 160,
    this.mood = CubiMood.joyeux,
    this.jumpOnShow = false,
    this.onPoke,
  });

  final double size;
  final CubiMood mood;

  /// Saute en riant dès qu'il apparaît (écrans de réussite).
  final bool jumpOnShow;

  /// L'enfant a touché l'avatar.
  final VoidCallback? onPoke;

  /// Avatar 3D natif disponible (Android, hors tests).
  static bool useNative =
      !kIsWeb &&
      Platform.isAndroid &&
      !Platform.environment.containsKey('FLUTTER_TEST');

  static const viewType = 'cubito/avatar';

  @override
  State<CubiAvatar> createState() => _CubiAvatarState();
}

class _CubiAvatarState extends State<CubiAvatar> {
  MethodChannel? _channel;
  bool _ready = false;

  void _created(int id) {
    final channel = MethodChannel('cubito/avatar_$id');
    channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onReady':
          if (!mounted) return;
          setState(() => _ready = true);
          _visible = null;
          _syncVisibility();
          if (widget.jumpOnShow) channel.invokeMethod<void>('poke');
        case 'onPoke':
          widget.onPoke?.call();
      }
    });
    _channel = channel;
  }

  bool? _visible;

  // L'avatar ne s'anime que si son écran est au premier plan : sous un autre
  // écran, il est mis en pause (un seul avatar calcule à la fois).
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncVisibility();
  }

  void _syncVisibility() {
    final visible = ModalRoute.isCurrentOf(context) ?? true;
    if (visible == _visible || _channel == null) return;
    _visible = visible;
    _channel!.invokeMethod<void>(visible ? 'resume' : 'pause');
  }

  @override
  void didUpdateWidget(CubiAvatar old) {
    super.didUpdateWidget(old);
    if (old.mood != widget.mood) {
      _channel?.invokeMethod<void>('setExpression', widget.mood.jsName);
    }
  }

  @override
  void dispose() {
    _channel?.setMethodCallHandler(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!CubiAvatar.useNative) {
      return Cubito(size: widget.size, onTap: widget.onPoke);
    }
    return Semantics(
      button: widget.onPoke != null,
      label: AppLocalizations.of(context).mascotLabel,
      child: SizedBox.square(
        dimension: widget.size,
        // Le temps que la 3D se charge, l'avatar reste invisible puis apparaît
        // en fondu (pas de carré vide qui clignote).
        child: AnimatedOpacity(
          opacity: _ready ? 1 : 0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          child: AndroidView(
            viewType: CubiAvatar.viewType,
            layoutDirection: TextDirection.ltr,
            creationParams: {'expression': widget.mood.jsName},
            creationParamsCodec: const StandardMessageCodec(),
            onPlatformViewCreated: _created,
            // L'avatar reçoit directement le doigt (regard qui suit, saut).
            gestureRecognizers: {
              Factory<OneSequenceGestureRecognizer>(EagerGestureRecognizer.new),
            },
          ),
        ),
      ),
    );
  }
}

/// Petite bulle « Cubito + message » pour les réussites et les erreurs.
class CubiSays extends StatelessWidget {
  const CubiSays({
    super.key,
    required this.mood,
    required this.message,
    this.size = 84,
    this.jumpOnShow = false,
    this.style,
  });

  final CubiMood mood;
  final String message;
  final double size;
  final bool jumpOnShow;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CubiAvatar(size: size, mood: mood, jumpOnShow: jumpOnShow),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            message,
            style: style ?? Theme.of(context).textTheme.titleMedium,
          ),
        ),
      ],
    );
  }
}
