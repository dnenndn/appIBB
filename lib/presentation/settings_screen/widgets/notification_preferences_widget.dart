import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class NotificationPreferencesWidget extends StatelessWidget {
  final Map<String, bool> preferences;
  final Function(String, bool) onPreferenceChanged;

  const NotificationPreferencesWidget({
    Key? key,
    required this.preferences,
    required this.onPreferenceChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final notificationTypes = [
      {
        'key': 'critical_alarms',
        'title': 'Critical Alarms',
        'subtitle': 'High priority equipment alerts'
      },
      {
        'key': 'warning_alarms',
        'title': 'Warning Alarms',
        'subtitle': 'Medium priority notifications'
      },
      {
        'key': 'maintenance_alerts',
        'title': 'Maintenance Alerts',
        'subtitle': 'Scheduled maintenance reminders'
      },
      {
        'key': 'system_updates',
        'title': 'System Updates',
        'subtitle': 'App and system notifications'
      },
    ];

    return Column(
      children: notificationTypes.map((type) {
        final key = type['key'] as String;
        final title = type['title'] as String;
        final subtitle = type['subtitle'] as String;
        final isEnabled = preferences[key] ?? true;

        return Container(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
          child: Row(
            children: [
              Container(
                width: 10.w,
                height: 10.w,
                decoration: BoxDecoration(
                  color:
                      AppTheme.lightTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: CustomIconWidget(
                  iconName: 'notifications',
                  color: AppTheme.lightTheme.primaryColor,
                  size: 5.w,
                ),
              ),
              SizedBox(width: 4.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textMediumEmphasisLight,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              SizedBox(width: 2.w),
              Switch(
                value: isEnabled,
                onChanged: (value) => onPreferenceChanged(key, value),
                activeColor: AppTheme.lightTheme.primaryColor,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
