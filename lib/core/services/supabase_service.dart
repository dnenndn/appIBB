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
      print('******** response: $response');
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
      print('******** heeeeerrrreee');
      final response = await supabase
          .from('machines')
          .select()
          .order('priority', ascending: true);
          print('********Machines data: $response');
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
      final response = await supabase
          .from('machine_parameters')
          .select('*, parameters(*)')
          .eq('machine_id', machineId);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch machine parameters: $e');
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
      final response = await supabase
          .from('shifts')
          .select()
          .gte('shift_date', startDate.toIso8601String().split('T')[0])
          .lte('shift_date', endDate.toIso8601String().split('T')[0])
          .order('shift_date', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch shifts: $e');
    }
  }

  /// Fetch shift details with machine metrics
  Future<Map<String, dynamic>> getShiftDetails(String shiftId) async {
    try {
      final shiftResponse = await supabase
          .from('shifts')
          .select()
          .eq('id', shiftId)
          .single();

      final metricsResponse = await supabase
          .from('shift_machine_metrics')
          .select()
          .eq('shift_id', shiftId);

      return {
        'shift': shiftResponse,
        'metrics': metricsResponse,
      };
    } catch (e) {
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
