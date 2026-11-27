# Rapport de vérification des algorithmes (phase 2)

Chaque algorithme a été vérifié **par simulation** (tests dans
`test/core/method_test.dart`, solveur testé sur 10 000 mélanges dans
`test/core/solver_test.dart`).

| Algorithme | Surnom | Verdict | Effet vérifié |
|---|---|---|---|
| `R' D' R D` | La petite danse 💃 | ✅ OK | Ne touche que le coin en haut à droite dans la couche du haut. Étape 3 : **1× blanc à droite, 3× dessous, 5× devant** (confirmé). Étape 8b : 2× ou 4× par coin, le cube se répare à la fin. |
| `R U R' U R U2 R' U` | L'escargot 🐌 | ✅ OK, règle précisée | Échange l'arête de **devant** et celle de **gauche** du haut, sans toucher droite ni fond. |
| `U R U' R' U' F' U F` | Toboggan droit 🛝 | ✅ OK | L'arête du haut-devant descend au milieu-droite, rien d'autre en bas. |
| `U' L' U L U F U' F'` | Toboggan gauche | ✅ OK | L'arête du haut-devant descend au milieu-gauche. |
| `R' U' F' U F R` (protocole) | L'étoile jaune ⭐ | ✅ OK, **retenu** | L en haut à gauche → croix ; ligne avant-arrière → L en haut à gauche ; point → ligne. Règle **L 1× · ligne 2× · point 3×** confirmée. |
| `F R U R' U' F'` (proposé) | — | ❌ incompatible avec la règle | Avec elle, un L en haut à gauche donne une ligne (pas la croix) : il faudrait « L 2×, ligne gauche-droite 1× ». Non retenu. |
| `L' U R U' L U R' U'` | Le manège des coins 🎠 | ✅ OK | Garde le coin en haut à droite (devant), fait tourner les 3 autres. Ne touche aucune arête. Au plus 3 manèges. |

Vocabulaire enfant (section 3.1) : **tous les sens sont corrects** (U → ligne
du haut vers la gauche, R → colonne de droite monte, L → colonne de gauche
descend, D → ligne du bas vers la droite, F → face avant comme une horloge).

## Précisions apportées aux règles

1. **Étape 1 → 2.** Comme les pétales sont alignés avec leur centre avant
   « 2 fois la face », la croix est déjà dans l'ordre : l'étape 2 est
   sautée automatiquement. Elle reste utile si l'enfant a fait sa croix
   autrement.
2. **Escargot (étapes 2 et 7).** Avant : *tourner la ligne du haut jusqu'à
   avoir au moins 2 arêtes alignées* (toujours possible, vérifié). Puis se
   tourner face à une arête non alignée, celle de droite alignée. Si les
   deux arêtes non alignées sont face à face : un escargot, puis on
   recommence. Au plus 2 escargots.
3. **Étape 3, coin blanc coincé en haut.** Mauvaise place : le tenir en haut
   à droite, 1 petite danse pour le faire descendre. Bonne place mais mal
   tourné : petite danse jusqu'à ce que le blanc soit en haut (2× ou 4×).
4. **Étape 5, arête mal placée au milieu** : la mettre devant à droite et
   faire un toboggan droit pour la remonter (confirmé).
5. **Étape 6.** La ligne doit être tenue **de l'avant vers l'arrière**. Après
   chaque étoile, tourner la ligne du haut pour remettre le L en haut à
   gauche ou la ligne avant-arrière.
6. **Étape 8b** : uniquement la ligne du haut entre deux coins, jamais le
   cube entier (le solveur le garantit, test à l'appui).
