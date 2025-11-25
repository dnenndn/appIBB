import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class ProfileSectionWidget extends StatelessWidget {
  final Map<String, dynamic> userProfile;

  const ProfileSectionWidget({
    Key? key,
    required this.userProfile,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
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
      child: Row(
        children: [
          Container(
            width: 15.w,
            height: 15.w,
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: CustomIconWidget(
              iconName: 'person',
              color: AppTheme.lightTheme.primaryColor,
              size: 8.w,
            ),
          ),
          SizedBox(width: 4.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userProfile['name'] as String? ?? 'Unknown User',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 0.5.h),
                Text(
                  userProfile['email'] as String? ?? 'No email',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textMediumEmphasisLight,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 1.h),
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                  decoration: BoxDecoration(
                    color: (userProfile['role'] as String? ?? 'User') == 'Admin'
                        ? AppTheme.warningLight.withValues(alpha: 0.1)
                        : AppTheme.successLight.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    userProfile['role'] as String? ?? 'User',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: (userProfile['role'] as String? ?? 'User') ==
                                  'Admin'
                              ? AppTheme.warningLight
                              : AppTheme.successLight,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
