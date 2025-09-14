import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static bool _isInitialized = false;
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    _isInitialized = true;
    await _initializePlugin();
    await _requestPermission();
    print('✅ Notification Service initialized');
  }

  static Future<void> _initializePlugin() async {
    const AndroidInitializationSettings androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosInit = DarwinInitializationSettings();
    const InitializationSettings initSettings = InitializationSettings(android: androidInit, iOS: iosInit);
    await _plugin.initialize(initSettings);
  }

  static Future<void> _requestPermission() async {
    try {
      if (kIsWeb) return;
      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidPlugin = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        await androidPlugin?.requestNotificationsPermission();
      }
      // iOS/macOS permissions
      final iosPlugin = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      await iosPlugin?.requestPermissions(alert: true, badge: true, sound: true);
    } catch (e) {
      print('❌ Notification permission error: $e');
    }
  }

  static Future<void> showNotification({
    required String title,
    required String body,
    String? icon,
  }) async {
    try {
      if (kIsWeb) {
        print('📢 Notification: $title - $body');
        return;
      }
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'default_channel',
        'General',
        channelDescription: 'General notifications',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      );
      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();
      const NotificationDetails details = NotificationDetails(android: androidDetails, iOS: iosDetails);
      await _plugin.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title,
        body,
        details,
      );
    } catch (e) {
      print('❌ Show notification error: $e');
    }
  }

  static Future<void> notifyDoctorUnavailable({
    required String doctorName,
    required String alternativeDate,
  }) async {
    await showNotification(
      title: 'Doctor Not Available',
      body: 'Dr. $doctorName is not available. Alternative date: $alternativeDate',
    );
  }

  static Future<void> notifyAppointmentConfirmed({
    required String doctorName,
    required String date,
    required String time,
  }) async {
    await showNotification(
      title: 'Appointment Confirmed',
      body: 'Your appointment with Dr. $doctorName on $date at $time has been confirmed.',
    );
  }

  static Future<void> notifyEmergencyResponse({
    required String message,
  }) async {
    await showNotification(
      title: 'Emergency Response',
      body: message,
    );
  }
}
