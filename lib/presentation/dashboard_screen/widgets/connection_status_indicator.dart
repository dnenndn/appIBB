import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

/// Connection status indicator showing PLC sync status
/// Displays real-time connection state with visual feedback
class ConnectionStatusIndicator extends StatelessWidget {
  final bool isConnected;
  final DateTime? lastSyncTime;

  const ConnectionStatusIndicator({
    super.key,
    required this.isConnected,
    this.lastSyncTime,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = isConnected
        ? AppTheme.lightTheme.colorScheme.tertiary
        : AppTheme.lightTheme.colorScheme.error;
    final statusText = isConnected ? 'Connected' : 'Disconnected';

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: statusColor.withValues(alpha: 0.5),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          SizedBox(width: 2.w),
          Text(
            statusText,
            style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
              color: statusColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (lastSyncTime != null && isConnected) ...[
            SizedBox(width: 2.w),
            Text(
              '• ${_formatSyncTime(lastSyncTime!)}',
              style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatSyncTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else {
      return '${difference.inHours}h ago';
    }
  }
}
