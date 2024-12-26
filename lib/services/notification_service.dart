import 'dart:ui';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:habit_tracker/models/habit.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  Future<void> initialize() async {
    tz.initializeTimeZones();

    await AwesomeNotifications().initialize(
      null,
      [
        NotificationChannel(
          channelKey: 'habit_reminders',
          channelName: 'Habit Reminders',
          channelDescription: 'Daily reminders for habits',
          defaultColor: const Color(0xFF9D50DD),
          importance: NotificationImportance.High,
          channelShowBadge: true,
        ),
      ],
      debug: true,
    );
  }

  Future<void> scheduleHabitReminder(Habit habit) async {
    if (!habit.reminderEnabled || habit.reminderTime == null) return;

    final now = DateTime.now();
    var scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      habit.reminderTime!.hour,
      habit.reminderTime!.minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: habit.id.hashCode,
        channelKey: 'habit_reminders',
        title: 'Habit Reminder',
        body: 'Time to work on: ${habit.title}',
        notificationLayout: NotificationLayout.Default,
      ),
      schedule: NotificationCalendar(
        hour: habit.reminderTime!.hour,
        minute: habit.reminderTime!.minute,
        repeats: true,
      ),
    );
  }

  Future<void> cancelHabitReminder(String habitId) async {
    await AwesomeNotifications().cancel(habitId.hashCode);
  }

  Future<void> requestPermissions() async {
    await AwesomeNotifications().requestPermissionToSendNotifications();
  }
} 