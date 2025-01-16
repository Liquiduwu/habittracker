import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:habit_tracker/services/partnership_service.dart';

class SuggestedPartnersScreen extends StatelessWidget {
  const SuggestedPartnersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Suggested Partners'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: context.read<PartnershipService>().getSuggestedPartners(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final suggestions = snapshot.data ?? [];

          if (suggestions.isEmpty) {
            return const Center(
              child: Text('No suggestions available'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: suggestions.length,
            itemBuilder: (context, index) {
              final suggestion = suggestions[index];
              final user = suggestion['user'];
              final commonHabits = (suggestion['commonHabits'] as List<String>);

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green[100],
                    child: const Icon(Icons.person, color: Colors.black54),
                  ),
                  title: Text(user['username']),
                  subtitle: Text(
                    'Common Habit(s): ${commonHabits.join(", ")}',
                    style: const TextStyle(fontSize: 13),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.person_add),
                    onPressed: () {
                      context
                          .read<PartnershipService>()
                          .sendPartnerInvite(user['username'])
                          .then((_) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Invitation sent')),
                        );
                      }).catchError((error) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $error')),
                        );
                      });
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
