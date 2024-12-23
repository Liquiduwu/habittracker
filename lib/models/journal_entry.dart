class JournalEntry {
  final String id;
  final String habitId;
  final String content;
  final DateTime date;
  final String mood; // 'great', 'good', 'okay', 'difficult'

  const JournalEntry({
    required this.id,
    required this.habitId,
    required this.content,
    required this.date,
    required this.mood,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'habitId': habitId,
      'content': content,
      'date': date.toIso8601String(),
      'mood': mood,
    };
  }

  factory JournalEntry.fromMap(Map<String, dynamic> map) {
    return JournalEntry(
      id: map['id'],
      habitId: map['habitId'],
      content: map['content'],
      date: DateTime.parse(map['date']),
      mood: map['mood'],
    );
  }
} 