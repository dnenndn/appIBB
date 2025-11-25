import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

/// Bottom sheet widget for machine control actions
class MachineControlsBottomSheetWidget extends StatelessWidget {
  final String machineName;
  final bool hasStartStopPermission;
  final VoidCallback onStartStop;
  final VoidCallback onResetCounters;
  final VoidCallback onExportData;

  const MachineControlsBottomSheetWidget({
    super.key,
    required this.machineName,
    required this.hasStartStopPermission,
    required this.onStartStop,
    required this.onResetCounters,
    required this.onExportData,
  });

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
            SizedBox(height: 1.h),
            Container(
              width: 12.w,
              height: 0.5.h,
              decoration: BoxDecoration(
                color:
                    theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            SizedBox(height: 2.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Machine Controls',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    machineName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: 3.h),
                  if (hasStartStopPermission)
                    _buildControlButton(
                      context: context,
                      icon: 'power_settings_new',
                      label: 'Start/Stop Machine',
                      color: AppTheme.getStatusColor('critical'),
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        Navigator.pop(context);
                        onStartStop();
                      },
                    ),
                  if (hasStartStopPermission) SizedBox(height: 2.h),
                  _buildControlButton(
                    context: context,
                    icon: 'refresh',
                    label: 'Reset Counters',
                    color: AppTheme.getStatusColor('warning'),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context);
                      onResetCounters();
                    },
                  ),
                  SizedBox(height: 2.h),
                  _buildControlButton(
                    context: context,
                    icon: 'download',
                    label: 'Export Data',
                    color: theme.colorScheme.primary,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context);
                      onExportData();
                    },
                  ),
                  SizedBox(height: 3.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required BuildContext context,
    required String icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: CustomIconWidget(
                iconName: icon,
                size: 24,
                color: color,
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            CustomIconWidget(
              iconName: 'arrow_forward_ios',
              size: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
