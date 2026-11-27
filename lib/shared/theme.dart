// Thème visuel pour enfants : couleurs vives, police arrondie, gros textes.
import 'package:material_ui/material_ui.dart';

/// Palette de l'application. Contrastes vérifiés pour du texte blanc ou
/// sombre selon le fond (WCAG AA).
abstract final class CubeColors {
  static const background = Color(0xFFFFF8EC); // crème doux
  static const ink = Color(0xFF2B2140); // texte principal (violet très foncé)
  static const learn = Color(0xFF1E8E3E); // vert
  static const solve = Color(0xFF1765CC); // bleu
  static const practice = Color(0xFFC2410C); // orange foncé
  static const trophies = Color(0xFF7B3FC4); // violet

  // Couleurs des faces du cube (rendu 3D et mascotte).
  static const cubeWhite = Color(0xFFFFFFFF);
  static const cubeYellow = Color(0xFFFFD500);
  static const cubeRed = Color(0xFFE53935);
  static const cubeOrange = Color(0xFFFF8F00);
  static const cubeBlue = Color(0xFF1E66F5);
  static const cubeGreen = Color(0xFF2EB82E);
}

/// Taille minimale des zones tactiles (le cahier des charges impose 56 dp).
const double kMinTouchTarget = 56;

ThemeData buildCubeTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: CubeColors.solve,
    surface: CubeColors.background,
  );

  // Tailles de texte : jamais en dessous de 18 sp.
  const textTheme = TextTheme(
    displaySmall: TextStyle(fontSize: 36, fontWeight: FontWeight.w900),
    headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
    headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
    titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
    titleMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
    bodyLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w400),
    bodyMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w400),
    labelLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
  );

  return ThemeData(
    colorScheme: scheme,
    scaffoldBackgroundColor: CubeColors.background,
    fontFamily: 'Nunito',
    textTheme: textTheme.apply(
      bodyColor: CubeColors.ink,
      displayColor: CubeColors.ink,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: CubeColors.ink,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontFamily: 'Nunito',
        fontSize: 24,
        fontWeight: FontWeight.w900,
        color: CubeColors.ink,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        minimumSize: const Size(kMinTouchTarget, kMinTouchTarget),
        iconSize: 32,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(kMinTouchTarget * 3, kMinTouchTarget),
        textStyle: const TextStyle(
          fontFamily: 'Nunito',
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    ),
    // Transitions douces entre écrans.
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {TargetPlatform.android: FadeForwardsPageTransitionsBuilder()},
    ),
  );
}
