// Medición de rendimiento de frames (jank del mapa).
//
// Dos usos:
//   • FrameStatsCollector: acumula los FrameTiming del motor entre start() y
//     stop() y los resume en un FrameStatsReport (percentiles + % de jank).
//     Lo usa el test de rendimiento (integration_test/map_perf_test.dart).
//   • FrameStatsOverlay: chip flotante con p99 y % jank en vivo (ventana
//     deslizante), para validar a ojo en el móvil con APK release. Solo se
//     monta en modo admin (ver main.dart).
//
// Los FrameTiming los da el motor en todos los modos, pero los números solo
// son representativos en --profile o release (en debug todo es más lento y
// vector_map_tiles ignora `concurrency`).

import 'dart:ui' show FontFeature, FramePhase, FrameTiming;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Resumen de una tanda de frames: percentiles de build/raster/total (ms) y
/// porcentaje de frames que superan el presupuesto de 60 fps y de 30 fps.
class FrameStatsReport {
  final int frames;
  final double buildP50, buildP90, buildP99;
  final double rasterP50, rasterP90, rasterP99;
  final double totalP50, totalP90, totalP99;
  final double maxTotalMs;

  /// % de frames por encima de ~16.7 ms (se pierde el presupuesto de 60 fps).
  final double jank60Pct;

  /// % de frames por encima de ~33.4 ms (tirón perceptible).
  final double jank30Pct;

  const FrameStatsReport({
    required this.frames,
    required this.buildP50,
    required this.buildP90,
    required this.buildP99,
    required this.rasterP50,
    required this.rasterP90,
    required this.rasterP99,
    required this.totalP50,
    required this.totalP90,
    required this.totalP99,
    required this.maxTotalMs,
    required this.jank60Pct,
    required this.jank30Pct,
  });

  static const _budget60Ms = 1000 / 60; // 16.7 ms
  static const _budget30Ms = 2000 / 60; // 33.4 ms

  /// Construye el resumen a partir de las duraciones (en ms) por frame.
  factory FrameStatsReport.fromSamples({
    required List<double> buildMs,
    required List<double> rasterMs,
    required List<double> totalMs,
  }) {
    final total = [...totalMs]..sort();
    final jank60 = totalMs.where((t) => t > _budget60Ms).length;
    final jank30 = totalMs.where((t) => t > _budget30Ms).length;
    final n = totalMs.isEmpty ? 1 : totalMs.length;
    return FrameStatsReport(
      frames: totalMs.length,
      buildP50: _percentile(buildMs, 50),
      buildP90: _percentile(buildMs, 90),
      buildP99: _percentile(buildMs, 99),
      rasterP50: _percentile(rasterMs, 50),
      rasterP90: _percentile(rasterMs, 90),
      rasterP99: _percentile(rasterMs, 99),
      totalP50: _percentile(totalMs, 50),
      totalP90: _percentile(totalMs, 90),
      totalP99: _percentile(totalMs, 99),
      maxTotalMs: total.isEmpty ? 0 : total.last,
      jank60Pct: 100.0 * jank60 / n,
      jank30Pct: 100.0 * jank30 / n,
    );
  }

  /// Percentil [p] (0-100) de [values]; 0 si no hay muestras.
  static double _percentile(List<double> values, int p) {
    if (values.isEmpty) return 0;
    final sorted = [...values]..sort();
    final index = (p / 100 * (sorted.length - 1)).round();
    return sorted[index];
  }

  /// Para reportData del integration test (JSON plano).
  Map<String, num> toJson() => {
        'frames': frames,
        'buildP50': _r(buildP50),
        'buildP90': _r(buildP90),
        'buildP99': _r(buildP99),
        'rasterP50': _r(rasterP50),
        'rasterP90': _r(rasterP90),
        'rasterP99': _r(rasterP99),
        'totalP50': _r(totalP50),
        'totalP90': _r(totalP90),
        'totalP99': _r(totalP99),
        'maxTotalMs': _r(maxTotalMs),
        'jank60Pct': _r(jank60Pct),
        'jank30Pct': _r(jank30Pct),
      };

  static double _r(double v) => (v * 100).roundToDouble() / 100;

  @override
  String toString() =>
      'frames=$frames total(p50/p90/p99)=${_r(totalP50)}/${_r(totalP90)}/'
      '${_r(totalP99)}ms max=${_r(maxTotalMs)}ms '
      'jank>16.7ms=${_r(jank60Pct)}% jank>33.4ms=${_r(jank30Pct)}%';
}

/// Acumula los FrameTiming del motor entre [start] y [stop].
class FrameStatsCollector {
  final List<double> _buildMs = [];
  final List<double> _rasterMs = [];
  final List<double> _totalMs = [];
  TimingsCallback? _callback;

  bool get isRunning => _callback != null;

  void start() {
    if (_callback != null) return;
    _buildMs.clear();
    _rasterMs.clear();
    _totalMs.clear();
    _callback = _onTimings;
    SchedulerBinding.instance.addTimingsCallback(_callback!);
  }

  /// Deja de escuchar y devuelve el resumen de lo acumulado.
  FrameStatsReport stop() {
    final cb = _callback;
    if (cb != null) {
      SchedulerBinding.instance.removeTimingsCallback(cb);
      _callback = null;
    }
    return FrameStatsReport.fromSamples(
      buildMs: _buildMs,
      rasterMs: _rasterMs,
      totalMs: _totalMs,
    );
  }

  void _onTimings(List<FrameTiming> timings) {
    for (final t in timings) {
      _buildMs.add(t.buildDuration.inMicroseconds / 1000);
      _rasterMs.add(t.rasterDuration.inMicroseconds / 1000);
      _totalMs.add(t.totalSpan.inMicroseconds / 1000);
    }
  }
}

/// Chip flotante con las métricas de frame en vivo (ventana deslizante de
/// [windowSize] frames). Solo consume trabajo cuando el motor produce frames:
/// con el mapa quieto no se repinta.
class FrameStatsOverlay extends StatefulWidget {
  final int windowSize;

  const FrameStatsOverlay({super.key, this.windowSize = 120});

  @override
  State<FrameStatsOverlay> createState() => _FrameStatsOverlayState();
}

class _FrameStatsOverlayState extends State<FrameStatsOverlay> {
  final List<double> _totalMs = [];
  final List<double> _buildMs = [];
  final List<double> _rasterMs = [];
  late final TimingsCallback _callback;
  Duration _lastRefresh = Duration.zero;
  FrameStatsReport? _report;

  @override
  void initState() {
    super.initState();
    _callback = _onTimings;
    SchedulerBinding.instance.addTimingsCallback(_callback);
  }

  @override
  void dispose() {
    SchedulerBinding.instance.removeTimingsCallback(_callback);
    super.dispose();
  }

  void _onTimings(List<FrameTiming> timings) {
    if (!mounted) return;
    for (final t in timings) {
      _buildMs.add(t.buildDuration.inMicroseconds / 1000);
      _rasterMs.add(t.rasterDuration.inMicroseconds / 1000);
      _totalMs.add(t.totalSpan.inMicroseconds / 1000);
    }
    final sobra = _totalMs.length - widget.windowSize;
    if (sobra > 0) {
      _buildMs.removeRange(0, sobra);
      _rasterMs.removeRange(0, sobra);
      _totalMs.removeRange(0, sobra);
    }
    // Refrescar el chip como mucho 2 veces/segundo para no añadir jank propio.
    final ahora = timings.last.timestampInMicroseconds(FramePhase.rasterFinish);
    final marca = Duration(microseconds: ahora);
    if (marca - _lastRefresh < const Duration(milliseconds: 500)) return;
    _lastRefresh = marca;
    setState(() {
      _report = FrameStatsReport.fromSamples(
        buildMs: _buildMs,
        rasterMs: _rasterMs,
        totalMs: _totalMs,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final r = _report;
    final texto = r == null
        ? 'frames…'
        : 'p90 ${r.totalP90.toStringAsFixed(0)}ms · '
            'p99 ${r.totalP99.toStringAsFixed(0)}ms · '
            'jank ${r.jank30Pct.toStringAsFixed(0)}%';
    return RepaintBoundary(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xB0000000),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          texto,
          style: const TextStyle(
            color: Color(0xFFFFFFFF),
            fontSize: 11,
            fontFeatures: [FontFeature.tabularFigures()],
            decoration: TextDecoration.none,
          ),
        ),
      ),
    );
  }
}
