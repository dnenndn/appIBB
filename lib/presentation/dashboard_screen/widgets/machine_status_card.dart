import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

/// Machine status card widget with dynamic color-coded glow effects
/// Displays real-time machine parameters with visual status indicators
class MachineStatusCard extends StatelessWidget {
  final Map<String, dynamic> machineData;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const MachineStatusCard({
    super.key,
    required this.machineData,
    required this.onTap,
    required this.onLongPress,
  });

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'normal':
        return AppTheme.lightTheme.colorScheme.tertiary;
      case 'warning':
        return const Color(0xFFFF8800);
      case 'critical':
        return AppTheme.lightTheme.colorScheme.error;
      default:
        return AppTheme.lightTheme.colorScheme.onSurfaceVariant;
    }
  }

  IconData _getMachineIcon(String type) {
    switch (type.toLowerCase()) {
      case 'kiln':
        return Icons.local_fire_department;
      case 'dryer':
        return Icons.air;
      default:
        return Icons.precision_manufacturing;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = machineData['status'] as String? ?? 'unknown';
    final statusColor = _getStatusColor(status);
    final machineName = machineData['name'] as String? ?? 'Unknown Machine';
    final machineType = machineData['type'] as String? ?? 'machine';

    // Metrics with fallbacks
    final gasConsumption = (machineData['gas_consumption'] as num?)?.toDouble() ??
        (machineData['energy_consumption'] as num?)?.toDouble() ??
        (machineData['energyConsumption'] as num?)?.toDouble() ??
        0.0;
    final wagons = (machineData['wagons'] as num?)?.toInt() ??
        (machineData['production_units'] as num?)?.toInt() ??
        (machineData['production'] as num?)?.toInt() ??
        0;
    final avgCutsPerMinute = (machineData['avg_cuts_per_minute'] as num?)?.toDouble() ??
        (machineData['avg_cut_per_min'] as num?)?.toDouble() ??
        (machineData['avgCutPerMin'] as num?)?.toDouble() ??
        0.0;
    final downtimeMinutes = (machineData['downtime_minutes'] as num?)?.toInt() ??
        (machineData['downtime'] as num?)?.toInt() ??
        0;
    final avgPushTime = (machineData['avg_push_time'] as num?)?.toDouble() ??
        (machineData['avg_push_time_minutes'] as num?)?.toDouble() ??
        0.0;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: statusColor.withValues(alpha: 0.3),
              blurRadius: 12.0,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: AppTheme.lightTheme.shadowColor.withValues(alpha: 0.1),
              blurRadius: 8.0,
              spreadRadius: 0,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: statusColor.withValues(alpha: 0.5),
            width: 2,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(2.w),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getMachineIcon(machineType),
                      color: statusColor,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          machineName,
                          style: AppTheme.lightTheme.textTheme.titleMedium
                              ?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 0.5.h),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: statusColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: 1.w),
                            Text(
                              status.toUpperCase(),
                              style: AppTheme.lightTheme.textTheme.labelSmall
                                  ?.copyWith(
                                color: statusColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 2.h),
              Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.colorScheme.surface
                      .withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.lightTheme.colorScheme.outline
                        .withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  children: _buildTypeSpecificMetrics(
                    context: context,
                    machineType: machineType,
                    gasConsumption: gasConsumption,
                    wagons: wagons,
                    avgCutsPerMinute: avgCutsPerMinute,
                    downtimeMinutes: downtimeMinutes,
                    avgPushTime: avgPushTime,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildParameterItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Column(
      children: [
        CustomIconWidget(
          iconName: icon.codePoint.toRadixString(16),
          color: AppTheme.lightTheme.colorScheme.primary,
          size: 20,
        ),
        SizedBox(height: 0.5.h),
        Text(
          label,
          style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 0.3.h),
        Text(
          value,
          style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  List<Widget> _buildTypeSpecificMetrics({
    required BuildContext context,
    required String machineType,
    required double gasConsumption,
    required int wagons,
    required double avgCutsPerMinute,
    required int downtimeMinutes,
    required double avgPushTime,
  }) {
    final isDryer = machineType.toLowerCase().contains('dryer');
    final isKiln = machineType.toLowerCase().contains('kiln');

    if (isDryer) {
      return [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: _buildParameterItem(
                context,
                'Gas Consumption',
                '${gasConsumption.toStringAsFixed(1)} kWh',
                Icons.local_gas_station,
              ),
            ),
            Container(
              width: 1,
              height: 40,
              color: AppTheme.lightTheme.colorScheme.outline
                  .withValues(alpha: 0.2),
            ),
            Expanded(
              child: _buildParameterItem(
                context,
                'Wagons',
                wagons.toString(),
                Icons.inventory_2,
              ),
            ),
          ],
        ),
        SizedBox(height: 1.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: _buildParameterItem(
                context,
                'Avg Cuts/Min',
                avgCutsPerMinute.toStringAsFixed(1),
                Icons.speed,
              ),
            ),
            Container(
              width: 1,
              height: 40,
              color: AppTheme.lightTheme.colorScheme.outline
                  .withValues(alpha: 0.2),
            ),
            Expanded(
              child: _buildParameterItem(
                context,
                'Downtime',
                '${downtimeMinutes} min',
                Icons.pause_circle,
              ),
            ),
          ],
        ),
      ];
    }

    if (isKiln) {
      return [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: _buildParameterItem(
                context,
                'Wagons',
                wagons.toString(),
                Icons.inventory_2,
              ),
            ),
            Container(
              width: 1,
              height: 40,
              color: AppTheme.lightTheme.colorScheme.outline
                  .withValues(alpha: 0.2),
            ),
            Expanded(
              child: _buildParameterItem(
                context,
                'Avg Push Time',
                '${avgPushTime.toStringAsFixed(1)} min',
                Icons.timer,
              ),
            ),
          ],
        ),
        SizedBox(height: 1.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: SizedBox()),
            Expanded(
              child: _buildParameterItem(
                context,
                'Gas Consumption',
                '${gasConsumption.toStringAsFixed(1)} kWh',
                Icons.local_gas_station,
              ),
            ),
            Expanded(child: SizedBox()),
          ],
        ),
      ];
    }

    // Fallback for unknown machine types: show gas and wagons
    return [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: _buildParameterItem(
              context,
              'Gas Consumption',
              '${gasConsumption.toStringAsFixed(1)} kWh',
              Icons.local_gas_station,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: AppTheme.lightTheme.colorScheme.outline
                .withValues(alpha: 0.2),
          ),
          Expanded(
            child: _buildParameterItem(
              context,
              'Wagons',
              wagons.toString(),
              Icons.inventory_2,
            ),
          ),
        ],
      ),
    ];
  }
}
