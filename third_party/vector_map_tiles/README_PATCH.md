# vector_map_tiles 9.0.0-beta.8 — copia local parcheada

Copia exacta de `vector_map_tiles 9.0.0-beta.8` (pub.dev) con parches MÍNIMOS
de manejo de errores. **El comportamiento de render y rendimiento es el
mismo**; el pin de versión del proyecto sigue siendo deliberado (la 10.x
requiere toolchain nativa cmake — ver memoria del proyecto).

## Por qué

Al hacer pan/zoom, flutter_map cancela los tiles que salen del viewport. El
paquete crea futures "en abanico" y los espera en secuencia con
`testCancelled()`, que lanza a mitad del bucle: los futures aún no esperados
fallan con `CancellationException` **sin dueño**. Eso ensucia el log de la app
real y mata los integration tests de rendimiento (tool/perf) de forma no
determinista.

## Qué se ha tocado (buscar `PATCH fog_of_war`)

- `lib/src/stream/caches_tile_provider.dart` — `_retrieve` y `_createTiles`:
  se esperan SIEMPRE todos los futures aunque uno lance; el primer error se
  re-lanza al final (misma semántica, sin huérfanos).
- `lib/src/raster/tile_loader.dart` — `_renderTile`: si el retrieve del raster
  lanza, se marca `tileResponseFuture.ignore()` antes de re-lanzar.

## Mantenimiento

Si algún día se actualiza el paquete, borrar esta carpeta y el
`dependency_overrides` del pubspec, y comprobar si el upstream ya arregló esto
(o re-aplicar los tres parches).
