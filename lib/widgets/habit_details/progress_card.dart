import 'package:flutter/material.dart';
import 'package:habit_tracker/models/habit.dart';

class ProgressCard extends StatelessWidget {
  final Habit habit;

  const ProgressCard({
    super.key,
    required this.habit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Progress',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: habit.progress,
              minHeight: 10,
            ),
            const SizedBox(height: 8),
            Text(
              '${(habit.progress * 100).toInt()}% Complete',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            Text(
              '${habit.currentStreak} days out of ${habit.targetDays}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
} 