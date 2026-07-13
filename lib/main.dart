// Fog of War — mapa con niebla que se desvela al moverte (GPS).
//
// Al arrancar pide permiso de ubicación y, si lo concedes, salta a tu posición
// actual de inmediato y luego escucha tus movimientos: cada vez que te mueves,
// pinta tu posición, centra el mapa en ti y desvela la niebla a tu alrededor.
// La niebla se desvela SOLO con el GPS (moviéndote), nunca tocando el mapa.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';

import 'achievement/achievement.dart';
import 'achievement/achievement_controller.dart';
import 'avatar/avatar.dart';
import 'avatar/avatar_controller.dart';
import 'cities/city.dart';
import 'content/content_controller.dart';
import 'debug/frame_stats.dart';
import 'fog/fog_controller.dart';
import 'fog/fog_layer.dart';
import 'l10n/app_localizations.dart';
import 'l10n/content_l10n.dart';
import 'l10n/l10n_ext.dart';
import 'locale/locale_controller.dart';
import 'location/location_service.dart';
import 'map/game_style.dart';
import 'map/map_style.dart';
import 'mission/mission_controller.dart';
import 'notify/notification_service.dart';
import 'onboarding/onboarding_storage.dart';
import 'poi/poi.dart';
import 'poi/poi_collection.dart';
import 'poi/poi_controller.dart';
import 'ui/achievements_screen.dart';
// Avatar 3D desactivado temporalmente (no convence el look). Para reactivarlo:
// descomentar este import, el método _abrirAvatar y su botón en la UI.
// import 'ui/avatar_screen.dart';
import 'ui/cities_screen.dart';
import 'ui/hud.dart';
import 'ui/leaderboard_screen.dart';
import 'ui/onboarding_screen.dart';
import 'ui/poi_collection_screen.dart' show iconForCategory, PoiCollectionScreen;
import 'ui/poi_collections_screen.dart';
import 'ui/poi_detail_sheet.dart';
import 'ui/settings_screen.dart';
import 'ui/toast.dart';
import 'ui/transitions.dart';
import 'watchtower/watchtower.dart';
import 'watchtower/watchtower_controller.dart';

void main() {
  // Solo para capturas/depuración manual (tool/perf): arrancar directamente
  // en un estilo concreto, p. ej. --dart-define=MAP_PERF_STYLE=12. En el
  // binario normal no se define y queda en el estilo por defecto.
  const styleOverride = int.fromEnvironment('MAP_PERF_STYLE', defaultValue: -1);
  runApp(FogOfWarApp(
    initialStyleIndex: styleOverride >= 0 ? styleOverride : null,
  ));
}

class FogOfWarApp extends StatefulWidget {
  // Ganchos SOLO para tests (integration_test/map_perf_test.dart): inyectar el
  // controlador de cámara, arrancar en un estilo concreto y saltarse la intro.
  // En el arranque normal (main) van todos por defecto y no cambian nada.
  final MapController? mapController;
  final int? initialStyleIndex;
  final bool skipOnboarding;

  const FogOfWarApp({
    super.key,
    this.mapController,
    this.initialStyleIndex,
    this.skipOnboarding = false,
  });

  @override
  State<FogOfWarApp> createState() => _FogOfWarAppState();
}

class _FogOfWarAppState extends State<FogOfWarApp> {
  // Idioma de la app (o null = el del sistema). Se carga del disco al arrancar.
  final LocaleController _locale = LocaleController();

  @override
  void initState() {
    super.initState();
    _locale.load();
  }

  @override
  void dispose() {
    _locale.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Al cambiar el idioma, se reconstruye toda la app.
    return ListenableBuilder(
      listenable: _locale,
      builder: (context, _) => MaterialApp(
        title: 'Fog of War',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        ),
        locale: _locale.locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MapScreen(
          localeController: _locale,
          mapController: widget.mapController,
          initialStyleIndex: widget.initialStyleIndex,
          skipOnboarding: widget.skipOnboarding,
        ),
      ),
    );
  }
}

class MapScreen extends StatefulWidget {
  final LocaleController localeController;

  // Ganchos de test; ver FogOfWarApp.
  final MapController? mapController;
  final int? initialStyleIndex;
  final bool skipOnboarding;

  const MapScreen({
    super.key,
    required this.localeController,
    this.mapController,
    this.initialStyleIndex,
    this.skipOnboarding = false,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with WidgetsBindingObserver {
  // Centro inicial del mapa mientras aún no tenemos posición GPS: Barcelona.
  static const LatLng _centroInicial = LatLng(41.3874, 2.1686);

  // Caja a la que se limita la cámara: el término municipal de Barcelona (y
  // alrededores). De momento solo Barcelona es jugable, así que encerramos el
  // mapa aquí para que no se pueda desplazar/alejar a zonas sin contenido (y de
  // paso evitar que flutter_map cargue tiles de medio mundo y se congele).
  static final LatLngBounds _limiteBarcelona = LatLngBounds(
    LatLng(kBarcelona.south, kBarcelona.west),
    LatLng(kBarcelona.north, kBarcelona.east),
  );

  // Controla el estado del fog (celdas descubiertas).
  final FogController _fog = FogController();
  // Controla el estado de los POIs (descubiertos y puntos).
  final PoiController _poi = PoiController();
  // Personalización del marcador del jugador (icono y color).
  final AvatarController _avatar = AvatarController();
  // Misión activa (colección fijada) que rige el indicador de POIs del HUD.
  final MissionController _mission = MissionController();
  // Atalayas: al alcanzarlas, avistan (revelan en gris) los POIs de su zona.
  final WatchtowerController _watchtower = WatchtowerController();
  // Logros: medallas que se desbloquean al alcanzar hitos (celdas, POIs, etc.).
  final AchievementController _achievements = AchievementController();
  // Contenido del juego (POIs y colecciones): semilla embebida o, si está
  // configurada la hoja, lo descargado de ella (ver content/).
  final ContentController _content = ContentController();
  // Permite mover/leer la cámara del mapa (para centrar en el usuario). El
  // test de rendimiento inyecta el suyo para guiar la cámara desde fuera.
  late final MapController _mapController =
      widget.mapController ?? MapController();
  // Acceso al GPS.
  final LocationService _location = LocationService();
  // Recuerda si ya se mostró la introducción de bienvenida.
  final OnboardingStorage _onboarding = OnboardingStorage();

  // Suscripción al flujo de posiciones; se cancela al cerrar la pantalla.
  StreamSubscription<LatLng>? _posSub;
  // Última posición conocida del usuario (null hasta la primera lectura). Es un
  // ValueNotifier para que actualizar la posición en cada lectura del GPS solo
  // redibuje el marcador del jugador, no todo el árbol del mapa (rendimiento).
  final ValueNotifier<LatLng?> _userPosition = ValueNotifier<LatLng?>(null);
  // Si está activo, el mapa sigue automáticamente al usuario al moverse.
  bool _seguir = true;
  // Índice del estilo de mapa actual dentro de kMapStyles.
  int _styleIndex = kDefaultStyleIndex;
  // Estilos vectoriales ya cargados (clave = styleUri). Cargar un style JSON es
  // asíncrono, así que lo cacheamos para no re-descargarlo al alternar estilos.
  final Map<String, Style> _estilosVectoriales = {};
  // Modo de seguimiento del GPS (precisión vs batería).
  TrackingMode _modo = TrackingMode.exploracion;
  // ¿La app está en primer plano (visible)? Si no, los descubrimientos se
  // avisan con una notificación del sistema en vez del toast (que no se vería).
  bool _enPrimerPlano = true;
  // Contador para dar ids distintos a las notificaciones (no se pisan).
  int _notifId = 0;
  // Modo admin: pinta TODOS los POIs en el mapa (coloreados por categoría) para
  // ver su distribución por la ciudad. Es SOLO visual: no los marca como
  // descubiertos ni afecta a puntos/logros. Al desactivarlo, todo vuelve a la
  // vista normal (descubiertos/avistados).
  bool _adminMostrarTodos = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Estilo inicial: el del gancho de test si lo hay; si no, el por defecto.
    _styleIndex = widget.initialStyleIndex ?? kDefaultStyleIndex;
    _fog.load();
    _avatar.load();
    // Preparar las notificaciones locales (el permiso se pide tras el de GPS).
    NotificationService.instance.init();
    // Si el estilo inicial es vectorial, empezar a cargar su style JSON ya.
    _asegurarEstiloVectorial(kActiveMapStyles[_styleIndex]);
    // Cargar el contenido (POIs/colecciones) y, con él listo, arrancar el resto.
    _inicializar();
  }

  // Carga el contenido (caché/semilla, al instante), lo aplica a los
  // controladores, restaura su estado guardado (descubiertos/atalayas/misión),
  // arranca el GPS y deja la hoja descargándose para el PRÓXIMO arranque.
  Future<void> _inicializar() async {
    await _content.loadInitial();
    if (!mounted) return;
    _aplicarContenido();
    await Future.wait([
      _poi.load(),
      _watchtower.load(),
      _mission.load(),
      _achievements.load(),
    ]);
    if (!mounted) return;
    // Evaluación inicial SILENCIOSA: desbloquea retroactivamente los logros ya
    // merecidos por la partida guardada (sin lanzar una ráfaga de toasts) y deja
    // la "foto" de métricas al día para la pantalla de Logros.
    _evaluarLogros(celebrar: false);
    // La primera vez, mostrar la intro ("¿de qué va el juego?") ANTES de pedir
    // el GPS, para que se entienda por qué el juego necesita la ubicación.
    await _mostrarIntroSiPrimeraVez();
    if (!mounted) return;
    _iniciarGps();
    _content.refreshForNextLaunch();
  }

  // Si el usuario no ha visto nunca la introducción, la muestra a pantalla
  // completa y espera a que la cierre; luego la marca como vista.
  Future<void> _mostrarIntroSiPrimeraVez() async {
    // El test de rendimiento la salta (arranca con datos limpios cada vez).
    if (widget.skipOnboarding) return;
    if (await _onboarding.hasSeen() || !mounted) return;
    await Navigator.of(context).push(appRoute(const OnboardingScreen()));
    await _onboarding.markSeen();
  }

  // Vuelca el contenido cargado en los controladores que dependen de él.
  void _aplicarContenido() {
    _poi.setPois(_content.pois);
    _watchtower.setPois(_content.pois);
    _mission.setCollections(_content.collections);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _posSub?.cancel();
    _userPosition.dispose();
    _fog.dispose();
    _poi.dispose();
    _avatar.dispose();
    _mission.dispose();
    _watchtower.dispose();
    _achievements.dispose();
    _content.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Solo "resumed" cuenta como visible; pausada/oculta/inactiva = minimizada.
    _enPrimerPlano = state == AppLifecycleState.resumed;
    // Al minimizar, volcar a disco la niebla pendiente de guardar (debounce):
    // si Android mata el proceso en segundo plano, no se pierde lo último.
    if (state == AppLifecycleState.paused) {
      _fog.flush();
    }
  }

  // Pide permiso y, si se concede, empieza a escuchar la posición.
  Future<void> _iniciarGps() async {
    final resultado = await _location.ensurePermission();
    if (!mounted) return;

    final concedido = resultado == LocationPermissionResult.grantedAlways ||
        resultado == LocationPermissionResult.grantedWhileInUse;
    if (!concedido) {
      _mostrarAviso(_mensajePermiso(resultado));
      return;
    }

    // Con "Mientras usas la app" el GPS funciona, pero el segundo plano puede
    // no ser fiable: avisamos para que el usuario suba el permiso a Ajustes.
    if (resultado == LocationPermissionResult.grantedWhileInUse) {
      _mostrarAviso(context.l10n.permGrantedWhileInUse);
    }

    // Pedir el permiso de notificaciones (para avisar de descubrimientos con la
    // app minimizada). Va después del de ubicación para no apilar dos diálogos.
    await NotificationService.instance.requestPermission();

    // Salto inmediato a tu posición actual (en paralelo a abrir el stream): así
    // el mapa no se queda en el centro de la ciudad esperando la primera lectura
    // del flujo, que con el filtro de distancia puede tardar si no te mueves.
    _irAPosicionInicial();
    _suscribirGps();
  }

  // Pide una sola lectura de GPS y la aplica como si fuera la primera posición
  // del flujo (centra, desvela y comprueba POIs). Si el flujo se adelanta y ya
  // hay posición, no hace nada. Si no hay fix disponible, falla en silencio.
  Future<void> _irAPosicionInicial() async {
    try {
      final pos = await _location.currentPosition();
      if (!mounted || _userPosition.value != null) return;
      _onNuevaPosicion(pos);
    } catch (_) {
      // Sin fix inicial: seguimos esperando al flujo, sin molestar al usuario.
    }
  }

  // (Re)suscribe al flujo de posiciones con el modo actual. Cancela la
  // suscripción anterior si la había (p. ej. al cambiar de modo).
  void _suscribirGps() {
    _posSub?.cancel();
    _posSub = _location.positionStream(mode: _modo).listen(_onNuevaPosicion);
  }

  // Alterna entre modo Exploración y Ahorro, y reinicia el GPS con los nuevos
  // ajustes (solo si el seguimiento ya estaba activo).
  void _cambiarModo() {
    setState(() {
      _modo = _modo == TrackingMode.exploracion
          ? TrackingMode.ahorro
          : TrackingMode.exploracion;
    });
    if (_posSub != null) _suscribirGps();
    final l = context.l10n;
    final nombre = _modo == TrackingMode.exploracion
        ? l.gpsModeExploration
        : l.gpsModeBattery;
    _mostrarAviso(l.gpsStatus(nombre));
  }

  // Se ejecuta cada vez que el GPS nos da una posición nueva.
  void _onNuevaPosicion(LatLng pos) {
    // Solo actualiza el ValueNotifier: redibuja el marcador del jugador (vía su
    // ValueListenableBuilder), no todo el árbol. El resto reacciona por su
    // cuenta: la niebla y el HUD a sus controllers, el mapa al move() de abajo.
    _userPosition.value = pos;
    // Desvelar la niebla a tu alrededor.
    _fog.reveal(pos);
    // ¿Has llegado a algún POI nuevo? Si es así, celébralo.
    final nuevos = _poi.checkDiscoveries(pos);
    if (nuevos.isNotEmpty) _celebrarPois(nuevos);
    // ¿Has alcanzado alguna atalaya? Si es así, avista (revela) su zona.
    final atalayas = _watchtower.checkActivations(pos);
    if (atalayas.isNotEmpty) _avisarAtalayas(atalayas);
    // ¿Esta jugada ha desbloqueado algún logro? Comprobarlo y celebrarlo.
    _evaluarLogros(celebrar: true);
    // Si el modo "seguir" está activo, centrar el mapa en ti.
    if (_seguir) {
      _mapController.move(pos, _mapController.camera.zoom);
    }
  }

  // Muestra un aviso al descubrir uno o varios POIs. Con la app abierta usa el
  // toast de cristal; minimizada, una notificación del sistema (el toast no se
  // vería).
  void _celebrarPois(List<Poi> nuevos) {
    final l = context.l10n;
    final String texto;
    final IconData icono;
    if (nuevos.length == 1) {
      final p = nuevos.first;
      texto = l.poiDiscoveredSingle(p.name, p.points);
      icono = iconForCategory(p.category);
    } else {
      final puntos = nuevos.fold<int>(0, (s, p) => s + p.points);
      texto = l.poiDiscoveredMultiple(nuevos.length, puntos);
      icono = Icons.celebration_rounded;
    }
    if (_enPrimerPlano) {
      // Ámbar: el color de los POIs descubiertos (el "tesoro").
      showGameToast(context,
          icon: icono, accent: const Color(0xFFFFB300), message: texto);
    } else {
      NotificationService.instance.showDiscovery(
        id: _notifId++,
        title: l.notifDiscoveryTitle,
        body: texto,
      );
    }
  }

  // Anuncia que has activado una atalaya y cuántos POIs ha avistado en su zona.
  void _avisarAtalayas(List<Watchtower> nuevas) {
    final l = context.l10n;
    // Si activas varias a la vez (raro), anunciamos la primera.
    final t = nuevas.first;
    final count = _watchtower.sightedCountFor(t);
    // Turquesa: el color de "avistar" (atalaya activada).
    showGameToast(context,
        icon: Icons.visibility,
        accent: const Color(0xFF1FB8C4),
        message: l.watchtowerSighted(t.name, count));
  }

  // Recoge las métricas actuales del juego y se las pasa al controlador de
  // logros. Si [celebrar] es true, anuncia los recién desbloqueados con un toast
  // (o notificación si la app está en segundo plano).
  void _evaluarLogros({required bool celebrar}) {
    final nuevos = _achievements.evaluate(
      cells: _fog.discoveredCount,
      pois: _poi.discoveredCount,
      // Contador incremental por ciudad: O(1) en cada tick de GPS, en vez de
      // recorrer todas las celdas descubiertas.
      cityPercent: kBarcelona
          .percentageFromCount(_fog.discoveredCountInCity(kBarcelona.id))
          .floor(),
      watchtowers: _watchtower.activatedCount,
      collectionsComplete: _coleccionesCompletas(),
    );
    if (celebrar && nuevos.isNotEmpty) _celebrarLogros(nuevos);
  }

  // Cuántas colecciones están completas (todos sus POIs descubiertos). Las
  // colecciones vacías no cuentan.
  int _coleccionesCompletas() {
    var n = 0;
    for (final c in _content.collections) {
      if (c.poiIds.isNotEmpty &&
          c.discoveredCount(_poi.isDiscoveredId) == c.poiIds.length) {
        n++;
      }
    }
    return n;
  }

  // Celebra los logros recién desbloqueados. Anuncia uno a uno (lo normal es uno
  // por jugada); con la app abierta usa el toast de cristal, minimizada una
  // notificación del sistema. El acento es el color del nivel de la medalla.
  void _celebrarLogros(List<Achievement> nuevos) {
    final l = context.l10n;
    for (final a in nuevos) {
      final nombre = '${achievementFamilyName(l, a.metric)} · '
          '${medalLabel(a.metric, a.threshold)}';
      final texto = l.achievementUnlockedToast(nombre);
      if (_enPrimerPlano) {
        showGameToast(context,
            icon: iconForMetric(a.metric),
            accent: colorForAchievement(a),
            message: texto);
      } else {
        NotificationService.instance.showDiscovery(
          id: _notifId++,
          title: l.achievementsTitle,
          body: texto,
        );
      }
    }
  }

  // Mensaje legible según por qué no tenemos permiso/GPS.
  String _mensajePermiso(LocationPermissionResult r) {
    final l = context.l10n;
    switch (r) {
      case LocationPermissionResult.serviceDisabled:
        return l.permServiceDisabled;
      case LocationPermissionResult.deniedForever:
        return l.permDeniedForever;
      case LocationPermissionResult.denied:
        return l.permDenied;
      case LocationPermissionResult.grantedWhileInUse:
      case LocationPermissionResult.grantedAlways:
        return '';
    }
  }

  void _mostrarAviso(String texto) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(texto)));
  }

  // Pasa al siguiente estilo de mapa (vuelve al primero tras el último) y
  // avisa con el nombre del estilo elegido.
  void _siguienteEstilo() {
    final siguiente = (_styleIndex + 1) % kActiveMapStyles.length;
    setState(() => _styleIndex = siguiente);
    final estilo = kActiveMapStyles[siguiente];
    // Si es vectorial, asegurarse de que su style JSON esté cargado.
    _asegurarEstiloVectorial(estilo);
    // Quitar avisos en cola para que, al pulsar rápido, se vea siempre el
    // nombre del estilo actual y no los anteriores encolados.
    ScaffoldMessenger.of(context).clearSnackBars();
    final nombre =
        localizedMapStyleName(context.l10n, estilo.nameKey, estilo.name);
    _mostrarAviso(context.l10n.mapStatus(nombre));
  }

  // Carga (una sola vez) el style JSON de un estilo vectorial y lo cachea. Los
  // estilos "custom" usan nuestra skin propia (game_style.dart); el resto, tal
  // cual lo sirve el proveedor. Si falla la descarga, cae al primer estilo
  // raster para no dejar el mapa en gris. No hace nada para estilos raster o ya
  // cargados.
  Future<void> _asegurarEstiloVectorial(MapStyle estilo) async {
    final uri = estilo.styleUri;
    if (uri == null || _estilosVectoriales.containsKey(estilo.cacheKey)) return;
    try {
      // Cada skin propia tiene su loader; sin skin, el estilo del proveedor.
      // Las skins 'exp_*' son variantes de medición (solo binario de perf).
      final cargado = switch (estilo.customSkin) {
        'game' => await loadGameStyle(),
        'corsair' => await loadCorsairStyle(),
        final skin? => await loadExperimentStyle(skin),
        _ => await StyleReader(uri: uri).read(),
      };
      if (!mounted) return;
      setState(() => _estilosVectoriales[estilo.cacheKey] = cargado);
    } catch (_) {
      if (!mounted) return;
      // Sin red o estilo no disponible: caer a un mapa raster de respaldo.
      setState(() => _styleIndex = kRasterFallbackIndex);
      final raster = kActiveMapStyles[kRasterFallbackIndex];
      ScaffoldMessenger.of(context).clearSnackBars();
      _mostrarAviso(context.l10n.mapStatus(
          localizedMapStyleName(context.l10n, raster.nameKey, raster.name)));
    }
  }

  // Abre el hub de colecciones de POIs. Si al cerrarlo el usuario tocó un POI
  // descubierto, centramos el mapa en él (y desactivamos el auto-seguir).
  Future<void> _abrirColeccion() async {
    final elegido = await Navigator.of(context).push<Poi>(
      appRoute(
        PoiCollectionsScreen(
          poiController: _poi,
          mission: _mission,
          collections: _content.collections,
        ),
        opaque: false,
      ),
    );
    if (elegido == null || !mounted) return;
    setState(() => _seguir = false);
    _mapController.move(elegido.location, 17);
  }

  // Abre directamente el detalle de la misión fijada (al tocar el HUD). Si
  // dentro tocas un POI descubierto, centra el mapa en él.
  Future<void> _abrirMisionSeleccionada() async {
    final mision = _mission.selected;
    if (mision == null) return;
    final elegido = await Navigator.of(context).push<Poi>(
      appRoute(PoiCollectionScreen(
        poiController: _poi,
        collection: mision,
        mission: _mission,
      )),
    );
    if (elegido == null || !mounted) return;
    setState(() => _seguir = false);
    _mapController.move(elegido.location, 17);
  }

  // Quita la misión fijada (pulsación larga sobre el HUD) y lo avisa.
  void _quitarMision() {
    _mission.setMission(null);
    ScaffoldMessenger.of(context).clearSnackBars();
    _mostrarAviso(context.l10n.missionUnpinnedToast);
  }

  // Abre la lista de ciudades (al tocar el nombre de la ciudad en el HUD). Si al
  // cerrarla el usuario eligió una ciudad, centramos el mapa en ella.
  Future<void> _abrirCiudades() async {
    final elegida = await Navigator.of(context).push<City>(
      appRoute(
        CitiesScreen(
          fogController: _fog,
          poiController: _poi,
          activeCityId: kBarcelona.id,
        ),
        opaque: false,
      ),
    );
    if (elegida == null || !mounted) return;
    // La cámara está encerrada en Barcelona: solo tiene sentido centrar el mapa
    // si la ciudad cae dentro de la caja. Las demás se listan por su progreso,
    // pero todavía no son navegables.
    if (!_limiteBarcelona.contains(elegida.center)) return;
    setState(() => _seguir = false);
    _mapController.move(elegida.center, 13);
  }

  // Abre el panel de detalle de un POI al tocar su marcador en el mapa. Resuelve
  // a qué colecciones pertenece (filtrando las del contenido por su id). Al tocar
  // una de esas colecciones se abre su pantalla (solo si el POI está descubierto:
  // en modo teaser no se listan colecciones).
  void _abrirDetallePoi(Poi poi, {required bool descubierto}) {
    final colecciones = _content.collections
        .where((c) => c.poiIds.contains(poi.id))
        .toList();
    showPoiDetailSheet(
      context: context,
      poi: poi,
      collections: colecciones,
      discovered: descubierto,
      userPosition: _userPosition.value,
      cityName: kBarcelona.name,
      isDiscoveredId: _poi.isDiscoveredId,
      onCollectionTap: descubierto ? _abrirDetalleColeccion : null,
    );
  }

  // Abre la pantalla de una colección concreta (desde un chip del detalle de un
  // POI). Si dentro tocas un POI descubierto, la pantalla se cierra devolviéndolo
  // y centramos el mapa en él (igual que la misión fijada).
  Future<void> _abrirDetalleColeccion(PoiCollection coleccion) async {
    final elegido = await Navigator.of(context).push<Poi>(
      appRoute(PoiCollectionScreen(
        poiController: _poi,
        collection: coleccion,
        mission: _mission,
      )),
    );
    if (elegido == null || !mounted) return;
    setState(() => _seguir = false);
    _mapController.move(elegido.location, 17);
  }

  // Abre la pantalla del personaje 3D del jugador. Desactivado temporalmente
  // (ver import de avatar_screen.dart y el botón en la UI).
  // void _abrirAvatar() {
  //   Navigator.of(context).push(appRoute(const AvatarScreen()));
  // }

  // Abre los Ajustes (personalización del marcador del jugador).
  void _abrirAjustes() {
    Navigator.of(context).push(
      appRoute(SettingsScreen(
        avatar: _avatar,
        localeController: widget.localeController,
      )),
    );
  }

  // Abre la clasificación (ranking) de jugadores por puntuación.
  void _abrirRanking() {
    Navigator.of(context).push(
      appRoute(LeaderboardScreen(
        fogController: _fog,
        poiController: _poi,
      )),
    );
  }

  // Abre la vitrina de Logros (medallas).
  void _abrirLogros() {
    Navigator.of(context).push(
      appRoute(AchievementsScreen(controller: _achievements), opaque: false),
    );
  }

  // Alterna el modo admin (mostrar todos los POIs). Solo visual; ver
  // [_adminMostrarTodos].
  void _alternarAdmin() {
    setState(() => _adminMostrarTodos = !_adminMostrarTodos);
    ScaffoldMessenger.of(context).clearSnackBars();
    _mostrarAviso(_adminMostrarTodos
        ? 'Admin: los ${_poi.totalCount} POIs como descubiertos (vista previa)'
        : 'Admin: vista normal');
  }

  // Vuelve a centrar el mapa en el usuario y reactiva el auto-seguir.
  void _recentrar() {
    final pos = _userPosition.value;
    if (pos == null) {
      _mostrarAviso(context.l10n.noLocationYet);
      return;
    }
    setState(() => _seguir = true);
    _mapController.move(pos, _mapController.camera.zoom);
  }

  // Construye la capa base del mapa para [style]: vectorial (nítida, vía
  // vector_map_tiles) o raster (tiles PNG). Si el estilo vectorial aún no está
  // cargado, devuelve una capa vacía: mientras tanto el mapa muestra el color de
  // fondo de MapOptions (gris claro) y la carga ya está en marcha.
  Widget _buildBaseLayer(MapStyle style) {
    if (style.isVector) {
      final cargado = _estilosVectoriales[style.cacheKey];
      if (cargado == null) return const SizedBox.shrink();
      // Ajustes finos del render (nulos = defaults de vector_map_tiles); los
      // fijan los experimentos de rendimiento y, tras medir, la config final.
      final tuning = style.tuning;
      return VectorTileLayer(
        // La key por id de estilo recrea la capa al cambiar de estilo vectorial
        // (cacheKey y no styleUri: las skins custom comparten el estilo base).
        key: ValueKey(style.cacheKey),
        tileProviders: cargado.providers,
        theme: cargado.theme,
        sprites: cargado.sprites,
        tileOffset: tuning?.zoomOffset == null
            ? TileOffset.DEFAULT
            : TileOffset(zoomOffset: tuning!.zoomOffset!),
        concurrency:
            tuning?.concurrency ?? VectorTileLayer.defaultConcurrency,
        maximumZoom: tuning?.maximumZoom,
        memoryTileCacheMaxSize: tuning?.memoryTileCacheMaxSize ??
            VectorTileLayer.defaultTileCacheMaxSize,
        memoryTileDataCacheMaxSize: tuning?.memoryTileDataCacheMaxSize ??
            VectorTileLayer.defaultTileDataCacheMaxSize,
        fileCacheMaximumSizeInBytes: tuning?.fileCacheMaximumSizeInBytes ??
            VectorTileLayer.defaultCacheMaxSize,
        textCacheMaxSize:
            tuning?.textCacheMaxSize ?? VectorTileLayer.defaultTextCacheMaxSize,
      );
    }
    // Estilo raster: tiles PNG, con filtro de color opcional.
    final matrix = style.colorMatrix;
    return TileLayer(
      key: ValueKey(style.urlTemplate),
      urlTemplate: style.urlTemplate,
      subdomains: style.subdomains,
      userAgentPackageName: 'com.fogofwar.fog_of_war',
      tileBuilder: matrix == null
          ? null
          : (context, tileWidget, tile) => ColorFiltered(
                colorFilter: ColorFilter.matrix(matrix),
                child: tileWidget,
              ),
    );
  }

  // HUD: la interfaz de cristal que flota sobre el mapa.
  Widget _buildHud() {
    final l = context.l10n;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Stack(
          children: [
            // Tarjeta de estadísticas (arriba-izquierda). Se redibuja sola al
            // cambiar el fog gracias al ListenableBuilder.
            Align(
              alignment: Alignment.topLeft,
              child: ListenableBuilder(
                listenable: Listenable.merge([_fog, _poi, _mission]),
                builder: (context, _) {
                  final mision = _mission.selected;
                  return HudStats(
                    cityName: kBarcelona.name,
                    percentage: kBarcelona.percentageFromCount(
                        _fog.discoveredCountInCity(kBarcelona.id)),
                    cells: _fog.discoveredCount,
                    points: _poi.totalPoints,
                    poisDiscovered: _poi.discoveredCount,
                    poisTotal: _poi.totalCount,
                    missionActive: mision != null,
                    missionDiscovered:
                        mision?.discoveredCount(_poi.isDiscoveredId) ?? 0,
                    missionTotal: mision?.poiIds.length ?? 0,
                    missionColor: mision?.accent,
                    missionIcon: mision?.icon,
                    missionLabel: l.hudMission,
                    onTap: mision != null ? _abrirMisionSeleccionada : null,
                    onLongPress: mision != null ? _quitarMision : null,
                    onCityTap: _abrirCiudades,
                  );
                },
              ),
            ),
            // Botones de la esquina superior derecha: estilo de mapa y modo GPS.
            Align(
              alignment: Alignment.topRight,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GlassIconButton(
                    icon: Icons.layers,
                    tooltip: l.tooltipMapStyle,
                    onPressed: _siguienteEstilo,
                  ),
                  const SizedBox(height: 10),
                  // El icono refleja el modo actual: brújula = exploración,
                  // batería = ahorro. Al pulsar, se alterna.
                  GlassIconButton(
                    icon: _modo == TrackingMode.exploracion
                        ? Icons.explore
                        : Icons.battery_saver,
                    tooltip: l.tooltipGpsMode,
                    active: _modo == TrackingMode.exploracion,
                    onPressed: _cambiarModo,
                  ),
                  const SizedBox(height: 10),
                  // Botón del personaje 3D desactivado temporalmente (no
                  // convence el look). Para reactivarlo, descomentar esto y el
                  // método _abrirAvatar + el import de avatar_screen.dart.
                  // GlassIconButton(
                  //   icon: Icons.person,
                  //   tooltip: l.avatarTitle,
                  //   onPressed: _abrirAvatar,
                  // ),
                  // const SizedBox(height: 10),
                  GlassIconButton(
                    icon: Icons.settings,
                    tooltip: l.tooltipSettings,
                    onPressed: _abrirAjustes,
                  ),
                  const SizedBox(height: 10),
                  // Admin (solo desarrollo): muestra todos los POIs del mapa
                  // como si estuvieran descubiertos (vista previa). No los
                  // descubre de verdad; ver [_adminMostrarTodos].
                  GlassIconButton(
                    icon: Icons.pin_drop,
                    tooltip: 'Admin: mostrar todos los POIs',
                    active: _adminMostrarTodos,
                    onPressed: _alternarAdmin,
                  ),
                ],
              ),
            ),
            // Botones de la esquina inferior izquierda: ranking y colecciones.
            Align(
              alignment: Alignment.bottomLeft,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GlassIconButton(
                    icon: Icons.leaderboard,
                    tooltip: l.tooltipRanking,
                    onPressed: _abrirRanking,
                  ),
                  const SizedBox(height: 10),
                  GlassIconButton(
                    icon: Icons.military_tech,
                    tooltip: l.achievementsTitle,
                    onPressed: _abrirLogros,
                  ),
                  const SizedBox(height: 10),
                  GlassIconButton(
                    icon: Icons.emoji_events,
                    tooltip: l.tooltipCollections,
                    onPressed: _abrirColeccion,
                  ),
                ],
              ),
            ),
            // Botón de recentrar en el usuario (abajo-derecha).
            Align(
              alignment: Alignment.bottomRight,
              child: GlassIconButton(
                icon: _seguir ? Icons.my_location : Icons.location_searching,
                tooltip: l.tooltipRecenter,
                active: _seguir,
                onPressed: _recentrar,
              ),
            ),
            // Métricas de frames en vivo (solo en modo admin): para comprobar
            // en el móvil, con APK release, si el mapa da tirones y cuánto.
            if (_adminMostrarTodos)
              const Align(
                alignment: Alignment.bottomCenter,
                child: FrameStatsOverlay(),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Sin AppBar: el mapa ocupa toda la pantalla y el HUD flota encima.
      body: Stack(
        children: [
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _userPosition.value ?? _centroInicial,
                initialZoom: 16,
                // Topes de zoom: ni tan lejos que se vea medio mundo (y cargue
                // miles de tiles) ni más cerca de lo que sirven los proveedores.
                minZoom: 12,
                maxZoom: 19,
                // Encerramos la cámara en Barcelona: no se puede arrastrar ni
                // alejar fuera de la caja. Esto es lo que evita la congelación.
                cameraConstraint:
                    CameraConstraint.contain(bounds: _limiteBarcelona),
                // Si el usuario arrastra el mapa a mano, desactivamos el
                // auto-seguir para no pelearnos con él.
                onPositionChanged: (camera, hasGesture) {
                  if (hasGesture && _seguir) {
                    setState(() => _seguir = false);
                  }
                },
              ),
              children: [
                // Mapa base. El estilo lo elige el usuario con el botón de capas;
                // se usa el estilo actual de kActiveMapStyles. La clave (key)
                // fuerza a flutter_map a recrear la capa al cambiar de estilo.
                _buildBaseLayer(kActiveMapStyles[_styleIndex]),
                // La niebla va encima de los tiles del mapa, con el color a
                // juego con el estilo actual (o el del juego por defecto).
                // MAP_PERF_NO_FOG (solo capturas de tool/perf): la oculta para
                // poder comparar el mapa base; jamás se define en producción.
                if (!const bool.fromEnvironment('MAP_PERF_NO_FOG'))
                  FogLayer(
                    controller: _fog,
                    color: kActiveMapStyles[_styleIndex].fogColor ?? kFogColor,
                    // Sin ribete por ahora (borderColor: kHudAccent lo
                    // reactiva con el verde del HUD). El contorno suave del
                    // velo no depende de esto.
                  ),
                // Atalayas (siempre visibles) y POIs: avistados en gris,
                // descubiertos en dorado. Se redibuja al activar una atalaya,
                // descubrir un POI o cambiar la misión fijada. Todo va encima
                // de la niebla.
                ListenableBuilder(
                  listenable: Listenable.merge([_poi, _watchtower, _mission]),
                  builder: (context, _) {
                    // Con una misión (colección) fijada y fuera del modo admin,
                    // el mapa se enfoca en esa colección: solo se pintan sus
                    // POIs. El modo admin (ver todos) tiene prioridad.
                    final mision =
                        _adminMostrarTodos ? null : _mission.selected;
                    final soloIds = mision?.poiIds.toSet();
                    final pois = soloIds == null
                        ? _poi.allPois
                        : _poi.allPois
                            .where((p) => soloIds.contains(p.id))
                            .toList();
                    return MarkerLayer(
                    // Mantener los marcadores en vertical aunque se gire el
                    // mapa (flutter_map los contrarrota respecto a la cámara).
                    rotate: true,
                    markers: [
                      // Atalayas: marcador propio, siempre visible.
                      for (final tower in _watchtower.towers)
                        Marker(
                          point: tower.location,
                          width: 44,
                          height: 44,
                          child: _WatchtowerMarker(
                              activated: _watchtower.isActivated(tower)),
                        ),
                      // POIs: dorado si descubierto; gris si solo avistado. En
                      // modo admin, TODOS se muestran como descubiertos (dorado
                      // + ficha completa): es solo una vista previa, no suma
                      // puntos ni se guarda; al salir de admin vuelve el
                      // progreso real.
                      for (final poi in pois)
                        if (_poi.isDiscovered(poi) || _adminMostrarTodos)
                          Marker(
                            point: poi.location,
                            width: 40,
                            height: 40,
                            child: GestureDetector(
                              onTap: () =>
                                  _abrirDetallePoi(poi, descubierto: true),
                              child: _PoiMarker(category: poi.category),
                            ),
                          )
                        else if (_watchtower.isSightedId(poi.id))
                          Marker(
                            point: poi.location,
                            width: 36,
                            height: 36,
                            child: GestureDetector(
                              onTap: () =>
                                  _abrirDetallePoi(poi, descubierto: false),
                              child: _GhostPoiMarker(category: poi.category),
                            ),
                          ),
                    ],
                    );
                  },
                ),
                // Marcador de "estás aquí" (solo si ya tenemos posición). Se
                // redibuja al moverte (ValueNotifier) y al cambiar el avatar en
                // Ajustes, sin reconstruir el resto del mapa.
                ValueListenableBuilder<LatLng?>(
                  valueListenable: _userPosition,
                  builder: (context, pos, _) {
                    if (pos == null) return const SizedBox.shrink();
                    return ListenableBuilder(
                      listenable: _avatar,
                      builder: (context, _) => MarkerLayer(
                        // El avatar también se mantiene en vertical al girar.
                        rotate: true,
                        markers: [
                          Marker(
                            point: pos,
                            // Algo más grande que el avatar para que su halo no
                            // se recorte.
                            width: 42,
                            height: 42,
                            child: AvatarMarker(
                              icon: _avatar.icon,
                              color: _avatar.color,
                              size: 26,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          // El HUD de cristal por encima del mapa.
          _buildHud(),
        ],
      ),
    );
  }
}

// Marcador de un POI descubierto: un círculo ámbar con el icono de su categoría.
class _PoiMarker extends StatelessWidget {
  final PoiCategory category;

  const _PoiMarker({required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFB300), // ámbar: "tesoro" descubierto
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 4),
        ],
      ),
      child: Icon(iconForCategory(category), color: Colors.white, size: 22),
    );
  }
}

// Marcador de un POI AVISTADO (revelado por una atalaya) pero aún no descubierto:
// gris y semitransparente, para que se lea como "sé que está aquí, pero todavía
// no lo he visitado".
class _GhostPoiMarker extends StatelessWidget {
  final PoiCategory category;

  const _GhostPoiMarker({required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xB3667084), // gris azulado semitransparente
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white70, width: 2),
      ),
      child: Icon(iconForCategory(category), color: Colors.white70, size: 18),
    );
  }
}

// Marcador de una ATALAYA: un mirador al que llegar para avistar la zona. Color
// distinto al de los POIs (turquesa si ya la activaste, pizarra si no) con un
// icono de "ojo/avistar".
class _WatchtowerMarker extends StatelessWidget {
  final bool activated;

  const _WatchtowerMarker({required this.activated});

  @override
  Widget build(BuildContext context) {
    final color =
        activated ? const Color(0xFF1FB8C4) : const Color(0xFF566B8C);
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 4)],
      ),
      child: Icon(
        activated ? Icons.visibility : Icons.visibility_outlined,
        color: Colors.white,
        size: 22,
      ),
    );
  }
}

