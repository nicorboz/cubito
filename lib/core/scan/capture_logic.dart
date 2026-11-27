// Capture automatique d'une face : quand la face est trouvée et que ses
// couleurs restent à peu près les mêmes pendant ~1,5 s (le temps de bien
// placer le cube). Tolérant : une
// image floue de temps en temps ne remet pas tout à zéro (on garde la
// couleur médiane). Une seule consigne simple à la fois.
import '../cube/cube.dart';
import 'color_lab.dart';
import 'face_detector.dart';

/// Consigne à donner à l'enfant.
enum ScanAdvice {
  none,
  tooDark,

  /// Pas de cube trouvé au centre : « mets ton cube dans le carré ».
  notFound,

  /// Cube trouvé mais trop petit : « rapproche-toi ».
  closer,
  wrongFace,
  holdStill,

  /// On voit encore la face d'avant : faire le geste demandé.
  doGesture,
}

/// Couleurs « typiques » sous une lumière normale (pour reconnaître le
/// centre attendu ; la vraie calibration se fait après, avec les 6 centres).
final Map<CubeColor, Lab> typicalLab = {
  CubeColor.white: rgbToLab(const Rgb(225, 225, 220)),
  CubeColor.yellow: rgbToLab(const Rgb(230, 210, 30)),
  CubeColor.red: rgbToLab(const Rgb(190, 25, 35)),
  CubeColor.orange: rgbToLab(const Rgb(245, 110, 20)),
  CubeColor.blue: rgbToLab(const Rgb(20, 70, 190)),
  CubeColor.green: rgbToLab(const Rgb(10, 155, 75)),
};

/// Couleur typique la plus proche (aperçu « je vois » à l'écran).
CubeColor nearestTypical(Lab lab) => typicalLab.entries
    .reduce((a, b) => lab.distance(a.value) <= lab.distance(b.value) ? a : b)
    .key;

/// Familles de couleurs faciles à confondre sous une lampe.
int _family(CubeColor c) => switch (c) {
  CubeColor.white || CubeColor.yellow => 0,
  CubeColor.red || CubeColor.orange => 1,
  CubeColor.green => 2,
  CubeColor.blue => 3,
};

class _Frame {
  _Frame(this.t, this.face);
  final Duration t;
  final FaceDetection face;
}

class CaptureLogic {
  CaptureLogic({
    required this.expectedCenter,
    this.stableFor = const Duration(milliseconds: 1500),
  });

  /// Couleur du centre attendu pour cette face.
  CubeColor expectedCenter;
  final Duration stableFor;

  /// Centre de la face capturée juste avant (pour attendre le geste).
  Lab? previousCenter;

  final _frames = <_Frame>[];
  Duration? _unstableSince;

  ScanAdvice advice = ScanAdvice.none;

  /// Avancement de la capture (0 à 1), pour l'anneau de progression.
  double progress = 0;

  /// Dernière face lue (aperçu « je vois »), et si elle ressemble à une
  /// vraie face (sinon : lecture du carré guide, pour le bouton manuel).
  FaceDetection? lastFace;
  bool lastOk = false;

  void reset(CubeColor expected, {Lab? previous}) {
    expectedCenter = expected;
    previousCenter = previous;
    _frames.clear();
    _unstableSince = null;
    advice = ScanAdvice.none;
    progress = 0;
    lastFace = null;
  }

  /// Ajoute une image analysée. Renvoie les 9 couleurs quand la face est
  /// capturée, sinon null (et met à jour [advice] et [progress]).
  List<Lab>? feed(Duration t, DetectResult r) {
    final face = r.face;
    lastFace = face;
    lastOk = face != null && r.failure == DetectFailure.none;
    if (face == null || r.failure != DetectFailure.none) {
      progress = 0;
      _frames.clear();
      advice = switch (r.failure) {
        DetectFailure.tooDark => ScanAdvice.tooDark,
        DetectFailure.tooSmall => ScanAdvice.closer,
        _ => ScanAdvice.notFound,
      };
      return null;
    }
    final center = face.cells[4].lab;
    // Encore la face d'avant : on attend le geste.
    final prev = previousCenter;
    if (prev != null && center.distance(prev) < 12) {
      progress = 0;
      _frames.clear();
      advice = ScanAdvice.doGesture;
      return null;
    }
    if (_clearlyWrongCenter(center)) {
      progress = 0;
      _frames.clear();
      advice = ScanAdvice.wrongFace;
      return null;
    }

    _frames.add(_Frame(t, face));
    _frames.removeWhere((f) => t - f.t > stableFor * 1.6);
    final recent = _frames.where((f) => t - f.t <= stableFor).toList();
    final medians = _medians(recent);

    // Une image « bonne » ressemble à la médiane (couleurs et position).
    // Tolérant : la caméra corrige sans cesse la lumière (les couleurs
    // bougent un peu), et une case sur neuf peut être floue un instant.
    bool good(_Frame f) {
      if (!f.face.guided && !face.guided) {
        final moved = (f.face.cx - face.cx).abs() + (f.face.cy - face.cy).abs();
        if (moved > 0.18 * face.size) return false;
      }
      var off = 0;
      for (var k = 0; k < 9; k++) {
        if (f.face.cells[k].lab.distance(medians[k]) > 20) off++;
      }
      return off <= 1;
    }

    final goodFrames = recent.where(good).toList();
    final span = recent.isEmpty ? Duration.zero : t - recent.first.t;
    final stableRatio = recent.isEmpty
        ? 0.0
        : goodFrames.length / recent.length;

    if (stableRatio >= 0.7) {
      _unstableSince = null;
      advice = ScanAdvice.none;
      progress = (span.inMilliseconds / stableFor.inMilliseconds).clamp(
        0.0,
        1.0,
      );
      if (recent.length >= 6 && span >= stableFor * 0.9) {
        final result = _medians(goodFrames);
        previousCenter = result[4];
        _frames.clear();
        progress = 0;
        return result;
      }
    } else {
      // Ça bouge : on repart de cette image, sans tout jeter d'un coup.
      _unstableSince ??= t;
      _frames.removeWhere((f) => !good(f) && f != _frames.last);
      progress = 0;
      if (t - _unstableSince! > const Duration(milliseconds: 2500)) {
        advice = ScanAdvice.holdStill;
      }
    }
    return null;
  }

  /// Capture manuelle (bouton) : la médiane des dernières images.
  List<Lab>? captureNow() {
    if (_frames.isEmpty && lastFace == null) return null;
    final result = _frames.isEmpty
        ? [for (final c in lastFace!.cells) c.lab]
        : _medians(_frames);
    previousCenter = result[4];
    _frames.clear();
    progress = 0;
    return result;
  }

  static List<Lab> _medians(List<_Frame> frames) {
    if (frames.isEmpty) return const [];
    double med(List<double> v) {
      v.sort();
      return v[v.length ~/ 2];
    }

    return [
      for (var k = 0; k < 9; k++)
        Lab(
          med([for (final f in frames) f.face.cells[k].lab.l]),
          med([for (final f in frames) f.face.cells[k].lab.a]),
          med([for (final f in frames) f.face.cells[k].lab.b]),
        ),
    ];
  }

  /// Le centre ressemble nettement à une couleur d'une AUTRE famille que
  /// celle attendue (on ne refuse jamais blanc/jaune ni rouge/orange : la
  /// lumière les mélange ; la vérification finale rattrape).
  bool _clearlyWrongCenter(Lab center) {
    final nearest = nearestTypical(center);
    if (_family(nearest) == _family(expectedCenter)) return false;
    final dExpected = center.distance(typicalLab[expectedCenter]!);
    final dNearest = center.distance(typicalLab[nearest]!);
    return dNearest * 3 < dExpected;
  }
}
