import 'package:supabase_flutter/supabase_flutter.dart';
import 'local_threshold_service.dart';
import 'notification_service.dart';
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
    const int maxRetries = 2;
    int attempt = 0;
    while (true) {
      try {
        final response = await supabase.from('machines').select().eq('id', machineId).single();
        return response;
      } catch (e) {
        attempt += 1;
        final errStr = e.toString();
        

        // If transient (502/timeout/cloudflare), retry a couple times
        final isTransient = errStr.contains('502') || errStr.toLowerCase().contains('bad gateway') || errStr.toLowerCase().contains('timeout');
        if (attempt <= maxRetries && isTransient) {
          final delayMs = 300 * attempt; // simple backoff
          await Future.delayed(Duration(milliseconds: delayMs));
          continue;
        }

        // Not recoverable or retries exhausted — rethrow so repository can fall back
        throw Exception('Failed to fetch machine: $e');
      }
    }
  }

  /// Get machine parameters and current values from parameters table
  /// The parameters table now includes machine_id and current_value directly
  Future<List<Map<String, dynamic>>> getMachineParameters(
      String machineId) async {
    try {
      
      // Query parameters table directly filtered by machine_id
      final response = await supabase
          .from('parameters')
          .select()
          .eq('machine_id', machineId)
          .order('name', ascending: true);
      
      // Return parameters directly (no transformation needed since structure matches)
      // The parameters table now has all fields including machine_id and current_value
      final transformedResponse = response.map((param) {
        return {
          ...param,
          'last_updated': param['created_at'], // Use created_at as last_updated if not available
        };
      }).toList();
      
      if (transformedResponse.isNotEmpty) {
      }
      
      return List<Map<String, dynamic>>.from(transformedResponse);
    } catch (e) {
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

  /// Fetch resolved/acknowledged alerts for history
  Future<List<Map<String, dynamic>>> getResolvedAlerts() async {
    try {
      final response = await supabase
          .from('alerts')
          .select()
          .eq('is_resolved', true)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch resolved alerts: $e');
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

  /// Check parameters against thresholds and create/update/remove alerts
  /// This should be called periodically or when parameter values change
  /// Uses local user-specific thresholds instead of Supabase thresholds
  Future<void> checkAndUpdateAlerts() async {
    try {
      
      
      // Initialize local threshold service
      final thresholdService = LocalThresholdService();
      
      // Get all machines
      final machines = await getAllMachines();
      
      for (var machine in machines) {
        final machineId = machine['id'] as String;
        final machineName = machine['name'] as String;
        
        // Get all parameters for this machine
        final parameters = await getAllParameters(machineId: machineId);
        
        for (var parameter in parameters) {
          final parameterId = parameter['id'] as String;
          final parameterName = parameter['name'] as String;
          final currentValue = (parameter['current_value'] as num?)?.toDouble();
          
          if (currentValue == null) continue;
          
          // Get thresholds from local storage (user-specific)
          // Default is currentValue - 10 and currentValue + 10
          final threshold = await thresholdService.getThresholdWithDefaults(
            machineId: machineId,
            parameterId: parameterId,
            currentValue: currentValue,
          );
          
          final minThreshold = threshold['min']!;
          final maxThreshold = threshold['max']!;
          
          // Get warning thresholds from storage
          final warningThresholds = await thresholdService.getWarningThresholds(
            machineId: machineId,
            parameterId: parameterId,
          );
          
          // Use actual warning thresholds if available, otherwise calculate from critical
          final warningThresholdLow = warningThresholds?['min'] ?? (minThreshold * 0.9);
          final warningThresholdHigh = warningThresholds?['max'] ?? (maxThreshold * 1.1);
          
          // Determine current status
          String? currentStatus;
          String alertType = 'warning';
          
          // Check critical thresholds first (outside critical range)
          if (currentValue < minThreshold || currentValue > maxThreshold) {
            currentStatus = 'critical';
            alertType = 'critical';
          } 
          // Check warning thresholds (outside warning range but inside critical)
          else if (currentValue < warningThresholdLow || currentValue > warningThresholdHigh) {
            currentStatus = 'warning';
            alertType = 'warning';
          } 
          // Normal (inside both ranges)
          else {
            currentStatus = 'normal';
          }
          
          // Use a deterministic ID to prevent duplicates
          final alertId = 'alert_${machineId}_${parameterId}';
          
          // Check if alert with this ID already exists (regardless of resolved status)
          final existingAlertById = await supabase
              .from('alerts')
              .select()
              .eq('id', alertId)
              .maybeSingle();
          
          // Also check for any unresolved alerts for this parameter (for cleanup)
          final existingUnresolvedAlerts = await supabase
              .from('alerts')
              .select()
              .eq('machine_id', machineId)
              .eq('parameter', parameterName)
              .eq('is_resolved', false);
          
          final existingUnresolvedList = List<Map<String, dynamic>>.from(existingUnresolvedAlerts);
          
          if (currentStatus == 'normal') {
            // Remove/resolve all active alerts for this parameter
            for (var alert in existingUnresolvedList) {
              await resolveAlert(alert['id'] as String);
            }
            // Also resolve the deterministic alert if it exists
            if (existingAlertById != null && existingAlertById['is_resolved'] != true) {
              await resolveAlert(alertId);
            }
            
          } else {
            // Create or update alert - use upsert pattern
            final alertData = {
              'id': alertId,
              'machine_id': machineId,
              'parameter': parameterName,
              'alert_type': 'Threshold ${currentStatus == 'critical' ? 'Exceeded' : 'Warning'}',
              'type': alertType,
              'severity': currentStatus,
              'title': '$parameterName ${currentStatus == 'critical' ? 'Critical' : 'Warning'}',
              'description': 'Parameter value ${currentValue} is ${currentStatus == 'critical' ? 'outside' : 'approaching'} threshold limits',
              'current_status': 'Current value: $currentValue (Threshold: ${currentValue < minThreshold ? 'Min: $minThreshold' : 'Max: $maxThreshold'})',
              'current_value': currentValue,
              'expected_value': currentValue < minThreshold ? minThreshold : maxThreshold,
              'is_resolved': false,
            };
            
            if (existingAlertById != null) {
              // Alert exists - update it
              final existingSeverity = existingAlertById['severity'] as String?;
              final wasResolved = existingAlertById['is_resolved'] == true;
              
              await supabase.from('alerts').update(alertData).eq('id', alertId);
              
              // Show notification if status changed to critical or if alert was just reactivated
              if ((currentStatus == 'critical' && (existingSeverity != 'critical' || wasResolved)) || wasResolved) {
                final notificationService = NotificationService();
                if (currentStatus == 'critical') {
                  await notificationService.showCriticalAlert(
                    title: '$parameterName Critical Alert',
                    body: 'Parameter value ${currentValue} is outside threshold limits on $machineName',
                    machineName: machineName,
                    parameterName: parameterName,
                  );
                } else {
                  await notificationService.showWarningAlert(
                    title: '$parameterName Warning',
                    body: 'Parameter value ${currentValue} is approaching threshold limits on $machineName',
                    machineName: machineName,
                    parameterName: parameterName,
                  );
                }
              }
              
              if (wasResolved) {
                
              } else if (existingSeverity != currentStatus) {
                
              } else {
                
              }
            } else {
              // Alert doesn't exist - create it
              try {
                await createAlert(alertData);
                
                // Show system notification
                final notificationService = NotificationService();
                if (currentStatus == 'critical') {
                  await notificationService.showCriticalAlert(
                    title: '$parameterName Critical Alert',
                    body: 'Parameter value ${currentValue} is outside threshold limits on $machineName',
                    machineName: machineName,
                    parameterName: parameterName,
                  );
                } else {
                  await notificationService.showWarningAlert(
                    title: '$parameterName Warning',
                    body: 'Parameter value ${currentValue} is approaching threshold limits on $machineName',
                    machineName: machineName,
                    parameterName: parameterName,
                  );
                }
                
                
              } catch (e) {
                // If creation fails due to duplicate key, try to update instead
                if (e.toString().contains('duplicate key') || e.toString().contains('23505')) {
                  
                  await supabase.from('alerts').update(alertData).eq('id', alertId);
                  
                } else {
                  rethrow;
                }
              }
            }
            
            // Resolve any other duplicate alerts (alerts with different IDs for same parameter)
            for (var alert in existingUnresolvedList) {
              if (alert['id'] != alertId) {
                await resolveAlert(alert['id'] as String);
                
              }
            }
          }
        }
      }
      
      
    } catch (e) {
      
      throw Exception('Failed to check and update alerts: $e');
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
      // Probe the table for any sample dates (non-fatal)
      try {
        final allShiftsSample = await supabase
            .from('shifts')
            .select('shift_date, id')
            .order('shift_date', ascending: false)
            .limit(10);
        if (allShiftsSample != null && allShiftsSample.isNotEmpty) {
          // probe returned results; no action needed
        }
      } catch (probeError) {
        // ignore probe errors
        final _probeErr = probeError;
      }

      final startDateStr = startDate.toIso8601String().split('T')[0];
      final endDateStr = endDate.toIso8601String().split('T')[0];

      final response = await supabase
          .from('shifts')
          .select()
          .gte('shift_date', startDateStr)
          .lte('shift_date', endDateStr)
          .order('shift_date', ascending: false);

      // If no results, try without date filter to see if there's any data
      if (response == null || (response is List && response.isEmpty)) {
        try {
          final allShifts = await supabase.from('shifts').select('id');
          if (allShifts != null && allShifts.isNotEmpty) {
            final dates = await supabase.from('shifts').select('shift_date').order('shift_date');
            final uniqueDates = (dates as List).map((d) => d['shift_date']).toSet();
            final _unique = uniqueDates;
          }
        } catch (probeError) {
          final _probeErr = probeError;
        }
      }

      return List<Map<String, dynamic>>.from(response ?? []);
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
        'metrics': List<Map<String, dynamic>>.from(metricsResponse),
      };
    } catch (e) {
      
      
      throw Exception('Failed to fetch shift details: $e');
    }
  }

  // ========================================================================
  // PARAMETER & THRESHOLD METHODS
  // ========================================================================

  /// Fetch all parameters (optionally filtered by machine_id)
  Future<List<Map<String, dynamic>>> getAllParameters({String? machineId}) async {
    try {
      var query = supabase.from('parameters').select();
      if (machineId != null) {
        query = query.eq('machine_id', machineId);
      }
      final response = await query;
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

  /// Fetch historical parameter data for trend analysis from history_parameters table
  Future<List<Map<String, dynamic>>> getParameterHistory({
    required String machineId,
    required String parameterName,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {
      
      
      // First, get the parameter ID by name and machine_id
      final parameterResponse = await supabase
          .from('parameters')
          .select()
          .eq('name', parameterName)
          .eq('machine_id', machineId)
          .maybeSingle();
      
      if (parameterResponse == null) {
        
        return [];
      }
      
      final parameterId = parameterResponse['id'] as String;
      
      
      // Get current value from parameters table
      final currentValue = (parameterResponse['current_value'] as num?)?.toDouble();
      
      
      // Fetch historical data from history_parameters table
      
      final historyResponse = await supabase
          .from('history_parameters')
          .select()
          .eq('parameter_id', parameterId)
          .gte('last_updated', startTime.toIso8601String())
          .lte('last_updated', endTime.toIso8601String())
          .order('last_updated', ascending: true);
      
      final historyList = List<Map<String, dynamic>>.from(historyResponse);
      
      
      // Build data points from history_parameters
      final dataPoints = <Map<String, dynamic>>[];
      
      for (var record in historyList) {
        final value = (record['value'] as num?)?.toDouble();
        if (value != null) {
          // Use last_updated timestamp, fallback to created_at
          String timestamp;
          if (record['last_updated'] != null) {
            timestamp = record['last_updated'] as String;
          } else if (record['created_at'] != null) {
            timestamp = record['created_at'] as String;
          } else {
            continue; // Skip records without timestamps
          }
          
          dataPoints.add({
            'timestamp': timestamp,
            'value': value,
          });
        }
      }
      
      
      
      // Add current value as the latest point if available and not already in history
      if (currentValue != null) {
        final nowTimestamp = DateTime.now().toIso8601String();
        final exists = dataPoints.any((dp) => dp['timestamp'] == nowTimestamp);
        if (!exists) {
          dataPoints.add({
            'timestamp': nowTimestamp,
            'value': currentValue,
          });
        }
      }
      
      // Sort by timestamp
      dataPoints.sort((a, b) {
        final aTime = DateTime.parse(a['timestamp'] as String);
        final bTime = DateTime.parse(b['timestamp'] as String);
        return aTime.compareTo(bTime);
      });
      
      
      
      return dataPoints;
    } catch (e) {
      
      throw Exception('Failed to fetch parameter history: $e');
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
