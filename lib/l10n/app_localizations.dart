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
