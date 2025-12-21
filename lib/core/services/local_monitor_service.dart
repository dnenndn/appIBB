import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Local per-user monitored parameters persistence.
/// Stores a map of machineId -> list of parameterIds in SharedPreferences.
class LocalMonitorService {
  static const _prefsKey = 'ibb_monitored_parameters_v1';

  Future<SharedPreferences> get _prefs async => await SharedPreferences.getInstance();

  Future<Map<String, List<String>>> _readAll() async {
    final p = await _prefs;
    final raw = p.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = json.decode(raw) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(k, List<String>.from(v as List)));
    } catch (_) {
      return {};
    }
  }

  Future<void> _writeAll(Map<String, List<String>> data) async {
    final p = await _prefs;
    await p.setString(_prefsKey, json.encode(data));
  }

  /// Get monitored parameter ids for a machine.
  ///
  /// Returns `null` when the user has not set any preference for the machine
  /// (treat as "no filter" -> show all parameters). Returns an empty list when
  /// the user explicitly saved zero parameters (treat as "show none").
  Future<List<String>?> getMonitoredParameterIds(String machineId) async {
    final all = await _readAll();
    if (!all.containsKey(machineId)) return null;
    return all[machineId] ?? [];
  }

  /// Overwrite monitored parameter ids for a machine.
  Future<void> setMonitoredParameterIds(String machineId, List<String> ids) async {
    final all = await _readAll();
    all[machineId] = ids;
    await _writeAll(all);
  }

  /// Clear monitored parameters for machine (remove entry)
  Future<void> clearMonitoredForMachine(String machineId) async {
    final all = await _readAll();
    all.remove(machineId);
    await _writeAll(all);
  }
}
