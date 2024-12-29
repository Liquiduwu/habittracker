import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:habit_tracker/models/habit.dart';
import 'package:habit_tracker/models/reward.dart';
import 'package:habit_tracker/services/reward_service.dart';

class RewardsSection extends StatelessWidget {
  final Habit habit;

  const RewardsSection({
    super.key,
    required this.habit,
  });

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
                context
                    .read<RewardService>()
                    .checkAndUpdateRewards(habit.currentStreak);

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: rewards.length,
                  itemBuilder: (context, index) {
                    final reward = rewards[index];
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
                          fontWeight: reward.isUnlocked
                              ? FontWeight.bold
                              : FontWeight.normal,
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