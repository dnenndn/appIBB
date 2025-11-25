import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Bottom sheet for alert settings and preferences
class AlertSettingsBottomSheet extends StatefulWidget {
  final Map<String, bool> notificationPreferences;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final Function(Map<String, bool>, bool, bool) onSave;

  const AlertSettingsBottomSheet({
    super.key,
    required this.notificationPreferences,
    required this.soundEnabled,
    required this.vibrationEnabled,
    required this.onSave,
  });

  @override
  State<AlertSettingsBottomSheet> createState() =>
      _AlertSettingsBottomSheetState();
}

class _AlertSettingsBottomSheetState extends State<AlertSettingsBottomSheet> {
  late Map<String, bool> _preferences;
  late bool _soundEnabled;
  late bool _vibrationEnabled;

  @override
  void initState() {
    super.initState();
    _preferences = Map.from(widget.notificationPreferences);
    _soundEnabled = widget.soundEnabled;
    _vibrationEnabled = widget.vibrationEnabled;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: EdgeInsets.only(top: 1.h),
              width: 10.w,
              height: 0.5.h,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: EdgeInsets.all(4.w),
              child: Row(
                children: [
                  CustomIconWidget(
                    iconName: 'settings',
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                  SizedBox(width: 3.w),
                  Text(
                    'Alert Settings',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context);
                    },
                    icon: CustomIconWidget(
                      iconName: 'close',
                      color: theme.colorScheme.onSurface,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: theme.colorScheme.outline),
            // Settings content
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(4.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Notification preferences section
                    Text(
                      'Notification Preferences',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    _buildSwitchTile(
                      context,
                      'Critical Alerts',
                      'Receive notifications for critical machine issues',
                      _preferences['critical'] ?? true,
                      (value) {
                        setState(() {
                          _preferences['critical'] = value;
                        });
                      },
                      const Color(0xFFDC3545),
                    ),
                    _buildSwitchTile(
                      context,
                      'Warning Alerts',
                      'Receive notifications for warning conditions',
                      _preferences['warning'] ?? true,
                      (value) {
                        setState(() {
                          _preferences['warning'] = value;
                        });
                      },
                      const Color(0xFFFF8800),
                    ),
                    _buildSwitchTile(
                      context,
                      'Status Changes',
                      'Receive notifications for machine status updates',
                      _preferences['status'] ?? true,
                      (value) {
                        setState(() {
                          _preferences['status'] = value;
                        });
                      },
                      const Color(0xFF17A2B8),
                    ),
                    SizedBox(height: 3.h),
                    // Sound and vibration section
                    Text(
                      'Alert Feedback',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    _buildSwitchTile(
                      context,
                      'Sound',
                      'Play sound for new alerts',
                      _soundEnabled,
                      (value) {
                        setState(() {
                          _soundEnabled = value;
                        });
                      },
                      theme.colorScheme.primary,
                    ),
                    _buildSwitchTile(
                      context,
                      'Vibration',
                      'Vibrate device for new alerts',
                      _vibrationEnabled,
                      (value) {
                        setState(() {
                          _vibrationEnabled = value;
                        });
                      },
                      theme.colorScheme.primary,
                    ),
                    SizedBox(height: 3.h),
                    // Save button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          widget.onSave(
                            _preferences,
                            _soundEnabled,
                            _vibrationEnabled,
                          );
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 2.h),
                        ),
                        child: const Text('Save Settings'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    BuildContext context,
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
    Color accentColor,
  ) {
    final theme = Theme.of(context);

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: CustomIconWidget(
              iconName: 'notifications',
              color: accentColor,
              size: 20,
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: (newValue) {
              HapticFeedback.lightImpact();
              onChanged(newValue);
            },
            activeColor: accentColor,
          ),
        ],
      ),
    );
  }
}
