# Contenido del juego desde una hoja de cálculo

La app puede leer sus **POIs**, **colecciones** y **atalayas** de una Google
Sheet, para poder añadir contenido sin tocar código ni recompilar. Este
directorio contiene la **plantilla de arranque** (`POIs.csv`, `Collections.csv`
y `Watchtowers.csv`) con el contenido actual de Barcelona, lista para importar.

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
| `lat` | Latitud (grados decimales, con **punto**) | `41.4036` |
| `lon` | Longitud (grados decimales, con **punto**) | `2.1744` |
| `category` | Categoría (fija los puntos), de la lista de abajo | `iglesia` |
| `maps_url` | **Opcional.** Enlace a Google Maps del lugar. Si lo dejas vacío, la app genera uno solo desde `lat`/`lon`. | `https://maps.app.goo.gl/...` |

> **Nota sobre los decimales:** la hoja debe estar en configuración regional
> **Estados Unidos** (Archivo → Configuración → General) para que el punto `.`
> sea el separador decimal. Si no, al importar se corrompen las coordenadas.

> **El enlace `maps_url`:** al tocar un POI **ya descubierto** en el mapa se abre
> un panel con su nombre, las colecciones a las que pertenece y un botón "Abrir
> en Google Maps" que usa este enlace (o, si está vacío, uno generado con las
> coordenadas). Para obtenerlo: busca el sitio en Google Maps → Compartir →
> Copiar enlace.

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

## Pestaña `Watchtowers`

Las atalayas: miradores que, al llegar físicamente (a menos de 70 m), **avistan**
los POIs de su alrededor (aparecen en gris; descubrirlos sigue exigiendo ir).
Una fila por atalaya. Columnas:

| Columna | Qué es | Ejemplo |
|---|---|---|
| `id` | Identificador único y estable (misma regla de oro que los POIs) | `atalaya_gracia` |
| `name` | Nombre del lugar real al que está anclada (no se traduce) | `Plaça del Sol` |
| `lat` / `lon` | Coordenadas (grados decimales, con **punto**) | `41.4016` / `2.1567` |
| `radius_m` | Radio de avistado en metros. Vacío = 600. | `800` |

> **Importante:** la columna `radius_m` debe existir en la cabecera **aunque
> dejes celdas vacías**: es la firma con la que la app reconoce la pestaña. Si
> la pestaña no existe o le falta esa columna, la app ignora la descarga y usa
> las atalayas embebidas de fábrica (no se rompe nada, pero tus cambios no
> salen).

Para colocar atalayas nuevas o ajustar radios sin ir a ciegas:
`dart run tool/watchtower_coverage.dart` descarga esta misma hoja y te dice qué
POIs avista cada atalaya y cuáles quedan huérfanos. En el móvil, el modo admin
dibuja el círculo de rango de cada atalaya sobre el mapa.

## Puesta en marcha (una sola vez)

1. Crea una Google Sheet con **tres pestañas** llamadas exactamente `POIs`,
   `Collections` y `Watchtowers`.
2. Importa cada CSV de esta carpeta en su pestaña
   (Archivo → Importar → Subir → "Reemplazar hoja actual").
3. Comparte la hoja: **Compartir → Acceso general → "Cualquiera con el enlace" →
   Lector**.
4. Copia el ID de la hoja desde su URL:
   `docs.google.com/spreadsheets/d/`**`ESTE_TROZO_LARGO`**`/edit`
5. Pégalo en `lib/content/content_config.dart`, en `kSpreadsheetId`.
6. Recompila la app una vez. A partir de ahí, editar la hoja basta: los cambios
   salen en el siguiente arranque.
