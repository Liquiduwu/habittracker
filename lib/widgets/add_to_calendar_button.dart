import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:habit_tracker/models/habit.dart';

class AddToCalendarButton extends StatelessWidget {
  final Habit habit;

  const AddToCalendarButton({required this.habit});

  String _generateCalendarUrl(Habit habit) {
    final startDate = DateTime.now(); // Set the start date
    final endDate = startDate.add(Duration(hours: 1)); // 1-hour event

    final startDateFormatted = _formatDateForCalendar(startDate);
    final endDateFormatted = _formatDateForCalendar(endDate);

    final details =
        Uri.encodeComponent(habit.description ?? 'Habit tracking event');
    final title = Uri.encodeComponent(habit.title);

    // Recurrence rule: Daily for the target days of the habit
    final recurrence = 'RRULE:FREQ=DAILY;COUNT=${habit.targetDays}';

    return 'https://calendar.google.com/calendar/render?action=TEMPLATE'
        '&text=$title'
        '&dates=$startDateFormatted/$endDateFormatted'
        '&details=$details'
        '&recur=$recurrence';
  }

  String _formatDateForCalendar(DateTime dateTime) {
    return dateTime
            .toUtc()
            .toIso8601String()
            .replaceAll('-', '')
            .replaceAll(':', '')
            .split('.')
            .first +
        'Z';
  }

  Future<void> _launchCalendarUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.calendar_today),
      label: const Text('Add to Google Calendar'),
      onPressed: () {
        final url = _generateCalendarUrl(habit);
        _launchCalendarUrl(url);
      },
    );
  }
}
