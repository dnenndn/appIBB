import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class SettingsRowWidget extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String iconName;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? iconColor;
  final bool showChevron;

  const SettingsRowWidget({
    Key? key,
    required this.title,
    this.subtitle,
    required this.iconName,
    this.trailing,
    this.onTap,
    this.iconColor,
    this.showChevron = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 3.h),
          child: Row(
            children: [
              Container(
                width: 10.w,
                height: 10.w,
                decoration: BoxDecoration(
                  color: (iconColor ?? AppTheme.lightTheme.primaryColor)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: CustomIconWidget(
                  iconName: iconName,
                  color: iconColor ?? AppTheme.lightTheme.primaryColor,
                  size: 5.w,
                ),
              ),
              SizedBox(width: 4.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null) ...[
                      SizedBox(height: 0.5.h),
                      Text(
                        subtitle!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textMediumEmphasisLight,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                SizedBox(width: 2.w),
                trailing!,
              ] else if (showChevron && onTap != null) ...[
                SizedBox(width: 2.w),
                CustomIconWidget(
                  iconName: 'chevron_right',
                  color: AppTheme.textMediumEmphasisLight,
                  size: 5.w,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
