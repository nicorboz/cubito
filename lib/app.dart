// Configuration générale de l'application : thème, langue, écran d'accueil.
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:material_ui/material_ui.dart';

import 'package:flutter/foundation.dart' show kIsWeb;

import 'features/access/access_gate.dart';
import 'features/home/home_screen.dart';
import 'l10n/app_localizations.dart';
import 'shared/edge_swipe_back.dart';
import 'shared/theme.dart';

class CubeMagiqueApp extends StatefulWidget {
  const CubeMagiqueApp({super.key, this.home});

  /// Écran de départ (pour les tests) ; l'accueil par défaut.
  final Widget? home;

  @override
  State<CubeMagiqueApp> createState() => _CubeMagiqueAppState();
}

class _CubeMagiqueAppState extends State<CubeMagiqueApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      // Glisser depuis le bord gauche ou droit = revenir en arrière.
      builder: (context, child) =>
          EdgeSwipeBack(navigatorKey: _navigatorKey, child: child!),
      // Le titre est utilisé par Android dans la liste des applis récentes.
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: buildCubeTheme(),
      // Français uniquement pour l'instant, mais tous les textes passent par
      // AppLocalizations : ajouter une langue = ajouter un fichier .arb.
      locale: const Locale('fr'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: [
        AppLocalizations.delegate,
        // Material + Cupertino (boîtes de dialogue système en français).
        ...GlobalMaterialLocalizations.delegates,
        GlobalWidgetsLocalizations.delegate,
      ],
      // Version web : code d'accès demandé une fois par appareil.
      home:
          widget.home ??
          (kIsWeb ? const AccessGate(child: HomeScreen()) : const HomeScreen()),
    );
  }
}
