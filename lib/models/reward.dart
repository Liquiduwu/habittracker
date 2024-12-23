class Reward {
  final String id;
  final String title;
  final String description;
  final int requiredStreak;
  final String iconName;
  final bool isUnlocked;

  const Reward({
    required this.id,
    required this.title,
    required this.description,
    required this.requiredStreak,
    required this.iconName,
    this.isUnlocked = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'requiredStreak': requiredStreak,
      'iconName': iconName,
      'isUnlocked': isUnlocked,
    };
  }

  factory Reward.fromMap(Map<String, dynamic> map) {
    return Reward(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      requiredStreak: map['requiredStreak'],
      iconName: map['iconName'],
      isUnlocked: map['isUnlocked'] ?? false,
    );
  }
} 