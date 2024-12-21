import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:habit_tracker/services/habit_service.dart';
import 'package:habit_tracker/models/habit.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
      ),
      body: Consumer<HabitService?>(
        builder: (context, habitService, child) {
          if (habitService == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return StreamBuilder<List<Habit>>(
            stream: habitService.getHabits(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final habits = snapshot.data!;
              final completedDates = _getCompletedDates(habits);

              return Column(
                children: [
                  TableCalendar(
                    firstDay: DateTime.utc(2024, 1, 1),
                    lastDay: DateTime.now().add(const Duration(days: 365)),
                    focusedDay: _focusedDay,
                    selectedDayPredicate: (day) => isSameDay(context, _selectedDay ?? DateTime.now(), day),
                    calendarFormat: _calendarFormat,
                    eventLoader: (day) {
                      return completedDates[day] ?? [];
                    },
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                    },
                    onFormatChanged: (format) {
                      setState(() {
                        _calendarFormat = format;
                      });
                    },
                    calendarStyle: CalendarStyle(
                      markerDecoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const Divider(),
                  Expanded(
                    child: _selectedDay == null
                        ? const Center(
                            child: Text('Select a day to see completed habits'),
                          )
                        : _HabitList(
                            habits: habits,
                            selectedDay: _selectedDay!,
                          ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Map<DateTime, List<Habit>> _getCompletedDates(List<Habit> habits) {
    final Map<DateTime, List<Habit>> completedDates = {};

    for (final habit in habits) {
      for (final date in habit.completedDates) {
        final key = DateTime(date.year, date.month, date.day);
        completedDates[key] = [...(completedDates[key] ?? []), habit];
      }
    }

    return completedDates;
  }

  bool isSameDay(BuildContext context, DateTime a, DateTime b) {
    return context.read<HabitService>().isSameDay(a, b);
  }
}

class _HabitList extends StatelessWidget {
  final List<Habit> habits;
  final DateTime selectedDay;

  const _HabitList({
    required this.habits,
    required this.selectedDay,
  });

  @override
  Widget build(BuildContext context) {
    final completedHabits = habits.where((habit) {
      return habit.completedDates.any((date) => isSameDay(context, date, selectedDay));
    }).toList();

    if (completedHabits.isEmpty) {
      return Center(
        child: Text(
          'No habits completed on ${selectedDay.toString().split(' ')[0]}',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: completedHabits.length,
      itemBuilder: (context, index) {
        final habit = completedHabits[index];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.check_circle),
            title: Text(habit.title),
            subtitle: Text(habit.description),
          ),
        );
      },
    );
  }

  bool isSameDay(BuildContext context, DateTime a, DateTime b) {
    return context.read<HabitService>().isSameDay(a, b);
  }
} 