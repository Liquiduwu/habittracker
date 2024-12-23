import 'package:flutter/material.dart';
import 'package:habit_tracker/models/habit_template.dart';

class TemplateService {
  static const List<HabitTemplate> templates = [
    // Health & Fitness
    HabitTemplate(
      id: 'exercise',
      title: 'Daily Exercise',
      description: '30 minutes of physical activity',
      targetDays: 30,
      category: 'Health & Fitness',
      icon: Icons.fitness_center,
    ),
    HabitTemplate(
      id: 'meditation',
      title: 'Meditation',
      description: '10 minutes of mindfulness',
      targetDays: 21,
      category: 'Health & Fitness',
      icon: Icons.self_improvement,
    ),
    
    // Productivity
    HabitTemplate(
      id: 'reading',
      title: 'Daily Reading',
      description: 'Read for 20 minutes',
      targetDays: 30,
      category: 'Productivity',
      icon: Icons.book,
    ),
    HabitTemplate(
      id: 'journaling',
      title: 'Journaling',
      description: 'Write daily reflections',
      targetDays: 21,
      category: 'Productivity',
      icon: Icons.edit_note,
    ),
    
    // Personal Growth
    HabitTemplate(
      id: 'gratitude',
      title: 'Gratitude Practice',
      description: 'List 3 things you\'re grateful for',
      targetDays: 21,
      category: 'Personal Growth',
      icon: Icons.favorite,
    ),
    HabitTemplate(
      id: 'learning',
      title: 'Learn Something New',
      description: '15 minutes of learning',
      targetDays: 30,
      category: 'Personal Growth',
      icon: Icons.school,
    ),
  ];

  static List<String> get categories {
    return templates
        .map((t) => t.category)
        .toSet()
        .toList();
  }

  static List<HabitTemplate> getTemplatesByCategory(String category) {
    return templates.where((t) => t.category == category).toList();
  }
} 