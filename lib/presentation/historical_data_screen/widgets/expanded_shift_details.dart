import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';
import 'machine_subcard.dart';

/// Expanded details view for shift card
class ExpandedShiftDetails extends StatelessWidget {
  final Map<String, dynamic> shiftData;

  const ExpandedShiftDetails({
    super.key,
    required this.shiftData,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final machines = shiftData['machines'] as List<Map<String, dynamic>>? ?? [];

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Machine Performance',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          ...machines.map((machine) {
            final explicitType = machine['machine_type'] as String?;
            final machineName = (machine['name'] as String? ?? '').toLowerCase();
            String machineType;
            if (explicitType != null) {
              machineType = explicitType.toLowerCase();
            } else if (machineName.contains('dryer')) {
              machineType = 'dryer';
            } else if (machineName.contains('kiln')) {
              machineType = 'kiln';
            } else {
              machineType = 'unknown';
            }
            return MachineSubcard(
              machineData: machine,
              machineType: machineType,
            );
          }),
          SizedBox(height: 2.h),
          Text(
            'Alert Summary',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          _buildAlertSummary(context),
        ],
      ),
    );
  }

  Widget _buildMachineRow(BuildContext context, Map<String, dynamic> machine) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.5.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              machine['name'] as String? ?? '',
              style: theme.textTheme.bodyMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: Text(
              '${machine['efficiency']}%',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: _getEfficiencyColor(
                  machine['efficiency'] as int? ?? 0,
                  context,
                ),
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertSummary(BuildContext context) {
    final theme = Theme.of(context);
    final alerts = shiftData['alertSummary'] as Map<String, int>? ?? {};

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildAlertBadge(
          context,
          'Critical',
          alerts['critical'] ?? 0,
          theme.colorScheme.error,
        ),
        _buildAlertBadge(
          context,
          'Warning',
          alerts['warning'] ?? 0,
          const Color(0xFFFF8800),
        ),
        _buildAlertBadge(
          context,
          'Info',
          alerts['info'] ?? 0,
          theme.colorScheme.secondary,
        ),
      ],
    );
  }

  Widget _buildAlertBadge(
    BuildContext context,
    String label,
    int count,
    Color color,
  ) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color, width: 1),
          ),
          child: Text(
            count.toString(),
            style: theme.textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        SizedBox(height: 0.5.h),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Color _getEfficiencyColor(int efficiency, BuildContext context) {
    final theme = Theme.of(context);
    if (efficiency >= 85) {
      return AppTheme.lightTheme.colorScheme.tertiary;
    } else if (efficiency >= 70) {
      return const Color(0xFFFF8800);
    } else {
      return theme.colorScheme.error;
    }
  }
}
