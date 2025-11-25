import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../core/app_export.dart';
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

  // Mock machine data
  final Map<String, dynamic> _machineData = {
    "id": "KILN-001",
    "name": "Kiln 1",
    "type": "Tunnel Kiln",
    "status": "normal",
    "lastUpdated": DateTime.now(),
  };

  // Mock parameter data organized by categories
  final Map<String, List<Map<String, dynamic>>> _parametersByCategory = {
    "Production": [
      {
        "name": "Production Rate",
        "value": "1,250",
        "unit": "bricks/hour",
        "timestamp": DateTime.now().subtract(const Duration(seconds: 15)),
        "status": "normal",
        "trendData": [1200.0, 1220.0, 1240.0, 1230.0, 1250.0, 1245.0, 1250.0],
      },
      {
        "name": "Average Cut/Min",
        "value": "45",
        "unit": "cuts/min",
        "timestamp": DateTime.now().subtract(const Duration(seconds: 20)),
        "status": "normal",
        "trendData": [42.0, 43.0, 44.0, 45.0, 45.0, 44.0, 45.0],
      },
      {
        "name": "Downtime",
        "value": "12",
        "unit": "minutes",
        "timestamp": DateTime.now().subtract(const Duration(seconds: 30)),
        "status": "warning",
        "trendData": [5.0, 7.0, 9.0, 10.0, 11.0, 12.0, 12.0],
      },
      {
        "name": "Efficiency",
        "value": "94.5",
        "unit": "%",
        "timestamp": DateTime.now().subtract(const Duration(seconds: 10)),
        "status": "normal",
        "trendData": [92.0, 93.0, 93.5, 94.0, 94.2, 94.5, 94.5],
      },
    ],
    "Temperature": [
      {
        "name": "Burner Temperature",
        "value": "1,150",
        "unit": "°C",
        "timestamp": DateTime.now().subtract(const Duration(seconds: 5)),
        "status": "normal",
        "trendData": [1140.0, 1145.0, 1148.0, 1150.0, 1150.0, 1149.0, 1150.0],
      },
      {
        "name": "Zone 1 Temperature",
        "value": "950",
        "unit": "°C",
        "timestamp": DateTime.now().subtract(const Duration(seconds: 8)),
        "status": "normal",
        "trendData": [945.0, 947.0, 948.0, 950.0, 950.0, 949.0, 950.0],
      },
      {
        "name": "Zone 2 Temperature",
        "value": "1,050",
        "unit": "°C",
        "timestamp": DateTime.now().subtract(const Duration(seconds: 12)),
        "status": "warning",
        "trendData": [1040.0, 1042.0, 1045.0, 1048.0, 1050.0, 1050.0, 1050.0],
      },
      {
        "name": "Cooling Zone Temp",
        "value": "450",
        "unit": "°C",
        "timestamp": DateTime.now().subtract(const Duration(seconds: 18)),
        "status": "normal",
        "trendData": [455.0, 453.0, 451.0, 450.0, 450.0, 449.0, 450.0],
      },
    ],
    "Flow": [
      {
        "name": "Gas Flow Rate",
        "value": "125",
        "unit": "m³/h",
        "timestamp": DateTime.now().subtract(const Duration(seconds: 7)),
        "status": "normal",
        "trendData": [120.0, 122.0, 123.0, 124.0, 125.0, 125.0, 125.0],
      },
      {
        "name": "Air Flow Rate",
        "value": "850",
        "unit": "m³/h",
        "timestamp": DateTime.now().subtract(const Duration(seconds: 11)),
        "status": "normal",
        "trendData": [840.0, 845.0, 847.0, 850.0, 850.0, 848.0, 850.0],
      },
      {
        "name": "Exhaust Flow",
        "value": "1,200",
        "unit": "m³/h",
        "timestamp": DateTime.now().subtract(const Duration(seconds: 14)),
        "status": "critical",
        "trendData": [1150.0, 1160.0, 1170.0, 1180.0, 1190.0, 1200.0, 1200.0],
      },
    ],
    "Energy": [
      {
        "name": "Power Consumption",
        "value": "245",
        "unit": "kW",
        "timestamp": DateTime.now().subtract(const Duration(seconds: 6)),
        "status": "normal",
        "trendData": [240.0, 242.0, 243.0, 244.0, 245.0, 245.0, 245.0],
      },
      {
        "name": "Gas Consumption",
        "value": "3,450",
        "unit": "m³",
        "timestamp": DateTime.now().subtract(const Duration(seconds: 9)),
        "status": "normal",
        "trendData": [3400.0, 3410.0, 3420.0, 3430.0, 3440.0, 3450.0, 3450.0],
      },
      {
        "name": "Energy Efficiency",
        "value": "87.5",
        "unit": "%",
        "timestamp": DateTime.now().subtract(const Duration(seconds: 13)),
        "status": "warning",
        "trendData": [88.0, 87.8, 87.6, 87.5, 87.5, 87.4, 87.5],
      },
    ],
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _parametersByCategory.keys.length,
      vsync: this,
    );
    _lastUpdated = DateTime.now();
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

    // Simulate data refresh with staggered animation
    await Future.delayed(const Duration(milliseconds: 1500));

    setState(() {
      _isRefreshing = false;
      _lastUpdated = DateTime.now();
      _machineData['lastUpdated'] = DateTime.now();
    });

    Fluttertoast.showToast(
      msg: "Data refreshed successfully",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: AppTheme.getStatusColor('normal'),
      textColor: Colors.white,
    );
  }

  void _handleParameterTap(Map<String, dynamic> parameter) {
    HapticFeedback.lightImpact();
    Navigator.pushNamed(
      context,
      '/parameter-trend-screen',
      arguments: {
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
            machineType: _machineData['type'] as String,
            status: _machineData['status'] as String,
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
