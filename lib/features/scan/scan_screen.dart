// Scan du cube à la caméra, pensé pour un enfant de 8 ans :
// vidéo en direct (pas de photo à prendre), capture automatique quand les
// 9 cases sont stables ~0,7 s, ordre des faces et gestes imposés.
// Aucune image n'est enregistrée ni envoyée : on lit juste 9 couleurs.
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/cube/cube.dart';
import '../../core/scan/capture_logic.dart';
import '../../core/scan/color_lab.dart';
import '../../core/scan/face_detector.dart';
import '../../core/scan/frame_analyzer.dart';
import '../../core/scan/scan_plan.dart';
import '../../core/scan/scan_reader.dart';
import '../../l10n/app_localizations.dart';
import '../../render/cube_controller.dart';
import '../../render/cube_scene.dart';
import '../../render/cube_view.dart';
import '../../shared/color_text.dart';
import '../../shared/prefs.dart';
import '../../shared/sounds.dart';
import '../../shared/speech.dart';
import '../../shared/theme.dart';
import '../../shared/widgets/pill_button.dart';

/// Consigne du geste à faire avant une face.
String gestureText(AppLocalizations l, ScanGesture g) => switch (g) {
  ScanGesture.start => l.scanStart,
  ScanGesture.rollTowardYou => l.scanRoll,
  ScanGesture.turnLeft => l.scanTurnLeft,
  ScanGesture.turnLeftTwice => l.scanTurnLeftTwice,
};

String adviceText(AppLocalizations l, ScanAdvice a) => switch (a) {
  ScanAdvice.tooDark => l.scanTooDarkTorch,
  ScanAdvice.closer => l.scanCloser,
  ScanAdvice.holdStill => l.scanHoldStill,
  ScanAdvice.wrongFace => l.scanWrongFace,
  ScanAdvice.notFound => l.scanNotFound,
  ScanAdvice.doGesture => l.scanDoGesture,
  ScanAdvice.none => '',
};

/// Résultat : les 54 mesures (Lab), ou null si l'enfant abandonne.
class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key, this.onlyStep, this.previous});

  /// Refaire une seule face (indice dans [scanPlan]).
  final int? onlyStep;

  /// Mesures déjà faites (pour ne refaire qu'une face).
  final List<List<Lab>>? previous;

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  CameraController? _camera;
  bool _introDone = false;
  bool _failed = false;
  late int _step = widget.onlyStep ?? 0;
  late final List<List<Lab>?> _faces = widget.previous == null
      ? List.filled(6, null)
      : [...widget.previous!];
  late final CaptureLogic _logic = CaptureLogic(
    expectedCenter: scanPlan[_step].center,
  );
  ScanAdvice _advice = ScanAdvice.none;
  bool _busy = false;
  int _rotation = 90;
  bool _mirror = false;
  final _clock = Stopwatch()..start();
  DateTime _lastFrame = DateTime.fromMillisecondsSinceEpoch(0);

  /// Pause après une capture : le temps de faire le geste suivant.
  DateTime _pauseUntil = DateTime.fromMillisecondsSinceEpoch(0);
  bool _flash = false;

  /// Lampe de la tablette (flash) allumée ?
  bool _torch = false;
  bool _torchAvailable = true;

  // Petit cube qui montre le geste à faire.
  final _demo = CubeController(camera: const CubeCamera(yaw: -0.5, pitch: 0.35))
    ..quarterTurnDuration = const Duration(milliseconds: 700);
  Timer? _demoTimer;

  @override
  void initState() {
    super.initState();
    // Écran du scan tenu en portrait (plus simple pour viser).
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _introDone = ref.read(prefsProvider).getBool('cameraIntroSeen') ?? false;
    if (_introDone) _startCamera();
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([]);
    _demoTimer?.cancel();
    _demo.dispose();
    final cam = _camera;
    _camera = null;
    if (kIsWeb) {
      cam?.dispose();
    } else {
      cam?.stopImageStream().catchError((_) {}).whenComplete(cam.dispose);
    }
    super.dispose();
  }

  Future<void> _startCamera() async {
    try {
      final cams = await availableCameras();
      if (cams.isEmpty) throw CameraException('none', 'no camera');
      final back = cams.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cams.first,
      );
      final controller = CameraController(
        back,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );
      await controller.initialize(); // demande la permission ici
      if (!mounted) {
        controller.dispose();
        return;
      }
      // Navigateur : la photo est déjà retournée comme l'aperçu.
      _mirror = !kIsWeb && back.lensDirection == CameraLensDirection.front;
      // Mise au point et lumière réglées sur le CENTRE (le cube), pas sur
      // tout le décor : couleurs plus justes devant une fenêtre ou un mur
      // sombre. Pas grave si l'appareil ne sait pas le faire.
      for (final setup in <Future<void> Function()>[
        () => controller.setFocusMode(FocusMode.auto),
        () => controller.setFocusPoint(const Offset(0.5, 0.5)),
        () => controller.setExposurePoint(const Offset(0.5, 0.5)),
      ]) {
        try {
          await setup();
        } catch (_) {}
      }
      setState(() => _camera = controller);
      if (kIsWeb) {
        // Navigateur : pas de flux d'images, on prend de petites photos
        // l'une après l'autre (rien n'est enregistré ni envoyé).
        _webLoop(controller);
      } else {
        await controller.startImageStream(_onImage);
      }
      _announceStep();
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  /// Rotation de l'image capteur → image droite (méthode recommandée par
  /// Google pour l'analyse d'images).
  int _imageRotation(CameraController c) {
    const deg = {
      DeviceOrientation.portraitUp: 0,
      DeviceOrientation.landscapeLeft: 90,
      DeviceOrientation.portraitDown: 180,
      DeviceOrientation.landscapeRight: 270,
    };
    final device = deg[c.value.deviceOrientation] ?? 0;
    final sensor = c.description.sensorOrientation;
    return c.description.lensDirection == CameraLensDirection.front
        ? (sensor + device) % 360
        : (sensor - device + 360) % 360;
  }

  /// Version web : une petite photo toutes les ~150 ms, décodée en pixels
  /// puis lue exactement comme une image de téléphone.
  Future<void> _webLoop(CameraController cam) async {
    while (mounted && _camera == cam && _step < 6) {
      final started = DateTime.now();
      try {
        if (!started.isBefore(_pauseUntil)) {
          final shot = await cam.takePicture();
          final bytes = await shot.readAsBytes();
          final codec = await ui.instantiateImageCodec(bytes);
          final image = (await codec.getNextFrame()).image;
          final data = await image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          );
          final w = image.width, h = image.height;
          image.dispose();
          if (data != null && mounted && _camera == cam && _step < 6) {
            // L'image du navigateur est déjà droite (rotation 0).
            _processFrame(
              YuvFrame.fromRgba(w, h, data.buffer.asUint8List()),
              rotation: 0,
            );
          }
        }
      } catch (_) {
        // Photo ratée : on réessaie un peu plus tard.
      }
      final spent = DateTime.now().difference(started).inMilliseconds;
      await Future<void>.delayed(
        Duration(milliseconds: math.max(30, 150 - spent)),
      );
    }
  }

  void _onImage(CameraImage img) {
    final cam = _camera;
    if (cam == null || _busy || _step >= 6) return;
    final now = DateTime.now();
    if (now.isBefore(_pauseUntil)) return;
    if (now.difference(_lastFrame).inMilliseconds < 90) return; // ~10 images/s
    _lastFrame = now;
    if (img.planes.length < 3) return;
    _processFrame(
      YuvFrame(
        width: img.width,
        height: img.height,
        y: img.planes[0].bytes,
        yRowStride: img.planes[0].bytesPerRow,
        u: img.planes[1].bytes,
        v: img.planes[2].bytes,
        uvRowStride: img.planes[1].bytesPerRow,
        uvPixelStride: img.planes[1].bytesPerPixel ?? 1,
      ),
      rotation: _imageRotation(cam),
    );
  }

  /// Lit une image (téléphone ou navigateur) et fait avancer la capture.
  void _processFrame(YuvFrame frame, {required int rotation}) {
    if (_busy || _step >= 6) return;
    if (DateTime.now().isBefore(_pauseUntil)) return;
    _busy = true;
    try {
      _rotation = rotation;
      final result = readFace(frame, rotation: _rotation, mirror: _mirror);
      final captured = _logic.feed(_clock.elapsed, result);
      if (captured != null) {
        _onCaptured(captured);
      } else {
        _advice = _logic.advice;
        // Rafraîchit l'aperçu (cadre, « je vois », progression).
        if (mounted) setState(() {});
      }
    } catch (_) {
      // Image illisible : on attend la suivante.
    } finally {
      _busy = false;
    }
  }

  void _onCaptured(List<Lab> labs) {
    HapticFeedback.mediumImpact();
    ref.read(soundsProvider).play(Sfx.bip);
    _faces[_step] = labs;
    setState(() {
      _flash = true;
      _advice = ScanAdvice.none;
    });
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => _flash = false);
    });
    // Face suivante (ou fin).
    final next = widget.onlyStep != null ? 6 : _step + 1;
    if (next >= 6 || _faces.every((f) => f != null)) {
      _finish();
      return;
    }
    // Petit temps de pause : on laisse l'enfant faire le geste.
    _step = next;
    _logic.reset(scanPlan[_step].center, previous: labs[4]);
    _pauseUntil = DateTime.now().add(const Duration(milliseconds: 2500));
    _announceStep();
  }

  /// Allume / éteint la lampe (zones sombres).
  Future<void> _toggleTorch() async {
    final cam = _camera;
    if (cam == null) return;
    try {
      await cam.setFlashMode(_torch ? FlashMode.off : FlashMode.torch);
      setState(() => _torch = !_torch);
    } catch (_) {
      setState(() => _torchAvailable = false); // pas de lampe sur cet appareil
    }
  }

  /// Capture manuelle (si la capture automatique n'y arrive pas).
  void _takeNow() {
    final labs = _logic.captureNow();
    if (labs != null) _onCaptured(labs);
  }

  void _finish() {
    _step = 6;
    if (!kIsWeb) _camera?.stopImageStream().catchError((_) {});
    Navigator.of(context).pop(<List<Lab>>[for (final f in _faces) f!]);
  }

  /// Annonce le geste et anime le petit cube de démonstration.
  void _announceStep() {
    if (!mounted || _step >= 6) return;
    final l = AppLocalizations.of(context);
    final s = scanPlan[_step];
    final text = widget.onlyStep != null
        ? l.scanShowCenter(colorName(l, s.center), colorName(l, s.top))
        : gestureText(l, s.gesture);
    ref.read(speechProvider).speak(text);
    setState(() {});
    // Le petit cube montre la position AVANT le geste puis le geste.
    var before = Cube.solved();
    for (var k = 0; k < _step; k++) {
      before = before.apply(scanPlan[k].rotation);
    }
    final gesture = s.gesture == ScanGesture.start
        ? <Move>[]
        : parseMoves(s.rotation);
    void loop() {
      if (!mounted) return;
      _demo.jumpTo(
        widget.onlyStep != null || gesture.isEmpty
            ? before.apply(s.rotation)
            : before,
      );
      if (gesture.isNotEmpty && widget.onlyStep == null) _demo.play(gesture);
    }

    _demoTimer?.cancel();
    loop();
    _demoTimer = Timer.periodic(
      const Duration(milliseconds: 2600),
      (_) => loop(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    Widget body;
    if (!_introDone) {
      body = _ParentIntro(
        onAllow: () {
          ref.read(prefsProvider).setBool('cameraIntroSeen', true);
          setState(() => _introDone = true);
          _startCamera();
        },
      );
    } else if (_failed) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.no_photography_rounded,
                size: 72,
                color: CubeColors.ink,
              ),
              const SizedBox(height: 12),
              Text(
                l.scanNoCamera,
                textAlign: TextAlign.center,
                style: t.titleLarge,
              ),
              const SizedBox(height: 16),
              PillButton(
                icon: Icons.edit_rounded,
                label: l.solveChooseHand,
                color: CubeColors.solve,
                onTap: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      );
    } else if (_camera == null || !_camera!.value.isInitialized) {
      body = const Center(child: CircularProgressIndicator());
    } else {
      final s = scanPlan[_step.clamp(0, 5)];
      final instruction = _advice != ScanAdvice.none
          ? adviceText(l, _advice)
          : (widget.onlyStep != null
                ? l.scanShowCenter(colorName(l, s.center), colorName(l, s.top))
                : gestureText(l, s.gesture));
      body = Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              instruction,
              textAlign: TextAlign.center,
              style: t.titleLarge?.copyWith(
                color: _advice != ScanAdvice.none
                    ? CubeColors.practice
                    : CubeColors.ink,
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: AspectRatio(
                // Téléphone : image du capteur couchée (on inverse le
                // rapport). Navigateur : la vidéo est déjà droite.
                aspectRatio: kIsWeb
                    ? _camera!.value.aspectRatio
                    : 1 / _camera!.value.aspectRatio,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    kIsWeb ? _camera!.buildPreview() : CameraPreview(_camera!),
                    CustomPaint(
                      painter: _GridOverlay(
                        flash: _flash,
                        face: _logic.lastFace,
                        ok: _logic.lastOk,
                        progress: _logic.progress,
                      ),
                    ),
                    Positioned(
                      right: 8,
                      bottom: 8,
                      width: 110,
                      height: 110,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: CubeView(controller: _demo, allowOrbit: false),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Wrap(
              spacing: 10,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: _logic.lastFace == null ? null : _takeNow,
                  icon: const Icon(Icons.photo_camera_rounded, size: 26),
                  label: Text(
                    l.scanTakeNow,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(200, 56),
                  ),
                ),
                if (_torchAvailable)
                  FilledButton.icon(
                    onPressed: _toggleTorch,
                    icon: Icon(
                      _torch
                          ? Icons.flashlight_off_rounded
                          : Icons.flashlight_on_rounded,
                      size: 26,
                    ),
                    label: Text(
                      _torch ? l.scanTorchOff : l.scanTorchOn,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(200, 56),
                      // Mis en avant quand l'image est trop sombre.
                      backgroundColor: _advice == ScanAdvice.tooDark && !_torch
                          ? const Color(0xFFE6A100)
                          : CubeColors.ink,
                    ),
                  ),
              ],
            ),
          ),
          // Progression : 6 pastilles ●●●○○○
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var k = 0; k < 6; k++)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _faces[k] != null
                            ? cubeColorToColor(scanPlan[k].center)
                            : Colors.transparent,
                        border: Border.all(color: CubeColors.ink, width: 2.5),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(l.solveChooseScan),
        leading: IconButton(
          tooltip: l.back,
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(child: body),
    );
  }
}

/// Grand carré guide au centre, découpé en 9 cases. Dans chaque case, une
/// pastille montre en direct la couleur lue : l'enfant voit tout de suite
/// si c'est bon. Le cadre devient vert quand la face est bien vue, et une
/// barre se remplit jusqu'à la capture.
class _GridOverlay extends CustomPainter {
  _GridOverlay({
    required this.flash,
    this.face,
    this.ok = false,
    this.progress = 0,
  });
  final bool flash;
  final FaceDetection? face;
  final bool ok;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final side = guideFraction * size.shortestSide;
    final guide = Rect.fromCenter(
      center: size.center(Offset.zero),
      width: side,
      height: side,
    );
    final outside = Path()
      ..addRect(Offset.zero & size)
      ..addRRect(RRect.fromRectAndRadius(guide, const Radius.circular(18)))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(
      outside,
      Paint()..color = Colors.black.withValues(alpha: 0.35),
    );

    final f = face;
    // Cadre : celui de la face trouvée, sinon le carré guide.
    final r = f == null || f.guided
        ? guide
        : Rect.fromLTRB(
            f.left * size.width,
            f.top * size.height,
            f.right * size.width,
            f.bottom * size.height,
          );
    final good = ok && f != null;
    canvas.drawRRect(
      RRect.fromRectAndRadius(r, const Radius.circular(16)),
      Paint()
        ..color = flash
            ? Colors.white
            : (good
                  ? CubeColors.cubeGreen
                  : Colors.white.withValues(alpha: 0.9))
        ..style = PaintingStyle.stroke
        ..strokeWidth = flash ? 9 : (good ? 6 : 3.5),
    );
    final thin = Paint()
      ..color = (good ? CubeColors.cubeGreen : Colors.white).withValues(
        alpha: 0.75,
      )
      ..strokeWidth = 2;
    for (var k = 1; k < 3; k++) {
      canvas.drawLine(
        Offset(r.left + r.width * k / 3, r.top),
        Offset(r.left + r.width * k / 3, r.bottom),
        thin,
      );
      canvas.drawLine(
        Offset(r.left, r.top + r.height * k / 3),
        Offset(r.right, r.top + r.height * k / 3),
        thin,
      );
    }
    // Pastilles « je vois ».
    if (f != null) {
      final cw = r.width / 3, ch = r.height / 3;
      for (var k = 0; k < 9; k++) {
        final c = Offset(
          r.left + cw * (k % 3 + 0.5),
          r.top + ch * (k ~/ 3 + 0.5),
        );
        final radius = math.min(cw, ch) * 0.17;
        canvas.drawCircle(
          c,
          radius + 3,
          Paint()..color = Colors.white.withValues(alpha: 0.95),
        );
        canvas.drawCircle(
          c,
          radius,
          Paint()..color = cubeColorToColor(nearestTypical(f.cells[k].lab)),
        );
      }
    }
    // Barre de progression sous le cadre.
    if (progress > 0) {
      final bar = Rect.fromLTWH(r.left, r.bottom + 10, r.width, 12);
      canvas.drawRRect(
        RRect.fromRectAndRadius(bar, const Radius.circular(6)),
        Paint()..color = Colors.white.withValues(alpha: 0.6),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(bar.left, bar.top, bar.width * progress, bar.height),
          const Radius.circular(6),
        ),
        Paint()..color = CubeColors.cubeGreen,
      );
    }
  }

  @override
  bool shouldRepaint(_GridOverlay old) => true;
}

/// Écran d'explication destiné au parent, avant la première demande.
class _ParentIntro extends StatelessWidget {
  const _ParentIntro({required this.onAllow});
  final VoidCallback onAllow;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            children: [
              const Icon(
                Icons.photo_camera_rounded,
                size: 72,
                color: CubeColors.solve,
              ),
              const SizedBox(height: 12),
              Text(l.scanParentTitle, style: t.headlineSmall),
              const SizedBox(height: 8),
              Text(
                l.scanParentText,
                textAlign: TextAlign.center,
                style: t.bodyLarge,
              ),
              const SizedBox(height: 20),
              PillButton(
                icon: Icons.check_rounded,
                label: l.scanAllow,
                color: CubeColors.learn,
                onTap: onAllow,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
