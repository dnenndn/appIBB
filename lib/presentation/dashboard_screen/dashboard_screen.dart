import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_bottom_bar.dart';
import './widgets/connection_status_indicator.dart';
import './widgets/machine_status_card.dart';
import './widgets/quick_actions_bottom_sheet.dart';

/// Dashboard Screen - Main overview of factory machines
/// Displays real-time machine status with color-coded cards
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isConnected = true;
  DateTime _lastSyncTime = DateTime.now();
  bool _isRefreshing = false;
  List<Map<String, dynamic>> _machines = [];

  @override
  void initState() {
    super.initState();
    _initializeMockData();
    _startRealTimeUpdates();
  }

  void _initializeMockData() {
    _machines = [
      {
        "id": "kiln_01",
        "name": "Kiln 1",
        "type": "kiln",
        "status": "normal",
        "production": 245.8,
        "temperature": 1150.0,
        "downtime": 0,
        "flow": 85.5,
        "burnerTemp": 1200.0,
        "energyConsumption": 342.5,
        "avgCutPerMin": 12.5,
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
        "burnerTemp": 1150.0,
        "energyConsumption": 298.7,
        "avgCutPerMin": 10.2,
        "priority": 2,
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
        "burnerTemp": 220.0,
        "energyConsumption": 156.3,
        "avgCutPerMin": 15.8,
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
        "burnerTemp": 180.0,
        "energyConsumption": 98.5,
        "avgCutPerMin": 6.3,
        "priority": 0,
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
        "burnerTemp": 1225.0,
        "energyConsumption": 365.2,
        "avgCutPerMin": 13.2,
        "priority": 4,
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
        "burnerTemp": 195.0,
        "energyConsumption": 132.8,
        "avgCutPerMin": 12.1,
        "priority": 5,
      },
    ];

    _sortMachinesByPriority();
  }

  void _sortMachinesByPriority() {
    _machines.sort((a, b) {
      final statusPriority = {
        'critical': 0,
        'warning': 1,
        'normal': 2,
        'unknown': 3,
      };

      final aPriority = statusPriority[a['status']] ?? 3;
      final bPriority = statusPriority[b['status']] ?? 3;

      if (aPriority != bPriority) {
        return aPriority.compareTo(bPriority);
      }

      return (a['priority'] as int).compareTo(b['priority'] as int);
    });
  }

  void _startRealTimeUpdates() {
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _lastSyncTime = DateTime.now();
          for (var machine in _machines) {
            if (machine['status'] == 'normal') {
              machine['production'] = (machine['production'] as double) +
                  (DateTime.now().millisecond % 10 - 5) * 0.5;
              machine['temperature'] = (machine['temperature'] as double) +
                  (DateTime.now().millisecond % 6 - 3) * 0.2;
            }
          }
        });
        _startRealTimeUpdates();
      }
    });
  }

  Future<void> _handleRefresh() async {
    HapticFeedback.mediumImpact();
    setState(() {
      _isRefreshing = true;
    });

    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _isRefreshing = false;
        _lastSyncTime = DateTime.now();
        _isConnected = true;
      });

      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Data refreshed successfully'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppTheme.lightTheme.colorScheme.tertiary,
        ),
      );
    }
  }

  void _handleMachineCardTap(Map<String, dynamic> machine) {
    HapticFeedback.lightImpact();
    Navigator.pushNamed(
      context,
      '/machine-detail-screen',
      arguments: machine,
    );
  }

  void _handleMachineCardLongPress(Map<String, dynamic> machine) {
    QuickActionsBottomSheet.show(
      context,
      machineName: machine['name'] as String,
      onViewTrends: () {
        Navigator.pushNamed(
          context,
          '/parameter-trend-screen',
          arguments: machine,
        );
      },
      onMuteAlerts: () {
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Alerts muted for ${machine['name']}'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      onPriorityStatus: () {
        HapticFeedback.lightImpact();
        setState(() {
          machine['priority'] = 0;
          _sortMachinesByPriority();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${machine['name']} marked as high priority'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: CustomAppBar.standard(
        title: 'BrickMonitor Pro',
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _machines.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _handleRefresh,
                      color: AppTheme.lightTheme.colorScheme.primary,
                      child: ListView.builder(
                        padding: EdgeInsets.only(top: 1.h, bottom: 2.h),
                        itemCount: _machines.length,
                        itemBuilder: (context, index) {
                          return MachineStatusCard(
                            machineData: _machines[index],
                            onTap: () =>
                                _handleMachineCardTap(_machines[index]),
                            onLongPress: () =>
                                _handleMachineCardLongPress(_machines[index]),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomBar(
        currentIndex: 0,
      ),
      floatingActionButton: _isRefreshing
          ? null
          : FloatingActionButton(
              onPressed: _handleRefresh,
              backgroundColor: AppTheme.lightTheme.colorScheme.primary,
              child: CustomIconWidget(
                iconName: Icons.refresh.codePoint.toRadixString(16),
                color: Colors.white,
                size: 24,
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: AppTheme.lightTheme.shadowColor.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Factory Overview',
                    style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    '${_machines.length} machines active',
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              ConnectionStatusIndicator(
                isConnected: _isConnected,
                lastSyncTime: _lastSyncTime,
              ),
            ],
          ),
          SizedBox(height: 1.5.h),
          _buildStatusSummary(),
        ],
      ),
    );
  }

  Widget _buildStatusSummary() {
    final normalCount = _machines.where((m) => m['status'] == 'normal').length;
    final warningCount =
        _machines.where((m) => m['status'] == 'warning').length;
    final criticalCount =
        _machines.where((m) => m['status'] == 'critical').length;

    return Row(
      children: [
        Expanded(
          child: _buildStatusChip(
            'Normal',
            normalCount,
            AppTheme.lightTheme.colorScheme.tertiary,
          ),
        ),
        SizedBox(width: 2.w),
        Expanded(
          child: _buildStatusChip(
            'Warning',
            warningCount,
            const Color(0xFFFF8800),
          ),
        ),
        SizedBox(width: 2.w),
        Expanded(
          child: _buildStatusChip(
            'Critical',
            criticalCount,
            AppTheme.lightTheme.colorScheme.error,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String label, int count, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 1.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            count.toString(),
            style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 0.3.h),
          Text(
            label,
            style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(8.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(6.w),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.primary
                    .withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: CustomIconWidget(
                iconName:
                    Icons.precision_manufacturing.codePoint.toRadixString(16),
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 64,
              ),
            ),
            SizedBox(height: 3.h),
            Text(
              'No Machines Connected',
              style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 1.h),
            Text(
              'Check your PLC connection and ensure machines are properly configured.',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 3.h),
            ElevatedButton.icon(
              onPressed: _handleRefresh,
              icon: CustomIconWidget(
                iconName: Icons.refresh.codePoint.toRadixString(16),
                color: Colors.white,
                size: 20,
              ),
              label: const Text('Retry Connection'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.5.h),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
