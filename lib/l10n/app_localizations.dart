import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ca.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ca'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Fog of War'**
  String get appTitle;

  /// No description provided for @onboardingSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingSkip;

  /// No description provided for @onboardingNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardingNext;

  /// No description provided for @onboardingStart.
  ///
  /// In en, this message translates to:
  /// **'Start exploring!'**
  String get onboardingStart;

  /// No description provided for @onboardingWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Your city, under the fog'**
  String get onboardingWelcomeTitle;

  /// No description provided for @onboardingWelcomeBody.
  ///
  /// In en, this message translates to:
  /// **'The whole map starts hidden by fog. Explore the real city to uncover it bit by bit and turn it into your own adventure.'**
  String get onboardingWelcomeBody;

  /// No description provided for @onboardingMoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Move to clear the fog'**
  String get onboardingMoveTitle;

  /// No description provided for @onboardingMoveBody.
  ///
  /// In en, this message translates to:
  /// **'The fog only lifts as you walk around in real life. Your GPS reveals the area around you — there\'s no cheating from the couch!'**
  String get onboardingMoveBody;

  /// No description provided for @onboardingDiscoverTitle.
  ///
  /// In en, this message translates to:
  /// **'Discover places'**
  String get onboardingDiscoverTitle;

  /// No description provided for @onboardingDiscoverBody.
  ///
  /// In en, this message translates to:
  /// **'Reach points of interest to discover them and earn points. Each one tells you what it is and why it\'s worth a visit.'**
  String get onboardingDiscoverBody;

  /// No description provided for @onboardingCollectTitle.
  ///
  /// In en, this message translates to:
  /// **'Watchtowers & collections'**
  String get onboardingCollectTitle;

  /// No description provided for @onboardingCollectBody.
  ///
  /// In en, this message translates to:
  /// **'Climb to watchtowers to spot nearby places, and complete themed collections as you explore the city.'**
  String get onboardingCollectBody;

  /// No description provided for @hudCells.
  ///
  /// In en, this message translates to:
  /// **'cells'**
  String get hudCells;

  /// No description provided for @hudPoints.
  ///
  /// In en, this message translates to:
  /// **'points'**
  String get hudPoints;

  /// No description provided for @hudPois.
  ///
  /// In en, this message translates to:
  /// **'POIs'**
  String get hudPois;

  /// No description provided for @tooltipMapStyle.
  ///
  /// In en, this message translates to:
  /// **'Change map style'**
  String get tooltipMapStyle;

  /// No description provided for @tooltipGpsMode.
  ///
  /// In en, this message translates to:
  /// **'Change GPS mode (accuracy / battery)'**
  String get tooltipGpsMode;

  /// No description provided for @tooltipSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings & customization'**
  String get tooltipSettings;

  /// No description provided for @tooltipRanking.
  ///
  /// In en, this message translates to:
  /// **'Leaderboard'**
  String get tooltipRanking;

  /// No description provided for @tooltipCollections.
  ///
  /// In en, this message translates to:
  /// **'POI collection'**
  String get tooltipCollections;

  /// No description provided for @tooltipRecenter.
  ///
  /// In en, this message translates to:
  /// **'Center on me'**
  String get tooltipRecenter;

  /// No description provided for @gpsModeExploration.
  ///
  /// In en, this message translates to:
  /// **'Exploration (high accuracy)'**
  String get gpsModeExploration;

  /// No description provided for @gpsModeBattery.
  ///
  /// In en, this message translates to:
  /// **'Battery saving'**
  String get gpsModeBattery;

  /// No description provided for @gpsStatus.
  ///
  /// In en, this message translates to:
  /// **'GPS: {mode}'**
  String gpsStatus(String mode);

  /// No description provided for @mapStatus.
  ///
  /// In en, this message translates to:
  /// **'Map: {name}'**
  String mapStatus(String name);

  /// No description provided for @noLocationYet.
  ///
  /// In en, this message translates to:
  /// **'I don\'t have your location yet.'**
  String get noLocationYet;

  /// No description provided for @permGrantedWhileInUse.
  ///
  /// In en, this message translates to:
  /// **'To record with the app closed, set \"Allow all the time\" in location settings.'**
  String get permGrantedWhileInUse;

  /// No description provided for @permServiceDisabled.
  ///
  /// In en, this message translates to:
  /// **'Device location is off. Turn it on to play.'**
  String get permServiceDisabled;

  /// No description provided for @permDeniedForever.
  ///
  /// In en, this message translates to:
  /// **'Location permission denied. Enable it in the app settings.'**
  String get permDeniedForever;

  /// No description provided for @permDenied.
  ///
  /// In en, this message translates to:
  /// **'No location permission: the fog won\'t clear as you move.'**
  String get permDenied;

  /// No description provided for @poiDiscoveredSingle.
  ///
  /// In en, this message translates to:
  /// **'🏛️ You discovered {name}!  +{points} points'**
  String poiDiscoveredSingle(String name, int points);

  /// No description provided for @poiDiscoveredMultiple.
  ///
  /// In en, this message translates to:
  /// **'🏛️ {count} POIs discovered!  +{points} points'**
  String poiDiscoveredMultiple(int count, int points);

  /// No description provided for @watchtowerSighted.
  ///
  /// In en, this message translates to:
  /// **'🔭 {name}: {count} POIs in sight'**
  String watchtowerSighted(String name, int count);

  /// No description provided for @notifDiscoveryTitle.
  ///
  /// In en, this message translates to:
  /// **'New discovery!'**
  String get notifDiscoveryTitle;

  /// No description provided for @mapStyleVoyager.
  ///
  /// In en, this message translates to:
  /// **'Voyager'**
  String get mapStyleVoyager;

  /// No description provided for @mapStyleLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get mapStyleLight;

  /// No description provided for @mapStyleDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get mapStyleDark;

  /// No description provided for @mapStyleOsm.
  ///
  /// In en, this message translates to:
  /// **'Classic OSM'**
  String get mapStyleOsm;

  /// No description provided for @mapStyleSatellite.
  ///
  /// In en, this message translates to:
  /// **'Satellite'**
  String get mapStyleSatellite;

  /// No description provided for @mapStyleTopographic.
  ///
  /// In en, this message translates to:
  /// **'Topographic'**
  String get mapStyleTopographic;

  /// No description provided for @mapStyleExplorer.
  ///
  /// In en, this message translates to:
  /// **'Explorer'**
  String get mapStyleExplorer;

  /// No description provided for @mapStyleSepia.
  ///
  /// In en, this message translates to:
  /// **'Amber'**
  String get mapStyleSepia;

  /// No description provided for @mapStyleBright.
  ///
  /// In en, this message translates to:
  /// **'Vivid'**
  String get mapStyleBright;

  /// No description provided for @mapStyleLiberty.
  ///
  /// In en, this message translates to:
  /// **'Detailed'**
  String get mapStyleLiberty;

  /// No description provided for @mapStyleGame.
  ///
  /// In en, this message translates to:
  /// **'Game'**
  String get mapStyleGame;

  /// No description provided for @mapStyleCorsair.
  ///
  /// In en, this message translates to:
  /// **'Corsair'**
  String get mapStyleCorsair;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsIcon.
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get settingsIcon;

  /// No description provided for @settingsColor.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get settingsColor;

  /// No description provided for @settingsMarkerPreview.
  ///
  /// In en, this message translates to:
  /// **'Your marker on the map'**
  String get settingsMarkerPreview;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get languageSystem;

  /// No description provided for @settingsAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settingsAccount;

  /// No description provided for @accountBenefit.
  ///
  /// In en, this message translates to:
  /// **'Back up your progress to the cloud and restore it on any phone.'**
  String get accountBenefit;

  /// No description provided for @accountSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get accountSignIn;

  /// No description provided for @accountSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get accountSignOut;

  /// No description provided for @accountSyncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing…'**
  String get accountSyncing;

  /// No description provided for @accountSynced.
  ///
  /// In en, this message translates to:
  /// **'Progress synced'**
  String get accountSynced;

  /// No description provided for @accountSyncError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t sync; it will retry on its own'**
  String get accountSyncError;

  /// No description provided for @accountSignInFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the sign-in page'**
  String get accountSignInFailed;

  /// No description provided for @hudMission.
  ///
  /// In en, this message translates to:
  /// **'Mission'**
  String get hudMission;

  /// No description provided for @pinMission.
  ///
  /// In en, this message translates to:
  /// **'Pin as mission'**
  String get pinMission;

  /// No description provided for @unpinMission.
  ///
  /// In en, this message translates to:
  /// **'Unpin mission'**
  String get unpinMission;

  /// No description provided for @missionPinnedToast.
  ///
  /// In en, this message translates to:
  /// **'📌 Mission: {name}'**
  String missionPinnedToast(String name);

  /// No description provided for @missionUnpinnedToast.
  ///
  /// In en, this message translates to:
  /// **'Mission removed'**
  String get missionUnpinnedToast;

  /// No description provided for @leaderboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Leaderboard'**
  String get leaderboardTitle;

  /// No description provided for @rankHeadline.
  ///
  /// In en, this message translates to:
  /// **'You\'re #{rank}'**
  String rankHeadline(int rank);

  /// No description provided for @globalSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your score: {score} pts'**
  String globalSubtitle(int score);

  /// No description provided for @collectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You\'ve discovered {discovered} of {total}'**
  String collectionSubtitle(int discovered, int total);

  /// No description provided for @unitPts.
  ///
  /// In en, this message translates to:
  /// **'pts'**
  String get unitPts;

  /// No description provided for @unitPois.
  ///
  /// In en, this message translates to:
  /// **'POIs'**
  String get unitPois;

  /// No description provided for @youSuffix.
  ///
  /// In en, this message translates to:
  /// **'{name} (you)'**
  String youSuffix(String name);

  /// No description provided for @citiesTitle.
  ///
  /// In en, this message translates to:
  /// **'Cities'**
  String get citiesTitle;

  /// No description provided for @citiesStats.
  ///
  /// In en, this message translates to:
  /// **'{cells} cells · {discovered}/{total} POIs'**
  String citiesStats(int cells, int discovered, int total);

  /// No description provided for @collectionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Collections'**
  String get collectionsTitle;

  /// No description provided for @collectionLeaderboardTooltip.
  ///
  /// In en, this message translates to:
  /// **'This collection\'s leaderboard'**
  String get collectionLeaderboardTooltip;

  /// No description provided for @collectionProgress.
  ///
  /// In en, this message translates to:
  /// **'{discovered} / {total} discovered'**
  String collectionProgress(int discovered, int total);

  /// No description provided for @collectionCompleted.
  ///
  /// In en, this message translates to:
  /// **'Collection completed! 🎉'**
  String get collectionCompleted;

  /// No description provided for @pointsBadge.
  ///
  /// In en, this message translates to:
  /// **'{points} pts'**
  String pointsBadge(int points);

  /// No description provided for @poiHiddenName.
  ///
  /// In en, this message translates to:
  /// **'?????'**
  String get poiHiddenName;

  /// No description provided for @poiPointsEarned.
  ///
  /// In en, this message translates to:
  /// **'+{points} points'**
  String poiPointsEarned(int points);

  /// No description provided for @poiToDiscover.
  ///
  /// In en, this message translates to:
  /// **'To discover · {points} pts'**
  String poiToDiscover(int points);

  /// No description provided for @poiSheetInCollections.
  ///
  /// In en, this message translates to:
  /// **'In these collections'**
  String get poiSheetInCollections;

  /// No description provided for @poiSheetNoCollections.
  ///
  /// In en, this message translates to:
  /// **'Not part of any collection yet.'**
  String get poiSheetNoCollections;

  /// No description provided for @poiSheetOpenInMaps.
  ///
  /// In en, this message translates to:
  /// **'Open in Google Maps'**
  String get poiSheetOpenInMaps;

  /// No description provided for @poiSheetUndiscoveredTitle.
  ///
  /// In en, this message translates to:
  /// **'Yet to discover'**
  String get poiSheetUndiscoveredTitle;

  /// No description provided for @poiSheetUndiscoveredHint.
  ///
  /// In en, this message translates to:
  /// **'Get close to this spot to reveal what\'s hidden here. Adventure awaits! 🧭'**
  String get poiSheetUndiscoveredHint;

  /// No description provided for @poiSheetMapsError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open Google Maps.'**
  String get poiSheetMapsError;

  /// No description provided for @poiSheetDistanceAway.
  ///
  /// In en, this message translates to:
  /// **'{distance} from you'**
  String poiSheetDistanceAway(String distance);

  /// No description provided for @poiSheetStatRating.
  ///
  /// In en, this message translates to:
  /// **'rating'**
  String get poiSheetStatRating;

  /// No description provided for @poiSheetStatVisit.
  ///
  /// In en, this message translates to:
  /// **'visit'**
  String get poiSheetStatVisit;

  /// No description provided for @poiSheetStatExplored.
  ///
  /// In en, this message translates to:
  /// **'explored'**
  String get poiSheetStatExplored;

  /// No description provided for @poiSheetAppearsIn.
  ///
  /// In en, this message translates to:
  /// **'Appears in'**
  String get poiSheetAppearsIn;

  /// No description provided for @poiSheetProgress.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} completed'**
  String poiSheetProgress(int done, int total);

  /// No description provided for @poiSheetStops.
  ///
  /// In en, this message translates to:
  /// **'{count} stops'**
  String poiSheetStops(int count);

  /// No description provided for @poiSheetDirections.
  ///
  /// In en, this message translates to:
  /// **'Get directions'**
  String get poiSheetDirections;

  /// No description provided for @collGaudiName.
  ///
  /// In en, this message translates to:
  /// **'Gaudí Route'**
  String get collGaudiName;

  /// No description provided for @collGaudiDesc.
  ///
  /// In en, this message translates to:
  /// **'Antoni Gaudí\'s modernist work across Barcelona.'**
  String get collGaudiDesc;

  /// No description provided for @collEssentialName.
  ///
  /// In en, this message translates to:
  /// **'Barcelona Essentials'**
  String get collEssentialName;

  /// No description provided for @collEssentialDesc.
  ///
  /// In en, this message translates to:
  /// **'The must-see places in the city.'**
  String get collEssentialDesc;

  /// No description provided for @collOtakuName.
  ///
  /// In en, this message translates to:
  /// **'Otaku BCN (example)'**
  String get collOtakuName;

  /// No description provided for @collOtakuDesc.
  ///
  /// In en, this message translates to:
  /// **'Temples of comics, manga and geek culture.'**
  String get collOtakuDesc;

  /// No description provided for @collMuseumsName.
  ///
  /// In en, this message translates to:
  /// **'Barcelona Museums'**
  String get collMuseumsName;

  /// No description provided for @collMuseumsDesc.
  ///
  /// In en, this message translates to:
  /// **'The city\'s great museums.'**
  String get collMuseumsDesc;

  /// No description provided for @collTapasName.
  ///
  /// In en, this message translates to:
  /// **'Tapas Trail'**
  String get collTapasName;

  /// No description provided for @collTapasDesc.
  ///
  /// In en, this message translates to:
  /// **'Barcelona\'s classic tapas bars.'**
  String get collTapasDesc;

  /// No description provided for @collMichelinName.
  ///
  /// In en, this message translates to:
  /// **'Michelin Stars'**
  String get collMichelinName;

  /// No description provided for @collMichelinDesc.
  ///
  /// In en, this message translates to:
  /// **'Barcelona\'s starred fine dining.'**
  String get collMichelinDesc;

  /// No description provided for @achievementsTitle.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get achievementsTitle;

  /// No description provided for @achievementsUnlocked.
  ///
  /// In en, this message translates to:
  /// **'{unlocked} of {total} unlocked'**
  String achievementsUnlocked(int unlocked, int total);

  /// No description provided for @achievementFamilyDone.
  ///
  /// In en, this message translates to:
  /// **'All levels complete! 🏅'**
  String get achievementFamilyDone;

  /// No description provided for @achievementUnlockedToast.
  ///
  /// In en, this message translates to:
  /// **'Achievement unlocked: {name}'**
  String achievementUnlockedToast(String name);

  /// No description provided for @achTierBronze.
  ///
  /// In en, this message translates to:
  /// **'Bronze'**
  String get achTierBronze;

  /// No description provided for @achTierSilver.
  ///
  /// In en, this message translates to:
  /// **'Silver'**
  String get achTierSilver;

  /// No description provided for @achTierGold.
  ///
  /// In en, this message translates to:
  /// **'Gold'**
  String get achTierGold;

  /// No description provided for @achExplorerName.
  ///
  /// In en, this message translates to:
  /// **'Explorer'**
  String get achExplorerName;

  /// No description provided for @achExplorerGoal.
  ///
  /// In en, this message translates to:
  /// **'Uncover {count} fog cells'**
  String achExplorerGoal(int count);

  /// No description provided for @achTreasureName.
  ///
  /// In en, this message translates to:
  /// **'Treasure Hunter'**
  String get achTreasureName;

  /// No description provided for @achTreasureGoal.
  ///
  /// In en, this message translates to:
  /// **'Discover {count} POIs'**
  String achTreasureGoal(int count);

  /// No description provided for @achCartographerName.
  ///
  /// In en, this message translates to:
  /// **'Cartographer'**
  String get achCartographerName;

  /// No description provided for @achCartographerGoal.
  ///
  /// In en, this message translates to:
  /// **'Reveal {count}% of Barcelona'**
  String achCartographerGoal(int count);

  /// No description provided for @achLookoutName.
  ///
  /// In en, this message translates to:
  /// **'Lookout'**
  String get achLookoutName;

  /// No description provided for @achLookoutGoal.
  ///
  /// In en, this message translates to:
  /// **'Activate {count, plural, =1{1 watchtower} other{{count} watchtowers}}'**
  String achLookoutGoal(int count);

  /// No description provided for @achCollectorName.
  ///
  /// In en, this message translates to:
  /// **'Collector'**
  String get achCollectorName;

  /// No description provided for @achCollectorGoal.
  ///
  /// In en, this message translates to:
  /// **'Complete {count, plural, =1{1 collection} other{{count} collections}}'**
  String achCollectorGoal(int count);

  /// No description provided for @achExplorerTagline.
  ///
  /// In en, this message translates to:
  /// **'Uncover the fog as you go'**
  String get achExplorerTagline;

  /// No description provided for @achTreasureTagline.
  ///
  /// In en, this message translates to:
  /// **'Visit points of interest'**
  String get achTreasureTagline;

  /// No description provided for @achCartographerTagline.
  ///
  /// In en, this message translates to:
  /// **'Map out Barcelona'**
  String get achCartographerTagline;

  /// No description provided for @achLookoutTagline.
  ///
  /// In en, this message translates to:
  /// **'Activate the watchtowers'**
  String get achLookoutTagline;

  /// No description provided for @achCollectorTagline.
  ///
  /// In en, this message translates to:
  /// **'Complete collections'**
  String get achCollectorTagline;

  /// No description provided for @avatarTitle.
  ///
  /// In en, this message translates to:
  /// **'Your character'**
  String get avatarTitle;

  /// No description provided for @avatarRotateHint.
  ///
  /// In en, this message translates to:
  /// **'Drag to rotate · pinch to zoom'**
  String get avatarRotateHint;
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
      <String>['ca', 'en', 'es', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ca':
      return AppLocalizationsCa();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
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
