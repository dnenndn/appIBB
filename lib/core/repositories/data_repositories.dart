import '../../core/services/supabase_service.dart';

/// Repository Pattern for Data Management
/// 
/// This class provides a clean abstraction layer between the UI and Supabase,
/// making it easier to switch data sources or add caching logic later.

class MachineRepository {
  final SupabaseService _supabaseService = SupabaseService();

  /// Get all machines
  Future<List<Map<String, dynamic>>> getAllMachines() async {
    try {
      return await _supabaseService.getAllMachines();
    } catch (e) {
      throw Exception('Unable to load machines: $e');
    }
  }

  /// Get specific machine by ID
  Future<Map<String, dynamic>> getMachineById(String machineId) async {
    try {
      return await _supabaseService.getMachineById(machineId);
    } catch (e) {
      throw Exception('Unable to load machine $machineId: $e');
    }
  }

  /// Get machine parameters
  Future<List<Map<String, dynamic>>> getMachineParameters(
      String machineId) async {
    try {
      final result = await _supabaseService.getMachineParameters(machineId);

      // If we got data from Supabase (even if empty), return it - don't use mock data
      if (result.isNotEmpty) {
        return result;
      } else {
        // Return empty list instead of mock data when Supabase returns empty
        // This allows the UI to show "No parameters" instead of fake data
        return [];
      }
    } catch (e) {
      throw Exception('Unable to load parameters for $machineId: $e');
    }
  }
}

class AlertRepository {
  final SupabaseService _supabaseService = SupabaseService();

  /// Get all active alerts
  Future<List<Map<String, dynamic>>> getActiveAlerts() async {
    try {
      return await _supabaseService.getActiveAlerts();
    } catch (e) {
      throw Exception('Unable to load alerts: $e');
    }
  }

  /// Get alerts by type
  Future<List<Map<String, dynamic>>> getAlertsByType(String type) async {
    try {
      return await _supabaseService.getAlertsByType(type);
    } catch (e) {
      throw Exception('Unable to load alerts of type $type: $e');
    }
  }

  /// Resolve alert
  Future<void> resolveAlert(String alertId) async {
    try {
      await _supabaseService.resolveAlert(alertId);
    } catch (e) {
      throw Exception('Unable to resolve alert $alertId: $e');
    }
  }

}

class ShiftRepository {
  final SupabaseService _supabaseService = SupabaseService();

  /// Get shifts for date range
  Future<List<Map<String, dynamic>>> getShifts({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final shifts = await _supabaseService.getShifts(
        startDate: startDate,
        endDate: endDate,
      );
      // Return whatever Supabase returned (may be empty)
      return shifts;
    } catch (e) {
      throw Exception('Unable to load shifts: $e');
    }
  }

  /// Get shift details
  Future<Map<String, dynamic>> getShiftDetails(String shiftId) async {
    try {
      final details = await _supabaseService.getShiftDetails(shiftId);
      return details;
    } catch (e) {
      throw Exception('Unable to load shift details for $shiftId: $e');
    }
  }

}