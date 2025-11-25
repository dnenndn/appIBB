import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

/// Data point for parameter trend chart
class ParameterDataPoint {
  final DateTime timestamp;
  final double value;

  const ParameterDataPoint({
    required this.timestamp,
    required this.value,
  });
}

/// Interactive line chart for parameter trends
class ParameterChart extends StatefulWidget {
  final List<ParameterDataPoint> dataPoints;
  final double minThreshold;
  final double maxThreshold;
  final double minValue;
  final double maxValue;
  final String unit;
  final ValueChanged<double>? onMinThresholdDragged;
  final ValueChanged<double>? onMaxThresholdDragged;

  const ParameterChart({
    super.key,
    required this.dataPoints,
    required this.minThreshold,
    required this.maxThreshold,
    required this.minValue,
    required this.maxValue,
    required this.unit,
    this.onMinThresholdDragged,
    this.onMaxThresholdDragged,
  });

  @override
  State<ParameterChart> createState() => _ParameterChartState();
}

class _ParameterChartState extends State<ParameterChart> {
  int? _touchedIndex;
  bool _isDraggingMinThreshold = false;
  bool _isDraggingMaxThreshold = false;

  Color _getZoneColor(double value) {
    if (value < widget.minThreshold || value > widget.maxThreshold) {
      return AppTheme.lightTheme.colorScheme.error;
    } else if (value < widget.minThreshold * 1.1 ||
        value > widget.maxThreshold * 0.9) {
      return const Color(0xFFFF8800);
    } else {
      return AppTheme.lightTheme.colorScheme.tertiary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.dataPoints.isEmpty) {
      return Center(
        child: Text(
          'No data available',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      );
    }

    return GestureDetector(
      onVerticalDragUpdate: (details) {
        if (_isDraggingMinThreshold || _isDraggingMaxThreshold) {
          final renderBox = context.findRenderObject() as RenderBox;
          final localPosition = renderBox.globalToLocal(details.globalPosition);
          final chartHeight = renderBox.size.height - 40;
          final relativeY = (chartHeight - localPosition.dy) / chartHeight;
          final value =
              widget.minValue + (widget.maxValue - widget.minValue) * relativeY;

          if (_isDraggingMinThreshold && widget.onMinThresholdDragged != null) {
            widget.onMinThresholdDragged!(value.clamp(
              widget.minValue,
              widget.maxThreshold - 1,
            ));
          } else if (_isDraggingMaxThreshold &&
              widget.onMaxThresholdDragged != null) {
            widget.onMaxThresholdDragged!(value.clamp(
              widget.minThreshold + 1,
              widget.maxValue,
            ));
          }
        }
      },
      onVerticalDragEnd: (_) {
        setState(() {
          _isDraggingMinThreshold = false;
          _isDraggingMaxThreshold = false;
        });
      },
      child: Semantics(
        label: 'Parameter trend chart showing historical data',
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: true,
              horizontalInterval: (widget.maxValue - widget.minValue) / 5,
              verticalInterval: 1,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  strokeWidth: 1,
                );
              },
              getDrawingVerticalLine: (value) {
                return FlLine(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  strokeWidth: 1,
                );
              },
            ),
            titlesData: FlTitlesData(
              show: true,
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  interval: widget.dataPoints.length / 4,
                  getTitlesWidget: (value, meta) {
                    if (value.toInt() >= 0 &&
                        value.toInt() < widget.dataPoints.length) {
                      final point = widget.dataPoints[value.toInt()];
                      return Padding(
                        padding: EdgeInsets.only(top: 1.h),
                        child: Text(
                          '${point.timestamp.hour}:${point.timestamp.minute.toString().padLeft(2, '0')}',
                          style: theme.textTheme.labelSmall,
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: (widget.maxValue - widget.minValue) / 5,
                  reservedSize: 42,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      '${value.toStringAsFixed(0)}${widget.unit}',
                      style: theme.textTheme.labelSmall,
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(
              show: true,
              border: Border.all(
                color: theme.colorScheme.outline,
                width: 1,
              ),
            ),
            minX: 0,
            maxX: widget.dataPoints.length.toDouble() - 1,
            minY: widget.minValue,
            maxY: widget.maxValue,
            lineBarsData: [
              LineChartBarData(
                spots: widget.dataPoints.asMap().entries.map((entry) {
                  return FlSpot(
                    entry.key.toDouble(),
                    entry.value.value,
                  );
                }).toList(),
                isCurved: true,
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withValues(alpha: 0.5),
                  ],
                ),
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) {
                    final color = _getZoneColor(spot.y);
                    return FlDotCirclePainter(
                      radius: _touchedIndex == index ? 6 : 4,
                      color: color,
                      strokeWidth: 2,
                      strokeColor: theme.colorScheme.surface,
                    );
                  },
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary.withValues(alpha: 0.3),
                      theme.colorScheme.primary.withValues(alpha: 0.0),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ],
            extraLinesData: ExtraLinesData(
              horizontalLines: [
                // Min threshold line
                HorizontalLine(
                  y: widget.minThreshold,
                  color: AppTheme.lightTheme.colorScheme.tertiary,
                  strokeWidth: 2,
                  dashArray: [5, 5],
                  label: HorizontalLineLabel(
                    show: true,
                    alignment: Alignment.topRight,
                    padding: EdgeInsets.only(right: 1.w, bottom: 0.5.h),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.tertiary,
                      fontWeight: FontWeight.w600,
                    ),
                    labelResolver: (line) => 'Min',
                  ),
                ),
                // Max threshold line
                HorizontalLine(
                  y: widget.maxThreshold,
                  color: AppTheme.lightTheme.colorScheme.error,
                  strokeWidth: 2,
                  dashArray: [5, 5],
                  label: HorizontalLineLabel(
                    show: true,
                    alignment: Alignment.bottomRight,
                    padding: EdgeInsets.only(right: 1.w, top: 0.5.h),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                    labelResolver: (line) => 'Max',
                  ),
                ),
              ],
            ),
            lineTouchData: LineTouchData(
              enabled: true,
              touchCallback: (FlTouchEvent event, LineTouchResponse? response) {
                if (response == null || response.lineBarSpots == null) {
                  setState(() {
                    _touchedIndex = null;
                  });
                  return;
                }
                setState(() {
                  _touchedIndex = response.lineBarSpots!.first.spotIndex;
                });
              },
              touchTooltipData: LineTouchTooltipData(
                tooltipBgColor: theme.colorScheme.surface.withValues(alpha: 0.9),
                tooltipRoundedRadius: 8,
                tooltipPadding: EdgeInsets.all(2.w),
                getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                  return touchedBarSpots.map((barSpot) {
                    final point = widget.dataPoints[barSpot.spotIndex];
                    return LineTooltipItem(
                      '${point.value.toStringAsFixed(1)}${widget.unit}\n${point.timestamp.hour}:${point.timestamp.minute.toString().padLeft(2, '0')}',
                      theme.textTheme.labelMedium!.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  }).toList();
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}