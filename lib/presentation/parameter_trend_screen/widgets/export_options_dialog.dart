import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Export options dialog for parameter trend data
class ExportOptionsDialog extends StatelessWidget {
  final VoidCallback onExportPDF;
  final VoidCallback onExportCSV;
  final VoidCallback onShareScreenshot;

  const ExportOptionsDialog({
    super.key,
    required this.onExportPDF,
    required this.onExportCSV,
    required this.onShareScreenshot,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Export Options',
              style: theme.textTheme.titleLarge,
            ),
            SizedBox(height: 3.h),
            _buildExportOption(
              context: context,
              icon: 'picture_as_pdf',
              title: 'Export as PDF',
              subtitle: 'Generate detailed report',
              onTap: () {
                Navigator.pop(context);
                onExportPDF();
              },
            ),
            SizedBox(height: 2.h),
            _buildExportOption(
              context: context,
              icon: 'table_chart',
              title: 'Export as CSV',
              subtitle: 'Download raw data',
              onTap: () {
                Navigator.pop(context);
                onExportCSV();
              },
            ),
            SizedBox(height: 2.h),
            _buildExportOption(
              context: context,
              icon: 'share',
              title: 'Share Screenshot',
              subtitle: 'Share chart image',
              onTap: () {
                Navigator.pop(context);
                onShareScreenshot();
              },
            ),
            SizedBox(height: 2.h),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportOption({
    required BuildContext context,
    required String icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          border: Border.all(
            color: theme.colorScheme.outline,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: CustomIconWidget(
                iconName: icon,
                color: theme.colorScheme.primary,
                size: 24,
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium,
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            CustomIconWidget(
              iconName: 'chevron_right',
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
