// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Fog of War';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingStart => 'Start exploring!';

  @override
  String get onboardingWelcomeTitle => 'Your city, under the fog';

  @override
  String get onboardingWelcomeBody =>
      'The whole map starts hidden by fog. Explore the real city to uncover it bit by bit and turn it into your own adventure.';

  @override
  String get onboardingMoveTitle => 'Move to clear the fog';

  @override
  String get onboardingMoveBody =>
      'The fog only lifts as you walk around in real life. Your GPS reveals the area around you — there\'s no cheating from the couch!';

  @override
  String get onboardingDiscoverTitle => 'Discover places';

  @override
  String get onboardingDiscoverBody =>
      'Reach points of interest to discover them and earn points. Each one tells you what it is and why it\'s worth a visit.';

  @override
  String get onboardingCollectTitle => 'Watchtowers & collections';

  @override
  String get onboardingCollectBody =>
      'Climb to watchtowers to spot nearby places, and complete themed collections as you explore the city.';

  @override
  String get hudCells => 'cells';

  @override
  String get hudPoints => 'points';

  @override
  String get hudPois => 'POIs';

  @override
  String get tooltipMapStyle => 'Change map style';

  @override
  String get tooltipGpsMode => 'Change GPS mode (accuracy / battery)';

  @override
  String get tooltipSettings => 'Settings & customization';

  @override
  String get tooltipRanking => 'Leaderboard';

  @override
  String get tooltipCollections => 'POI collection';

  @override
  String get tooltipRecenter => 'Center on me';

  @override
  String get gpsModeExploration => 'Exploration (high accuracy)';

  @override
  String get gpsModeBattery => 'Battery saving';

  @override
  String gpsStatus(String mode) {
    return 'GPS: $mode';
  }

  @override
  String mapStatus(String name) {
    return 'Map: $name';
  }

  @override
  String get noLocationYet => 'I don\'t have your location yet.';

  @override
  String get permGrantedWhileInUse =>
      'To record with the app closed, set \"Allow all the time\" in location settings.';

  @override
  String get permServiceDisabled =>
      'Device location is off. Turn it on to play.';

  @override
  String get permDeniedForever =>
      'Location permission denied. Enable it in the app settings.';

  @override
  String get permDenied =>
      'No location permission: the fog won\'t clear as you move.';

  @override
  String poiDiscoveredSingle(String name, int points) {
    return '🏛️ You discovered $name!  +$points points';
  }

  @override
  String poiDiscoveredMultiple(int count, int points) {
    return '🏛️ $count POIs discovered!  +$points points';
  }

  @override
  String watchtowerSighted(String name, int count) {
    return '🔭 $name: $count POIs in sight';
  }

  @override
  String get notifDiscoveryTitle => 'New discovery!';

  @override
  String get mapStyleVoyager => 'Voyager';

  @override
  String get mapStyleLight => 'Light';

  @override
  String get mapStyleDark => 'Dark';

  @override
  String get mapStyleOsm => 'Classic OSM';

  @override
  String get mapStyleSatellite => 'Satellite';

  @override
  String get mapStyleTopographic => 'Topographic';

  @override
  String get mapStyleExplorer => 'Explorer';

  @override
  String get mapStyleSepia => 'Amber';

  @override
  String get mapStyleBright => 'Vivid';

  @override
  String get mapStyleLiberty => 'Detailed';

  @override
  String get mapStyleGame => 'Game';

  @override
  String get mapStyleCorsair => 'Corsair';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsIcon => 'Icon';

  @override
  String get settingsColor => 'Color';

  @override
  String get settingsMarkerPreview => 'Your marker on the map';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get languageSystem => 'System default';

  @override
  String get hudMission => 'Mission';

  @override
  String get pinMission => 'Pin as mission';

  @override
  String get unpinMission => 'Unpin mission';

  @override
  String missionPinnedToast(String name) {
    return '📌 Mission: $name';
  }

  @override
  String get missionUnpinnedToast => 'Mission removed';

  @override
  String get leaderboardTitle => 'Leaderboard';

  @override
  String rankHeadline(int rank) {
    return 'You\'re #$rank';
  }

  @override
  String globalSubtitle(int score) {
    return 'Your score: $score pts';
  }

  @override
  String collectionSubtitle(int discovered, int total) {
    return 'You\'ve discovered $discovered of $total';
  }

  @override
  String get unitPts => 'pts';

  @override
  String get unitPois => 'POIs';

  @override
  String youSuffix(String name) {
    return '$name (you)';
  }

  @override
  String get citiesTitle => 'Cities';

  @override
  String citiesStats(int cells, int discovered, int total) {
    return '$cells cells · $discovered/$total POIs';
  }

  @override
  String get collectionsTitle => 'Collections';

  @override
  String get collectionLeaderboardTooltip => 'This collection\'s leaderboard';

  @override
  String collectionProgress(int discovered, int total) {
    return '$discovered / $total discovered';
  }

  @override
  String get collectionCompleted => 'Collection completed! 🎉';

  @override
  String pointsBadge(int points) {
    return '$points pts';
  }

  @override
  String get poiHiddenName => '?????';

  @override
  String poiPointsEarned(int points) {
    return '+$points points';
  }

  @override
  String poiToDiscover(int points) {
    return 'To discover · $points pts';
  }

  @override
  String get poiSheetInCollections => 'In these collections';

  @override
  String get poiSheetNoCollections => 'Not part of any collection yet.';

  @override
  String get poiSheetOpenInMaps => 'Open in Google Maps';

  @override
  String get poiSheetUndiscoveredTitle => 'Yet to discover';

  @override
  String get poiSheetUndiscoveredHint =>
      'Get close to this spot to reveal what\'s hidden here. Adventure awaits! 🧭';

  @override
  String get poiSheetMapsError => 'Couldn\'t open Google Maps.';

  @override
  String get collGaudiName => 'Gaudí Route';

  @override
  String get collGaudiDesc =>
      'Antoni Gaudí\'s modernist work across Barcelona.';

  @override
  String get collEssentialName => 'Barcelona Essentials';

  @override
  String get collEssentialDesc => 'The must-see places in the city.';

  @override
  String get collOtakuName => 'Otaku BCN (example)';

  @override
  String get collOtakuDesc => 'Temples of comics, manga and geek culture.';

  @override
  String get collMuseumsName => 'Barcelona Museums';

  @override
  String get collMuseumsDesc => 'The city\'s great museums.';

  @override
  String get collTapasName => 'Tapas Trail';

  @override
  String get collTapasDesc => 'Barcelona\'s classic tapas bars.';

  @override
  String get collMichelinName => 'Michelin Stars';

  @override
  String get collMichelinDesc => 'Barcelona\'s starred fine dining.';

  @override
  String get achievementsTitle => 'Achievements';

  @override
  String achievementsUnlocked(int unlocked, int total) {
    return '$unlocked of $total unlocked';
  }

  @override
  String get achievementFamilyDone => 'All levels complete! 🏅';

  @override
  String achievementUnlockedToast(String name) {
    return 'Achievement unlocked: $name';
  }

  @override
  String get achTierBronze => 'Bronze';

  @override
  String get achTierSilver => 'Silver';

  @override
  String get achTierGold => 'Gold';

  @override
  String get achExplorerName => 'Explorer';

  @override
  String achExplorerGoal(int count) {
    return 'Uncover $count fog cells';
  }

  @override
  String get achTreasureName => 'Treasure Hunter';

  @override
  String achTreasureGoal(int count) {
    return 'Discover $count POIs';
  }

  @override
  String get achCartographerName => 'Cartographer';

  @override
  String achCartographerGoal(int count) {
    return 'Reveal $count% of Barcelona';
  }

  @override
  String get achLookoutName => 'Lookout';

  @override
  String achLookoutGoal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count watchtowers',
      one: '1 watchtower',
    );
    return 'Activate $_temp0';
  }

  @override
  String get achCollectorName => 'Collector';

  @override
  String achCollectorGoal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count collections',
      one: '1 collection',
    );
    return 'Complete $_temp0';
  }

  @override
  String get achExplorerTagline => 'Uncover the fog as you go';

  @override
  String get achTreasureTagline => 'Visit points of interest';

  @override
  String get achCartographerTagline => 'Map out Barcelona';

  @override
  String get achLookoutTagline => 'Activate the watchtowers';

  @override
  String get achCollectorTagline => 'Complete collections';

  @override
  String get avatarTitle => 'Your character';

  @override
  String get avatarRotateHint => 'Drag to rotate · pinch to zoom';
}
