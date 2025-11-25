import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/app_export.dart';

/// Navigation item configuration for bottom bar
class CustomBottomBarItem {
  final String label;
  final IconData icon;
  final IconData? activeIcon;
  final String route;

  const CustomBottomBarItem({
    required this.label,
    required this.icon,
    this.activeIcon,
    required this.route,
  });
}

/// Custom bottom navigation bar optimized for Industrial IoT monitoring
class CustomBottomBar extends StatelessWidget {
  final int currentIndex;
  final Function(int)? onTap;
  final List<CustomBottomBarItem>? items;

  const CustomBottomBar({
    super.key,
    required this.currentIndex,
    this.onTap,
    this.items,
  });

  /// Default navigation items based on Mobile Navigation Hierarchy
  static const List<CustomBottomBarItem> _defaultItems = [
    CustomBottomBarItem(
      label: 'Dashboard',
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard,
      route: '/dashboard-screen',
    ),
    CustomBottomBarItem(
      label: 'Historical',
      icon: Icons.bar_chart_outlined,
      activeIcon: Icons.bar_chart,
      route: '/historical-data-screen',
    ),
    CustomBottomBarItem(
      label: 'Alerts',
      icon: Icons.notifications_outlined,
      activeIcon: Icons.notifications,
      route: '/alerts-screen',
    ),
    CustomBottomBarItem(
      label: 'Settings',
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings,
      route: AppRoutes.settings,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final navigationItems = items ?? _defaultItems;

    return BottomNavigationBar(
      currentIndex: currentIndex,
      type: BottomNavigationBarType.fixed,
      onTap: (index) {
        HapticFeedback.lightImpact();
        if (onTap != null) {
          onTap!(index);
        } else {
          Navigator.pushNamed(context, navigationItems[index].route);
        }
      },
      items: navigationItems
          .map(
            (item) => BottomNavigationBarItem(
              icon: Icon(item.icon),
              activeIcon: Icon(item.activeIcon ?? item.icon),
              label: item.label,
            ),
          )
          .toList(),
    );
  }
}

/// Stateful wrapper for CustomBottomBar with automatic index management
class CustomBottomBarStateful extends StatefulWidget {
  final int initialIndex;
  final List<CustomBottomBarItem>? items;

  const CustomBottomBarStateful({
    super.key,
    this.initialIndex = 0,
    this.items,
  });

  @override
  State<CustomBottomBarStateful> createState() =>
      _CustomBottomBarStatefulState();
}

class _CustomBottomBarStatefulState extends State<CustomBottomBarStateful> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });

    // Navigate to the selected route
    final items = widget.items ?? CustomBottomBar._defaultItems;
    if (index < items.length) {
      Navigator.pushNamed(context, items[index].route);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomBottomBar(
      currentIndex: _currentIndex,
      onTap: _onItemTapped,
      items: widget.items,
    );
  }
}
