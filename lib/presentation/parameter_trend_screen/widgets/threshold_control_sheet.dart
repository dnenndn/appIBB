import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

/// Bottom sheet for threshold adjustment controls
/// Now supports separate warning and critical thresholds with text input only
class ThresholdControlSheet extends StatefulWidget {
  final double minThreshold;
  final double maxThreshold;
  final double? warningMin;
  final double? warningMax;
  final double parameterMin;
  final double parameterMax;
  final ValueChanged<double> onMinChanged;
  final ValueChanged<double> onMaxChanged;
  final Function(double warningMin, double warningMax, double criticalMin, double criticalMax)? onWarningAndCriticalChanged;
  final Function(double warningMin, double warningMax, double criticalMin, double criticalMax)? onSave;
  final VoidCallback? onCancel;

  const ThresholdControlSheet({
    super.key,
    required this.minThreshold,
    required this.maxThreshold,
    this.warningMin,
    this.warningMax,
    required this.parameterMin,
    required this.parameterMax,
    required this.onMinChanged,
    required this.onMaxChanged,
    this.onWarningAndCriticalChanged,
    this.onSave,
    this.onCancel,
  });

  @override
  State<ThresholdControlSheet> createState() => _ThresholdControlSheetState();
}

class _ThresholdControlSheetState extends State<ThresholdControlSheet> {
  late TextEditingController _warningMinController;
  late TextEditingController _warningMaxController;
  late TextEditingController _criticalMinController;
  late TextEditingController _criticalMaxController;
  late double _warningMin;
  late double _warningMax;
  late double _criticalMin;
  late double _criticalMax;

  @override
  void initState() {
    super.initState();
    // Initialize critical thresholds from widget values
    _criticalMin = widget.minThreshold;
    _criticalMax = widget.maxThreshold;
    
    // Initialize warning thresholds - use provided values or defaults
    if (widget.warningMin != null && widget.warningMax != null) {
      _warningMin = widget.warningMin!;
      _warningMax = widget.warningMax!;
    } else {
      // Defaults are -5 and +5 from current value (which would be middle of critical range)
      final currentValue = (widget.minThreshold + widget.maxThreshold) / 2;
      _warningMin = currentValue - 5;
      _warningMax = currentValue + 5;
    }
    
    _warningMinController = TextEditingController(
      text: _warningMin.toStringAsFixed(1),
    );
    _warningMaxController = TextEditingController(
      text: _warningMax.toStringAsFixed(1),
    );
    _criticalMinController = TextEditingController(
      text: _criticalMin.toStringAsFixed(1),
    );
    _criticalMaxController = TextEditingController(
      text: _criticalMax.toStringAsFixed(1),
    );
  }

  @override
  void dispose() {
    _warningMinController.dispose();
    _warningMaxController.dispose();
    _criticalMinController.dispose();
    _criticalMaxController.dispose();
    super.dispose();
  }

  void _updateWarningMin(String value) {
    final parsed = double.tryParse(value);
    if (parsed != null &&
        parsed >= widget.parameterMin &&
        parsed < _criticalMin) {
      setState(() {
        _warningMin = parsed;
      });
      _notifyThresholdsChanged();
    }
  }

  void _updateWarningMax(String value) {
    final parsed = double.tryParse(value);
    if (parsed != null &&
        parsed <= widget.parameterMax &&
        parsed > _criticalMax) {
      setState(() {
        _warningMax = parsed;
      });
      _notifyThresholdsChanged();
    }
  }

  void _updateCriticalMin(String value) {
    final parsed = double.tryParse(value);
    if (parsed != null &&
        parsed >= widget.parameterMin &&
        parsed < _warningMin) {
      setState(() {
        _criticalMin = parsed;
      });
      _notifyThresholdsChanged();
    }
  }

  void _updateCriticalMax(String value) {
    final parsed = double.tryParse(value);
    if (parsed != null &&
        parsed <= widget.parameterMax &&
        parsed > _warningMax) {
      setState(() {
        _criticalMax = parsed;
      });
      _notifyThresholdsChanged();
    }
  }

  void _notifyThresholdsChanged() {
    if (widget.onWarningAndCriticalChanged != null) {
      widget.onWarningAndCriticalChanged!(
        _warningMin,
        _warningMax,
        _criticalMin,
        _criticalMax,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 10.w,
              height: 0.5.h,
              decoration: BoxDecoration(
                color: theme.colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          SizedBox(height: 2.h),
          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  if (widget.onCancel != null) widget.onCancel!();
                  Navigator.of(context).pop();
                },
                child: Text('Cancel', style: theme.textTheme.bodyMedium),
              ),
              SizedBox(width: 3.w),
              ElevatedButton(
                onPressed: () {
                  // Ensure any in-progress edits are committed
                  FocusScope.of(context).unfocus();

                  // Parse final values from controllers (safer than relying on onChanged)
                  final parsedCriticalMin = double.tryParse(_criticalMinController.text);
                  final parsedCriticalMax = double.tryParse(_criticalMaxController.text);
                  final parsedWarningMin = double.tryParse(_warningMinController.text);
                  final parsedWarningMax = double.tryParse(_warningMaxController.text);

                  // Apply parsed values if valid and within parameter bounds
                  if (parsedCriticalMin != null && parsedCriticalMin >= widget.parameterMin) {
                    _criticalMin = parsedCriticalMin;
                  }
                  if (parsedCriticalMax != null && parsedCriticalMax <= widget.parameterMax) {
                    _criticalMax = parsedCriticalMax;
                  }

                  if (parsedWarningMin != null && parsedWarningMin >= widget.parameterMin) {
                    _warningMin = parsedWarningMin;
                  }
                  if (parsedWarningMax != null && parsedWarningMax <= widget.parameterMax) {
                    _warningMax = parsedWarningMax;
                  }

                  // Enforce simple relational constraints: ensure criticals are outside warnings
                  if (!(_criticalMin < _warningMin)) {
                    // adjust criticalMin to be slightly below warningMin
                    _criticalMin = (_warningMin - 0.1).clamp(widget.parameterMin, _warningMin - 0.0001);
                  }
                  if (!(_criticalMax > _warningMax)) {
                    _criticalMax = (_warningMax + 0.1).clamp(_warningMax + 0.0001, widget.parameterMax);
                  }

                  _notifyThresholdsChanged();

                  if (widget.onSave != null) {
                    widget.onSave!(_warningMin, _warningMax, _criticalMin, _criticalMax);
                  }

                  Navigator.of(context).pop();
                },
                child: const Text('Save'),
              ),
            ],
          ),

          // Title
          Text(
            'Threshold Settings',
            style: theme.textTheme.titleLarge,
          ),
          SizedBox(height: 3.h),

          // Warning thresholds section
          Text(
            'Warning Thresholds',
            style: theme.textTheme.titleMedium?.copyWith(
              color: const Color(0xFFFF8800),
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              Expanded(
                child: _buildThresholdInput(
                  context: context,
                  label: 'Min Warning',
                  controller: _warningMinController,
                  color: const Color(0xFFFF8800),
                  onChanged: _updateWarningMin,
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: _buildThresholdInput(
                  context: context,
                  label: 'Max Warning',
                  controller: _warningMaxController,
                  color: const Color(0xFFFF8800),
                  onChanged: _updateWarningMax,
                ),
              ),
            ],
          ),
          SizedBox(height: 3.h),

          // Critical thresholds section
          Text(
            'Critical Thresholds',
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.error,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              Expanded(
                child: _buildThresholdInput(
                  context: context,
                  label: 'Min Critical',
                  controller: _criticalMinController,
                  color: AppTheme.lightTheme.colorScheme.error,
                  onChanged: _updateCriticalMin,
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: _buildThresholdInput(
                  context: context,
                  label: 'Max Critical',
                  controller: _criticalMaxController,
                  color: AppTheme.lightTheme.colorScheme.error,
                  onChanged: _updateCriticalMax,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),

          // Color preview
          _buildColorPreview(context),
          SizedBox(height: 2.h),
        ],
      ),
    );
  }

  Widget _buildThresholdInput({
    required BuildContext context,
    required String label,
    required TextEditingController controller,
    required Color color,
    required ValueChanged<String> onChanged,
  }) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 0.5.h),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: color,
          ),
          decoration: InputDecoration(
            contentPadding: EdgeInsets.symmetric(
              horizontal: 2.w,
              vertical: 1.h,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: color, width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: color.withValues(alpha: 0.5), width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: color, width: 2),
            ),
          ),
          onChanged: onChanged,
        
        ),
      ],
    );
  }

  Widget _buildColorPreview(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Zone Preview',
          style: theme.textTheme.titleMedium,
        ),
        SizedBox(height: 1.h),
        Row(
          children: [
            Expanded(
              child: _buildZoneIndicator(
                context: context,
                label: 'Critical',
                color: AppTheme.lightTheme.colorScheme.error,
              ),
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: _buildZoneIndicator(
                context: context,
                label: 'Warning',
                color: const Color(0xFFFF8800),
              ),
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: _buildZoneIndicator(
                context: context,
                label: 'Normal',
                color: AppTheme.lightTheme.colorScheme.tertiary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildZoneIndicator({
    required BuildContext context,
    required String label,
    required Color color,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.symmetric(vertical: 1.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1),
      ),
      child: Column(
        children: [
          Container(
            width: 4.w,
            height: 4.w,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
