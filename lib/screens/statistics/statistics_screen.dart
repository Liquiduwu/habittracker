import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:habit_tracker/services/habit_service.dart';
import 'package:habit_tracker/models/habit.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Statistics'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Overview'),
              Tab(text: 'Progress'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _OverviewTab(),
            _ProgressTab(),
          ],
        ),
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<HabitService?>(
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
            final totalHabits = habits.length;
            final activeHabits = habits.where((h) => h.currentStreak > 0).length;
            final completedHabits =
                habits.where((h) => h.progress >= 1.0).length;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _StatCard(
                  title: 'Total Habits',
                  value: totalHabits.toString(),
                  icon: Icons.list_alt,
                ),
                const SizedBox(height: 16),
                _StatCard(
                  title: 'Active Habits',
                  value: activeHabits.toString(),
                  icon: Icons.trending_up,
                ),
                const SizedBox(height: 16),
                _StatCard(
                  title: 'Completed Habits',
                  value: completedHabits.toString(),
                  icon: Icons.check_circle_outline,
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _ProgressTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<HabitService?>(
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
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: habits.length,
              itemBuilder: (context, index) {
                final habit = habits[index];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          habit.title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: habit.progress,
                          backgroundColor:
                              Theme.of(context).colorScheme.surfaceVariant,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${(habit.progress * 100).toInt()}% Complete',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 48, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                Text(value, style: Theme.of(context).textTheme.headlineMedium),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 