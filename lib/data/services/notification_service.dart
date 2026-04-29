import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin plugin =
      FlutterLocalNotificationsPlugin();

  // ===============================
  // INIT
  // ===============================
  static Future<void> init() async {
    const AndroidInitializationSettings android = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const InitializationSettings settings = InitializationSettings(
      android: android,
    );

    await plugin.initialize(settings);

    await plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    tz.initializeTimeZones();

    tz.setLocalLocation(tz.getLocation('Asia/Makassar'));
  }

  // ===============================
  // NOTIFIKASI LANGSUNG
  // ===============================
  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    await plugin.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'debt_channel',
          'Debt Reminder',
          channelDescription: 'Pengingat hutang',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
    );
  }

  // ===============================
  // NOTIFIKASI TERJADWAL
  // ===============================
  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime date,
  }) async {
    await plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(date, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'debt_channel',
          'Debt Reminder',
          channelDescription: 'Pengingat hutang',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}
