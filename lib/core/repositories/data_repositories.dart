import '../../core/services/supabase_service.dart';

/// Repository Pattern for Data Management
/// 
/// This class provides a clean abstraction layer between the UI and Supabase,
/// making it easier to switch data sources or add caching logic later.

class MachineRepository {
  final SupabaseService _supabaseService = SupabaseService();

  /// Get all machines with fallback to mock data
  Future<List<Map<String, dynamic>>> getAllMachines({
    bool useMockDataOnError = false,
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
        orElse: () => mockMachines.first,
      );
    }
  }

  /// Get machine parameters
  Future<List<Map<String, dynamic>>> getMachineParameters(
      String machineId) async {
    try {
      print('Attempting to fetch parameters for machine: $machineId');
      final result = await _supabaseService.getMachineParameters(machineId);
      print('Successfully fetched ${result.length} parameters for machine $machineId');
      
      // If we got data from Supabase (even if empty), return it - don't use mock data
      if (result.isNotEmpty) {
        print('Using real Supabase data - ${result.length} parameters');
        print('First parameter structure: ${result[0]}');
        return result;
      } else {
        print('No parameters found in Supabase for machine $machineId');
        print('This could mean:');
        print('  1. No data exists for this machine_id in the database');
        print('  2. RLS policies are still blocking access');
        print('  3. The machine_id does not match any records');
        // Return empty list instead of mock data when Supabase returns empty
        // This allows the UI to show "No parameters" instead of fake data
        return [];
      }
    } catch (e) {
      print('❌ Error fetching machine parameters for machine $machineId: $e');
      print('Error type: ${e.runtimeType}');
      print('Stack trace: ${StackTrace.current}');
      
      // Check if it's a specific Supabase/Postgrest error
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('permission denied') || 
          errorString.contains('unauthorized') ||
          errorString.contains('row-level security')) {
        print('⚠️  Permission denied error detected - RLS might still be blocking access');
        print('SOLUTION: Make sure you ran SUPABASE_RLS_POLICIES_SETUP.sql');
        print('          Check that policies exist for machine_parameters and parameters tables');
      }
      
      // Only return mock data as a last resort when there's a connection/error issue
      // NOT when we successfully connected but got no data
      print('⚠️  Falling back to mock data due to error (not empty result)');
      final mockParams = _getMockMachineParameters(machineId);
      print('Falling back to ${mockParams.length} mock parameters for machine $machineId');
      
      if (mockParams.isNotEmpty) {
        print('First mock parameter structure: ${mockParams[0]}');
      }
      
      return mockParams;
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

  /// Mock data for machine parameters
  List<Map<String, dynamic>> _getMockMachineParameters(String machineId) {
    // Return mock parameters based on the machine ID
    switch (machineId) {
      case 'kiln_01':
        return [
          {
            'parameters': {
              'id': 'param_001',
              'name': 'Burner Temperature',
              'unit': '°C',
              'parameter_type': 'temperature',
              'min_value': 0.0,
              'max_value': 1300.0,
              'is_critical': true,
            },
            'current_value': 1150.0,
            'previous_value': 1145.0,
            'last_updated': DateTime.now().toIso8601String(),
          },
          {
            'parameters': {
              'id': 'param_005',
              'name': 'Production Rate',
              'unit': 'units/hour',
              'parameter_type': 'production',
              'min_value': 0.0,
              'max_value': 2000.0,
              'is_critical': false,
            },
            'current_value': 245.8,
            'previous_value': 242.5,
            'last_updated': DateTime.now().toIso8601String(),
          },
          {
            'parameters': {
              'id': 'param_009',
              'name': 'Flow Rate',
              'unit': 'm³/h',
              'parameter_type': 'flow',
              'min_value': 0.0,
              'max_value': 200.0,
              'is_critical': false,
            },
            'current_value': 85.3,
            'previous_value': 84.7,
            'last_updated': DateTime.now().toIso8601String(),
          },
          {
            'parameters': {
              'id': 'param_008',
              'name': 'Efficiency',
              'unit': '%',
              'parameter_type': 'production',
              'min_value': 0.0,
              'max_value': 100.0,
              'is_critical': false,
            },
            'current_value': 92.5,
            'previous_value': 91.8,
            'last_updated': DateTime.now().toIso8601String(),
          },
          {
            'parameters': {
              'id': 'param_010',
              'name': 'Energy Consumption',
              'unit': 'kW',
              'parameter_type': 'energy',
              'min_value': 0.0,
              'max_value': 500.0,
              'is_critical': false,
            },
            'current_value': 245.6,
            'previous_value': 240.3,
            'last_updated': DateTime.now().toIso8601String(),
          },
        ];
      case 'kiln_02':
        return [
          {
            'parameters': {
              'id': 'param_001',
              'name': 'Burner Temperature',
              'unit': '°C',
              'parameter_type': 'temperature',
              'min_value': 0.0,
              'max_value': 1300.0,
              'is_critical': true,
            },
            'current_value': 1175.0,
            'previous_value': 1170.0,
            'last_updated': DateTime.now().toIso8601String(),
          },
          {
            'parameters': {
              'id': 'param_005',
              'name': 'Production Rate',
              'unit': 'units/hour',
              'parameter_type': 'production',
              'min_value': 0.0,
              'max_value': 2000.0,
              'is_critical': false,
            },
            'current_value': 268.4,
            'previous_value': 265.1,
            'last_updated': DateTime.now().toIso8601String(),
          },
          {
            'parameters': {
              'id': 'param_009',
              'name': 'Flow Rate',
              'unit': 'm³/h',
              'parameter_type': 'flow',
              'min_value': 0.0,
              'max_value': 200.0,
              'is_critical': false,
            },
            'current_value': 92.1,
            'previous_value': 91.5,
            'last_updated': DateTime.now().toIso8601String(),
          },
          {
            'parameters': {
              'id': 'param_008',
              'name': 'Efficiency',
              'unit': '%',
              'parameter_type': 'production',
              'min_value': 0.0,
              'max_value': 100.0,
              'is_critical': false,
            },
            'current_value': 94.2,
            'previous_value': 93.7,
            'last_updated': DateTime.now().toIso8601String(),
          },
          {
            'parameters': {
              'id': 'param_010',
              'name': 'Energy Consumption',
              'unit': 'kW',
              'parameter_type': 'energy',
              'min_value': 0.0,
              'max_value': 500.0,
              'is_critical': false,
            },
            'current_value': 312.5,
            'previous_value': 308.2,
            'last_updated': DateTime.now().toIso8601String(),
          },
        ];
      case 'kiln_03':
        return [
          {
            'parameters': {
              'id': 'param_001',
              'name': 'Burner Temperature',
              'unit': '°C',
              'parameter_type': 'temperature',
              'min_value': 0.0,
              'max_value': 1300.0,
              'is_critical': true,
            },
            'current_value': 980.0,
            'previous_value': 985.0,
            'last_updated': DateTime.now().toIso8601String(),
          },
          {
            'parameters': {
              'id': 'param_005',
              'name': 'Production Rate',
              'unit': 'units/hour',
              'parameter_type': 'production',
              'min_value': 0.0,
              'max_value': 2000.0,
              'is_critical': false,
            },
            'current_value': 301.2,
            'previous_value': 298.7,
            'last_updated': DateTime.now().toIso8601String(),
          },
          {
            'parameters': {
              'id': 'param_009',
              'name': 'Flow Rate',
              'unit': 'm³/h',
              'parameter_type': 'flow',
              'min_value': 0.0,
              'max_value': 200.0,
              'is_critical': false,
            },
            'current_value': 78.9,
            'previous_value': 79.3,
            'last_updated': DateTime.now().toIso8601String(),
          },
          {
            'parameters': {
              'id': 'param_008',
              'name': 'Efficiency',
              'unit': '%',
              'parameter_type': 'production',
              'min_value': 0.0,
              'max_value': 100.0,
              'is_critical': false,
            },
            'current_value': 88.7,
            'previous_value': 89.1,
            'last_updated': DateTime.now().toIso8601String(),
          },
          {
            'parameters': {
              'id': 'param_010',
              'name': 'Energy Consumption',
              'unit': 'kW',
              'parameter_type': 'energy',
              'min_value': 0.0,
              'max_value': 500.0,
              'is_critical': false,
            },
            'current_value': 198.3,
            'previous_value': 201.5,
            'last_updated': DateTime.now().toIso8601String(),
          },
        ];
      case 'dryer_01':
        return [
          {
            'parameters': {
              'id': 'param_001',
              'name': 'Burner Temperature',
              'unit': '°C',
              'parameter_type': 'temperature',
              'min_value': 0.0,
              'max_value': 1300.0,
              'is_critical': true,
            },
            'current_value': 142.0,
            'previous_value': 140.5,
            'last_updated': DateTime.now().toIso8601String(),
          },
          {
            'parameters': {
              'id': 'param_005',
              'name': 'Production Rate',
              'unit': 'units/hour',
              'parameter_type': 'production',
              'min_value': 0.0,
              'max_value': 2000.0,
              'is_critical': false,
            },
            'current_value': 289.5,
            'previous_value': 287.3,
            'last_updated': DateTime.now().toIso8601String(),
          },
          {
            'parameters': {
              'id': 'param_009',
              'name': 'Flow Rate',
              'unit': 'm³/h',
              'parameter_type': 'flow',
              'min_value': 0.0,
              'max_value': 200.0,
              'is_critical': false,
            },
            'current_value': 65.4,
            'previous_value': 64.8,
            'last_updated': DateTime.now().toIso8601String(),
          },
          {
            'parameters': {
              'id': 'param_008',
              'name': 'Efficiency',
              'unit': '%',
              'parameter_type': 'production',
              'min_value': 0.0,
              'max_value': 100.0,
              'is_critical': false,
            },
            'current_value': 91.3,
            'previous_value': 90.7,
            'last_updated': DateTime.now().toIso8601String(),
          },
          {
            'parameters': {
              'id': 'param_010',
              'name': 'Energy Consumption',
              'unit': 'kW',
              'parameter_type': 'energy',
              'min_value': 0.0,
              'max_value': 500.0,
              'is_critical': false,
            },
            'current_value': 156.2,
            'previous_value': 153.8,
            'last_updated': DateTime.now().toIso8601String(),
          },
        ];
      case 'dryer_02':
        return [
          {
            'parameters': {
              'id': 'param_001',
              'name': 'Burner Temperature',
              'unit': '°C',
              'parameter_type': 'temperature',
              'min_value': 0.0,
              'max_value': 1300.0,
              'is_critical': true,
            },
            'current_value': 165.0,
            'previous_value': 163.5,
            'last_updated': DateTime.now().toIso8601String(),
          },
          {
            'parameters': {
              'id': 'param_005',
              'name': 'Production Rate',
              'unit': 'units/hour',
              'parameter_type': 'production',
              'min_value': 0.0,
              'max_value': 2000.0,
              'is_critical': false,
            },
            'current_value': 312.5,
            'previous_value': 310.2,
            'last_updated': DateTime.now().toIso8601String(),
          },
          {
            'parameters': {
              'id': 'param_009',
              'name': 'Flow Rate',
              'unit': 'm³/h',
              'parameter_type': 'flow',
              'min_value': 0.0,
              'max_value': 200.0,
              'is_critical': false,
            },
            'current_value': 48.2,
            'previous_value': 49.1,
            'last_updated': DateTime.now().toIso8601String(),
          },
          {
            'parameters': {
              'id': 'param_008',
              'name': 'Efficiency',
              'unit': '%',
              'parameter_type': 'production',
              'min_value': 0.0,
              'max_value': 100.0,
              'is_critical': false,
            },
            'current_value': 87.5,
            'previous_value': 88.2,
            'last_updated': DateTime.now().toIso8601String(),
          },
          {
            'parameters': {
              'id': 'param_010',
              'name': 'Energy Consumption',
              'unit': 'kW',
              'parameter_type': 'energy',
              'min_value': 0.0,
              'max_value': 500.0,
              'is_critical': false,
            },
            'current_value': 287.9,
            'previous_value': 290.1,
            'last_updated': DateTime.now().toIso8601String(),
          },
        ];
      case 'dryer_03':
        return [
          {
            'parameters': {
              'id': 'param_001',
              'name': 'Burner Temperature',
              'unit': '°C',
              'parameter_type': 'temperature',
              'min_value': 0.0,
              'max_value': 1300.0,
              'is_critical': true,
            },
            'current_value': 155.0,
            'previous_value': 153.8,
            'last_updated': DateTime.now().toIso8601String(),
          },
          {
            'parameters': {
              'id': 'param_005',
              'name': 'Production Rate',
              'unit': 'units/hour',
              'parameter_type': 'production',
              'min_value': 0.0,
              'max_value': 2000.0,
              'is_critical': false,
            },
            'current_value': 275.6,
            'previous_value': 273.4,
            'last_updated': DateTime.now().toIso8601String(),
          },
          {
            'parameters': {
              'id': 'param_009',
              'name': 'Flow Rate',
              'unit': 'm³/h',
              'parameter_type': 'flow',
              'min_value': 0.0,
              'max_value': 200.0,
              'is_critical': false,
            },
            'current_value': 95.8,
            'previous_value': 94.6,
            'last_updated': DateTime.now().toIso8601String(),
          },
          {
            'parameters': {
              'id': 'param_008',
              'name': 'Efficiency',
              'unit': '%',
              'parameter_type': 'production',
              'min_value': 0.0,
              'max_value': 100.0,
              'is_critical': false,
            },
            'current_value': 93.8,
            'previous_value': 93.2,
            'last_updated': DateTime.now().toIso8601String(),
          },
          {
            'parameters': {
              'id': 'param_010',
              'name': 'Energy Consumption',
              'unit': 'kW',
              'parameter_type': 'energy',
              'min_value': 0.0,
              'max_value': 500.0,
              'is_critical': false,
            },
            'current_value': 98.5,
            'previous_value': 96.7,
            'last_updated': DateTime.now().toIso8601String(),
          },
        ];
      default:
        // Return some default parameters for other machines
        return [
          {
            'parameters': {
              'id': 'param_001',
              'name': 'Burner Temperature',
              'unit': '°C',
              'parameter_type': 'temperature',
              'min_value': 0.0,
              'max_value': 1300.0,
              'is_critical': true,
            },
            'current_value': 1150.0,
            'previous_value': 1145.0,
            'last_updated': DateTime.now().toIso8601String(),
          },
          {
            'parameters': {
              'id': 'param_005',
              'name': 'Production Rate',
              'unit': 'units/hour',
              'parameter_type': 'production',
              'min_value': 0.0,
              'max_value': 2000.0,
              'is_critical': false,
            },
            'current_value': 245.8,
            'previous_value': 242.5,
            'last_updated': DateTime.now().toIso8601String(),
          },
        ];
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
      print('ShiftRepository: Fetching shifts from Supabase for date range: $startDate to $endDate');
      final shifts = await _supabaseService.getShifts(
        startDate: startDate,
        endDate: endDate,
      );
      print('ShiftRepository: Successfully fetched ${shifts.length} shifts from Supabase');
      
      // If we got data from Supabase (even if empty), return it - don't use mock data
      if (shifts.isNotEmpty) {
        print('ShiftRepository: Using real Supabase data - ${shifts.length} shifts');
        return shifts;
      } else {
        print('ShiftRepository: No shifts found in Supabase for the selected date range');
        print('ShiftRepository: This could mean:');
        print('  1. No data exists for this date range in the database');
        print('  2. RLS policies are still blocking access');
        print('  3. The date format or query is incorrect');
        // Return empty list instead of mock data when Supabase returns empty
        return [];
      }
    } catch (e) {
      print('❌ ShiftRepository: Error fetching shifts: $e');
      print('Error type: ${e.runtimeType}');
      
      // Check if it's a specific Supabase/Postgrest error
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('permission denied') || 
          errorString.contains('unauthorized') ||
          errorString.contains('row-level security')) {
        print('⚠️  Permission denied error detected - RLS might still be blocking access');
        print('SOLUTION: Make sure you ran SUPABASE_RLS_POLICIES_SETUP.sql');
        print('          Check that policies exist for shifts and shift_machine_metrics tables');
      }
      
      // Only return mock data as a last resort when there's a connection/error issue
      print('⚠️  Falling back to mock data due to error (not empty result)');
      return _getMockShifts();
    }
  }

  /// Get shift details
  Future<Map<String, dynamic>> getShiftDetails(String shiftId) async {
    try {
      print('ShiftRepository: Fetching shift details for shift ID: $shiftId');
      final details = await _supabaseService.getShiftDetails(shiftId);
      print('ShiftRepository: Successfully fetched shift details');
      return details;
    } catch (e) {
      print('❌ ShiftRepository: Error fetching shift details: $e');
      print('Error type: ${e.runtimeType}');
      
      // Only return mock data as a last resort when there's a connection/error issue
      print('⚠️  Falling back to mock data due to error');
      return {
        'shift': _getMockShifts().firstWhere(
          (s) => s['id'] == shiftId,
          orElse: () => _getMockShifts().first,
        ),
        'metrics': _getMockShiftMetrics(shiftId),
      };
    }
  }

  /// Mock shift data
  List<Map<String, dynamic>> _getMockShifts() {
    return [
      {
        'id': 'shift_001',
        'date': '2025-11-22',
        'shiftType': 'Morning',
        'status': 'normal',
        'duration': '8h',
        'production': '12,450 units',
        'efficiency': '92%',
        'alertCount': 3,
        'criticalAlerts': 0,
        'warningAlerts': 2,
        'infoAlerts': 1,
      },
      {
        'id': 'shift_002',
        'date': '2025-11-22',
        'shiftType': 'Afternoon',
        'status': 'warning',
        'duration': '8h',
        'production': '11,890 units',
        'efficiency': '88%',
        'alertCount': 5,
        'criticalAlerts': 1,
        'warningAlerts': 3,
        'infoAlerts': 1,
      },
      {
        'id': 'shift_003',
        'date': '2025-11-22',
        'shiftType': 'Night',
        'status': 'critical',
        'duration': '8h',
        'production': '10,230 units',
        'efficiency': '76%',
        'alertCount': 8,
        'criticalAlerts': 3,
        'warningAlerts': 4,
        'infoAlerts': 1,
      },
      {
        'id': 'shift_004',
        'date': '2025-11-21',
        'shiftType': 'Morning',
        'status': 'normal',
        'duration': '8h',
        'production': '12,680 units',
        'efficiency': '94%',
        'alertCount': 2,
        'criticalAlerts': 0,
        'warningAlerts': 1,
        'infoAlerts': 1,
      },
      {
        'id': 'shift_005',
        'date': '2025-11-21',
        'shiftType': 'Afternoon',
        'status': 'normal',
        'duration': '8h',
        'production': '12,340 units',
        'efficiency': '91%',
        'alertCount': 2,
        'criticalAlerts': 0,
        'warningAlerts': 1,
        'infoAlerts': 1,
      },
    ];
  }

  /// Mock shift metrics data
  List<Map<String, dynamic>> _getMockShiftMetrics(String shiftId) {
    return [
      {
        'machineId': 'kiln_01',
        'machineName': 'Kiln 1',
        'efficiency': 94,
        'downtime': '2 min',
        'production': '4,150 units',
        'status': 'normal',
      },
      {
        'machineId': 'kiln_02',
        'machineName': 'Kiln 2',
        'efficiency': 90,
        'downtime': '5 min',
        'production': '4,100 units',
        'status': 'normal',
      },
      {
        'machineId': 'dryer_01',
        'machineName': 'Dryer 1',
        'efficiency': 92,
        'downtime': '3 min',
        'production': '4,200 units',
        'status': 'normal',
      },
    ];
  }
}