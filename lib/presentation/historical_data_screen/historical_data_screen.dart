import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/comparison_bottom_sheet.dart';
import './widgets/empty_state_widget.dart';
import './widgets/expanded_shift_details.dart';
import './widgets/shift_card.dart';
import './widgets/shift_filter_chip.dart';

class HistoricalDataScreen extends StatefulWidget {
  const HistoricalDataScreen({super.key});

  @override
  State<HistoricalDataScreen> createState() => _HistoricalDataScreenState();
}

class _HistoricalDataScreenState extends State<HistoricalDataScreen> {
  String _selectedShift = 'All';
  DateTime _selectedStartDate =
      DateTime.now().subtract(const Duration(days: 7));
  DateTime _selectedEndDate = DateTime.now();
  bool _isComparisonMode = false;
  final List<String> _selectedShiftIds = [];
  String? _expandedShiftId;
  bool _isLoading = false;
  String _searchQuery = '';

  // Mock data for shifts
  final List<Map<String, dynamic>> _allShifts = [
    {
      "id": "shift_001",
      "date": "11/22/2025",
      "shiftType": "Morning",
      "duration": "8h 00m",
      "production": "12,450 units",
      "efficiency": "92%",
      "alertCount": 3,
      "status": "normal",
      "machines": [
        {"name": "Kiln 1", "efficiency": 94},
        {"name": "Kiln 2", "efficiency": 90},
        {"name": "Dryer 1", "efficiency": 92},
      ],
      "alertSummary": {"critical": 0, "warning": 2, "info": 1},
    },
    {
      "id": "shift_002",
      "date": "11/22/2025",
      "shiftType": "Afternoon",
      "duration": "8h 00m",
      "production": "11,890 units",
      "efficiency": "88%",
      "alertCount": 5,
      "status": "warning",
      "machines": [
        {"name": "Kiln 1", "efficiency": 89},
        {"name": "Kiln 2", "efficiency": 87},
        {"name": "Dryer 1", "efficiency": 88},
      ],
      "alertSummary": {"critical": 1, "warning": 3, "info": 1},
    },
    {
      "id": "shift_003",
      "date": "11/22/2025",
      "shiftType": "Night",
      "duration": "8h 00m",
      "production": "10,230 units",
      "efficiency": "76%",
      "alertCount": 8,
      "status": "critical",
      "machines": [
        {"name": "Kiln 1", "efficiency": 78},
        {"name": "Kiln 2", "efficiency": 74},
        {"name": "Dryer 1", "efficiency": 76},
      ],
      "alertSummary": {"critical": 3, "warning": 4, "info": 1},
    },
    {
      "id": "shift_004",
      "date": "11/21/2025",
      "shiftType": "Morning",
      "duration": "8h 00m",
      "production": "12,680 units",
      "efficiency": "94%",
      "alertCount": 2,
      "status": "normal",
      "machines": [
        {"name": "Kiln 1", "efficiency": 95},
        {"name": "Kiln 2", "efficiency": 93},
        {"name": "Dryer 1", "efficiency": 94},
      ],
      "alertSummary": {"critical": 0, "warning": 1, "info": 1},
    },
    {
      "id": "shift_005",
      "date": "11/21/2025",
      "shiftType": "Afternoon",
      "duration": "8h 00m",
      "production": "12,100 units",
      "efficiency": "90%",
      "alertCount": 4,
      "status": "normal",
      "machines": [
        {"name": "Kiln 1", "efficiency": 91},
        {"name": "Kiln 2", "efficiency": 89},
        {"name": "Dryer 1", "efficiency": 90},
      ],
      "alertSummary": {"critical": 0, "warning": 3, "info": 1},
    },
  ];

  List<Map<String, dynamic>> get _filteredShifts {
    return _allShifts.where((shift) {
      final matchesShift =
          _selectedShift == 'All' || shift['shiftType'] == _selectedShift;

      final matchesSearch = _searchQuery.isEmpty ||
          (shift['date'] as String)
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          (shift['shiftType'] as String)
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());

      return matchesShift && matchesSearch;
    }).toList();
  }

  void _selectShift(String shift) {
    setState(() {
      _selectedShift = shift;
    });
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: _selectedStartDate,
        end: _selectedEndDate,
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedStartDate = picked.start;
        _selectedEndDate = picked.end;
      });
    }
  }

  void _toggleComparisonMode() {
    setState(() {
      _isComparisonMode = !_isComparisonMode;
      if (!_isComparisonMode) {
        _selectedShiftIds.clear();
      }
    });
  }

  void _toggleShiftSelection(String shiftId) {
    setState(() {
      if (_selectedShiftIds.contains(shiftId)) {
        _selectedShiftIds.remove(shiftId);
      } else {
        _selectedShiftIds.add(shiftId);
      }
    });
  }

  void _showComparisonSheet() {
    final selectedShifts = _allShifts
        .where((shift) => _selectedShiftIds.contains(shift['id']))
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ComparisonBottomSheet(
        selectedShifts: selectedShifts,
        onCompare: () {
          Navigator.pop(context);
          _compareShifts();
        },
        onCancel: () {
          Navigator.pop(context);
          _toggleComparisonMode();
        },
      ),
    );
  }

  void _compareShifts() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Comparing ${_selectedShiftIds.length} shifts'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    _toggleComparisonMode();
  }

  void _generateReport(Map<String, dynamic> shift) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Generating report for ${shift['date']} ${shift['shiftType']} shift'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _exportData(Map<String, dynamic> shift) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Exporting data for ${shift['date']} ${shift['shiftType']} shift'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showContextMenu(Map<String, dynamic> shift) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(4.w),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: CustomIconWidget(
                  iconName: 'push_pin',
                  size: 24,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: const Text('Pin as Favorite'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Shift pinned as favorite'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              ListTile(
                leading: CustomIconWidget(
                  iconName: 'flag',
                  size: 24,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                title: const Text('Set as Benchmark'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Shift set as benchmark'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              ListTile(
                leading: CustomIconWidget(
                  iconName: 'delete',
                  size: 24,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: const Text('Delete (Admin Only)'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Admin access required'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
    });

    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _isLoading = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data refreshed'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MM/dd/yyyy');

    return Scaffold(
      appBar: CustomAppBar.standard(
        title: 'Historical Data',
        actions: [
          IconButton(
            icon: CustomIconWidget(
              iconName: 'search',
              size: 24,
              color: theme.appBarTheme.foregroundColor ?? Colors.white,
            ),
            onPressed: () {
              showSearch(
                context: context,
                delegate: _ShiftSearchDelegate(
                  shifts: _allShifts,
                  onShiftSelected: (shift) {
                    setState(() {
                      _searchQuery = shift['date'] as String;
                    });
                  },
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Date range selector
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: theme.shadowColor.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: InkWell(
              onTap: _selectDateRange,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CustomIconWidget(
                        iconName: 'calendar_today',
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        '${dateFormat.format(_selectedStartDate)} - ${dateFormat.format(_selectedEndDate)}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  CustomIconWidget(
                    iconName: 'arrow_drop_down',
                    size: 24,
                    color: theme.colorScheme.onSurface,
                  ),
                ],
              ),
            ),
          ),
          // Shift filter chips
          Container(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ShiftFilterChip(
                    label: 'All',
                    isSelected: _selectedShift == 'All',
                    onTap: () => _selectShift('All'),
                  ),
                  SizedBox(width: 2.w),
                  ShiftFilterChip(
                    label: 'Morning',
                    isSelected: _selectedShift == 'Morning',
                    onTap: () => _selectShift('Morning'),
                  ),
                  SizedBox(width: 2.w),
                  ShiftFilterChip(
                    label: 'Afternoon',
                    isSelected: _selectedShift == 'Afternoon',
                    onTap: () => _selectShift('Afternoon'),
                  ),
                  SizedBox(width: 2.w),
                  ShiftFilterChip(
                    label: 'Night',
                    isSelected: _selectedShift == 'Night',
                    onTap: () => _selectShift('Night'),
                  ),
                ],
              ),
            ),
          ),
          // Shift list
          Expanded(
            child: _filteredShifts.isEmpty
                ? const EmptyStateWidget(
                    message: 'No Data Available',
                    suggestion: 'Try adjusting your date range or shift filter',
                  )
                : RefreshIndicator(
                    onRefresh: _refreshData,
                    child: ListView.builder(
                      itemCount: _filteredShifts.length,
                      itemBuilder: (context, index) {
                        final shift = _filteredShifts[index];
                        final isExpanded = _expandedShiftId == shift['id'];
                        final isSelected =
                            _selectedShiftIds.contains(shift['id']);

                        return Column(
                          children: [
                            ShiftCard(
                              shiftData: shift,
                              isSelected: _isComparisonMode && isSelected,
                              onTap: () {
                                if (_isComparisonMode) {
                                  _toggleShiftSelection(shift['id'] as String);
                                } else {
                                  setState(() {
                                    _expandedShiftId = isExpanded
                                        ? null
                                        : shift['id'] as String;
                                  });
                                }
                              },
                              onGenerateReport: () => _generateReport(shift),
                              onCompare: () {
                                _toggleComparisonMode();
                                _toggleShiftSelection(shift['id'] as String);
                              },
                              onExport: () => _exportData(shift),
                              onLongPress: () => _showContextMenu(shift),
                            ),
                            if (isExpanded)
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 4.w),
                                child: ExpandedShiftDetails(shiftData: shift),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: _isComparisonMode
          ? FloatingActionButton.extended(
              onPressed:
                  _selectedShiftIds.length >= 2 ? _showComparisonSheet : null,
              backgroundColor: _selectedShiftIds.length >= 2
                  ? theme.floatingActionButtonTheme.backgroundColor
                  : theme.colorScheme.outline,
              icon: CustomIconWidget(
                iconName: 'compare_arrows',
                size: 24,
                color: Colors.white,
              ),
              label: Text('Compare (${_selectedShiftIds.length})'),
            )
          : FloatingActionButton(
              onPressed: _toggleComparisonMode,
              child: CustomIconWidget(
                iconName: 'compare_arrows',
                size: 24,
                color: Colors.white,
              ),
            ),
      bottomNavigationBar: const CustomBottomBar(
        currentIndex: 1,
      ),
    );
  }
}

class _ShiftSearchDelegate extends SearchDelegate<Map<String, dynamic>?> {
  final List<Map<String, dynamic>> shifts;
  final Function(Map<String, dynamic>) onShiftSelected;

  _ShiftSearchDelegate({
    required this.shifts,
    required this.onShiftSelected,
  });

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    final results = shifts.where((shift) {
      final searchLower = query.toLowerCase();
      return (shift['date'] as String).toLowerCase().contains(searchLower) ||
          (shift['shiftType'] as String).toLowerCase().contains(searchLower);
    }).toList();

    if (results.isEmpty) {
      return const Center(
        child: Text('No shifts found'),
      );
    }

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final shift = results[index];
        return ListTile(
          title: Text('${shift['date']} - ${shift['shiftType']} Shift'),
          subtitle: Text(shift['production'] as String),
          onTap: () {
            onShiftSelected(shift);
            close(context, shift);
          },
        );
      },
    );
  }
}
