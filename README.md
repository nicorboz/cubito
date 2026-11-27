# Cube Magique

Application Android pour apprendre aux enfants (7–12 ans) à résoudre le
Rubik's Cube, 100 % hors-ligne. Voir `CLAUDE.md` (technique) et `PLAN.md`
(avancement).

## Version web (GitHub Pages)

L'appli est aussi publiée comme site web : **https://nicorboz.github.io/cubito/**
(code d'accès demandé une fois par appareil).

- Publication automatique à chaque envoi sur `main`
  (`.github/workflows/deploy-web.yml` : tests, construction, mise en ligne).
- Réglage unique sur GitHub : *Settings → Pages → Source : GitHub Actions*.
- Code d'accès : `lib/features/access/access_gate.dart` (seule son empreinte
  SHA-256 est dans le code). Il est vérifié dans le navigateur : il éloigne
  les curieux mais ne protège pas un secret.
- Différences avec Android : mascotte dessinée (l'avatar 3D est propre à
  Android), scan par petites photos successives (pas de flux vidéo dans le
  navigateur), lampe souvent indisponible, fiche mémo partagée ou
  téléchargée, solveur rapide dans un « Web Worker » (`web_worker/`).
- Tester en local :
  ```bash
  flutter build web --release --base-href /cubito/
  dart compile js -O2 -o build/web/solver_worker.js web_worker/solver_worker.dart
  ```
