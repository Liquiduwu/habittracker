import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:habit_tracker/models/habit.dart';
import 'package:habit_tracker/screens/habit/habit_form_screen.dart';
import 'package:provider/provider.dart';
import 'package:habit_tracker/services/habit_service.dart';

class HabitDetailsScreen extends StatelessWidget {
  final Habit habit;

  const HabitDetailsScreen({super.key, required this.habit});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(habit.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HabitFormScreen(habit: habit),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ProgressCard(habit: habit),
          const SizedBox(height: 16),
          _StatsCard(habit: habit),
          const SizedBox(height: 16),
          _WeeklyChart(habit: habit),
          const SizedBox(height: 16),
          _CompletionHistory(habit: habit),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final Habit habit;

  const _ProgressCard({required this.habit});

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

class _StatsCard extends StatelessWidget {
  final Habit habit;

  const _StatsCard({required this.habit});

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

class _WeeklyChart extends StatelessWidget {
  final Habit habit;

  const _WeeklyChart({required this.habit});

  @override
  Widget build(BuildContext context) {
    final weekData = _getWeeklyData(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Weekly Progress',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 1,
                  barGroups: weekData,
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                          return Text(days[value.toInt()]);
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<BarChartGroupData> _getWeeklyData(BuildContext context) {
    final now = DateTime.now();
    final weekDays = List.generate(7, (index) {
      final date = now.subtract(Duration(days: now.weekday - index - 1));
      return date;
    });

    return List.generate(7, (index) {
      final isCompleted = habit.completedDates.any(
        (date) => context.read<HabitService>().isSameDay(date, weekDays[index]),
      );
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: isCompleted ? 1 : 0,
            color: isCompleted
                ? Colors.green
                : Colors.grey.withOpacity(0.2),
            width: 20,
          ),
        ],
      );
    });
  }
}

class _CompletionHistory extends StatelessWidget {
  final Habit habit;

  const _CompletionHistory({required this.habit});

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