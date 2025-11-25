import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

/// Card displaying shift information with swipe actions
class ShiftCard extends StatelessWidget {
  final Map<String, dynamic> shiftData;
  final VoidCallback onTap;
  final VoidCallback onGenerateReport;
  final VoidCallback onCompare;
  final VoidCallback onExport;
  final VoidCallback? onLongPress;
  final bool isSelected;

  const ShiftCard({
    super.key,
    required this.shiftData,
    required this.onTap,
    required this.onGenerateReport,
    required this.onCompare,
    required this.onExport,
    this.onLongPress,
    this.isSelected = false,
  });

  Color _getStatusColor(String status, BuildContext context) {
    final theme = Theme.of(context);
    switch (status.toLowerCase()) {
      case 'normal':
        return AppTheme.lightTheme.colorScheme.tertiary;
      case 'warning':
        return const Color(0xFFFF8800);
      case 'critical':
        return theme.colorScheme.error;
      default:
        return theme.colorScheme.outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _getStatusColor(
      shiftData['status'] as String? ?? 'normal',
      context,
    );

    return Slidable(
      key: ValueKey(shiftData['id']),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => onGenerateReport(),
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            icon: Icons.description,
            label: 'Report',
          ),
          SlidableAction(
            onPressed: (_) => onCompare(),
            backgroundColor: theme.colorScheme.secondary,
            foregroundColor: theme.colorScheme.onSecondary,
            icon: Icons.compare_arrows,
            label: 'Compare',
          ),
          SlidableAction(
            onPressed: (_) => onExport(),
            backgroundColor: AppTheme.lightTheme.colorScheme.tertiary,
            foregroundColor: theme.colorScheme.onTertiary,
            icon: Icons.download,
            label: 'Export',
          ),
        ],
      ),
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
          decoration: BoxDecoration(
            color: theme.cardColor,
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
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                // Status indicator
                Container(
                  width: 1.w,
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                  ),
                ),
                // Content
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(3.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    shiftData['date'] as String? ?? '',
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: 0.5.h),
                                  Row(
                                    children: [
                                      CustomIconWidget(
                                        iconName: 'access_time',
                                        size: 16,
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                      ),
                                      SizedBox(width: 1.w),
                                      Text(
                                        '${shiftData['shiftType']} Shift',
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                          color: theme
                                              .colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              CustomIconWidget(
                                iconName: 'check_circle',
                                size: 24,
                                color: theme.colorScheme.primary,
                              ),
                          ],
                        ),
                        SizedBox(height: 2.h),
                        // Metrics row
                        Row(
                          children: [
                            Expanded(
                              child: _buildMetric(
                                context,
                                'Duration',
                                shiftData['duration'] as String? ?? '',
                                Icons.schedule,
                              ),
                            ),
                            Expanded(
                              child: _buildMetric(
                                context,
                                'Production',
                                shiftData['production'] as String? ?? '',
                                Icons.inventory_2,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 1.h),
                        Row(
                          children: [
                            Expanded(
                              child: _buildMetric(
                                context,
                                'Efficiency',
                                shiftData['efficiency'] as String? ?? '',
                                Icons.trending_up,
                              ),
                            ),
                            Expanded(
                              child: _buildMetric(
                                context,
                                'Alerts',
                                shiftData['alertCount'].toString(),
                                Icons.notifications,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetric(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    final theme = Theme.of(context);

    return Row(
      children: [
        CustomIconWidget(
          iconName: icon
              .toString()
              .split('.')
              .last
              .replaceAll('IconData(U+', '')
              .replaceAll(')', ''),
          size: 16,
          color: theme.colorScheme.primary,
        ),
        SizedBox(width: 1.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
