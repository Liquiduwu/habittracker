import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:habit_tracker/services/habit_service.dart';
import 'package:habit_tracker/models/habit.dart';
import 'package:habit_tracker/widgets/habit_card.dart';

class HabitListScreen extends StatefulWidget {
  const HabitListScreen({super.key});

  @override
  State<HabitListScreen> createState() => _HabitListScreenState();
}

class _HabitListScreenState extends State<HabitListScreen> {
  String _sortBy = 'name'; // Default sort

  @override
  Widget build(BuildContext context) {
    return Consumer<HabitService?>(
      builder: (context, habitService, child) {
        if (habitService == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text('Sort by:'),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: _sortBy,
                    items: [
                      DropdownMenuItem(
                        value: 'name',
                        child: Row(
                          children: const [
                            Icon(Icons.sort_by_alpha),
                            SizedBox(width: 8),
                            Text('Name'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'date',
                        child: Row(
                          children: const [
                            Icon(Icons.calendar_today),
                            SizedBox(width: 8),
                            Text('Date Created'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'favorites',
                        child: Row(
                          children: const [
                            Icon(Icons.star),
                            SizedBox(width: 8),
                            Text('Favorites'),
                          ],
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _sortBy = value);
                      }
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<List<Habit>>(
                stream: habitService.getHabits(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final habits = habitService.sortHabits(snapshot.data!, _sortBy);

                  if (habits.isEmpty) {
                    return const Center(
                      child: Text('No habits yet'),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: habits.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: HabitCard(habit: habits[index]),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
} 