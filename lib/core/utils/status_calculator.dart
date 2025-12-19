import '../services/local_threshold_service.dart';

/// Utility class for calculating parameter status consistently across the app
class StatusCalculator {
  /// Calculate parameter status based on value and thresholds
  /// Uses local threshold service to get user-specific thresholds
  /// Returns: 'normal', 'warning', or 'critical'
  static Future<String> calculateStatus({
    required double? value,
    required String machineId,
    required String parameterId,
    required double currentValue,
    LocalThresholdService? thresholdService,
  }) async {
    if (value == null) return 'unknown';
    
    final service = thresholdService ?? LocalThresholdService();
    
    // Get critical thresholds (main thresholds)
    final criticalThresholds = await service.getThresholdWithDefaults(
      machineId: machineId,
      parameterId: parameterId,
      currentValue: currentValue,
    );
    
    final criticalMin = criticalThresholds['min']!;
    final criticalMax = criticalThresholds['max']!;
    
    // Get warning thresholds
    final warningThresholds = await service.getWarningThresholds(
      machineId: machineId,
      parameterId: parameterId,
    );
    
    // Default warning thresholds are 90% of min and 110% of max if not set
    final warningMin = warningThresholds?['min'] ?? (criticalMin * 0.9);
    final warningMax = warningThresholds?['max'] ?? (criticalMax * 1.1);
    
    // Check critical thresholds first
    if (value < criticalMin || value > criticalMax) {
      return 'critical';
    }
    
    // Check warning thresholds
    if (value < warningMin || value > warningMax) {
      return 'warning';
    }
    
    return 'normal';
  }
  
  /// Calculate status synchronously using provided thresholds
  /// This is used when thresholds are already known
  static String calculateStatusSync({
    required double? value,
    required double criticalMin,
    required double criticalMax,
    double? warningMin,
    double? warningMax,
  }) {
    if (value == null) return 'unknown';
    
    // Default warning thresholds if not provided
    final warningMinValue = warningMin ?? (criticalMin * 0.9);
    final warningMaxValue = warningMax ?? (criticalMax * 1.1);
    
    // Check critical thresholds first
    if (value < criticalMin || value > criticalMax) {
      return 'critical';
    }
    
    // Check warning thresholds
    if (value < warningMinValue || value > warningMaxValue) {
      return 'warning';
    }
    
    return 'normal';
  }
}

