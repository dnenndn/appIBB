import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_bottom_bar.dart';

/// Settings Screen - User preferences and application configuration
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _criticalAlertsEnabled = true;
  bool _warningAlertsEnabled = true;
  bool _statusUpdatesEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: CustomAppBar.standard(
        title: 'Settings',
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshSettings,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(vertical: 2.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildNotificationSection(),
                SizedBox(height: 2.h),
                _buildPreferencesSection(),
                SizedBox(height: 2.h),
                _buildAboutSection(),
                SizedBox(height: 4.h),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const CustomBottomBar(
        currentIndex: 3,
      ),
    );
  }

  Widget _buildNotificationSection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Notifications',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryLight,
                ),
          ),
          SizedBox(height: 1.5.h),
          _buildSettingsTile(
            icon: Icons.notifications_outlined,
            label: 'Push Notifications',
            subtitle: 'Receive notifications on device',
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() {
                _notificationsEnabled = value;
              });
              _showSnackBar('Push notifications ${value ? 'enabled' : 'disabled'}');
            },
          ),
          SizedBox(height: 1.h),
          _buildSettingsTile(
            icon: Icons.error_outline,
            label: 'Critical Alerts',
            subtitle: 'High priority system alerts',
            value: _criticalAlertsEnabled,
            onChanged: (value) {
              setState(() {
                _criticalAlertsEnabled = value;
              });
              _showSnackBar('Critical alerts ${value ? 'enabled' : 'disabled'}');
            },
          ),
          SizedBox(height: 1.h),
          _buildSettingsTile(
            icon: Icons.warning_outlined,
            label: 'Warning Alerts',
            subtitle: 'Medium priority warnings',
            value: _warningAlertsEnabled,
            onChanged: (value) {
              setState(() {
                _warningAlertsEnabled = value;
              });
              _showSnackBar('Warning alerts ${value ? 'enabled' : 'disabled'}');
            },
          ),
          SizedBox(height: 1.h),
          _buildSettingsTile(
            icon: Icons.info_outline,
            label: 'Status Updates',
            subtitle: 'Machine status change notifications',
            value: _statusUpdatesEnabled,
            onChanged: (value) {
              setState(() {
                _statusUpdatesEnabled = value;
              });
              _showSnackBar('Status updates ${value ? 'enabled' : 'disabled'}');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesSection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Preferences',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryLight,
                ),
          ),
          SizedBox(height: 1.5.h),
          _buildActionTile(
            icon: Icons.lock_outline,
            label: 'Change Password',
            subtitle: 'Update your account password',
            onTap: _showChangePasswordDialog,
          ),
          SizedBox(height: 1.h),
          _buildActionTile(
            icon: Icons.delete_sweep_outlined,
            label: 'Clear Cache',
            subtitle: 'Remove stored offline data',
            onTap: _showClearCacheDialog,
          ),
          SizedBox(height: 1.h),
          _buildActionTile(
            icon: Icons.download_outlined,
            label: 'Export Settings',
            subtitle: 'Backup your preferences',
            onTap: _exportSettings,
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryLight,
                ),
          ),
          SizedBox(height: 1.5.h),
          Container(
            padding: EdgeInsets.all(2.5.w),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.borderLight,
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('App Name', 'appIBB'),
                SizedBox(height: 1.h),
                _buildInfoRow('Version', '1.0.0'),
                SizedBox(height: 1.h),
                _buildInfoRow('Build', '1'),
                SizedBox(height: 1.h),
                _buildInfoRow('Environment', 'Production'),
              ],
            ),
          ),
          SizedBox(height: 2.h),
          Center(
            child: ElevatedButton.icon(
              onPressed: _handleLogout,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.criticalLight,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 1.5.h),
              ),
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String label,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.h),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.borderLight,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: AppTheme.primaryLight.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: AppTheme.primaryLight,
              size: 24,
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondaryLight,
                      ),
                ),
              ],
            ),
          ),
          SizedBox(width: 2.w),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.successLight,
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.h),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.borderLight,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: AppTheme.primaryLight,
                size: 24,
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondaryLight,
                        ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 2.w),
            Icon(
              Icons.chevron_right,
              color: AppTheme.textSecondaryLight,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondaryLight,
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }

  Future<void> _refreshSettings() async {
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      _showSnackBar('Settings refreshed');
    }
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Change Password',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          content: const Text('Password change feature coming soon'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Clear Cache',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          content: const Text(
            'This will remove all cached data. Are you sure you want to continue?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showSnackBar('Cache cleared successfully');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.warningLight,
              ),
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );
  }

  void _exportSettings() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Export Settings',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          content: const Text('Export feature coming soon'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Confirm Logout',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          content: const Text(
            'Are you sure you want to logout? You will need to login again to access the application.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login-screen',
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.criticalLight,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
