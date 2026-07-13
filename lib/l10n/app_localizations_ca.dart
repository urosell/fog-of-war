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
  String get onboardingSkip => 'Omet';

  @override
  String get onboardingNext => 'Següent';

  @override
  String get onboardingStart => 'A explorar!';

  @override
  String get onboardingWelcomeTitle => 'La teva ciutat, sota la boira';

  @override
  String get onboardingWelcomeBody =>
      'Tot el mapa comença cobert de boira. Explora la ciutat de veritat per anar-la desvelant a poc a poc i convertir-la en la teva pròpia aventura.';

  @override
  String get onboardingMoveTitle => 'Mou-te per desvelar';

  @override
  String get onboardingMoveBody =>
      'La boira només s\'aixeca quan camines a la vida real. El teu GPS desvela la zona del teu voltant: no val fer trampes des del sofà!';

  @override
  String get onboardingDiscoverTitle => 'Descobreix llocs';

  @override
  String get onboardingDiscoverBody =>
      'Arriba als punts d\'interès per descobrir-los i guanyar punts. Cadascun t\'explica què és i per què val la pena visitar-lo.';

  @override
  String get onboardingCollectTitle => 'Talaies i col·leccions';

  @override
  String get onboardingCollectBody =>
      'Puja a les talaies per albirar els llocs propers i completa col·leccions temàtiques mentre recorres la ciutat.';

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
  String watchtowerSighted(String name, int count) {
    return '🔭 $name: $count punts albirats';
  }

  @override
  String get notifDiscoveryTitle => 'Nou descobriment!';

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
  String get mapStyleExplorer => 'Explorador';

  @override
  String get mapStyleSepia => 'Ambre';

  @override
  String get mapStyleBright => 'Viu';

  @override
  String get mapStyleLiberty => 'Detallat';

  @override
  String get mapStyleGame => 'Joc';

  @override
  String get mapStyleCorsair => 'Corsari';

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
  String get settingsAccount => 'Compte';

  @override
  String get accountBenefit =>
      'Desa el teu progrés al núvol i recupera\'l a qualsevol mòbil.';

  @override
  String get accountSignIn => 'Inicia la sessió amb Google';

  @override
  String get accountSignOut => 'Tanca la sessió';

  @override
  String get accountSyncing => 'Sincronitzant…';

  @override
  String get accountSynced => 'Progrés sincronitzat';

  @override
  String get accountSyncError =>
      'No s\'ha pogut sincronitzar; es reintentarà sol';

  @override
  String get accountSignInFailed => 'No s\'ha pogut obrir l\'inici de sessió';

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
  String get citiesTitle => 'Ciutats';

  @override
  String citiesStats(int cells, int discovered, int total) {
    return '$cells cel·les · $discovered/$total POIs';
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
  String get poiSheetInCollections => 'En aquestes col·leccions';

  @override
  String get poiSheetNoCollections => 'Encara no és a cap col·lecció.';

  @override
  String get poiSheetOpenInMaps => 'Obre a Google Maps';

  @override
  String get poiSheetUndiscoveredTitle => 'Pendent de descobrir';

  @override
  String get poiSheetUndiscoveredHint =>
      'Acosta\'t fins aquí per descobrir què s\'amaga en aquest punt. L\'aventura t\'espera! 🧭';

  @override
  String get poiSheetMapsError => 'No s\'ha pogut obrir Google Maps.';

  @override
  String poiSheetDistanceAway(String distance) {
    return 'A $distance de tu';
  }

  @override
  String get poiSheetStatRating => 'valoració';

  @override
  String get poiSheetStatVisit => 'visita';

  @override
  String get poiSheetStatExplored => 'han explorat';

  @override
  String get poiSheetAppearsIn => 'Apareix a';

  @override
  String poiSheetProgress(int done, int total) {
    return '$done de $total completats';
  }

  @override
  String poiSheetStops(int count) {
    return '$count parades';
  }

  @override
  String get poiSheetDirections => 'Com arribar-hi';

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

  @override
  String get achievementsTitle => 'Assoliments';

  @override
  String achievementsUnlocked(int unlocked, int total) {
    return '$unlocked de $total desbloquejats';
  }

  @override
  String get achievementFamilyDone => 'Tots els nivells completats! 🏅';

  @override
  String achievementUnlockedToast(String name) {
    return 'Assoliment desbloquejat! $name';
  }

  @override
  String get achTierBronze => 'Bronze';

  @override
  String get achTierSilver => 'Plata';

  @override
  String get achTierGold => 'Or';

  @override
  String get achExplorerName => 'Explorador';

  @override
  String achExplorerGoal(int count) {
    return 'Descobreix $count cel·les de boira';
  }

  @override
  String get achTreasureName => 'Caçatresors';

  @override
  String achTreasureGoal(int count) {
    return 'Visita $count POIs';
  }

  @override
  String get achCartographerName => 'Cartògraf';

  @override
  String achCartographerGoal(int count) {
    return 'Revela el $count% de Barcelona';
  }

  @override
  String get achLookoutName => 'Vigia';

  @override
  String achLookoutGoal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count talaies',
      one: '1 talaia',
    );
    return 'Activa $_temp0';
  }

  @override
  String get achCollectorName => 'Col·leccionista';

  @override
  String achCollectorGoal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count col·leccions',
      one: '1 col·lecció',
    );
    return 'Completa $_temp0';
  }

  @override
  String get achExplorerTagline => 'Desvela la boira al teu pas';

  @override
  String get achTreasureTagline => 'Visita punts d\'interès';

  @override
  String get achCartographerTagline => 'Cartografia Barcelona';

  @override
  String get achLookoutTagline => 'Activa les talaies';

  @override
  String get achCollectorTagline => 'Completa col·leccions';

  @override
  String get avatarTitle => 'El teu personatge';

  @override
  String get avatarRotateHint => 'Arrossega per girar · pessiga per fer zoom';
}
