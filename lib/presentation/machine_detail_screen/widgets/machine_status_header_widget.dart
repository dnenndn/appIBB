import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

/// Header widget displaying machine name, type, and live status indicator
class MachineStatusHeaderWidget extends StatelessWidget {
  final String machineName;
  final String machineType;
  final String status;
  final DateTime lastUpdated;

  const MachineStatusHeaderWidget({
    super.key,
    required this.machineName,
    required this.machineType,
    required this.status,
    required this.lastUpdated,
  });

  Color _getStatusColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppTheme.getStatusColor(status, isDark: isDark);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _getStatusColor(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        machineName,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        machineType,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: statusColor,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: statusColor.withValues(alpha: 0.3),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: statusColor.withValues(alpha: 0.5),
                              blurRadius: 6,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        status.toUpperCase(),
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                CustomIconWidget(
                  iconName: 'update',
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                SizedBox(width: 1.w),
                Text(
                  'Last updated: ${_formatTimestamp(lastUpdated)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else {
      return '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }
}
