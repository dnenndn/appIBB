import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Alert card widget displaying individual alert information
class AlertCard extends StatelessWidget {
  final Map<String, dynamic> alert;
  final VoidCallback onTap;
  final VoidCallback onAcknowledge;
  final VoidCallback onMuteMachine;
  final VoidCallback onViewDetails;
  final VoidCallback? onDismiss;
  final bool isMultiSelectMode;
  final bool isSelected;
  final VoidCallback? onLongPress;
  final bool enableSlidable;

  const AlertCard({
    super.key,
    required this.alert,
    required this.onTap,
    required this.onAcknowledge,
    required this.onMuteMachine,
    required this.onViewDetails,
    this.onDismiss,
    this.isMultiSelectMode = false,
    this.isSelected = false,
    this.onLongPress,
    this.enableSlidable = true,
  });

  Color _getAlertColor(String type) {
    switch (type.toLowerCase()) {
      case 'critical':
        return const Color(0xFFDC3545);
      case 'warning':
        return const Color(0xFFFF8800);
      case 'status':
      case 'normal':
        return const Color(0xFF17A2B8);
      default:
        return const Color(0xFF6C757D);
    }
  }

  IconData _getAlertIcon(String type) {
    switch (type.toLowerCase()) {
      case 'critical':
        return Icons.error;
      case 'warning':
        return Icons.warning;
      case 'status':
      case 'normal':
        return Icons.info;
      default:
        return Icons.notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final alertColor = _getAlertColor(alert['type'] as String);
    final bool canDismiss = alert['type'] != 'critical';
    final bool isResolved = alert['isResolved'] == true;

    Widget cardContent = Container(
        margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left color stripe
              Container(
                width: 1.w,
                decoration: BoxDecoration(
                  color: alertColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
              ),
              // Main content
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(3.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header row
                      Row(
                        children: [
                          if (isMultiSelectMode)
                            Padding(
                              padding: EdgeInsets.only(right: 2.w),
                              child: CustomIconWidget(
                                iconName: isSelected
                                    ? 'check_circle'
                                    : 'radio_button_unchecked',
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurface
                                        .withValues(alpha: 0.4),
                                size: 20,
                              ),
                            ),
                          CustomIconWidget(
                            iconName: _getAlertIcon(alert['type'] as String)
                                .codePoint
                                .toRadixString(16),
                            color: alertColor,
                            size: 20,
                          ),
                          SizedBox(width: 2.w),
                          Expanded(
                            child: Text(
                              alert['machineName'] as String,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isResolved)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 2.w,
                                vertical: 0.5.h,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00C851)
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Resolved',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: const Color(0xFF00C851),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 1.h),
                      // Alert type and timestamp
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 2.w,
                              vertical: 0.5.h,
                            ),
                            decoration: BoxDecoration(
                              color: alertColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              alert['alertType'] as String,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: alertColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          SizedBox(width: 2.w),
                          CustomIconWidget(
                            iconName: 'access_time',
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                            size: 14,
                          ),
                          SizedBox(width: 1.w),
                          Text(
                            alert['timestamp'] as String,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 1.h),
                      // Current status
                      Text(
                        'Status: ${alert['currentStatus']}',
                        style: theme.textTheme.bodyMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
        ),
      ),
    );

    // Wrap with Slidable for swipe actions (only for active alerts and not in multi-select mode)
    if (!isMultiSelectMode && enableSlidable) {
      return Slidable(
        key: ValueKey(alert['id']),
        startActionPane: ActionPane(
          motion: const DrawerMotion(),
          children: [
            SlidableAction(
              onPressed: (_) {
                HapticFeedback.mediumImpact();
                onAcknowledge();
              },
              backgroundColor: const Color(0xFF00C851),
              foregroundColor: Colors.white,
              icon: Icons.check,
              label: 'Acknowledge',
            ),
            SlidableAction(
              onPressed: (_) {
                HapticFeedback.mediumImpact();
                onViewDetails();
              },
              backgroundColor: const Color(0xFF17A2B8),
              foregroundColor: Colors.white,
              icon: Icons.visibility,
              label: 'Details',
            ),
          ],
        ),
        endActionPane: canDismiss && onDismiss != null
            ? ActionPane(
                motion: const DrawerMotion(),
                children: [
                  SlidableAction(
                    onPressed: (_) {
                      HapticFeedback.mediumImpact();
                      onDismiss!();
                    },
                    backgroundColor: const Color(0xFFDC3545),
                    foregroundColor: Colors.white,
                    icon: Icons.delete,
                    label: 'Dismiss',
                  ),
                ],
              )
            : null,
        child: cardContent,
      );
    }

    return cardContent;
  }
}
