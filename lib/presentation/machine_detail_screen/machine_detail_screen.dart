import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../core/app_export.dart';
import '../../core/repositories/data_repositories.dart';
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
  
  // Parameter data organized by categories, fetched from Supabase
  Map<String, List<Map<String, dynamic>>> _parametersByCategory = {};

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
      // Get the machine data passed from the previous screen
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      
      if (args != null && args.containsKey('id')) {
        final machineId = args['id'] as String;
        print('Loading data for machine ID: $machineId');
        
        // Load machine data from Supabase
        final machineRepo = MachineRepository();
        final machine = await machineRepo.getMachineById(machineId);
        print('Loaded machine data: $machine');
        
        // Load parameters for this machine
        final parameters = await machineRepo.getMachineParameters(machineId);
        print('Loaded ${parameters.length} parameters');
        
        // Process parameters into categories
        final categorizedParams = _organizeParametersByCategory(parameters);
        print('Organized parameters into ${categorizedParams.length} categories');
        
        if (mounted) {
          setState(() {
            _machineData = machine;
            _parametersByCategory = categorizedParams;
            _lastUpdated = DateTime.now();
            
            // Initialize tab controller after we know the categories
            _tabController = TabController(
              length: _parametersByCategory.keys.length,
              vsync: this,
            );
          });
        }
      }
    } catch (e) {
      print('Error loading machine data: $e');
      // Show error message to user
      if (mounted) {
        Fluttertoast.showToast(
          msg: "Failed to load machine data",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: AppTheme.getStatusColor('critical'),
          textColor: Colors.white,
        );
      }
    }
  }

  Map<String, List<Map<String, dynamic>>> _organizeParametersByCategory(
      List<Map<String, dynamic>> parameters) {
    final categorized = <String, List<Map<String, dynamic>>>{};
    
    print('Organizing ${parameters.length} parameters');
    
    for (var param in parameters) {
      try {
        // Log the parameter structure for debugging
        print('Processing parameter: $param');
        
        // Parameters table now has all fields directly (no nested 'parameters' object)
        final paramName = param['name'] as String? ?? 'Unknown';
        final paramType = param['parameter_type'] as String? ?? 'general';
        final paramUnit = param['unit'] as String? ?? '';
        
        // Get current value directly from parameters table
        final currentValue = (param['current_value'] as num?)?.toDouble();
        
        // Get timestamp (use created_at or last_updated if available)
        final timestampStr = param['created_at'] as String? ?? DateTime.now().toIso8601String();
        
        // Create parameter entry
        final paramEntry = {
          "name": paramName,
          "value": currentValue != null ? currentValue.toStringAsFixed(2) : "N/A",
          "unit": paramUnit,
          "timestamp": DateTime.parse(timestampStr),
          "status": _getParameterStatus(currentValue, param),
          "trendData": [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, currentValue ?? 0.0], // Simplified trend data
        };
        
        // Add to appropriate category
        if (!categorized.containsKey(paramType)) {
          categorized[paramType] = [];
        }
        categorized[paramType]!.add(paramEntry);
      } catch (e) {
        print('Error processing parameter: $param, error: $e');
        // Skip malformed parameters instead of crashing
        continue;
      }
    }
    
    print('Organized parameters into categories: ${categorized.keys}');
    return categorized;
  }

  String _getParameterStatus(double? value, Map<String, dynamic> paramData) {
    try {
      if (value == null) return 'unknown';
      
      final minValue = (paramData['min_value']  as num?)?.toDouble();
      final maxValue = (paramData['max_value']  as num?)?.toDouble();
      final isCritical = paramData['is_critical'] as bool? ?? false;
      
      if (minValue != null && value < minValue) {
        return isCritical ? 'critical' : 'warning';
      }
      
      if (maxValue != null && value > maxValue) {
        return isCritical ? 'critical' : 'warning';
      }
      
      return 'normal';
    } catch (e) {
      print('Error determining parameter status: $e');
      return 'unknown';
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
      print('Error refreshing data: $e');
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

    // Show loading indicator while data is being fetched
    if (_machineData.isEmpty) {
      return Scaffold(
        appBar: CustomAppBar.withBack(
          title: 'Machine Details',
          onBackPressed: () => Navigator.pop(context),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: CustomAppBar.withBack(
        title: 'Machine Details',
        onBackPressed: () => Navigator.pop(context),
        actions: [
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
                children: _parametersByCategory.entries.map((entry) {
                  return ParameterCategoryTabWidget(
                    parameters: entry.value,
                    onParameterTap: _handleParameterTap,
                    onParameterLongPress: _handleParameterLongPress,
                  );
                }).toList(),
              ),
            ),
          ),
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