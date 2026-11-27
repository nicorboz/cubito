# CLAUDE.md — Cube Magique

Application **Android** (iOS plus tard, même code) qui apprend à un enfant de
**7 à 12 ans** à résoudre seul un Rubik's Cube 3×3, sans notation technique.
Cahier des charges complet : document « PROMPT CubeMagique ClaudeCode.md » du
projet. Avancement : `PLAN.md`.

## Façon de travailler
- Travail par phases (voir `PLAN.md`). Fin de phase = tests verts + commit +
  résumé simple, puis **attendre le feu vert** du propriétaire.
- Le propriétaire n'est pas développeur : expliquer simplement, donner les
  commandes exactes.
- Signaler tout point ambigu ou faux du cahier des charges avant de coder.
- Code commenté en **français**, testé, sans dépendance inutile.

## Choix techniques (imposés)
- Flutter stable (3.50 / Dart 3.14). Depuis Flutter 3.47, Material est dans
  le paquet `material_ui` → importer `package:material_ui/material_ui.dart`
  (et non `package:flutter/material.dart`).
- État : `flutter_riverpod`. Persistance : `shared_preferences` (phase 4+).
- Voix : `flutter_tts` (phase 4). Caméra : `camera` (phase 6 uniquement).
- Rendu du cube : moteur 3D maison sur `CustomPainter` (pas de moteur de jeu).
- Android : `minSdk 24`, `targetSdk 36`, `compileSdk 36`.
- Police Nunito **embarquée** dans `assets/fonts/` (licence OFL), pas de
  `google_fonts` (qui télécharge à l'exécution).
- Textes : uniquement via `AppLocalizations` (`lib/l10n/app_fr.arb`).

## Contraintes absolues
- 100 % hors-ligne, aucune pub, aucun tracking, aucune donnée collectée.
- Aucune permission, sauf caméra en phase 6, demandée au moment du scan.
- Politique Google Play « Familles » + RGPD mineurs.
- Design enfant : zones tactiles ≥ 56 dp (`kMinTouchTarget`), texte ≥ 18 sp,
  phrases ≤ 10 mots, tutoiement, jamais « faux » ni « échec ».
- Mascotte : Cubi, personnage original dessiné en code. Aucun personnage existant.

## Architecture
```
lib/
  main.dart, app.dart  # démarrage, thème, langue
  core/cube/           # modèle, mouvements, validation, solveur (Dart pur)
  core/method/         # les 8 étapes, algos, surnoms, règles
  render/              # moteur 3D CustomPainter + gestes + animations
  features/            # home/ learn/ solve/ practice/ trophies/ settings/
  l10n/                # app_fr.arb (+ fichiers générés, ne pas éditer)
  shared/              # theme.dart, widgets/, mascot/
test/                  # tests (le cœur du cube est prioritaire)
```
`core/` ne doit dépendre d'aucun paquet Flutter (testable en Dart pur).

## Cœur du cube (phase 2)
- `core/cube/cube.dart` : 54 facettes (ordre Kociemba U R F D L B), repère
  x droite / y haut / z avant, mouvements calculés géométriquement.
- `core/cube/cubies.dart` : coins/arêtes ; `validation.dart` : cube saisi.
- `core/method/method.dart` : algorithmes à surnom + tests d'étape.
- `core/cube/solver.dart` : solveur méthode débutant (actions = rotation
  du cube / tour de couche / algorithme × répétitions + indice).
- Étoile jaune : `R' U' F' U F R` (protocole, validé). Voir
  `docs/RAPPORT_ALGOS.md`.

## Commandes
```bash
flutter pub get            # installer les dépendances
flutter gen-l10n           # régénérer les textes après modification du .arb
flutter analyze            # doit afficher « No issues found! »
flutter test               # tous les tests doivent passer
dart format lib test       # mise en forme
flutter run                # lancer sur le téléphone branché
flutter build apk --debug  # APK de test → build/app/outputs/flutter-apk/
```
