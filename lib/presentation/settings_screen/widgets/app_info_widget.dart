import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class AppInfoWidget extends StatelessWidget {
  const AppInfoWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 12.w,
                height: 12.w,
                decoration: BoxDecoration(
                  color:
                      AppTheme.lightTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: CustomIconWidget(
                  iconName: 'factory',
                  color: AppTheme.lightTheme.primaryColor,
                  size: 6.w,
                ),
              ),
              SizedBox(width: 4.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BrickFactory Monitor',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      'Version 1.0.0 (Build 1)',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textMediumEmphasisLight,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 3.h),
          Divider(
            color: AppTheme.dividerLight.withValues(alpha: 0.3),
          ),
          SizedBox(height: 2.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildInfoItem(
                context,
                'support',
                'Support',
                'help@brickfactory.com',
              ),
              Container(
                width: 1,
                height: 6.h,
                color: AppTheme.dividerLight.withValues(alpha: 0.3),
              ),
              _buildInfoItem(
                context,
                'info',
                'About',
                'Industrial IoT Monitor',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(
      BuildContext context, String iconName, String title, String subtitle) {
    return Expanded(
      child: Column(
        children: [
          CustomIconWidget(
            iconName: iconName,
            color: AppTheme.lightTheme.primaryColor,
            size: 6.w,
          ),
          SizedBox(height: 1.h),
          Text(
            title,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textMediumEmphasisLight,
                ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}
