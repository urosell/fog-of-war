// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Fog of War';

  @override
  String get onboardingSkip => 'Saltar';

  @override
  String get onboardingNext => 'Siguiente';

  @override
  String get onboardingStart => '¡A explorar!';

  @override
  String get onboardingWelcomeTitle => 'Tu ciudad, bajo la niebla';

  @override
  String get onboardingWelcomeBody =>
      'Todo el mapa empieza cubierto de niebla. Explora la ciudad de verdad para irla desvelando poco a poco y convertirla en tu propia aventura.';

  @override
  String get onboardingMoveTitle => 'Muévete para desvelar';

  @override
  String get onboardingMoveBody =>
      'La niebla solo se levanta cuando caminas en la vida real. Tu GPS desvela la zona a tu alrededor: ¡no vale hacer trampas desde el sofá!';

  @override
  String get onboardingDiscoverTitle => 'Descubre lugares';

  @override
  String get onboardingDiscoverBody =>
      'Llega a los puntos de interés para descubrirlos y ganar puntos. Cada uno te cuenta qué es y por qué merece una visita.';

  @override
  String get onboardingCollectTitle => 'Atalayas y colecciones';

  @override
  String get onboardingCollectBody =>
      'Sube a las atalayas para avistar los lugares cercanos y completa colecciones temáticas mientras recorres la ciudad.';

  @override
  String get hudCells => 'celdas';

  @override
  String get hudPoints => 'puntos';

  @override
  String get hudPois => 'POIs';

  @override
  String get tooltipMapStyle => 'Cambiar estilo de mapa';

  @override
  String get tooltipGpsMode => 'Cambiar modo de GPS (precisión / batería)';

  @override
  String get tooltipSettings => 'Ajustes y personalización';

  @override
  String get tooltipRanking => 'Clasificación';

  @override
  String get tooltipCollections => 'Colección de POIs';

  @override
  String get tooltipRecenter => 'Centrar en mí';

  @override
  String get gpsModeExploration => 'Exploración (alta precisión)';

  @override
  String get gpsModeBattery => 'Ahorro de batería';

  @override
  String gpsStatus(String mode) {
    return 'GPS: $mode';
  }

  @override
  String mapStatus(String name) {
    return 'Mapa: $name';
  }

  @override
  String get noLocationYet => 'Aún no tengo tu ubicación.';

  @override
  String get permGrantedWhileInUse =>
      'Para registrar con la app cerrada, pon \"Permitir todo el tiempo\" en Ajustes de ubicación.';

  @override
  String get permServiceDisabled =>
      'La ubicación del dispositivo está apagada. Actívala para jugar.';

  @override
  String get permDeniedForever =>
      'Permiso de ubicación denegado. Actívalo en Ajustes de la app.';

  @override
  String get permDenied =>
      'Sin permiso de ubicación: la niebla no se desvelará al moverte.';

  @override
  String poiDiscoveredSingle(String name, int points) {
    return '🏛️ ¡Descubriste $name!  +$points puntos';
  }

  @override
  String poiDiscoveredMultiple(int count, int points) {
    return '🏛️ ¡$count POIs descubiertos!  +$points puntos';
  }

  @override
  String watchtowerSighted(String name, int count) {
    return '🔭 $name: $count puntos avistados';
  }

  @override
  String get notifDiscoveryTitle => '¡Nuevo descubrimiento!';

  @override
  String get mapStyleVoyager => 'Voyager';

  @override
  String get mapStyleLight => 'Claro';

  @override
  String get mapStyleDark => 'Oscuro';

  @override
  String get mapStyleOsm => 'OSM clásico';

  @override
  String get mapStyleSatellite => 'Satélite';

  @override
  String get mapStyleTopographic => 'Topográfico';

  @override
  String get mapStyleExplorer => 'Explorador';

  @override
  String get mapStyleSepia => 'Ámbar';

  @override
  String get mapStyleBright => 'Vivo';

  @override
  String get mapStyleLiberty => 'Detallado';

  @override
  String get mapStyleGame => 'Juego';

  @override
  String get mapStyleCorsair => 'Corsario';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get settingsIcon => 'Icono';

  @override
  String get settingsColor => 'Color';

  @override
  String get settingsMarkerPreview => 'Tu marcador en el mapa';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get languageSystem => 'Idioma del sistema';

  @override
  String get settingsAccount => 'Cuenta';

  @override
  String get accountBenefit =>
      'Guarda tu progreso en la nube y recupéralo en cualquier móvil.';

  @override
  String get accountSignIn => 'Iniciar sesión con Google';

  @override
  String get accountSignOut => 'Cerrar sesión';

  @override
  String get accountSyncing => 'Sincronizando…';

  @override
  String get accountSynced => 'Progreso sincronizado';

  @override
  String get accountSyncError => 'No se pudo sincronizar; se reintentará solo';

  @override
  String get accountSignInFailed => 'No se pudo abrir el inicio de sesión';

  @override
  String get hudMission => 'Misión';

  @override
  String get pinMission => 'Fijar como misión';

  @override
  String get unpinMission => 'Quitar misión';

  @override
  String missionPinnedToast(String name) {
    return '📌 Misión: $name';
  }

  @override
  String get missionUnpinnedToast => 'Misión quitada';

  @override
  String get leaderboardTitle => 'Clasificación';

  @override
  String rankHeadline(int rank) {
    return 'Vas el nº $rank';
  }

  @override
  String globalSubtitle(int score) {
    return 'Tu puntuación: $score pts';
  }

  @override
  String collectionSubtitle(int discovered, int total) {
    return 'Has descubierto $discovered de $total';
  }

  @override
  String get unitPts => 'pts';

  @override
  String get unitPois => 'POIs';

  @override
  String youSuffix(String name) {
    return '$name (tú)';
  }

  @override
  String get citiesTitle => 'Ciudades';

  @override
  String citiesStats(int cells, int discovered, int total) {
    return '$cells celdas · $discovered/$total POIs';
  }

  @override
  String get collectionsTitle => 'Colecciones';

  @override
  String get collectionLeaderboardTooltip => 'Clasificación de esta colección';

  @override
  String collectionProgress(int discovered, int total) {
    return '$discovered / $total descubiertos';
  }

  @override
  String get collectionCompleted => '¡Colección completada! 🎉';

  @override
  String pointsBadge(int points) {
    return '$points pts';
  }

  @override
  String get poiHiddenName => '?????';

  @override
  String poiPointsEarned(int points) {
    return '+$points puntos';
  }

  @override
  String poiToDiscover(int points) {
    return 'Por descubrir · $points pts';
  }

  @override
  String get poiSheetInCollections => 'En estas colecciones';

  @override
  String get poiSheetNoCollections => 'Todavía no está en ninguna colección.';

  @override
  String get poiSheetOpenInMaps => 'Abrir en Google Maps';

  @override
  String get poiSheetUndiscoveredTitle => 'Pendiente de descubrir';

  @override
  String get poiSheetUndiscoveredHint =>
      'Acércate hasta este punto para descubrir qué se esconde aquí. ¡La aventura te espera! 🧭';

  @override
  String get poiSheetMapsError => 'No se pudo abrir Google Maps.';

  @override
  String poiSheetDistanceAway(String distance) {
    return 'A $distance de ti';
  }

  @override
  String get poiSheetStatRating => 'valoración';

  @override
  String get poiSheetStatVisit => 'visita';

  @override
  String get poiSheetStatExplored => 'exploraron';

  @override
  String get poiSheetAppearsIn => 'Aparece en';

  @override
  String poiSheetProgress(int done, int total) {
    return '$done de $total completados';
  }

  @override
  String poiSheetStops(int count) {
    return '$count paradas';
  }

  @override
  String get poiSheetDirections => 'Cómo llegar';

  @override
  String get collGaudiName => 'Ruta Gaudí';

  @override
  String get collGaudiDesc =>
      'La obra modernista de Antoni Gaudí por Barcelona.';

  @override
  String get collEssentialName => 'Imprescindibles de Barcelona';

  @override
  String get collEssentialDesc =>
      'Los lugares que no te puedes perder en la ciudad.';

  @override
  String get collOtakuName => 'Otaku BCN (ejemplo)';

  @override
  String get collOtakuDesc => 'Templos del cómic, el manga y la cultura geek.';

  @override
  String get collMuseumsName => 'Museos de Barcelona';

  @override
  String get collMuseumsDesc => 'Los grandes museos de la ciudad.';

  @override
  String get collTapasName => 'Ruta de Tapas';

  @override
  String get collTapasDesc => 'Bares de tapas con solera de Barcelona.';

  @override
  String get collMichelinName => 'Estrellas Michelin';

  @override
  String get collMichelinDesc => 'Alta cocina con estrella en Barcelona.';

  @override
  String get achievementsTitle => 'Logros';

  @override
  String achievementsUnlocked(int unlocked, int total) {
    return '$unlocked de $total desbloqueados';
  }

  @override
  String get achievementFamilyDone => '¡Todos los niveles completados! 🏅';

  @override
  String achievementUnlockedToast(String name) {
    return '¡Logro desbloqueado! $name';
  }

  @override
  String get achTierBronze => 'Bronce';

  @override
  String get achTierSilver => 'Plata';

  @override
  String get achTierGold => 'Oro';

  @override
  String get achExplorerName => 'Explorador';

  @override
  String achExplorerGoal(int count) {
    return 'Descubre $count celdas de niebla';
  }

  @override
  String get achTreasureName => 'Cazatesoros';

  @override
  String achTreasureGoal(int count) {
    return 'Visita $count POIs';
  }

  @override
  String get achCartographerName => 'Cartógrafo';

  @override
  String achCartographerGoal(int count) {
    return 'Revela el $count% de Barcelona';
  }

  @override
  String get achLookoutName => 'Vigía';

  @override
  String achLookoutGoal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count atalayas',
      one: '1 atalaya',
    );
    return 'Activa $_temp0';
  }

  @override
  String get achCollectorName => 'Coleccionista';

  @override
  String achCollectorGoal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count colecciones',
      one: '1 colección',
    );
    return 'Completa $_temp0';
  }

  @override
  String get achExplorerTagline => 'Desvela la niebla a tu paso';

  @override
  String get achTreasureTagline => 'Visita puntos de interés';

  @override
  String get achCartographerTagline => 'Cartografía Barcelona';

  @override
  String get achLookoutTagline => 'Activa las atalayas';

  @override
  String get achCollectorTagline => 'Completa colecciones';

  @override
  String get avatarTitle => 'Tu personaje';

  @override
  String get avatarRotateHint => 'Arrastra para girar · pellizca para zoom';
}
