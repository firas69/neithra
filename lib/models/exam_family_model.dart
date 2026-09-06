class ExamFamily {
  static const uncategorizedId = 'family-uncategorized';
  static const uncategorizedName = 'Uncategorized';

  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ExamFamily({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ExamFamily.create(String name) {
    final now = DateTime.now();
    return ExamFamily(
      id: 'family-${now.microsecondsSinceEpoch}',
      name: name.trim(),
      createdAt: now,
      updatedAt: now,
    );
  }

  factory ExamFamily.uncategorized() {
    final now = DateTime.now();
    return ExamFamily(
      id: uncategorizedId,
      name: uncategorizedName,
      createdAt: now,
      updatedAt: now,
    );
  }

  factory ExamFamily.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now();
    return ExamFamily(
      id: json['id']?.toString() ?? uncategorizedId,
      name: json['name']?.toString() ?? uncategorizedName,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? now,
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ?? now,
    );
  }

  ExamFamily copyWith({String? name, DateTime? updatedAt}) {
    return ExamFamily(
      id: id,
      name: name?.trim() ?? this.name,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
