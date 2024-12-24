class Partnership {
  final String id;
  final String userId;
  final String partnerId;
  final String partnerEmail;
  final bool isAccepted;
  final DateTime createdAt;

  Partnership({
    required this.id,
    required this.userId,
    required this.partnerId,
    required this.partnerEmail,
    this.isAccepted = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'partnerId': partnerId,
      'partnerEmail': partnerEmail,
      'isAccepted': isAccepted,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Partnership.fromMap(Map<String, dynamic> map) {
    return Partnership(
      id: map['id'],
      userId: map['userId'],
      partnerId: map['partnerId'],
      partnerEmail: map['partnerEmail'],
      isAccepted: map['isAccepted'] ?? false,
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
} 