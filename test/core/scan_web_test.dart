// Version web : les photos du navigateur (RVBA, déjà droites) sont lues
// comme les images du téléphone. Et le code d'accès du site.
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:cube_magique/core/scan/face_detector.dart';
import 'package:cube_magique/core/scan/frame_analyzer.dart';
import 'package:cube_magique/core/scan/scan_reader.dart';
import 'package:cube_magique/features/access/access_gate.dart';
import 'package:flutter_test/flutter_test.dart';

import 'scan_camera_test.dart' show scene, nearest, randomFace;

/// Image YUV → RVBA (ce que donnerait le navigateur).
Uint8List toRgba(YuvFrame f) {
  final out = Uint8List(f.width * f.height * 4);
  for (var y = 0; y < f.height; y++) {
    for (var x = 0; x < f.width; x++) {
      final p = f.pixel(x, y);
      final i = (y * f.width + x) * 4;
      out
        ..[i] = p.r
        ..[i + 1] = p.g
        ..[i + 2] = p.b
        ..[i + 3] = 255;
    }
  }
  return out;
}

void main() {
  test('Conversion RVBA → YUV : couleurs conservées', () {
    final rgba = Uint8List.fromList([
      ...[229, 57, 53, 255], ...[255, 213, 0, 255], //
      ...[30, 102, 245, 255], ...[255, 255, 255, 255],
    ]);
    final f = YuvFrame.fromRgba(2, 2, rgba);
    // Luminosité exacte pour chaque pixel ; couleur moyennée sur 2×2.
    expect(f.y.length, 4);
    expect(f.u.length, 1);
    expect(f.y[0], (0.299 * 229 + 0.587 * 57 + 0.114 * 53).round());
    expect(f.y[3], 255);
  });

  test('Photo du navigateur (rotation 0) : face lue sans erreur', () {
    final rnd = math.Random(11);
    var ok = 0;
    const total = 30;
    for (var k = 0; k < total; k++) {
      final face = randomFace(rnd);
      final yuv = scene(face, rotation: 0, seed: k);
      final web = YuvFrame.fromRgba(yuv.width, yuv.height, toRgba(yuv));
      final r = readFace(web, rotation: 0);
      if (r.failure != DetectFailure.none || r.face == null) continue;
      final read = [for (final c in r.face!.cells) nearest(c.lab)];
      if (read.join() == face.join()) ok++;
    }
    expect(ok, greaterThanOrEqualTo(28), reason: '$ok/$total');
  });

  test('Code d\'accès', () {
    expect(isAccessCode('cubito!1234'), isTrue);
    expect(isAccessCode(' cubito!1234 '), isTrue);
    expect(isAccessCode('cubito1234'), isFalse);
    expect(isAccessCode(''), isFalse);
  });
}
