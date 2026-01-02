import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  bool _isInitialized = false;
  bool _notificationsEnabled = true;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    if (_isInitialized) return;

    final prefs = await SharedPreferences.getInstance();
    _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;

    // Initialize local notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // Request notification permissions for Android 13+
    if (_notificationsEnabled) {
      await _requestPermissions();
    }

    _isInitialized = true;
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    _notificationsEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', enabled);

    if (enabled) {
      // Initialize notification permissions if enabled
      await _requestPermissions();
    }
  }

  Future<bool> _requestPermissions() async {
    // Request notification permissions for Android 13+ (API level 33+)
    final result = await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    debugPrint('Notification permissions: $result');
    return result ?? true;
  }

  bool get isEnabled => _notificationsEnabled;

  Future<void> showNotification({
    required String title,
    required String body,
    int id = 0,
  }) async {
    if (!_notificationsEnabled) {
      debugPrint('Notifications disabled - showing in-app notification instead');
      // In-app notification will be handled by the UI layer
      return;
    }

    // Show actual system notification
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'admin_channel',
      'Admin Notifications',
      channelDescription: 'Notifications for admin actions and updates',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails,
    );

    debugPrint('System notification shown: $title - $body');
  }

  Future<void> showProblemReportNotification(int newReportsCount) async {
    if (newReportsCount <= 0) return;

    final title = 'New Problem Report${newReportsCount > 1 ? 's' : ''}';
    final body = 'You have $newReportsCount new problem report${newReportsCount > 1 ? 's' : ''} to review';

    await showNotification(
      title: title,
      body: body,
      id: 1, // Use ID 1 for problem reports
    );
  }

  Future<void> showPaymentProofNotification(int newProofsCount) async {
    if (newProofsCount <= 0) return;

    final title = 'New Payment Proof${newProofsCount > 1 ? 's' : ''}';
    final body = 'You have $newProofsCount new payment proof${newProofsCount > 1 ? 's' : ''} to review';

    await showNotification(
      title: title,
      body: body,
      id: 2, // Use ID 2 for payment proofs
    );
  }

  Future<void> showFeatureRequestNotification(int newRequestsCount) async {
    if (newRequestsCount <= 0) return;

    final title = 'New Feature Request${newRequestsCount > 1 ? 's' : ''}';
    final body = 'You have $newRequestsCount new feature request${newRequestsCount > 1 ? 's' : ''} to review';

    await showNotification(
      title: title,
      body: body,
      id: 3, // Use ID 3 for feature requests
    );
  }

  /// Cancel a specific notification
  Future<void> cancelNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }
}