import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class RefreshIntervalPickerWidget extends StatelessWidget {
  final int selectedInterval;
  final Function(int) onIntervalChanged;

  const RefreshIntervalPickerWidget({
    Key? key,
    required this.selectedInterval,
    required this.onIntervalChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final intervals = [1, 5, 10, 30];

    return Container(
      height: 6.h,
      child: Row(
        children: intervals.map((interval) {
          final isSelected = selectedInterval == interval;
          return Expanded(
            child: GestureDetector(
              onTap: () => onIntervalChanged(interval),
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 1.w),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.lightTheme.primaryColor
                      : AppTheme.lightTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.lightTheme.primaryColor
                        : AppTheme.lightTheme.primaryColor
                            .withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    '${interval}s',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isSelected
                              ? Colors.white
                              : AppTheme.lightTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
