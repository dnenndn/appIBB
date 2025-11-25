import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

/// Alert filter chip widget for filtering alerts by type
class AlertFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? selectedColor;

  const AlertFilterChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.selectedColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color chipColor = selectedColor ?? theme.colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
        decoration: BoxDecoration(
          color: isSelected
              ? chipColor.withValues(alpha: 0.15)
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? chipColor : theme.colorScheme.outline,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: isSelected ? chipColor : theme.colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
