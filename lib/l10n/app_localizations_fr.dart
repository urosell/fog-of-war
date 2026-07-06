// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Fog of War';

  @override
  String get onboardingSkip => 'Passer';

  @override
  String get onboardingNext => 'Suivant';

  @override
  String get onboardingStart => 'À l\'aventure !';

  @override
  String get onboardingWelcomeTitle => 'Ta ville, sous le brouillard';

  @override
  String get onboardingWelcomeBody =>
      'Toute la carte est d\'abord cachée par le brouillard. Explore la vraie ville pour la dévoiler peu à peu et en faire ta propre aventure.';

  @override
  String get onboardingMoveTitle => 'Bouge pour dévoiler';

  @override
  String get onboardingMoveBody =>
      'Le brouillard ne se lève que lorsque tu marches dans la vraie vie. Ton GPS dévoile la zone autour de toi : pas de triche depuis le canapé !';

  @override
  String get onboardingDiscoverTitle => 'Découvre des lieux';

  @override
  String get onboardingDiscoverBody =>
      'Atteins les points d\'intérêt pour les découvrir et gagner des points. Chacun te dit ce que c\'est et pourquoi il vaut le détour.';

  @override
  String get onboardingCollectTitle => 'Tours de guet et collections';

  @override
  String get onboardingCollectBody =>
      'Monte aux tours de guet pour repérer les lieux proches et complète des collections thématiques en parcourant la ville.';

  @override
  String get hudCells => 'cellules';

  @override
  String get hudPoints => 'points';

  @override
  String get hudPois => 'POIs';

  @override
  String get tooltipMapStyle => 'Changer le style de carte';

  @override
  String get tooltipGpsMode => 'Changer le mode GPS (précision / batterie)';

  @override
  String get tooltipSettings => 'Paramètres et personnalisation';

  @override
  String get tooltipRanking => 'Classement';

  @override
  String get tooltipCollections => 'Collection de POIs';

  @override
  String get tooltipRecenter => 'Me centrer';

  @override
  String get gpsModeExploration => 'Exploration (haute précision)';

  @override
  String get gpsModeBattery => 'Économie de batterie';

  @override
  String gpsStatus(String mode) {
    return 'GPS : $mode';
  }

  @override
  String mapStatus(String name) {
    return 'Carte : $name';
  }

  @override
  String get noLocationYet => 'Je n\'ai pas encore votre position.';

  @override
  String get permGrantedWhileInUse =>
      'Pour enregistrer avec l\'app fermée, choisissez « Toujours autoriser » dans les paramètres de localisation.';

  @override
  String get permServiceDisabled =>
      'La localisation de l\'appareil est désactivée. Activez-la pour jouer.';

  @override
  String get permDeniedForever =>
      'Autorisation de localisation refusée. Activez-la dans les paramètres de l\'app.';

  @override
  String get permDenied =>
      'Sans autorisation de localisation : le brouillard ne se dissipera pas en vous déplaçant.';

  @override
  String poiDiscoveredSingle(String name, int points) {
    return '🏛️ Vous avez découvert $name !  +$points points';
  }

  @override
  String poiDiscoveredMultiple(int count, int points) {
    return '🏛️ $count POIs découverts !  +$points points';
  }

  @override
  String watchtowerSighted(String name, int count) {
    return '🔭 $name : $count POI en vue';
  }

  @override
  String get notifDiscoveryTitle => 'Nouvelle découverte !';

  @override
  String get mapStyleVoyager => 'Voyager';

  @override
  String get mapStyleLight => 'Clair';

  @override
  String get mapStyleDark => 'Sombre';

  @override
  String get mapStyleOsm => 'OSM classique';

  @override
  String get mapStyleSatellite => 'Satellite';

  @override
  String get mapStyleTopographic => 'Topographique';

  @override
  String get mapStyleExplorer => 'Explorateur';

  @override
  String get mapStyleSepia => 'Ambre';

  @override
  String get mapStyleBright => 'Vif';

  @override
  String get mapStyleLiberty => 'Détaillé';

  @override
  String get mapStyleGame => 'Jeu';

  @override
  String get mapStyleCorsair => 'Corsaire';

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get settingsIcon => 'Icône';

  @override
  String get settingsColor => 'Couleur';

  @override
  String get settingsMarkerPreview => 'Votre marqueur sur la carte';

  @override
  String get settingsLanguage => 'Langue';

  @override
  String get languageSystem => 'Langue du système';

  @override
  String get hudMission => 'Mission';

  @override
  String get pinMission => 'Épingler comme mission';

  @override
  String get unpinMission => 'Retirer la mission';

  @override
  String missionPinnedToast(String name) {
    return '📌 Mission : $name';
  }

  @override
  String get missionUnpinnedToast => 'Mission retirée';

  @override
  String get leaderboardTitle => 'Classement';

  @override
  String rankHeadline(int rank) {
    return 'Vous êtes nº $rank';
  }

  @override
  String globalSubtitle(int score) {
    return 'Votre score : $score pts';
  }

  @override
  String collectionSubtitle(int discovered, int total) {
    return 'Vous avez découvert $discovered sur $total';
  }

  @override
  String get unitPts => 'pts';

  @override
  String get unitPois => 'POIs';

  @override
  String youSuffix(String name) {
    return '$name (vous)';
  }

  @override
  String get citiesTitle => 'Villes';

  @override
  String citiesStats(int cells, int discovered, int total) {
    return '$cells cellules · $discovered/$total POIs';
  }

  @override
  String get collectionsTitle => 'Collections';

  @override
  String get collectionLeaderboardTooltip => 'Classement de cette collection';

  @override
  String collectionProgress(int discovered, int total) {
    return '$discovered / $total découverts';
  }

  @override
  String get collectionCompleted => 'Collection terminée ! 🎉';

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
    return 'À découvrir · $points pts';
  }

  @override
  String get poiSheetInCollections => 'Dans ces collections';

  @override
  String get poiSheetNoCollections =>
      'Ne fait encore partie d\'aucune collection.';

  @override
  String get poiSheetOpenInMaps => 'Ouvrir dans Google Maps';

  @override
  String get poiSheetUndiscoveredTitle => 'À découvrir';

  @override
  String get poiSheetUndiscoveredHint =>
      'Approche-toi de cet endroit pour révéler ce qui s\'y cache. L\'aventure t\'attend ! 🧭';

  @override
  String get poiSheetMapsError => 'Impossible d\'ouvrir Google Maps.';

  @override
  String get collGaudiName => 'Route Gaudí';

  @override
  String get collGaudiDesc =>
      'L\'œuvre moderniste d\'Antoni Gaudí à travers Barcelone.';

  @override
  String get collEssentialName => 'Incontournables de Barcelone';

  @override
  String get collEssentialDesc => 'Les lieux à ne pas manquer dans la ville.';

  @override
  String get collOtakuName => 'Otaku BCN (exemple)';

  @override
  String get collOtakuDesc =>
      'Temples de la BD, du manga et de la culture geek.';

  @override
  String get collMuseumsName => 'Musées de Barcelone';

  @override
  String get collMuseumsDesc => 'Les grands musées de la ville.';

  @override
  String get collTapasName => 'Route des Tapas';

  @override
  String get collTapasDesc => 'Les bars à tapas typiques de Barcelone.';

  @override
  String get collMichelinName => 'Étoiles Michelin';

  @override
  String get collMichelinDesc => 'La haute gastronomie étoilée de Barcelone.';

  @override
  String get achievementsTitle => 'Succès';

  @override
  String achievementsUnlocked(int unlocked, int total) {
    return '$unlocked sur $total débloqués';
  }

  @override
  String get achievementFamilyDone => 'Tous les niveaux terminés ! 🏅';

  @override
  String achievementUnlockedToast(String name) {
    return 'Succès débloqué : $name';
  }

  @override
  String get achTierBronze => 'Bronze';

  @override
  String get achTierSilver => 'Argent';

  @override
  String get achTierGold => 'Or';

  @override
  String get achExplorerName => 'Explorateur';

  @override
  String achExplorerGoal(int count) {
    return 'Dévoile $count cellules de brouillard';
  }

  @override
  String get achTreasureName => 'Chasseur de trésors';

  @override
  String achTreasureGoal(int count) {
    return 'Découvre $count POI';
  }

  @override
  String get achCartographerName => 'Cartographe';

  @override
  String achCartographerGoal(int count) {
    return 'Révèle $count% de Barcelone';
  }

  @override
  String get achLookoutName => 'Guetteur';

  @override
  String achLookoutGoal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tours de guet',
      one: '1 tour de guet',
    );
    return 'Active $_temp0';
  }

  @override
  String get achCollectorName => 'Collectionneur';

  @override
  String achCollectorGoal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count collections',
      one: '1 collection',
    );
    return 'Complète $_temp0';
  }

  @override
  String get achExplorerTagline => 'Dévoile le brouillard sur ton passage';

  @override
  String get achTreasureTagline => 'Visite des points d\'intérêt';

  @override
  String get achCartographerTagline => 'Cartographie Barcelone';

  @override
  String get achLookoutTagline => 'Active les tours de guet';

  @override
  String get achCollectorTagline => 'Complète des collections';

  @override
  String get avatarTitle => 'Ton personnage';

  @override
  String get avatarRotateHint => 'Glisse pour tourner · pince pour zoomer';
}
