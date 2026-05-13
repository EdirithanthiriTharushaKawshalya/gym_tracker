import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';

@pragma('vm:entry-point')
class BackgroundService {
  static const String notificationChannelId = 'workout_foreground';
  static const int notificationId = 888;

  static Future<void> initialize() async {
    final service = FlutterBackgroundService();

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      notificationChannelId,
      'Workout Foreground Service',
      description: 'Keeps your workout session alive in the background',
      importance: Importance.low,
    );

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: notificationChannelId,
        initialNotificationTitle: 'Workout Active',
        initialNotificationContent: 'Your session is running in the background',
        foregroundServiceNotificationId: notificationId,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }

  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    return true;
  }

  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();

    final notificationService = NotificationService();
    await notificationService.init();

    service.on('stopService').listen((event) {
      service.stopSelf();
    });

    // Check for timer end time in background
    Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (service is AndroidServiceInstance) {
        if (await service.isForegroundService()) {
          final prefs = await SharedPreferences.getInstance();
          final endTimeStr = prefs.getString('timer_end_time');
          
          if (endTimeStr != null) {
            final endTime = DateTime.parse(endTimeStr);
            final now = DateTime.now();
            final remaining = endTime.difference(now).inSeconds;
            
            if (remaining > 0) {
              service.setForegroundNotificationInfo(
                title: "Workout Active",
                content: "Resting: ${remaining}s remaining",
              );
            } else {
              // Timer just finished in background
              prefs.remove('timer_end_time');
              service.setForegroundNotificationInfo(
                title: "Workout Active",
                content: "Rest Over! Get back to work.",
              );
              // Trigger the local notification as a fallback for high priority
              notificationService.showRestTimerNotification(0);
            }
          }
        }
      }
    });
  }
}
