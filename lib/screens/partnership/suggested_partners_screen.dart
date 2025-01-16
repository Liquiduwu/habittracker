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
  // List to hold suggested partners fetched from the service.
  List<Map<String, dynamic>> suggestions = [];

  // Boolean to track whether the screen is loading data.
  bool isLoading = true;

  // Variable to store any error that occurs while fetching data.
  String? error;

  @override
  void initState() {
    super.initState();
    // Load suggestions when the widget is initialized.
    _loadSuggestions();
  }

  // Method to fetch suggestions from the PartnershipService.
  Future<void> _loadSuggestions() async {
    try {
      // Set loading state and clear any previous error.
      setState(() {
        isLoading = true;
        error = null;
      });

      // Fetch suggested partners from the service.
      final loadedSuggestions =
          await context.read<PartnershipService>().getSuggestedPartners();

      // Update the state with the fetched suggestions and mark loading as complete.
      setState(() {
        suggestions = loadedSuggestions;
        isLoading = false;
      });
    } catch (e) {
      // If an error occurs, update the error state and mark loading as complete.
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  // Method to send an invitation to a suggested partner.
  Future<void> _sendInvite(int index, Map<String, dynamic> user) async {
    try {
      // Use the PartnershipService to send an invite.
      await context
          .read<PartnershipService>()
          .sendPartnerInvite(user['username']);

      // Remove the invited user from the suggestions list.
      setState(() {
        suggestions.removeAt(index);
      });

      // Show a success message if the widget is still mounted.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invitation sent')),
        );
      }
    } catch (error) {
      // Show an error message if the widget is still mounted.
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
        title: const Text('Suggested Partners'), // AppBar title.
      ),
      body: isLoading
          ? const Center(
              // Show a loading spinner if data is being fetched.
              child: CircularProgressIndicator(),
            )
          : error != null
              ? Center(
                  // Show an error message if one occurred.
                  child: Text('Error: $error'),
                )
              : suggestions.isEmpty
                  ? const Center(
                      // Show a message if there are no suggestions available.
                      child: Text('No suggestions available'),
                    )
                  : ListView.builder(
                      // Build a list of suggested partners.
                      padding: const EdgeInsets.all(16),
                      itemCount: suggestions.length,
                      itemBuilder: (context, index) {
                        final suggestion = suggestions[index];
                        final user = suggestion['user']; // Suggested user data.
                        final commonHabits = (suggestion['commonHabits']
                            as List<String>); // Common habits.

                        return Card(
                          margin: const EdgeInsets.only(
                              bottom: 12), // Add spacing between cards.
                          child: ListTile(
                            leading: CircleAvatar(
                              // CircleAvatar for user representation.
                              backgroundColor: Colors.green[100],
                              child: const Icon(
                                Icons.person,
                                color: Colors.black54,
                              ),
                            ),
                            title:
                                Text(user['username']), // Display the username.
                            subtitle: Text(
                              // Display common habits.
                              'Common Habit(s): ${commonHabits.join(", ")}',
                              style: const TextStyle(fontSize: 13),
                            ),
                            trailing: IconButton(
                              // Button to send an invitation.
                              icon: const Icon(Icons.person_add),
                              onPressed: () => _sendInvite(
                                  index, user), // Trigger invite logic.
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
