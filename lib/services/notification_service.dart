import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import '../models/reminder_model.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
  FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(settings);
  }

  static Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'study_channel',
      'Study Notifications',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(id, title, body, details);
  }

  static Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    final scheduledTime = tz.TZDateTime(
      tz.local,
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
      hour,
      minute,
    );

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = scheduledTime;
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      'study_channel',
      'Study Notifications',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      details,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  static Future<void> scheduleReminderNotifications(ReminderItem item) async {
    final notificationId = item.id.hashCode;
    
    // Cancel any existing notifications for this reminder first
    await cancelNotification(notificationId);
    await cancelNotification(notificationId + 1); // for pre-due alert
    for (int i = 1; i <= 5; i++) {
      await cancelNotification(notificationId + i); // weekdays
    }
    
    if (item.isCompleted) return;

    final targetDateTime = item.scheduledDateTime;
    if (targetDateTime.isBefore(DateTime.now())) return;

    final tzDateTime = tz.TZDateTime.from(targetDateTime, tz.local);

    const androidDetails = AndroidNotificationDetails(
      'reminder_channel',
      'Reminders',
      channelDescription: 'Scheduled study and personal task reminders',
      importance: Importance.max,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
      actions: [
        AndroidNotificationAction('complete', 'Complete'),
        AndroidNotificationAction('snooze', 'Snooze'),
      ],
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // 1. Schedule main due-time notification
    if (item.repeat == RepeatType.oneTime) {
      await _notifications.zonedSchedule(
        notificationId,
        item.title,
        item.description.isNotEmpty ? item.description : 'Your reminder is due!',
        tzDateTime,
        details,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } else {
      DateTimeComponents? matchComponents;
      if (item.repeat == RepeatType.daily) {
        matchComponents = DateTimeComponents.time;
      } else if (item.repeat == RepeatType.weekly) {
        matchComponents = DateTimeComponents.dayOfWeekAndTime;
      } else if (item.repeat == RepeatType.monthly) {
        matchComponents = DateTimeComponents.dayOfMonthAndTime;
      }
      
      if (matchComponents != null) {
        await _notifications.zonedSchedule(
          notificationId,
          item.title,
          item.description.isNotEmpty ? item.description : 'Your reminder is due!',
          tzDateTime,
          details,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: matchComponents,
        );
      } else if (item.repeat == RepeatType.weekdays) {
        // Weekdays: schedule for Monday to Friday
        for (int i = 1; i <= 5; i++) {
          final weekdayOffset = (i - targetDateTime.weekday) % 7;
          final weekdayTime = targetDateTime.add(Duration(days: weekdayOffset));
          final tzWeekdayTime = tz.TZDateTime.from(weekdayTime, tz.local);
          if (tzWeekdayTime.isAfter(DateTime.now())) {
            await _notifications.zonedSchedule(
              notificationId + i,
              item.title,
              item.description.isNotEmpty ? item.description : 'Your reminder is due!',
              tzWeekdayTime,
              details,
              uiLocalNotificationDateInterpretation:
                  UILocalNotificationDateInterpretation.absoluteTime,
              androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
              matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
            );
          }
        }
      }
    }

    // 2. Schedule Pre-due alert if set
    if (item.preDueMinutes > 0) {
      final preDueTime = targetDateTime.subtract(Duration(minutes: item.preDueMinutes));
      if (preDueTime.isAfter(DateTime.now())) {
        final tzPreDueTime = tz.TZDateTime.from(preDueTime, tz.local);
        await _notifications.zonedSchedule(
          notificationId + 1,
          'Upcoming: ${item.title}',
          'Due in ${item.preDueMinutes} minutes.',
          tzPreDueTime,
          details,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
      }
    }
  }

  static Future<void> cancelReminderNotifications(String reminderId) async {
    final notificationId = reminderId.hashCode;
    await cancelNotification(notificationId);
    await cancelNotification(notificationId + 1); // pre-due
    for (int i = 1; i <= 5; i++) {
      await cancelNotification(notificationId + i); // weekdays
    }
  }

  static Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }
}