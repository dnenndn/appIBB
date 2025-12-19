import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

/// Service for managing system notifications
/// Replaces popup notifications with system notifications like other apps
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// Initialize notification service
  Future<void> initialize() async {
    if (_initialized) return;

    final androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    final iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channels for Android
    if (!kIsWeb) {
      await _createNotificationChannels();
    }

    _initialized = true;
  }

  /// Create notification channels for Android
  Future<void> _createNotificationChannels() async {
    final criticalChannel = AndroidNotificationChannel(
      'critical_alerts',
      'Critical Alerts',
      description: 'High priority equipment alerts',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    final warningChannel = AndroidNotificationChannel(
      'warning_alerts',
      'Warning Alerts',
      description: 'Medium priority notifications',
      importance: Importance.defaultImportance,
      playSound: true,
      enableVibration: true,
    );

    final statusChannel = AndroidNotificationChannel(
      'status_updates',
      'Status Updates',
      description: 'General status notifications',
      importance: Importance.low,
      playSound: false,
      enableVibration: false,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(criticalChannel);
    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(warningChannel);
    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(statusChannel);
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap - can navigate to specific screen
    print('Notification tapped: ${response.payload}');
  }

  /// Show critical alert notification
  Future<void> showCriticalAlert({
    required String title,
    required String body,
    String? machineName,
    String? parameterName,
  }) async {
    if (!_initialized) await initialize();

    final androidDetails = AndroidNotificationDetails(
      'critical_alerts',
      'Critical Alerts',
      channelDescription: 'High priority equipment alerts',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch % 100000,
      title,
      body,
      details,
      payload: machineName != null ? 'machine:$machineName' : null,
    );
  }

  /// Show warning alert notification
  Future<void> showWarningAlert({
    required String title,
    required String body,
    String? machineName,
    String? parameterName,
  }) async {
    if (!_initialized) await initialize();

    final androidDetails = AndroidNotificationDetails(
      'warning_alerts',
      'Warning Alerts',
      channelDescription: 'Medium priority notifications',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch % 100000,
      title,
      body,
      details,
      payload: machineName != null ? 'machine:$machineName' : null,
    );
  }

  /// Show status update notification
  Future<void> showStatusUpdate({
    required String title,
    required String body,
  }) async {
    if (!_initialized) await initialize();

    final androidDetails = AndroidNotificationDetails(
      'status_updates',
      'Status Updates',
      channelDescription: 'General status notifications',
      importance: Importance.low,
      priority: Priority.low,
      playSound: false,
      enableVibration: false,
      icon: '@mipmap/ic_launcher',
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: false,
      presentBadge: true,
      presentSound: false,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch % 100000,
      title,
      body,
      details,
    );
  }

  /// Cancel all notifications
  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }
}

