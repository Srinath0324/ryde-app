import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:timezone/timezone.dart' as tz;
import 'dart:convert';
import 'dart:typed_data';

class NotificationService {
  static final FlutterLocalNotificationsPlugin
  _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  /// Initialize local notifications
  static Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channels for Android
    await _createNotificationChannels();
  }

  /// Create notification channels for different types of notifications
  static Future<void> _createNotificationChannels() async {
    const List<AndroidNotificationChannel> channels = [
      AndroidNotificationChannel(
        'ride_updates',
        'Ride Updates',
        description: 'Notifications about ride status changes',
        importance: Importance.high,
        sound: RawResourceAndroidNotificationSound('ride_notification'),
      ),
      AndroidNotificationChannel(
        'driver_responses',
        'Driver Responses',
        description: 'Notifications when drivers respond to ride requests',
        importance: Importance.high,
        sound: RawResourceAndroidNotificationSound('driver_response'),
      ),
      AndroidNotificationChannel(
        'general',
        'General Notifications',
        description: 'General app notifications',
        importance: Importance.defaultImportance,
      ),
    ];

    for (final channel in channels) {
      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(channel);
    }
  }

  /// Handle notification tap
  static void _onNotificationTapped(NotificationResponse notificationResponse) {
    final String? payload = notificationResponse.payload;
    if (payload != null) {
      final Map<String, dynamic> data = jsonDecode(payload);
      _handleNotificationAction(data);
    }
  }

  /// Handle notification action based on type
  static void _handleNotificationAction(Map<String, dynamic> data) {
    final String type = data['type'] ?? '';

    switch (type) {
      case 'ride_request_accepted':
        // Navigate to ride tracking screen
        break;
      case 'driver_response':
        // Navigate to fare negotiation screen
        break;
      case 'ride_completed':
        // Navigate to ride history or rating screen
        break;
      default:
        // Navigate to home screen
        break;
    }
  }

  /// Show ride request confirmation notification
  static Future<void> showRideRequestNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    final AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
          'ride_updates',
          'Ride Updates',
          channelDescription: 'Notifications about ride status changes',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFF2196F3),
          playSound: true,
          enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
        );

    const DarwinNotificationDetails iosNotificationDetails =
        DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          sound: 'ride_notification.aiff',
        );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: iosNotificationDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      1,
      title,
      body,
      notificationDetails,
      payload: data != null ? jsonEncode(data) : null,
    );
  }

  /// Show driver response notification
  static Future<void> showDriverResponseNotification({
    required String driverName,
    required double fareAmount,
    String? message,
    Map<String, dynamic>? data,
  }) async {
    final String title = 'New Offer from $driverName';
    final String body =
        message != null
            ? '₹${fareAmount.toInt()} - $message'
            : '₹${fareAmount.toInt()}';

    final AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
          'driver_responses',
          'Driver Responses',
          channelDescription:
              'Notifications when drivers respond to ride requests',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFF4CAF50),
          playSound: true,
          enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 500, 250, 500]),
          actions: <AndroidNotificationAction>[
            AndroidNotificationAction(
              'accept',
              'Accept',
              icon: DrawableResourceAndroidBitmap('@drawable/ic_check'),
            ),
            AndroidNotificationAction(
              'counter',
              'Counter',
              icon: DrawableResourceAndroidBitmap('@drawable/ic_reply'),
            ),
          ],
        );

    const DarwinNotificationDetails iosNotificationDetails =
        DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          sound: 'driver_response.aiff',
          categoryIdentifier: 'DRIVER_RESPONSE',
        );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: iosNotificationDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      2,
      title,
      body,
      notificationDetails,
      payload: data != null ? jsonEncode(data) : null,
    );
  }

  /// Show ride accepted notification
  static Future<void> showRideAcceptedNotification({
    required String driverName,
    required String vehicleInfo,
    required double fareAmount,
    Map<String, dynamic>? data,
  }) async {
    final AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
          'ride_updates',
          'Ride Updates',
          channelDescription: 'Notifications about ride status changes',
          importance: Importance.max,
          priority: Priority.max,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFF4CAF50),
          playSound: true,
          enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 1000, 500, 1000, 500, 1000]),
          ongoing: true, // Make it persistent
          autoCancel: false,
          actions: <AndroidNotificationAction>[
            AndroidNotificationAction(
              'call_driver',
              'Call Driver',
              icon: DrawableResourceAndroidBitmap('@drawable/ic_call'),
            ),
            AndroidNotificationAction(
              'track_ride',
              'Track',
              icon: DrawableResourceAndroidBitmap('@drawable/ic_location'),
            ),
          ],
        );

    const DarwinNotificationDetails iosNotificationDetails =
        DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          sound: 'ride_accepted.aiff',
          categoryIdentifier: 'RIDE_ACCEPTED',
        );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: iosNotificationDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      3,
      'Ride Confirmed! 🚗',
      '$driverName is coming to pick you up\n$vehicleInfo • ₹${fareAmount.toInt()}',
      notificationDetails,
      payload: data != null ? jsonEncode(data) : null,
    );
  }

  /// Show ride completion notification
  static Future<void> showRideCompletedNotification({
    required double fareAmount,
    required String paymentMethod,
    Map<String, dynamic>? data,
  }) async {
    final AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
          'ride_updates',
          'Ride Updates',
          channelDescription: 'Notifications about ride status changes',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFF2196F3),
          playSound: true,
          actions: <AndroidNotificationAction>[
            AndroidNotificationAction(
              'rate_driver',
              'Rate Driver',
              icon: DrawableResourceAndroidBitmap('@drawable/ic_star'),
            ),
            AndroidNotificationAction(
              'view_receipt',
              'Receipt',
              icon: DrawableResourceAndroidBitmap('@drawable/ic_receipt'),
            ),
          ],
        );

    const DarwinNotificationDetails iosNotificationDetails =
        DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          categoryIdentifier: 'RIDE_COMPLETED',
        );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: iosNotificationDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      4,
      'Ride Completed! ✅',
      'Fare: ₹${fareAmount.toInt()} • Paid via $paymentMethod',
      notificationDetails,
      payload: data != null ? jsonEncode(data) : null,
    );
  }

  /// Show general notification
  static Future<void> showGeneralNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    final AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
          'general',
          'General Notifications',
          channelDescription: 'General app notifications',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFF2196F3),
        );

    const DarwinNotificationDetails iosNotificationDetails =
        DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: iosNotificationDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      notificationDetails,
      payload: data != null ? jsonEncode(data) : null,
    );
  }

  /// Cancel specific notification
  static Future<void> cancelNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
  }

  /// Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }

  /// Check if notifications are enabled
  static Future<bool> areNotificationsEnabled() async {
    final bool? result =
        await _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.areNotificationsEnabled();
    return result ?? false;
  }

  /// Request permission for notifications
  static Future<bool> requestNotificationPermission() async {
    final bool? result =
        await _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.requestNotificationsPermission();
    return result ?? false;
  }

  /// Schedule a notification
  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    Map<String, dynamic>? data,
  }) async {
    final AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
          'general',
          'General Notifications',
          channelDescription: 'General app notifications',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        );

    const DarwinNotificationDetails iosNotificationDetails =
        DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: iosNotificationDetails,
    );

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      notificationDetails,
      payload: data != null ? jsonEncode(data) : null,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }
}
