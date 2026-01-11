import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:convert';
import '../models/in_app_notification.dart';
import '../models/appointment.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
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
    String? appointmentId,
  }) async {
    // Show device notification
    await showNotification(
      title: 'Appointment Confirmed',
      body: 'Your appointment with Dr. $doctorName on $date at $time has been confirmed.',
    );

    // Create in-app notification
    await createInAppNotification(
      title: 'Appointment Confirmed',
      description: 'Appointment with Dr. $doctorName on $date at $time confirmed',
      icon: Icons.calendar_today,
      iconColor: Colors.green,
      iconBackgroundColor: Colors.green.shade50,
      appointmentId: appointmentId,
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

  // In-app notification methods
  static Future<void> createInAppNotification({
    required String title,
    required String description,
    required IconData icon,
    required Color iconColor,
    required Color iconBackgroundColor,
    String? appointmentId,
  }) async {
    try {
      final notification = InAppNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        description: description,
        createdAt: DateTime.now(),
        icon: icon,
        iconColor: iconColor,
        iconBackgroundColor: iconBackgroundColor,
        isRead: false,
        appointmentId: appointmentId,
      );

      final notifications = await getInAppNotifications();
      notifications.insert(0, notification); // Add to beginning
      
      // Keep only last 100 notifications
      if (notifications.length > 100) {
        notifications.removeRange(100, notifications.length);
      }

      await _saveInAppNotifications(notifications);
      print('✅ In-app notification created: $title');
    } catch (e) {
      print('❌ Error creating in-app notification: $e');
    }
  }

  static Future<List<InAppNotification>> getInAppNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = prefs.getString('in_app_notifications');
      
      if (notificationsJson == null) {
        return [];
      }

      final List<dynamic> notificationsList = json.decode(notificationsJson);
      return notificationsList
          .map((n) => InAppNotification.fromJson(n as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ Error loading in-app notifications: $e');
      return [];
    }
  }

  static Future<void> _saveInAppNotifications(List<InAppNotification> notifications) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = json.encode(
        notifications.map((n) => n.toJson()).toList(),
      );
      await prefs.setString('in_app_notifications', notificationsJson);
    } catch (e) {
      print('❌ Error saving in-app notifications: $e');
    }
  }

  static Future<int> getUnreadCount() async {
    final notifications = await getInAppNotifications();
    return notifications.where((n) => !n.isRead).length;
  }

  static Future<void> markAsRead(String notificationId) async {
    final notifications = await getInAppNotifications();
    final index = notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      notifications[index].isRead = true;
      await _saveInAppNotifications(notifications);
    }
  }

  static Future<void> markAllAsRead() async {
    final notifications = await getInAppNotifications();
    for (var notification in notifications) {
      notification.isRead = true;
    }
    await _saveInAppNotifications(notifications);
  }

  static Future<void> deleteNotification(String notificationId) async {
    final notifications = await getInAppNotifications();
    notifications.removeWhere((n) => n.id == notificationId);
    await _saveInAppNotifications(notifications);
  }

  static Future<void> createAppointmentNotification(Appointment appointment) async {
    final dateStr = '${appointment.appointmentDate.day}/${appointment.appointmentDate.month}/${appointment.appointmentDate.year}';
    
    await createInAppNotification(
      title: 'Appointment Confirmed',
      description: 'Appointment with Dr. ${appointment.doctorName} on $dateStr at ${appointment.timeSlot} confirmed',
      icon: Icons.calendar_today,
      iconColor: Colors.green,
      iconBackgroundColor: Colors.green.shade50,
      appointmentId: appointment.id,
    );
  }
}
