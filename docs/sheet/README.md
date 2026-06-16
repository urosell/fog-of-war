# Contenido del juego desde una hoja de cálculo

La app puede leer sus **POIs** y **colecciones** de una Google Sheet, para poder
añadir contenido sin tocar código ni recompilar. Este directorio contiene la
**plantilla de arranque** (`POIs.csv` y `Collections.csv`) con el contenido
actual de Barcelona, lista para importar.

## Regla de oro: los `id` son sagrados

El progreso de cada jugador (POIs descubiertos, puntos, misión) se guarda en su
móvil **indexado por el `id`**. Por eso:

- **Añadir** filas nuevas → seguro, no afecta a nadie.
- **Editar** una fila existente manteniendo su `id` (corregir coordenadas, nombre,
  meterla en otra colección) → seguro, el progreso se conserva.
- **Cambiar o reutilizar un `id`**, o **borrar** un POI ya descubierto → ese
  descubrimiento queda huérfano. **No lo hagas** salvo que sepas lo que implica.

## Cómo se actualiza

La app carga el contenido **al arrancar** (de su caché interna, al instante) y
descarga la hoja en segundo plano. **Los cambios que hagas aparecen la próxima
vez que se abre la app.** Si no hay internet, usa la última copia descargada (o
el contenido embebido de fábrica). Nunca se queda en blanco.

## Pestaña `POIs`

Una fila por lugar. Columnas (la cabecera debe llamarse exactamente así):

| Columna | Qué es | Ejemplo |
|---|---|---|
| `id` | Identificador único y estable (sin espacios) | `sagrada_familia` |
| `name` | Nombre que se muestra (no se traduce) | `Sagrada Família` |
| `lat` | Latitud (grados decimales) | `41.4036` |
| `lon` | Longitud (grados decimales) | `2.1744` |
| `category` | Categoría (fija los puntos), de la lista de abajo | `iglesia` |

**Categorías y puntos:**

| `category` | Puntos |
|---|---|
| `michelin` | 60 |
| `monumento` | 50 |
| `iglesia` | 45 |
| `museo` | 40 |
| `parque` | 30 |
| `mirador` | 25 |
| `plaza` | 20 |
| `tapas` | 20 |
| `tienda` | 15 |

## Pestaña `Collections`

Una fila por colección temática. Columnas:

| Columna | Qué es | Ejemplo |
|---|---|---|
| `id` | Identificador único y estable | `gaudi` |
| `icon` | Nombre de icono del catálogo (ver abajo) | `architecture` |
| `color` | Color de acento en hex | `#6BCB77` |
| `poi_ids` | Lista de `id` de POIs separados por `;` | `sagrada_familia;casa_batllo` |
| `name_es` / `name_en` / `name_ca` / `name_fr` | Nombre por idioma | `Ruta Gaudí` |
| `desc_es` / `desc_en` / `desc_ca` / `desc_fr` | Descripción por idioma | `La obra de Gaudí...` |

Si dejas un idioma en blanco, se usa el español como respaldo. Los `id` de
`poi_ids` deben existir en la pestaña `POIs`.

**Iconos disponibles** (columna `icon`): `architecture`, `star`, `auto_awesome`,
`museum`, `tapas`, `restaurant`, `place`, `church`, `park`, `castle`,
`landscape`, `storefront`, `local_cafe`, `local_bar`, `shopping_bag`,
`photo_camera`, `directions_walk`, `map`, `flag`, `favorite`, `sports_soccer`,
`theater_comedy`, `palette`, `music_note`, `menu_book`.
(¿Quieres otro icono? Pídemelo y lo añado al catálogo.)

## Puesta en marcha (una sola vez)

1. Crea una Google Sheet con **dos pestañas** llamadas exactamente `POIs` y
   `Collections`.
2. Importa `POIs.csv` en la pestaña `POIs` y `Collections.csv` en `Collections`
   (Archivo → Importar → Subir → "Reemplazar hoja actual").
3. Comparte la hoja: **Compartir → Acceso general → "Cualquiera con el enlace" →
   Lector**.
4. Copia el ID de la hoja desde su URL:
   `docs.google.com/spreadsheets/d/`**`ESTE_TROZO_LARGO`**`/edit`
5. Pégalo en `lib/content/content_config.dart`, en `kSpreadsheetId`.
6. Recompila la app una vez. A partir de ahí, editar la hoja basta: los cambios
   salen en el siguiente arranque.
