import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

/// Bottom sheet for comparing selected shifts
class ComparisonBottomSheet extends StatelessWidget {
  final List<Map<String, dynamic>> selectedShifts;
  final VoidCallback onCompare;
  final VoidCallback onCancel;

  const ComparisonBottomSheet({
    super.key,
    required this.selectedShifts,
    required this.onCompare,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.dialogBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 12.w,
              height: 0.5.h,
              decoration: BoxDecoration(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            SizedBox(height: 2.h),
            // Title
            Text(
              'Compare Shifts',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              '${selectedShifts.length} shifts selected',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 3.h),
            // Selected shifts preview
            SizedBox(
              height: 15.h,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: selectedShifts.length,
                itemBuilder: (context, index) {
                  final shift = selectedShifts[index];
                  return Container(
                    width: 40.w,
                    margin: EdgeInsets.only(right: 2.w),
                    padding: EdgeInsets.all(2.w),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.outline.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          shift['date'] as String? ?? '',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 0.5.h),
                        Text(
                          '${shift['shiftType']} Shift',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 1.h),
                        Text(
                          shift['production'] as String? ?? '',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 3.h),
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onCancel,
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 1.5.h),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: selectedShifts.length >= 2 ? onCompare : null,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 1.5.h),
                    ),
                    child: const Text('Compare'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
