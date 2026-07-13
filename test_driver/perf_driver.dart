// Driver (lado host) del test de rendimiento del mapa. Recoge el reportData
// del integration test y lo vuelca a build/map_perf.json, que luego parsea
// tool/perf/run_map_perf.ps1.

import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver(
      responseDataCallback: (data) async {
        await writeResponseData(data, testOutputFilename: 'map_perf');
      },
    );
