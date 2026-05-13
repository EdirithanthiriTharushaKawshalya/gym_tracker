import 'dart:typed_data';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz_data.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (e) {
      // Fallback if timezone detection fails
    }

    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(settings: settings);
  }

  Future<void> showRestTimerNotification(int seconds) async {
    final Int64List vibrationPattern = Int64List.fromList([0, 500, 200, 500]);
    
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'rest_timer_v2', // Changed channel ID to force fresh settings
      'Rest Timer',
      channelDescription: 'Notifications for rest timer completion',
      importance: Importance.max,
      priority: Priority.max,
      showWhen: true,
      vibrationPattern: vibrationPattern,
      enableVibration: true,
      category: AndroidNotificationCategory.alarm,
      autoCancel: false, // Ensures tapping the notification doesn't dismiss it automatically
      ongoing: false,
      visibility: NotificationVisibility.public,
      timeoutAfter: 60000, // Stay on screen for at least 60 seconds unless dismissed
    );

    final NotificationDetails details = NotificationDetails(android: androidDetails);

    await _notifications.zonedSchedule(
      id: 0,
      title: 'Rest Over!',
      body: 'Time for your next set!',
      scheduledDate: tz.TZDateTime.now(tz.local).add(Duration(seconds: seconds)),
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> cancelRestTimerNotification() async {
    await _notifications.cancel(id: 0);
  }

  Future<void> showWorkoutInProgressNotification(String workoutName) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'workout_in_progress',
      'Workout in Progress',
      channelDescription: 'Persistent notification when a workout is active',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      showWhen: false,
    );

    const NotificationDetails details = NotificationDetails(android: androidDetails);

    await _notifications.show(
      id: 1,
      title: 'Workout Active: $workoutName',
      body: 'Tap to return to your workout',
      notificationDetails: details,
    );
  }

  Future<void> cancelWorkoutNotification() async {
    await _notifications.cancel(id: 1);
  }
}
