import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Dialog widget for parameter quick actions
class ParameterQuickActionsDialogWidget extends StatelessWidget {
  final String parameterName;
  final VoidCallback onSetThreshold;
  final VoidCallback onViewHistory;
  final VoidCallback onShareData;

  const ParameterQuickActionsDialogWidget({
    super.key,
    required this.parameterName,
    required this.onSetThreshold,
    required this.onViewHistory,
    required this.onShareData,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              parameterName,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 3.h),
            _buildActionItem(
              context: context,
              icon: 'notifications_active',
              label: 'Set Alert Threshold',
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context);
                onSetThreshold();
              },
            ),
            SizedBox(height: 2.h),
            _buildActionItem(
              context: context,
              icon: 'history',
              label: 'View History',
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context);
                onViewHistory();
              },
            ),
            SizedBox(height: 2.h),
            _buildActionItem(
              context: context,
              icon: 'share',
              label: 'Share Data',
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context);
                onShareData();
              },
            ),
            SizedBox(height: 2.h),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context);
                },
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionItem({
    required BuildContext context,
    required String icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(3.w),
        child: Row(
          children: [
            CustomIconWidget(
              iconName: icon,
              size: 24,
              color: theme.colorScheme.primary,
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyLarge,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
