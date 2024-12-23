import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:habit_tracker/models/habit.dart';
import 'package:habit_tracker/services/habit_service.dart';
import 'package:habit_tracker/screens/habit/habit_form_screen.dart';
import 'package:habit_tracker/screens/habit/habit_details_screen.dart';
import 'package:share_plus/share_plus.dart';

class HabitCard extends StatelessWidget {
  final Habit habit;

  const HabitCard({super.key, required this.habit});

  @override
  Widget build(BuildContext context) {
    final progress = (habit.currentStreak / habit.targetDays * 100).clamp(0, 100);
    
    return Card(
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => HabitDetailsScreen(habit: habit),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          habit.title,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        if (habit.description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            habit.description,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ],
                    ),
                  ),
                  CircularProgressIndicator(
                    value: progress / 100,
                    backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                    strokeWidth: 8,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${progress.toInt()}%',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () {
                      _showOptions(context);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Streak',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.local_fire_department,
                            color: Theme.of(context).colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${habit.currentStreak} days',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      context.read<HabitService>().toggleHabitCompletion(habit);
                    },
                    icon: Icon(
                      habit.completedDates.any((date) =>
                              context.read<HabitService>().isSameDay(date, DateTime.now()))
                          ? Icons.check_circle
                          : Icons.circle_outlined,
                    ),
                    label: const Text('Done for Today'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: habit.progress,
                backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                minHeight: 6,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Share Progress'),
                onTap: () {
                  Navigator.pop(context);
                  _shareProgress(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HabitFormScreen(habit: habit),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _shareProgress(BuildContext context) {
    final completionRate = (habit.completedDates.length / habit.targetDays * 100).clamp(0, 100);
    final streakEmoji = habit.currentStreak >= 7 ? '🔥' : '✨';
    
    final message = '''
Check out my progress in building this habit! $streakEmoji

🎯 ${habit.title}
📝 ${habit.description}
🔄 Current Streak: ${habit.currentStreak} days
⭐ Completion Rate: ${completionRate.toStringAsFixed(1)}%
📅 Total Days: ${habit.completedDates.length}

Track your habits too with Daily Habit Tracker!
''';

    Share.share(message);
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Habit'),
          content: const Text('Are you sure you want to delete this habit?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                context.read<HabitService>().deleteHabit(habit.id);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  bool _isSameDay(BuildContext context, DateTime a, DateTime b) {
    return context.read<HabitService>().isSameDay(a, b);
  }
} 