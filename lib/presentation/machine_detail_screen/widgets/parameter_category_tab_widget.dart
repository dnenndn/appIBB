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
  final bool monitoredFilterApplied;
  final VoidCallback? onOpenSelection;
  final void Function(String)? onDelete;

  const ParameterCategoryTabWidget({
    super.key,
    required this.parameters,
    required this.onParameterTap,
    required this.onParameterLongPress,
    this.onDelete,
    this.monitoredFilterApplied = false,
    this.onOpenSelection,
  });

  @override
  Widget build(BuildContext context) {
    if (parameters.isEmpty) {
      // Show a different message when the empty state is due to monitored-filter
      if (monitoredFilterApplied) {
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
                'No parameters selected for this category',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 2.h),
              ElevatedButton(
                onPressed: onOpenSelection,
                child: const Text('Select Parameters'),
              ),
            ],
          ),
        );
      }

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

    return GridView.builder(
      padding: EdgeInsets.symmetric(vertical: 1.h, horizontal: 2.w),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 1.5.h,
        crossAxisSpacing: 2.w,
        // Reduce aspect ratio so cards are taller (width / height).
        // Smaller value -> taller cards which allows larger text.
        childAspectRatio: 1.5,
      ),
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
          rangeMin: (parameter['rangeMin'] as num?)?.toDouble(),
          rangeMax: (parameter['rangeMax'] as num?)?.toDouble(),
          onTap: () => onParameterTap(parameter),
          onLongPress: () => onParameterLongPress(parameter),
        );
      },
    );
  }
}
