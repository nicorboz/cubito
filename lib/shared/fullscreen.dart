// Plein écran « immersif » : l'appli occupe tout l'écran, sans la barre de
// navigation ni la barre d'état d'Android. Un glissement depuis le bord fait
// réapparaître les barres quelques secondes, puis elles se cachent seules.
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

/// Active le mode plein écran immersif.
Future<void> enterFullscreen() async {
  if (kIsWeb) return; // navigateur : il gère lui-même son plein écran
  return SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
}

/// Réactive le plein écran quand l'enfant revient dans l'appli (après être
/// passé par une autre appli ou avoir verrouillé l'écran), car Android peut
/// alors réafficher les barres.
class FullscreenKeeper extends StatefulWidget {
  const FullscreenKeeper({super.key, required this.child});
  final Widget child;

  @override
  State<FullscreenKeeper> createState() => _FullscreenKeeperState();
}

class _FullscreenKeeperState extends State<FullscreenKeeper>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Si les barres réapparaissent (glissement depuis le bord), on les
    // recache automatiquement après un court instant.
    SystemChrome.setSystemUIChangeCallback((barsVisible) async {
      if (barsVisible) {
        await Future<void>.delayed(const Duration(seconds: 3));
        await enterFullscreen();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) enterFullscreen();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    SystemChrome.setSystemUIChangeCallback(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
