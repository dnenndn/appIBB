import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

/// Quick actions bottom sheet for machine card long-press
/// Provides contextual actions for machine management
class QuickActionsBottomSheet extends StatelessWidget {
  final String machineName;
  final VoidCallback onViewTrends;
  final VoidCallback onMuteAlerts;
  final VoidCallback onPriorityStatus;

  const QuickActionsBottomSheet({
    super.key,
    required this.machineName,
    required this.onViewTrends,
    required this.onMuteAlerts,
    required this.onPriorityStatus,
  });

  static void show(
    BuildContext context, {
    required String machineName,
    required VoidCallback onViewTrends,
    required VoidCallback onMuteAlerts,
    required VoidCallback onPriorityStatus,
  }) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => QuickActionsBottomSheet(
        machineName: machineName,
        onViewTrends: onViewTrends,
        onMuteAlerts: onMuteAlerts,
        onPriorityStatus: onPriorityStatus,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.lightTheme.shadowColor.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 1.h),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant
                    .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 2.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Text(
                machineName,
                style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 2.h),
            _buildActionItem(
              context,
              icon: Icons.show_chart,
              title: 'View Trends',
              subtitle: 'See parameter history',
              onTap: () {
                Navigator.pop(context);
                onViewTrends();
              },
            ),
            _buildActionItem(
              context,
              icon: Icons.notifications_off,
              title: 'Mute Alerts',
              subtitle: 'Temporarily disable notifications',
              onTap: () {
                Navigator.pop(context);
                onMuteAlerts();
              },
            ),
            _buildActionItem(
              context,
              icon: Icons.priority_high,
              title: 'Priority Status',
              subtitle: 'Mark as high priority',
              onTap: () {
                Navigator.pop(context);
                onPriorityStatus();
              },
            ),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  Widget _buildActionItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.primary
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: CustomIconWidget(
                iconName: icon.codePoint.toRadixString(16),
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 24,
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 0.3.h),
                  Text(
                    subtitle,
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            CustomIconWidget(
              iconName: Icons.chevron_right.codePoint.toRadixString(16),
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
