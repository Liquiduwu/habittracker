import 'package:flutter/material.dart' show IconData;

class HabitTemplate {
  final String id;
  final String title;
  final String description;
  final int targetDays;
  final String category;
  final IconData icon;

  const HabitTemplate({
    required this.id,
    required this.title,
    required this.description,
    required this.targetDays,
    required this.category,
    required this.icon,
  });
} 