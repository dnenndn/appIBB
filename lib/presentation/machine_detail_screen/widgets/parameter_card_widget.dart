import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class ParameterCardWidget extends StatefulWidget {
  final String? parameterId;
  final String parameterName;
  final String currentValue;
  final String unit;
  final DateTime timestamp;
  final String status;
  final List<double> trendData;
  final double? rangeMin;
  final double? rangeMax;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final bool editMode;
  final void Function(String id)? onDelete;

  const ParameterCardWidget({
    super.key,
    this.parameterId,
    required this.parameterName,
    required this.currentValue,
    required this.unit,
    required this.timestamp,
    required this.status,
    required this.trendData,
    this.rangeMin,
    this.rangeMax,
    required this.onTap,
    required this.onLongPress,
    this.editMode = false,
    this.onDelete,
  });

  @override
  State<ParameterCardWidget> createState() => _ParameterCardWidgetState();
  
}

class _ParameterCardWidgetState extends State<ParameterCardWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _wiggleController;
  late final Animation<double> _rotation;

  @override
  void initState() {
    super.initState();
    _wiggleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _rotation = Tween(begin: -0.03, end: 0.03).animate(
      CurvedAnimation(parent: _wiggleController, curve: Curves.easeInOut),
    );
    if (widget.editMode) {
      _wiggleController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant ParameterCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.editMode && widget.editMode) {
      _wiggleController.repeat(reverse: true);
    } else if (oldWidget.editMode && !widget.editMode) {
      _wiggleController.stop();
      _wiggleController.reset();
    }
  }

  @override
  void dispose() {
    _wiggleController.dispose();
    super.dispose();
  }
  // Responsive sizing calculations
  double get _cardPadding => 2.w.clamp(8, 16).toDouble();
  double get _elementSpacing => 1.w.clamp(4, 10).toDouble();
  double get _innerSpacing => 0.8.w.clamp(3, 8).toDouble();
  
  // Font sizes with responsive scaling
  double get _titleFontSize => 14.sp.clamp(10, 18).toDouble();
  double get _valueFontSize => 20.sp.clamp(14, 28).toDouble();
  double get _unitFontSize => 10.sp.clamp(8, 12).toDouble();
  double get _rangeFontSize => 11.sp.clamp(9, 13).toDouble(); // Increased from 9.sp

  Color _getStatusColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppTheme.getStatusColor(widget.status, isDark: isDark);
  }

  Color _getBackgroundColor(BuildContext context) {
    final statusColor = _getStatusColor(context);
    final alpha = switch (widget.status.toLowerCase()) {
      'critical' => 0.15,
      'warning' => 0.12,
      _ => 0.08,
    };
    return statusColor.withValues(alpha: alpha);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _getStatusColor(context);
    final backgroundColor = _getBackgroundColor(context);
    
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate appropriate content sizes based on available space
        final bool showRangeInfo = widget.rangeMin != null && widget.rangeMax != null;
        final double contentHeight = constraints.maxHeight;
        final bool isCompact = contentHeight < 120;
        
        return GestureDetector(
          onTap: widget.onTap,
          onLongPress: widget.onLongPress,
          child: AnimatedBuilder(
            animation: _wiggleController,
            builder: (context, child) {
              return Transform.rotate(
                angle: widget.editMode ? _rotation.value : 0.0,
                child: child,
              );
            },
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Card body
                Container(
                  margin: EdgeInsets.zero,
                  padding: EdgeInsets.all(_cardPadding),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: statusColor.withValues(
                        alpha: widget.status == 'critical'
                            ? 0.8
                            : widget.status == 'warning'
                                ? 0.6
                                : 0.3,
                      ),
                      width: widget.status == 'critical'
                          ? 2.0
                          : widget.status == 'warning'
                              ? 1.6
                              : 1.0,
                    ),
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Parameter Name
                        Flexible(
                          flex: 2,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              widget.parameterName,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: _titleFontSize,
                                height: 1.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),

                        SizedBox(height: _elementSpacing),

                        // Value + Unit
                        Flexible(
                          flex: 3,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    widget.currentValue,
                                    style: theme.textTheme.headlineLarge?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: statusColor,
                                      fontSize: _valueFontSize,
                                      height: 1.1,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),

                              SizedBox(width: _innerSpacing / 2),

                              Flexible(
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 2.0),
                                  child: Text(
                                    widget.unit,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                      fontSize: _unitFontSize * 1.2,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Expanded range info
                        if (showRangeInfo && !isCompact) ...[
                          SizedBox(height: _elementSpacing * 1.2),
                          Flexible(
                            flex: 2,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Range: ',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
                                          fontSize: _rangeFontSize * 0.9,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        '${widget.rangeMin!.toStringAsFixed(0)}-${widget.rangeMax!.toStringAsFixed(0)} ${widget.unit}',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.onSurfaceVariant,
                                          fontSize: _rangeFontSize,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                SizedBox(height: _innerSpacing * 1.2),

                                Builder(builder: (context) {
                                  final current = double.tryParse(widget.currentValue) ?? widget.rangeMin!;
                                  final min = widget.rangeMin!;
                                  final max = widget.rangeMax!;
                                  final pct = ((current - min) / (max - min)).clamp(0.0, 1.0);

                                  return ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: SizedBox(
                                      height: 5.h.clamp(4, 7).toDouble(),
                                      width: double.infinity,
                                      child: LinearProgressIndicator(
                                        value: pct,
                                        minHeight: 5.h.clamp(4, 7).toDouble(),
                                        backgroundColor: theme.colorScheme.onSurface.withOpacity(0.1),
                                        valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        ],

                        // Compact range info
                        if (showRangeInfo && isCompact) ...[
                          SizedBox(height: _innerSpacing),
                          Flexible(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${widget.rangeMin!.toStringAsFixed(0)}-${widget.rangeMax!.toStringAsFixed(0)} ',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontSize: _rangeFontSize * 0.9,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  widget.unit,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
                                    fontSize: _rangeFontSize * 0.8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Timestamp
                        if (constraints.maxHeight > 140) ...[
                          SizedBox(height: _innerSpacing),
                          Flexible(
                            child: Text(
                              _formatTimestamp(widget.timestamp),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                                fontSize: _rangeFontSize * 0.85,
                              ),
                              maxLines: 1,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Delete affordance in edit mode
                if (widget.editMode && widget.parameterId != null)
                  Positioned(
                    top: -8,
                    right: -8,
                    child: GestureDetector(
                      onTap: () {
                        if (widget.onDelete != null && widget.parameterId != null) {
                          widget.onDelete!(widget.parameterId!);
                        }
                      },
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.error,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.close, size: 16, color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}