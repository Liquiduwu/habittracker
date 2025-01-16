import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:habit_tracker/services/partnership_service.dart';

class SuggestedPartnersScreen extends StatefulWidget {
  const SuggestedPartnersScreen({super.key});

  @override
  State<SuggestedPartnersScreen> createState() =>
      _SuggestedPartnersScreenState();
}

class _SuggestedPartnersScreenState extends State<SuggestedPartnersScreen> {
  List<Map<String, dynamic>> suggestions = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  Future<void> _loadSuggestions() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      final loadedSuggestions =
          await context.read<PartnershipService>().getSuggestedPartners();

      setState(() {
        suggestions = loadedSuggestions;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> _sendInvite(int index, Map<String, dynamic> user) async {
    try {
      await context
          .read<PartnershipService>()
          .sendPartnerInvite(user['username']);

      setState(() {
        suggestions.removeAt(index);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invitation sent')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Suggested Partners'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text('Error: $error'))
              : suggestions.isEmpty
                  ? const Center(
                      child: Text('No suggestions available'),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: suggestions.length,
                      itemBuilder: (context, index) {
                        final suggestion = suggestions[index];
                        final user = suggestion['user'];
                        final commonHabits =
                            (suggestion['commonHabits'] as List<String>);

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.green[100],
                              child: const Icon(
                                Icons.person,
                                color: Colors.black54,
                              ),
                            ),
                            title: Text(user['username']),
                            subtitle: Text(
                              'Common Habit(s): ${commonHabits.join(", ")}',
                              style: const TextStyle(fontSize: 13),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.person_add),
                              onPressed: () => _sendInvite(index, user),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
