# PLAN — Cube Magique

## Phase 1 — Socle ✅
- [x] Projet Flutter (Android + iOS), `minSdk 24`, `targetSdk 36`
- [x] `CLAUDE.md`, `PLAN.md`
- [x] Thème enfant (couleurs vives, Nunito embarquée, textes ≥ 18 sp, zones ≥ 56 dp)
- [x] Textes centralisés en français (`lib/l10n/app_fr.arb`)
- [x] Mascotte originale « Cubi » animée (flotte, cligne des yeux, respecte « réduire les animations »)
- [x] Accueil : 4 grosses tuiles + bouton réglages, portrait/paysage, téléphone/tablette
- [x] Écrans provisoires « Bientôt ici ! » pour chaque mode
- [x] Tests : accueil, navigation, tailles d'écran, taille des tuiles
- [x] APK de test

## Phase 2 — Moteur cube + tests ✅
- [x] Modèle 54 facettes, mouvements U D R L F B (+ ' et 2), rotations x y z
- [x] Séquences, inverse, mélange 25 coups, « résolu », tests d'étape
- [x] Validation d'un cube saisi (comptes, centres, pièces, parité, orientations)
- [x] Vérification par simulation de chaque algorithme de la section 4
- [x] Rapport : `docs/RAPPORT_ALGOS.md` (étoile jaune : version du protocole retenue)
- [x] Solveur méthode débutant (avancé depuis la phase 5) : 10 000 mélanges OK

## Phase 3 — Rendu 3D ✅
- [x] 27 cubies, perspective, tri par profondeur, rotation au doigt (double-tap : vue de départ)
- [x] Animation des tranches, flèches 3D (×2 pour les doubles), cases qui clignotent
- [x] Glisser sur une ligne/colonne = mouvement (testé : R, R', L, L', U, U', D, D', F')
- [x] Phrases enfant de chaque mouvement (l10n)
- [x] Premier écran « S'entraîner » : mélanger, annuler, recommencer

## Phase 4 — Mode Apprendre ✅
- [x] Carte des 8 îles, déblocage progressif, progression sauvegardée (shared_preferences)
- [x] Leçon en 5 parties : Regarde (avant/après), Pas à pas (voix, ◀ ▶ 🔁, 🐢/🐇),
      À toi ! (coups vérifiés au doigt), Défi (3 situations, ⭐ selon les indices), Fiche
- [x] Voix française (flutter_tts, synthèse du téléphone), coupée en quittant la leçon
- [x] Confettis de réussite, onglets compacts pour petits écrans

## Phase 5 — Solveur débutant + Résoudre mon cube + S'entraîner ✅
- [x] Solveur suivant exactement la méthode (fait en phase 2)
- [x] Saisie face par face (ordre et tenue imposés), palette géante, compteurs x/9, patron
- [x] Validation avec message gentil + cases qui clignotent sur la bonne face
- [x] Guidage coup par coup (étape, consigne, flèche, voix), « Je me suis trompé » → resaisie pré-remplie
- [x] S'entraîner : mélanger, annuler, tourner/retourner le cube, chrono, indice « quelle étape ? »
- [x] Statistiques (vrais cubes, cubes virtuels, meilleur temps) pour les trophées

## Phase 6 — Scan caméra, trophées, fiches mémo ✅
- [x] Scan vidéo : capture auto (stable 0,7 s), ordre des faces et gestes imposés, petit cube animé qui montre le geste
- [x] Consignes une à la fois : lampe / rapproche-toi / ne bouge plus / mauvaise face
- [x] CIELAB, calibration par les 6 centres, affinage, exactement 9 par couleur (hongrois)
      → 100 % en lumière simulée normale, 99,9 % en conditions très difficiles (tests)
- [x] Vérification 3D « C'est bien ton cube ? », cases douteuses qui clignotent, correction au doigt,
      cube impossible → « on refait la face X ? », repli saisie manuelle
- [x] Écran parent avant la 1ʳᵉ demande de caméra ; permissions micro/stockage/Internet retirées
- [x] Trophées (9 badges), réglages (voix, sons, vitesse, symboles daltoniens), espace parent (calcul)
- [x] Fiche mémo exportée en PNG (menu Partager → imprimer), sons embarqués
- [ ] Mode gaucher (miroirs) : réglage présent, mouvements miroirs à faire
- [ ] Photos réelles de référence dans test/fixtures/ (à fournir) pour mesurer le scan sur de vraies images

## Phase 7 — Finitions & publication
- [ ] Icône, écran de démarrage, TalkBack, petits/grands écrans
- [ ] APK signé + AAB, politique de confidentialité, fiche Play Store

## Refonte des consignes « livret LEGO » ✅ (validée sur maquette le 14/11)
- [x] Cube dessiné à plat, toujours le même (face avant + dessus + droite), plus de 3D qui tourne dans les consignes
- [x] Carte « Tiens ton cube comme ça » (couleur du haut + couleur devant) à la place des rotations
- [x] Carte « La formule » : cartes numérotées, chanson, nombre de fois ; formules longues en morceaux de 4
- [x] Carte « un geste » : partie violette qui esquisse le geste, grosse flèche, main droite/gauche, bouton « Fait ! »
- [x] Carte « Ton cube ressemble à ça ? » après chaque formule (non → on recommence la formule / resaisie)
- [x] Utilisé dans : Pas à pas, À toi (glisser sur le dessin), Défi (dessin + boutons pour tourner), Résoudre mon cube, indices (feuille de cartes)

## Réparation du scan caméra ✅ (14/11)
- [x] Détection réelle de la face : les 9 autocollants repérés un par un (n'importe quel fond, taille, position, légère inclinaison) ; secours par bloc
- [x] Capture tolérante : couleur médiane sur ~0,7 s, une image floue ne remet plus tout à zéro
- [x] Pas de double capture (attend que la face change), centre blanc accepté sous lampe jaune
- [x] Retour visuel : contour vert du cube trouvé, barre de progression, « Je vois » en direct
- [x] Bouton « Prendre cette face » (capture manuelle)
- [x] Tests : 120/120 faces variées, 80/80 en conditions dures (reflets, peu de lumière, petite image), 25/25 cubes de bout en bout

## Clarté du début + vraies couleurs (15/11)
- [x] Une seule carte « Tiens ton cube comme ça » au départ (les positions qui se suivent sont fusionnées, même d'une étape à l'autre)
- [x] Rappel « Orange devant · Blanc en haut » sur chaque carte de geste et de vérification
- [x] Vraies couleurs du cube sur toutes les cartes ; la partie à tourner a un gros contour, les centres ne sont jamais estompés
- [x] Carte de position en vraies couleurs, centres du haut et de devant entourés
- [x] Scan : bouton lampe (flash), proposé automatiquement quand c'est trop sombre

## Identité Cubito + refonte de l'accueil (15/11)
- Nom de l'appli : « Cubito » (Android, iOS, textes). Identifiant d'appli inchangé : la mise à jour s'installe par-dessus.
- Logo fourni intégré : icônes Android (classiques + adaptatives), iOS, écran de démarrage, icône Play Store 512 px, master 4096 px (agrandi depuis la source 1254 px).
- Accueil refait aux vraies couleurs du cube : tuiles autocollants vert / bleu / orange / jaune avec relief et appui, logo « CUBITO » en lettres-autocollants, entrée échelonnée (ease-out).
- Nouvelle mascotte Cubito : cube 3D bleu/jaune/rouge à grands yeux, clignement, regard, rebond quand on la touche ; texte adapté aux tablettes et petits écrans.
- Tuiles de l'accueil plates (couleur + icône + texte, plus de reflet ni de relief) ; léger rétrécissement à l'appui.
- Retour en glissant depuis le bord gauche ou droit, sur tous les écrans (bulle-flèche qui suit le doigt, vibration quand c'est validé). Le geste retour d'Android ne marchait pas du premier coup à cause du plein écran.

## Avatar 3D animé (15/11)
- Nouvel avatar fourni (cube 3D avec visage, Three.js hors ligne dans une WebView transparente) : `android/app/src/main/assets/cubi/index.html` (non modifié), `CubiAvatarView.kt` + pont Flutter (`CubiPlatformView.kt`, `MainActivity.kt`), widget `CubiAvatar` (`lib/shared/mascot/cubi_avatar.dart`). Toujours aucune permission Internet.
- Le prénom reste « Cubito ». Sur iPhone et dans les tests, la mascotte dessinée (`cubito.dart`) reste utilisée.
- Expressions : accueil joyeux (dodo après 40 s sans toucher, réveil au toucher ; toucher = saut + phrase), rire + saut sur toutes les réussites (Pas à pas, À toi, Défi, cube résolu, S'entraîner), triste + encouragement sur les erreurs (saisie, face à refaire au scan), surpris sur « C'est bien ton cube ? », clin d'œil dans les indices.
- Fluidité (15/11) : visage redessiné seulement quand il change, textures du visage en 512 px, ombre au sol peinte (plus de shadow map), pas d'antialiasing, géométrie allégée, résolution abaissée automatiquement si < 45 images/s, l'animation garde sa vitesse même si l'appareil saute des images, avatar en pause quand son écran est caché. Mesure en rendu logiciel : 4,7 → ~34 images/s.
- Retour par le bord : plus aucune flèche affichée (seulement une petite vibration).
- Netteté (15/11) : antialiasing réactivé, pleine résolution de l'écran (jusqu'à 2,5x), baisse automatique seulement sous 28 images/s et jamais sous 1,5x ; visage en 768 px.

## Voix « Pulcherrima » (15/11)
- 408 phrases enregistrées à l'avance avec la voix Google Chirp 3 HD fr-FR-Chirp3-HD-Pulcherrima (vitesse 0,95), dans `assets/voice/` (~5 Mo, MP3) + `index.json`. L'appli reste hors ligne.
- `RecordedSpeech` (lib/shared/speech.dart) : joue l'enregistrement de la phrase exacte, sinon voix du téléphone (ex. temps au chrono).
- Régénérer après un changement de textes : `VOICE_DUMP=build/voice_lines.json flutter test test/tool/voice_lines_test.dart` puis `GOOGLE_TTS_KEY=… python3 tool/voice/generate.py` (seules les nouvelles phrases sont envoyées). La clé n'est jamais stockée dans le projet.

## Apprendre = parcours des formules ; Résoudre = 2 chemins (15/11)
- Apprendre : 10 leçons dans l'ordre de la résolution (`lib/features/learn/lessons.dart`) : gestes de base, escargot, petite danse, retourner, toboggan droit, toboggan gauche, étoile jaune, escargot (révision), manège, petite danse (révision). Chaque leçon : Regarde (étape, avant/après, formule en cartes) · Pas à pas · À toi · Par cœur (gestes cachés, « Aide » ou erreur les montre ; 3 étoiles sans aide, 2 si ≤ 2 aides) · Fiche. Progression `lesson_stars_N`, la leçon suivante s'ouvre après « Par cœur ». Défis par île supprimés.
- Résoudre : après vérification du cube, choix « Toute la méthode » (méthode débutant, étape par étape) ou « Le plus court » (solveur deux phases maison `lib/core/cube/fast_solver.dart`, ~20 coups, calculé en arrière-plan ; face arrière évitée en tournant le cube, vérification tous les 4 gestes). Nombre de gestes affiché pour chaque chemin.
- Nouvelles phrases parlées (gestes de base, bravo « par cœur ») : voix du téléphone tant que les voix ne sont pas régénérées.
- Ajustements (15/11) : tuiles S'entraîner et Mes trophées en texte blanc, plus de compteur d'étoiles sur l'accueil. Leçons réduites à Regarde · Pas à pas · Fiche (plus de manipulation : « À toi » et « Par cœur » retirés) ; une leçon est « vue » à la fin du pas à pas, ce qui ouvre la suivante. Page de fin : Cubito dit « Bien joué, tu as tout vu ! », rappel de la formule (cartes + chanson), boutons Revoir / Fiche / Leçon suivante. Plus d'indice hors sujet sous les gestes de base et du chemin court.

## Scan plus tolérant (15/11)
- `lib/core/scan/scan_reader.dart` : on essaie d'abord de trouver la face ; sinon on lit directement les 9 cases du grand carré guide (cœur de chaque case, pixels sombres écartés). Accepté si les cases sont franches et qu'on voit un vrai cube (couleurs variées ou fentes sombres entre cases) : un mur uni n'est pas capturé.
- Capture plus tolérante : 0,6 s de stabilité, écarts de couleur admis plus grands, une case floue sur neuf tolérée, « mauvaise face » seulement si c'est flagrant.
- Écran : carré guide découpé en 9 avec une pastille de la couleur lue dans chaque case, cadre vert quand c'est bon ; « Prendre cette face » toujours possible ; mise au point et lumière sur le centre de l'image.
- Tests : cubes sans plastique noir, décalés, penchés (≥ 95 % lus), mur uni refusé.
- Vérification du scan (15/11) : cube impossible → on essaie d'abord de tourner les faces (toutes pareil = caméra orientée autrement, sinon le moins de faces possible), puis l'unique échange rouge/orange ou blanc/jaune qui rend le cube possible (cases mises en évidence). Le message « on la refait ? » ne vient qu'ensuite.
- Écran toujours allumé tant que l'appli est ouverte (Android FLAG_KEEP_SCREEN_ON, iOS isIdleTimerDisabled).
- Scan moins pressé (15/11) : il faut tenir la face immobile ~1,5 s (au moins 6 images) avant la capture automatique, critères de stabilité un peu plus stricts, 2,5 s de pause après chaque capture pour faire le geste.
- Cube « bricolé » à la main (15/11) : coin tourné, arête retournée ou pièces échangées → toutes les couleurs sont justes mais aucun geste ne peut le résoudre. L'écran de vérification (et la saisie à la main) l'explique clairement, propose « Recommencer le scan » une fois réparé, et ne tente plus de « corriger » ce cas.
- Voix (16/11) : 53 nouvelles phrases Pulcherrima (gestes de base, fin de leçon, cube bricolé, toutes les tenues « Tiens ton cube comme ça »), 452 au total. Seules les phrases avec un temps de chrono restent à la voix du téléphone.

## Version web sur GitHub Pages (27/11)
- [x] Plateforme web ajoutée (icônes Cubito, écran de chargement, pas d'indexation par les moteurs)
- [x] Code d'accès à l'ouverture (empreinte SHA-256, mémorisé sur l'appareil)
- [x] Scan caméra dans le navigateur : petites photos successives lues comme les images du téléphone (test : 30 faces)
- [x] Solveur rapide dans un Web Worker (l'écran ne se fige pas), fiche mémo partagée ou téléchargée
- [x] Publication automatique (GitHub Actions : tests → construction → Pages)
- [ ] Avatar 3D sur le web (aujourd'hui : mascotte dessinée)
