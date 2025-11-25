import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Empty state widget when no data is available
class EmptyStateWidget extends StatelessWidget {
  final String message;
  final String? suggestion;

  const EmptyStateWidget({
    super.key,
    required this.message,
    this.suggestion,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: EdgeInsets.all(6.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: 'folder_open',
              size: 80,
              color: theme.colorScheme.outline.withValues(alpha: 0.5),
            ),
            SizedBox(height: 3.h),
            Text(
              message,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (suggestion != null) ...[
              SizedBox(height: 1.h),
              Text(
                suggestion!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color:
                      theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
