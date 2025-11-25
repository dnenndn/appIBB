import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

/// Bottom sheet for threshold adjustment controls
class ThresholdControlSheet extends StatefulWidget {
  final double minThreshold;
  final double maxThreshold;
  final double parameterMin;
  final double parameterMax;
  final ValueChanged<double> onMinChanged;
  final ValueChanged<double> onMaxChanged;

  const ThresholdControlSheet({
    super.key,
    required this.minThreshold,
    required this.maxThreshold,
    required this.parameterMin,
    required this.parameterMax,
    required this.onMinChanged,
    required this.onMaxChanged,
  });

  @override
  State<ThresholdControlSheet> createState() => _ThresholdControlSheetState();
}

class _ThresholdControlSheetState extends State<ThresholdControlSheet> {
  late TextEditingController _minController;
  late TextEditingController _maxController;
  late double _currentMin;
  late double _currentMax;

  @override
  void initState() {
    super.initState();
    _currentMin = widget.minThreshold;
    _currentMax = widget.maxThreshold;
    _minController = TextEditingController(
      text: _currentMin.toStringAsFixed(1),
    );
    _maxController = TextEditingController(
      text: _currentMax.toStringAsFixed(1),
    );
  }

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  void _updateMinThreshold(double value) {
    setState(() {
      _currentMin = value;
      _minController.text = value.toStringAsFixed(1);
    });
    widget.onMinChanged(value);
  }

  void _updateMaxThreshold(double value) {
    setState(() {
      _currentMax = value;
      _maxController.text = value.toStringAsFixed(1);
    });
    widget.onMaxChanged(value);
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

          // Title
          Text(
            'Threshold Settings',
            style: theme.textTheme.titleLarge,
          ),
          SizedBox(height: 3.h),

          // Minimum threshold control
          _buildThresholdControl(
            context: context,
            label: 'Minimum Threshold',
            value: _currentMin,
            controller: _minController,
            color: AppTheme.lightTheme.colorScheme.tertiary,
            onSliderChanged: _updateMinThreshold,
            onTextChanged: (value) {
              final parsed = double.tryParse(value);
              if (parsed != null &&
                  parsed >= widget.parameterMin &&
                  parsed < _currentMax) {
                _updateMinThreshold(parsed);
              }
            },
          ),
          SizedBox(height: 3.h),

          // Maximum threshold control
          _buildThresholdControl(
            context: context,
            label: 'Maximum Threshold',
            value: _currentMax,
            controller: _maxController,
            color: AppTheme.lightTheme.colorScheme.error,
            onSliderChanged: _updateMaxThreshold,
            onTextChanged: (value) {
              final parsed = double.tryParse(value);
              if (parsed != null &&
                  parsed <= widget.parameterMax &&
                  parsed > _currentMin) {
                _updateMaxThreshold(parsed);
              }
            },
          ),
          SizedBox(height: 2.h),

          // Color preview
          _buildColorPreview(context),
          SizedBox(height: 2.h),
        ],
      ),
    );
  }

  Widget _buildThresholdControl({
    required BuildContext context,
    required String label,
    required double value,
    required TextEditingController controller,
    required Color color,
    required ValueChanged<double> onSliderChanged,
    required ValueChanged<String> onTextChanged,
  }) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: theme.textTheme.titleMedium,
            ),
            SizedBox(
              width: 20.w,
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge,
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 2.w,
                    vertical: 1.h,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onSubmitted: onTextChanged,
              ),
            ),
          ],
        ),
        SizedBox(height: 1.h),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: color,
            thumbColor: color,
            overlayColor: color.withValues(alpha: 0.2),
            inactiveTrackColor: theme.colorScheme.outline,
          ),
          child: Slider(
            value: value,
            min: widget.parameterMin,
            max: widget.parameterMax,
            divisions: 100,
            onChanged: onSliderChanged,
          ),
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
