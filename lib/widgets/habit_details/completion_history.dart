import 'package:flutter/material.dart';
import 'package:habit_tracker/models/habit.dart';

class CompletionHistory extends StatelessWidget {
  final Habit habit;

  const CompletionHistory({
    super.key,
    required this.habit,
  });

  @override
  Widget build(BuildContext context) {
    final sortedDates = [...habit.completedDates]..sort((a, b) => b.compareTo(a));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Completion History',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sortedDates.length,
              itemBuilder: (context, index) {
                final date = sortedDates[index];
                return ListTile(
                  leading: const Icon(Icons.check_circle),
                  title: Text(
                    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
} 