import 'dart:async';

import 'package:vector_tile_renderer/vector_tile_renderer.dart';

import '../cache/caches.dart';
import 'tile_processor.dart';
import 'tile_supplier.dart';
import 'tileset_executor_preprocessor.dart';
import 'tileset_ui_preprocessor.dart';

class CachesTileProvider extends TileProvider {
  final Caches _caches;
  final TileProcessor _tileProcessor;
  final TilesetExecutorPreprocessor _preprocessor;
  final TilesetUiPreprocessor _uiPreprocessor;

  CachesTileProvider(this._caches, this._tileProcessor, this._preprocessor,
      this._uiPreprocessor);

  @override
  int get maximumZoom => _caches.vectorTileCache.maximumZoom;

  @override
  Future<TileResponse> provide(TileRequest request) =>
      _provide(request, localOnly: false);

  @override
  Future<TileResponse> provideLocalCopy(TileRequest request) =>
      _provide(request, localOnly: true);

  Future<TileResponse> _provide(TileRequest request,
      {required bool localOnly}) async {
    Map<String, TileData?> tileDataBySource =
        await _retrieve(request, localOnly: localOnly);
    if (tileDataBySource.values.any((t) => t == null)) {
      return TileResponse(identity: request.tileId, tileset: null);
    }
    Map<String, TileData> loadedDataBySource =
        tileDataBySource.map((key, value) => MapEntry(key, value!));
    Map<String, Tile> tileBySource =
        await _createTiles(request, loadedDataBySource);
    var tileset = await _preprocessor.preprocess(
        request.tileId,
        Tileset(tileBySource),
        request.clip,
        request.zoom.truncate(),
        request.cancelled);
    tileset = await _uiPreprocessor.preprocess(request.tileId, tileset,
        request.clip, request.zoom.truncate(), request.cancelled);
    return TileResponse(identity: request.tileId, tileset: tileset);
  }

  Future<Map<String, TileData?>> _retrieve(TileRequest request,
      {required bool localOnly}) async {
    Map<String, Future<TileData?>> futureBySource = {};
    for (final source in request.tileSources) {
      futureBySource[source] = _caches.vectorTileCache.retrieve(
          source, request.tileId,
          cachedOnly: localOnly, cancelled: request.cancelled);
      // PATCH fog_of_war: observar cada future desde ya; si falla mientras se
      // espera otro (hueco async), el error no queda sin dueño. El await de
      // abajo sigue recibiendo el valor o el error.
      futureBySource[source]!.ignore();
    }
    // PATCH fog_of_war: esperar SIEMPRE todos los futures aunque uno lance
    // (p. ej. CancellationException al podar un tile durante un pan). El
    // original abortaba el bucle a mitad y dejaba futures fallidos sin dueño,
    // que subían como errores asíncronos no manejados.
    Map<String, TileData?> tileBySource = {};
    Object? error;
    StackTrace? stack;
    for (final entry in futureBySource.entries) {
      try {
        request.testCancelled();
        tileBySource[entry.key] = await entry.value;
      } catch (e, s) {
        error ??= e;
        stack ??= s;
        // seguir esperando el resto para que ningún future quede sin dueño
        try {
          await entry.value;
        } catch (_) {}
      }
    }
    if (error != null) {
      return Future.error(error, stack);
    }
    return tileBySource;
  }

  Future<Map<String, Tile>> _createTiles(
      TileRequest request, Map<String, TileData> tileDataBySource) async {
    final sourceToTileFuture = tileDataBySource.map((source, tileData) =>
        MapEntry(
            source,
            _tileProcessor.process(
                request, source, tileData, request.cancelled)));
    // PATCH fog_of_war: mismo arreglo que en _retrieve (ver arriba), en sus
    // dos partes: observar ya cada future y esperarlos todos aunque uno lance.
    for (final future in sourceToTileFuture.values) {
      future.ignore();
    }
    Map<String, Tile> tileBySource = {};
    Object? error;
    StackTrace? stack;
    for (final entry in sourceToTileFuture.entries) {
      try {
        request.testCancelled();
        tileBySource[entry.key] = await entry.value;
      } catch (e, s) {
        error ??= e;
        stack ??= s;
        try {
          await entry.value;
        } catch (_) {}
      }
    }
    if (error != null) {
      return Future.error(error, stack);
    }
    return tileBySource;
  }
}
