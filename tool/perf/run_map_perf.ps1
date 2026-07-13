# Mide el rendimiento del mapa (frames/jank por estilo) en el emulador.
#
# Compila el integration test en modo PROFILE (en debug los numeros no valen),
# deja el dispositivo en estado limpio y conocido (pm clear + permisos + GPS
# fijo en Barcelona), lanza el guion de camara de integration_test/
# map_perf_test.dart y pinta una tabla comparativa por estilo y pasada
# (fria/caliente). Cada run se guarda en tool/perf/results/.
#
# Uso (desde la raiz del repo):
#   powershell -File tool\perf\run_map_perf.ps1                  # 1 run, todos los estilos
#   powershell -File tool\perf\run_map_perf.ps1 -Runs 3          # medianas de 3 runs
#   powershell -File tool\perf\run_map_perf.ps1 -Only game,satellite
#   powershell -File tool\perf\run_map_perf.ps1 -SkipBuild       # reusar el APK ya compilado
#
# Requisitos: AVD 'fog_pixel' (se arranca solo si no esta) y red (los tiles
# vienen de OpenFreeMap/Esri/CARTO).

param(
    [int]$Runs = 1,
    [string]$Only = '',
    [switch]$SkipBuild,
    [string]$DeviceId = 'emulator-5554'
)

$ErrorActionPreference = 'Stop'

$adb = Join-Path $env:LOCALAPPDATA 'Android\Sdk\platform-tools\adb.exe'
$pkg = 'com.fogofwar.fog_of_war'
$repo = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$apk = Join-Path $repo 'build\app\outputs\flutter-apk\app-profile.apk'
$resultsDir = Join-Path $PSScriptRoot 'results'

if (-not (Test-Path $adb)) { throw "No se encuentra adb en $adb" }
if (-not (Test-Path $resultsDir)) { New-Item -ItemType Directory $resultsDir | Out-Null }

function Wait-Emulator {
    $listado = & $adb devices
    if ($listado -match [regex]::Escape($DeviceId)) { return }
    Write-Host "Arrancando emulador fog_pixel..."
    flutter emulators --launch fog_pixel
    $reloj = [System.Diagnostics.Stopwatch]::StartNew()
    while ($true) {
        if ($reloj.Elapsed.TotalSeconds -gt 180) { throw 'El emulador no arranca (180 s)' }
        Start-Sleep -Seconds 5
        $boot = & $adb -s $DeviceId shell getprop sys.boot_completed 2>$null
        if ("$boot".Trim() -eq '1') { break }
    }
    Start-Sleep -Seconds 5
}

function Reset-App {
    # Estado limpio: borra datos y caches de tiles; luego re-concede permisos
    # (pm clear los revoca) y fija el GPS en el punto de partida del guion.
    & $adb -s $DeviceId shell pm clear $pkg | Out-Null
    foreach ($permiso in 'android.permission.ACCESS_FINE_LOCATION',
                         'android.permission.ACCESS_COARSE_LOCATION',
                         'android.permission.POST_NOTIFICATIONS') {
        try { & $adb -s $DeviceId shell pm grant $pkg $permiso 2>$null | Out-Null } catch {}
    }
    # geo fix va en orden LONGITUD LATITUD.
    try { & $adb -s $DeviceId emu geo fix 2.140 41.380 | Out-Null } catch {}
}

function Get-Mediana([double[]]$valores) {
    $orden = $valores | Sort-Object
    $n = $orden.Count
    if ($n -eq 0) { return 0 }
    if ($n % 2 -eq 1) { return $orden[[int](($n - 1) / 2)] }
    return ($orden[$n / 2 - 1] + $orden[$n / 2]) / 2
}

Wait-Emulator

# --- Compilar el APK de profile con el test integrado ---
if (-not $SkipBuild) {
    $defines = @('--dart-define=MAP_PERF_EXPERIMENTS=true')
    if ($Only -ne '') { $defines += "--dart-define=MAP_PERF_ONLY=$Only" }
    Write-Host "Compilando APK profile (esto tarda un par de minutos)..."
    Push-Location $repo
    try {
        flutter build apk --profile -t integration_test/map_perf_test.dart @defines
        if ($LASTEXITCODE -ne 0) { throw 'flutter build apk fallo' }
    } finally { Pop-Location }
}
if (-not (Test-Path $apk)) { throw "No existe el APK $apk (compila sin -SkipBuild)" }

# --- Ejecutar los runs ---
$sello = Get-Date -Format 'yyyyMMdd_HHmmss'
$ficherosRun = @()
for ($run = 1; $run -le $Runs; $run++) {
    Write-Host "`n=== Run $run de $Runs ===" -ForegroundColor Cyan
    # Instalar primero para poder limpiar datos ANTES de ejecutar (el drive
    # reinstala el mismo binario, y una reinstalacion no restaura los datos).
    & $adb -s $DeviceId install -r $apk | Out-Null
    Reset-App

    Push-Location $repo
    try {
        flutter drive --profile -d $DeviceId `
            --driver=test_driver/perf_driver.dart `
            --target=integration_test/map_perf_test.dart `
            --use-application-binary=$apk
        if ($LASTEXITCODE -ne 0) { throw "flutter drive fallo en el run $run" }
    } finally { Pop-Location }

    $json = Join-Path $repo 'build\map_perf.json'
    if (-not (Test-Path $json)) { throw "No aparece $json tras el run $run" }
    $destino = Join-Path $resultsDir "map_perf_${sello}_run$run.json"
    Copy-Item $json $destino
    $ficherosRun += $destino
    Write-Host "Resultados del run $run -> $destino"
}

# --- Tabla comparativa (medianas entre runs) ---
$porEstilo = @{}   # estilo -> pasada -> metrica -> lista de valores
$ordenEstilos = @()
foreach ($fichero in $ficherosRun) {
    $data = Get-Content $fichero -Raw | ConvertFrom-Json
    foreach ($prop in $data.PSObject.Properties) {
        $estilo = $prop.Name
        if ($estilo -eq '_meta') { continue }
        if (-not $porEstilo.ContainsKey($estilo)) {
            $porEstilo[$estilo] = @{}
            $ordenEstilos += $estilo
        }
        if ($null -ne $prop.Value.PSObject.Properties['error']) {
            $porEstilo[$estilo]['error'] = $prop.Value.error
            continue
        }
        foreach ($pasada in 'cold', 'warm') {
            $metricas = $prop.Value.$pasada
            if ($null -eq $metricas) { continue }
            if (-not $porEstilo[$estilo].ContainsKey($pasada)) { $porEstilo[$estilo][$pasada] = @{} }
            foreach ($m in $metricas.PSObject.Properties) {
                if (-not $porEstilo[$estilo][$pasada].ContainsKey($m.Name)) {
                    $porEstilo[$estilo][$pasada][$m.Name] = @()
                }
                $porEstilo[$estilo][$pasada][$m.Name] += [double]$m.Value
            }
        }
    }
}

$filas = @()
foreach ($estilo in $ordenEstilos) {
    if ($porEstilo[$estilo].ContainsKey('error')) {
        $filas += [pscustomobject]@{
            Estilo = $estilo; Pasada = 'ERROR'; Frames = 0
            'build p90' = 0; 'raster p90' = 0; 'total p90' = 0; 'total p99' = 0
            'jank>16.7 %' = 0; 'jank>33.4 %' = 0
        }
        Write-Host "ERROR en ${estilo}: $($porEstilo[$estilo]['error'])" -ForegroundColor Red
        continue
    }
    foreach ($pasada in 'cold', 'warm') {
        if (-not $porEstilo[$estilo].ContainsKey($pasada)) { continue }
        $m = $porEstilo[$estilo][$pasada]
        $filas += [pscustomobject]@{
            Estilo = $estilo
            Pasada = @{cold = 'fria'; warm = 'caliente'}[$pasada]
            Frames = [int](Get-Mediana $m['frames'])
            'build p90' = [math]::Round((Get-Mediana $m['buildP90']), 1)
            'raster p90' = [math]::Round((Get-Mediana $m['rasterP90']), 1)
            'total p90' = [math]::Round((Get-Mediana $m['totalP90']), 1)
            'total p99' = [math]::Round((Get-Mediana $m['totalP99']), 1)
            'jank>16.7 %' = [math]::Round((Get-Mediana $m['jank60Pct']), 1)
            'jank>33.4 %' = [math]::Round((Get-Mediana $m['jank30Pct']), 1)
        }
    }
}

Write-Host "`n=== Rendimiento del mapa (ms por frame; medianas de $Runs run(s)) ===" -ForegroundColor Green
$filas | Format-Table -AutoSize
