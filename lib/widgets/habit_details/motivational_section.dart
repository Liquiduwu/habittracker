import 'package:flutter/material.dart';

class MotivationalSection extends StatelessWidget {
  final String motivationalMessage;
  final bool isLoading;
  final VoidCallback onRefresh;

  const MotivationalSection({
    super.key,
    required this.motivationalMessage,
    required this.isLoading,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Motivation',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : Text(
                    motivationalMessage,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 