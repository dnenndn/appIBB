import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Supabase Service - Centralized database and authentication management
/// 
/// This service handles all Supabase operations including:
/// - Authentication (login, logout, session management)
/// - Machine data retrieval
/// - Alert management
/// - Shift and historical data
/// - Parameter and threshold management
class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();

  late SupabaseClient supabase;

  factory SupabaseService() {
    return _instance;
  }

  SupabaseService._internal();

  // Realtime subscription stream for machines table
  Stream<List<Map<String, dynamic>>> getMachinesStream() {
    return supabase
        .from('machines')
        .stream(primaryKey: ['id'])
        .map((list) => list.cast<Map<String, dynamic>>().toList());
  }

  /// Initialize Supabase connection
  /// Call this in main.dart during app startup
  Future<void> initialize({
    required String supabaseUrl,
    required String supabaseAnonKey,
  }) async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
    supabase = Supabase.instance.client;
   
  }

  // ========================================================================
  // AUTHENTICATION METHODS
  // ========================================================================

  /// Login user with email and password
  Future<AuthResponse> login(String email, String password) async {
    try {
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  /// Authenticate against the `users` table instead of Supabase Auth.
  /// Expects `users` table to have: id, email, password_hash, must_change_password, role
  /// Passwords are compared by SHA-256 hash of the provided password.
  /// Returns the user record map on success.
  Future<Map<String, dynamic>> loginWithUsersTable(
      String username, String password) async {
    try {
      final response = await supabase
          .from('users')
          .select()
          .eq('username', username)
          .maybeSingle();
      if (response == null) {
        throw Exception('User not found');
      }

      final Map<String, dynamic> user = Map<String, dynamic>.from(response);

      final storedHash = (user['password_hash'] ?? '') as String;
      final inputHash = sha256.convert(utf8.encode(password)).toString();

  
      if (storedHash.isEmpty || storedHash != inputHash) {
        throw Exception('Invalid credentials');
      }

      return user;
    } catch (e) {
      throw Exception('User login failed: $e');
    }
  }

  /// Change a user's password in the `users` table and clear the must_change_password flag.
  Future<void> changeUserPassword(String userId, String newPassword) async {
    try {
      final newHash = sha256.convert(utf8.encode(newPassword)).toString();
      await supabase.from('users').update({
        'password_hash': newHash,
        'must_change_password': false,
        'last_updated': DateTime.now().toIso8601String(),
      }).eq('id', userId);
    } catch (e) {
      throw Exception('Failed to change password: $e');
    }
  }

  /// Logout current user
  Future<void> logout() async {
    try {
      await supabase.auth.signOut();
    } catch (e) {
      throw Exception('Logout failed: $e');
    }
  }

  /// Get current authenticated user
  User? getCurrentUser() {
    return supabase.auth.currentUser;
  }

  /// Check if user is authenticated
  bool isAuthenticated() {
    return supabase.auth.currentUser != null;
  }

  // ========================================================================
  // MACHINE METHODS
  // ========================================================================

  /// Fetch all machines with current status
  Future<List<Map<String, dynamic>>> getAllMachines() async {
    try {
      final response = await supabase
          .from('machines')
          .select()
          .order('priority', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch machines: $e');
    }
  }

  /// Fetch specific machine by ID
  Future<Map<String, dynamic>> getMachineById(String machineId) async {
    try {
      final response =
          await supabase.from('machines').select().eq('id', machineId).single();
      return response;
    } catch (e) {
      throw Exception('Failed to fetch machine: $e');
    }
  }

  /// Get machine parameters and current values
  Future<List<Map<String, dynamic>>> getMachineParameters(
      String machineId) async {
    try {
      print('Supabase: Attempting to fetch machine parameters for machine ID: $machineId');
      
      // First, try to fetch without the join to see if rows exist
      final simpleResponse = await supabase
          .from('machine_parameters')
          .select()
          .eq('machine_id', machineId);
      print('Supabase: Found ${simpleResponse.length} rows in machine_parameters for machine $machineId');
      
      if (simpleResponse.isEmpty) {
        print('Supabase: No rows found for machine_id: $machineId');
        print('Supabase: Checking if table is accessible and what machine_ids exist...');
        
        // Try to fetch all rows to check if table is accessible
        try {
          final allRows = await supabase.from('machine_parameters').select('machine_id').limit(10);
          print('Supabase: Table is accessible. Found ${allRows.length} total rows (sample)');
          
          if (allRows.isEmpty) {
            print('');
            print('⚠️  RLS POLICY ISSUE DETECTED ⚠️');
            print('The table is accessible but returns 0 rows even without filters.');
            print('This usually means Row Level Security (RLS) is blocking access.');
            print('');
            print('SOLUTION: Run the RLS setup script in Supabase SQL Editor:');
            print('  1. Open Supabase Dashboard → SQL Editor');
            print('  2. Run: SUPABASE_RLS_POLICIES_SETUP.sql');
            print('  3. See RLS_FIX_GUIDE.md for detailed instructions');
            print('');
          } else {
            final uniqueMachineIds = allRows.map((r) => r['machine_id']).toSet();
            print('Supabase: Sample machine_ids in table: $uniqueMachineIds');
            print('Supabase: Looking for machine_id: "$machineId" (type: ${machineId.runtimeType})');
            print('Supabase: Case-sensitive match: ${uniqueMachineIds.contains(machineId)}');
            
            if (!uniqueMachineIds.contains(machineId)) {
              print('⚠️  Machine ID mismatch detected!');
              print('The machine_id "$machineId" does not exist in the table.');
              print('Available machine_ids: $uniqueMachineIds');
            }
          }
        } catch (e) {
          print('Supabase: Error accessing machine_parameters table: $e');
          print('This might indicate a permission or connection issue.');
        }
        
        return [];
      }
      
      // Now try with the join - but handle cases where foreign key might not be set up
      print('Supabase: Attempting to fetch with parameters join...');
      List<Map<String, dynamic>> response;
      
      try {
        // Try the foreign key join syntax
        response = await supabase
            .from('machine_parameters')
            .select('*, parameters(*)')
            .eq('machine_id', machineId);
        print('Supabase: Successfully fetched ${response.length} machine parameters with join');
        
        // Check if ALL parameters are null (foreign key relationship might not be set up)
        final allNullParameters = response.isNotEmpty && response.every((r) => r['parameters'] == null);
        if (allNullParameters) {
          print('Supabase: All parameters are null in join result, foreign key relationship may not be configured');
          print('Supabase: Using manual join fallback to fetch parameters separately');
          throw Exception('All parameters null in join - using fallback');
        } else if (response.any((r) => r['parameters'] == null)) {
          print('Supabase: Warning - some parameters are null in join result');
        }
      } catch (joinError) {
        print('Supabase: Join failed with error: $joinError');
        print('Supabase: This might indicate the foreign key relationship is not configured in Supabase');
        print('Supabase: Fetching parameters separately...');
        
        // Fallback: fetch parameters separately and merge
        final machineParams = await supabase
            .from('machine_parameters')
            .select()
            .eq('machine_id', machineId);
        
        if (machineParams.isEmpty) {
          return [];
        }
        
        // Get all parameter IDs
        final paramIds = machineParams
            .map((mp) => mp['parameter_id'] as String)
            .where((id) => id != null)
            .toSet()
            .toList();
        
        if (paramIds.isEmpty) {
          return List<Map<String, dynamic>>.from(machineParams);
        }
        
        // Fetch parameters - fetch all and filter in memory (simple and reliable)
        print('Supabase: Fetching parameters for IDs: $paramIds');
        final allParams = await supabase.from('parameters').select();
        final parameters = allParams.where((p) => paramIds.contains(p['id'])).toList();
        print('Supabase: Found ${parameters.length} matching parameters out of ${allParams.length} total');
        
        // Create a map for quick lookup
        final paramMap = {for (var p in parameters) p['id']: p};
        
        // Merge the data
        response = machineParams.map((mp) {
          final paramId = mp['parameter_id'] as String;
          return {
            ...mp,
            'parameters': paramMap[paramId],
          };
        }).toList();
        
        print('Supabase: Successfully merged ${response.length} machine parameters with manual join');
      }
      
      // Log first result structure if available
      if (response.isNotEmpty) {
        print('Supabase: First parameter structure keys: ${response[0].keys}');
        if (response[0].containsKey('parameters')) {
          print('Supabase: Parameters object type: ${response[0]['parameters'].runtimeType}');
        }
      }
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      // Log the specific error for debugging
      print('Supabase error in getMachineParameters for machine $machineId: $e');
      print('Error type: ${e.runtimeType}');
      print('Error details: ${e.toString()}');
      
      // Re-throw with more context
      throw Exception('Failed to fetch machine parameters for machine $machineId: $e');
    }
  }

  /// Update machine status
  Future<void> updateMachineStatus(String machineId, String status) async {
    try {
      await supabase
          .from('machines')
          .update({'status': status})
          .eq('id', machineId);
    } catch (e) {
      throw Exception('Failed to update machine status: $e');
    }
  }

  /// Update machine parameter value
  Future<void> updateMachineParameter(
    String machineId,
    String parameterId,
    double value,
  ) async {
    try {
      await supabase.from('machine_parameters').update({
        'current_value': value,
        'last_updated': DateTime.now().toIso8601String(),
      }).match({
        'machine_id': machineId,
        'parameter_id': parameterId,
      });
    } catch (e) {
      throw Exception('Failed to update machine parameter: $e');
    }
  }

  // ========================================================================
  // ALERT METHODS
  // ========================================================================

  /// Fetch all active alerts
  Future<List<Map<String, dynamic>>> getActiveAlerts() async {
    try {
      final response = await supabase
          .from('alerts')
          .select()
          .eq('is_resolved', false)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch alerts: $e');
    }
  }

  /// Fetch alerts for specific machine
  Future<List<Map<String, dynamic>>> getMachineAlerts(String machineId) async {
    try {
      final response = await supabase
          .from('alerts')
          .select()
          .eq('machine_id', machineId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch machine alerts: $e');
    }
  }

  /// Get alerts by type (critical, warning, status)
  Future<List<Map<String, dynamic>>> getAlertsByType(String type) async {
    try {
      final response = await supabase
          .from('alerts')
          .select()
          .eq('type', type)
          .eq('is_resolved', false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch alerts by type: $e');
    }
  }

  /// Create new alert
  Future<void> createAlert(Map<String, dynamic> alertData) async {
    try {
      await supabase.from('alerts').insert(alertData);
    } catch (e) {
      throw Exception('Failed to create alert: $e');
    }
  }

  /// Resolve alert
  Future<void> resolveAlert(String alertId) async {
    try {
      await supabase.from('alerts').update({
        'is_resolved': true,
        'resolved_at': DateTime.now().toIso8601String(),
      }).eq('id', alertId);
    } catch (e) {
      throw Exception('Failed to resolve alert: $e');
    }
  }

  // ========================================================================
  // SHIFT METHODS
  // ========================================================================

  /// Fetch shifts for date range
  Future<List<Map<String, dynamic>>> getShifts({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      print('Supabase: Fetching shifts from ${startDate.toIso8601String().split('T')[0]} to ${endDate.toIso8601String().split('T')[0]}');
      
      // First, check what dates actually exist in the table
      try {
        final allShiftsSample = await supabase
            .from('shifts')
            .select('shift_date, id')
            .order('shift_date', ascending: false)
            .limit(10);
        print('Supabase: Sample shifts in table (first 10):');
        if (allShiftsSample.isNotEmpty) {
          for (var shift in allShiftsSample) {
            print('  - Shift ${shift['id']}: date = ${shift['shift_date']} (type: ${shift['shift_date'].runtimeType})');
          }
        } else {
          print('  - No shifts found in table at all');
        }
      } catch (e) {
        print('Supabase: Could not check sample shifts: $e');
      }
      
      final startDateStr = startDate.toIso8601String().split('T')[0];
      final endDateStr = endDate.toIso8601String().split('T')[0];
      
      print('Supabase: Querying with date range: $startDateStr to $endDateStr');
      
      final response = await supabase
          .from('shifts')
          .select()
          .gte('shift_date', startDateStr)
          .lte('shift_date', endDateStr)
          .order('shift_date', ascending: false);
      
      print('Supabase: Successfully fetched ${response.length} shifts');
      
      // If no results, try without date filter to see if there's any data
      if (response.isEmpty) {
        print('Supabase: No shifts found in date range, checking total count...');
        try {
          final allShifts = await supabase.from('shifts').select('id');
          print('Supabase: Total shifts in table: ${allShifts.length}');
          if (allShifts.isNotEmpty) {
            print('Supabase: Available shift dates:');
            final dates = await supabase.from('shifts').select('shift_date').order('shift_date');
            final uniqueDates = (dates as List).map((d) => d['shift_date']).toSet();
            print('Supabase: Unique dates in table: $uniqueDates');
          }
        } catch (e) {
          print('Supabase: Could not get total count: $e');
        }
      }
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Supabase: Error fetching shifts: $e');
      print('Error type: ${e.runtimeType}');
      throw Exception('Failed to fetch shifts: $e');
    }
  }

  /// Fetch shift details with machine metrics
  Future<Map<String, dynamic>> getShiftDetails(String shiftId) async {
    try {
      print('Supabase: Fetching shift details for shift ID: $shiftId');
      
      final shiftResponse = await supabase
          .from('shifts')
          .select()
          .eq('id', shiftId)
          .single();

      final metricsResponse = await supabase
          .from('shift_machine_metrics')
          .select()
          .eq('shift_id', shiftId);

      print('Supabase: Successfully fetched shift details with ${metricsResponse.length} machine metrics');
      
      return {
        'shift': shiftResponse,
        'metrics': List<Map<String, dynamic>>.from(metricsResponse),
      };
    } catch (e) {
      print('Supabase: Error fetching shift details: $e');
      print('Error type: ${e.runtimeType}');
      throw Exception('Failed to fetch shift details: $e');
    }
  }

  // ========================================================================
  // PARAMETER & THRESHOLD METHODS
  // ========================================================================

  /// Fetch all parameters
  Future<List<Map<String, dynamic>>> getAllParameters() async {
    try {
      final response = await supabase.from('parameters').select();
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch parameters: $e');
    }
  }

  /// Fetch thresholds for machine
  Future<List<Map<String, dynamic>>> getMachineThresholds(
      String machineId) async {
    try {
      final response = await supabase
          .from('parameter_thresholds')
          .select('*, parameters(*)')
          .eq('machine_id', machineId)
          .eq('is_active', true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch thresholds: $e');
    }
  }

  /// Update threshold
  Future<void> updateThreshold({
    required String thresholdId,
    required double minThreshold,
    required double maxThreshold,
  }) async {
    try {
      await supabase.from('parameter_thresholds').update({
        'min_threshold': minThreshold,
        'max_threshold': maxThreshold,
        'last_updated': DateTime.now().toIso8601String(),
      }).eq('id', thresholdId);
    } catch (e) {
      throw Exception('Failed to update threshold: $e');
    }
  }

  // ========================================================================
  // REAL-TIME SUBSCRIPTIONS
  // ========================================================================

  // REAL-TIME SUBSCRIPTIONS

  /// Subscribe to machine status changes.
  /// Returns the created `RealtimeChannel` so the caller can unsubscribe later.
  void subscribeMachineChanges(
      String machineId, Function(Map<String, dynamic>) onUpdate) {
    // Create a channel for the machine; listeners are not attached here to avoid
    // depending on specific realtime helper signatures that vary between
    // package versions. Callers can still receive updates via other means.
    supabase.channel('machines:$machineId').subscribe();
  }

  /// Subscribe to alert insert events.
  /// Returns the created `RealtimeChannel` so the caller can unsubscribe later.
  void subscribeAlerts(Function(Map<String, dynamic>) onNewAlert) {
    // Create a channel for alerts. No event handler is attached here to keep
    // compatibility with the installed realtime client version.
    supabase.channel('alerts').subscribe();
  }

  /// Unsubscribe from channel by name
  Future<void> unsubscribeChannel(String channelName) async {
    await supabase.removeChannel(supabase.channel(channelName));
  }
}
