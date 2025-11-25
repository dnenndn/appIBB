import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

/// Time range options for parameter trend display
enum TimeRange {
  oneHour('1H', Duration(hours: 1)),
  sixHours('6H', Duration(hours: 6)),
  twentyFourHours('24H', Duration(hours: 24)),
  sevenDays('7D', Duration(days: 7));

  final String label;
  final Duration duration;

  const TimeRange(this.label, this.duration);
}

/// Segmented control for time range selection
class TimeRangeSelector extends StatelessWidget {
  final TimeRange selectedRange;
  final ValueChanged<TimeRange> onRangeChanged;

  const TimeRangeSelector({
    super.key,
    required this.selectedRange,
    required this.onRangeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 6.h,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline,
          width: 1,
        ),
      ),
      child: Row(
        children: TimeRange.values.map((range) {
          final isSelected = range == selectedRange;
          return Expanded(
            child: GestureDetector(
              onTap: () => onRangeChanged(range),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
                alignment: Alignment.center,
                child: Text(
                  range.label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: isSelected
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurface,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
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
