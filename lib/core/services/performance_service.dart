import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

class PerformanceService {
  static final PerformanceService _instance = PerformanceService._internal();
  factory PerformanceService() => _instance;
  PerformanceService._internal();

  final Map<String, DateTime> _startTimes = {};
  final Map<String, List<Duration>> _metrics = {};

  /// Start timing an operation
  void startTiming(String operation) {
    _startTimes[operation] = DateTime.now();
  }

  /// End timing an operation and record the duration
  void endTiming(String operation) {
    final startTime = _startTimes[operation];
    if (startTime == null) return;

    final duration = DateTime.now().difference(startTime);
    _recordMetric(operation, duration);
    _startTimes.remove(operation);

    if (kDebugMode) {
      developer.log('$operation completed in ${duration.inMilliseconds}ms');
    }
  }

  /// Record a custom metric
  void recordMetric(String operation, Duration duration) {
    _recordMetric(operation, duration);
  }

  void _recordMetric(String operation, Duration duration) {
    _metrics.putIfAbsent(operation, () => []).add(duration);
    
    // Keep only last 100 measurements per operation
    if (_metrics[operation]!.length > 100) {
      _metrics[operation]!.removeAt(0);
    }
  }

  /// Get average duration for an operation
  Duration? getAverageDuration(String operation) {
    final measurements = _metrics[operation];
    if (measurements == null || measurements.isEmpty) return null;

    final totalMs = measurements.fold<int>(
      0, (sum, duration) => sum + duration.inMilliseconds,
    );
    
    return Duration(milliseconds: totalMs ~/ measurements.length);
  }

  /// Get performance summary for debugging
  Map<String, Map<String, dynamic>> getPerformanceSummary() {
    final summary = <String, Map<String, dynamic>>{};
    
    for (final entry in _metrics.entries) {
      final operation = entry.key;
      final durations = entry.value;
      
      if (durations.isEmpty) continue;
      
      final totalMs = durations.fold<int>(
        0, (sum, duration) => sum + duration.inMilliseconds,
      );
      
      final avgMs = totalMs ~/ durations.length;
      final minMs = durations.map((d) => d.inMilliseconds).reduce((a, b) => a < b ? a : b);
      final maxMs = durations.map((d) => d.inMilliseconds).reduce((a, b) => a > b ? a : b);
      
      summary[operation] = {
        'count': durations.length,
        'averageMs': avgMs,
        'minMs': minMs,
        'maxMs': maxMs,
        'totalMs': totalMs,
      };
    }
    
    return summary;
  }

  /// Clear all metrics
  void clearMetrics() {
    _metrics.clear();
    _startTimes.clear();
  }

  /// Log performance summary
  void logPerformanceSummary() {
    if (!kDebugMode) return;
    
    final summary = getPerformanceSummary();
    if (summary.isEmpty) {
      developer.log('No performance metrics available');
      return;
    }
    
    developer.log('=== Performance Summary ===');
    for (final entry in summary.entries) {
      final operation = entry.key;
      final stats = entry.value;
      
      developer.log(
        '$operation: ${stats['count']} calls, '
        'avg: ${stats['averageMs']}ms, '
        'min: ${stats['minMs']}ms, '
        'max: ${stats['maxMs']}ms',
      );
    }
    developer.log('=== End Summary ===');
  }
}

/// Helper class to automatically time operations
class TimedOperation {
  final String operation;
  final PerformanceService _performance = PerformanceService();
  
  TimedOperation(this.operation) {
    _performance.startTiming(operation);
  }
  
  void end() {
    _performance.endTiming(operation);
  }
}
