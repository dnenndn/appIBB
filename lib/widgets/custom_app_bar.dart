import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// App bar variant types for different screen contexts
enum CustomAppBarVariant {
  /// Standard app bar with title and actions
  standard,

  /// App bar with back button for navigation stack
  withBack,

  /// App bar with search functionality
  withSearch,

  /// Transparent app bar for overlay contexts
  transparent,
}

/// Custom app bar optimized for Industrial IoT monitoring
/// Implements Industrial Clarity Design with high contrast for factory environments
/// Supports multiple variants for different screen contexts
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final CustomAppBarVariant variant;
  final List<Widget>? actions;
  final VoidCallback? onBackPressed;
  final VoidCallback? onSearchPressed;
  final Widget? leading;
  final bool centerTitle;
  final double elevation;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final PreferredSizeWidget? bottom;

  const CustomAppBar({
    super.key,
    required this.title,
    this.variant = CustomAppBarVariant.standard,
    this.actions,
    this.onBackPressed,
    this.onSearchPressed,
    this.leading,
    this.centerTitle = true,
    this.elevation = 2.0,
    this.backgroundColor,
    this.foregroundColor,
    this.bottom,
  });

  /// Factory constructor for standard app bar
  factory CustomAppBar.standard({
    required String title,
    List<Widget>? actions,
    bool centerTitle = true,
    PreferredSizeWidget? bottom,
  }) {
    return CustomAppBar(
      title: title,
      variant: CustomAppBarVariant.standard,
      actions: actions,
      centerTitle: centerTitle,
      bottom: bottom,
    );
  }

  /// Factory constructor for app bar with back button
  factory CustomAppBar.withBack({
    required String title,
    VoidCallback? onBackPressed,
    List<Widget>? actions,
    bool centerTitle = true,
  }) {
    return CustomAppBar(
      title: title,
      variant: CustomAppBarVariant.withBack,
      onBackPressed: onBackPressed,
      actions: actions,
      centerTitle: centerTitle,
    );
  }

  /// Factory constructor for app bar with search
  factory CustomAppBar.withSearch({
    required String title,
    required VoidCallback onSearchPressed,
    List<Widget>? actions,
    bool centerTitle = true,
  }) {
    return CustomAppBar(
      title: title,
      variant: CustomAppBarVariant.withSearch,
      onSearchPressed: onSearchPressed,
      actions: actions,
      centerTitle: centerTitle,
    );
  }

  /// Factory constructor for transparent app bar
  factory CustomAppBar.transparent({
    required String title,
    VoidCallback? onBackPressed,
    List<Widget>? actions,
    bool centerTitle = true,
  }) {
    return CustomAppBar(
      title: title,
      variant: CustomAppBarVariant.transparent,
      onBackPressed: onBackPressed,
      actions: actions,
      centerTitle: centerTitle,
      elevation: 0,
      backgroundColor: Colors.transparent,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (bottom?.preferredSize.height ?? 0.0),
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appBarTheme = theme.appBarTheme;

    return AppBar(
      title: Text(title),
      centerTitle: centerTitle,
      elevation: elevation,
      backgroundColor: backgroundColor ?? appBarTheme.backgroundColor,
      foregroundColor: foregroundColor ?? appBarTheme.foregroundColor,
      leading: _buildLeading(context),
      actions: _buildActions(context),
      bottom: bottom,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: theme.brightness == Brightness.light
            ? Brightness.dark
            : Brightness.light,
        statusBarBrightness: theme.brightness,
      ),
    );
  }

  Widget? _buildLeading(BuildContext context) {
    if (leading != null) {
      return leading;
    }

    switch (variant) {
      case CustomAppBarVariant.withBack:
      case CustomAppBarVariant.transparent:
        return IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            HapticFeedback.lightImpact();
            if (onBackPressed != null) {
              onBackPressed!();
            } else {
              Navigator.of(context).pop();
            }
          },
          tooltip: 'Back',
        );
      case CustomAppBarVariant.standard:
      case CustomAppBarVariant.withSearch:
        // Check if there's a drawer or previous route
        final scaffold = Scaffold.maybeOf(context);
        final hasDrawer = scaffold?.hasDrawer ?? false;
        final canPop = Navigator.of(context).canPop();

        if (hasDrawer) {
          return IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              HapticFeedback.lightImpact();
              Scaffold.of(context).openDrawer();
            },
            tooltip: 'Menu',
          );
        } else if (canPop) {
          return IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).pop();
            },
            tooltip: 'Back',
          );
        }
        return null;
    }
  }

  List<Widget>? _buildActions(BuildContext context) {
    final List<Widget> actionWidgets = [];

    // Add search button for withSearch variant
    if (variant == CustomAppBarVariant.withSearch && onSearchPressed != null) {
      actionWidgets.add(
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () {
            HapticFeedback.lightImpact();
            onSearchPressed!();
          },
          tooltip: 'Search',
        ),
      );
    }

    // Add custom actions
    if (actions != null) {
      actionWidgets.addAll(actions!);
    }

    return actionWidgets.isEmpty ? null : actionWidgets;
  }
}

/// Custom app bar with real-time status indicator
/// Shows machine status or connection status in the app bar
class CustomAppBarWithStatus extends StatelessWidget
    implements PreferredSizeWidget {
  final String title;
  final String statusText;
  final Color statusColor;
  final CustomAppBarVariant variant;
  final List<Widget>? actions;
  final VoidCallback? onBackPressed;
  final bool centerTitle;

  const CustomAppBarWithStatus({
    super.key,
    required this.title,
    required this.statusText,
    required this.statusColor,
    this.variant = CustomAppBarVariant.standard,
    this.actions,
    this.onBackPressed,
    this.centerTitle = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CustomAppBar(
      title: title,
      variant: variant,
      actions: [
        // Status indicator
        Container(
          margin: const EdgeInsets.only(right: 16),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: statusColor,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                statusText,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        if (actions != null) ...actions!,
      ],
      onBackPressed: onBackPressed,
      centerTitle: centerTitle,
    );
  }
}
