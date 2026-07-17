// Configuración de la fuente de contenido (la Google Sheet).
//
// Cuando tengas tu hoja creada y compartida, pega aquí su ID (la parte larga de
// la URL: docs.google.com/spreadsheets/d/<ESTE_ID>/edit). Mientras sea null, la
// app funciona solo con el contenido semilla embebido (no intenta descargar).

/// ID de la Google Sheet con el contenido. null = no descargar (usar semilla).
// El tipo es String? a propósito: poner null aquí es el interruptor documentado
// para desactivar la descarga (el analizador sugiere String al ver un valor).
// ignore: unnecessary_nullable_for_final_variable_declarations
const String? kSpreadsheetId = '1oLCwYutbWWN6ANN6oRhr5PJqyZcYeFDOpThDtYN0WaE';

/// Nombres de las pestañas dentro de la hoja.
const String kPoisSheetName = 'POIs';
const String kCollectionsSheetName = 'Collections';
const String kWatchtowersSheetName = 'Watchtowers';

/// Idiomas soportados (deben coincidir con los de la app y los sufijos de las
/// columnas name_xx / desc_xx de la hoja).
const List<String> kContentLocales = ['es', 'en', 'ca', 'fr'];

/// Construye la URL que devuelve una pestaña como CSV (endpoint público gviz;
/// la hoja debe estar compartida como "cualquiera con el enlace: lector").
String sheetCsvUrl(String spreadsheetId, String sheetName) {
  final sheet = Uri.encodeQueryComponent(sheetName);
  return 'https://docs.google.com/spreadsheets/d/$spreadsheetId'
      '/gviz/tq?tqx=out:csv&sheet=$sheet';
}
