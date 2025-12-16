import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing user-specific parameter thresholds locally
/// Thresholds are stored per user and not synced to Supabase DB
class LocalThresholdService {
  static const String _thresholdPrefix = 'threshold_';
  
  /// Get threshold for a specific machine-parameter combination
  /// Returns null if not set, which means default should be used
  Future<Map<String, double>?> getThreshold({
    required String machineId,
    required String parameterId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_thresholdPrefix$machineId\_$parameterId';
      
      final minThreshold = prefs.getDouble('${key}_min');
      final maxThreshold = prefs.getDouble('${key}_max');
      
      if (minThreshold != null && maxThreshold != null) {
        return {
          'min': minThreshold,
          'max': maxThreshold,
        };
      }
      
      return null;
    } catch (e) {
      print('Error getting threshold: $e');
      return null;
    }
  }
  
  /// Save threshold for a specific machine-parameter combination
  Future<void> setThreshold({
    required String machineId,
    required String parameterId,
    required double minThreshold,
    required double maxThreshold,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_thresholdPrefix$machineId\_$parameterId';
      
      await prefs.setDouble('${key}_min', minThreshold);
      await prefs.setDouble('${key}_max', maxThreshold);
    } catch (e) {
      print('Error saving threshold: $e');
    }
  }
  
  /// Get threshold with default values if not set
  /// Default is currentValue - 10 for min and currentValue + 10 for max
  Future<Map<String, double>> getThresholdWithDefaults({
    required String machineId,
    required String parameterId,
    required double currentValue,
  }) async {
    final threshold = await getThreshold(
      machineId: machineId,
      parameterId: parameterId,
    );
    
    if (threshold != null) {
      return threshold;
    }
    
    // Default: -10 and +10 from current value
    return {
      'min': currentValue - 10,
      'max': currentValue + 10,
    };
  }
  
  /// Get all thresholds for a machine
  Future<Map<String, Map<String, double>>> getMachineThresholds(
    String machineId,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      final prefix = '$_thresholdPrefix$machineId\_';
      
      final Map<String, Map<String, double>> thresholds = {};
      
      for (var key in keys) {
        if (key.startsWith(prefix) && key.endsWith('_min')) {
          // Extract parameter ID from key
          final paramKey = key.substring(prefix.length, key.length - 4); // Remove prefix and '_min'
          final minThreshold = prefs.getDouble(key);
          final maxThreshold = prefs.getDouble('$_thresholdPrefix$machineId\_$paramKey\_max');
          
          if (minThreshold != null && maxThreshold != null) {
            thresholds[paramKey] = {
              'min': minThreshold,
              'max': maxThreshold,
            };
          }
        }
      }
      
      return thresholds;
    } catch (e) {
      print('Error getting machine thresholds: $e');
      return {};
    }
  }
  
  /// Clear all thresholds (useful for testing or reset)
  Future<void> clearAllThresholds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      final keysToRemove = keys.where((key) => key.startsWith(_thresholdPrefix)).toList();
      
      for (var key in keysToRemove) {
        await prefs.remove(key);
      }
    } catch (e) {
      print('Error clearing thresholds: $e');
    }
  }
}


