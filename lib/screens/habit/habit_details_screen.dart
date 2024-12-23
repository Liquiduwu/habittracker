import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:habit_tracker/models/habit.dart';
import 'package:habit_tracker/screens/habit/habit_form_screen.dart';
import 'package:provider/provider.dart';
import 'package:habit_tracker/services/habit_service.dart';
import 'package:habit_tracker/models/reward.dart';
import 'package:habit_tracker/services/reward_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:habit_tracker/screens/journal/journal_entry_screen.dart';
import 'package:habit_tracker/services/journal_service.dart';
import 'package:habit_tracker/models/journal_entry.dart';

class HabitDetailsScreen extends StatelessWidget {
  final Habit habit;

  const HabitDetailsScreen({super.key, required this.habit});

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(habit.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareProgress(context),
          ),
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
          IconButton(
            icon: const Icon(Icons.edit_note),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => JournalEntryScreen(habit: habit),
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
          _RewardsSection(habit: habit),
          const SizedBox(height: 16),
          _CompletionHistory(habit: habit),
          const SizedBox(height: 16),
          _JournalSection(habit: habit),
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

class _RewardsSection extends StatelessWidget {
  final Habit habit;

  const _RewardsSection({required this.habit});

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'sprout':
        return Icons.eco;
      case 'fire':
        return Icons.local_fire_department;
      case 'star':
        return Icons.stars;
      case 'trophy':
        return Icons.emoji_events;
      default:
        return Icons.emoji_events;
    }
  }

  String _getRewardStatus(Reward reward, int currentStreak) {
    if (reward.isUnlocked) {
      return 'Completed!';
    }
    final daysLeft = reward.requiredStreak - currentStreak;
    return '$daysLeft ${daysLeft == 1 ? 'day' : 'days'} to go';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rewards',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            StreamBuilder<List<Reward>>(
              stream: context.read<RewardService>().getUserRewards(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final rewards = snapshot.data!;
                context.read<RewardService>().checkAndUpdateRewards(habit.currentStreak);

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: rewards.length,
                  itemBuilder: (context, index) {
                    final reward = rewards[index];
                    final isCompleted = habit.currentStreak >= reward.requiredStreak;
                    
                    return ListTile(
                      leading: Icon(
                        _getIconData(reward.iconName),
                        color: reward.isUnlocked
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey,
                        size: 24,
                      ),
                      title: Text(
                        reward.title,
                        style: TextStyle(
                          fontWeight: reward.isUnlocked ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(reward.description),
                      trailing: reward.isUnlocked
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : Text(
                              _getRewardStatus(reward, habit.currentStreak),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
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

class _JournalSection extends StatelessWidget {
  final Habit habit;

  const _JournalSection({required this.habit});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Journal Entries',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => JournalEntryScreen(habit: habit),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Entry'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            StreamBuilder<List<JournalEntry>>(
              stream: context.read<JournalService>().getJournalEntries(habit.id),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final entries = snapshot.data!;
                if (entries.isEmpty) {
                  return const Center(
                    child: Text('No journal entries yet'),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    return ListTile(
                      leading: Text(_getMoodEmoji(entry.mood)),
                      title: Text(
                        entry.content,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        _formatDate(entry.date),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => JournalEntryScreen(
                              habit: habit,
                              existingEntry: entry,
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _getMoodEmoji(String mood) {
    switch (mood) {
      case 'great':
        return '😄';
      case 'good':
        return '🙂';
      case 'okay':
        return '😐';
      case 'difficult':
        return '😔';
      default:
        return '🙂';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
} 