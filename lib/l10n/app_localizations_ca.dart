// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Catalan Valencian (`ca`).
class AppLocalizationsCa extends AppLocalizations {
  AppLocalizationsCa([String locale = 'ca']) : super(locale);

  @override
  String get appTitle => 'Fog of War';

  @override
  String get hudCells => 'cel·les';

  @override
  String get hudPoints => 'punts';

  @override
  String get hudPois => 'POIs';

  @override
  String get tooltipMapStyle => 'Canviar estil de mapa';

  @override
  String get tooltipGpsMode => 'Canviar mode de GPS (precisió / bateria)';

  @override
  String get tooltipSettings => 'Configuració i personalització';

  @override
  String get tooltipRanking => 'Classificació';

  @override
  String get tooltipCollections => 'Col·lecció de POIs';

  @override
  String get tooltipRecenter => 'Centrar en mi';

  @override
  String get gpsModeExploration => 'Exploració (alta precisió)';

  @override
  String get gpsModeBattery => 'Estalvi de bateria';

  @override
  String gpsStatus(String mode) {
    return 'GPS: $mode';
  }

  @override
  String mapStatus(String name) {
    return 'Mapa: $name';
  }

  @override
  String get noLocationYet => 'Encara no tinc la teva ubicació.';

  @override
  String get permGrantedWhileInUse =>
      'Per registrar amb l\'app tancada, posa \"Permetre sempre\" a la configuració d\'ubicació.';

  @override
  String get permServiceDisabled =>
      'La ubicació del dispositiu està apagada. Activa-la per jugar.';

  @override
  String get permDeniedForever =>
      'Permís d\'ubicació denegat. Activa\'l a la configuració de l\'app.';

  @override
  String get permDenied =>
      'Sense permís d\'ubicació: la boira no es desvelarà en moure\'t.';

  @override
  String poiDiscoveredSingle(String name, int points) {
    return '🏛️ Has descobert $name!  +$points punts';
  }

  @override
  String poiDiscoveredMultiple(int count, int points) {
    return '🏛️ $count POIs descoberts!  +$points punts';
  }

  @override
  String get mapStyleVoyager => 'Voyager';

  @override
  String get mapStyleLight => 'Clar';

  @override
  String get mapStyleDark => 'Fosc';

  @override
  String get mapStyleOsm => 'OSM clàssic';

  @override
  String get mapStyleSatellite => 'Satèl·lit';

  @override
  String get mapStyleTopographic => 'Topogràfic';

  @override
  String get settingsTitle => 'Configuració';

  @override
  String get settingsIcon => 'Icona';

  @override
  String get settingsColor => 'Color';

  @override
  String get settingsMarkerPreview => 'El teu marcador al mapa';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get languageSystem => 'Idioma del sistema';

  @override
  String get hudMission => 'Missió';

  @override
  String get pinMission => 'Fixar com a missió';

  @override
  String get unpinMission => 'Treure la missió';

  @override
  String missionPinnedToast(String name) {
    return '📌 Missió: $name';
  }

  @override
  String get missionUnpinnedToast => 'Missió treta';

  @override
  String get leaderboardTitle => 'Classificació';

  @override
  String rankHeadline(int rank) {
    return 'Vas el núm. $rank';
  }

  @override
  String globalSubtitle(int score) {
    return 'La teva puntuació: $score pts';
  }

  @override
  String collectionSubtitle(int discovered, int total) {
    return 'Has descobert $discovered de $total';
  }

  @override
  String get unitPts => 'pts';

  @override
  String get unitPois => 'POIs';

  @override
  String youSuffix(String name) {
    return '$name (tu)';
  }

  @override
  String get collectionsTitle => 'Col·leccions';

  @override
  String get collectionLeaderboardTooltip =>
      'Classificació d\'aquesta col·lecció';

  @override
  String collectionProgress(int discovered, int total) {
    return '$discovered / $total descoberts';
  }

  @override
  String get collectionCompleted => 'Col·lecció completada! 🎉';

  @override
  String pointsBadge(int points) {
    return '$points pts';
  }

  @override
  String get poiHiddenName => '?????';

  @override
  String poiPointsEarned(int points) {
    return '+$points punts';
  }

  @override
  String poiToDiscover(int points) {
    return 'Per descobrir · $points pts';
  }

  @override
  String get collGaudiName => 'Ruta Gaudí';

  @override
  String get collGaudiDesc =>
      'L\'obra modernista d\'Antoni Gaudí per Barcelona.';

  @override
  String get collEssentialName => 'Imprescindibles de Barcelona';

  @override
  String get collEssentialDesc =>
      'Els llocs que no et pots perdre a la ciutat.';

  @override
  String get collOtakuName => 'Otaku BCN (exemple)';

  @override
  String get collOtakuDesc => 'Temples del còmic, el manga i la cultura geek.';

  @override
  String get collMuseumsName => 'Museus de Barcelona';

  @override
  String get collMuseumsDesc => 'Els grans museus de la ciutat.';

  @override
  String get collTapasName => 'Ruta de Tapes';

  @override
  String get collTapasDesc => 'Bars de tapes amb solera de Barcelona.';

  @override
  String get collMichelinName => 'Estrelles Michelin';

  @override
  String get collMichelinDesc => 'Alta cuina amb estrella a Barcelona.';
}
