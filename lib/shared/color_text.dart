// Noms des couleurs et des faces en français.
import '../core/cube/cube.dart';
import '../l10n/app_localizations.dart';

String colorName(AppLocalizations l, CubeColor c) => switch (c) {
  CubeColor.white => l.colorWhite,
  CubeColor.red => l.colorRed,
  CubeColor.green => l.colorGreen,
  CubeColor.yellow => l.colorYellow,
  CubeColor.orange => l.colorOrange,
  CubeColor.blue => l.colorBlue,
};

String faceName(AppLocalizations l, CubeColor center) => switch (center) {
  CubeColor.white => l.faceWhite,
  CubeColor.red => l.faceRed,
  CubeColor.green => l.faceGreen,
  CubeColor.yellow => l.faceYellow,
  CubeColor.orange => l.faceOrange,
  CubeColor.blue => l.faceBlue,
};
