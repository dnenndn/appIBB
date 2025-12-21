import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:async';

import '../../core/app_export.dart';
import '../../core/repositories/data_repositories.dart';
import '../../core/services/supabase_service.dart';
import '../../core/services/local_threshold_service.dart';
import '../../core/services/local_monitor_service.dart';
import '../../core/utils/status_calculator.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_bottom_bar.dart';
import './widgets/machine_controls_bottom_sheet_widget.dart';
import './widgets/machine_status_header_widget.dart';
import './widgets/parameter_category_tab_widget.dart';
import './widgets/parameter_quick_actions_dialog_widget.dart';

class MachineDetailScreen extends StatefulWidget {
  const MachineDetailScreen({super.key});

  @override
  State<MachineDetailScreen> createState() => _MachineDetailScreenState();
}

class _MachineDetailScreenState extends State<MachineDetailScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isRefreshing = false;
  DateTime _lastUpdated = DateTime.now();
  bool _isLoading = true;
  
  // Machine data fetched from Supabase
  Map<String, dynamic> _machineData = {};
  String? _errorMessage;
  
  // Parameter data organized by categories, fetched from Supabase
  Map<String, List<Map<String, dynamic>>> _parametersByCategory = {};
  
  // Real-time subscriptions
  StreamSubscription? _parametersSubscription;
  StreamSubscription? _machineSubscription;
  Timer? _parameterRefreshTimer;
  final SupabaseService _supabaseService = SupabaseService();
  final LocalMonitorService _monitorService = LocalMonitorService();
  bool _monitoredFilterApplied = false; // true when user saved a monitored preference (even empty)


  @override
  void initState() {
    super.initState();
    // We'll load data in didChangeDependencies instead of initState
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Load data when dependencies change (this includes when the widget is first built)
    if (_isLoading) {
      _loadMachineData();
      _isLoading = false;
    }
  }

  Future<void> _loadMachineData() async {
    try {
      // Show loading state
      if (mounted) {
        setState(() {
          _isLoading = true;
        });
      }
      
      // Get the machine data passed from the previous screen
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      
      if (args != null && args.containsKey('id')) {
        final machineId = args['id'] as String;
        
        
        // Load machine data from Supabase
        final machineRepo = MachineRepository();
        final machine = await machineRepo.getMachineById(machineId);
        
        
        // Load parameters for this machine
        final parameters = await machineRepo.getMachineParameters(machineId);

        // Load monitored preference (nullable): null = no preference -> show all
        final monitoredPref = await _monitorService.getMonitoredParameterIds(machineId);
        _monitoredFilterApplied = monitoredPref != null;

        // Process parameters into categories (now async) - this will calculate status correctly
        final categorizedParams = await _organizeParametersByCategory(parameters, monitoredPref);
        
        
        if (mounted) {
          // Preserve current tab index if tab controller already exists
          int? previousTabIndex;
          String? previousTabCategory;
            try {
            if (_tabController.length > 0 && _tabController.index < _tabController.length) {
              previousTabIndex = _tabController.index;
              // Get the category name at the current tab index
              final categoryList = _parametersByCategory.keys.toList();
              if (previousTabIndex < categoryList.length) {
                previousTabCategory = categoryList[previousTabIndex];
              }
            }
          } catch (e) {
            // Tab controller not initialized yet, that's okay
          }
          
          setState(() {
            _machineData = machine;
            _parametersByCategory = categorizedParams;
            _lastUpdated = DateTime.now();
            _isLoading = false; // Hide loading after data is ready with correct status
            
            // Initialize or update tab controller after we know the categories
            final categoryCount = _parametersByCategory.keys.length;
            final categoryList = _parametersByCategory.keys.toList();
            
            // Check if tab controller needs to be recreated
            bool needsRecreation = false;
            try {
              // Try to access length to see if controller is valid
              if (_tabController.length != categoryCount) {
                needsRecreation = true;
              }
            } catch (e) {
              // Controller is not initialized or disposed
              needsRecreation = true;
            }
            
            if (needsRecreation) {
              try {
                _tabController.dispose();
              } catch (e) {
                // Controller might already be disposed
              }
              _tabController = TabController(
                length: categoryCount,
                vsync: this,
              );
              
              // Restore previous tab by category name if possible, otherwise by index
              if (previousTabCategory != null) {
                final newIndex = categoryList.indexOf(previousTabCategory);
                if (newIndex >= 0 && newIndex < categoryCount) {
                  _tabController.index = newIndex;
                } else if (previousTabIndex != null && previousTabIndex < categoryCount) {
                  _tabController.index = previousTabIndex;
                }
              } else if (previousTabIndex != null && previousTabIndex < categoryCount) {
                _tabController.index = previousTabIndex;
              }
            }
          });
          
          // Start real-time updates after initial load
          _startRealTimeUpdates();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<Map<String, List<Map<String, dynamic>>>> _organizeParametersByCategory(
      List<Map<String, dynamic>> parameters, List<String>? monitoredPref) async {
    final categorized = <String, List<Map<String, dynamic>>>{};
    // If user has selected monitored parameters for this machine, filter the list.
    // monitoredPref: null => no preference (show all), empty list => explicitly selected none
    try {
      if (monitoredPref != null) {
        final monitored = monitoredPref.toSet();
        parameters = parameters.where((p) {
          final id = p['id'] as String?;
          return id != null && monitored.contains(id);
        }).toList();
      }
    } catch (_) {
      // ignore and show all if monitor prefs fail
    }
    
    final machineId = _machineData['id'] as String?;
    final thresholdService = LocalThresholdService();
    
    // Pre-fetch all thresholds in parallel for better performance
    final thresholdFutures = <String, Future<Map<String, double?>>>{};
    if (machineId != null) {
      for (var param in parameters) {
        final parameterId = param['id'] as String?;
        final currentValue = (param['current_value'] as num?)?.toDouble();
        if (parameterId != null && currentValue != null) {
          thresholdFutures[parameterId] = _getThresholdsForParameter(
            machineId: machineId,
            parameterId: parameterId,
            currentValue: currentValue,
          );
        }
      }
    }
    
    // Wait for all thresholds to be fetched
    final thresholdResults = <String, Map<String, double?>>{};
    await Future.wait(thresholdFutures.entries.map((e) async {
      thresholdResults[e.key] = await e.value;
    }));
    
    for (var param in parameters) {
      try {
        
        
        // Parameters table now has all fields directly (no nested 'parameters' object)
        final paramName = param['name'] as String? ?? 'Unknown';
        final paramType = param['parameter_type'] as String? ?? 'general';
        final paramUnit = param['unit'] as String? ?? '';
        
        // Get current value directly from parameters table
        final currentValue = (param['current_value'] as num?)?.toDouble();
        
        // Get timestamp (use created_at or last_updated if available)
        final timestampStr = param['created_at'] as String? ?? DateTime.now().toIso8601String();
        
        // Calculate status using pre-fetched thresholds
        String status = 'normal';
        if (currentValue != null && machineId != null) {
          final parameterId = param['id'] as String?;
          if (parameterId != null && thresholdResults.containsKey(parameterId)) {
            final thresholds = thresholdResults[parameterId]!;
            final criticalMin = thresholds['criticalMin'] ?? (currentValue - 10);
            final criticalMax = thresholds['criticalMax'] ?? (currentValue + 10);
            final warningMin = thresholds['warningMin'] ?? (criticalMin * 0.9);
            final warningMax = thresholds['warningMax'] ?? (criticalMax * 1.1);
            
            // Check critical thresholds first
            if (currentValue < criticalMin || currentValue > criticalMax) {
              status = 'critical';
            } 
            // Check warning thresholds
            else if (currentValue < warningMin || currentValue > warningMax) {
              status = 'warning';
            } else {
              status = 'normal';
            }
          }
        }
        
        // Create parameter entry
        final paramEntry = {
          "name": paramName,
          "value": currentValue != null ? currentValue.toStringAsFixed(2) : "N/A",
          "unit": paramUnit,
          "timestamp": DateTime.parse(timestampStr),
          "status": status,
          "trendData": [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, currentValue ?? 0.0], // Simplified trend data
          // expose critical thresholds as range for UI
          "rangeMin": (thresholdResults.containsKey(param['id']) ? (thresholdResults[param['id']]!['criticalMin']) : (currentValue != null ? currentValue - 10 : 0)),
          "rangeMax": (thresholdResults.containsKey(param['id']) ? (thresholdResults[param['id']]!['criticalMax']) : (currentValue != null ? currentValue + 10 : 100)),
        };
        
        // Add to appropriate category
        if (!categorized.containsKey(paramType)) {
          categorized[paramType] = [];
        }
        categorized[paramType]!.add(paramEntry);
      } catch (e) {
        
        // Skip malformed parameters instead of crashing
        continue;
      }
    }
    
    return categorized;
  }

  Future<void> _showParameterSelection() async {
    final machineId = _machineData['id'] as String?;
    if (machineId == null) return;

    final repo = MachineRepository();
    List<Map<String, dynamic>> allParams;
    try {
      allParams = await repo.getMachineParameters(machineId);
    } catch (e) {
      Fluttertoast.showToast(msg: 'Failed to load parameters');
      return;
    }

    final monitoredList = await _monitorService.getMonitoredParameterIds(machineId);
    final allIds = allParams.map((p) => p['id'] as String).whereType<String>().toSet();
    final selectedInitial = monitoredList == null ? Set<String>.from(allIds) : Set<String>.from(monitoredList);

    final result = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
      builder: (context) {
        final selected = Set<String>.from(selectedInitial);
        return StatefulBuilder(builder: (context, setState) {
          return SafeArea(
            child: Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Select Parameters', style: TextStyle(fontWeight: FontWeight.w600)),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              // toggle select all
                              final allIds = allParams.map((p) => p['id'] as String).toSet();
                              if (selected.length == allIds.length) {
                                selected.clear();
                              } else {
                                selected.clear();
                                selected.addAll(allIds);
                              }
                            });
                          },
                          child: const Text('Toggle All'),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.6,
                      child: ListView.builder(
                        itemCount: allParams.length,
                        itemBuilder: (ctx, i) {
                          final p = allParams[i];
                          final id = p['id'] as String?;
                          final name = p['name'] as String? ?? 'Unknown';
                          final checked = id != null && selected.contains(id);
                          return CheckboxListTile(
                            value: checked,
                            title: Text(name),
                            onChanged: id == null ? null : (v) {
                              setState(() {
                                if (v == true) selected.add(id); else selected.remove(id);
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              if (selected.length == allIds.length) {
                                await _monitorService.clearMonitoredForMachine(machineId);
                              } else {
                                await _monitorService.setMonitoredParameterIds(machineId, selected.toList());
                              }
                              Navigator.pop(context, selected.toList());
                            },
                            child: const Text('Save'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );

    if (result != null) {
      await _loadMachineData();
      Fluttertoast.showToast(msg: 'Monitored parameters updated');
    }
  }
  
  Future<Map<String, double?>> _getThresholdsForParameter({
    required String machineId,
    required String parameterId,
    required double currentValue,
  }) async {
    try {
      final thresholdService = LocalThresholdService();
      
      // Get critical thresholds
      final criticalThresholds = await thresholdService.getThresholdWithDefaults(
        machineId: machineId,
        parameterId: parameterId,
        currentValue: currentValue,
      );
      
      final criticalMin = criticalThresholds['min']!;
      final criticalMax = criticalThresholds['max']!;
      
      // Get warning thresholds
      final warningThresholds = await thresholdService.getWarningThresholds(
        machineId: machineId,
        parameterId: parameterId,
      );
      
      // Use actual warning thresholds if available, otherwise calculate from critical
      final warningMin = warningThresholds?['min'] ?? (criticalMin * 0.9);
      final warningMax = warningThresholds?['max'] ?? (criticalMax * 1.1);
      
      return {
        'criticalMin': criticalMin,
        'criticalMax': criticalMax,
        'warningMin': warningMin,
        'warningMax': warningMax,
      };
    } catch (e) {
      // Return defaults
      return {
        'criticalMin': currentValue - 10,
        'criticalMax': currentValue + 10,
        'warningMin': (currentValue - 10) * 0.9,
        'warningMax': (currentValue + 10) * 1.1,
      };
    }
  }

  Future<String> _getParameterStatusAsync({
    required double value,
    required String machineId,
    required String parameterId,
  }) async {
    try {
      final thresholdService = LocalThresholdService();
      
      // Get critical thresholds
      final criticalThresholds = await thresholdService.getThresholdWithDefaults(
        machineId: machineId,
        parameterId: parameterId,
        currentValue: value,
      );
      
      final criticalMin = criticalThresholds['min']!;
      final criticalMax = criticalThresholds['max']!;
      
      // Get warning thresholds
      final warningThresholds = await thresholdService.getWarningThresholds(
        machineId: machineId,
        parameterId: parameterId,
      );
      
      // Use actual warning thresholds if available, otherwise calculate from critical
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
    } catch (e) {
      return 'unknown';
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _parametersSubscription?.cancel();
    _machineSubscription?.cancel();
    _parameterRefreshTimer?.cancel();
    super.dispose();
  }
  
  void _startRealTimeUpdates() {
    final machineId = _machineData['id'] as String?;
    if (machineId == null) return;
    
    // Subscribe to machine changes
    _machineSubscription?.cancel();
    _machineSubscription = _supabaseService.getMachinesStream().listen(
      (machines) {
        final updatedMachine = machines.firstWhere(
          (m) => m['id'] == machineId,
          orElse: () => {},
        );
        if (updatedMachine.isNotEmpty && mounted) {
          setState(() {
            _machineData = updatedMachine;
            _lastUpdated = DateTime.now();
          });
        }
      },
      onError: (error) {
        
      },
    );
    
    // Subscribe to parameter changes by periodically refreshing
    // Note: Supabase real-time for parameters table would need to be set up
    _parameterRefreshTimer?.cancel();
    _parameterRefreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      // Preserve current tab index
      int? currentTabIndex;
      String? currentTabCategory;
      try {
        if (_tabController.length > 0 && _tabController.index < _tabController.length) {
          currentTabIndex = _tabController.index;
          final categoryList = _parametersByCategory.keys.toList();
          if (currentTabIndex < categoryList.length) {
            currentTabCategory = categoryList[currentTabIndex];
          }
        }
      } catch (e) {
        // Tab controller not initialized yet, that's okay
      }
      
      // Reload data
      await _loadMachineData();
      
      // Restore tab index after reload
      if (mounted && currentTabCategory != null) {
        final categoryList = _parametersByCategory.keys.toList();
        final newIndex = categoryList.indexOf(currentTabCategory);
        if (newIndex >= 0 && newIndex < _tabController.length) {
          _tabController.index = newIndex;
        } else if (currentTabIndex != null && currentTabIndex < _tabController.length) {
          _tabController.index = currentTabIndex;
        }
      }
    });
  }

  Future<void> _refreshData() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    HapticFeedback.lightImpact();

    try {
      await _loadMachineData();
      
      if (mounted) {
        Fluttertoast.showToast(
          msg: "Data refreshed successfully",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: AppTheme.getStatusColor('normal'),
          textColor: Colors.white,
        );
      }
    } catch (e) {
      
      if (mounted) {
        Fluttertoast.showToast(
          msg: "Failed to refresh data",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: AppTheme.getStatusColor('critical'),
          textColor: Colors.white,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
          _lastUpdated = DateTime.now();
        });
      }
    }
  }

  void _handleParameterTap(Map<String, dynamic> parameter) {
    HapticFeedback.lightImpact();
    Navigator.pushNamed(
      context,
      '/parameter-trend-screen',
      arguments: {
        'machineId': _machineData['id'],
        'machineName': _machineData['name'],
        'parameterName': parameter['name'],
        'currentValue': parameter['value'],
        'unit': parameter['unit'],
      },
    );
  }

  void _handleParameterLongPress(Map<String, dynamic> parameter) {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (context) => ParameterQuickActionsDialogWidget(
        parameterName: parameter['name'] as String,
        onSetThreshold: () => _handleSetThreshold(parameter),
        onViewHistory: () => _handleViewHistory(parameter),
        onShareData: () => _handleShareData(parameter),
      ),
    );
  }

  void _handleSetThreshold(Map<String, dynamic> parameter) {
    Fluttertoast.showToast(
      msg: "Setting threshold for ${parameter['name']}",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  void _handleViewHistory(Map<String, dynamic> parameter) {
    Navigator.pushNamed(
      context,
      '/historical-data-screen',
      arguments: {
        'machineId': _machineData['id'],
        'parameterName': parameter['name'],
      },
    );
  }

  void _handleShareData(Map<String, dynamic> parameter) {
    Fluttertoast.showToast(
      msg: "Sharing data for ${parameter['name']}",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  void _showMachineControls() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MachineControlsBottomSheetWidget(
        machineName: _machineData['name'] as String,
        hasStartStopPermission: true,
        onStartStop: _handleStartStop,
        onResetCounters: _handleResetCounters,
        onExportData: _handleExportData,
      ),
    );
  }

  void _handleStartStop() {
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Action'),
        content: Text(
          'Are you sure you want to start/stop ${_machineData['name']}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Fluttertoast.showToast(
                msg: "Machine control command sent",
                toastLength: Toast.LENGTH_SHORT,
                gravity: ToastGravity.BOTTOM,
                backgroundColor: AppTheme.getStatusColor('critical'),
                textColor: Colors.white,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.getStatusColor('critical'),
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _handleResetCounters() {
    Fluttertoast.showToast(
      msg: "Resetting counters for ${_machineData['name']}",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: AppTheme.getStatusColor('warning'),
      textColor: Colors.white,
    );
  }

  void _handleExportData() {
    Fluttertoast.showToast(
      msg: "Exporting data for ${_machineData['name']}",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final bool noParametersSelected = _monitoredFilterApplied &&
      (_parametersByCategory.isEmpty || _parametersByCategory.values.every((list) => list.isEmpty));

    // Show loading indicator while data is being fetched
    if (_machineData.isEmpty) {
      return Scaffold(
        appBar: CustomAppBar.withBack(
          title: 'Machine Details',
          onBackPressed: () => Navigator.pop(context),
        ),
        body: Center(
          child: _isLoading
              ? const CircularProgressIndicator()
              : _errorMessage != null
                  ? Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 48, color: AppTheme.getStatusColor('critical')),
                          const SizedBox(height: 16),
                          Text('Unable to load machine data', style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 8),
                          Text(
                            _errorMessage ?? '',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _isLoading = true;
                                _errorMessage = null;
                              });
                              _loadMachineData();
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : const Text('No machine data'),
        ),
      );
    }

    return Scaffold(
      appBar: CustomAppBar.withBack(
        title: 'Machine Details',
        onBackPressed: () => Navigator.pop(context),
        actions: [
          IconButton(
            icon: Icon(
              Icons.view_list,
              size: 24,
              color: theme.appBarTheme.foregroundColor ?? Colors.white,
            ),
            onPressed: _showParameterSelection,
            tooltip: 'Select Parameters',
          ),
          IconButton(
            icon: CustomIconWidget(
              iconName: 'refresh',
              size: 24,
              color: theme.appBarTheme.foregroundColor ?? Colors.white,
            ),
            onPressed: _refreshData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          MachineStatusHeaderWidget(
            machineName: _machineData['name'] as String,
            machineType: _machineData['type'] as String? ?? 'Unknown',
            status: _machineData['status'] as String? ?? 'unknown',
            lastUpdated: _lastUpdated,
          ),

          // If user explicitly selected zero parameters, show centered message
          if (noParametersSelected) ...[
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.info_outline, size: 56, color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(height: 16),
                      Text(
                        'No parameters selected yet',
                        style: theme.textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Select which parameters you want to monitor for this machine.',
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 18),
                      ElevatedButton(
                        onPressed: _showParameterSelection,
                        child: const Text('Select Parameters'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ] else ...[
            Container(
              color: theme.colorScheme.surface,
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                tabs: _parametersByCategory.keys
                    .map((category) => Tab(text: category))
                    .toList(),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshData,
                child: TabBarView(
                  controller: _tabController,
                  children: _parametersByCategory.entries.map<Widget>((entry) {
                    return ParameterCategoryTabWidget(
                      parameters: entry.value,
                      onParameterTap: _handleParameterTap,
                      onParameterLongPress: _handleParameterLongPress,
                      monitoredFilterApplied: _monitoredFilterApplied,
                      onOpenSelection: _showParameterSelection,
                    );
                  }).toList(growable: false),
                ),
              ),
            ),
          ],
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showMachineControls,
        icon: CustomIconWidget(
          iconName: 'settings',
          size: 24,
          color: Colors.white,
        ),
        label: const Text('Controls'),
      ),
      bottomNavigationBar: const CustomBottomBar(
        currentIndex: 0,
      ),
    );
  }
}