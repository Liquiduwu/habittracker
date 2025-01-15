import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:habit_tracker/services/partnership_service.dart';
import 'package:habit_tracker/models/partnership.dart';
import 'package:habit_tracker/models/habit.dart';
import 'package:habit_tracker/screens/partnership/suggested_partners_screen.dart';

class PartnershipScreen extends StatelessWidget {
  const PartnershipScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Accountability Partners'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'My Partners'),
              Tab(text: 'Invites'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.person_add),
              onPressed: () => _showAddPartnerDialog(context),
            ),
            IconButton(
              icon: const Icon(Icons.lightbulb_outline),
              tooltip: 'Suggestions',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SuggestedPartnersScreen(),
                  ),
                );
              },
            ),
          ],
        ),
        body: TabBarView(
          children: [
            _PartnersTab(),
            _InvitesTab(),
          ],
        ),
      ),
    );
  }

  void _showAddPartnerDialog(BuildContext context) {
    final usernameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Partner'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                hintText: 'Enter partner\'s username',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter the exact username of your partner',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final username = usernameController.text.trim();
              if (username.isNotEmpty) {
                context
                    .read<PartnershipService>()
                    .sendPartnerInvite(username)
                    .then((_) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invitation sent')),
                  );
                }).catchError((error) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(error.toString())),
                  );
                });
              }
            },
            child: const Text('Send Invite'),
          ),
        ],
      ),
    );
  }
}

class _PartnersTab extends StatelessWidget {
  void _showRemovePartnerDialog(BuildContext context, Partnership partnership) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Partner'),
        content: const Text('Are you sure you want to remove this partner?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context
                  .read<PartnershipService>()
                  .removePartnership(partnership.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Partner removed')),
              );
            },
            child: Text(
              'Remove',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Partnership>>(
      stream: context.read<PartnershipService>().getPartnerships(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final partnerships = snapshot.data!;
        if (partnerships.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 48, color: Colors.grey),
                SizedBox(height: 16),
                Text('No partners yet'),
                SizedBox(height: 8),
                Text(
                  'Add partners using their username',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: partnerships.length,
          itemBuilder: (context, index) {
            final partnership = partnerships[index];
            return Card(
              child: ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.person),
                ),
                title: FutureBuilder<String>(
                  future: context
                      .read<PartnershipService>()
                      .getPartnerUsername(partnership.partnerId),
                  builder: (context, snapshot) {
                    return Text(snapshot.data ?? 'Loading...');
                  },
                ),
                subtitle: Text(
                  partnership.isAccepted ? 'Active Partner' : 'Pending',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (partnership.isAccepted)
                      IconButton(
                        icon: const Icon(Icons.visibility),
                        onPressed: () =>
                            _showPartnerHabits(context, partnership),
                      ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      color: Theme.of(context).colorScheme.error,
                      onPressed: () =>
                          _showRemovePartnerDialog(context, partnership),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showPartnerHabits(BuildContext context, Partnership partnership) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _PartnerHabitsSheet(partnership: partnership),
    );
  }
}

class _InvitesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Partnership>>(
      stream: context.read<PartnershipService>().getPendingInvites(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final invites = snapshot.data!;
        if (invites.isEmpty) {
          return const Center(
            child: Text('No pending invites'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: invites.length,
          itemBuilder: (context, index) {
            final invite = invites[index];
            return Card(
              child: ListTile(
                leading: const Icon(Icons.person_add),
                title: Text(invite.partnerEmail),
                subtitle: const Text('Wants to be your accountability partner'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.green),
                      onPressed: () {
                        context
                            .read<PartnershipService>()
                            .acceptInvite(invite.id);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () {
                        context
                            .read<PartnershipService>()
                            .declineInvite(invite.id);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _PartnerHabitsSheet extends StatelessWidget {
  final Partnership partnership;

  const _PartnerHabitsSheet({required this.partnership});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Habit>>(
      stream: context
          .read<PartnershipService>()
          .getPartnerHabits(partnership.partnerId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final habits = snapshot.data!;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '${partnership.partnerEmail}\'s Habits',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: habits.length,
                itemBuilder: (context, index) {
                  final habit = habits[index];
                  return ListTile(
                    title: Text(habit.title),
                    subtitle: Text(habit.description),
                    trailing: Text(
                      '${habit.currentStreak} day streak',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
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
