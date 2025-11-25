import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';
import './parameter_card_widget.dart';

/// Tab content widget displaying parameters for a specific category
class ParameterCategoryTabWidget extends StatelessWidget {
  final List<Map<String, dynamic>> parameters;
  final Function(Map<String, dynamic>) onParameterTap;
  final Function(Map<String, dynamic>) onParameterLongPress;

  const ParameterCategoryTabWidget({
    super.key,
    required this.parameters,
    required this.onParameterTap,
    required this.onParameterLongPress,
  });

  @override
  Widget build(BuildContext context) {
    if (parameters.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: 'info_outline',
              size: 48,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            SizedBox(height: 2.h),
            Text(
              'No parameters available',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(vertical: 1.h),
      itemCount: parameters.length,
      itemBuilder: (context, index) {
        final parameter = parameters[index];
        return ParameterCardWidget(
          parameterName: parameter['name'] as String,
          currentValue: parameter['value'] as String,
          unit: parameter['unit'] as String,
          timestamp: parameter['timestamp'] as DateTime,
          status: parameter['status'] as String,
          trendData: (parameter['trendData'] as List).cast<double>(),
          onTap: () => onParameterTap(parameter),
          onLongPress: () => onParameterLongPress(parameter),
        );
      },
    );
  }
}
