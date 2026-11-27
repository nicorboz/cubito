import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('fr')];

  /// No description provided for @appTitle.
  ///
  /// In fr, this message translates to:
  /// **'Cubito'**
  String get appTitle;

  /// No description provided for @accessTitle.
  ///
  /// In fr, this message translates to:
  /// **'Code d\'accès'**
  String get accessTitle;

  /// No description provided for @accessHelp.
  ///
  /// In fr, this message translates to:
  /// **'Demande le code à un adulte.'**
  String get accessHelp;

  /// No description provided for @accessLabel.
  ///
  /// In fr, this message translates to:
  /// **'Le code'**
  String get accessLabel;

  /// No description provided for @accessEnter.
  ///
  /// In fr, this message translates to:
  /// **'Entrer'**
  String get accessEnter;

  /// No description provided for @accessWrong.
  ///
  /// In fr, this message translates to:
  /// **'Ce n\'est pas le bon code. Réessaie !'**
  String get accessWrong;

  /// No description provided for @homeGreeting.
  ///
  /// In fr, this message translates to:
  /// **'Salut, moi c\'est Cubito !'**
  String get homeGreeting;

  /// No description provided for @homeSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'On résout ton cube ensemble ?'**
  String get homeSubtitle;

  /// No description provided for @tileLearn.
  ///
  /// In fr, this message translates to:
  /// **'Apprendre'**
  String get tileLearn;

  /// No description provided for @tileSolve.
  ///
  /// In fr, this message translates to:
  /// **'Résoudre mon cube'**
  String get tileSolve;

  /// No description provided for @tilePractice.
  ///
  /// In fr, this message translates to:
  /// **'S\'entraîner'**
  String get tilePractice;

  /// No description provided for @tileTrophies.
  ///
  /// In fr, this message translates to:
  /// **'Mes trophées'**
  String get tileTrophies;

  /// No description provided for @settings.
  ///
  /// In fr, this message translates to:
  /// **'Réglages'**
  String get settings;

  /// No description provided for @back.
  ///
  /// In fr, this message translates to:
  /// **'Retour'**
  String get back;

  /// No description provided for @comingSoonTitle.
  ///
  /// In fr, this message translates to:
  /// **'Bientôt ici !'**
  String get comingSoonTitle;

  /// No description provided for @comingSoonLearn.
  ///
  /// In fr, this message translates to:
  /// **'Ici, tu apprendras le cube en 8 étapes.'**
  String get comingSoonLearn;

  /// No description provided for @comingSoonSolve.
  ///
  /// In fr, this message translates to:
  /// **'Ici, je t\'aiderai à résoudre TON cube.'**
  String get comingSoonSolve;

  /// No description provided for @comingSoonPractice.
  ///
  /// In fr, this message translates to:
  /// **'Ici, tu pourras t\'entraîner librement.'**
  String get comingSoonPractice;

  /// No description provided for @comingSoonTrophies.
  ///
  /// In fr, this message translates to:
  /// **'Ici, tu verras tous tes trophées.'**
  String get comingSoonTrophies;

  /// No description provided for @comingSoonSettings.
  ///
  /// In fr, this message translates to:
  /// **'Ici, tu pourras régler la voix et les sons.'**
  String get comingSoonSettings;

  /// No description provided for @mascotLabel.
  ///
  /// In fr, this message translates to:
  /// **'Cubito, le cube qui sourit'**
  String get mascotLabel;

  /// No description provided for @moveR.
  ///
  /// In fr, this message translates to:
  /// **'Monte la colonne de droite'**
  String get moveR;

  /// No description provided for @moveRp.
  ///
  /// In fr, this message translates to:
  /// **'Descends la colonne de droite'**
  String get moveRp;

  /// No description provided for @moveR2.
  ///
  /// In fr, this message translates to:
  /// **'Monte 2 fois la colonne de droite'**
  String get moveR2;

  /// No description provided for @moveL.
  ///
  /// In fr, this message translates to:
  /// **'Descends la colonne de gauche'**
  String get moveL;

  /// No description provided for @moveLp.
  ///
  /// In fr, this message translates to:
  /// **'Monte la colonne de gauche'**
  String get moveLp;

  /// No description provided for @moveL2.
  ///
  /// In fr, this message translates to:
  /// **'Descends 2 fois la colonne de gauche'**
  String get moveL2;

  /// No description provided for @moveU.
  ///
  /// In fr, this message translates to:
  /// **'Tourne la ligne du haut vers la gauche'**
  String get moveU;

  /// No description provided for @moveUp.
  ///
  /// In fr, this message translates to:
  /// **'Tourne la ligne du haut vers la droite'**
  String get moveUp;

  /// No description provided for @moveU2.
  ///
  /// In fr, this message translates to:
  /// **'Tourne 2 fois la ligne du haut'**
  String get moveU2;

  /// No description provided for @moveD.
  ///
  /// In fr, this message translates to:
  /// **'Tourne la ligne du bas vers la droite'**
  String get moveD;

  /// No description provided for @moveDp.
  ///
  /// In fr, this message translates to:
  /// **'Tourne la ligne du bas vers la gauche'**
  String get moveDp;

  /// No description provided for @moveD2.
  ///
  /// In fr, this message translates to:
  /// **'Tourne 2 fois la ligne du bas'**
  String get moveD2;

  /// No description provided for @moveF.
  ///
  /// In fr, this message translates to:
  /// **'Tourne la face avant comme une horloge'**
  String get moveF;

  /// No description provided for @moveFp.
  ///
  /// In fr, this message translates to:
  /// **'Tourne la face avant vers la gauche'**
  String get moveFp;

  /// No description provided for @moveF2.
  ///
  /// In fr, this message translates to:
  /// **'Tourne 2 fois la face avant'**
  String get moveF2;

  /// No description provided for @moveB.
  ///
  /// In fr, this message translates to:
  /// **'Tourne la face de derrière'**
  String get moveB;

  /// No description provided for @moveY.
  ///
  /// In fr, this message translates to:
  /// **'Tourne tout le cube vers la gauche'**
  String get moveY;

  /// No description provided for @moveYp.
  ///
  /// In fr, this message translates to:
  /// **'Tourne tout le cube vers la droite'**
  String get moveYp;

  /// No description provided for @moveY2.
  ///
  /// In fr, this message translates to:
  /// **'Fais faire un demi-tour au cube'**
  String get moveY2;

  /// No description provided for @moveX2.
  ///
  /// In fr, this message translates to:
  /// **'Retourne le cube : le haut va en bas'**
  String get moveX2;

  /// No description provided for @moveOther.
  ///
  /// In fr, this message translates to:
  /// **'Tourne tout le cube'**
  String get moveOther;

  /// No description provided for @practiceHelp.
  ///
  /// In fr, this message translates to:
  /// **'Glisse ton doigt sur une ligne ou une colonne.'**
  String get practiceHelp;

  /// No description provided for @practiceHelpOrbit.
  ///
  /// In fr, this message translates to:
  /// **'Glisse à côté du cube pour le faire tourner.'**
  String get practiceHelpOrbit;

  /// No description provided for @scramble.
  ///
  /// In fr, this message translates to:
  /// **'Mélanger'**
  String get scramble;

  /// No description provided for @undo.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get undo;

  /// No description provided for @restart.
  ///
  /// In fr, this message translates to:
  /// **'Recommencer'**
  String get restart;

  /// No description provided for @solvedBravo.
  ///
  /// In fr, this message translates to:
  /// **'Bravo, tu as résolu le cube !'**
  String get solvedBravo;

  /// No description provided for @cubeLabel.
  ///
  /// In fr, this message translates to:
  /// **'Le cube en 3D'**
  String get cubeLabel;

  /// No description provided for @island1Title.
  ///
  /// In fr, this message translates to:
  /// **'La marguerite 🌼'**
  String get island1Title;

  /// No description provided for @island1Goal.
  ///
  /// In fr, this message translates to:
  /// **'Fais une croix blanche.'**
  String get island1Goal;

  /// No description provided for @island1Rule1.
  ///
  /// In fr, this message translates to:
  /// **'Jaune en haut : 4 pétales blancs autour.'**
  String get island1Rule1;

  /// No description provided for @island1Rule2.
  ///
  /// In fr, this message translates to:
  /// **'Pose chaque pétale sur sa couleur.'**
  String get island1Rule2;

  /// No description provided for @island1Rule3.
  ///
  /// In fr, this message translates to:
  /// **'Puis tourne 2 fois la face avant.'**
  String get island1Rule3;

  /// No description provided for @island1Rule4.
  ///
  /// In fr, this message translates to:
  /// **'Retourne le cube : croix blanche en haut !'**
  String get island1Rule4;

  /// No description provided for @island2Title.
  ///
  /// In fr, this message translates to:
  /// **'La croix bien rangée'**
  String get island2Title;

  /// No description provided for @island2Goal.
  ///
  /// In fr, this message translates to:
  /// **'Chaque arête blanche sur sa couleur.'**
  String get island2Goal;

  /// No description provided for @island2Rule1.
  ///
  /// In fr, this message translates to:
  /// **'Tourne le haut : au moins 2 arêtes alignées.'**
  String get island2Rule1;

  /// No description provided for @island2Rule2.
  ///
  /// In fr, this message translates to:
  /// **'Mets une arête pas alignée devant toi.'**
  String get island2Rule2;

  /// No description provided for @island2Rule3.
  ///
  /// In fr, this message translates to:
  /// **'Celle de droite doit être alignée.'**
  String get island2Rule3;

  /// No description provided for @island2Rule4.
  ///
  /// In fr, this message translates to:
  /// **'Fais l\'escargot, puis recommence.'**
  String get island2Rule4;

  /// No description provided for @island3Title.
  ///
  /// In fr, this message translates to:
  /// **'Les coins blancs'**
  String get island3Title;

  /// No description provided for @island3Goal.
  ///
  /// In fr, this message translates to:
  /// **'Termine toute la face blanche !'**
  String get island3Goal;

  /// No description provided for @island3Rule1.
  ///
  /// In fr, this message translates to:
  /// **'Mets le coin blanc en bas, sous sa place.'**
  String get island3Rule1;

  /// No description provided for @island3Rule2.
  ///
  /// In fr, this message translates to:
  /// **'Blanc à droite : 1 petite danse.'**
  String get island3Rule2;

  /// No description provided for @island3Rule3.
  ///
  /// In fr, this message translates to:
  /// **'Blanc dessous : 3 petites danses.'**
  String get island3Rule3;

  /// No description provided for @island3Rule4.
  ///
  /// In fr, this message translates to:
  /// **'Blanc devant : 5 petites danses.'**
  String get island3Rule4;

  /// No description provided for @island4Title.
  ///
  /// In fr, this message translates to:
  /// **'On retourne le cube'**
  String get island4Title;

  /// No description provided for @island4Goal.
  ///
  /// In fr, this message translates to:
  /// **'Le blanc va en bas.'**
  String get island4Goal;

  /// No description provided for @island4Rule1.
  ///
  /// In fr, this message translates to:
  /// **'Fais rouler le cube vers toi, deux fois.'**
  String get island4Rule1;

  /// No description provided for @island4Rule2.
  ///
  /// In fr, this message translates to:
  /// **'Le jaune est en haut maintenant.'**
  String get island4Rule2;

  /// No description provided for @island5Title.
  ///
  /// In fr, this message translates to:
  /// **'La 2e couronne'**
  String get island5Title;

  /// No description provided for @island5Goal.
  ///
  /// In fr, this message translates to:
  /// **'Range les arêtes du milieu.'**
  String get island5Goal;

  /// No description provided for @island5Rule1.
  ///
  /// In fr, this message translates to:
  /// **'Cherche une arête du haut sans jaune.'**
  String get island5Rule1;

  /// No description provided for @island5Rule2.
  ///
  /// In fr, this message translates to:
  /// **'Tourne le haut pour faire un T à l\'envers.'**
  String get island5Rule2;

  /// No description provided for @island5Rule3.
  ///
  /// In fr, this message translates to:
  /// **'Le dessus va à droite : toboggan droit.'**
  String get island5Rule3;

  /// No description provided for @island5Rule4.
  ///
  /// In fr, this message translates to:
  /// **'Le dessus va à gauche : toboggan gauche.'**
  String get island5Rule4;

  /// No description provided for @island6Title.
  ///
  /// In fr, this message translates to:
  /// **'L\'étoile jaune ⭐'**
  String get island6Title;

  /// No description provided for @island6Goal.
  ///
  /// In fr, this message translates to:
  /// **'Fais une croix jaune.'**
  String get island6Goal;

  /// No description provided for @island6Rule1.
  ///
  /// In fr, this message translates to:
  /// **'Petit L en haut à gauche : 1 fois.'**
  String get island6Rule1;

  /// No description provided for @island6Rule2.
  ///
  /// In fr, this message translates to:
  /// **'Ligne de l\'avant vers l\'arrière : 2 fois.'**
  String get island6Rule2;

  /// No description provided for @island6Rule3.
  ///
  /// In fr, this message translates to:
  /// **'Juste le point jaune : 3 fois.'**
  String get island6Rule3;

  /// No description provided for @island7Title.
  ///
  /// In fr, this message translates to:
  /// **'Les arêtes jaunes'**
  String get island7Title;

  /// No description provided for @island7Goal.
  ///
  /// In fr, this message translates to:
  /// **'Chaque arête jaune sur sa couleur.'**
  String get island7Goal;

  /// No description provided for @island7Rule1.
  ///
  /// In fr, this message translates to:
  /// **'Tourne le haut : au moins 2 arêtes alignées.'**
  String get island7Rule1;

  /// No description provided for @island7Rule2.
  ///
  /// In fr, this message translates to:
  /// **'Mets une arête pas alignée devant toi.'**
  String get island7Rule2;

  /// No description provided for @island7Rule3.
  ///
  /// In fr, this message translates to:
  /// **'Celle de droite doit être alignée.'**
  String get island7Rule3;

  /// No description provided for @island7Rule4.
  ///
  /// In fr, this message translates to:
  /// **'Fais l\'escargot, comme pour la croix blanche.'**
  String get island7Rule4;

  /// No description provided for @island8Title.
  ///
  /// In fr, this message translates to:
  /// **'Les coins jaunes 🎉'**
  String get island8Title;

  /// No description provided for @island8Goal.
  ///
  /// In fr, this message translates to:
  /// **'Termine le cube !'**
  String get island8Goal;

  /// No description provided for @island8Rule1.
  ///
  /// In fr, this message translates to:
  /// **'Un coin bien placé en haut à droite.'**
  String get island8Rule1;

  /// No description provided for @island8Rule2.
  ///
  /// In fr, this message translates to:
  /// **'Fais le manège, 1 ou 2 fois.'**
  String get island8Rule2;

  /// No description provided for @island8Rule3.
  ///
  /// In fr, this message translates to:
  /// **'Puis petite danse jusqu\'au jaune en haut.'**
  String get island8Rule3;

  /// No description provided for @island8Rule4.
  ///
  /// In fr, this message translates to:
  /// **'Entre deux coins, tourne seulement le haut.'**
  String get island8Rule4;

  /// No description provided for @island8Rule5.
  ///
  /// In fr, this message translates to:
  /// **'Le cube a l\'air cassé : c\'est normal !'**
  String get island8Rule5;

  /// No description provided for @algoPetiteDanse.
  ///
  /// In fr, this message translates to:
  /// **'La petite danse'**
  String get algoPetiteDanse;

  /// No description provided for @algoEscargot.
  ///
  /// In fr, this message translates to:
  /// **'L\'escargot'**
  String get algoEscargot;

  /// No description provided for @algoTobogganDroit.
  ///
  /// In fr, this message translates to:
  /// **'Le toboggan droit'**
  String get algoTobogganDroit;

  /// No description provided for @algoTobogganGauche.
  ///
  /// In fr, this message translates to:
  /// **'Le toboggan gauche'**
  String get algoTobogganGauche;

  /// No description provided for @algoEtoileJaune.
  ///
  /// In fr, this message translates to:
  /// **'L\'étoile jaune'**
  String get algoEtoileJaune;

  /// No description provided for @algoManege.
  ///
  /// In fr, this message translates to:
  /// **'Le manège des coins'**
  String get algoManege;

  /// No description provided for @hintRetournerJauneEnHaut.
  ///
  /// In fr, this message translates to:
  /// **'Retourne le cube : le jaune en haut.'**
  String get hintRetournerJauneEnHaut;

  /// No description provided for @hintPetale.
  ///
  /// In fr, this message translates to:
  /// **'Fais monter une arête blanche près du jaune.'**
  String get hintPetale;

  /// No description provided for @hintPetaleAuDessusDeSaCouleur.
  ///
  /// In fr, this message translates to:
  /// **'Tourne le haut : un pétale sur sa couleur.'**
  String get hintPetaleAuDessusDeSaCouleur;

  /// No description provided for @hintPetaleDevant.
  ///
  /// In fr, this message translates to:
  /// **'Tourne le cube : ce pétale devant toi.'**
  String get hintPetaleDevant;

  /// No description provided for @hintPetaleDescend.
  ///
  /// In fr, this message translates to:
  /// **'Tourne 2 fois la face avant.'**
  String get hintPetaleDescend;

  /// No description provided for @hintRetournerBlancEnHaut.
  ///
  /// In fr, this message translates to:
  /// **'Retourne le cube : la croix blanche en haut.'**
  String get hintRetournerBlancEnHaut;

  /// No description provided for @hintArretesAligner.
  ///
  /// In fr, this message translates to:
  /// **'Tourne le haut pour aligner 2 arêtes.'**
  String get hintArretesAligner;

  /// No description provided for @hintFaceAreteNonAlignee.
  ///
  /// In fr, this message translates to:
  /// **'Une arête pas alignée devant toi.'**
  String get hintFaceAreteNonAlignee;

  /// No description provided for @hintEscargot.
  ///
  /// In fr, this message translates to:
  /// **'Fais l\'escargot !'**
  String get hintEscargot;

  /// No description provided for @hintCoinCibleDevantDroite.
  ///
  /// In fr, this message translates to:
  /// **'Tourne le cube : la place du coin à droite.'**
  String get hintCoinCibleDevantDroite;

  /// No description provided for @hintCoinSousSaPlace.
  ///
  /// In fr, this message translates to:
  /// **'Tourne le bas : le coin sous sa place.'**
  String get hintCoinSousSaPlace;

  /// No description provided for @hintPetiteDanseCoinBlanc.
  ///
  /// In fr, this message translates to:
  /// **'Fais la petite danse {count} fois.'**
  String hintPetiteDanseCoinBlanc(int count);

  /// No description provided for @hintSortirCoinBlanc.
  ///
  /// In fr, this message translates to:
  /// **'Coin mal placé : une petite danse le sort.'**
  String get hintSortirCoinBlanc;

  /// No description provided for @hintTournerCoinBlancEnPlace.
  ///
  /// In fr, this message translates to:
  /// **'Petite danse jusqu\'au blanc en haut.'**
  String get hintTournerCoinBlancEnPlace;

  /// No description provided for @hintRetournerBlancEnBas.
  ///
  /// In fr, this message translates to:
  /// **'Retourne le cube : le blanc en bas.'**
  String get hintRetournerBlancEnBas;

  /// No description provided for @hintFaireTAlEnvers.
  ///
  /// In fr, this message translates to:
  /// **'Tourne le haut : fais un T à l\'envers.'**
  String get hintFaireTAlEnvers;

  /// No description provided for @hintTDevant.
  ///
  /// In fr, this message translates to:
  /// **'Tourne le cube : le T devant toi.'**
  String get hintTDevant;

  /// No description provided for @hintTobogganDroit.
  ///
  /// In fr, this message translates to:
  /// **'Toboggan vers la droite !'**
  String get hintTobogganDroit;

  /// No description provided for @hintTobogganGauche.
  ///
  /// In fr, this message translates to:
  /// **'Toboggan vers la gauche !'**
  String get hintTobogganGauche;

  /// No description provided for @hintAreteMalPlaceeDevantDroite.
  ///
  /// In fr, this message translates to:
  /// **'L\'arête mal rangée devant, à droite.'**
  String get hintAreteMalPlaceeDevantDroite;

  /// No description provided for @hintSortirArete.
  ///
  /// In fr, this message translates to:
  /// **'Un toboggan pour la faire remonter.'**
  String get hintSortirArete;

  /// No description provided for @hintPlacerMotifJaune.
  ///
  /// In fr, this message translates to:
  /// **'Tourne le haut pour bien placer le jaune.'**
  String get hintPlacerMotifJaune;

  /// No description provided for @hintEtoileJaune.
  ///
  /// In fr, this message translates to:
  /// **'Fais l\'étoile jaune !'**
  String get hintEtoileJaune;

  /// No description provided for @hintCoinBienPlaceEnHautADroite.
  ///
  /// In fr, this message translates to:
  /// **'Un coin bien placé en haut à droite.'**
  String get hintCoinBienPlaceEnHautADroite;

  /// No description provided for @hintManege.
  ///
  /// In fr, this message translates to:
  /// **'Fais le manège des coins !'**
  String get hintManege;

  /// No description provided for @hintAmenerCoinJaune.
  ///
  /// In fr, this message translates to:
  /// **'Tourne seulement le haut : coin suivant à droite.'**
  String get hintAmenerCoinJaune;

  /// No description provided for @hintPetiteDanseCoinJaune.
  ///
  /// In fr, this message translates to:
  /// **'Petite danse jusqu\'au jaune en haut.'**
  String get hintPetiteDanseCoinJaune;

  /// No description provided for @hintAlignerDernierePlace.
  ///
  /// In fr, this message translates to:
  /// **'Tourne le haut pour finir !'**
  String get hintAlignerDernierePlace;

  /// No description provided for @learnMapTitle.
  ///
  /// In fr, this message translates to:
  /// **'Le parcours des formules'**
  String get learnMapTitle;

  /// No description provided for @learnLocked.
  ///
  /// In fr, this message translates to:
  /// **'Réussis la leçon d\'avant pour ouvrir celle-ci.'**
  String get learnLocked;

  /// No description provided for @islandNumber.
  ///
  /// In fr, this message translates to:
  /// **'Île {n}'**
  String islandNumber(int n);

  /// No description provided for @partGoal.
  ///
  /// In fr, this message translates to:
  /// **'Regarde'**
  String get partGoal;

  /// No description provided for @partSteps.
  ///
  /// In fr, this message translates to:
  /// **'Pas à pas'**
  String get partSteps;

  /// No description provided for @partYourTurn.
  ///
  /// In fr, this message translates to:
  /// **'À toi !'**
  String get partYourTurn;

  /// No description provided for @partChallenge.
  ///
  /// In fr, this message translates to:
  /// **'Par cœur'**
  String get partChallenge;

  /// No description provided for @partMemo.
  ///
  /// In fr, this message translates to:
  /// **'Fiche'**
  String get partMemo;

  /// No description provided for @watch.
  ///
  /// In fr, this message translates to:
  /// **'Regarder'**
  String get watch;

  /// No description provided for @watchAgain.
  ///
  /// In fr, this message translates to:
  /// **'Revoir'**
  String get watchAgain;

  /// No description provided for @before.
  ///
  /// In fr, this message translates to:
  /// **'Avant'**
  String get before;

  /// No description provided for @after.
  ///
  /// In fr, this message translates to:
  /// **'Après'**
  String get after;

  /// No description provided for @next.
  ///
  /// In fr, this message translates to:
  /// **'Suivant'**
  String get next;

  /// No description provided for @previous.
  ///
  /// In fr, this message translates to:
  /// **'Précédent'**
  String get previous;

  /// No description provided for @replay.
  ///
  /// In fr, this message translates to:
  /// **'Recommencer'**
  String get replay;

  /// No description provided for @slow.
  ///
  /// In fr, this message translates to:
  /// **'Lent'**
  String get slow;

  /// No description provided for @fast.
  ///
  /// In fr, this message translates to:
  /// **'Rapide'**
  String get fast;

  /// No description provided for @moveCounter.
  ///
  /// In fr, this message translates to:
  /// **'Coup {n} sur {total}'**
  String moveCounter(int n, int total);

  /// No description provided for @repetition.
  ///
  /// In fr, this message translates to:
  /// **'Fois {n} sur {total}'**
  String repetition(int n, int total);

  /// No description provided for @stepsDone.
  ///
  /// In fr, this message translates to:
  /// **'Bien joué, tu as tout vu !'**
  String get stepsDone;

  /// No description provided for @yourTurnHelp.
  ///
  /// In fr, this message translates to:
  /// **'Fais le mouvement de la flèche.'**
  String get yourTurnHelp;

  /// No description provided for @tryAgain.
  ///
  /// In fr, this message translates to:
  /// **'Presque ! Essaie encore.'**
  String get tryAgain;

  /// No description provided for @wellDone.
  ///
  /// In fr, this message translates to:
  /// **'Bravo !'**
  String get wellDone;

  /// No description provided for @rotateCubeButton.
  ///
  /// In fr, this message translates to:
  /// **'Tourner le cube'**
  String get rotateCubeButton;

  /// No description provided for @yourTurnDone.
  ///
  /// In fr, this message translates to:
  /// **'Super, tu l\'as fait tout seul !'**
  String get yourTurnDone;

  /// No description provided for @challengeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Défi {n} sur 3'**
  String challengeTitle(int n);

  /// No description provided for @challengeHelp.
  ///
  /// In fr, this message translates to:
  /// **'Réussis l\'étape. Besoin d\'aide ? Touche l\'ampoule.'**
  String get challengeHelp;

  /// No description provided for @hint.
  ///
  /// In fr, this message translates to:
  /// **'Indice'**
  String get hint;

  /// No description provided for @challengeSolved.
  ///
  /// In fr, this message translates to:
  /// **'Réussi !'**
  String get challengeSolved;

  /// No description provided for @challengeAllDone.
  ///
  /// In fr, this message translates to:
  /// **'Défi terminé !'**
  String get challengeAllDone;

  /// No description provided for @challengeBroken.
  ///
  /// In fr, this message translates to:
  /// **'Oups, le cube s\'est un peu dérangé.'**
  String get challengeBroken;

  /// No description provided for @tryAgainButton.
  ///
  /// In fr, this message translates to:
  /// **'On recommence'**
  String get tryAgainButton;

  /// No description provided for @nextIsland.
  ///
  /// In fr, this message translates to:
  /// **'Île suivante'**
  String get nextIsland;

  /// No description provided for @backToMap.
  ///
  /// In fr, this message translates to:
  /// **'Retour au parcours'**
  String get backToMap;

  /// No description provided for @memoTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ma fiche mémo'**
  String get memoTitle;

  /// No description provided for @memoRules.
  ///
  /// In fr, this message translates to:
  /// **'La règle'**
  String get memoRules;

  /// No description provided for @memoMoves.
  ///
  /// In fr, this message translates to:
  /// **'Les mouvements'**
  String get memoMoves;

  /// No description provided for @turnLeft.
  ///
  /// In fr, this message translates to:
  /// **'Tourner à gauche'**
  String get turnLeft;

  /// No description provided for @turnRight.
  ///
  /// In fr, this message translates to:
  /// **'Tourner à droite'**
  String get turnRight;

  /// No description provided for @flipCube.
  ///
  /// In fr, this message translates to:
  /// **'Retourner'**
  String get flipCube;

  /// No description provided for @nothingToDo.
  ///
  /// In fr, this message translates to:
  /// **'Rien à faire ici : c\'est déjà bon !'**
  String get nothingToDo;

  /// No description provided for @colorWhite.
  ///
  /// In fr, this message translates to:
  /// **'blanc'**
  String get colorWhite;

  /// No description provided for @colorRed.
  ///
  /// In fr, this message translates to:
  /// **'rouge'**
  String get colorRed;

  /// No description provided for @colorGreen.
  ///
  /// In fr, this message translates to:
  /// **'vert'**
  String get colorGreen;

  /// No description provided for @colorYellow.
  ///
  /// In fr, this message translates to:
  /// **'jaune'**
  String get colorYellow;

  /// No description provided for @colorOrange.
  ///
  /// In fr, this message translates to:
  /// **'orange'**
  String get colorOrange;

  /// No description provided for @colorBlue.
  ///
  /// In fr, this message translates to:
  /// **'bleu'**
  String get colorBlue;

  /// No description provided for @faceWhite.
  ///
  /// In fr, this message translates to:
  /// **'la face blanche'**
  String get faceWhite;

  /// No description provided for @faceRed.
  ///
  /// In fr, this message translates to:
  /// **'la face rouge'**
  String get faceRed;

  /// No description provided for @faceGreen.
  ///
  /// In fr, this message translates to:
  /// **'la face verte'**
  String get faceGreen;

  /// No description provided for @faceYellow.
  ///
  /// In fr, this message translates to:
  /// **'la face jaune'**
  String get faceYellow;

  /// No description provided for @faceOrange.
  ///
  /// In fr, this message translates to:
  /// **'la face orange'**
  String get faceOrange;

  /// No description provided for @faceBlue.
  ///
  /// In fr, this message translates to:
  /// **'la face bleue'**
  String get faceBlue;

  /// No description provided for @inputTitle.
  ///
  /// In fr, this message translates to:
  /// **'Colorie ton cube'**
  String get inputTitle;

  /// No description provided for @inputHoldU.
  ///
  /// In fr, this message translates to:
  /// **'Centre blanc face à toi, centre bleu en haut.'**
  String get inputHoldU;

  /// No description provided for @inputHoldF.
  ///
  /// In fr, this message translates to:
  /// **'Centre vert face à toi, centre blanc en haut.'**
  String get inputHoldF;

  /// No description provided for @inputHoldR.
  ///
  /// In fr, this message translates to:
  /// **'Centre rouge face à toi, centre blanc en haut.'**
  String get inputHoldR;

  /// No description provided for @inputHoldB.
  ///
  /// In fr, this message translates to:
  /// **'Centre bleu face à toi, centre blanc en haut.'**
  String get inputHoldB;

  /// No description provided for @inputHoldL.
  ///
  /// In fr, this message translates to:
  /// **'Centre orange face à toi, centre blanc en haut.'**
  String get inputHoldL;

  /// No description provided for @inputHoldD.
  ///
  /// In fr, this message translates to:
  /// **'Centre jaune face à toi, centre vert en haut.'**
  String get inputHoldD;

  /// No description provided for @inputFaceCounter.
  ///
  /// In fr, this message translates to:
  /// **'Face {n} sur 6'**
  String inputFaceCounter(int n);

  /// No description provided for @inputPickColor.
  ///
  /// In fr, this message translates to:
  /// **'Choisis une couleur, puis touche les cases.'**
  String get inputPickColor;

  /// No description provided for @inputCheck.
  ///
  /// In fr, this message translates to:
  /// **'Vérifier'**
  String get inputCheck;

  /// No description provided for @inputPrevFace.
  ///
  /// In fr, this message translates to:
  /// **'Face d\'avant'**
  String get inputPrevFace;

  /// No description provided for @inputNextFace.
  ///
  /// In fr, this message translates to:
  /// **'Face suivante'**
  String get inputNextFace;

  /// No description provided for @inputClear.
  ///
  /// In fr, this message translates to:
  /// **'Effacer la face'**
  String get inputClear;

  /// No description provided for @inputColorCount.
  ///
  /// In fr, this message translates to:
  /// **'{count} sur 9'**
  String inputColorCount(int count);

  /// No description provided for @inputMissing.
  ///
  /// In fr, this message translates to:
  /// **'Il reste des cases à colorier.'**
  String get inputMissing;

  /// No description provided for @errTooMany.
  ///
  /// In fr, this message translates to:
  /// **'Oups, il y a trop de cases {color}. Vérifie !'**
  String errTooMany(String color);

  /// No description provided for @errPiece.
  ///
  /// In fr, this message translates to:
  /// **'Oups, une case semble mal coloriée. Vérifie {face} !'**
  String errPiece(String face);

  /// No description provided for @errImpossible.
  ///
  /// In fr, this message translates to:
  /// **'Hmm, vérifie bien toutes les faces, une par une.'**
  String get errImpossible;

  /// No description provided for @solveReady.
  ///
  /// In fr, this message translates to:
  /// **'C\'est parti ! Je te guide coup par coup.'**
  String get solveReady;

  /// No description provided for @solveStep.
  ///
  /// In fr, this message translates to:
  /// **'Étape {n} : {title}'**
  String solveStep(int n, String title);

  /// No description provided for @solveDoneAlready.
  ///
  /// In fr, this message translates to:
  /// **'Déjà fait, bravo !'**
  String get solveDoneAlready;

  /// No description provided for @solveIDidIt.
  ///
  /// In fr, this message translates to:
  /// **'C\'est fait'**
  String get solveIDidIt;

  /// No description provided for @solveMistake.
  ///
  /// In fr, this message translates to:
  /// **'Je me suis trompé'**
  String get solveMistake;

  /// No description provided for @solveMistakeHelp.
  ///
  /// In fr, this message translates to:
  /// **'Pas grave ! Colorie ton cube comme il est maintenant.'**
  String get solveMistakeHelp;

  /// No description provided for @solveFinished.
  ///
  /// In fr, this message translates to:
  /// **'Bravo, tu as résolu ton vrai cube ! 🎉'**
  String get solveFinished;

  /// No description provided for @solveProgress.
  ///
  /// In fr, this message translates to:
  /// **'Coup {n} sur {total}'**
  String solveProgress(int n, int total);

  /// No description provided for @solveEditColors.
  ///
  /// In fr, this message translates to:
  /// **'Modifier les couleurs'**
  String get solveEditColors;

  /// No description provided for @backHome.
  ///
  /// In fr, this message translates to:
  /// **'Retour à l\'accueil'**
  String get backHome;

  /// No description provided for @timer.
  ///
  /// In fr, this message translates to:
  /// **'Chrono'**
  String get timer;

  /// No description provided for @practiceWhichStep.
  ///
  /// In fr, this message translates to:
  /// **'Quelle étape ?'**
  String get practiceWhichStep;

  /// No description provided for @practiceStepIs.
  ///
  /// In fr, this message translates to:
  /// **'Tu en es à l\'île {n} : {title}'**
  String practiceStepIs(int n, String title);

  /// No description provided for @practiceSolvedIn.
  ///
  /// In fr, this message translates to:
  /// **'Résolu en {time} !'**
  String practiceSolvedIn(String time);

  /// No description provided for @practiceFlipWhiteUp.
  ///
  /// In fr, this message translates to:
  /// **'Retourne le cube : blanc en haut.'**
  String get practiceFlipWhiteUp;

  /// No description provided for @practiceFlipYellowUp.
  ///
  /// In fr, this message translates to:
  /// **'Retourne le cube : jaune en haut.'**
  String get practiceFlipYellowUp;

  /// No description provided for @practiceAlreadySolved.
  ///
  /// In fr, this message translates to:
  /// **'Le cube est déjà résolu ! Mélange-le.'**
  String get practiceAlreadySolved;

  /// No description provided for @settingsVoice.
  ///
  /// In fr, this message translates to:
  /// **'Voix'**
  String get settingsVoice;

  /// No description provided for @settingsVoiceHelp.
  ///
  /// In fr, this message translates to:
  /// **'Cubito lit les consignes à voix haute.'**
  String get settingsVoiceHelp;

  /// No description provided for @settingsSounds.
  ///
  /// In fr, this message translates to:
  /// **'Sons'**
  String get settingsSounds;

  /// No description provided for @settingsSoundsHelp.
  ///
  /// In fr, this message translates to:
  /// **'Petits sons de réussite.'**
  String get settingsSoundsHelp;

  /// No description provided for @settingsSpeed.
  ///
  /// In fr, this message translates to:
  /// **'Vitesse du cube'**
  String get settingsSpeed;

  /// No description provided for @speedSlow.
  ///
  /// In fr, this message translates to:
  /// **'Lent'**
  String get speedSlow;

  /// No description provided for @speedNormal.
  ///
  /// In fr, this message translates to:
  /// **'Normal'**
  String get speedNormal;

  /// No description provided for @speedFast.
  ///
  /// In fr, this message translates to:
  /// **'Rapide'**
  String get speedFast;

  /// No description provided for @settingsColorBlind.
  ///
  /// In fr, this message translates to:
  /// **'Symboles sur les couleurs'**
  String get settingsColorBlind;

  /// No description provided for @settingsColorBlindHelp.
  ///
  /// In fr, this message translates to:
  /// **'Pour bien voir les couleurs (daltonisme).'**
  String get settingsColorBlindHelp;

  /// No description provided for @settingsLeftHanded.
  ///
  /// In fr, this message translates to:
  /// **'Je suis gaucher'**
  String get settingsLeftHanded;

  /// No description provided for @settingsLeftHandedHelp.
  ///
  /// In fr, this message translates to:
  /// **'Bientôt : des mouvements pour la main gauche.'**
  String get settingsLeftHandedHelp;

  /// No description provided for @settingsTryVoice.
  ///
  /// In fr, this message translates to:
  /// **'Essayer la voix'**
  String get settingsTryVoice;

  /// No description provided for @voiceSample.
  ///
  /// In fr, this message translates to:
  /// **'Bonjour ! Je suis Cubito. On résout le cube ensemble ?'**
  String get voiceSample;

  /// No description provided for @parentArea.
  ///
  /// In fr, this message translates to:
  /// **'Espace parent'**
  String get parentArea;

  /// No description provided for @parentQuestion.
  ///
  /// In fr, this message translates to:
  /// **'Combien font {a} + {b} ?'**
  String parentQuestion(int a, int b);

  /// No description provided for @parentWrong.
  ///
  /// In fr, this message translates to:
  /// **'Ce n\'est pas ça. Demande à un adulte !'**
  String get parentWrong;

  /// No description provided for @parentOk.
  ///
  /// In fr, this message translates to:
  /// **'Valider'**
  String get parentOk;

  /// No description provided for @parentReset.
  ///
  /// In fr, this message translates to:
  /// **'Remettre la progression à zéro'**
  String get parentReset;

  /// No description provided for @parentResetConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Toutes les étoiles et les trophées seront effacés.'**
  String get parentResetConfirm;

  /// No description provided for @parentResetDone.
  ///
  /// In fr, this message translates to:
  /// **'La progression a été remise à zéro.'**
  String get parentResetDone;

  /// No description provided for @parentPrivacy.
  ///
  /// In fr, this message translates to:
  /// **'Cette appli ne collecte aucune donnée. Rien n\'est envoyé sur Internet. La caméra sert seulement à lire les couleurs du cube, aucune image n\'est gardée.'**
  String get parentPrivacy;

  /// No description provided for @cancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get cancel;

  /// No description provided for @trophyFirstCross.
  ///
  /// In fr, this message translates to:
  /// **'Premiers gestes'**
  String get trophyFirstCross;

  /// No description provided for @trophyFirstCrossHelp.
  ///
  /// In fr, this message translates to:
  /// **'Réussis la leçon 1 : les gestes de base.'**
  String get trophyFirstCrossHelp;

  /// No description provided for @trophyHalfway.
  ///
  /// In fr, this message translates to:
  /// **'À mi-chemin'**
  String get trophyHalfway;

  /// No description provided for @trophyHalfwayHelp.
  ///
  /// In fr, this message translates to:
  /// **'Réussis la leçon 5.'**
  String get trophyHalfwayHelp;

  /// No description provided for @trophyAllIslands.
  ///
  /// In fr, this message translates to:
  /// **'Explorateur'**
  String get trophyAllIslands;

  /// No description provided for @trophyAllIslandsHelp.
  ///
  /// In fr, this message translates to:
  /// **'Réussis les 10 leçons.'**
  String get trophyAllIslandsHelp;

  /// No description provided for @trophyAllStars.
  ///
  /// In fr, this message translates to:
  /// **'Pluie d\'étoiles'**
  String get trophyAllStars;

  /// No description provided for @trophyAllStarsHelp.
  ///
  /// In fr, this message translates to:
  /// **'Gagne les 30 étoiles.'**
  String get trophyAllStarsHelp;

  /// No description provided for @trophyFirstSolve.
  ///
  /// In fr, this message translates to:
  /// **'Premier cube'**
  String get trophyFirstSolve;

  /// No description provided for @trophyFirstSolveHelp.
  ///
  /// In fr, this message translates to:
  /// **'Résous un cube en entier.'**
  String get trophyFirstSolveHelp;

  /// No description provided for @trophyRealCube.
  ///
  /// In fr, this message translates to:
  /// **'Le vrai cube'**
  String get trophyRealCube;

  /// No description provided for @trophyRealCubeHelp.
  ///
  /// In fr, this message translates to:
  /// **'Résous ton vrai cube avec Cubito.'**
  String get trophyRealCubeHelp;

  /// No description provided for @trophyFiveSolves.
  ///
  /// In fr, this message translates to:
  /// **'5 cubes'**
  String get trophyFiveSolves;

  /// No description provided for @trophyFiveSolvesHelp.
  ///
  /// In fr, this message translates to:
  /// **'Résous 5 cubes.'**
  String get trophyFiveSolvesHelp;

  /// No description provided for @trophyUnder5.
  ///
  /// In fr, this message translates to:
  /// **'Moins de 5 minutes'**
  String get trophyUnder5;

  /// No description provided for @trophyUnder5Help.
  ///
  /// In fr, this message translates to:
  /// **'Résous le cube virtuel au chrono en moins de 5 min.'**
  String get trophyUnder5Help;

  /// No description provided for @trophyUnder2.
  ///
  /// In fr, this message translates to:
  /// **'Fusée'**
  String get trophyUnder2;

  /// No description provided for @trophyUnder2Help.
  ///
  /// In fr, this message translates to:
  /// **'Moins de 2 minutes au chrono !'**
  String get trophyUnder2Help;

  /// No description provided for @trophiesCount.
  ///
  /// In fr, this message translates to:
  /// **'{n} trophées sur {total}'**
  String trophiesCount(int n, int total);

  /// No description provided for @statsSolves.
  ///
  /// In fr, this message translates to:
  /// **'Cubes résolus : {n}'**
  String statsSolves(int n);

  /// No description provided for @statsBest.
  ///
  /// In fr, this message translates to:
  /// **'Meilleur temps : {time}'**
  String statsBest(String time);

  /// No description provided for @memoShare.
  ///
  /// In fr, this message translates to:
  /// **'Imprimer ou partager la fiche'**
  String get memoShare;

  /// No description provided for @memoShareText.
  ///
  /// In fr, this message translates to:
  /// **'Ma fiche mémo Cubito'**
  String get memoShareText;

  /// No description provided for @solveChooseTitle.
  ///
  /// In fr, this message translates to:
  /// **'Comment veux-tu me montrer ton cube ?'**
  String get solveChooseTitle;

  /// No description provided for @solveChooseScan.
  ///
  /// In fr, this message translates to:
  /// **'Avec la caméra'**
  String get solveChooseScan;

  /// No description provided for @solveChooseScanHelp.
  ///
  /// In fr, this message translates to:
  /// **'Je regarde ton cube, face par face.'**
  String get solveChooseScanHelp;

  /// No description provided for @solveChooseHand.
  ///
  /// In fr, this message translates to:
  /// **'Colorier à la main'**
  String get solveChooseHand;

  /// No description provided for @solveChooseHandHelp.
  ///
  /// In fr, this message translates to:
  /// **'Tu colories les cases toi-même.'**
  String get solveChooseHandHelp;

  /// No description provided for @scanParentTitle.
  ///
  /// In fr, this message translates to:
  /// **'Pour les parents'**
  String get scanParentTitle;

  /// No description provided for @scanParentText.
  ///
  /// In fr, this message translates to:
  /// **'Pour lire les couleurs du cube, l\'appli a besoin de la caméra, seulement pendant le scan. Aucune photo n\'est enregistrée ni envoyée : tout reste sur le téléphone.'**
  String get scanParentText;

  /// No description provided for @scanAllow.
  ///
  /// In fr, this message translates to:
  /// **'Autoriser la caméra'**
  String get scanAllow;

  /// No description provided for @scanNoCamera.
  ///
  /// In fr, this message translates to:
  /// **'La caméra n\'est pas disponible. On colorie à la main ?'**
  String get scanNoCamera;

  /// No description provided for @scanStart.
  ///
  /// In fr, this message translates to:
  /// **'Tiens ton cube : centre blanc face à toi, vert en haut.'**
  String get scanStart;

  /// No description provided for @scanRoll.
  ///
  /// In fr, this message translates to:
  /// **'Fais rouler le cube vers toi : le dessus vient devant.'**
  String get scanRoll;

  /// No description provided for @scanTurnLeft.
  ///
  /// In fr, this message translates to:
  /// **'Tourne le cube vers la gauche.'**
  String get scanTurnLeft;

  /// No description provided for @scanTurnLeftTwice.
  ///
  /// In fr, this message translates to:
  /// **'Tourne encore le cube 2 fois vers la gauche.'**
  String get scanTurnLeftTwice;

  /// No description provided for @scanShowCenter.
  ///
  /// In fr, this message translates to:
  /// **'Montre le centre {color}, {top} en haut.'**
  String scanShowCenter(String color, String top);

  /// No description provided for @scanTooDark.
  ///
  /// In fr, this message translates to:
  /// **'Va près d\'une lampe.'**
  String get scanTooDark;

  /// No description provided for @scanCloser.
  ///
  /// In fr, this message translates to:
  /// **'Rapproche-toi.'**
  String get scanCloser;

  /// No description provided for @scanHoldStill.
  ///
  /// In fr, this message translates to:
  /// **'Ne bouge plus.'**
  String get scanHoldStill;

  /// No description provided for @scanWrongFace.
  ///
  /// In fr, this message translates to:
  /// **'Oups, ce n\'est pas la bonne face.'**
  String get scanWrongFace;

  /// No description provided for @scanGot.
  ///
  /// In fr, this message translates to:
  /// **'Super !'**
  String get scanGot;

  /// No description provided for @scanVerifyTitle.
  ///
  /// In fr, this message translates to:
  /// **'C\'est bien ton cube ?'**
  String get scanVerifyTitle;

  /// No description provided for @scanVerifyHelp.
  ///
  /// In fr, this message translates to:
  /// **'Les cases qui clignotent sont peut-être fausses. Touche une case pour changer sa couleur.'**
  String get scanVerifyHelp;

  /// No description provided for @scanYes.
  ///
  /// In fr, this message translates to:
  /// **'Oui, c\'est mon cube'**
  String get scanYes;

  /// No description provided for @scanFix.
  ///
  /// In fr, this message translates to:
  /// **'Corriger à la main'**
  String get scanFix;

  /// No description provided for @scanRedoFace.
  ///
  /// In fr, this message translates to:
  /// **'Je crois que je me suis trompé sur {face}. On la refait ?'**
  String scanRedoFace(String face);

  /// No description provided for @scanRedoYes.
  ///
  /// In fr, this message translates to:
  /// **'Refaire cette face'**
  String get scanRedoYes;

  /// No description provided for @scanPickColor.
  ///
  /// In fr, this message translates to:
  /// **'Choisis la bonne couleur'**
  String get scanPickColor;

  /// No description provided for @solveHoldStart.
  ///
  /// In fr, this message translates to:
  /// **'Tiens ton cube : blanc en haut, vert devant toi.'**
  String get solveHoldStart;

  /// No description provided for @onTop.
  ///
  /// In fr, this message translates to:
  /// **'{color} en haut'**
  String onTop(String color);

  /// No description provided for @inFront.
  ///
  /// In fr, this message translates to:
  /// **'{color} devant'**
  String inFront(String color);

  /// No description provided for @wholeCubeTurns.
  ///
  /// In fr, this message translates to:
  /// **'Tout le cube tourne dans tes mains.'**
  String get wholeCubeTurns;

  /// No description provided for @timesBadge.
  ///
  /// In fr, this message translates to:
  /// **'fois {n} sur {total}'**
  String timesBadge(int n, int total);

  /// No description provided for @placeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Tiens ton cube comme ça'**
  String get placeTitle;

  /// No description provided for @placeCenters.
  ///
  /// In fr, this message translates to:
  /// **'Vérifie les deux centres entourés.'**
  String get placeCenters;

  /// No description provided for @placeOk.
  ///
  /// In fr, this message translates to:
  /// **'C\'est bon !'**
  String get placeOk;

  /// No description provided for @formulaLabel.
  ///
  /// In fr, this message translates to:
  /// **'LA FORMULE'**
  String get formulaLabel;

  /// No description provided for @formulaSing.
  ///
  /// In fr, this message translates to:
  /// **'Chante-la :'**
  String get formulaSing;

  /// No description provided for @formulaTimes.
  ///
  /// In fr, this message translates to:
  /// **'Ici : {n} fois'**
  String formulaTimes(int n);

  /// No description provided for @formulaNoTurn.
  ///
  /// In fr, this message translates to:
  /// **'Ne tourne pas le cube pendant la formule.'**
  String get formulaNoTurn;

  /// No description provided for @formulaGo.
  ///
  /// In fr, this message translates to:
  /// **'On y va !'**
  String get formulaGo;

  /// No description provided for @formulaPart.
  ///
  /// In fr, this message translates to:
  /// **'Morceau {n} sur {total}'**
  String formulaPart(int n, int total);

  /// No description provided for @formulaParts.
  ///
  /// In fr, this message translates to:
  /// **'C\'est long : on la coupe en {n} morceaux.'**
  String formulaParts(int n);

  /// No description provided for @formulaTimesProgress.
  ///
  /// In fr, this message translates to:
  /// **'fois {n} sur {total}'**
  String formulaTimesProgress(int n, int total);

  /// No description provided for @gestureDone.
  ///
  /// In fr, this message translates to:
  /// **'Fait !'**
  String get gestureDone;

  /// No description provided for @handRight.
  ///
  /// In fr, this message translates to:
  /// **'main droite'**
  String get handRight;

  /// No description provided for @handLeft.
  ///
  /// In fr, this message translates to:
  /// **'main gauche'**
  String get handLeft;

  /// No description provided for @checkTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ton cube ressemble à ça ?'**
  String get checkTitle;

  /// No description provided for @checkYes.
  ///
  /// In fr, this message translates to:
  /// **'Oui !'**
  String get checkYes;

  /// No description provided for @checkNo.
  ///
  /// In fr, this message translates to:
  /// **'Pas tout à fait'**
  String get checkNo;

  /// No description provided for @checkRetry.
  ///
  /// In fr, this message translates to:
  /// **'Pas grave ! On recommence la formule.'**
  String get checkRetry;

  /// No description provided for @verbUp.
  ///
  /// In fr, this message translates to:
  /// **'MONTE'**
  String get verbUp;

  /// No description provided for @verbDown.
  ///
  /// In fr, this message translates to:
  /// **'DESCENDS'**
  String get verbDown;

  /// No description provided for @verbLeft.
  ///
  /// In fr, this message translates to:
  /// **'À GAUCHE'**
  String get verbLeft;

  /// No description provided for @verbRight.
  ///
  /// In fr, this message translates to:
  /// **'À DROITE'**
  String get verbRight;

  /// No description provided for @verbTurn.
  ///
  /// In fr, this message translates to:
  /// **'TOURNE'**
  String get verbTurn;

  /// No description provided for @objRightCol.
  ///
  /// In fr, this message translates to:
  /// **'la colonne de droite'**
  String get objRightCol;

  /// No description provided for @objLeftCol.
  ///
  /// In fr, this message translates to:
  /// **'la colonne de gauche'**
  String get objLeftCol;

  /// No description provided for @objTopRow.
  ///
  /// In fr, this message translates to:
  /// **'la ligne du haut'**
  String get objTopRow;

  /// No description provided for @objBottomRow.
  ///
  /// In fr, this message translates to:
  /// **'la ligne du bas'**
  String get objBottomRow;

  /// No description provided for @objFrontCw.
  ///
  /// In fr, this message translates to:
  /// **'la face devant toi, comme une horloge'**
  String get objFrontCw;

  /// No description provided for @objFrontCcw.
  ///
  /// In fr, this message translates to:
  /// **'la face devant toi, à l\'envers'**
  String get objFrontCcw;

  /// No description provided for @objBack.
  ///
  /// In fr, this message translates to:
  /// **'la face de derrière'**
  String get objBack;

  /// No description provided for @twiceSuffix.
  ///
  /// In fr, this message translates to:
  /// **'2 fois'**
  String get twiceSuffix;

  /// No description provided for @chantUp.
  ///
  /// In fr, this message translates to:
  /// **'monte'**
  String get chantUp;

  /// No description provided for @chantDown.
  ///
  /// In fr, this message translates to:
  /// **'descends'**
  String get chantDown;

  /// No description provided for @chantLeft.
  ///
  /// In fr, this message translates to:
  /// **'à gauche'**
  String get chantLeft;

  /// No description provided for @chantRight.
  ///
  /// In fr, this message translates to:
  /// **'à droite'**
  String get chantRight;

  /// No description provided for @chantTurn.
  ///
  /// In fr, this message translates to:
  /// **'tourne'**
  String get chantTurn;

  /// No description provided for @chantTurnBack.
  ///
  /// In fr, this message translates to:
  /// **'tourne à l\'envers'**
  String get chantTurnBack;

  /// No description provided for @yourTurnSwipe.
  ///
  /// In fr, this message translates to:
  /// **'Glisse ton doigt sur la partie violette.'**
  String get yourTurnSwipe;

  /// No description provided for @wellDoneShort.
  ///
  /// In fr, this message translates to:
  /// **'Bravo !'**
  String get wellDoneShort;

  /// No description provided for @goalBefore.
  ///
  /// In fr, this message translates to:
  /// **'Avant'**
  String get goalBefore;

  /// No description provided for @goalAfter.
  ///
  /// In fr, this message translates to:
  /// **'Après'**
  String get goalAfter;

  /// No description provided for @checkCompare.
  ///
  /// In fr, this message translates to:
  /// **'Compare avec ton vrai cube.'**
  String get checkCompare;

  /// No description provided for @scanNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Mets ton cube dans le carré.'**
  String get scanNotFound;

  /// No description provided for @scanDoGesture.
  ///
  /// In fr, this message translates to:
  /// **'Fais le geste, puis montre la face suivante.'**
  String get scanDoGesture;

  /// No description provided for @scanISee.
  ///
  /// In fr, this message translates to:
  /// **'Je vois :'**
  String get scanISee;

  /// No description provided for @scanTakeNow.
  ///
  /// In fr, this message translates to:
  /// **'Prendre cette face'**
  String get scanTakeNow;

  /// No description provided for @scanTorchOn.
  ///
  /// In fr, this message translates to:
  /// **'Allumer la lampe'**
  String get scanTorchOn;

  /// No description provided for @scanTorchOff.
  ///
  /// In fr, this message translates to:
  /// **'Éteindre la lampe'**
  String get scanTorchOff;

  /// No description provided for @scanTooDarkTorch.
  ///
  /// In fr, this message translates to:
  /// **'C\'est sombre : allume la lampe !'**
  String get scanTooDarkTorch;

  /// No description provided for @solvePathTitle.
  ///
  /// In fr, this message translates to:
  /// **'Comment veux-tu le résoudre ?'**
  String get solvePathTitle;

  /// No description provided for @solvePathMethod.
  ///
  /// In fr, this message translates to:
  /// **'Toute la méthode'**
  String get solvePathMethod;

  /// No description provided for @solvePathMethodHelp.
  ///
  /// In fr, this message translates to:
  /// **'On repart de l\'étape 1 et on fait toutes les formules apprises, étape par étape.'**
  String get solvePathMethodHelp;

  /// No description provided for @solvePathShort.
  ///
  /// In fr, this message translates to:
  /// **'Le plus court'**
  String get solvePathShort;

  /// No description provided for @solvePathShortHelp.
  ///
  /// In fr, this message translates to:
  /// **'Le moins de gestes possible. On ne suit pas les étapes : un geste à la fois.'**
  String get solvePathShortHelp;

  /// No description provided for @solvePathMoves.
  ///
  /// In fr, this message translates to:
  /// **'{n} gestes'**
  String solvePathMoves(int n);

  /// No description provided for @solvePathThinking.
  ///
  /// In fr, this message translates to:
  /// **'Je cherche le chemin le plus court…'**
  String get solvePathThinking;

  /// No description provided for @solveShortHeader.
  ///
  /// In fr, this message translates to:
  /// **'Chemin court · geste {n} sur {total}'**
  String solveShortHeader(int n, int total);

  /// No description provided for @lessonNumber.
  ///
  /// In fr, this message translates to:
  /// **'Leçon {n}'**
  String lessonNumber(int n);

  /// No description provided for @lessonBasicsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Les gestes de base'**
  String get lessonBasicsTitle;

  /// No description provided for @lessonBasicsUse.
  ///
  /// In fr, this message translates to:
  /// **'Avant de commencer'**
  String get lessonBasicsUse;

  /// No description provided for @lessonBasicsGoal.
  ///
  /// In fr, this message translates to:
  /// **'Apprends les 10 gestes qui servent partout : monter, descendre, tourner les lignes et la face de devant.'**
  String get lessonBasicsGoal;

  /// No description provided for @lessonReview.
  ///
  /// In fr, this message translates to:
  /// **'{name} (révision)'**
  String lessonReview(String name);

  /// No description provided for @lessonFormula.
  ///
  /// In fr, this message translates to:
  /// **'La formule'**
  String get lessonFormula;

  /// No description provided for @lessonGestures.
  ///
  /// In fr, this message translates to:
  /// **'Les gestes'**
  String get lessonGestures;

  /// No description provided for @memoryPrompt.
  ///
  /// In fr, this message translates to:
  /// **'De mémoire : fais le geste suivant.'**
  String get memoryPrompt;

  /// No description provided for @memoryHelp.
  ///
  /// In fr, this message translates to:
  /// **'💡 Aide'**
  String get memoryHelp;

  /// No description provided for @memoryPerfect.
  ///
  /// In fr, this message translates to:
  /// **'Tu la connais par cœur !'**
  String get memoryPerfect;

  /// No description provided for @memoryAlmost.
  ///
  /// In fr, this message translates to:
  /// **'Bravo ! Refais-la pour la savoir sans aide.'**
  String get memoryAlmost;

  /// No description provided for @memoryAgain.
  ///
  /// In fr, this message translates to:
  /// **'Recommencer'**
  String get memoryAgain;

  /// No description provided for @lessonNext.
  ///
  /// In fr, this message translates to:
  /// **'Leçon suivante'**
  String get lessonNext;

  /// No description provided for @lessonReplay.
  ///
  /// In fr, this message translates to:
  /// **'Revoir'**
  String get lessonReplay;

  /// No description provided for @lessonLearned.
  ///
  /// In fr, this message translates to:
  /// **'✅ Vue'**
  String get lessonLearned;

  /// No description provided for @lessonSeenCount.
  ///
  /// In fr, this message translates to:
  /// **'{n}/{total}'**
  String lessonSeenCount(int n, int total);

  /// No description provided for @lessonYouSaw.
  ///
  /// In fr, this message translates to:
  /// **'Tu viens de voir'**
  String get lessonYouSaw;

  /// No description provided for @cubeTwistedCorner.
  ///
  /// In fr, this message translates to:
  /// **'Un coin a été tourné à la main : ce cube ne peut plus se résoudre. Un adulte peut tourner un coin sur lui-même (un tiers de tour), puis on recommence.'**
  String get cubeTwistedCorner;

  /// No description provided for @cubeFlippedEdge.
  ///
  /// In fr, this message translates to:
  /// **'Une arête a été remise à l\'envers à la main : ce cube ne peut plus se résoudre. Un adulte peut retourner une arête, puis on recommence.'**
  String get cubeFlippedEdge;

  /// No description provided for @cubeSwappedPieces.
  ///
  /// In fr, this message translates to:
  /// **'Deux pièces ont été échangées à la main : ce cube ne peut plus se résoudre. Un adulte peut échanger deux coins, puis on recommence.'**
  String get cubeSwappedPieces;

  /// No description provided for @scanRestart.
  ///
  /// In fr, this message translates to:
  /// **'Recommencer le scan'**
  String get scanRestart;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
