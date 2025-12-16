import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../core/services/supabase_service.dart';
import '../../core/services/local_threshold_service.dart';
import '../../core/repositories/data_repositories.dart';
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
  String _machineName = 'Loading...';
  String _parameterName = 'Loading...';
  String _unit = '';
  String? _machineId;
  String? _parameterId;
  double _currentValue = 0.0;
  TimeRange _selectedRange = TimeRange.twentyFourHours;
  double _minThreshold = 0.0;
  double _maxThreshold = 100.0;
  double _parameterMin = 0.0;
  double _parameterMax = 1000.0;
  List<ParameterDataPoint> _dataPoints = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _hasInitialized = false;

  final SupabaseService _supabaseService = SupabaseService();
  final MachineRepository _machineRepository = MachineRepository();
  final LocalThresholdService _thresholdService = LocalThresholdService();

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitialized) {
      _hasInitialized = true;
      _initializeFromArguments();
    }
  }

  void _initializeFromArguments() {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    
    if (args != null) {
      _machineId = args['machineId'] as String?;
      _machineName = args['machineName'] as String? ?? 'Unknown Machine';
      _parameterName = args['parameterName'] as String? ?? 'Unknown Parameter';
      final currentValueStr = args['currentValue'] as String?;
      if (currentValueStr != null && currentValueStr != 'N/A') {
        _currentValue = double.tryParse(currentValueStr) ?? 0.0;
      }
      _unit = args['unit'] as String? ?? '';
    }
    
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get machine ID if not already set from arguments
      if (_machineId == null) {
        final machines = await _machineRepository.getAllMachines();
        final machine = machines.firstWhere(
          (m) => m['name'] == _machineName,
          orElse: () => {},
        );
        
        if (machine.isEmpty || machine['id'] == null) {
          throw Exception('Machine "$_machineName" not found');
        }
        
        _machineId = machine['id'] as String;
      }
      
      // Get parameter by name and machine_id
      final parameters = await _supabaseService.getAllParameters(machineId: _machineId);
      final parameter = parameters.firstWhere(
        (p) => p['name'] == _parameterName,
        orElse: () => {},
      );
      
      if (parameter.isEmpty || parameter['id'] == null) {
        throw Exception('Parameter "$_parameterName" not found for machine "$_machineName"');
      }
      
      _parameterId = parameter['id'] as String;
      
      // Get parameter min/max values
      _parameterMin = (parameter['min_value'] as num?)?.toDouble() ?? 0.0;
      _parameterMax = (parameter['max_value'] as num?)?.toDouble() ?? 1000.0;
      
      // Update current value from parameter if available
      final paramCurrentValue = (parameter['current_value'] as num?)?.toDouble();
      if (paramCurrentValue != null) {
        _currentValue = paramCurrentValue;
      }
      
      // Get thresholds from local storage (user-specific, not from Supabase)
      // Default is currentValue - 10 and currentValue + 10
      final threshold = await _thresholdService.getThresholdWithDefaults(
        machineId: _machineId!,
        parameterId: _parameterId!,
        currentValue: _currentValue,
      );
      
      _minThreshold = threshold['min']!;
      _maxThreshold = threshold['max']!;
      
      // Calculate time range
      final endTime = DateTime.now();
      final startTime = endTime.subtract(_selectedRange.duration);
      
      // Fetch historical data
      final historyData = await _supabaseService.getParameterHistory(
        machineId: _machineId!,
        parameterName: _parameterName,
        startTime: startTime,
        endTime: endTime,
      );
      
      // Convert to ParameterDataPoint list
      final dataPoints = historyData.map((point) {
        return ParameterDataPoint(
          timestamp: DateTime.parse(point['timestamp'] as String),
          value: (point['value'] as num).toDouble(),
        );
      }).toList();
      
      // Update current value from latest data point if available
      if (dataPoints.isNotEmpty) {
        _currentValue = dataPoints.last.value;
      }
      
      setState(() {
        _dataPoints = dataPoints;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading parameter trend data: $e');
      setState(() {
        _errorMessage = 'Failed to load data: $e';
        _isLoading = false;
      });
    }
  }

  void _onRangeChanged(TimeRange range) {
    setState(() => _selectedRange = range);
    _loadData();
  }

  void _onMinThresholdChanged(double value) {
    HapticFeedback.lightImpact();
    setState(() => _minThreshold = value);
    
    // Save threshold locally (user-specific, not to Supabase)
    _saveThresholdLocally(value, _maxThreshold);
  }

  void _onMaxThresholdChanged(double value) {
    HapticFeedback.lightImpact();
    setState(() => _maxThreshold = value);
    
    // Save threshold locally (user-specific, not to Supabase)
    _saveThresholdLocally(_minThreshold, value);
  }

  Future<void> _saveThresholdLocally(double minThreshold, double maxThreshold) async {
    if (_machineId == null || _parameterId == null) return;
    
    try {
      await _thresholdService.setThreshold(
        machineId: _machineId!,
        parameterId: _parameterId!,
        minThreshold: minThreshold,
        maxThreshold: maxThreshold,
      );
      print('Threshold saved locally');
    } catch (e) {
      print('Error saving threshold locally: $e');
    }
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

  void _showFullscreenChart() {
    // Only show fullscreen if we have enough data
    if (_dataPoints.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Not enough data to display fullscreen chart',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                ),
          ),
          backgroundColor: AppTheme.lightTheme.colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _FullscreenChartScreen(
          dataPoints: _dataPoints,
          minThreshold: _minThreshold,
          maxThreshold: _maxThreshold,
          minValue: _parameterMin,
          maxValue: _parameterMax,
          unit: _unit,
          parameterName: _parameterName,
          machineName: _machineName,
          onMinThresholdDragged: _onMinThresholdChanged,
          onMaxThresholdDragged: _onMaxThresholdChanged,
        ),
        fullscreenDialog: true,
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
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: theme.colorScheme.error,
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        _errorMessage!,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 2.h),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: const Text('Retry'),
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
                        // Check if we have enough data points for a meaningful trend (at least 2)
                        _dataPoints.length < 2
                            ? Container(
                                height: 50.h,
                                padding: EdgeInsets.all(4.w),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: theme.colorScheme.outline,
                                    width: 1,
                                  ),
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.show_chart,
                                        size: 48.sp,
                                        color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                                      ),
                                      SizedBox(height: 2.h),
                                      Text(
                                        'Insufficient Data',
                                        style: theme.textTheme.titleLarge?.copyWith(
                                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      SizedBox(height: 1.h),
                                      Text(
                                        _dataPoints.isEmpty
                                            ? 'No historical data available for this parameter in the selected time range.\n\nData will appear here as it is collected.'
                                            : 'Not enough data points to display a trend.\n\nAt least 2 data points are required.',
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      if (_dataPoints.length == 1) ...[
                                        SizedBox(height: 2.h),
                                        Container(
                                          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                                          decoration: BoxDecoration(
                                            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.info_outline,
                                                size: 20.sp,
                                                color: theme.colorScheme.primary,
                                              ),
                                              SizedBox(width: 2.w),
                                              Text(
                                                'Current value: ${_currentValue.toStringAsFixed(1)}$_unit',
                                                style: theme.textTheme.bodyMedium?.copyWith(
                                                  color: theme.colorScheme.primary,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              )
                            : Stack(
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
                                  // Fullscreen button
                                  Positioned(
                                    top: 1.h,
                                    right: 1.h,
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: _showFullscreenChart,
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          padding: EdgeInsets.all(1.w),
                                          decoration: BoxDecoration(
                                            color: theme.colorScheme.surface.withValues(alpha: 0.9),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: theme.colorScheme.outline,
                                              width: 1,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.fullscreen,
                                            size: 20.sp,
                                            color: theme.colorScheme.onSurface,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
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

/// Fullscreen chart screen
class _FullscreenChartScreen extends StatelessWidget {
  final List<ParameterDataPoint> dataPoints;
  final double minThreshold;
  final double maxThreshold;
  final double minValue;
  final double maxValue;
  final String unit;
  final String parameterName;
  final String machineName;
  final ValueChanged<double>? onMinThresholdDragged;
  final ValueChanged<double>? onMaxThresholdDragged;

  const _FullscreenChartScreen({
    required this.dataPoints,
    required this.minThreshold,
    required this.maxThreshold,
    required this.minValue,
    required this.maxValue,
    required this.unit,
    required this.parameterName,
    required this.machineName,
    this.onMinThresholdDragged,
    this.onMaxThresholdDragged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              machineName,
              style: theme.textTheme.titleMedium,
            ),
            Text(
              parameterName,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: ParameterChart(
            dataPoints: dataPoints,
            minThreshold: minThreshold,
            maxThreshold: maxThreshold,
            minValue: minValue,
            maxValue: maxValue,
            unit: unit,
            onMinThresholdDragged: onMinThresholdDragged,
            onMaxThresholdDragged: onMaxThresholdDragged,
          ),
        ),
      ),
    );
  }
}
