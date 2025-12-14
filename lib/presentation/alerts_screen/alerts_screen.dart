import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../core/services/supabase_service.dart';
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
  // Tab controller for Active/History tabs
  late TabController _tabController;
  
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

  // Supabase service
  final SupabaseService _supabaseService = SupabaseService();
  
  // Alerts data from Supabase
  List<Map<String, dynamic>> _allAlerts = [];
  bool _isLoading = true;
  
  // Track locally acknowledged alerts (user-specific, not stored in DB)
  final Set<String> _locallyAcknowledgedAlerts = {};

  // Get active alerts (not resolved and not locally acknowledged)
  List<Map<String, dynamic>> get _activeAlerts {
    final active = _allAlerts.where((alert) {
      final alertId = alert['id'] as String;
      // Exclude alerts that are resolved in DB OR locally acknowledged
      return alert['isResolved'] != true && !_locallyAcknowledgedAlerts.contains(alertId);
    }).toList();
    if (_selectedFilter == 'All') {
      return active;
    }
    return active.where((alert) =>
        (alert['type'] as String).toLowerCase() ==
        _selectedFilter.toLowerCase()).toList();
  }

  // Get history alerts (resolved/acknowledged - either from DB or locally)
  List<Map<String, dynamic>> get _historyAlerts {
    final history = _allAlerts.where((alert) {
      final alertId = alert['id'] as String;
      // Include alerts that are resolved in DB OR locally acknowledged
      return alert['isResolved'] == true || _locallyAcknowledgedAlerts.contains(alertId);
    }).toList();
    if (_selectedFilter == 'All') {
      return history;
    }
    return history.where((alert) =>
        (alert['type'] as String).toLowerCase() ==
        _selectedFilter.toLowerCase()).toList();
  }

  List<Map<String, dynamic>> get _filteredAlerts {
    // Return alerts based on current tab
    return _tabController.index == 0 ? _activeAlerts : _historyAlerts;
  }

  int get _unreadCount {
    return _allAlerts.where((alert) => alert['isResolved'] != true).length;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Fetch all alerts from Supabase
      final alerts = await _supabaseService.getActiveAlerts();
      
      // Also fetch resolved alerts for history
      final resolvedAlerts = await _supabaseService.getResolvedAlerts();
      
      final allAlertsList = List<Map<String, dynamic>>.from(alerts);
      final resolvedList = List<Map<String, dynamic>>.from(resolvedAlerts);
      
      // Get machine names
      final machines = await _supabaseService.getAllMachines();
      final machineMap = {for (var m in machines) m['id']: m['name']};
      
      // Transform to match expected format
      _allAlerts = [...allAlertsList, ...resolvedList].map((alert) {
        final machineId = alert['machine_id'] as String;
        final alertId = alert['id'] as String;
        // Preserve local acknowledgment state if alert was locally acknowledged
        final isLocallyAcknowledged = _locallyAcknowledgedAlerts.contains(alertId);
        return {
          'id': alertId,
          'machineName': machineMap[machineId] ?? machineId,
          'type': alert['type'] ?? alert['severity'] ?? 'status',
          'alertType': alert['alert_type'] ?? alert['title'] ?? 'Alert',
          'timestamp': _formatTimestamp(alert['created_at']),
          'currentStatus': alert['current_status'] ?? alert['description'] ?? '',
          'isResolved': alert['is_resolved'] ?? false || isLocallyAcknowledged,
          'parameter': alert['parameter'],
          'machineId': machineId,
        };
      }).toList();
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading alerts: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatTimestamp(String? timestamp) {
    if (timestamp == null) return 'Unknown';
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes} min ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
      } else {
        return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
      }
    } catch (e) {
      return 'Unknown';
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleRefresh() async {
    HapticFeedback.mediumImpact();
    await _loadAlerts();
    if (mounted) {
      _showFlushbar(
        'Alerts refreshed',
        'All alerts are up to date',
        const Color(0xFF00C851),
      );
    }
  }


  void _handleAlertTap(Map<String, dynamic> alert) {
    // Cards are not clickable - do nothing
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
    // Handle acknowledgment internally (user-specific, not stored in DB)
    setState(() {
      // Mark as locally acknowledged
      _locallyAcknowledgedAlerts.add(alertId);
      
      // Update local state
      final alert = _allAlerts.firstWhere((a) => a['id'] == alertId);
      alert['isResolved'] = true;
      // Alert will now appear in history tab
    });
    
    _showFlushbar(
      'Alert acknowledged',
      'Alert has been moved to history',
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
    // Use SchedulerBinding to ensure navigation happens after the current frame
    // This prevents Navigator lock errors when called from SlidableAction
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.pushNamed(
          context,
          '/machine-detail-screen',
          arguments: {
            'machineId': alert['machineId'],
            'highlightParameter': alert['parameter'],
          },
        );
      }
    });
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
    // Handle acknowledgment internally (user-specific, not stored in DB)
    setState(() {
      for (var alertId in _selectedAlerts) {
        // Mark as locally acknowledged
        _locallyAcknowledgedAlerts.add(alertId);
        
        // Update local state
        final alert = _allAlerts.firstWhere((a) => a['id'] == alertId);
        alert['isResolved'] = true;
        // Alerts will now appear in history tab
      }
    });
    
    _exitMultiSelectMode();
    _showFlushbar(
      'Alerts acknowledged',
      '${_selectedAlerts.length} alerts moved to history',
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
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _activeAlerts.isEmpty
                    ? _buildEmptyStateWithFilters(theme, 'No Active Alerts', 'All alerts are resolved', _activeAlerts)
                    : _buildAlertsList(theme, _activeAlerts, isHistory: false),
                _historyAlerts.isEmpty
                    ? _buildEmptyStateWithFilters(theme, 'No History', 'No acknowledged alerts yet', _historyAlerts)
                    : _buildAlertsList(theme, _historyAlerts, isHistory: true),
              ],
            ),
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
      automaticallyImplyLeading: false, // Remove back arrow
      title: Row(
        children: [
          const Text('Alerts'),
          if (_activeAlerts.length > 0) ...[
            SizedBox(width: 2.w),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
              decoration: BoxDecoration(
                color: const Color(0xFFDC3545),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _activeAlerts.length.toString(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
      bottom: TabBar(
        controller: _tabController,
        labelColor: theme.colorScheme.onPrimaryContainer,
        unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
        indicatorColor: theme.colorScheme.primary,
        tabs: const [
          Tab(text: 'Active'),
          Tab(text: 'History'),
        ],
        onTap: (index) {
          setState(() {}); // Refresh to show correct alerts
        },
      ),
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

  Widget _buildAlertsList(ThemeData theme, List<Map<String, dynamic>> alerts, {bool isHistory = false}) {
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
              itemCount: alerts.length,
              itemBuilder: (context, index) {
                final alert = alerts[index];
                // Apply filter
                if (_selectedFilter != 'All' &&
                    (alert['type'] as String).toLowerCase() !=
                        _selectedFilter.toLowerCase()) {
                  return const SizedBox.shrink();
                }
                return AlertCard(
                  alert: alert,
                  onTap: () {}, // Cards not clickable
                  onAcknowledge: () =>
                      _handleAcknowledge(alert['id'] as String),
                  onMuteMachine: () =>
                      _handleMuteMachine(alert['id'] as String),
                  onViewDetails: () =>
                      _handleViewDetails(alert['id'] as String),
                  onDismiss: null, // Remove dismiss functionality
                  isMultiSelectMode: _isMultiSelectMode,
                  isSelected: _selectedAlerts.contains(alert['id']),
                  onLongPress: () => _handleLongPress(alert),
                  enableSlidable: !isHistory, // Disable slidable for history alerts
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyStateWithFilters(ThemeData theme, String title, String message, List<Map<String, dynamic>> alerts) {
    return Column(
      children: [
        // Filter chips - always visible
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
        // Empty state content
        Expanded(
          child: Center(
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
                  title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF00C851),
                  ),
                ),
                SizedBox(height: 1.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10.w),
                  child: Text(
                    message,
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
          ),
        ),
      ],
    );
  }
}
