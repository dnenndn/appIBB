import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class LogoutButtonWidget extends StatelessWidget {
  final VoidCallback onLogout;

  const LogoutButtonWidget({
    Key? key,
    required this.onLogout,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: ElevatedButton(
        onPressed: () => _showLogoutConfirmation(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.criticalLight,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 3.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: 'logout',
              color: Colors.white,
              size: 5.w,
            ),
            SizedBox(width: 2.w),
            Text(
              'Logout',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Confirm Logout',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          content: Text(
            'Are you sure you want to logout? You will need to login again to access the application.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: AppTheme.textMediumEmphasisLight,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onLogout();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.criticalLight,
                foregroundColor: Colors.white,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }
}
