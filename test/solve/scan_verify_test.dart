// Écran de vérification du scan, avec des mesures fabriquées.
import 'package:cube_magique/app.dart';
import 'package:cube_magique/core/cube/cube.dart';
import 'package:cube_magique/core/scan/color_lab.dart';
import 'package:cube_magique/core/scan/scan_plan.dart';
import 'package:cube_magique/features/scan/scan_verify_screen.dart';
import 'package:cube_magique/render/cube_controller.dart';
import 'package:cube_magique/render/cube_view.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../test_app.dart';

const rgbOf = {
  CubeColor.white: Rgb(230, 230, 225),
  CubeColor.yellow: Rgb(235, 215, 25),
  CubeColor.red: Rgb(195, 25, 35),
  CubeColor.orange: Rgb(250, 110, 15),
  CubeColor.blue: Rgb(15, 70, 195),
  CubeColor.green: Rgb(5, 155, 70),
};

/// Les 6 faces « vues par la caméra » d'un cube (ordre du plan de scan).
List<List<Lab>> facesOf(Cube cube) {
  var held = cube;
  return [
    for (final s in scanPlan)
      () {
        held = held.apply(s.rotation);
        return [
          for (var k = 0; k < 9; k++)
            rgbToLab(rgbOf[held[Face.f.index * 9 + k]]!),
        ];
      }(),
  ];
}

class _Host extends StatefulWidget {
  const _Host(this.faces, this.onResult);
  final List<List<Lab>> faces;
  final ValueChanged<VerifyResult?> onResult;
  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: FilledButton(
        onPressed: () async {
          final r = await Navigator.of(context).push<VerifyResult>(
            MaterialPageRoute(
              builder: (_) => ScanVerifyScreen(faces: widget.faces),
            ),
          );
          widget.onResult(r);
        },
        child: const Text('go'),
      ),
    ),
  );
}

void main() {
  testWidgets('Scan correct : « Oui, c\'est mon cube » renvoie le bon cube', (
    tester,
  ) async {
    final cube = Cube.solved().apply("R U F' D2 L B'");
    VerifyResult? got;
    await pumpWithProviders(
      tester,
      CubeMagiqueApp(home: _Host(facesOf(cube), (r) => got = r)),
      size: const Size(420, 900),
    );
    await tester.tap(find.text('go'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text("C'est bien ton cube ?"), findsOneWidget);
    await tester.tap(find.text("Oui, c'est mon cube"));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(got, isA<VerifyConfirmed>());
    expect(Cube.fromColors((got! as VerifyConfirmed).colors), cube);
  });

  testWidgets('Face montrée tournée : remise dans le bon sens toute seule', (
    tester,
  ) async {
    final cube = Cube.solved().apply("R U F'");
    final faces = facesOf(cube);
    // La face verte a été montrée tournée d'un quart de tour (erreur typique).
    final g = faces[1];
    faces[1] = [g[6], g[3], g[0], g[7], g[4], g[1], g[8], g[5], g[2]];
    VerifyResult? got;
    await pumpWithProviders(
      tester,
      CubeMagiqueApp(home: _Host(faces, (r) => got = r)),
      size: const Size(420, 900),
    );
    await tester.tap(find.text('go'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text("Oui, c'est mon cube"));
    await tester.pump();
    await tester.pump();
    expect(got, isA<VerifyConfirmed>());
    expect((got! as VerifyConfirmed).colors, cube.colors);
  });

  testWidgets('Coin tourné à la main : explication, et on recommence', (
    tester,
  ) async {
    // Coin URF tourné sur lui-même (facettes 8, 9, 20).
    final t = Cube.solved().apply("R U F'").toString().split('');
    final a = t[8], b = t[9], c = t[20];
    t[8] = c;
    t[9] = a;
    t[20] = b;
    final cube = Cube.fromString(t.join());
    VerifyResult? got;
    await pumpWithProviders(
      tester,
      CubeMagiqueApp(home: _Host(facesOf(cube), (r) => got = r)),
      size: const Size(420, 900),
    );
    await tester.tap(find.text('go'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text("Oui, c'est mon cube"));
    await tester.pump();
    expect(
      find.textContaining('Un coin a été tourné à la main'),
      findsOneWidget,
    );
    await tester.ensureVisible(find.text('Recommencer le scan'));
    await tester.tap(find.text('Recommencer le scan'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(got, isA<VerifyRescan>());
  });

  testWidgets('Toucher une case ouvre la palette', (tester) async {
    await pumpWithProviders(
      tester,
      CubeMagiqueApp(home: ScanVerifyScreen(faces: facesOf(Cube.solved()))),
      size: const Size(420, 900),
    );
    await tester.pump(const Duration(milliseconds: 300));
    final view = tester.widget<CubeView>(find.byType(CubeView));
    expect(view.onStickerTap, isNotNull);
    view.onStickerTap!(20); // une case de la face avant
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Choisis la bonne couleur'), findsOneWidget);
    expect(view.controller, isA<CubeController>());
  });
}
