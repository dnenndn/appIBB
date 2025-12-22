import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

/// Subcard displaying machine-specific metrics for a shift
class MachineSubcard extends StatelessWidget {
  final Map<String, dynamic> machineData;
  final String machineType; // 'dryer' or 'kiln'

  const MachineSubcard({
    super.key,
    required this.machineData,
    required this.machineType,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final machineName = machineData['machine_name'] as String? ?? 
                       machineData['name'] as String? ?? 'Unknown Machine';
    
    // Determine machine type from name if not provided
    final type = machineType.toLowerCase();
    final isDryer = type.contains('dryer');
    final isKiln = type.contains('kiln');

    return Container(
      margin: EdgeInsets.only(bottom: 1.5.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Machine name header
          Row(
            children: [
              Icon(
                isDryer ? Icons.water_drop : Icons.local_fire_department,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  machineName,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          // Metrics grid
          if (isDryer) _buildDryerMetrics(context) else _buildKilnMetrics(context),
        ],
      ),
    );
  }

  Widget _buildDryerMetrics(BuildContext context) {
    final theme = Theme.of(context);
    
    // Extract values with fallbacks
    final gasConsumption = (machineData['gas_consumption'] as num?)?.toDouble() ?? 
                          (machineData['energy_consumption'] as num?)?.toDouble() ?? 0.0;
    final wagons = (machineData['wagons'] as num?)?.toInt() ?? 
                  (machineData['production_units'] as num?)?.toInt() ?? 0;
    final avgCutsPerMinute = (machineData['avg_cuts_per_minute'] as num?)?.toDouble() ?? 
                            (machineData['avg_cut_per_min'] as num?)?.toDouble() ?? 0.0;
    final downtimeMinutes = (machineData['downtime_minutes'] as num?)?.toInt() ?? 
                           (machineData['downtime'] as num?)?.toInt() ?? 0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricItem(
                context,
                'Gas Consumption',
                '${gasConsumption.toStringAsFixed(1)} kWh',
                Icons.local_gas_station,
              ),
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: _buildMetricItem(
                context,
                'Wagons',
                wagons.toString(),
                Icons.inventory_2,
              ),
            ),
          ],
        ),
        SizedBox(height: 1.5.h),
        Row(
          children: [
            Expanded(
              child: _buildMetricItem(
                context,
                'Avg Cuts/Min',
                avgCutsPerMinute.toStringAsFixed(1),
                Icons.speed,
              ),
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: _buildMetricItem(
                context,
                'Downtime',
                '${downtimeMinutes} min',
                Icons.pause_circle,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKilnMetrics(BuildContext context) {
    final theme = Theme.of(context);
    
    // Extract values with fallbacks
    final wagons = (machineData['wagons'] as num?)?.toInt() ?? 
                  (machineData['production_units'] as num?)?.toInt() ?? 0;
    final avgPushTime = (machineData['avg_push_time'] as num?)?.toDouble() ?? 
                       (machineData['avg_push_time_minutes'] as num?)?.toDouble() ?? 0.0;
    final gasConsumption = (machineData['gas_consumption'] as num?)?.toDouble() ?? 
                          (machineData['energy_consumption'] as num?)?.toDouble() ?? 0.0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricItem(
                context,
                'Wagons',
                wagons.toString(),
                Icons.inventory_2,
              ),
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: _buildMetricItem(
                context,
                'Avg Push Time',
                '${avgPushTime.toStringAsFixed(1)} min',
                Icons.timer,
              ),
            ),
          ],
        ),
        SizedBox(height: 1.5.h),
        Row(
          children: [
            Expanded(
              child: _buildMetricItem(
                context,
                'Gas Consumption',
                '${gasConsumption.toStringAsFixed(1)} kWh',
                Icons.local_gas_station,
              ),
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: SizedBox(), // Empty space for alignment
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              SizedBox(width: 1.w),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 10.sp,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 0.5.h),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 12.sp,
            ),
          ),
        ],
      ),
    );
  }
}

