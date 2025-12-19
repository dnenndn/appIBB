import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../core/services/supabase_service.dart';
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
  StreamSubscription? _machinesSubscription;
  Timer? _alertCheckTimer;
  final SupabaseService _supabaseService = SupabaseService();

  @override
  void initState() {
    super.initState();
    _loadMachinesFromSupabase();
    _startRealTimeUpdates();
    _startAlertChecking();
  }

  @override
  void dispose() {
    _machinesSubscription?.cancel();
    _alertCheckTimer?.cancel();
    super.dispose();
  }
  
  void _startAlertChecking() {
    // Periodically check parameters against thresholds and create/update alerts
    _alertCheckTimer?.cancel();
    _alertCheckTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      // Check and update alerts in background
      _supabaseService.checkAndUpdateAlerts().catchError((error) {
        print('Error checking alerts: $error');
      });
    });
  }

  Future<void> _loadMachinesFromSupabase() async {
    try {
      final machinesData = await _supabaseService.getAllMachines();
      
      if (mounted) {
        setState(() {
          _machines = List<Map<String, dynamic>>.from(machinesData);
          _sortMachinesByPriority();
        });
      }
    } catch (e) {
      print('Error loading machines: $e');
      _initializeMockData();
    }
  }

  void _initializeMockData() {
    setState(() {
      _machines = [
        {
          "id": "kiln_01",
          "name": "Kiln 1",
          "type": "kiln",
          "status": "normal",
          "wagons": 42,
          "avg_push_time": 3.5,
          "gas_consumption": 342.5,
          "downtime_minutes": 0,
          "priority": 1,
        },
        {
          "id": "kiln_02",
          "name": "Kiln 2",
          "type": "kiln",
          "status": "warning",
          "wagons": 35,
          "avg_push_time": 4.1,
          "gas_consumption": 298.7,
          "downtime_minutes": 12,
          "priority": 2,
        },
        {
          "id": "dryer_01",
          "name": "Dryer 1",
          "type": "dryer",
          "status": "normal",
          "gas_consumption": 156.3,
          "wagons": 28,
          "avg_cuts_per_minute": 15.8,
          "downtime_minutes": 0,
          "priority": 3,
        },
      ];
      _sortMachinesByPriority();
    });
  }

  void _sortMachinesByPriority() {
    if (_machines.isEmpty) return;
    
    final statusPriority = {
      'critical': 0,
      'warning': 1,
      'normal': 2,
      'unknown': 3,
    };

    _machines.sort((a, b) {
      final aStatus = (a['status'] as String?)?.toLowerCase() ?? 'unknown';
      final bStatus = (b['status'] as String?)?.toLowerCase() ?? 'unknown';
      
      final aPriority = statusPriority[aStatus] ?? 3;
      final bPriority = statusPriority[bStatus] ?? 3;

      if (aPriority != bPriority) {
        return aPriority.compareTo(bPriority);
      }

      return (a['priority'] as int?)?.compareTo(b['priority'] as int? ?? 0) ?? 0;
    });
  }

  void _startRealTimeUpdates() {
    _machinesSubscription?.cancel();
    
    _machinesSubscription = _supabaseService.getMachinesStream().listen(
      (updatedMachines) {
        if (mounted) {
          setState(() {
            _machines = updatedMachines;
            _sortMachinesByPriority();
            _lastSyncTime = DateTime.now();
          });
        }
      },
      onError: (error) {
        print('Error in real-time subscription: $error');
        _initializeMockData();
      },
      cancelOnError: false,
    );
  }

  Future<void> _handleRefresh() async {
    HapticFeedback.mediumImpact();
    if (mounted) {
      setState(() {
        _isRefreshing = true;
      });
    }

    try {
      await _loadMachinesFromSupabase();
    } catch (e) {
      print('Error refreshing data: $e');
      _initializeMockData();
    }

    if (mounted) {
      setState(() {
        _isRefreshing = false;
        _lastSyncTime = DateTime.now();
      });
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
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Alerts muted for ${machine['name']}'),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      onPriorityStatus: () {
        HapticFeedback.lightImpact();
        if (mounted) {
          setState(() {
            machine['priority'] = 0;
            _sortMachinesByPriority();
          });
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${machine['name']} marked as high priority'),
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: CustomAppBar.standard(
        title: 'appIBB',
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
                            onTap: () => _handleMachineCardTap(_machines[index]),
                            onLongPress: () => _handleMachineCardLongPress(_machines[index]),
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
    final warningCount = _machines.where((m) => m['status'] == 'warning').length;
    final criticalCount = _machines.where((m) => m['status'] == 'critical').length;

    return Row(
      children: [
        _buildStatusChip('Normal', normalCount, Colors.green),
        SizedBox(width: 2.w),
        _buildStatusChip('Warning', warningCount, Colors.orange),
        SizedBox(width: 2.w),
        _buildStatusChip('Critical', criticalCount, Colors.red),
      ],
    );
  }

  Widget _buildStatusChip(String label, int count, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 1.w),
          Text(
            '$count $label',
            style: TextStyle(
              color: color,
              fontSize: 10.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.construction_outlined,
            size: 48,
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
          ),
          SizedBox(height: 2.h),
          Text(
            'No machines found',
            style: AppTheme.lightTheme.textTheme.titleMedium,
          ),
          SizedBox(height: 1.h),
          Text(
            'Add a machine to get started\nCheck your PLC connection and ensure machines are properly configured.',
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
    );
  }
}
