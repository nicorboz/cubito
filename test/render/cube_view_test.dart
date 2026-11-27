// Tests du cube 3D : gestes au doigt → bons mouvements, animation.
import 'package:cube_magique/core/cube/cube.dart';
import 'package:cube_magique/render/cube_controller.dart';
import 'package:cube_magique/render/cube_scene.dart';
import 'package:cube_magique/render/cube_view.dart';
import 'package:cube_magique/render/math3d.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const size = Size(600, 600);

/// Centre à l'écran de l'autocollant [i] (caméra par défaut).
Offset stickerCenter(int i) {
  final proj = Projector(size, const CubeCamera());
  final p = stickerPositions[i], n = stickerNormals[i];
  return proj.project(V3(p.x + n.x * 0.5, p.y + n.y * 0.5, p.z + n.z * 0.5));
}

Future<Move?> swipe(WidgetTester tester, int facelet, Offset delta) async {
  Move? got;
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final c = CubeController();
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: CubeView(controller: c, onSwipeMove: (m) => got = m),
      ),
    ),
  );
  final start =
      tester.getTopLeft(find.byType(CubeView)) + stickerCenter(facelet);
  final g = await tester.startGesture(start);
  for (var k = 1; k <= 6; k++) {
    await g.moveTo(start + delta * (k / 6));
  }
  await g.up();
  await tester.pump(const Duration(seconds: 1));
  return got;
}

void main() {
  // Facettes de la face avant : F0..F8 = 18..26.
  testWidgets('Colonne de droite vers le haut = R', (t) async {
    expect(await swipe(t, 23, const Offset(0, -80)), Move.parse('R'));
  });
  testWidgets('Colonne de droite vers le bas = R\'', (t) async {
    expect(await swipe(t, 26, const Offset(0, 80)), Move.parse("R'"));
  });
  testWidgets('Colonne de gauche vers le bas = L ; vers le haut = L\'', (
    t,
  ) async {
    expect(await swipe(t, 21, const Offset(0, 80)), Move.parse('L'));
    expect(await swipe(t, 24, const Offset(0, -80)), Move.parse("L'"));
  });
  testWidgets('Ligne du haut vers la gauche = U ; vers la droite = U\'', (
    t,
  ) async {
    expect(await swipe(t, 19, const Offset(-80, 0)), Move.parse('U'));
    expect(await swipe(t, 18, const Offset(80, 0)), Move.parse("U'"));
  });
  testWidgets('Ligne du bas vers la droite = D ; vers la gauche = D\'', (
    t,
  ) async {
    expect(await swipe(t, 25, const Offset(80, 0)), Move.parse('D'));
    expect(await swipe(t, 26, const Offset(-80, 0)), Move.parse("D'"));
  });
  testWidgets('Sur la face de droite, colonne avant vers le haut = F\'', (
    t,
  ) async {
    expect(await swipe(t, 12, const Offset(0, -80)), Move.parse("F'"));
  });
  testWidgets('Ligne du milieu : aucun mouvement (pas dans la méthode)', (
    t,
  ) async {
    expect(await swipe(t, 22, const Offset(-80, 0)), isNull);
  });

  testWidgets('Un mouvement animé arrive bien au bon état', (tester) async {
    final c = CubeController();
    await tester.pumpWidget(MaterialApp(home: CubeView(controller: c)));
    var done = false;
    c.play(parseMoves("R U R' U'")).then((_) => done = true);
    for (var k = 0; k < 40 && !done; k++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(done, isTrue);
    expect(c.cube, Cube.solved().apply("R U R' U'"));
    expect(c.isAnimating, isFalse);
  });

  test('Rotation de caméra limitée verticalement', () {
    final c = CubeController();
    c.orbit(0, 100);
    expect(c.camera.pitch, lessThan(1.5));
  });
}
