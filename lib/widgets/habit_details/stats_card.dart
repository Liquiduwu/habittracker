import 'package:flutter/material.dart';
import 'package:habit_tracker/models/habit.dart';

class StatsCard extends StatelessWidget {
  final Habit habit;

  const StatsCard({
    super.key,
    required this.habit,
  });

  @override
  Widget build(BuildContext context) {
    final totalDays = DateTime.now().difference(habit.createdAt).inDays + 1;
    final completionRate =
        (habit.completedDates.length / totalDays * 100).toStringAsFixed(1);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statistics',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _StatRow(
              label: 'Current Streak',
              value: '${habit.currentStreak} days',
            ),
            const Divider(),
            _StatRow(
              label: 'Total Completions',
              value: habit.completedDates.length.toString(),
            ),
            const Divider(),
            _StatRow(
              label: 'Completion Rate',
              value: '$completionRate%',
            ),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;

  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyLarge),
          Text(value, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
} 