import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_app_bar.dart';
import './widgets/export_options_dialog.dart';
import './widgets/parameter_chart.dart';
import './widgets/threshold_control_sheet.dart';
import './widgets/time_range_selector.dart';

/// Parameter Trend Screen - Displays historical graphs with interactive threshold adjustment
class ParameterTrendScreen extends StatefulWidget {
  const ParameterTrendScreen({super.key});

  @override
  State<ParameterTrendScreen> createState() => _ParameterTrendScreenState();
}

class _ParameterTrendScreenState extends State<ParameterTrendScreen> {
  // Mock data for demonstration
  final String _machineName = 'Kiln 1';
  final String _parameterName = 'Burner Temperature';
  final String _unit = '°C';
  double _currentValue = 850.0;
  TimeRange _selectedRange = TimeRange.twentyFourHours;
  double _minThreshold = 750.0;
  double _maxThreshold = 900.0;
  final double _parameterMin = 0.0;
  final double _parameterMax = 1200.0;
  List<ParameterDataPoint> _dataPoints = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    // Simulate data loading
    await Future.delayed(const Duration(milliseconds: 800));

    // Generate mock data points based on selected time range
    final now = DateTime.now();
    final dataPoints = <ParameterDataPoint>[];
    final duration = _selectedRange.duration;
    final intervalMinutes = duration.inMinutes ~/ 50;

    for (int i = 0; i < 50; i++) {
      final timestamp =
          now.subtract(Duration(minutes: intervalMinutes * (49 - i)));
      final baseValue = 850.0;
      final variation = (i % 10 - 5) * 15.0;
      final value = (baseValue + variation).clamp(_parameterMin, _parameterMax);
      dataPoints.add(ParameterDataPoint(
        timestamp: timestamp,
        value: value,
      ));
    }

    setState(() {
      _dataPoints = dataPoints;
      _currentValue = dataPoints.last.value;
      _isLoading = false;
    });
  }

  void _onRangeChanged(TimeRange range) {
    setState(() => _selectedRange = range);
    _loadData();
  }

  void _onMinThresholdChanged(double value) {
    HapticFeedback.lightImpact();
    setState(() => _minThreshold = value);
  }

  void _onMaxThresholdChanged(double value) {
    HapticFeedback.lightImpact();
    setState(() => _maxThreshold = value);
  }

  void _showThresholdControls() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ThresholdControlSheet(
        minThreshold: _minThreshold,
        maxThreshold: _maxThreshold,
        parameterMin: _parameterMin,
        parameterMax: _parameterMax,
        onMinChanged: _onMinThresholdChanged,
        onMaxChanged: _onMaxThresholdChanged,
      ),
    );
  }

  void _showExportOptions() {
    showDialog(
      context: context,
      builder: (context) => ExportOptionsDialog(
        onExportPDF: _exportPDF,
        onExportCSV: _exportCSV,
        onShareScreenshot: _shareScreenshot,
      ),
    );
  }

  void _exportPDF() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'PDF report generated successfully',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white,
              ),
        ),
        backgroundColor: AppTheme.lightTheme.colorScheme.tertiary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _exportCSV() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'CSV data downloaded successfully',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white,
              ),
        ),
        backgroundColor: AppTheme.lightTheme.colorScheme.tertiary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _shareScreenshot() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Screenshot shared successfully',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white,
              ),
        ),
        backgroundColor: AppTheme.lightTheme.colorScheme.tertiary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Color _getStatusColor() {
    if (_currentValue < _minThreshold || _currentValue > _maxThreshold) {
      return AppTheme.lightTheme.colorScheme.error;
    } else if (_currentValue < _minThreshold * 1.1 ||
        _currentValue > _maxThreshold * 0.9) {
      return const Color(0xFFFF8800);
    } else {
      return AppTheme.lightTheme.colorScheme.tertiary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: CustomAppBar.withBack(
        title: _machineName,
        onBackPressed: () => Navigator.pop(context),
        actions: [
          IconButton(
            icon: CustomIconWidget(
              iconName: 'tune',
              color: theme.appBarTheme.foregroundColor ?? Colors.white,
              size: 24,
            ),
            onPressed: _showThresholdControls,
            tooltip: 'Threshold Settings',
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: theme.colorScheme.primary,
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'Loading trend data...',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Header section
                Container(
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    border: Border(
                      bottom: BorderSide(
                        color: theme.colorScheme.outline,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _parameterName,
                                  style: theme.textTheme.titleLarge,
                                ),
                                SizedBox(height: 1.h),
                                Row(
                                  children: [
                                    Container(
                                      width: 3.w,
                                      height: 3.w,
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    SizedBox(width: 2.w),
                                    Text(
                                      '${_currentValue.toStringAsFixed(1)}$_unit',
                                      style: theme.textTheme.headlineSmall
                                          ?.copyWith(
                                        color: _getStatusColor(),
                                        fontWeight: FontWeight.w700,
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
                      TimeRangeSelector(
                        selectedRange: _selectedRange,
                        onRangeChanged: _onRangeChanged,
                      ),
                    ],
                  ),
                ),

                // Chart section
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(4.w),
                    child: Column(
                      children: [
                        Container(
                          height: 50.h,
                          padding: EdgeInsets.all(2.w),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: theme.colorScheme.outline,
                              width: 1,
                            ),
                          ),
                          child: ParameterChart(
                            dataPoints: _dataPoints,
                            minThreshold: _minThreshold,
                            maxThreshold: _maxThreshold,
                            minValue: _parameterMin,
                            maxValue: _parameterMax,
                            unit: _unit,
                            onMinThresholdDragged: _onMinThresholdChanged,
                            onMaxThresholdDragged: _onMaxThresholdChanged,
                          ),
                        ),
                        SizedBox(height: 3.h),

                        // Statistics section
                        _buildStatisticsSection(theme),
                      ],
                    ),
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showExportOptions,
        icon: CustomIconWidget(
          iconName: 'file_download',
          color: Colors.white,
          size: 24,
        ),
        label: Text(
          'Export',
          style: theme.textTheme.labelLarge?.copyWith(
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildStatisticsSection(ThemeData theme) {
    final average = _dataPoints.isEmpty
        ? 0.0
        : _dataPoints.map((p) => p.value).reduce((a, b) => a + b) /
            _dataPoints.length;
    final min = _dataPoints.isEmpty
        ? 0.0
        : _dataPoints.map((p) => p.value).reduce((a, b) => a < b ? a : b);
    final max = _dataPoints.isEmpty
        ? 0.0
        : _dataPoints.map((p) => p.value).reduce((a, b) => a > b ? a : b);

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statistics',
            style: theme.textTheme.titleMedium,
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  theme: theme,
                  label: 'Average',
                  value: '${average.toStringAsFixed(1)}$_unit',
                  color: theme.colorScheme.primary,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildStatCard(
                  theme: theme,
                  label: 'Minimum',
                  value: '${min.toStringAsFixed(1)}$_unit',
                  color: AppTheme.lightTheme.colorScheme.tertiary,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildStatCard(
                  theme: theme,
                  label: 'Maximum',
                  value: '${max.toStringAsFixed(1)}$_unit',
                  color: AppTheme.lightTheme.colorScheme.error,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required ThemeData theme,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
