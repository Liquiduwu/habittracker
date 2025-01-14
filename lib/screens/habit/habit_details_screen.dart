import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
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
import 'package:habit_tracker/widgets/add_to_calendar_button.dart';
import 'package:habit_tracker/widgets/habit_details/motivational_section.dart';
import 'package:habit_tracker/widgets/habit_details/progress_card.dart';
import 'package:habit_tracker/widgets/habit_details/stats_card.dart';
import 'package:habit_tracker/widgets/habit_details/weekly_chart.dart';
import 'package:habit_tracker/widgets/habit_details/completion_history.dart';
import 'package:habit_tracker/widgets/habit_details/rewards_section.dart';

class HabitDetailsScreen extends StatefulWidget {
  final Habit habit;

  const HabitDetailsScreen({super.key, required this.habit});

  @override
  _HabitDetailsScreenState createState() => _HabitDetailsScreenState();
}

class _HabitDetailsScreenState extends State<HabitDetailsScreen> {
  String motivationalMessage = "Loading motivational message...";
  bool isLoadingMotivation = true;

  @override
  void initState() {
    super.initState();
    _fetchMotivationalMessage();
  }

  void _fetchMotivationalMessage() async {
    setState(() {
      isLoadingMotivation = true;
    });

    try {
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey:
            'AIzaSyA6fZ3aIeZmX-QAhyhJye3kWX4C-ZGozTY', // Use your API key or retrieve it dynamically
      );

      // Add instructions for variation and style
      final styles = [
        "inspirational",
        "funny",
        "thoughtful",
        "energetic",
        "poetic",
      ];
      final randomStyle = (styles..shuffle()).first;

      final prompt = '''
Provide a $randomStyle motivational message (less than 20 words) for the following habit:

Title: ${widget.habit.title}
Description: ${widget.habit.description}
Current Streak: ${widget.habit.currentStreak} days
Progress: ${(widget.habit.progress * 100).toInt()}%
''';

      final response = await model.generateContent([Content.text(prompt)]);

      setState(() {
        motivationalMessage = response.text?.trim() ??
            "Keep pushing forward, you're doing amazing!";
        isLoadingMotivation = false;
      });
    } catch (error) {
      setState(() {
        motivationalMessage = "Stay strong! Challenges make you grow.";
        isLoadingMotivation = false;
      });
      debugPrint("Error fetching motivational message: $error");
    }
  }

  void _shareProgress(BuildContext context) {
    final completionRate =
        (widget.habit.completedDates.length / widget.habit.targetDays * 100)
            .clamp(0, 100);
    final streakEmoji = widget.habit.currentStreak >= 7 ? '🔥' : '✨';

    final message = '''
Check out my progress in building this habit! $streakEmoji

🎯 ${widget.habit.title}
📝 ${widget.habit.description}
🔄 Current Streak: ${widget.habit.currentStreak} days
⭐ Completion Rate: ${completionRate.toStringAsFixed(1)}%
📅 Total Days: ${widget.habit.completedDates.length}

Track your habits too with Daily Habit Tracker!
''';

    Share.share(message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.habit.title),
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
                  builder: (context) => HabitFormScreen(habit: widget.habit),
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
                  builder: (context) => JournalEntryScreen(habit: widget.habit),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ProgressCard(habit: widget.habit),
          const SizedBox(height: 16),
          StatsCard(habit: widget.habit),
          const SizedBox(height: 16),
          MotivationalSection(
            motivationalMessage: motivationalMessage,
            isLoading: isLoadingMotivation,
            onRefresh: _fetchMotivationalMessage,
          ),
          const SizedBox(height: 16),
          AddToCalendarButton(habit: widget.habit),
          const SizedBox(height: 16),
          WeeklyChart(habit: widget.habit),
          const SizedBox(height: 16),
          RewardsSection(habit: widget.habit),
          const SizedBox(height: 16),
          CompletionHistory(habit: widget.habit),
          const SizedBox(height: 16),
          _JournalSection(habit: widget.habit),
        ],
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
              stream:
                  context.read<JournalService>().getJournalEntries(habit.id),
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
