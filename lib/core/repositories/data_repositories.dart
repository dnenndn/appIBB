import '../../core/services/supabase_service.dart';

/// Repository Pattern for Data Management
/// 
/// This class provides a clean abstraction layer between the UI and Supabase,
/// making it easier to switch data sources or add caching logic later.

class MachineRepository {
  final SupabaseService _supabaseService = SupabaseService();

  /// Get all machines with fallback to mock data
  Future<List<Map<String, dynamic>>> getAllMachines({
    bool useMockDataOnError = true,
  }) async {
    try {
      return await _supabaseService.getAllMachines();
    } catch (e) {
      print('Error fetching machines from Supabase: $e');
      if (useMockDataOnError) {
        return _getMockMachines();
      }
      rethrow;
    }
  }

  /// Get specific machine by ID
  Future<Map<String, dynamic>> getMachineById(String machineId) async {
    try {
      return await _supabaseService.getMachineById(machineId);
    } catch (e) {
      print('Error fetching machine: $e');
      final mockMachines = _getMockMachines();
      return mockMachines.firstWhere(
        (m) => m['id'] == machineId,
        orElse: () => {},
      );
    }
  }

  /// Get machine parameters
  Future<List<Map<String, dynamic>>> getMachineParameters(
      String machineId) async {
    try {
      return await _supabaseService.getMachineParameters(machineId);
    } catch (e) {
      print('Error fetching machine parameters: $e');
      return [];
    }
  }

  /// Mock data for development/offline mode
  List<Map<String, dynamic>> _getMockMachines() {
    return [
      {
        "id": "kiln_01",
        "name": "Kiln 1",
        "type": "kiln",
        "status": "normal",
        "production": 245.8,
        "temperature": 1150.0,
        "downtime": 0,
        "flow": 85.5,
        "burner_temp": 1200.0,
        "energy_consumption": 342.5,
        "avg_cut_per_min": 12.5,
        "priority": 1,
      },
      {
        "id": "kiln_02",
        "name": "Kiln 2",
        "type": "kiln",
        "status": "warning",
        "production": 198.3,
        "temperature": 1085.0,
        "downtime": 15,
        "flow": 72.3,
        "burner_temp": 1150.0,
        "energy_consumption": 298.7,
        "avg_cut_per_min": 10.2,
        "priority": 2,
      },
      {
        "id": "kiln_03",
        "name": "Kiln 3",
        "type": "kiln",
        "status": "normal",
        "production": 268.9,
        "temperature": 1175.0,
        "downtime": 0,
        "flow": 88.7,
        "burner_temp": 1225.0,
        "energy_consumption": 365.2,
        "avg_cut_per_min": 13.2,
        "priority": 4,
      },
      {
        "id": "dryer_01",
        "name": "Dryer 1",
        "type": "dryer",
        "status": "normal",
        "production": 312.5,
        "temperature": 185.0,
        "downtime": 0,
        "flow": 95.8,
        "burner_temp": 220.0,
        "energy_consumption": 156.3,
        "avg_cut_per_min": 15.8,
        "priority": 3,
      },
      {
        "id": "dryer_02",
        "name": "Dryer 2",
        "type": "dryer",
        "status": "critical",
        "production": 125.7,
        "temperature": 142.0,
        "downtime": 45,
        "flow": 45.2,
        "burner_temp": 180.0,
        "energy_consumption": 98.5,
        "avg_cut_per_min": 6.3,
        "priority": 0,
      },
      {
        "id": "dryer_03",
        "name": "Dryer 3",
        "type": "dryer",
        "status": "warning",
        "production": 245.3,
        "temperature": 168.0,
        "downtime": 8,
        "flow": 78.5,
        "burner_temp": 195.0,
        "energy_consumption": 132.8,
        "avg_cut_per_min": 12.1,
        "priority": 5,
      },
    ];
  }
}

class AlertRepository {
  final SupabaseService _supabaseService = SupabaseService();

  /// Get all active alerts
  Future<List<Map<String, dynamic>>> getActiveAlerts() async {
    try {
      return await _supabaseService.getActiveAlerts();
    } catch (e) {
      print('Error fetching alerts: $e');
      return _getMockAlerts();
    }
  }

  /// Get alerts by type
  Future<List<Map<String, dynamic>>> getAlertsByType(String type) async {
    try {
      return await _supabaseService.getAlertsByType(type);
    } catch (e) {
      print('Error fetching alerts by type: $e');
      return _getMockAlerts()
          .where((alert) => alert['type'] == type)
          .toList();
    }
  }

  /// Resolve alert
  Future<void> resolveAlert(String alertId) async {
    try {
      await _supabaseService.resolveAlert(alertId);
    } catch (e) {
      print('Error resolving alert: $e');
      rethrow;
    }
  }

  /// Mock alert data
  List<Map<String, dynamic>> _getMockAlerts() {
    return [
      {
        'id': 'alert_001',
        'machine_name': 'Kiln #1',
        'type': 'critical',
        'alert_type': 'Temperature Exceeded',
        'timestamp': '2 min ago',
        'current_status': 'Burner temperature at 1250°C (Max: 1200°C)',
        'is_resolved': false,
        'parameter': 'burner_temperature',
        'machine_id': 'kiln_01',
      },
      {
        'id': 'alert_002',
        'machine_name': 'Dryer #2',
        'type': 'warning',
        'alert_type': 'Low Flow Rate',
        'timestamp': '15 min ago',
        'current_status': 'Flow rate at 45 m³/h (Min: 50 m³/h)',
        'is_resolved': false,
        'parameter': 'flow_rate',
        'machine_id': 'dryer_02',
      },
      {
        'id': 'alert_003',
        'machine_name': 'Kiln #2',
        'type': 'status',
        'alert_type': 'Machine Started',
        'timestamp': '1 hour ago',
        'current_status': 'Machine resumed operation after maintenance',
        'is_resolved': true,
        'parameter': 'machine_status',
        'machine_id': 'kiln_02',
      },
      {
        'id': 'alert_004',
        'machine_name': 'Dryer #1',
        'type': 'critical',
        'alert_type': 'Emergency Stop',
        'timestamp': '3 hours ago',
        'current_status': 'Machine stopped due to safety sensor trigger',
        'is_resolved': false,
        'parameter': 'machine_status',
        'machine_id': 'dryer_01',
      },
      {
        'id': 'alert_005',
        'machine_name': 'Kiln #3',
        'type': 'warning',
        'alert_type': 'High Energy Consumption',
        'timestamp': '5 hours ago',
        'current_status': 'Energy usage at 125 kWh (Avg: 100 kWh)',
        'is_resolved': true,
        'parameter': 'energy_consumption',
        'machine_id': 'kiln_03',
      },
      {
        'id': 'alert_006',
        'machine_name': 'Dryer #3',
        'type': 'status',
        'alert_type': 'Maintenance Scheduled',
        'timestamp': '1 day ago',
        'current_status': 'Routine maintenance scheduled for tomorrow',
        'is_resolved': false,
        'parameter': 'maintenance',
        'machine_id': 'dryer_03',
      },
    ];
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
      return await _supabaseService.getShifts(
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      print('Error fetching shifts: $e');
      return _getMockShifts();
    }
  }

  /// Get shift details
  Future<Map<String, dynamic>> getShiftDetails(String shiftId) async {
    try {
      return await _supabaseService.getShiftDetails(shiftId);
    } catch (e) {
      print('Error fetching shift details: $e');
      return {};
    }
  }

  /// Mock shift data
  List<Map<String, dynamic>> _getMockShifts() {
    return [
      {
        "id": "shift_001",
        "date": "11/22/2025",
        "shift_type": "Morning",
        "duration": "8h 00m",
        "production": "12,450 units",
        "efficiency": "92%",
        "alert_count": 3,
        "status": "normal",
      },
      {
        "id": "shift_002",
        "date": "11/22/2025",
        "shift_type": "Afternoon",
        "duration": "8h 00m",
        "production": "11,890 units",
        "efficiency": "88%",
        "alert_count": 5,
        "status": "warning",
      },
      {
        "id": "shift_003",
        "date": "11/22/2025",
        "shift_type": "Night",
        "duration": "8h 00m",
        "production": "10,230 units",
        "efficiency": "76%",
        "alert_count": 8,
        "status": "critical",
      },
    ];
  }
}
