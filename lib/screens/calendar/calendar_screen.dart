import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:habit_tracker/services/habit_service.dart';
import 'package:habit_tracker/models/habit.dart';

// Main screen widget for the calendar
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  // Currently focused day in the calendar
  DateTime _focusedDay = DateTime.now();
  // Currently selected day in the calendar
  DateTime? _selectedDay;
  // Current calendar format (month, two weeks, or week view)
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Title for the calendar screen
        title: const Text('Calendar'),
      ),
      body: Consumer<HabitService?>(
        // Listen for changes in HabitService using Provider
        builder: (context, habitService, child) {
          if (habitService == null) {
            // Show loading indicator if HabitService is not yet available
            return const Center(child: CircularProgressIndicator());
          }

          return StreamBuilder<List<Habit>>(
            // Stream of habits fetched from HabitService
            stream: habitService.getHabits(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                // Show loading indicator while habits are being fetched
                return const Center(child: CircularProgressIndicator());
              }

              // List of habits from the stream
              final habits = snapshot.data!;
              // Map of completed dates and the corresponding habits
              final completedDates = _getCompletedDates(habits);

              return Column(
                children: [
                  // Calendar widget to display habits based on completed dates
                  TableCalendar(
                    firstDay:
                        DateTime.utc(2024, 1, 1), // Start date for the calendar
                    lastDay: DateTime.now().add(
                        const Duration(days: 365)), // End date for the calendar
                    focusedDay: _focusedDay, // Currently focused day
                    selectedDayPredicate: (day) => isSameDay(
                        context,
                        _selectedDay ?? DateTime.now(),
                        day), // Highlight selected day
                    calendarFormat:
                        _calendarFormat, // Current format (month, week, etc.)
                    eventLoader: (day) {
                      // Load events (completed habits) for the given day
                      return completedDates[day] ?? [];
                    },
                    onDaySelected: (selectedDay, focusedDay) {
                      // Update selected and focused day when a day is selected
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                    },
                    onFormatChanged: (format) {
                      // Update calendar format when user changes it
                      setState(() {
                        _calendarFormat = format;
                      });
                    },
                    calendarStyle: CalendarStyle(
                      // Style for markers (indicators of completed habits)
                      markerDecoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary, // Use theme's primary color
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const Divider(), // Divider between calendar and habit list
                  Expanded(
                    // Display list of habits completed on the selected day
                    child: _selectedDay == null
                        ? const Center(
                            child: Text(
                                'Select a day to see completed habits'), // Message for no selected day
                          )
                        : _HabitList(
                            habits: habits, // Pass habits to _HabitList widget
                            selectedDay: _selectedDay!, // Pass selected day
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

  // Map completed dates to their corresponding habits
  Map<DateTime, List<Habit>> _getCompletedDates(List<Habit> habits) {
    final Map<DateTime, List<Habit>> completedDates = {};

    for (final habit in habits) {
      // Iterate over each habit's completed dates
      for (final date in habit.completedDates) {
        final key = DateTime(date.year, date.month,
            date.day); // Normalize date (remove time component)
        completedDates[key] = [
          ...(completedDates[key] ?? []),
          habit
        ]; // Add habit to the map
      }
    }

    return completedDates;
  }

  // Helper method to check if two dates are the same (ignoring time)
  bool isSameDay(BuildContext context, DateTime a, DateTime b) {
    return context
        .read<HabitService>()
        .isSameDay(a, b); // Use HabitService's isSameDay method
  }
}

// Widget to display the list of habits completed on the selected day
class _HabitList extends StatelessWidget {
  final List<Habit> habits; // List of all habits
  final DateTime selectedDay; // Selected day for which to display habits

  const _HabitList({
    required this.habits,
    required this.selectedDay,
  });

  @override
  Widget build(BuildContext context) {
    // Filter habits completed on the selected day
    final completedHabits = habits.where((habit) {
      return habit.completedDates
          .any((date) => isSameDay(context, date, selectedDay));
    }).toList();

    if (completedHabits.isEmpty) {
      // Show message if no habits were completed on the selected day
      return Center(
        child: Text(
          'No habits completed on ${selectedDay.toString().split(' ')[0]}', // Format the date
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }

    return ListView.builder(
      // Build a list of completed habits
      padding: const EdgeInsets.all(16),
      itemCount: completedHabits.length,
      itemBuilder: (context, index) {
        final habit = completedHabits[index]; // Get each habit
        return Card(
          child: ListTile(
            leading: const Icon(Icons.check_circle), // Icon for completed habit
            title: Text(habit.title), // Title of the habit
            subtitle: Text(habit.description), // Description of the habit
          ),
        );
      },
    );
  }

  // Helper method to check if two dates are the same (ignoring time)
  bool isSameDay(BuildContext context, DateTime a, DateTime b) {
    return context
        .read<HabitService>()
        .isSameDay(a, b); // Use HabitService's isSameDay method
  }
}
