// Vérification PAR SIMULATION de chaque algorithme de la méthode (section 4
// du cahier des charges) : on part d'états déclencheurs et on vérifie que
// l'algorithme fait exactement l'effet annoncé sans casser les étapes
// précédentes.
import 'dart:math';

import 'package:cube_magique/core/cube/cube.dart';
import 'package:cube_magique/core/cube/cubies.dart';
import 'package:cube_magique/core/method/method.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

/// Arêtes / coins hors de place après l'algorithme, depuis le cube résolu.
Set<int> movedEdges(String alg) {
  final v = CubieView.of(Cube.solved().apply(alg));
  return {
    for (var i = 0; i < 12; i++)
      if (!v.edgeSolved(i)) i,
  };
}

Set<int> movedCorners(String alg) {
  final v = CubieView.of(Cube.solved().apply(alg));
  return {
    for (var i = 0; i < 8; i++)
      if (!v.cornerSolved(i)) i,
  };
}

// Indices (voir cubies.dart).
const ur = 0, uf = 1, ul = 2, ub = 3, fr = 8, fl = 9;
const urf = 0, ufl = 1, ulb = 2, ubr = 3, dfr = 4;

void main() {
  group('Vocabulaire enfant : sens réel des mouvements vus de face', () {
    // On suit la rangée de devant (vert) pour voir où elle part.
    List<CubeColor> row(Cube c, List<int> idx) => [for (final i in idx) c[i]];
    const green = [CubeColor.green, CubeColor.green, CubeColor.green];

    test('U : la ligne du haut part vers la GAUCHE', () {
      expect(row(Cube.solved().apply('U'), [36, 37, 38]), green);
    });
    test("U' : la ligne du haut part vers la DROITE", () {
      expect(row(Cube.solved().apply("U'"), [9, 10, 11]), green);
    });
    test("D : la ligne du bas part vers la DROITE ; D' vers la gauche", () {
      expect(row(Cube.solved().apply('D'), [15, 16, 17]), green);
      expect(row(Cube.solved().apply("D'"), [42, 43, 44]), green);
    });
    test("R : la colonne de droite MONTE ; R' descend", () {
      expect(row(Cube.solved().apply('R'), [2, 5, 8]), green);
      expect(row(Cube.solved().apply("R'"), [29, 32, 35]), green);
    });
    test("L : la colonne de gauche DESCEND ; L' monte", () {
      expect(row(Cube.solved().apply('L'), [27, 30, 33]), green);
      expect(row(Cube.solved().apply("L'"), [0, 3, 6]), green);
    });
    test("F : la face avant tourne comme une horloge ; F' à l'envers", () {
      const white = [CubeColor.white, CubeColor.white, CubeColor.white];
      expect(
        row(Cube.solved().apply('F'), [9, 12, 15]),
        white,
      ); // vers la droite
      expect(
        row(Cube.solved().apply("F'"), [38, 41, 44]),
        white,
      ); // vers la gauche
    });
    test('y : tout le cube tourne, rien ne se dérègle', () {
      expect(Cube.solved().apply('y').isSolved, isTrue);
    });
  });

  group('Étape 1 — marguerite puis croix', () {
    test(
      'Pétale aligné + 2 fois la face avant → arête blanche en bas, alignée',
      () {
        // Fabrique : jaune en haut, une arête blanche posée en pétale devant.
        final daisy = solvedYellowUp().apply(
          'F2',
        ); // l'arête blanche avant monte
        expect(daisy[7], CubeColor.white); // pétale sur le jaune
        expect(daisy[19], daisy.center(Face.f)); // aligné avec son centre
        final back = daisy.apply('F2');
        expect(back.apply('x2').isSolved, isTrue);
      },
    );
  });

  group('La petite danse (R\' D\' R D)', () {
    test('× 6 = identité', () {
      expect(
        Cube.solved()
            .apply(List.filled(6, Algorithm.petiteDanse.notation).join(' '))
            .isSolved,
        isTrue,
      );
    });

    test('Ne touche que le coin en haut à droite dans la couche du haut', () {
      for (var n = 1; n <= 5; n++) {
        final alg = List.filled(n, Algorithm.petiteDanse.notation).join(' ');
        final corners = movedCorners(alg);
        expect(corners.intersection({ufl, ulb, ubr}), isEmpty);
        expect(movedEdges(alg).intersection({ur, uf, ul, ub}), isEmpty);
      }
    });

    test('Étape 3 : 1× si blanc à droite, 3× dessous, 5× devant', () {
      // États déclencheurs : croix blanche faite, coins mélangés
      // (marches aléatoires avec D, y et la petite danse).
      final rnd = Random(20);
      final counts = <WhiteCornerFacing, int>{};
      for (var t = 0; t < 3000; t++) {
        final c = randomWalk(
          Cube.solved(),
          ['D', 'y', Algorithm.petiteDanse.notation],
          30,
          rnd,
        );
        expect(isWhiteCrossDone(c), isTrue);
        // Le coin qui va en haut à droite est-il juste en dessous ?
        final target = {
          for (final i in cornerFacelets[urf]) c.center(Face.values[i ~/ 9]),
        };
        final under = {for (final i in cornerFacelets[dfr]) c[i]};
        if (!under.containsAll(target)) continue;
        final whiteAt = cornerFacelets[dfr].firstWhere(
          (i) => c[i] == CubeColor.white,
        );
        final facing = switch (Face.values[whiteAt ~/ 9]) {
          Face.r => WhiteCornerFacing.droite,
          Face.d => WhiteCornerFacing.dessous,
          _ => WhiteCornerFacing.devant,
        };
        counts[facing] = (counts[facing] ?? 0) + 1;
        final after = c.apply(
          List.filled(facing.danses, Algorithm.petiteDanse.notation).join(' '),
        );
        // Le coin est bien placé et bien tourné…
        expect(
          cornerFacelets[urf].every(
            (i) => after[i] == after.center(Face.values[i ~/ 9]),
          ),
          isTrue,
        );
        // … la croix est intacte et les autres coins blancs déjà faits aussi.
        expect(isWhiteCrossDone(after), isTrue);
        for (final s in [ufl, ulb, ubr]) {
          final was = cornerFacelets[s].every(
            (i) => c[i] == c.center(Face.values[i ~/ 9]),
          );
          final now = cornerFacelets[s].every(
            (i) => after[i] == after.center(Face.values[i ~/ 9]),
          );
          if (was) expect(now, isTrue);
        }
      }
      // Les 3 cas ont bien été rencontrés.
      expect(counts.keys.toSet(), WhiteCornerFacing.values.toSet());
    });

    test('Étape 8b : 2 ou 4 danses par coin, puis le cube se répare tout seul', () {
      // Couche du haut : seulement des coins tournés (manège × n, danse…).
      final c = solvedYellowUp().apply(
        "${Algorithm.petiteDanse.notation} ${Algorithm.petiteDanse.notation} U "
        "${List.filled(4, Algorithm.petiteDanse.notation).join(' ')} U'",
      );
      expect(c.isSolved, isFalse);
      // Le coin à traiter (en haut à droite) : jaune pas sur le dessus.
      var x = c;
      var n = 0;
      while (x[8] != x.center(Face.u)) {
        x = x.apply(Algorithm.petiteDanse.notation);
        n++;
      }
      expect(n, anyOf(2, 4));
      x = x.apply('U');
      while (x[8] != x.center(Face.u)) {
        x = x.apply(Algorithm.petiteDanse.notation);
      }
      expect(x.apply("U'").isSolved, isTrue);
    });
  });

  group("L'escargot (R U R' U R U2 R' U)", () {
    test(
      "Échange l'arête de DEVANT et celle de GAUCHE, garde droite et fond",
      () {
        final v = CubieView.of(
          Cube.solved().apply(Algorithm.escargot.notation),
        );
        expect(v.edgePerm[uf], ul);
        expect(v.edgePerm[ul], uf);
        expect(v.edgeOri[uf] + v.edgeOri[ul], 0); // pas retournées
        expect(v.edgeSolved(ur), isTrue);
        expect(v.edgeSolved(ub), isTrue);
      },
    );

    test(
      'Ne touche que la couche du haut (croix du bas et 2 couronnes intactes)',
      () {
        expect(
          movedEdges(Algorithm.escargot.notation).every((e) => e <= ub),
          isTrue,
        );
        expect(
          movedCorners(Algorithm.escargot.notation).every((c) => c <= ubr),
          isTrue,
        );
      },
    );

    test('Règle : tourner le haut (≥ 2 alignées), face à une non alignée '
        'avec celle de droite alignée → au plus 2 escargots', () {
      final rnd = Random(21);
      final words = [
        'U',
        'y',
        Algorithm.escargot.notation,
        Algorithm.manege.notation,
      ];
      for (var t = 0; t < 500; t++) {
        var c = randomWalk(solvedYellowUp(), words, 20, rnd);
        var escargots = 0;
        for (var guard = 0; guard < 6; guard++) {
          // Tourner le haut pour avoir le plus d'arêtes alignées.
          var best = c, bestN = -1;
          var x = c;
          for (var q = 0; q < 4; q++) {
            final n = [
              (1, Face.b, 46),
              (3, Face.l, 37),
              (5, Face.r, 10),
              (7, Face.f, 19),
            ].where((e) => x[e.$3] == x.center(e.$2)).length;
            if (n > bestN) {
              best = x;
              bestN = n;
            }
            x = x.apply('U');
          }
          c = best;
          expect(bestN, greaterThanOrEqualTo(2)); // toujours au moins 2
          if (bestN == 4) break;
          // Se tourner face à une arête non alignée, celle de droite alignée.
          var placed = false;
          for (var q = 0; q < 4 && !placed; q++) {
            if (c[19] != c.center(Face.f) && c[10] == c.center(Face.r)) {
              placed = true;
            } else {
              c = c.apply('y');
            }
          }
          expect(placed, isTrue);
          c = c.apply(Algorithm.escargot.notation);
          escargots++;
        }
        expect(isYellowEdgesDone(c), isTrue);
        expect(isSecondLayerDone(c), isTrue);
        expect(escargots, lessThanOrEqualTo(2));
      }
    });
  });

  group('Les toboggans', () {
    test('Toboggan droit : arête du haut-devant → milieu-droite, rien d\'autre en bas', () {
      final v = CubieView.of(
        Cube.solved().apply(Algorithm.tobogganDroit.notation),
      );
      expect(v.edgePerm[fr], uf); // l'arête de devant est descendue à droite
      expect(
        movedEdges(Algorithm.tobogganDroit.notation)
            .every((e) => e <= ub || e == fr),
        isTrue,
      );
      expect(
        movedCorners(Algorithm.tobogganDroit.notation).every((c) => c <= ubr),
        isTrue,
      );
    });

    test('Toboggan gauche : arête du haut-devant → milieu-gauche', () {
      final v = CubieView.of(
        Cube.solved().apply(Algorithm.tobogganGauche.notation),
      );
      expect(v.edgePerm[fl], uf);
      expect(
        movedEdges(Algorithm.tobogganGauche.notation)
            .every((e) => e <= ub || e == fl),
        isTrue,
      );
      expect(
        movedCorners(Algorithm.tobogganGauche.notation).every((c) => c <= ubr),
        isTrue,
      );
    });

    test('« T à l\'envers » : la bonne arête se range sans casser la 1ʳᵉ couronne', () {
      final rnd = Random(22);
      final words = [
        'U',
        'y',
        Algorithm.tobogganDroit.notation,
        Algorithm.tobogganGauche.notation,
      ];
      var seenDroit = 0, seenGauche = 0;
      for (var t = 0; t < 3000; t++) {
        final c = randomWalk(solvedYellowUp(), words, 25, rnd);
        expect(isFirstLayerDone(c), isTrue);
        final y = c.center(Face.u);
        // T à l'envers devant : arête sans jaune, couleur avant = centre avant.
        if (c[7] == y || c[19] == y || c[19] != c.center(Face.f)) continue;
        final droite = c[7] == c.center(Face.r);
        final after = c.apply(
          droite
              ? Algorithm.tobogganDroit.notation
              : Algorithm.tobogganGauche.notation,
        );
        droite ? seenDroit++ : seenGauche++;
        final slot = droite ? fr : fl;
        expect(
          edgeFacelets[slot].every(
            (i) => after[i] == after.center(Face.values[i ~/ 9]),
          ),
          isTrue,
        );
        expect(isFirstLayerDone(after), isTrue);
        // Les arêtes du milieu déjà rangées le restent.
        for (final s in [fr, fl, 10, 11]) {
          final was = edgeFacelets[s].every(
            (i) => c[i] == c.center(Face.values[i ~/ 9]),
          );
          final now = edgeFacelets[s].every(
            (i) => after[i] == after.center(Face.values[i ~/ 9]),
          );
          if (was) expect(now, isTrue);
        }
      }
      expect(seenDroit, greaterThan(50));
      expect(seenGauche, greaterThan(50));
    });
  });

  group("L'étoile jaune", () {
    // Produit des états « 2 couronnes faites » avec tous les motifs.
    Map<YellowPattern, Cube> statesByPattern() {
      final rnd = Random(23);
      final out = <YellowPattern, Cube>{};
      final words = [
        'U',
        Algorithm.etoileJaune.notation,
        "F R U R' U' F'",
        Algorithm.escargot.notation,
      ];
      for (var t = 0; t < 2000 && out.length < 6; t++) {
        final c = randomWalk(solvedYellowUp(), words, 12, rnd);
        out.putIfAbsent(yellowPattern(c), () => c);
      }
      return out;
    }

    test('Tous les motifs sont rencontrés', () {
      expect(statesByPattern().keys.toSet(), YellowPattern.values.toSet());
    });

    test("Version du protocole R' U' F' U F R : L en haut à gauche → croix ; "
        'ligne avant-arrière → L en haut à gauche ; point → ligne', () {
      final s = statesByPattern();
      Cube star(Cube c) => c.apply(Algorithm.etoileJaune.notation);
      expect(
        yellowPattern(star(s[YellowPattern.lHautGauche]!)),
        YellowPattern.croix,
      );
      expect(
        yellowPattern(star(s[YellowPattern.ligneVerticale]!)),
        YellowPattern.lHautGauche,
      );
      expect(
        yellowPattern(star(s[YellowPattern.point]!)),
        YellowPattern.ligneHorizontale,
      );
      for (final c in s.values) {
        expect(isSecondLayerDone(star(c)), isTrue); // ne casse rien
      }
    });

    test('Règle du protocole : L 1× · ligne 2× · point 3×', () {
      final s = statesByPattern();
      int count(Cube c) {
        var n = 0;
        for (var guard = 0; guard < 10; guard++) {
          switch (yellowPattern(c)) {
            case YellowPattern.croix:
              return n;
            case YellowPattern.lAilleurs || YellowPattern.ligneHorizontale:
              c = c.apply('U'); // tourner le haut ne compte pas
            default:
              c = c.apply(Algorithm.etoileJaune.notation);
              n++;
          }
        }
        throw StateError('pas de croix');
      }

      expect(count(s[YellowPattern.lHautGauche]!), 1);
      expect(count(s[YellowPattern.ligneVerticale]!), 2);
      expect(count(s[YellowPattern.point]!), 3);
    });

    test("La version F R U R' U' F' ne suit PAS cette règle (L → ligne, pas croix)", () {
      final s = statesByPattern();
      final l = s[YellowPattern.lHautGauche]!.apply("F R U R' U' F'");
      expect(yellowPattern(l), YellowPattern.ligneHorizontale);
    });
  });

  group('Le manège des coins', () {
    test('Garde le coin en haut à droite, fait tourner les 3 autres', () {
      final v = CubieView.of(Cube.solved().apply(Algorithm.manege.notation));
      expect(v.cornerPerm[urf], urf);
      expect(v.cornerOri[urf], 0);
      expect(
        {v.cornerPerm[ufl], v.cornerPerm[ulb], v.cornerPerm[ubr]},
        {ufl, ulb, ubr},
      );
      expect(v.cornerPerm[ufl] != ufl, isTrue);
      expect(movedEdges(Algorithm.manege.notation), isEmpty); // aucune arête
      expect(
        movedCorners(Algorithm.manege.notation).every((c) => c <= ubr),
        isTrue,
      );
    });

    test('Règle : coin bien placé en haut à droite, 1 ou 2× ; aucun : 1× puis recommencer', () {
      final rnd = Random(24);
      // Arêtes jaunes déjà alignées : seuls les coins sont mélangés.
      final words = ['y', Algorithm.manege.notation];
      for (var t = 0; t < 500; t++) {
        var c = randomWalk(solvedYellowUp(), words, 15, rnd);
        var manages = 0;
        for (var guard = 0; guard < 5 && !isYellowCornersPlaced(c); guard++) {
          for (var q = 0; q < 4; q++) {
            if (isCornerPlaced(c, cornerFacelets[urf])) break;
            c = c.apply('y');
          }
          c = c.apply(Algorithm.manege.notation);
          manages++;
        }
        expect(isYellowCornersPlaced(c), isTrue);
        expect(isYellowEdgesDone(c), isTrue);
        expect(manages, lessThanOrEqualTo(3)); // 1 « n'importe où » + 2 au plus
      }
    });
  });
}
