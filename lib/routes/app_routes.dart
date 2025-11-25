import 'package:flutter/material.dart';
import '../presentation/dashboard_screen/dashboard_screen.dart';
import '../presentation/machine_detail_screen/machine_detail_screen.dart';
import '../presentation/alerts_screen/alerts_screen.dart';
import '../presentation/login_screen/login_screen.dart';
import '../presentation/parameter_trend_screen/parameter_trend_screen.dart';
import '../presentation/historical_data_screen/historical_data_screen.dart';
import '../presentation/settings_screen/settings_screen.dart';

class AppRoutes {
  // TODO: Add your routes here
  static const String initial = '/';
  static const String dashboard = '/dashboard-screen';
  static const String machineDetail = '/machine-detail-screen';
  static const String alerts = '/alerts-screen';
  static const String login = '/login-screen';
  static const String parameterTrend = '/parameter-trend-screen';
  static const String historicalData = '/historical-data-screen';
  static const String settings = '/settings-screen';

  static Map<String, WidgetBuilder> routes = {
    initial: (context) => const LoginScreen(),
    dashboard: (context) => const DashboardScreen(),
    machineDetail: (context) => const MachineDetailScreen(),
    alerts: (context) => const AlertsScreen(),
    login: (context) => const LoginScreen(),
    parameterTrend: (context) => const ParameterTrendScreen(),
    historicalData: (context) => const HistoricalDataScreen(),
    settings: (context) => const SettingsScreen(),
    // TODO: Add your other routes here
  };
}
