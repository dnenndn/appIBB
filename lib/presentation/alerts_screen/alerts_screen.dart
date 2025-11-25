import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/alert_card.dart';
import './widgets/alert_filter_chip.dart';
import './widgets/alert_settings_bottom_sheet.dart';

/// Alerts Screen - Real-time factory notification management
/// Displays color-coded alerts with auto-dismissal and multi-select functionality
class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen>
    with SingleTickerProviderStateMixin {
  // Filter state
  String _selectedFilter = 'All';
  final List<String> _filterOptions = ['All', 'Critical', 'Warning', 'Status'];

  // Multi-select state
  bool _isMultiSelectMode = false;
  final Set<String> _selectedAlerts = {};

  // Settings state
  Map<String, bool> _notificationPreferences = {
    'critical': true,
    'warning': true,
    'status': true,
  };
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;

  // Mock alerts data
  final List<Map<String, dynamic>> _allAlerts = [
    {
      'id': 'alert_001',
      'machineName': 'Kiln #1',
      'type': 'critical',
      'alertType': 'Temperature Exceeded',
      'timestamp': '2 min ago',
      'currentStatus': 'Burner temperature at 1250°C (Max: 1200°C)',
      'isResolved': false,
      'parameter': 'burner_temperature',
      'machineId': 'kiln_1',
    },
    {
      'id': 'alert_002',
      'machineName': 'Dryer #2',
      'type': 'warning',
      'alertType': 'Low Flow Rate',
      'timestamp': '15 min ago',
      'currentStatus': 'Flow rate at 45 m³/h (Min: 50 m³/h)',
      'isResolved': false,
      'parameter': 'flow_rate',
      'machineId': 'dryer_2',
    },
    {
      'id': 'alert_003',
      'machineName': 'Kiln #2',
      'type': 'status',
      'alertType': 'Machine Started',
      'timestamp': '1 hour ago',
      'currentStatus': 'Machine resumed operation after maintenance',
      'isResolved': true,
      'autoDismissSeconds': 45,
      'parameter': 'machine_status',
      'machineId': 'kiln_2',
    },
    {
      'id': 'alert_004',
      'machineName': 'Dryer #1',
      'type': 'critical',
      'alertType': 'Emergency Stop',
      'timestamp': '3 hours ago',
      'currentStatus': 'Machine stopped due to safety sensor trigger',
      'isResolved': false,
      'parameter': 'machine_status',
      'machineId': 'dryer_1',
    },
    {
      'id': 'alert_005',
      'machineName': 'Kiln #3',
      'type': 'warning',
      'alertType': 'High Energy Consumption',
      'timestamp': '5 hours ago',
      'currentStatus': 'Energy usage at 125 kWh (Avg: 100 kWh)',
      'isResolved': true,
      'autoDismissSeconds': 30,
      'parameter': 'energy_consumption',
      'machineId': 'kiln_3',
    },
    {
      'id': 'alert_006',
      'machineName': 'Dryer #3',
      'type': 'status',
      'alertType': 'Maintenance Scheduled',
      'timestamp': '1 day ago',
      'currentStatus': 'Routine maintenance scheduled for tomorrow',
      'isResolved': false,
      'parameter': 'maintenance',
      'machineId': 'dryer_3',
    },
  ];

  List<Map<String, dynamic>> get _filteredAlerts {
    if (_selectedFilter == 'All') {
      return _allAlerts;
    }
    return _allAlerts
        .where((alert) =>
            (alert['type'] as String).toLowerCase() ==
            _selectedFilter.toLowerCase())
        .toList();
  }

  int get _unreadCount {
    return _allAlerts.where((alert) => alert['isResolved'] != true).length;
  }

  @override
  void initState() {
    super.initState();
    _startAutoDismissTimers();
  }

  void _startAutoDismissTimers() {
    // Simulate auto-dismiss countdown
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          for (var alert in _allAlerts) {
            if (alert['isResolved'] == true &&
                alert['autoDismissSeconds'] != null) {
              final seconds = alert['autoDismissSeconds'] as int;
              if (seconds > 0) {
                alert['autoDismissSeconds'] = seconds - 1;
              } else {
                _allAlerts.remove(alert);
                break;
              }
            }
          }
        });
        _startAutoDismissTimers();
      }
    });
  }

  void _handleRefresh() async {
    HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      _showFlushbar(
        'Alerts refreshed',
        'All alerts are up to date',
        const Color(0xFF00C851),
      );
    }
  }

  void _handleMarkAllRead() {
    HapticFeedback.mediumImpact();
    setState(() {
      for (var alert in _allAlerts) {
        if (alert['type'] != 'critical') {
          alert['isResolved'] = true;
          alert['autoDismissSeconds'] = 60;
        }
      }
    });
    _showFlushbar(
      'Marked as read',
      'Non-critical alerts marked as read',
      const Color(0xFF00C851),
    );
  }

  void _handleAlertTap(Map<String, dynamic> alert) {
    if (_isMultiSelectMode) {
      setState(() {
        if (_selectedAlerts.contains(alert['id'])) {
          _selectedAlerts.remove(alert['id']);
        } else {
          _selectedAlerts.add(alert['id'] as String);
        }
      });
    } else {
      HapticFeedback.lightImpact();
      Navigator.pushNamed(
        context,
        '/machine-detail-screen',
        arguments: {
          'machineId': alert['machineId'],
          'highlightParameter': alert['parameter'],
        },
      );
    }
  }

  void _handleLongPress(Map<String, dynamic> alert) {
    setState(() {
      _isMultiSelectMode = true;
      _selectedAlerts.add(alert['id'] as String);
    });
  }

  void _exitMultiSelectMode() {
    setState(() {
      _isMultiSelectMode = false;
      _selectedAlerts.clear();
    });
  }

  void _handleAcknowledge(String alertId) {
    setState(() {
      final alert = _allAlerts.firstWhere((a) => a['id'] == alertId);
      alert['isResolved'] = true;
      alert['autoDismissSeconds'] = 60;
    });
    _showFlushbar(
      'Alert acknowledged',
      'Alert has been marked as acknowledged',
      const Color(0xFF00C851),
    );
  }

  void _handleMuteMachine(String alertId) {
    final alert = _allAlerts.firstWhere((a) => a['id'] == alertId);
    _showFlushbar(
      'Machine muted',
      '${alert['machineName']} alerts muted for 1 hour',
      const Color(0xFFFF8800),
    );
  }

  void _handleViewDetails(String alertId) {
    final alert = _allAlerts.firstWhere((a) => a['id'] == alertId);
    Navigator.pushNamed(
      context,
      '/machine-detail-screen',
      arguments: {
        'machineId': alert['machineId'],
        'highlightParameter': alert['parameter'],
      },
    );
  }

  void _handleDismiss(String alertId) {
    setState(() {
      _allAlerts.removeWhere((a) => a['id'] == alertId);
    });
    _showFlushbar(
      'Alert dismissed',
      'Alert has been removed',
      const Color(0xFF17A2B8),
    );
  }

  void _handleBulkAcknowledge() {
    setState(() {
      for (var alertId in _selectedAlerts) {
        final alert = _allAlerts.firstWhere((a) => a['id'] == alertId);
        alert['isResolved'] = true;
        alert['autoDismissSeconds'] = 60;
      }
    });
    _exitMultiSelectMode();
    _showFlushbar(
      'Alerts acknowledged',
      '${_selectedAlerts.length} alerts acknowledged',
      const Color(0xFF00C851),
    );
  }

  void _handleBulkDismiss() {
    setState(() {
      _allAlerts.removeWhere((a) => _selectedAlerts.contains(a['id']));
    });
    _exitMultiSelectMode();
    _showFlushbar(
      'Alerts dismissed',
      '${_selectedAlerts.length} alerts dismissed',
      const Color(0xFF17A2B8),
    );
  }

  void _handleExportLog() {
    _exitMultiSelectMode();
    _showFlushbar(
      'Export started',
      'Alert log export in progress',
      const Color(0xFF17A2B8),
    );
  }

  void _showAlertSettings() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AlertSettingsBottomSheet(
        notificationPreferences: _notificationPreferences,
        soundEnabled: _soundEnabled,
        vibrationEnabled: _vibrationEnabled,
        onSave: (preferences, sound, vibration) {
          setState(() {
            _notificationPreferences = preferences;
            _soundEnabled = sound;
            _vibrationEnabled = vibration;
          });
          _showFlushbar(
            'Settings saved',
            'Alert preferences updated successfully',
            const Color(0xFF00C851),
          );
        },
      ),
    );
  }

  void _showFlushbar(String title, String message, Color color) {
    Flushbar(
      title: title,
      message: message,
      duration: const Duration(seconds: 3),
      backgroundColor: color,
      margin: EdgeInsets.all(2.w),
      borderRadius: BorderRadius.circular(8),
      icon: CustomIconWidget(
        iconName: 'check_circle',
        color: Colors.white,
        size: 24,
      ),
      leftBarIndicatorColor: Colors.white,
    ).show(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: _isMultiSelectMode
          ? _buildMultiSelectAppBar(theme)
          : _buildNormalAppBar(theme),
      body: _filteredAlerts.isEmpty
          ? _buildEmptyState(theme)
          : _buildAlertsList(theme),
      bottomNavigationBar: const CustomBottomBar(currentIndex: 2),
      floatingActionButton: _isMultiSelectMode
          ? null
          : FloatingActionButton(
              onPressed: _showAlertSettings,
              child: CustomIconWidget(
                iconName: 'settings',
                color: Colors.white,
                size: 24,
              ),
            ),
    );
  }

  PreferredSizeWidget _buildNormalAppBar(ThemeData theme) {
    return AppBar(
      title: Row(
        children: [
          const Text('Alerts'),
          if (_unreadCount > 0) ...[
            SizedBox(width: 2.w),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
              decoration: BoxDecoration(
                color: const Color(0xFFDC3545),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _unreadCount.toString(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        IconButton(
          onPressed: _handleMarkAllRead,
          icon: CustomIconWidget(
            iconName: 'done_all',
            color: theme.colorScheme.onSurface,
            size: 24,
          ),
          tooltip: 'Mark all as read',
        ),
      ],
    );
  }

  PreferredSizeWidget _buildMultiSelectAppBar(ThemeData theme) {
    return AppBar(
      leading: IconButton(
        onPressed: _exitMultiSelectMode,
        icon: CustomIconWidget(
          iconName: 'close',
          color: theme.colorScheme.onSurface,
          size: 24,
        ),
      ),
      title: Text('${_selectedAlerts.length} selected'),
      actions: [
        IconButton(
          onPressed: _handleBulkAcknowledge,
          icon: CustomIconWidget(
            iconName: 'check',
            color: theme.colorScheme.onSurface,
            size: 24,
          ),
          tooltip: 'Acknowledge',
        ),
        IconButton(
          onPressed: _handleExportLog,
          icon: CustomIconWidget(
            iconName: 'download',
            color: theme.colorScheme.onSurface,
            size: 24,
          ),
          tooltip: 'Export',
        ),
        IconButton(
          onPressed: _handleBulkDismiss,
          icon: CustomIconWidget(
            iconName: 'delete',
            color: theme.colorScheme.onSurface,
            size: 24,
          ),
          tooltip: 'Dismiss',
        ),
      ],
    );
  }

  Widget _buildAlertsList(ThemeData theme) {
    return Column(
      children: [
        // Filter chips
        Container(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _filterOptions.map((filter) {
                final Color? chipColor = filter == 'Critical'
                    ? const Color(0xFFDC3545)
                    : filter == 'Warning'
                        ? const Color(0xFFFF8800)
                        : filter == 'Status'
                            ? const Color(0xFF17A2B8)
                            : null;

                return Padding(
                  padding: EdgeInsets.only(right: 2.w),
                  child: AlertFilterChip(
                    label: filter,
                    isSelected: _selectedFilter == filter,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() {
                        _selectedFilter = filter;
                      });
                    },
                    selectedColor: chipColor,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        // Alerts list
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => _handleRefresh(),
            child: ListView.builder(
              padding: EdgeInsets.only(bottom: 2.h),
              itemCount: _filteredAlerts.length,
              itemBuilder: (context, index) {
                final alert = _filteredAlerts[index];
                return AlertCard(
                  alert: alert,
                  onTap: () => _handleAlertTap(alert),
                  onAcknowledge: () =>
                      _handleAcknowledge(alert['id'] as String),
                  onMuteMachine: () =>
                      _handleMuteMachine(alert['id'] as String),
                  onViewDetails: () =>
                      _handleViewDetails(alert['id'] as String),
                  onDismiss: alert['type'] != 'critical'
                      ? () => _handleDismiss(alert['id'] as String)
                      : null,
                  isMultiSelectMode: _isMultiSelectMode,
                  isSelected: _selectedAlerts.contains(alert['id']),
                  onLongPress: () => _handleLongPress(alert),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(6.w),
            decoration: BoxDecoration(
              color: const Color(0xFF00C851).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: CustomIconWidget(
              iconName: 'check_circle',
              color: const Color(0xFF00C851),
              size: 60,
            ),
          ),
          SizedBox(height: 3.h),
          Text(
            'All Clear!',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF00C851),
            ),
          ),
          SizedBox(height: 1.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.w),
            child: Text(
              'No active alerts. All machines are operating normally.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 3.h),
          ElevatedButton.icon(
            onPressed: _handleRefresh,
            icon: CustomIconWidget(
              iconName: 'refresh',
              color: Colors.white,
              size: 20,
            ),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }
}
