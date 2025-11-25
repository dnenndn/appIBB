import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class ThemeSelectorWidget extends StatelessWidget {
  final String selectedTheme;
  final Function(String) onThemeChanged;

  const ThemeSelectorWidget({
    Key? key,
    required this.selectedTheme,
    required this.onThemeChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themes = ['Light', 'Dark', 'System'];

    return Container(
      height: 6.h,
      child: Row(
        children: themes.map((theme) {
          final isSelected = selectedTheme == theme;
          return Expanded(
            child: GestureDetector(
              onTap: () => onThemeChanged(theme),
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
                    theme,
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
